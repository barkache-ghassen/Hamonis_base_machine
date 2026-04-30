# Base image
FROM debian:13

USER root

# Configure APT sources for Debian 13 (trixie)
RUN cat > /etc/apt/sources.list << 'EOF'
deb http://deb.debian.org/debian trixie main contrib non-free
deb http://deb.debian.org/debian trixie-updates main contrib non-free
deb http://deb.debian.org/debian-security trixie-security main contrib non-free
EOF

# Install desktop, VNC, noVNC, tools, Papirus icons
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    xfce4 xfce4-goodies \
    tigervnc-standalone-server tigervnc-common tigervnc-tools \
    novnc websockify \
    x11-xserver-utils dbus-x11 xfonts-base \
    curl wget git nano sudo gosu \
    libasound2 libnspr4 libnss3 xdg-utils libx11-xcb1 \
    libxkbfile1 libsecret-1-0 libgtk-3-0 libxss1 \
    libcurl4 libstdc++6 libuuid1 \
    firefox-esr \
    net-tools \
    papirus-icon-theme \
    && apt-get clean && rm -rf /var/lib/apt/lists/*



RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv nodejs npm 

RUN node -v && npm -v && npx -v


# Install VS Code
RUN wget -O /tmp/vscode.deb https://update.code.visualstudio.com/latest/linux-deb-x64/stable && \
    dpkg -i /tmp/vscode.deb || apt-get -fy install && \
    rm -f /tmp/vscode.deb
RUN printf '#!/bin/sh\n# Disabled inside VNC container\nexit 0\n' > /usr/local/bin/xfce4-session-logout && \
    chmod +x /usr/local/bin/xfce4-session-logout

# Create non-root user
RUN useradd -m -s /bin/bash Hamonis && passwd -d Hamonis


COPY code.desktop /home/Hamonis/Desktop/code.desktop

RUN mkdir -p /home/Hamonis/Desktop \
    && cp /usr/share/applications/firefox-esr.desktop /home/Hamonis/Desktop/ \
    && chmod +x /home/Hamonis/Desktop/*.desktop \
    && chown -R Hamonis:Hamonis /home/Hamonis/Desktop



# Create VNC xstartup script (XFCE session)
RUN mkdir -p /home/Hamonis/.vnc && \
    cat << 'EOF' > /home/Hamonis/.vnc/xstartup
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
EOF
RUN chmod +x /home/Hamonis/.vnc/xstartup

# XFCE config (wallpaper + icon theme)
RUN mkdir -p /home/Hamonis/.config/xfce4/xfconf/xfce-perchannel-xml
COPY xfce4-desktop.xml /home/Hamonis/.config/xfce4/xfconf/xfce-perchannel-xml/
COPY xsettings.xml /home/Hamonis/.config/xfce4/xfconf/xfce-perchannel-xml/

# Background image
COPY Hamonis_background.png /home/Hamonis/Hamonis_background.png

# Custom noVNC landing page (auto-redirect)

COPY index.html /usr/share/novnc/index.html
# RUN sed -i 's|</head>|<style>#noVNC_control_bar_anchor,#noVNC_control_bar,#noVNC_toggle_control_bar_button{display:none !important;}</style></head>|' /usr/share/novnc/vnc.html

# Harden noVNC: block direct access to vnc.html and disable right-click / inspect
RUN cat << 'EOF' > /tmp/novnc_protect.js
<script>
  // Block direct access: only allow when embedded in an iframe
  if (window.top === window.self) {
    window.addEventListener("DOMContentLoaded", function () {
      document.body.innerHTML =
        "<h2 style='color:white;background:black;padding:20px;text-align:center'>Access Denied</h2>";
    });
    throw new Error("Direct access blocked");
  }

  // When loaded inside iframe: block right-click + some inspect shortcuts
  window.addEventListener("DOMContentLoaded", function () {
    // Disable right-click inside noVNC page (canvas, buttons, etc.)
    document.addEventListener("contextmenu", function (e) {
      e.preventDefault();
    });

    // Disable F12, Ctrl+Shift+I/J/C, Ctrl+U
    document.addEventListener("keydown", function (e) {
      // F12
      if (e.key === "F12") {
        e.preventDefault();
      }

      // Ctrl+Shift+I / J / C
      if (e.ctrlKey && e.shiftKey && ["I", "J", "C"].includes(e.key.toUpperCase())) {
        e.preventDefault();
      }

      // Ctrl+U (view source)
      if (e.ctrlKey && e.key.toUpperCase() === "U") {
        e.preventDefault();
      }
    });
  });
</script>
EOF

# Inject the script block right after <head> in vnc.html

RUN sed -i '/<head>/r /tmp/novnc_protect.js' /usr/share/novnc/vnc.html

RUN mv /usr/share/novnc/vnc.html /usr/share/novnc/hiddenvnc-43950.html





# Fix VS Code launcher:
COPY code.desktop /usr/share/applications/code.desktop
COPY code.sh /usr/bin/code
RUN chmod +x /usr/bin/code

# Start script that launches VNC + noVNC
COPY start.sh /root/start.sh
RUN chmod +x /root/start.sh

# Ensure everything in home belongs to the user
RUN chown -R Hamonis:Hamonis /home/Hamonis

# Expose VNC + noVNC ports
EXPOSE 5901 8080

# Default command
CMD ["/root/start.sh"]
