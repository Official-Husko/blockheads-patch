#!/usr/bin/env bash
set -euo pipefail

rm -rf bh-work patched-unsigned.apk patched-aligned.apk patched.apk patch.keystore

echo "[*] Decoding APK..."
apktool d -f base.apk -o bh-work

TARGET="$(find bh-work -type f \
  -path '*/com/noodlecake/noodlewebview/NoodleWebView$1.smali' \
  -print -quit)"

if [[ -z "${TARGET}" ]]; then
    echo "Could not find NoodleWebView\$1.smali" >&2
    exit 1
fi

echo "[*] Patching: ${TARGET}"

python3 - "$TARGET" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()

pattern = re.compile(
    r'(?ms)^(\.method[^\n]*\srun\(\)V\s*\n).*?^\.end method\s*$'
)

replacement = (
    r'\1'
    '    .locals 0\n'
    '\n'
    '    return-void\n'
    '.end method'
)

patched, count = pattern.subn(replacement, text, count=1)

if count != 1:
    raise SystemExit(f"Expected one run()V method, patched {count}")

path.write_text(patched)
print("Patched NoodleWebView$1.run()V -> return-void")
PY

echo "[*] Rebuilding..."
apktool b bh-work -o patched-unsigned.apk

echo "[*] Aligning..."
zipalign -f -p 4 patched-unsigned.apk patched-aligned.apk

echo "[*] Creating signing key..."
keytool -genkeypair \
    -keystore patch.keystore \
    -storepass android \
    -keypass android \
    -alias blockheads \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=Blockheads Patch" \
    >/dev/null 2>&1

echo "[*] Signing..."
apksigner sign \
    --ks patch.keystore \
    --ks-key-alias blockheads \
    --ks-pass pass:android \
    --key-pass pass:android \
    --out patched.apk \
    patched-aligned.apk

apksigner verify --verbose patched.apk

echo "[+] Created patched.apk"
