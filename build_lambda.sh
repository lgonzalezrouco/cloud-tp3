set -euo pipefail

SRC_DIR="${1:-./lambda}"
ZIP_PATH="${2:-./lambda.zip}"

if [ ! -d "${SRC_DIR}" ]; then
  echo "{\"ok\": \"false\", \"msg\": \"src dir not found: ${SRC_DIR}\"}"
  exit 0
fi

cd "${SRC_DIR}"

if command -v npm >/dev/null 2>&1; then
  if [ -f "package-lock.json" ] || [ -f "npm-shrinkwrap.json" ]; then
    npm ci --omit=dev > /dev/null 2>&1
  else
    npm install --production > /dev/null 2>&1
  fi
else
  echo "{\"ok\": \"false\", \"msg\": \"npm not found\"}"
  exit 0
fi

if ! command -v zip >/dev/null 2>&1; then
  echo "{\"ok\": \"false\", \"msg\": \"zip not found\"}"
  exit 0
fi

rm -f "${ZIP_PATH}"

ZIP_ABS="$(cd "$(dirname "${ZIP_PATH}")" && pwd)/$(basename "${ZIP_PATH}")"
zip -r "${ZIP_ABS}" . > /dev/null 2>&1

echo "{\"ok\": \"true\", \"zip\": \"${ZIP_ABS}\"}"