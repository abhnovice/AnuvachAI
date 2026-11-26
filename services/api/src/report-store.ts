import { createHash, randomUUID } from "node:crypto";
import { DatabaseSync } from "node:sqlite";
import type { Firestore } from "firebase-admin/firestore";
import type { AuditRow } from "./analytics.js";
import type { Report } from "./contracts.js";

type Entry = { report: Report; owner?: string };
type Event = Omit<AuditRow, "sequence" | "report_id"> & { actor: string };
type Row = AuditRow & { actor: string };
type Change = (entry: Entry) => Event | undefined;
type Claim = { report: Report; lease?: string };

export function fail(statusCode: number, message: string): never {
  throw Object.assign(new Error(message), { statusCode });
}

export interface ReportStore {
  get(id: string): Promise<Entry>;
  list(): Promise<Entry[]>;
  events(id?: string): Promise<Row[]>;
  create(
    entry: Entry,
    key: string,
    event: Event,
  ): Promise<{ entry: Entry; created: boolean }>;
  update(id: string, change: Change, lease?: string): Promise<Entry>;
  claim(now: string): Promise<Claim | undefined>;
  close(): void;
}

function replay(previous: string, body: string) {
  if (previous !== body) fail(409, "Retry key belongs to a different payload");
}

export function sqliteStore(filename: string): ReportStore {
  const db = new DatabaseSync(filename);
  db.exec(`PRAGMA journal_mode=WAL;
    CREATE TABLE IF NOT EXISTS reports (id TEXT PRIMARY KEY, data TEXT NOT NULL, request_key TEXT UNIQUE NOT NULL, request_body TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS audit (sequence INTEGER PRIMARY KEY AUTOINCREMENT, report_id TEXT NOT NULL, actor TEXT NOT NULL, action TEXT NOT NULL, at TEXT NOT NULL, data TEXT NOT NULL);
    CREATE TRIGGER IF NOT EXISTS audit_no_update BEFORE UPDATE ON audit BEGIN SELECT RAISE(ABORT, 'append only'); END;
    CREATE TRIGGER IF NOT EXISTS audit_no_delete BEFORE DELETE ON audit BEGIN SELECT RAISE(ABORT, 'append only'); END;
    PRAGMA user_version=1;`);
  function get(id: string): Entry {
    const row = db.prepare("SELECT data FROM reports WHERE id=?").get(id);
    if (!row) return fail(404, "Report not found");
    return { report: JSON.parse(row.data as string) };
  }
  function audit(id: string, event: Event) {
    db.prepare(
      "INSERT INTO audit(report_id,actor,action,at,data) VALUES(?,?,?,?,?)",
    ).run(id, event.actor, event.action, event.at, JSON.stringify(event.data));
  }
  function transaction<T>(fn: () => T): T {
    db.exec("BEGIN IMMEDIATE");
    try {
      const result = fn();
      db.exec("COMMIT");
      return result;
    } catch (error) {
      db.exec("ROLLBACK");
      throw error;
    }
  }
  return {
    get: async (id) => get(id),
    list: async () =>
      db
        .prepare("SELECT data FROM reports ORDER BY rowid DESC")
        .all()
        .map((r) => ({ report: JSON.parse(r.data as string) })),
    async events(id) {
      const query = db.prepare(
        `SELECT * FROM audit ${id ? "WHERE report_id=?" : ""} ORDER BY sequence`,
      );
      return (id ? query.all(id) : query.all()).map((r) => ({
        ...r,
        data: JSON.parse(r.data as string),
      })) as Row[];
    },
    async create(entry, key, event) {
      return transaction(() => {
        const body = JSON.stringify(entry.report.facts);
        const row = db
          .prepare("SELECT id,request_body FROM reports WHERE request_key=?")
          .get(key);
        if (row) {
          replay(row.request_body as string, body);
          return { entry: get(row.id as string), created: false };
        }
        db.prepare("INSERT INTO reports VALUES(?,?,?,?)").run(
          entry.report.id,
          JSON.stringify(entry.report),
          key,
          body,
        );
        audit(entry.report.id, event);
        return { entry, created: true };
      });
    },
    async update(id, change) {
      return transaction(() => {
        const entry = get(id);
        const event = change(entry);
        if (event) {
          db.prepare("UPDATE reports SET data=? WHERE id=?").run(
            JSON.stringify(entry.report),
            id,
          );
          audit(id, event);
        }
        return entry;
      });
    },
    async claim(now) {
      const row = db
        .prepare(
          `SELECT id FROM reports
        WHERE json_extract(data, '$.triage.status') = 'pending'
        AND COALESCE(json_extract(data, '$.triage.nextAttemptAt'), '') <= ?
        ORDER BY COALESCE(json_extract(data, '$.triage.nextAttemptAt'), ''), rowid LIMIT 1`,
        )
        .get(now);
      return row ? { report: get(row.id as string).report } : undefined;
    },
    close: () => db.close(),
  };
}

type Stored = Entry & {
  sequence: number;
  readyAt: string | null;
  lease: string | null;
};

export function firestoreStore(db: Firestore): ReportStore {
  const reports = db.collection("anuvachReports");
  const keys = db.collection("anuvachRequestKeys");
  const audit = db.collection("anuvachAudit");
  function reportRef(id: string) {
    if (!id || id.includes("/") || id === "." || id === "..")
      fail(404, "Report not found");
    return reports.doc(id);
  }
  function load(data: FirebaseFirestore.DocumentData | undefined): Stored {
    if (!data) return fail(404, "Report not found");
    return data as Stored;
  }
  function readyAt(report: Report) {
    return report.triage?.status === "pending"
      ? (report.triage.nextAttemptAt ?? report.createdAt)
      : null;
  }
  function row(id: string, sequence: number, event: Event): Row {
    return JSON.parse(JSON.stringify({ ...event, report_id: id, sequence }));
  }
  return {
    async get(id) {
      return load((await reportRef(id).get()).data());
    },
    async list() {
      return (await reports.get()).docs.map((doc) => load(doc.data()));
    },
    async events(id) {
      const docs = await (
        id ? audit.where("report_id", "==", id) : audit
      ).get();
      return docs.docs
        .map((doc) => doc.data() as Row)
        .sort((a, b) => a.sequence - b.sequence);
    },
    async create(entry, key, event) {
      const keyRef = keys.doc(
        createHash("sha256")
          .update(JSON.stringify([entry.owner, key]))
          .digest("hex"),
      );
      const body = JSON.stringify(entry.report.facts);
      return db.runTransaction(async (tx) => {
        const previous = (await tx.get(keyRef)).data();
        if (previous) {
          replay(previous.body, body);
          return {
            entry: load((await tx.get(reports.doc(previous.id))).data()),
            created: false,
          };
        }
        const id = entry.report.id;
        tx.create(keyRef, { id, body });
        tx.create(reports.doc(id), {
          ...entry,
          sequence: 1,
          readyAt: readyAt(entry.report),
          lease: null,
        });
        tx.create(audit.doc(id + "-1"), row(id, 1, event));
        return { entry, created: true };
      });
    },
    async update(id, change, lease) {
      return db.runTransaction(async (tx) => {
        const ref = reportRef(id);
        const entry = load((await tx.get(ref)).data());
        if (lease && entry.lease !== lease) return entry;
        const event = change(entry);
        if (event) {
          entry.sequence++;
          if (lease) {
            entry.lease = null;
            entry.readyAt = readyAt(entry.report);
          }
          tx.set(ref, entry);
          tx.create(
            audit.doc(id + "-" + entry.sequence),
            row(id, entry.sequence, event),
          );
        }
        return entry;
      });
    },
    async claim(now) {
      return db.runTransaction(async (tx) => {
        const found = await tx.get(
          reports
            .where("readyAt", ">=", "")
            .where("readyAt", "<=", now)
            .orderBy("readyAt")
            .limit(1),
        );
        const doc = found.docs[0];
        if (!doc) return;
        const { report } = load(doc.data());
        const lease = randomUUID();
        tx.update(doc.ref, {
          lease,
          readyAt: new Date(Date.parse(now) + 90_000).toISOString(),
        });
        return { report, lease };
      });
    },
    close() {},
  };
}
