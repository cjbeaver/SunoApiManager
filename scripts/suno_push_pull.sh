#!/usr/bin/env bash
set -euo pipefail

BASE="http://localhost:8080"
#SUNOAPILOGS="~/SunoApiManager/logs/suno_manager.log"
SUNOAPILOGS="~/git_repos/SunoApiManager/logs/suno_manager.log"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <xlsx_file>"
    echo "Example: $0 songs.xlsx"
    exit 1
fi

XLSX="$1"
if [ ! -f "$XLSX" ]; then
    echo "Error: file not found: $XLSX"
    exit 1
fi

## 1. Upload Excel
echo "Uploading Excel..."
UPLOAD=$(curl -s -X POST "$BASE/api/upload-excel" -F "file=@$XLSX")
echo "$UPLOAD" | jq .
## 2. Save songs
echo "Saving songs..."
SAVE_RESP=$(curl -s -X POST "$BASE/api/save-songs" \
  -H "Content-Type: application/json" \
  -d "$(echo "$UPLOAD" | jq '{songs: .songs, batch_name: ("batch_" + (now | strftime("%Y%m%d_%H%M%S")))}')")
echo "$SAVE_RESP" | jq .
## 3. Start generation
echo "Starting generation..."
curl -s -X POST "$BASE/api/start-generation" | jq .
## 4. Print monitoring instructions
echo "=== MONITORING INSTRUCTIONS ==="
echo "Poll status: curl -s -X POST $BASE/api/poll-status | jq ."
echo "Or check feed: curl -s \"$BASE/suno/feed?page=1\" | jq '. | length' clips"
echo ""
echo "When status shows 'complete', download with:"
echo "  curl -s -X POST $BASE/api/download-completed"
echo ""
echo "View stats anytime: curl -s $BASE/api/stats | jq ."
sleep 2
echo
echo "Monitoring logs: $SUNOAPILOGS"
echo
sleep 3
tail -f $SUNOAPILOGS
