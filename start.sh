#!/bin/bash

set -e

USER=Hamonis
HOME=/home/$USER
export USER HOME

# ---------------------------------------
# Prepare directories
# ---------------------------------------
mkdir -p $HOME/.config/tigervnc
mkdir -p $HOME/.vnc
chown -R $USER:$USER $HOME

# ---------------------------------------
# Create xstartup
# ---------------------------------------
cat > $HOME/.vnc/xstartup << 'EOF'
#!/bin/bash
export DISPLAY=:1
export XDG_SESSION_TYPE=x11
export XDG_RUNTIME_DIR=/tmp/runtime-Hamonis
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Start dbus
eval $(dbus-launch --sh-syntax)
export DBUS_SESSION_BUS_ADDRESS

[ -r "$HOME/.Xresources" ] && xrdb "$HOME/.Xresources"
xsetroot -solid '#2c2c2c'

# Keep restarting XFCE if it crashes
while true; do
    startxfce4
    echo "[!] XFCE exited, restarting in 2s..."
    sleep 2
done
EOF
chmod +x $HOME/.vnc/xstartup
chown $USER:$USER $HOME/.vnc/xstartup

# ---------------------------------------
# Remove stale locks/passwords
# ---------------------------------------
echo "Cleaning up old VNC / noVNC..."
pkill -f "Xtigervnc :1"      || true
pkill -f "vncserver :1"      || true
pkill -f "websockify.*8080"  || true
sleep 2
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

# ---------------------------------------
# VNC auto-restart loop script
# ---------------------------------------
cat > /usr/local/bin/vnc-autostart.sh << 'EOF'
#!/bin/bash
export USER=Hamonis
export HOME=/home/$USER

while true; do
    echo "[*] $(date) — Starting VNC session..."
    vncserver :1 \
        -geometry 1920x1080 \
        -depth 24 \
        -localhost no \
        -fg \
        -SecurityTypes None \
        -I-KNOW-THIS-IS-INSECURE
    EXIT_CODE=$?
    echo "[!] $(date) — VNC exited (code $EXIT_CODE), restarting in 3s..."
    # Clean stale lock so vncserver can restart cleanly
    rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
    sleep 3
done
EOF
chmod +x /usr/local/bin/vnc-autostart.sh

# ---------------------------------------
# Start VNC loop as Hamonis
# ---------------------------------------
echo "Starting VNC auto-restart loop..."
su - $USER -c "/usr/local/bin/vnc-autostart.sh" &
VNC_LOOP_PID=$!

# ---------------------------------------
# Wait for VNC to actually be ready
# ---------------------------------------
echo "Waiting for VNC to be ready on port 5901..."
TIMEOUT=30
ELAPSED=0
until netstat -tlnp 2>/dev/null | grep -q 5901; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "[✗] VNC did not start within ${TIMEOUT}s"
        exit 1
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done
echo "[✓] VNC ready on port 5901 (waited ${ELAPSED}s)"

# ---------------------------------------
# Start noVNC
# ---------------------------------------
echo "Starting noVNC..."
PUBLIC_IP=$(hostname -I | awk '{print $1}')
VNC_TARGET_IP="127.0.0.1"

websockify \
    --web=/usr/share/novnc \
    --heartbeat=30 \
    ${PUBLIC_IP}:8080 \
    ${VNC_TARGET_IP}:5901 &
NOVNC_PID=$!

# ---------------------------------------
# Wait for noVNC
# ---------------------------------------
echo "Waiting for noVNC on port 8080..."
ELAPSED=0
until netstat -tlnp 2>/dev/null | grep -q 8080; do
    if [ $ELAPSED -ge 15 ]; then
        echo "[✗] noVNC did not start within 15s"
        exit 1
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done
echo "[✓] noVNC ready on port 8080 (waited ${ELAPSED}s)"

# ---------------------------------------
# calling the Start challenge (auto-detect)
# ---------------------------------------
if [ -f /root/start_challenge.sh ]; then
    bash /root/start_challenge.sh &
else
    echo "[!] start_challenge.sh not found, skipping."
fi

# ---------------------------------------
# Monitor: restart noVNC if it dies
# ---------------------------------------
monitor_novnc() {
    while true; do
        sleep 10
        if ! kill -0 $NOVNC_PID 2>/dev/null; then
            echo "[!] $(date) — noVNC died, restarting..."
            websockify \
                --web=/usr/share/novnc \
                --heartbeat=30 \
                ${PUBLIC_IP}:8080 \
                ${VNC_TARGET_IP}:5901 &
            NOVNC_PID=$!
        fi
    done
}
monitor_novnc &

# ---------------------------------------
# Summary
# ---------------------------------------
echo ""
echo "=== VNC + XFCE SETUP COMPLETE ==="
echo "Direct VNC  : ${PUBLIC_IP}:5901"
echo "noVNC URL   : http://${PUBLIC_IP}:8080"
echo ""
echo "Auto-restart : ENABLED (VNC + XFCE both restart on crash)"
echo "Security     : NO PASSWORD (NOT SAFE FOR PUBLIC USAGE)"
echo ""

# Keep container alive — wait on VNC loop
wait $VNC_LOOP_PID