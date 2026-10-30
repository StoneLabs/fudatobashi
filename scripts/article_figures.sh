#!/usr/bin/env bash
# Re-renders the guides' pictures that are drawn from the app's own cards and
# widgets (tool/article_figures/) into assets/artworks/articles/ as WebP.
# Run it again after changing the card art, the poems or the figures.
#   ./scripts/article_figures.sh
set -e
source "$(dirname "$0")/env.sh"
rm -rf build/article_figures
flutter test tool/article_figures/render_figures_test.dart
mkdir -p assets/artworks/articles
for png in build/article_figures/*.png; do
  magick "$png" -define webp:lossless=true "assets/artworks/articles/$(basename "$png" .png).webp"
done
rm -rf build/article_figures
ls assets/artworks/articles
