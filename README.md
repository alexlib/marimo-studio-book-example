# The Spectral Lens

This repository builds an interactive book — in the spirit of a Jupyter Book
site — out of three marimo notebooks, using
[marimo studio](https://pypi.org/project/marimo-studio/). Each chapter is a
web page whose figures, equations, and statistics are computed live by a
Python notebook running in the reader's browser. The chapters are:

1. **The Shape of a Matrix** (`eigen.py`) — the eigendecomposition of a
   symmetric 2×2 matrix, shown as the stretch it applies to the unit circle.
2. **Drawing with Eigenvectors** (`spectral_graph_drawing.py`) — Laplacian
   eigenvectors used as 2D coordinates for drawing graphs.
3. **Filtering on Graphs** (`graph_signal_denoising.py`) — the Laplacian
   eigenbasis used as a Fourier basis to denoise a signal on a graph.

The notebooks come from the
[marimo gallery](https://github.com/marimo-team/gallery-examples/tree/main/notebooks/math),
lightly adapted for studio: cells that the pages project are named, composite
figures are split into separately placeable panels, and each notebook exposes
a small dictionary of statistics that the pages bind into prose and chips.

## How a book is assembled from studio parts

Studio's unit is one notebook. Each notebook declares a view named `chapter`
in its header, and the view's page template lives at
`__marimo__/studio/<notebook-stem>/chapter/index.html` (studio requires that
path). Studio has no notion of a multi-page site, so this repository supplies
the missing pieces itself:

- **Navigation** is ordinary markup. Every chapter template contains the same
  sidebar, and chapters link to each other with relative URLs (`../drawing/`,
  `../filtering/`). There is no shared-layout mechanism in studio, so the
  sidebar is deliberately duplicated in all three templates; if you add a
  chapter, update the sidebar in every template and the cards in
  `home/index.html`.
- **The shared design** lives in `theme/book.css` and `theme/book.js`. A view
  can only use files inside its own directory, so `build.sh` copies the theme
  into each view directory before serving or exporting. Edit the theme in
  `theme/`, never the copies (they are gitignored).
- **The cover page** (`home/index.html`) is a plain static page with no
  notebook behind it.
- **`build.sh`** joins everything: it syncs the theme, exports each
  notebook's `chapter` view to `site/<slug>/`, deduplicates the runtime (see
  below), and copies the cover to `site/index.html`.

The page templates deliberately restructure the notebooks rather than mirror
them: controls are grouped into labeled panels next to the figures they
drive, a three-panel notebook figure becomes three captioned cards, a proof
becomes a collapsible aside, and notebook values appear inline in sentences
("filtering improves the mean squared error by a factor of …"). The notebook
stays the single source of the computation; the page owns the presentation.

## Run it

Build the static site into `site/` and serve it:

```console
./build.sh
python3 -m http.server --directory site
```

Each chapter also runs as a live page against a local Python kernel, without
exporting (run `./build.sh` once first so the theme copies exist):

```console
uvx marimo run --sandbox eigen.py
```

To edit a chapter with the notebook and its page template side by side:

```console
uvx marimo edit --sandbox eigen.py
```

To validate that every projected cell and value in the templates still
matches the notebooks:

```console
uvx marimo-studio check eigen.py --runtime
```

## Performance choices

Every exported bundle ships an identical copy of marimo's ~20 MB frontend
(`_marimo-studio/assets/`). Browsers cache by URL, so three copies at three
URLs would each be downloaded in full. `build.sh` therefore keeps one copy at
`site/_studio/assets/` and rewrites each chapter page to reference it; a
reader downloads the frontend once for the whole book. This is safe because
every reference inside that directory is relative to its own file.

Pyodide (the Python interpreter compiled to WebAssembly) and the Python
packages are not in the bundles at all. The runtime fetches them from CDNs at
boot, from the same URLs on every chapter, so the browser's HTTP cache shares
them across chapters automatically.

What cannot be shared is the kernel itself: each page boots its own Python
interpreter on load, and no state carries from one chapter to the next. That
is the cost of studio's one-notebook-per-page model, and it is why each
chapter is written to be self-contained.

## Deploy

`.github/workflows/deploy.yml` runs `./build.sh` and publishes `site/` to
GitHub Pages on every push to `main`.
