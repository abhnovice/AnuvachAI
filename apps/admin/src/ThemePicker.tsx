import { useEffect, useState } from "react";
import { useLocalization } from "./localization";
type Theme = "light" | "dark" | "system";
export function ThemePicker() {
  const { t } = useLocalization();
  const [theme, setTheme] = useState<Theme>(() => {
    try {
      const saved = localStorage.getItem("anuvach-theme");
      return saved === "light" || saved === "dark" ? saved : "system";
    } catch {
      return "system";
    }
  });
  useEffect(() => {
    const media = window.matchMedia?.("(prefers-color-scheme: dark)");
    const apply = () => {
      document.documentElement.dataset.theme =
        theme === "system" ? (media?.matches ? "dark" : "light") : theme;
    };
    apply();
    media?.addEventListener("change", apply);
    try {
      localStorage.setItem("anuvach-theme", theme);
    } catch {
      /* Session-only preference when storage is unavailable. */
    }
    return () => media?.removeEventListener("change", apply);
  }, [theme]);
  return (
    <label className="theme-picker">
      {t("appearance")}
      <select
        aria-label={t("appearance")}
        value={theme}
        onChange={(e) => setTheme(e.target.value as Theme)}
      >
        <option value="light">{t("light")}</option>
        <option value="dark">{t("dark")}</option>
        <option value="system">{t("system")}</option>
      </select>
    </label>
  );
}
