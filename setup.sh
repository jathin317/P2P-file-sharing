#!/bin/bash
echo "Configuring P2P File Sharing"

echo "Configuring Firewall Discovery Rules"
sudo ufw allow 8080/udp comment 'P2P App Discovery'
SUBNET=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | head -n 1)
if [ -n "$SUBNET" ]; then
  echo "Configuring firewall transfer rules for subnet: $SUBNET"
  sudo ufw allow from $SUBNET to any proto tcp comment 'P2P App File Transfer'
else
  echo "⚠️ Warning: Could not automatically detect local subnet. TCP transfers might be blocked."
fi

echo "Creating desktop shortcut..."
SHARE_DIR="$HOME/.local/share/applications"
mkdir -p "$SHARE_DIR"

cat << EOF > "$SHARE_DIR/p2p-file-sharing.desktop"
[Desktop Entry]
Version=1.0
Name=P2P File Sharing
Comment=Lightning-fast local network file sharing
Exec=$(pwd)/p2p_file_sharing
Icon=$(pwd)/assets/icon.png
Terminal=false
Type=Application
Categories=Network;FileTransfer;
EOF

chmod +x "$SHARE_DIR/p2p-file-sharing.desktop"

echo "✅ Setup complete! You can now launch 'P2P File Sharing' from your app menu."