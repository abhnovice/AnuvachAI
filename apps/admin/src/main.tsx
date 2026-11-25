import React from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";
import "./style.css";
import "./pages.css";
import "./compact.css";
import "./experience.css";
import "./continuous.css";
import "./navigation.css";
import "./chart-interactions.css";
import "./view-layout.css";
import "./flow.css";
import "./chart-polish.css";
import "./brush.css";
createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
