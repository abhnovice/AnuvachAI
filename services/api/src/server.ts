import { buildApp } from "./app.js";
const app = await buildApp();
await app.listen({
  port: Number(process.env.PORT ?? 3000),
  host: process.env.HOST ?? "127.0.0.1",
});
console.log(
  "Synthetic demo API listening at " + app.server.address()?.toString(),
);
