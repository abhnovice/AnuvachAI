// Google Material Icons (Apache 2.0), embedded SVGs avoid downloading an icon font.
// https://github.com/google/material-design-icons
const paths = {
  dashboard: "M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z",
  reports:
    "M3 5v14h18V5H3zm4 12H5v-2h2v2zm0-4H5v-2h2v2zm0-4H5V7h2v2zm12 8H9v-2h10v2zm0-4H9v-2h10v2zm0-4H9V7h10v2z",
  review:
    "M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm.5-13H11v6l5.25 3.15.75-1.23-4.5-2.67z",
  escalations: "M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z",
};
export function MaterialNavIcon({ name }: { name: keyof typeof paths }) {
  return (
    <svg
      width="20"
      height="20"
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden="true"
    >
      <path d={paths[name]} />
    </svg>
  );
}
