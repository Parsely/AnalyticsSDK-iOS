#!/bin/bash
#
# Generates ParselyHosts.json from the site IDs declared in parsely-apikeys.json.
#
# Add this as a Run Script Build Phase on your app target, above Copy Bundle Resources:
#
#   Script:       bash "${SRCROOT}/Scripts/parsely-bake-hosts.sh"
#   Input Files:  $(SRCROOT)/parsely-apikeys.json
#   Output Files: $(SRCROOT)/ParselyHosts.json
#
# The build fails if a declared site ID cannot be resolved. If Parse.ly is unreachable but the
# existing generated file already covers every declared site ID, the build warns and continues
# rather than failing on a transient outage.

set -euo pipefail

API_BASE="${PARSELY_API_BASE:-https://dash.parsely.com/api}"
DECLARATION="${SRCROOT}/parsely-apikeys.json"
ARTIFACT="${SRCROOT}/ParselyHosts.json"
PY=/usr/bin/python3

fail() { echo "error: [Parse.ly] $1" >&2; exit 1; }
warn() { echo "warning: [Parse.ly] $1" >&2; }

[ -f "$DECLARATION" ] || fail "parsely-apikeys.json not found at ${DECLARATION}. Create it with {\"apikeys\": [\"yoursite.com\"]}."

# Python's own traceback would be noise in the Xcode build log; the fail message says it all.
SITE_IDS=$("$PY" -c 'import json,sys; print("\n".join(json.load(open(sys.argv[1])).get("apikeys", [])))' "$DECLARATION" 2>/dev/null) \
    || fail "parsely-apikeys.json is not valid JSON."
[ -n "$SITE_IDS" ] || fail "parsely-apikeys.json declares no site IDs. Add every site ID your app tracks."

HOSTS=""
NETWORK_FAILED=0

while IFS= read -r SITE_ID; do
    [ -n "$SITE_ID" ] || continue
    ENCODED=$("$PY" -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$SITE_ID")

    set +e
    RESPONSE=$(/usr/bin/curl -sS --max-time 20 -w '\n%{http_code}' "${API_BASE}/${ENCODED}/jess/sdk_config/" 2>/dev/null)
    CURL_STATUS=$?
    set -e

    if [ $CURL_STATUS -ne 0 ]; then
        NETWORK_FAILED=1
        break
    fi

    STATUS="${RESPONSE##*$'\n'}"
    BODY="${RESPONSE%$'\n'*}"

    case "$STATUS" in
        200) : ;;
        404) fail "Parse.ly does not recognise the site ID '${SITE_ID}'. Check it against your Parse.ly dashboard." ;;
        *)   fail "Parse.ly returned HTTP ${STATUS} for '${SITE_ID}'." ;;
    esac

    HOST=$("$PY" -c 'import json,sys; print(json.loads(sys.argv[1]).get("pixel_host",""))' "$BODY" 2>/dev/null) \
        || fail "Could not parse Parse.ly's response for '${SITE_ID}'."
    [ -n "$HOST" ] || fail "Parse.ly returned no host for '${SITE_ID}'."
    HOSTS="${HOSTS}${SITE_ID}	${HOST}
"
done <<< "$SITE_IDS"

if [ $NETWORK_FAILED -eq 1 ]; then
    # Network failure only. A site ID Parse.ly actively rejects still fails the build above.
    if "$PY" - "$DECLARATION" "$ARTIFACT" <<'PY'
import json, sys
try:
    declared = set(json.load(open(sys.argv[1])).get("apikeys", []))
    baked = json.load(open(sys.argv[2]))
except Exception:
    sys.exit(1)
sys.exit(0 if baked.get("version") == 1 and declared and declared <= set(baked.get("hosts", {})) else 1)
PY
    then
        warn "Could not reach Parse.ly. Using the existing ParselyHosts.json, which covers every declared site ID."
        exit 0
    fi
    fail "Could not reach Parse.ly, and ParselyHosts.json does not cover every declared site ID."
fi

printf '%s' "$HOSTS" | "$PY" -c '
import datetime, json, sys
hosts = dict(line.split("\t") for line in sys.stdin.read().splitlines() if line)
json.dump({
    "version": 1,
    "generated_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "hosts": hosts,
}, open(sys.argv[1], "w"), indent=2, sort_keys=True)
open(sys.argv[1], "a").write("\n")
' "$ARTIFACT"

echo "[Parse.ly] Wrote ${ARTIFACT}"
