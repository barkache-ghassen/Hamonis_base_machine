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

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

[ -r "$HOME/.Xresources" ] && xrdb "$HOME/.Xresources"
xsetroot -solid grey

# Start XFCE session
startxfce4
EOF

chmod +x $HOME/.vnc/xstartup
chown $USER:$USER $HOME/.vnc/xstartup

# Remove password file because no password is used
rm -f $HOME/.vnc/passwd

# ---------------------------------------
# Kill old processes
# ---------------------------------------
echo "Cleaning up old VNC / noVNC..."
pkill -f "vncserver :1" || true
pkill -f "Xtigervnc" || true
pkill -f "websockify.*8080" || true

sleep 2
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

# ---------------------------------------
# AUTO-RESTART VNC LOOP
# (Auto login again after logout)
# ---------------------------------------
echo "Starting VNC (auto-restart enabled)..."

cat > /usr/local/bin/vnc-autostart.sh << 'EOF'
#!/bin/bash
export USER=Hamonis
export HOME=/home/$USER

while true; do
    echo "Starting new VNC session..."
    vncserver :1 \
        -geometry 1920x1080 \
        -depth 24 \
        -localhost no \
        -SecurityTypes None \
        -I-KNOW-THIS-IS-INSECURE

    echo "VNC server stopped. Restarting in 2 seconds..."
    sleep 2
done
EOF

chmod +x /usr/local/bin/vnc-autostart.sh

# Run VNC auto restart loop as the user
su - $USER -c "/usr/local/bin/vnc-autostart.sh" &

sleep 3

# ---------------------------------------
# Check VNC server
# ---------------------------------------
echo "Checking VNC..."
if netstat -tlnp | grep 5901 > /dev/null; then
    echo "✓ VNC running on port 5901"
else
    echo "✗ VNC FAILED TO START!"
    exit 1
fi

# ---------------------------------------
# Start noVNC Websockify
# ---------------------------------------
# echo "Starting noVNC..."
# CONTAINER_IP="127.0.0.1"

# websockify --web=/usr/share/novnc 0.0.0.0:8080 $CONTAINER_IP:5901 &
# sleep 2


echo "Starting noVNC..."

# VNC server itself listens on localhost:5901
VNC_TARGET_IP="127.0.0.1"

# Get container's primary IP (eth0) – used only for noVNC HTTP
PUBLIC_IP=$(hostname -I | awk '{print $1}')

# noVNC listens ONLY on the container IP, NOT on 127.0.0.1
websockify --web=/usr/share/novnc ${PUBLIC_IP}:8080 ${VNC_TARGET_IP}:5901 &
sleep 2




# ---------------------------------------
# Verify noVNC
# ---------------------------------------
echo "Checking noVNC..."
if netstat -tlnp | grep 8080 > /dev/null; then
    echo "✓ noVNC running on port 8080"
else
    echo "✗ noVNC FAILED TO START!"
    exit 1
fi

# ---------------------------------------
# DONE
# ---------------------------------------
echo ""
echo "=== VNC + XFCE SETUP COMPLETE ==="
echo "Direct VNC : $CONTAINER_IP:5901"
echo "noVNC URL  : http://$CONTAINER_IP:8080/vnc.html"
echo ""
echo "Auto-relogin: ENABLED (VNC restarts after logout)"
echo "Security: NO PASSWORD (NOT SAFE FOR PUBLIC USAGE)"
echo ""

wait
