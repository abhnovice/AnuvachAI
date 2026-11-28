import { useEffect, useState, type FormEvent, type ReactNode } from "react";
import { firebaseClient } from "./firebaseClient";
import {
  getAuth,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
} from "firebase/auth";

const required =
  import.meta.env.PROD || import.meta.env.VITE_AUTH_REQUIRED === "true";

async function auth() {
  return getAuth(await firebaseClient());
}

export async function adminToken() {
  if (!required) return undefined;
  const token = await (await auth()).currentUser?.getIdToken();
  if (!token) throw new Error("Sign in to continue");
  return token;
}

export function AuthGate({
  children,
}: {
  children: (logout?: () => void) => ReactNode;
}) {
  const [state, setState] = useState<"loading" | "signed-out" | "signed-in">(
    "loading",
  );
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  useEffect(() => {
    if (!required) return;
    let disposed = false;
    let unsubscribe: (() => void) | undefined;
    void auth()
      .then((client) => {
        if (disposed) return;
        unsubscribe = onAuthStateChanged(client, (user) =>
          setState(user ? "signed-in" : "signed-out"),
        );
      })
      .catch(() => {
        if (disposed) return;
        setError("Firebase sign-in is unavailable. Reload to try again.");
        setState("signed-out");
      });
    return () => {
      disposed = true;
      unsubscribe?.();
    };
  }, []);
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const values = new FormData(event.currentTarget);
    setBusy(true);
    setError("");
    try {
      await signInWithEmailAndPassword(
        await auth(),
        String(values.get("email")).trim(),
        String(values.get("password")),
      );
    } catch {
      setError("Could not sign in. Check your account and try again.");
    } finally {
      setBusy(false);
    }
  }
  if (!required) return children();
  if (state === "loading")
    return <main aria-busy="true">Checking sign-in…</main>;
  if (state === "signed-in")
    return children(() => {
      void auth().then(signOut);
    });
  return (
    <main className="admin-auth">
      <header className="admin-auth-header">
        <img
          className="logo"
          src="/anuvach-logo.png"
          width={46}
          height={46}
          alt=""
        />
        <div>
          <h1>Admin sign-in</h1>
        </div>
      </header>
      <form onSubmit={submit}>
        <label>
          Email{" "}
          <input required name="email" type="email" autoComplete="username" />
        </label>
        <label>
          Password{" "}
          <input
            required
            name="password"
            type="password"
            autoComplete="current-password"
          />
        </label>
        <button disabled={busy} type="submit">
          Sign in
        </button>
      </form>
      {error && <p role="alert">{error}</p>}
    </main>
  );
}
