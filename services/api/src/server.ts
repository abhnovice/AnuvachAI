import { getFirestore } from "firebase-admin/firestore";
import { buildApp } from "./app.js";
import { firebaseAccess, firebaseApp } from "./auth.js";
import { firestoreStore } from "./report-store.js";

const protectedTrial =
  Boolean(process.env.K_SERVICE) ||
  process.env.FIREBASE_PROJECT_ID !== undefined;
const options = protectedTrial
  ? {
      access: firebaseAccess(),
      store: firestoreStore(getFirestore(firebaseApp())),
    }
  : undefined;
const app = await buildApp(undefined, undefined, undefined, options);
await app.listen({
  port: Number(process.env.PORT ?? 3000),
  host: process.env.HOST ?? "127.0.0.1",
});
console.log("Anuvach API listening");
