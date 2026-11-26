import React from "react";
import { createRoot } from "react-dom/client";
import { AuthGate } from "./AuthGate";
import { App } from "./App";
import { LocalizationProvider } from "./localization";
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
import "./localization.css";
createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <LocalizationProvider>
      <AuthGate>{(logout) => <App onSignOut={logout} />}</AuthGate>
    </LocalizationProvider>
  </React.StrictMode>,
);
