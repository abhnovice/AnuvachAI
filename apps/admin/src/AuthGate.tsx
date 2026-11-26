import { useEffect, useState, type FormEvent, type ReactNode } from "react";
import { getApp, getApps, initializeApp } from "firebase/app";
import {
  getAuth,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
} from "firebase/auth";

const required =
  import.meta.env.PROD || import.meta.env.VITE_AUTH_REQUIRED === "true";

function auth() {
  const app = getApps().length
    ? getApp()
    : initializeApp({
        apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
        authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
        projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
        appId: import.meta.env.VITE_FIREBASE_APP_ID,
        messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
      });
  return getAuth(app);
}

export async function adminToken() {
  if (!required) return undefined;
  const token = await auth().currentUser?.getIdToken();
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
    try {
      return onAuthStateChanged(auth(), (user) =>
        setState(user ? "signed-in" : "signed-out"),
      );
    } catch {
      setError("Firebase sign-in is unavailable.");
      setState("signed-out");
    }
  }, []);
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const values = new FormData(event.currentTarget);
    setBusy(true);
    setError("");
    try {
      await signInWithEmailAndPassword(
        auth(),
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
      void signOut(auth());
    });
  return (
    <main style={{ maxWidth: "26rem", margin: "4rem auto", padding: "1rem" }}>
      <h1>Admin sign-in</h1>
      <form onSubmit={submit} style={{ display: "grid", gap: "1rem" }}>
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
