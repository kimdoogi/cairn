#!/usr/bin/env bash
# cairn: 위키 정합성 점검 — frontmatter / 깨진 링크 / index 미등록 / 번호 중복·역전.
# usage: bash wiki/check.sh [--write-index] [wiki-dir]
#        --write-index  index.md의 목록 섹션과 "다음 번호"를 파일 스캔 결과로 다시 쓴다
#                       (여러 명이 작업할 때 index.md 충돌은 재생성으로 푼다)
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

err=0
fail() { echo "ERROR $*"; err=1; }
field() { sed -n "s/^$2: *\"\{0,1\}\([^\"]*\)\"\{0,1\}.*/\1/p" "$1" | head -1; }
maxnum() { find "$W" -name "$1-[0-9][0-9][0-9]-*.md" | sed "s/.*$1-\([0-9]\{3\}\)-.*/\1/" | sort -n | tail -1; }

pages=$(find "$W" -name '*.md' -not -path '*/_templates/*' | sort)
[ -n "$pages" ] || { echo "no pages under $W"; exit 1; }

# --write-index: 목록 섹션과 다음 번호를 파일 스캔으로 재생성
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
    [ -s "$gen" ] || echo '- (아직 없음)' > "$gen"
    awk -v head="## $head" -v gen="$gen" '
      index($0, head) == 1 { print; while ((getline l < gen) > 0) print l; close(gen); print ""; skip = 1; next }
      skip && /^## / { skip = 0 }
      skip { next }
      { print }
    ' "$INDEX" > "$tmp/out" && mv "$tmp/out" "$INDEX"
  done
  mp=$(maxnum P); md=$(maxnum D)
  nextline=$(printf -- '- **다음 번호**: P-%03d · D-%03d' "$(( 10#${mp:-000} + 1 ))" "$(( 10#${md:-000} + 1 ))")
  awk -v nl="$nextline" '/다음 번호/ { print nl; next } { print }' "$INDEX" > "$tmp/out" && mv "$tmp/out" "$INDEX"
  rm -rf "$tmp"
  echo "WROTE $INDEX (목록 · 다음 번호 재생성)"
  pages=$(find "$W" -name '*.md' -not -path '*/_templates/*' | sort)
fi

# 1. frontmatter (title/date/status)
while IFS= read -r f; do
  if ! head -1 "$f" | grep -q '^---$'; then fail "$f: frontmatter 없음"; continue; fi
  fm=$(sed -n '2,/^---$/p' "$f")
  for k in title date status; do
    printf '%s\n' "$fm" | grep -q "^$k:" || fail "$f: frontmatter '$k' 없음"
  done
done <<< "$pages"

# 2. 깨진 상대 링크
while IFS= read -r f; do
  d=$(dirname "$f")
  for l in $(grep -o '](\([^)#[:space:]]*\.md\)' "$f" | sed 's/^](//'); do
    case "$l" in http*|/*) continue;; esac
    [ -e "$d/$l" ] || fail "$f: 깨진 링크 -> $l"
  done
done <<< "$pages"

# 3. index 미등록 페이지
for dir in journal problems decisions concepts experiments; do
  [ -d "$W/$dir" ] || continue
  for f in $(find "$W/$dir" -name '*.md' | sort); do
    grep -qF "$(basename "$f")" "$INDEX" || fail "$f: index에 미등록 (bash wiki/check.sh --write-index)"
  done
done

# 4. 번호 중복(동시 작업 충돌) + index 다음 번호 역전
for p in P D; do
  for d in $(find "$W" -name "$p-[0-9][0-9][0-9]-*.md" | sed "s/.*\($p-[0-9]\{3\}\)-.*/\1/" | sort | uniq -d); do
    fail "번호 중복 $d: $(find "$W" -name "$d-*.md" -exec basename {} \; | tr '\n' ' ')"
  done
  nx=$(grep '다음 번호' "$INDEX" | grep -o "$p-[0-9]\{3\}" | head -1 | sed "s/$p-//")
  mx=$(maxnum "$p")
  if [ -n "$nx" ] && [ -n "$mx" ] && [ "$((10#$mx))" -ge "$((10#$nx))" ]; then
    fail "index 다음 번호 $p-$nx 인데 $p-$mx 가 이미 존재 (bash wiki/check.sh --write-index)"
  fi
done

# 5. 정보 — 진행 중 journal / 열린 문제
for pair in "journal:in-progress:진행 중 journal" "problems:open:열린 문제"; do
  dir=${pair%%:*}; rest=${pair#*:}; st=${rest%%:*}; label=${rest#*:}
  [ -d "$W/$dir" ] || continue
  hits=$(grep -l "^status: $st" $(find "$W/$dir" -name '*.md') /dev/null 2>/dev/null | tr '\n' ' ')
  [ -n "$hits" ] && echo "INFO $label: $hits"
done

[ $err -eq 0 ] && echo "OK $W ($(printf '%s\n' "$pages" | wc -l | tr -d ' ') 페이지)"
exit $err
