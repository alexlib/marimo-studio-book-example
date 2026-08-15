#!/usr/bin/env bash
# Build the static book into site/.
#
# Studio has no notion of a multi-notebook site: each notebook exports on its
# own, and a view can only use files inside its own directory. This script is
# the glue that makes a book out of the parts. It does three things:
#
#   1. Copies the shared theme (theme/book.css, theme/book.js) into every
#      chapter's view directory, so all chapters render with one design.
#   2. Exports each notebook's "chapter" view to a sibling directory under
#      site/. Chapter pages link to each other with plain relative URLs
#      (../drawing/, ../filtering/), so the directory names here must match
#      the links in the chapter templates and in home/index.html.
#   3. Copies the hand-authored cover page (home/index.html) to site/.

set -euo pipefail
cd "$(dirname "$0")"

STUDIO="uvx marimo-studio@0.0.6"

# Chapter slug -> notebook. Keep in sync with the sidebar links in each
# view's index.html and the cards in home/index.html.
CHAPTERS=(
  "shape:eigen.py"
  "drawing:spectral_graph_drawing.py"
  "filtering:graph_signal_denoising.py"
)

for entry in "${CHAPTERS[@]}"; do
  notebook="${entry#*:}"
  stem="$(basename "$notebook" .py)"
  cp theme/book.css theme/book.js "__marimo__/studio/$stem/chapter/"
done

rm -rf site
mkdir -p site

for entry in "${CHAPTERS[@]}"; do
  slug="${entry%%:*}"
  notebook="${entry#*:}"
  echo "==> Exporting $notebook -> site/$slug"
  $STUDIO export "$notebook" --view chapter --output "site/$slug" --force
done

# Deduplicate the studio runtime. Every export writes an identical 20 MB
# _marimo-studio/assets directory (marimo's frontend JS; Pyodide and Python
# wheels are fetched from CDNs at boot and are not part of the bundle).
# Browsers cache by URL, so three copies at three URLs would each download
# in full. Keep the first copy at site/_studio/assets, delete the rest, and
# point every chapter page at the shared copy. This is safe because every
# reference inside the assets directory is relative to its own file
# (ES-module chunk imports and CSS url()s), so the hoisted copy resolves
# them from the shared path. The per-chapter _marimo-studio/views directory
# stays where it is.
mkdir -p site/_studio
first_slug="${CHAPTERS[0]%%:*}"
mv "site/$first_slug/_marimo-studio/assets" site/_studio/assets
for entry in "${CHAPTERS[@]}"; do
  slug="${entry%%:*}"
  if [ "$slug" != "$first_slug" ]; then
    rm -rf "site/$slug/_marimo-studio/assets"
  fi
  sed -i.bak 's|\./_marimo-studio/assets/|../_studio/assets/|g' "site/$slug/index.html"
  rm "site/$slug/index.html.bak"
done

cp home/index.html site/

echo "==> Done. Serve locally with: python3 -m http.server --directory site"
