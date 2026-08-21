#!/usr/bin/env bash
# cairn: 위키 정합성 점검 — frontmatter / 깨진 링크 / index 미등록 / 번호 역전.
# usage: bash wiki/check.sh   (인자 없으면 이 스크립트가 있는 폴더를 검사)
set -uo pipefail

W="${1:-$(cd "$(dirname "$0")" && pwd)}"
[ -d "$W" ] || { echo "no wiki dir: $W"; exit 1; }
INDEX="$W/index.md"; [ -f "$INDEX" ] || INDEX="$W/README.md"
[ -f "$INDEX" ] || { echo "no index: $W/index.md"; exit 1; }

err=0
fail() { echo "ERROR $*"; err=1; }

pages=$(find "$W" -name '*.md' -not -path '*/_templates/*' | sort)
[ -n "$pages" ] || { echo "no pages under $W"; exit 1; }

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
    grep -qF "$(basename "$f")" "$INDEX" || fail "$f: index에 미등록"
  done
done

# 4. 번호 역전 (index '다음 번호' <= 이미 존재하는 최대 번호)
for p in P D; do
  nx=$(grep '다음 번호' "$INDEX" | grep -o "$p-[0-9]\{3\}" | head -1 | sed "s/$p-//")
  mx=$(find "$W" -name "$p-[0-9][0-9][0-9]-*.md" | sed "s/.*$p-\([0-9]\{3\}\)-.*/\1/" | sort -n | tail -1)
  if [ -n "$nx" ] && [ -n "$mx" ] && [ "$((10#$mx))" -ge "$((10#$nx))" ]; then
    fail "index 다음 번호 $p-$nx 인데 $p-$mx 가 이미 존재 (번호 갱신 누락)"
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
