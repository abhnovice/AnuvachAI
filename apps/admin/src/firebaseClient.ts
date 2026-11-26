import {
  getApp,
  getApps,
  initializeApp,
  type FirebaseOptions,
} from "firebase/app";

let pending: Promise<ReturnType<typeof initializeApp>> | undefined;

async function initializeFirebase() {
  let options: FirebaseOptions = {
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
    appId: import.meta.env.VITE_FIREBASE_APP_ID,
    messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  };
  if (
    import.meta.env.PROD &&
    (!options.apiKey || !options.projectId || !options.appId)
  ) {
    const response = await fetch("/__/firebase/init.json", {
      signal: AbortSignal.timeout(10_000),
    });
    if (!response.ok)
      throw new Error("Firebase Hosting configuration is unavailable.");
    options = await response.json();
    if (!options.apiKey || !options.projectId || !options.appId)
      throw new Error("Firebase Hosting configuration is incomplete.");
  }
  return getApps().length ? getApp() : initializeApp(options);
}

export function firebaseClient() {
  return (pending ??= initializeFirebase().catch((error) => {
    pending = undefined;
    throw error;
  }));
}
