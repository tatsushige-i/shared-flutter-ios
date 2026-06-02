#!/usr/bin/env bash
#
# bootstrap.sh — wire shared-flutter-ios assets into a Flutter/iOS app.
#
# Run from the TARGET APP's root (current directory = target app):
#
#   cd ~/projects/myapp && bash ../shared-flutter-ios/bootstrap.sh
#
# Prerequisite: shared-flutter-ios and the target app are cloned into the SAME
# parent directory (siblings). This is the same placement model as shared-claude-code.
#
# What it does (idempotent — existing links/files are left untouched):
#   - symlinks rules/flutter-ios/*.md      -> .claude/rules/flutter-ios/<name>.md
#   - symlinks skills/<name>               -> .claude/skills/<name>
#   - symlinks docs/process/*.md           -> docs/process/<name>.md
#   - copies flutter-ios-profile.md.template -> .claude/flutter-ios-profile.md (if absent)
#
set -euo pipefail

# --- Resolve this script's own directory (the shared-flutter-ios repo root) ---
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SHARED_ROOT="$(cd -P "$(dirname "$SOURCE")" && pwd)"
SHARED_NAME="$(basename "$SHARED_ROOT")"

APP_ROOT="$(pwd)"

# --- Sanity checks -----------------------------------------------------------
if [ "$SHARED_ROOT" = "$APP_ROOT" ]; then
  echo "Error: run bootstrap.sh from the TARGET APP's root, not from inside $SHARED_NAME." >&2
  echo "       Example: cd ~/projects/myapp && bash ../$SHARED_NAME/bootstrap.sh" >&2
  exit 1
fi

if [ "$(dirname "$SHARED_ROOT")" != "$(dirname "$APP_ROOT")" ]; then
  echo "Warning: $SHARED_NAME and this app are not siblings in the same parent directory." >&2
  echo "         Relative symlinks assume sibling placement and may not resolve." >&2
fi

for d in "rules/flutter-ios" "skills" "docs/process"; do
  if [ ! -d "$SHARED_ROOT/$d" ]; then
    echo "Error: $SHARED_NAME/$d not found. Is the shared repo complete?" >&2
    exit 1
  fi
done

echo "Bootstrapping from: $SHARED_ROOT"
echo "Into app:           $APP_ROOT"
echo

created=0
skipped=0

# link_one <symlink_path> <relative_target>
link_one() {
  local link_path="$1" target="$2"
  if [ -L "$link_path" ] || [ -e "$link_path" ]; then
    echo "  skip   $link_path (already exists)"
    skipped=$((skipped + 1))
    return
  fi
  ln -s "$target" "$link_path"
  if [ -e "$link_path" ]; then
    echo "  link   $link_path -> $target"
    created=$((created + 1))
  else
    echo "  WARN   $link_path -> $target (target does not resolve)" >&2
    created=$((created + 1))
  fi
}

# --- Rules: .claude/rules/flutter-ios/<name>.md (4 levels up to parent) -------
mkdir -p .claude/rules/flutter-ios
echo "Rules:"
for f in "$SHARED_ROOT"/rules/flutter-ios/*.md; do
  [ -e "$f" ] || continue
  name="$(basename "$f")"
  link_one ".claude/rules/flutter-ios/$name" "../../../../$SHARED_NAME/rules/flutter-ios/$name"
done

# --- Skills: .claude/skills/<name> (3 levels up to parent) --------------------
mkdir -p .claude/skills
echo "Skills:"
for d in "$SHARED_ROOT"/skills/*/; do
  [ -f "${d}SKILL.md" ] || continue
  name="$(basename "$d")"
  link_one ".claude/skills/$name" "../../../$SHARED_NAME/skills/$name"
done

# --- Docs: docs/process/<name>.md (3 levels up to parent) ---------------------
mkdir -p docs/process
echo "Docs (docs/process):"
for f in "$SHARED_ROOT"/docs/process/*.md; do
  [ -e "$f" ] || continue
  name="$(basename "$f")"
  link_one "docs/process/$name" "../../../$SHARED_NAME/docs/process/$name"
done

# --- Profile template --------------------------------------------------------
echo "Profile:"
if [ -f ".claude/flutter-ios-profile.md" ]; then
  echo "  skip   .claude/flutter-ios-profile.md (already exists — not overwriting)"
else
  cp "$SHARED_ROOT/flutter-ios-profile.md.template" ".claude/flutter-ios-profile.md"
  echo "  copy   .claude/flutter-ios-profile.md (from template — fill in app-specific values)"
fi

echo
echo "Done. Created $created symlink(s), skipped $skipped existing item(s)."
echo
echo "Next steps:"
echo "  1. Edit .claude/flutter-ios-profile.md and fill in this app's values."
echo "  2. Commit the new symlinks and profile."
echo "  3. Run /config-flutter-ios-sync later to pull in any assets added to $SHARED_NAME."
