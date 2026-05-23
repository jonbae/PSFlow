import { createPortal as reactCreatePortal } from "react-dom";

export const createPortal = (jsx) => (container) =>
  reactCreatePortal(jsx, container);
