export function Icon({ name, size = 20 }: { name: string; size?: number }) {
  const paths: Record<string, string> = {
    reports: "M8 3h8l4 4v14H4V3h4Zm8 0v5h4M8 12h8M8 16h5",
    grid: "M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h7v7h-7z",
    shield: "M12 3 3 7v5c0 5 9 9 9 9s9-4 9-9V7l-9-4ZM8 12l3 3 5-6",
    refresh:
      "M20 7v5h-5M4 17v-5h5M6.1 6.1A8 8 0 0 1 20 12M4 12a8 8 0 0 0 13.9 5.9",
    clock: "M12 8v5l3 2M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0",
    arrow: "M5 12h14M13 6l6 6-6 6",
    bell: "M18 8a6 6 0 0 0-12 0c0 6-2 7-2 9h16c0-2-2-3-2-9m-8 12a2 2 0 0 0 4 0",
    close: "M6 6l12 12M18 6 6 18",
    message: "M4 4h16v12H9l-5 4V4ZM8 8h8M8 12h5",
    user: "M20 21v-3a5 5 0 0 0-5-5H9a5 5 0 0 0-5 5v3M16 6a4 4 0 1 1-8 0 4 4 0 0 1 8 0",
    alert: "M12 8v5M12 17h.01M12 3 2 21h20L12 3Z",
    check: "M5 12l4 4L19 6",
    info: "M12 11v6M12 7h.01M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0",
  };
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.6"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d={paths[name] ?? paths.reports} />
    </svg>
  );
}
