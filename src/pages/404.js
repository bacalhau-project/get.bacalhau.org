import * as React from "react";
import { Link } from "gatsby";

export default function NotFound() {
  if (typeof window !== "undefined") {
    window.location = "/install.sh";
  }

  return null;
}
