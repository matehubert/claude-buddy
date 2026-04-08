#!/bin/bash
# Meshy Auto-Rig API — Rig all buddy species GLB models
# Usage: ./rig_models.sh [species...]

set -euo pipefail

API_KEY="msy_jQEg6ekZyoKs5XtR7EHdxS0AsWf4YdpCCDXE"
RIG_URL="https://api.meshy.ai/openapi/v1/rigging"
UPLOAD_URL="https://tmpfiles.org/api/v1/upload"
MODELS_DIR="$(dirname "$0")/Resources/Models"
OUTPUT_DIR="$MODELS_DIR/rigged"
TMPDIR_WORK="$OUTPUT_DIR/.tmp"
mkdir -p "$OUTPUT_DIR" "$TMPDIR_WORK"

LOGFILE="$OUTPUT_DIR/rig.log"
> "$LOGFILE"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOGFILE"; }

ALL_SPECIES=(robot cat rabbit chonk capybara dragon axolotl penguin owl turtle duck goose mushroom cactus ghost blob octopus snail)

if [ $# -gt 0 ]; then
    SPECIES_LIST=("$@")
else
    SPECIES_LIST=("${ALL_SPECIES[@]}")
fi

upload_glb() {
    local species="$1"
    local glb_path="$MODELS_DIR/${species}.glb"
    [ -f "$glb_path" ] || { log "$species: GLB not found"; return 1; }

    local resp
    resp=$(curl -s -F "file=@$glb_path" "$UPLOAD_URL")
    local url
    url=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['url'])" 2>/dev/null)
    [ -n "$url" ] || { log "$species: Upload failed"; return 1; }

    # tmpfiles.org direct download URL
    echo "$url" | sed 's|tmpfiles.org/|tmpfiles.org/dl/|'
}

create_rig() {
    local model_url="$1"
    local species="$2"
    local resp
    resp=$(curl -s -X POST "$RIG_URL" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"model_url\": \"$model_url\", \"height_meters\": 0.5}")

    # Check for error
    local err
    err=$(echo "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message',''))" 2>/dev/null)
    if [ -n "$err" ] && [ "$err" != "" ] && [ "$err" != "None" ]; then
        log "$species: API error: $err"
    fi

    echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result',''))" 2>/dev/null
}

poll_task() {
    local task_id="$1"
    local species="$2"
    local tmpfile="$TMPDIR_WORK/${species}_result.json"
    local max_wait=300
    local elapsed=0

    while [ $elapsed -lt $max_wait ]; do
        curl -s -X GET "$RIG_URL/$task_id" -H "Authorization: Bearer $API_KEY" > "$tmpfile"
        local status
        status=$(python3 -c "import json; print(json.load(open('$tmpfile')).get('status',''))" 2>/dev/null)
        local progress
        progress=$(python3 -c "import json; print(json.load(open('$tmpfile')).get('progress',0))" 2>/dev/null)

        if [ "$status" = "SUCCEEDED" ]; then
            log "$species: DONE"
            echo "$tmpfile"
            return 0
        elif [ "$status" = "FAILED" ]; then
            local err
            err=$(python3 -c "import json; print(json.load(open('$tmpfile')).get('task_error','unknown'))" 2>/dev/null)
            log "$species: FAILED — $err"
            return 1
        fi

        log "$species: $status ($progress%)"
        sleep 10
        elapsed=$((elapsed + 10))
    done
    log "$species: TIMEOUT"
    return 1
}

download_results() {
    local tmpfile="$1"
    local species="$2"

    python3 -c "
import json, subprocess, sys
d = json.load(open('$tmpfile'))
r = d['result']
anims = r.get('basic_animations') or {}
files = {
    '${species}_rigged.glb': r.get('rigged_character_glb_url',''),
    '${species}_rigged.fbx': r.get('rigged_character_fbx_url',''),
    '${species}_walking.glb': anims.get('walking_glb_url',''),
    '${species}_running.glb': anims.get('running_glb_url',''),
}
for name, url in files.items():
    if url:
        out = '$OUTPUT_DIR/' + name
        subprocess.run(['curl', '-sL', url, '-o', out], check=True)
        print(f'Downloaded {name}')
"
}

process_species() {
    local species="$1"

    if [ -f "$OUTPUT_DIR/${species}_rigged.glb" ]; then
        log "$species: Already rigged, skipping"
        return 0
    fi

    log "=== $species: Uploading ==="
    local dl_url
    dl_url=$(upload_glb "$species") || return 1
    log "$species: URL: $dl_url"

    log "=== $species: Creating rig task ==="
    local task_id
    task_id=$(create_rig "$dl_url" "$species")
    if [ -z "$task_id" ]; then
        log "$species: No task ID returned"
        return 1
    fi
    log "$species: Task ID: $task_id"

    log "=== $species: Polling ==="
    local result_file
    result_file=$(poll_task "$task_id" "$species") || return 1

    log "=== $species: Downloading ==="
    download_results "$result_file" "$species"

    log "=== $species: COMPLETE ==="
}

# Check balance
BALANCE=$(curl -s "https://api.meshy.ai/openapi/v1/balance" -H "Authorization: Bearer $API_KEY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('balance',0))")
NEED=$((${#SPECIES_LIST[@]} * 5))
log "Balance: $BALANCE credits, need ~$NEED for ${#SPECIES_LIST[@]} species"

# Process sequentially — avoid rate limits
for species in "${SPECIES_LIST[@]}"; do
    log "--- Processing: $species ---"
    process_species "$species" || log "$species: SKIPPED (failed)"
    sleep 2
done

log "=== ALL DONE ==="
ls -lh "$OUTPUT_DIR"/*_rigged.glb 2>/dev/null | tee -a "$LOGFILE" || log "No rigged files"
RIGGED=$(ls "$OUTPUT_DIR"/*_rigged.glb 2>/dev/null | wc -l | tr -d ' ')
log "Rigged: $RIGGED / ${#SPECIES_LIST[@]} species"

# Cleanup
rm -rf "$TMPDIR_WORK"
