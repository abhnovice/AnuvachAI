import { useEffect, useRef, useState, type FormEvent } from "react";
import { Icon } from "./Icon";
import { useLocalization } from "./localization";

type Notice = { id: string; summary: string; createdAt: string };
type Turn = { role: "user" | "assistant"; text: string };

export function IncidentNotifications({
  load,
  openReport,
}: {
  load: () => Promise<Notice[]>;
  openReport: (id: string) => void;
}) {
  const { t } = useLocalization();
  const [notices, setNotices] = useState<Notice[]>([]);
  const [open, setOpen] = useState(false);
  const [failed, setFailed] = useState(false);
  const [seen, setSeen] = useState(() => {
    try {
      return localStorage.getItem("anuvach-notice-seen") ?? "";
    } catch {
      return "";
    }
  });
  const anchor = useRef<HTMLDivElement>(null);
  const trigger = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    let active = true;
    let pending = false;
    const refresh = async () => {
      if (pending || document.visibilityState === "hidden") return;
      pending = true;
      try {
        const next = await load();
        if (active) {
          setNotices(next);
          setFailed(false);
        }
      } catch {
        if (active) setFailed(true);
      } finally {
        pending = false;
      }
    };
    void refresh();
    const timer = window.setInterval(refresh, 30000);
    document.addEventListener("visibilitychange", refresh);
    return () => {
      active = false;
      window.clearInterval(timer);
      document.removeEventListener("visibilitychange", refresh);
    };
  }, [load]);

  useEffect(() => {
    if (!open) return;
    const outside = (event: PointerEvent) => {
      if (
        event.target instanceof Node &&
        !anchor.current?.contains(event.target)
      )
        setOpen(false);
    };
    const escape = (event: KeyboardEvent) => {
      if (event.key !== "Escape") return;
      setOpen(false);
      trigger.current?.focus();
    };
    document.addEventListener("pointerdown", outside);
    document.addEventListener("keydown", escape);
    return () => {
      document.removeEventListener("pointerdown", outside);
      document.removeEventListener("keydown", escape);
    };
  }, [open]);

  const unread = notices.filter(({ createdAt }) => createdAt > seen).length;
  if (!failed && unread === 0 && !open) return null;
  return (
    <div ref={anchor} className="incident-notifications">
      <button
        ref={trigger}
        type="button"
        className="workspace-icon-button"
        aria-label={
          unread ? `${t("notifications")} (${unread})` : t("notifications")
        }
        aria-expanded={open}
        aria-controls="incident-notices"
        onClick={() => {
          if (!open && notices[0]) {
            const latest = notices[0].createdAt;
            setSeen(latest);
            try {
              localStorage.setItem("anuvach-notice-seen", latest);
            } catch {
              // Keep read state for this session when storage is unavailable.
            }
          }
          setOpen(!open);
        }}
      >
        <Icon name="bell" size={20} />
        {unread > 0 && (
          <span className="notification-count" aria-hidden>
            {unread}
          </span>
        )}
      </button>
      {open && (
        <section
          id="incident-notices"
          className="workspace-popover"
          aria-label={t("notifications")}
        >
          <h2>{t("recentIncidents")}</h2>
          {notices.map((notice) => (
            <button
              key={notice.id}
              className="incident-notice"
              onClick={() => {
                setOpen(false);
                openReport(notice.id);
              }}
            >
              <span className="incident-excerpt">{notice.summary}</span>
              <small>{notice.id}</small>
              <time dateTime={notice.createdAt}>
                {new Date(notice.createdAt).toLocaleString()}
              </time>
            </button>
          ))}
          {notices.length === 0 && (
            <p>{t(failed ? "noticesUnavailable" : "noNotices")}</p>
          )}
        </section>
      )}
    </div>
  );
}

export function WebsiteAssistant({
  ask,
  navigate,
}: {
  ask: (message: string, history: Turn[]) => Promise<string>;
  navigate: (page: "dashboard" | "reports") => void;
}) {
  const { t } = useLocalization();
  const [open, setOpen] = useState(false);
  const [text, setText] = useState("");
  const [turns, setTurns] = useState<Turn[]>([]);
  const [pending, setPending] = useState(false);
  const [failed, setFailed] = useState(false);
  const input = useRef<HTMLInputElement>(null);
  const trigger = useRef<HTMLButtonElement>(null);
  const transcript = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (open) input.current?.focus();
  }, [open]);
  useEffect(() => {
    const node = transcript.current;
    if (node) node.scrollTop = node.scrollHeight;
  }, [turns, pending, open]);

  async function send(event: FormEvent) {
    event.preventDefault();
    const message = text.trim();
    if (!message || pending) return;
    setText("");
    setTurns([...turns, { role: "user", text: message }]);
    setPending(true);
    setFailed(false);
    try {
      const reply = await ask(message, turns.slice(-6));
      setTurns((current) => [...current, { role: "assistant", text: reply }]);
    } catch {
      setFailed(true);
      setText(message);
      setTurns(turns);
    } finally {
      setPending(false);
    }
  }

  function close() {
    setOpen(false);
    requestAnimationFrame(() => trigger.current?.focus());
  }

  return (
    <div className="workspace-assistant">
      {open && (
        <section
          id="website-assistant"
          className="workspace-popover assistant-window"
          aria-label={t("websiteAssistant")}
          onKeyDown={(event) => {
            if (event.key === "Escape") close();
          }}
        >
          <header>
            <h2>{t("websiteAssistant")}</h2>
            <button
              className="workspace-icon-button"
              onClick={close}
              aria-label={t("closeAssistant")}
            >
              <Icon name="close" size={18} />
            </button>
          </header>
          <div className="assistant-shortcuts">
            <button onClick={() => navigate("dashboard")}>
              {t("dashboard")}
            </button>
            <button onClick={() => navigate("reports")}>
              {t("allReports")}
            </button>
          </div>
          <div
            ref={transcript}
            className="assistant-transcript"
            role="log"
            aria-live="polite"
          >
            {turns.map((turn, index) => (
              <p key={index} data-role={turn.role} dir="auto">
                {turn.text}
              </p>
            ))}
            {pending && <p>{t("assistantThinking")}</p>}
            {failed && <p role="alert">{t("assistantUnavailable")}</p>}
          </div>
          <form onSubmit={(event) => void send(event)}>
            <input
              ref={input}
              value={text}
              maxLength={800}
              aria-label={t("askWebsite")}
              placeholder={t("askWebsite")}
              onChange={(event) => setText(event.target.value)}
              autoComplete="off"
            />
            <button
              type="submit"
              disabled={pending || !text.trim()}
              aria-label={t("sendQuestion")}
            >
              <Icon name="arrow" size={18} />
            </button>
          </form>
        </section>
      )}
      {!open && (
        <button
          ref={trigger}
          className="assistant-launcher"
          aria-controls="website-assistant"
          aria-expanded={open}
          aria-label={t("websiteAssistant")}
          onClick={() => setOpen(true)}
        >
          <Icon name="female" size={22} />
        </button>
      )}
    </div>
  );
}
