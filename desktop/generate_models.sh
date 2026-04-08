#!/bin/bash
# Meshy API - Generate all Buddy species 3D models
# Usage: ./generate_models.sh

API_KEY="msy_jQEg6ekZyoKs5XtR7EHdxS0AsWf4YdpCCDXE"
BASE_URL="https://api.meshy.ai/openapi/v2/text-to-3d"
OUTPUT_DIR="$(dirname "$0")/Resources/Models"
mkdir -p "$OUTPUT_DIR"

LOGFILE="$OUTPUT_DIR/generate.log"
> "$LOGFILE"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOGFILE"; }

# Species prompts
declare -A PROMPTS
PROMPTS[duck]="Cute chibi kawaii rubber duck character, low-poly stylized, big round head, large glossy black eyes, small orange beak, golden yellow body, tiny orange webbed feet, small tail feathers pointing up, smooth rounded shapes, desktop pet game asset, T-pose, white background"
PROMPTS[goose]="Cute chibi kawaii goose character, low-poly stylized, big round head, large glossy black eyes, orange beak, white feathered body, slightly elongated neck, tiny orange feet, small upward tail, mischievous expression, smooth rounded shapes, desktop pet game asset, T-pose, white background"
PROMPTS[cat]="Cute chibi kawaii cat character, low-poly stylized, big round head with pointed triangle ears, large glossy black eyes, tiny pink nose, small omega-shaped mouth, gray fur body, small rounded paws, long curved tail, smooth rounded shapes, desktop pet game asset, T-pose, white background"
PROMPTS[dragon]="Cute chibi kawaii baby dragon character, low-poly stylized, big round head with two small horns, large glossy black eyes, red crimson body, tiny wings on back, small fangs, zigzag tail tip, tiny clawed feet, smooth rounded shapes, desktop pet game asset, T-pose, white background"
PROMPTS[octopus]="Cute chibi kawaii octopus character, low-poly stylized, big round dome head, large glossy black eyes, purple body, 8 short curled tentacles underneath, smooth rounded shapes, no sharp edges, desktop pet game asset, T-pose, white background"
PROMPTS[owl]="Cute chibi kawaii owl character, low-poly stylized, big round head with ear tufts, extra large round glossy black eyes with spectacle markings, brown feathered body, small beak, tiny talons, folded wings at sides, smooth rounded shapes, desktop pet game asset, T-pose, white background"
PROMPTS[penguin]="Cute chibi kawaii penguin character, low-poly stylized, big round head, large glossy black eyes, small orange beak, black and white tuxedo body, ice-blue belly accent, tiny orange feet, small flipper wings at sides, smooth rounded shapes, desktop pet game asset, T-pose, white background"
PROMPTS[turtle]="Cute chibi kawaii turtle character, low-poly stylized, big round head poking out, large glossy black eyes, green body, domed brown green shell on back with hexagon pattern, four tiny stubby legs, small tail, smooth rounded shapes, desktop pet game asset, T-pose, white background"
PROMPTS[snail]="Cute chibi kawaii snail character, low-poly stylized, two eye stalks on top with large glossy black eyes, soft beige cream body, brown spiral shell on back, flat underbody, smooth rounded shapes, desktop pet game asset, white background"
PROMPTS[ghost]="Cute chibi kawaii ghost character, low-poly stylized, big round head, large glossy black eyes, pale lavender translucent white body, wavy bottom edge instead of legs, tiny stubby arms, blushing cheeks, smooth rounded shapes, desktop pet game asset, T-pose, white background"
PROMPTS[axolotl]="Cute chibi kawaii axolotl character, low-poly stylized, big round head with pink feathery external gills on sides, large glossy black eyes, wide smile, pink body, four tiny legs, long flat tail, smooth rounded shapes, desktop pet game asset, T-pose, white background"
PROMPTS[capybara]="Cute chibi kawaii capybara character, low-poly stylized, big round head with small rounded ears, large glossy black eyes, warm brown fur body, flat wide nose, short stubby legs, no tail visible, calm relaxed expression, smooth rounded shapes, desktop pet game asset, T-pose, white background"
PROMPTS[cactus]="Cute chibi kawaii cactus character, low-poly stylized, round green body like a barrel cactus, large glossy black eyes on front, tiny dot mouth, two small arm branches on sides, small pink flower on top of head, sitting in a tiny brown pot, smooth rounded shapes, desktop pet game asset, white background"
PROMPTS[robot]="Cute chibi kawaii robot character, low-poly stylized, big boxy-round head with antenna on top, large glossy circular screen eyes with steel blue glow, small rectangular mouth, metallic gray steel blue body, blocky arms and legs, small chest panel with buttons, smooth rounded shapes, desktop pet game asset, T-pose, white background"
PROMPTS[rabbit]="Cute chibi kawaii rabbit character, low-poly stylized, big round head with two long floppy ears, large glossy black eyes, tiny pink nose, pastel pink white body, fluffy round cotton tail, small rounded paws, smooth rounded shapes, desktop pet game asset, T-pose, white background"
PROMPTS[mushroom]="Cute chibi kawaii mushroom character, low-poly stylized, large red mushroom cap with white polka dots as hat, large glossy black eyes on white stem face, tiny dot mouth, small stubby arms, no visible legs rounded bottom, smooth rounded shapes, desktop pet game asset, T-pose, white background"
PROMPTS[chonk]="Cute chibi kawaii extra chubby round cat character, low-poly stylized, extremely round spherical body, big round head with tiny ears, large glossy black eyes, warm orange tabby color, very short stubby legs barely visible, tiny tail, maximum roundness, smooth rounded shapes, desktop pet game asset, T-pose, white background"
PROMPTS[blob]="Cute chibi kawaii blob slime character, low-poly stylized, amorphous rounded teardrop shape, large glossy black eyes, light blue translucent jelly body, tiny dot mouth, no arms or legs, slight shine on surface, smooth rounded shapes, desktop pet game asset, white background"

# Create a preview task
create_preview() {
    local species="$1"
    local prompt="${PROMPTS[$species]}"
    local response
    response=$(curl -s -X POST "$BASE_URL" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"mode\": \"preview\",
            \"prompt\": \"$prompt\",
            \"ai_model\": \"meshy-6\",
            \"topology\": \"quad\",
            \"target_polycount\": 5000,
            \"symmetry_mode\": \"auto\",
            \"target_formats\": [\"glb\", \"usdz\"]
        }")
    echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result',''))" 2>/dev/null
}

# Create a refine task
create_refine() {
    local preview_id="$1"
    local response
    response=$(curl -s -X POST "$BASE_URL" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"mode\": \"refine\",
            \"preview_task_id\": \"$preview_id\",
            \"enable_pbr\": true,
            \"target_formats\": [\"glb\", \"usdz\"]
        }")
    echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result',''))" 2>/dev/null
}

# Poll task until done
poll_task() {
    local task_id="$1"
    local species="$2"
    local stage="$3"
    local max_wait=300  # 5 minutes max
    local elapsed=0

    while [ $elapsed -lt $max_wait ]; do
        local resp
        resp=$(curl -s -X GET "$BASE_URL/$task_id" \
            -H "Authorization: Bearer $API_KEY")

        local status
        status=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))" 2>/dev/null)
        local progress
        progress=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('progress',0))" 2>/dev/null)

        if [ "$status" = "SUCCEEDED" ]; then
            log "$species $stage: DONE"
            echo "$resp"
            return 0
        elif [ "$status" = "FAILED" ]; then
            log "$species $stage: FAILED"
            return 1
        fi

        log "$species $stage: $status ($progress%) ..."
        sleep 10
        elapsed=$((elapsed + 10))
    done
    log "$species $stage: TIMEOUT"
    return 1
}

# Download model file
download_model() {
    local resp="$1"
    local species="$2"
    local format="$3"

    local url
    url=$(echo "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('model_urls',{}).get('$format',''))" 2>/dev/null)

    if [ -n "$url" ] && [ "$url" != "None" ] && [ "$url" != "" ]; then
        curl -sL "$url" -o "$OUTPUT_DIR/${species}.${format}"
        log "$species: Downloaded ${species}.${format}"
    else
        log "$species: No $format URL available"
    fi
}

# Process one species (preview -> refine -> download)
process_species() {
    local species="$1"
    log "=== $species: Starting preview ==="

    local preview_id
    preview_id=$(create_preview "$species")
    if [ -z "$preview_id" ]; then
        log "$species: Failed to create preview task"
        return 1
    fi
    log "$species: Preview task ID: $preview_id"

    # Poll preview
    local preview_resp
    preview_resp=$(poll_task "$preview_id" "$species" "preview")
    if [ $? -ne 0 ]; then return 1; fi

    # Download preview GLB (for inspection)
    download_model "$preview_resp" "$species" "glb"

    log "=== $species: Starting refine ==="
    local refine_id
    refine_id=$(create_refine "$preview_id")
    if [ -z "$refine_id" ]; then
        log "$species: Failed to create refine task"
        return 1
    fi
    log "$species: Refine task ID: $refine_id"

    # Poll refine
    local refine_resp
    refine_resp=$(poll_task "$refine_id" "$species" "refine")
    if [ $? -ne 0 ]; then return 1; fi

    # Download final models
    download_model "$refine_resp" "$species" "usdz"
    download_model "$refine_resp" "$species" "glb"

    log "=== $species: COMPLETE ==="
}

# Main - process species in batches of 3 (rate limit friendly)
SPECIES_LIST=(duck goose cat dragon octopus owl penguin turtle snail ghost axolotl capybara cactus robot rabbit mushroom chonk blob)

log "Starting generation of ${#SPECIES_LIST[@]} species..."
log "Output: $OUTPUT_DIR"

BATCH_SIZE=3
for ((i=0; i<${#SPECIES_LIST[@]}; i+=BATCH_SIZE)); do
    batch=("${SPECIES_LIST[@]:i:BATCH_SIZE}")
    log "--- Batch: ${batch[*]} ---"

    # Launch batch in parallel
    pids=()
    for species in "${batch[@]}"; do
        process_species "$species" &
        pids+=($!)
    done

    # Wait for batch
    for pid in "${pids[@]}"; do
        wait "$pid"
    done

    # Small delay between batches
    if [ $((i + BATCH_SIZE)) -lt ${#SPECIES_LIST[@]} ]; then
        log "Batch done. Waiting 5s..."
        sleep 5
    fi
done

log "=== ALL DONE ==="
log "Models saved to: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"/*.usdz 2>/dev/null || log "No .usdz files found"
ls -la "$OUTPUT_DIR"/*.glb 2>/dev/null || log "No .glb files found"
