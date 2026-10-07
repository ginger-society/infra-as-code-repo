#!/usr/bin/env bash
# optimize-images.sh - build SEO / bandwidth friendly images from public/ into public-dist/
#
# Rules
#   .svg              copied untouched
#   .png              resized (never upscaled) + compressed, stays .png
#   .jpg / .jpeg      converted to .webp (kept as jpg only if the webp would be bigger)
#   .webp             resized + re-encoded (original kept if that does not help)
#   anything else     copied untouched (ico, gif, txt ...) so public-dist is a drop-in for public
#
# Outputs per raster image (folder structure mirrored)
#   {name}.{ext}      display / zoom version   max width 1600 px (default)
#   {name}-t.{ext}    thumbnail                max width  400 px (default)
#
# 1600 px = ~5 inch wide image on a 13-14" MacBook (254 ppi needs ~1270 px) + ~25% hover-zoom headroom.
#
# Requires: ImageMagick (convert|magick + identify), webp (cwebp), pngquant, optipng (or oxipng), awk, sed, xargs
#   Debian/Ubuntu : apt-get install -y imagemagick webp pngquant optipng
#   macOS (brew)  : brew install imagemagick webp pngquant optipng
#
# Usage: ./optimize-images.sh [options]
#   --src DIR            source folder              (default: public)
#   --dist DIR           output folder              (default: public-dist)
#   --display-width PX   display max width          (default: 1600)
#   --thumb-width PX     thumbnail max width        (default: 400)
#   --quality N          webp / jpeg quality        (default: 82)
#   --png-lossless       skip pngquant (no colour reduction, smaller savings)
#   --rewrite-md DIR     rewrite .jpg/.jpeg image paths to .webp in .md files under DIR
#   --clean              empty the dist folder first
#   --jobs N             parallel workers           (default: CPU count)
#   --report-dir DIR     where CSV/manifest go      (default: .image-report)

set -euo pipefail

SRC=public; DIST=public-dist; DISPLAY_W=1600; THUMB_W=400; QUALITY=82
PNG_LOSSY=1; CLEAN=0; REWRITE_MD=""; REPORT_DIR=.image-report
JOBS=$( (nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4) | head -1)

while [ $# -gt 0 ]; do
  case "$1" in
    --src) SRC=$2; shift 2;;
    --dist) DIST=$2; shift 2;;
    --display-width) DISPLAY_W=$2; shift 2;;
    --thumb-width) THUMB_W=$2; shift 2;;
    --quality) QUALITY=$2; shift 2;;
    --png-lossless) PNG_LOSSY=0; shift;;
    --rewrite-md) REWRITE_MD=$2; shift 2;;
    --clean) CLEAN=1; shift;;
    --jobs) JOBS=$2; shift 2;;
    --report-dir) REPORT_DIR=$2; shift 2;;
    -h|--help) sed -n '2,32p' "$0"; exit 0;;
    *) echo "Unknown option: $1" >&2; exit 1;;
  esac
done

# ------------------------------------------------------------------ dependencies
if command -v magick >/dev/null 2>&1; then IM="magick"; ID="magick identify"
elif command -v convert >/dev/null 2>&1; then IM="convert"; ID="identify"
else IM=""; fi
missing=()
[ -z "$IM" ] && missing+=("imagemagick")
command -v cwebp >/dev/null 2>&1 || missing+=("webp (cwebp)")
[ "$PNG_LOSSY" = 1 ] && { command -v pngquant >/dev/null 2>&1 || missing+=("pngquant"); }
if command -v oxipng >/dev/null 2>&1; then PNGOPT=oxipng
elif command -v optipng >/dev/null 2>&1; then PNGOPT=optipng
else missing+=("optipng or oxipng"); PNGOPT=""; fi
if [ ${#missing[@]} -gt 0 ]; then
  echo "Missing tools: ${missing[*]}" >&2
  echo "  apt-get install -y imagemagick webp pngquant optipng   (or: brew install imagemagick webp pngquant optipng)" >&2
  exit 1
fi
[ -d "$SRC" ] || { echo "Source folder not found: $SRC" >&2; exit 1; }
SRC=${SRC%/}; DIST=${DIST%/}
if [ "$CLEAN" = 1 ] && [ -d "$DIST" ]; then rm -rf "$DIST"; fi
mkdir -p "$DIST" "$REPORT_DIR"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
RESULTS="$TMP/results.tsv"; : > "$RESULTS"
export SRC DIST DISPLAY_W THUMB_W QUALITY PNG_LOSSY IM ID PNGOPT TMP RESULTS

# ----------------------------------------------------------------------- helpers
size()  { wc -c < "$1" | tr -d ' '; }
width() { $ID -format '%w' "$1[0]" 2>/dev/null; }

optimize_png() {   # lossless re-pack, in place
  if [ "$PNGOPT" = oxipng ]; then oxipng -o 3 --strip safe -q "$1" >/dev/null 2>&1 || true
  else optipng -o2 -strip all -quiet "$1" >/dev/null 2>&1 || true; fi
}

make_png() {       # in out maxwidth  -> resize (shrink only), strip, quantize + repack, keep smallest
  local in=$1 out=$2 w=$3 t best
  t=$(mktemp -d "$TMP/p.XXXXXX")
  $IM "$in[0]" -auto-orient -resize "${w}x>" -strip "png:$t/a.png" || return 1
  optimize_png "$t/a.png"
  best="$t/a.png"
  if [ "$PNG_LOSSY" = 1 ]; then
    # exit 99 = could not reach min quality -> we simply keep the lossless result
    if pngquant --force --quality=70-95 --speed 1 --strip --output "$t/q.png" "$t/a.png" >/dev/null 2>&1; then
      optimize_png "$t/q.png"
      if [ "$(size "$t/q.png")" -lt "$(size "$best")" ]; then best="$t/q.png"; fi
    fi
  fi
  cp "$best" "$out"; rm -rf "$t"
}

make_webp() {      # in out maxwidth
  $IM "$1[0]" -auto-orient -resize "${3}x>" -strip png:- \
    | cwebp -quiet -q "$QUALITY" -m 6 -alpha_q 90 -o "$2" -- - >/dev/null 2>&1 || return 1
}

make_jpg() {       # in out maxwidth
  $IM "$1[0]" -auto-orient -resize "${3}x>" -strip -sampling-factor 4:2:0 -interlace Plane \
    -quality "$QUALITY" "$2" || return 1
}

make_as() {        # in out maxwidth ext
  case "$4" in
    png) make_png "$1" "$2" "$3";;
    webp) make_webp "$1" "$2" "$3";;
    *) make_jpg "$1" "$2" "$3";;
  esac
}

record() { printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$@" >> "$RESULTS"; }

process_one() {
  local src=$1 rel ext dir stem out_ext fin_ext dest thumb sw os ds ts note="" fmt dim
  rel=${src#"$SRC"/}
  ext=$(printf '%s' "${src##*.}" | tr '[:upper:]' '[:lower:]')
  dir=$(dirname "$rel"); stem=$(basename "${rel%.*}")
  mkdir -p "$DIST/$dir"

  case "$ext" in
    png|jpg|jpeg|webp) ;;
    *) cp -p "$src" "$DIST/$rel"; record copied - 0 0 0 "/$rel" "/$rel" - - ""; return 0;;
  esac

  os=$(size "$src"); sw=$(width "$src") || sw=0; sw=${sw:-0}
  if [ "$ext" = png ]; then out_ext=png; else out_ext=webp; fi
  fmt=$ext; [ "$ext" = jpeg ] && fmt=jpg

  local tmpd; tmpd=$(mktemp -d "$TMP/d.XXXXXX")
  make_as "$src" "$tmpd/disp.$out_ext" "$DISPLAY_W" "$out_ext" || { rm -rf "$tmpd"; return 1; }
  ds=$(size "$tmpd/disp.$out_ext")

  fin_ext=$out_ext
  if [ "$sw" -le "$DISPLAY_W" ] && [ "$ds" -ge "$os" ]; then
    # nothing gained and no resize needed: keep the original file (and its format)
    fin_ext=$ext; cp -p "$src" "$DIST/$dir/$stem.$fin_ext"; ds=$os
    note="kept original (re-encode was not smaller)"
  else
    cp "$tmpd/disp.$out_ext" "$DIST/$dir/$stem.$fin_ext"
    if [ "$fmt" = jpg ]; then fmt="jpg>webp"; fi
  fi
  rm -rf "$tmpd"

  thumb="$DIST/$dir/$stem-t.$fin_ext"
  make_as "$src" "$thumb" "$THUMB_W" "$fin_ext" || return 1
  ts=$(size "$thumb")
  dim=$($ID -format '%wx%h' "$DIST/$dir/$stem.$fin_ext[0]" 2>/dev/null || echo "-")
  record image "$fmt" "$os" "$ds" "$ts" "/$rel" "/$dir/$stem.$fin_ext" "/$dir/$stem-t.$fin_ext" "$dim" "$note"
}

run_one() {        # never lose an image: on failure copy the original and log it
  if ! process_one "$1"; then
    local rel=${1#"$SRC"/}
    mkdir -p "$DIST/$(dirname "$rel")"; cp -p "$1" "$DIST/$rel"
    record failed - 0 0 0 "/$rel" "/$rel" - - "conversion failed, copied as-is"
  fi
}
export -f size width optimize_png make_png make_webp make_jpg make_as record process_one run_one

# --------------------------------------------------------------------------- run
echo "src=$SRC dist=$DIST | display ${DISPLAY_W}px, thumb ${THUMB_W}px, q$QUALITY, png: $([ "$PNG_LOSSY" = 1 ] && echo pngquant+$PNGOPT || echo lossless-$PNGOPT), jobs=$JOBS"
find "$SRC" -type f -print0 | xargs -0 -n1 -P "$JOBS" bash -c 'run_one "$0"'

# ------------------------------------------------------------------------ report
sort -t$'\t' -k6,6 "$RESULTS" > "$TMP/sorted.tsv"

echo
awk -F'\t' '
  function kb(x){return x/1024}
  function pc(a,b){return a==0?0:(a-b)/a*100}
  $1=="image"{n[$2]++;o[$2]+=$3;d[$2]+=$4;t[$2]+=$5;N++;O+=$3;D+=$4;T+=$5; if($10!="")kept++}
  $1=="copied"{c++}  $1=="failed"{f++}
  END{
    line="--------------------------------------------------------------------------------------"
    print line
    printf "%-12s%7s%14s%13s%12s%9s%12s\n","Format","Files","Original KB","Display KB","Saved KB","Saved %","Thumbs KB"
    print line
    for(k in n) printf "%-12s%7d%14.1f%13.1f%12.1f%8.1f%%%12.1f\n",k,n[k],kb(o[k]),kb(d[k]),kb(o[k]-d[k]),pc(o[k],d[k]),kb(t[k]) | "sort"
    close("sort")
    print line
    printf "%-12s%7d%14.1f%13.1f%12.1f%8.1f%%%12.1f\n","TOTAL",N,kb(O),kb(D),kb(O-D),pc(O,D),kb(T)
    print line
    printf "Display images: %d | thumbnails (-t): %d | copied untouched (svg/other): %d | failed: %d | kept original: %d\n",N,N,c,f,kept
  }' "$TMP/sorted.tsv"

echo; echo "Top 10 savings (KB, %)"
awk -F'\t' '$1=="image"{printf "%10.1f  %5.1f%%  %s\n",($3-$4)/1024,($3==0?0:($3-$4)/$3*100),$6}' "$TMP/sorted.tsv" \
  | sort -rn | head -10 | sed 's/^/  /'

if awk -F'\t' '$1=="failed"{f=1} END{exit !f}' "$TMP/sorted.tsv"; then
  echo; echo "FAILED (copied as-is):"; awk -F'\t' '$1=="failed"{print "  - "$6}' "$TMP/sorted.tsv"
fi

# CSV + manifests
awk -F'\t' 'BEGIN{print "source,format,original_kb,display_kb,saved_kb,saved_pct,thumb_kb,dimensions,display_path,thumb_path,note"}
  $1=="image"{printf "%s,%s,%.1f,%.1f,%.1f,%.1f,%.1f,%s,%s,%s,\"%s\"\n",$6,$2,$3/1024,$4/1024,($3-$4)/1024,($3==0?0:($3-$4)/$3*100),$5/1024,$9,$7,$8,$10}' \
  "$TMP/sorted.tsv" > "$REPORT_DIR/image-report.csv"
awk -F'\t' 'BEGIN{print "{"} $1=="image"{printf "%s  \"%s\": {\"display\": \"%s\", \"thumb\": \"%s\", \"size\": \"%s\"}",(s++?",\n":""),$6,$7,$8,$9} END{print "\n}"}' \
  "$TMP/sorted.tsv" > "$REPORT_DIR/image-manifest.json"
echo; echo "Wrote $REPORT_DIR/image-report.csv and $REPORT_DIR/image-manifest.json"

# ------------------------------------------------------------- markdown rewrite
if [ -n "$REWRITE_MD" ]; then
  SEDF="$TMP/rewrite.sed"; : > "$SEDF"
  while IFS=$'\t' read -r st _ _ _ _ s d _ _ _; do
    [ "$st" = image ] && [ "$s" != "$d" ] || continue
    printf 's|%s|%s|g\n' "$(printf '%s' "$s" | sed 's/[][\.*^$|]/\\&/g')" "$d" >> "$SEDF"
  done < "$TMP/sorted.tsv"
  if [ -s "$SEDF" ]; then
    before=$(grep -rlE '\.(jpe?g)' "$REWRITE_MD" --include='*.md' 2>/dev/null | wc -l | tr -d ' ')
    find "$REWRITE_MD" -type f -name '*.md' -exec sed -i.bak -f "$SEDF" {} +
    changed=0
    while IFS= read -r bak; do
      if ! cmp -s "$bak" "${bak%.bak}"; then changed=$((changed+1)); fi
      rm -f "$bak"
    done < <(find "$REWRITE_MD" -type f -name '*.md.bak')
    echo "Markdown: rewrote jpg/jpeg image paths in $changed file(s) under $REWRITE_MD"
  else
    echo "Markdown: nothing to rewrite"
  fi
fi