// Shared chapter-page behavior. The source of truth is theme/book.js;
// build.sh copies it into each view directory. Edit it there, not the copies.

// The boot pill covers initial startup only. Remove it the first time the
// runtime settles rather than binding to the ready state, which can flicker.
const bootPill = document.querySelector(".boot-pill");
if (bootPill) {
  if (document.documentElement.dataset.marimoStudioState === "ready") {
    bootPill.remove();
  } else {
    document.addEventListener("marimo-studio:idle", () => bootPill.remove(), {
      once: true,
    });
  }
}

// Highlight the sidebar link for the section currently in view.
const sectionLinks = Array.from(
  document.querySelectorAll(".toc .sections a[href^='#']"),
);
const sections = sectionLinks
  .map((link) => document.getElementById(link.hash.slice(1)))
  .filter(Boolean);

if (sections.length > 0) {
  const setCurrent = (id) => {
    sectionLinks.forEach((link) => {
      if (link.hash.slice(1) === id) {
        link.setAttribute("aria-current", "true");
      } else {
        link.removeAttribute("aria-current");
      }
    });
  };

  const observer = new IntersectionObserver(
    (entries) => {
      const visible = entries
        .filter((entry) => entry.isIntersecting)
        .sort((a, b) => a.target.offsetTop - b.target.offsetTop);
      if (visible.length > 0) {
        setCurrent(visible[0].target.id);
      }
    },
    { rootMargin: "-15% 0px -65% 0px" },
  );
  sections.forEach((section) => observer.observe(section));
}
