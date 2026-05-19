#!/bin/bash
# ── Auto-detect challenge directory ──────────────────────────────────────────
SEARCH_ROOTS=("/root" "/home" "/opt" "/srv" "/app")
RUN_SCRIPT=""
CHALLENGE_DIR=""

for root in "${SEARCH_ROOTS[@]}"; do
    found=$(find "$root" -maxdepth 3 -name "*.sh" -type f -perm /111 2>/dev/null \
        | grep -v "start_challenge.sh\|start.sh\|xstartup\|vnc-autostart.sh" \
        | head -n 1)
    if [ -n "$found" ]; then
        RUN_SCRIPT=$(basename "$found")
        CHALLENGE_DIR=$(dirname "$found")
        break
    fi
done

# Fallback: check current working directory
if [ -z "$CHALLENGE_DIR" ]; then
    found=$(find "$(pwd)" -maxdepth 1 -name "*.sh" -type f -perm /111 2>/dev/null \
        | grep -v "start_challenge.sh\|start.sh\|xstartup\|vnc-autostart.sh" \
        | head -n 1)
    if [ -n "$found" ]; then
        RUN_SCRIPT=$(basename "$found")
        CHALLENGE_DIR=$(pwd)
    fi
fi

if [ -z "$CHALLENGE_DIR" ] || [ -z "$RUN_SCRIPT" ]; then
    echo "[✗] Could not find any executable .sh script to run"
    exit 1
fi

LOG="${CHALLENGE_DIR}/challenge.log"

echo "=================================================="
echo "Starting Challenge services"
echo "=================================================="
echo "[*] Detected challenge dir : $CHALLENGE_DIR"
echo "[*] Detected run script    : $RUN_SCRIPT"

cd "$CHALLENGE_DIR" || {
    echo "[✗] Cannot enter $CHALLENGE_DIR"
    exit 1
}

# Clean npm cache before handing off to run_challenge.sh
rm -rf /root/.npm/_cacache

# Start challenge
chmod +x "./$RUN_SCRIPT"
echo "[*] Starting challenge..." | tee "$LOG"
nohup bash "./$RUN_SCRIPT" >> "$LOG" 2>&1 &
CH_PID=$!
echo "[*] PID: $CH_PID" | tee -a "$LOG"
sleep 5
if ps -p $CH_PID > /dev/null; then
    echo "[✓] Challenge running (PID: $CH_PID)"
else
    echo "[✗] Challenge crashed"
    tail -n 50 "$LOG"
    exit 1
fi

echo ""
echo "[✓] Challenge log: $LOG"