#!/bin/bash
# Builds the free-edition web demo and commits it to the gh-pages branch (commit only, no push).
# Run only on develop; master is the full edition.
set -e
cd "$(dirname "$0")/.."

branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$branch" != "develop" ]; then
  echo "The demo can only be published from develop; current branch is $branch"
  exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
  echo "The working tree has uncommitted changes; commit them before publishing"
  exit 1
fi

flutter build web --release --base-href /FlutterKline/

rev=$(git rev-parse --short HEAD)
dir=$(mktemp -d)
if git show-ref --verify --quiet refs/heads/gh-pages; then
  git worktree add -q "$dir" gh-pages
else
  git worktree add -q --orphan -b gh-pages "$dir"
fi
rsync -a --delete --exclude .git build/web/ "$dir"/
touch "$dir/.nojekyll"
git -C "$dir" add -A
if git -C "$dir" diff --cached --quiet; then
  echo "The demo has not changed"
else
  git -C "$dir" commit -q -m "chore(web): update web demo ($rev)"
  echo "Committed to gh-pages: git push github gh-pages"
fi
git worktree remove "$dir"
