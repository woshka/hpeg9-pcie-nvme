#!/bin/bash

SERVICE_NAME="woshka-pcie-fix"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
SCRIPT_PATH="/usr/local/bin/${SERVICE_NAME}"

# Handle -d parameter (disable and revert)
if [[ "$1" == "-d" ]]; then
  echo "🧹 Reverting Woshka PCIe Fix..."

  if systemctl is-enabled --quiet "$SERVICE_NAME"; then
    systemctl disable "$SERVICE_NAME" >/dev/null 2>&1
    echo "🛑 Service disabled."
  fi

  if [ -f "$SERVICE_PATH" ]; then
    rm -f "$SERVICE_PATH"
    echo "🗑 Service file removed: $SERVICE_PATH"
  fi

  if [ -f "$SCRIPT_PATH" ]; then
    rm -f "$SCRIPT_PATH"
    echo "🗑 Script removed: $SCRIPT_PATH"
  fi

  echo ""
  echo "🔄 All changes reverted. PCIe power saving settings may return on reboot."
  echo "👋 Woshka is resting now. Bye!"
  exit 0
fi

# Normal mode – apply fix
echo "🔧 Woshka PCIe Power Saver Fix"
echo "------------------------------"

progress_bar() {
  local width=40
  local duration=3
  local steps=$((width * 10))
  local delay=$(echo "$duration / $steps" | bc -l)

  echo -n "🌀 Woshka is fixing things: ["
  for ((i = 0; i <= steps; i++)); do
    percent=$((i * 100 / steps))
    filled=$((i * width / steps))
    empty=$((width - filled))
    bar=$(printf "%0.s#" $(seq 1 $filled))
    space=$(printf "%0.s " $(seq 1 $empty))
    echo -ne "\r🌀 Woshka is fixing things: [$bar$space] $percent%"
    sleep "$delay"
  done
  echo ""
}

progress_bar

count=0
for dev in /sys/bus/pci/devices/*/power/control; do
  echo on > "$dev" 2>/dev/null && ((count++))
done

echo "✅ Fixed $count PCIe devices."

if [ -f "$SERVICE_PATH" ]; then
  echo "ℹ️  Systemd service already exists and is enabled: $SERVICE_NAME"
else
  echo "🛠 Creating systemd service to persist fix after reboot..."

  cat <<EOF > "$SERVICE_PATH"
[Unit]
Description=Disable PCIe Power Saving (Woshka Fix)
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'for dev in /sys/bus/pci/devices/*/power/control; do echo on > \$dev; done'
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

  echo "#!/bin/bash
for dev in /sys/bus/pci/devices/*/power/control; do echo on > \$dev; done" > "$SCRIPT_PATH"
  chmod +x "$SCRIPT_PATH"

  systemctl daemon-reload
  systemctl enable "$SERVICE_NAME"

  echo "✅ Service '${SERVICE_NAME}.service' created and enabled."
fi

# Check current status
echo ""
echo "🔍 Verifying current PCIe power state..."

total=0
bad=0
for dev in /sys/bus/pci/devices/*/power/control; do
  state=$(cat "$dev")
  ((total++))
  if [[ "$state" != "on" ]]; then
    ((bad++))
  fi
done

if [[ "$bad" -eq 0 ]]; then
  echo "✅ All PCIe devices are in performance mode. You're all good!"
else
  echo "⚠️  $bad out of $total devices are still in power saving mode (auto)."
  echo "👉 Try rebooting to apply the fix permanently."
fi

echo ""
echo "🔁 Waiting for reboot to take effect..."
echo "👁️  Woshka is watching. You're good to go. ✅"
