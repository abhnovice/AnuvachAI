import { useEffect, useRef } from "react";
export function usePageScroll(page: string, navigate: (page: string) => void) {
  const action = useRef(navigate);
  action.current = navigate;
  const switchedAt = useRef(0);
  useEffect(() => {
    let accumulated = 0,
      lastInput = 0,
      touchY = 0;
    const eligible = (target: EventTarget | null) => {
      if (
        !(target instanceof Element) ||
        target.closest(
          ".sidebar, select, input, textarea, [role=dialog], .modal-backdrop",
        )
      )
        return false;
      for (
        let node: Element | null = target;
        node && node !== document.body;
        node = node.parentElement
      ) {
        const style = getComputedStyle(node);
        if (
          /auto|scroll/.test(style.overflowY) &&
          node.scrollHeight > node.clientHeight + 2
        )
          return false;
      }
      return true;
    };
    const advance = (delta: number, target: EventTarget | null) => {
      if (!eligible(target) || Date.now() - switchedAt.current < 1000) return;
      const bottom =
        window.scrollY + window.innerHeight >=
        document.documentElement.scrollHeight - 3;
      const top = window.scrollY <= 3;
      if (!(
        (page === "dashboard" && delta > 0 && bottom) ||
        (page === "reports" && delta < 0 && top)
      )) {
        accumulated = 0;
        return;
      }
      const now = Date.now();
      if (now - lastInput > 250 || Math.sign(accumulated) !== Math.sign(delta))
        accumulated = 0;
      lastInput = now;
      accumulated += delta;
      if (Math.abs(accumulated) < 80) return;
      accumulated = 0;
      switchedAt.current = now;
      action.current(page === "dashboard" ? "reports" : "dashboard");
    };
    const wheel = (event: WheelEvent) => {
      if (event.ctrlKey || Math.abs(event.deltaX) > Math.abs(event.deltaY))
        return;
      advance(
        event.deltaY *
          (event.deltaMode === 1
            ? 16
            : event.deltaMode === 2
              ? innerHeight
              : 1),
        event.target,
      );
    };
    const start = (event: TouchEvent) => {
      touchY = event.touches[0]?.clientY ?? 0;
    };
    const end = (event: TouchEvent) => {
      const y = event.changedTouches[0]?.clientY;
      if (y !== undefined) advance(touchY - y, event.target);
    };
    window.addEventListener("wheel", wheel, { passive: true });
    window.addEventListener("touchstart", start, { passive: true });
    window.addEventListener("touchend", end, { passive: true });
    return () => {
      window.removeEventListener("wheel", wheel);
      window.removeEventListener("touchstart", start);
      window.removeEventListener("touchend", end);
    };
  }, [page]);
}
