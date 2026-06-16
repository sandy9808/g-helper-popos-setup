#!/usr/bin/env bash
set -euo pipefail

# Prevent in-app updater from replacing the Pop 22.04-compatible local build.

CONFIG_DIR="$HOME/.config/ghelper"
CONFIG="$CONFIG_DIR/config.json"

mkdir -p "$CONFIG_DIR"

if [[ ! -f "$CONFIG" ]]; then
  cat > "$CONFIG" <<'EOF'
{
  "skip_update_prompt": 1
}
EOF
  echo "==> Created $CONFIG with skip_update_prompt=1"
  exit 0
fi

if grep -q '"skip_update_prompt"' "$CONFIG"; then
  python3 - <<'PY'
import json, os
path = os.path.expanduser("~/.config/ghelper/config.json")
with open(path) as f:
    data = json.load(f)
data["skip_update_prompt"] = 1
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print("==> Set skip_update_prompt=1 in", path)
PY
else
  # append key before closing brace (simple/robust for small config)
  python3 - <<'PY'
import json, os
path = os.path.expanduser("~/.config/ghelper/config.json")
with open(path) as f:
    data = json.load(f)
data["skip_update_prompt"] = 1
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print("==> Added skip_update_prompt=1 to", path)
PY
fi