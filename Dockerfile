FROM jrei/systemd-ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install packages (NO snapd needed)
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies \
    tigervnc-standalone-server \
    novnc websockify \
    sudo xterm vim net-tools curl wget git tzdata \
    dbus-x11 x11-utils x11-xserver-utils x11-apps \
    software-properties-common

# Install Firefox (PPA method)
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox && \
    apt update -y && apt install -y firefox

# XFCE default session
RUN echo "startxfce4" > /root/.vnc/xstartup && chmod +x /root/.vnc/xstartup

# Create VNC password (optional but better)
RUN mkdir -p /root/.vnc && \
    echo "1234" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# Create systemd service for VNC
RUN bash -c 'cat > /etc/systemd/system/vncserver.service <<EOF
[Unit]
Description=VNC Server
After=network.target

[Service]
Type=forking
User=root
ExecStart=/usr/bin/vncserver :1 -geometry 1024x768 -localhost no
ExecStop=/usr/bin/vncserver -kill :1

[Install]
WantedBy=multi-user.target
EOF'

# Create systemd service for noVNC
RUN bash -c 'cat > /etc/systemd/system/novnc.service <<EOF
[Unit]
Description=noVNC Web Access
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/websockify --web=/usr/share/novnc/ 6080 localhost:5901

[Install]
WantedBy=multi-user.target
EOF'

# Enable services
RUN systemctl enable vncserver
RUN systemctl enable novnc

EXPOSE 5901
EXPOSE 6080

CMD ["/sbin/init"]
