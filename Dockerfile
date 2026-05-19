# Base image
FROM debian:13-slim

USER root

# Configure APT sources for Debian 13 (trixie)
RUN cat > /etc/apt/sources.list << 'EOF'
deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
EOF

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    xfce4 \
    xfce4-terminal \
    xfce4-taskmanager \
    xfce4-screenshooter \
    xfce4-notifyd \
    librsvg2-common \
    tumbler \
    tigervnc-standalone-server tigervnc-common tigervnc-tools \
    novnc websockify \
    x11-xserver-utils dbus-x11 xfonts-base \
    libnspr4 libnss3 xdg-utils libx11-xcb1 \
    libxkbfile1 libsecret-1-0 libxss1 \
    libstdc++6 libuuid1 \
    curl wget git nano sudo net-tools \
    python3 python3-venv \
    nodejs npm \
    # build-essential \
    firefox-esr \
    papirus-icon-theme \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ── Install renamed/transitional packages with fallbacks (Debian 13 t64 ABI) ─
RUN apt-get update && \
    for pkg in \
        "libasound2t64|libasound2" \
        "libcurl4t64|libcurl4" \
        "libgtk-3-0t64|libgtk-3-0" \
        "gosu|gosu" \
    ; do \
        primary="${pkg%%|*}"; \
        fallback="${pkg##*|}"; \
        if apt-cache show "$primary" > /dev/null 2>&1; then \
            apt-get install --no-install-recommends -y "$primary"; \
        elif apt-cache show "$fallback" > /dev/null 2>&1; then \
            apt-get install --no-install-recommends -y "$fallback"; \
        else \
            echo "[!] Neither $primary nor $fallback found, skipping."; \
        fi; \
    done \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# # ── Install Go from official upstream (always latest stable) ──────────────────
# RUN GO_VERSION=$(curl -sSL https://go.dev/VERSION?m=text | head -n1) \
#     && echo "Installing Go ${GO_VERSION}..." \
#     && curl -sSL "https://dl.google.com/go/${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz \
#     && rm -rf /usr/local/go \
#     && tar -C /usr/local -xzf /tmp/go.tar.gz \
#     && rm /tmp/go.tar.gz \
#     && /usr/local/go/bin/go version


# # ── Install Rust via rustup (system-wide) ─────────────────────────────────────
# ENV RUSTUP_HOME=/usr/local/rustup \
#     CARGO_HOME=/usr/local/cargo

# RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
#     | sh -s -- -y --no-modify-path --default-toolchain stable \
#     && chmod -R a+rx /usr/local/rustup /usr/local/cargo \
#     && /usr/local/cargo/bin/rustc --version \
#     && /usr/local/cargo/bin/cargo --version

# # ── Export Go + Rust paths ────────────────────────────────────────────────────
# ENV PATH=/usr/local/go/bin:/usr/local/cargo/bin:$PATH   # rust and go are heavy install them when needed 

# ── Install VS Code ───────────────────────────────────────────────────────────
RUN wget -q -O /tmp/vscode.deb https://update.code.visualstudio.com/latest/linux-deb-x64/stable \
    && dpkg -i /tmp/vscode.deb || apt-get -fy install \
    && rm -f /tmp/vscode.deb \
    && rm -rf /var/lib/apt/lists/*

# Disable logout button inside VNC session
RUN printf '#!/bin/sh\n# Disabled inside VNC container\nexit 0\n' > /usr/local/bin/xfce4-session-logout \
    && chmod +x /usr/local/bin/xfce4-session-logout

# ── Create non-root user ──────────────────────────────────────────────────────
RUN useradd -m -s /bin/bash Hamonis && passwd -d Hamonis

# ── Desktop shortcuts ─────────────────────────────────────────────────────────
COPY code.desktop /home/Hamonis/Desktop/code.desktop

RUN mkdir -p /home/Hamonis/Desktop \
    && cp /usr/share/applications/firefox-esr.desktop /home/Hamonis/Desktop/ \
    && chmod +x /home/Hamonis/Desktop/*.desktop \
    && chown -R Hamonis:Hamonis /home/Hamonis/Desktop

# ── VNC xstartup ─────────────────────────────────────────────────────────────
RUN mkdir -p /home/Hamonis/.vnc && \
    cat << 'EOF' > /home/Hamonis/.vnc/xstartup
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
EOF
RUN chmod +x /home/Hamonis/.vnc/xstartup

# ── XFCE config ───────────────────────────────────────────────────────────────
RUN mkdir -p /home/Hamonis/.config/xfce4/xfconf/xfce-perchannel-xml
COPY xfce4-desktop.xml /home/Hamonis/.config/xfce4/xfconf/xfce-perchannel-xml/
COPY xsettings.xml     /home/Hamonis/.config/xfce4/xfconf/xfce-perchannel-xml/

# ── Assets ────────────────────────────────────────────────────────────────────
COPY Hamonis_background.png /home/Hamonis/Hamonis_background.png
COPY index.html /usr/share/novnc/index.html

# ── Harden noVNC ─────────────────────────────────────────────────────────────
RUN cat << 'EOF' > /tmp/novnc_protect.js
<script>
  if (window.top === window.self) {
    window.addEventListener("DOMContentLoaded", function () {
      document.body.innerHTML =
        "<h2 style='color:white;background:black;padding:20px;text-align:center'>Access Denied</h2>";
    });
    throw new Error("Direct access blocked");
  }
  window.addEventListener("DOMContentLoaded", function () {
    document.addEventListener("contextmenu", function (e) { e.preventDefault(); });
    document.addEventListener("keydown", function (e) {
      if (e.key === "F12") e.preventDefault();
      if (e.ctrlKey && e.shiftKey && ["I", "J", "C"].includes(e.key.toUpperCase())) e.preventDefault();
      if (e.ctrlKey && e.key.toUpperCase() === "U") e.preventDefault();
    });
  });
</script>
EOF

RUN sed -i '/<head>/r /tmp/novnc_protect.js' /usr/share/novnc/vnc.html \
    && mv /usr/share/novnc/vnc.html /usr/share/novnc/hiddenvnc-43950.html \
    && rm /tmp/novnc_protect.js

# ── VS Code launcher ──────────────────────────────────────────────────────────
COPY code.desktop /usr/share/applications/code.desktop
COPY code.sh /usr/bin/code
RUN chmod +x /usr/bin/code

# ── Startup scripts ───────────────────────────────────────────────────────────
COPY start.sh /root/start.sh
RUN chmod +x /root/start.sh

COPY start_challenge.sh /root/start_challenge.sh
RUN chmod +x /root/start_challenge.sh

# ── Fix ownership ─────────────────────────────────────────────────────────────
RUN chown -R Hamonis:Hamonis /home/Hamonis

EXPOSE 5901 8080

CMD ["/root/start.sh"]