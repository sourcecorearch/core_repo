#!/bin/bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

DB=core_repo.db.tar.gz
FILES=core_repo.files.tar.gz

STRICT=0
case "${1:-}" in
  "") ;;
  --strict) STRICT=1 ;;
  *) echo "Uso: $0 [--strict]" >&2; exit 2 ;;
esac

is_lfs_pointer() {
  head -c 200 -- "$1" 2>/dev/null | grep -aq '^version https://git-lfs.github.com/spec/v1'
}

shopt -s nullglob
packages=()
pointers=()
for pkg in *.pkg.tar.zst; do
  if is_lfs_pointer "$pkg"; then
    pointers+=("$pkg")
  else
    packages+=("$pkg")
  fi
done

if ((${#pointers[@]} > 0)); then
  if ((STRICT)); then
    echo "ERROR: paquetes LFS sin materializar:" >&2
    printf '  - %s\n' "${pointers[@]}" >&2
    echo "Ejecuta 'git lfs pull' o vuelve a lanzar sin --strict." >&2
    exit 1
  fi
  echo "⚠️  Paquetes LFS omitidos (sus entradas actuales se conservan):"
  printf '   - %s\n' "${pointers[@]}"
  echo "   Si cambió su versión, ejecuta 'git lfs pull' para indexarlos."
fi

if ((${#packages[@]} == 0)); then
  echo "ERROR: no hay paquetes reales para indexar." >&2
  exit 1
fi

echo "🔎 Validando paquetes..."
for pkg in "${packages[@]}"; do
  if ! bsdtar -xOf "$pkg" .PKGINFO >/dev/null 2>&1; then
    echo "ERROR: paquete inválido o corrupto: $pkg" >&2
    exit 1
  fi
done

tmpdir=$(mktemp -d "$PWD/.repo-tmp.XXXXXX")
trap 'rm -rf -- "$tmpdir"' EXIT

# Partimos de la DB actual para conservar las entradas de paquetes LFS.
if [[ -f $DB ]]; then
  cp -- "$DB" "$tmpdir/$DB"
fi
if [[ -f $FILES ]]; then
  cp -- "$FILES" "$tmpdir/$FILES"
fi

# Quitar entradas que apunten a archivos que ya no existen.
if [[ -f $tmpdir/$DB ]]; then
  mkdir -p "$tmpdir/prune"
  bsdtar -xf "$tmpdir/$DB" -C "$tmpdir/prune"
  for desc in "$tmpdir"/prune/*/desc; do
    [[ -f $desc ]] || continue
    filename=$(awk '/^%FILENAME%$/{getline; print; exit}' "$desc")
    [[ -n $filename ]] || continue
    if [[ ! -f $filename ]]; then
      pkgname=$(awk '/^%NAME%$/{getline; print; exit}' "$desc")
      echo "🧹 Quitando entrada obsoleta: $pkgname ($filename)"
      repo-remove "$tmpdir/$DB" "$pkgname"
    fi
  done
fi

echo "📦 Running repo-add..."
repo-add -R "$tmpdir/$DB" "${packages[@]}"

# Verificación antes de publicar nada.
[[ -s $tmpdir/$DB ]] || { echo "ERROR: la nueva DB está vacía." >&2; exit 1; }
[[ -s $tmpdir/$FILES ]] || { echo "ERROR: la nueva base de archivos está vacía." >&2; exit 1; }
bsdtar -tf "$tmpdir/$DB" >/dev/null

echo "🔁 Reemplazando base de datos..."
mv -f -- "$tmpdir/$DB" "$DB"
mv -f -- "$tmpdir/$FILES" "$FILES"

rm -f -- core_repo.db core_repo.files
cp -- "$DB" core_repo.db
cp -- "$FILES" core_repo.files

echo "#####"
echo "Repo Update!!"
echo "#####"
