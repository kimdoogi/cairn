#!/usr/bin/env bash
# cairn: wiki consistency check — frontmatter / broken links / unlisted pages / duplicate or stale numbers.
# usage: bash wiki/check.sh [--write-index] [wiki-dir]
#        --write-index  regenerate index.md list sections and the "next number" line from the files on disk
#                       (with several people working, index.md conflicts are solved by regenerating, not merging)
set -uo pipefail

WRITE=0
W=""
for a in "$@"; do
  case "$a" in
    --write-index) WRITE=1 ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) W="$a" ;;
  esac
done
[ -n "$W" ] || W="$(cd "$(dirname "$0")" && pwd)"
[ -d "$W" ] || { echo "no wiki dir: $W"; exit 1; }
INDEX="$W/index.md"; [ -f "$INDEX" ] || INDEX="$W/README.md"
[ -f "$INDEX" ] || { echo "no index: $W/index.md"; exit 1; }

# The index ships in Korean or English — keep whichever wording it already uses.
if grep -q '다음 번호' "$INDEX"; then NEXT_LABEL='다음 번호'; EMPTY='- (아직 없음)'
else NEXT_LABEL='Next number'; EMPTY='- (none yet)'; fi

err=0
fail() { echo "ERROR $*"; err=1; }
field() { sed -n "s/^$2: *\"\{0,1\}\([^\"]*\)\"\{0,1\}.*/\1/p" "$1" | head -1; }
maxnum() { find "$W" -name "$1-[0-9][0-9][0-9]-*.md" | sed "s/.*$1-\([0-9]\{3\}\)-.*/\1/" | sort -n | tail -1; }

pages=$(find "$W" -name '*.md' -not -path '*/_templates/*' | sort)
[ -n "$pages" ] || { echo "no pages under $W"; exit 1; }

# --write-index: regenerate the list sections and the next-number line
if [ $WRITE -eq 1 ]; then
  tmp=$(mktemp -d)
  for spec in "journal:Journal:desc" "problems:Problems:asc" "decisions:Decisions:asc" "experiments:Experiments:asc" "concepts:Concepts:asc"; do
    dir=${spec%%:*}; rest=${spec#*:}; head=${rest%%:*}; order=${rest#*:}
    gen="$tmp/$dir"; : > "$gen"
    if [ -d "$W/$dir" ]; then
      files=$(find "$W/$dir" -name '*.md' | sort)
      [ "$order" = desc ] && files=$(printf '%s\n' "$files" | sort -r)
      while IFS= read -r f; do
        [ -n "$f" ] || continue
        t=$(field "$f" title); s=$(field "$f" status)
        printf -- '- [%s](%s/%s)%s\n' "${t:-$(basename "$f" .md)}" "$dir" "$(basename "$f")" "${s:+ — $s}" >> "$gen"
      done <<< "$files"
    fi
    [ -s "$gen" ] || echo "$EMPTY" > "$gen"
    awk -v head="## $head" -v gen="$gen" '
      index($0, head) == 1 { print; while ((getline l < gen) > 0) print l; close(gen); print ""; skip = 1; next }
      skip && /^## / { skip = 0 }
      skip { next }
      { print }
    ' "$INDEX" > "$tmp/out" && mv "$tmp/out" "$INDEX"
  done
  mp=$(maxnum P); md=$(maxnum D)
  nextline=$(printf -- '- **%s**: P-%03d · D-%03d' "$NEXT_LABEL" "$(( 10#${mp:-000} + 1 ))" "$(( 10#${md:-000} + 1 ))")
  awk -v nl="$nextline" -v label="$NEXT_LABEL" 'index($0, label) > 0 { print nl; next } { print }' "$INDEX" > "$tmp/out" && mv "$tmp/out" "$INDEX"
  rm -rf "$tmp"
  echo "WROTE $INDEX (lists + next number regenerated)"
  pages=$(find "$W" -name '*.md' -not -path '*/_templates/*' | sort)
fi

# 1. frontmatter (title/date/status)
while IFS= read -r f; do
  if ! head -1 "$f" | grep -q '^---$'; then fail "$f: no frontmatter"; continue; fi
  fm=$(sed -n '2,/^---$/p' "$f")
  for k in title date status; do
    printf '%s\n' "$fm" | grep -q "^$k:" || fail "$f: frontmatter missing '$k'"
  done
done <<< "$pages"

# 2. broken relative links
while IFS= read -r f; do
  d=$(dirname "$f")
  for l in $(grep -o '](\([^)#[:space:]]*\.md\)' "$f" | sed 's/^](//'); do
    case "$l" in http*|/*) continue;; esac
    [ -e "$d/$l" ] || fail "$f: broken link -> $l"
  done
done <<< "$pages"

# 3. pages missing from the index
for dir in journal problems decisions concepts experiments; do
  [ -d "$W/$dir" ] || continue
  for f in $(find "$W/$dir" -name '*.md' | sort); do
    grep -qF "$(basename "$f")" "$INDEX" || fail "$f: not listed in index (bash wiki/check.sh --write-index)"
  done
done

# 4. duplicate numbers (two people grabbed the same one) + stale next-number
for p in P D; do
  for d in $(find "$W" -name "$p-[0-9][0-9][0-9]-*.md" | sed "s/.*\($p-[0-9]\{3\}\)-.*/\1/" | sort | uniq -d); do
    fail "duplicate number $d: $(find "$W" -name "$d-*.md" -exec basename {} \; | tr '\n' ' ')"
  done
  nx=$(grep "$NEXT_LABEL" "$INDEX" | grep -o "$p-[0-9]\{3\}" | head -1 | sed "s/$p-//")
  mx=$(maxnum "$p")
  if [ -n "$nx" ] && [ -n "$mx" ] && [ "$((10#$mx))" -ge "$((10#$nx))" ]; then
    fail "index says next is $p-$nx but $p-$mx already exists (bash wiki/check.sh --write-index)"
  fi
done

# 5. info — journals in progress / open problems
for pair in "journal:in-progress:journals in progress" "problems:open:open problems"; do
  dir=${pair%%:*}; rest=${pair#*:}; st=${rest%%:*}; label=${rest#*:}
  [ -d "$W/$dir" ] || continue
  hits=$(grep -l "^status: $st" $(find "$W/$dir" -name '*.md') /dev/null 2>/dev/null | tr '\n' ' ')
  [ -n "$hits" ] && echo "INFO $label: $hits"
done

[ $err -eq 0 ] && echo "OK $W ($(printf '%s\n' "$pages" | wc -l | tr -d ' ') pages)"
exit $err
