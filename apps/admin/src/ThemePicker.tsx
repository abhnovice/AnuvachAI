import { Icon } from "./Icon";
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
  const [isDark, setIsDark] = useState(
    () =>
      theme === "dark" ||
      (theme === "system" &&
        window.matchMedia?.("(prefers-color-scheme: dark)").matches === true),
  );
  useEffect(() => {
    const media = window.matchMedia?.("(prefers-color-scheme: dark)");
    const apply = () => {
      const dark =
        theme === "dark" || (theme === "system" && media?.matches === true);
      document.documentElement.dataset.theme = dark ? "dark" : "light";
      setIsDark(dark);
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
    <button
      type="button"
      className="workspace-icon-button"
      aria-label={isDark ? t("light") : t("dark")}
      title={t("appearance")}
      onClick={() =>
        setTheme(
          document.documentElement.dataset.theme === "dark" ? "light" : "dark",
        )
      }
    >
      <Icon name={isDark ? "sun" : "moon"} size={20} />
    </button>
  );
}
