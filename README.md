# hpeg9-pcie-nvme
Fix HP G9 Power Loss Issue on PCI-e NVME
🔧 Fix for NVMe Disappearing from PCIe – Power Management Patch
This script addresses a common issue on Linux systems where NVMe drives randomly disappear from the PCIe bus — especially after periods of inactivity or system sleep.

🧩 Problem
Linux enables power saving on non-critical PCIe devices by default. While this behavior is useful for saving energy, it often causes issues with NVMe drives — leading to:

NVMe drive disappearing from the OS

Drive not showing in BIOS after a soft reboot

Drive only coming back after a full power cycle

✅ Solution
This script disables PCIe power saving for all devices, ensuring NVMe drives stay awake and connected at all times.

🔍 What the script does
bash
Copy
Edit
for dev in /sys/bus/pci/devices/*/power/control; do
  echo on | sudo tee $dev
done
This command iterates through all PCIe devices and sets their power management policy to on, disabling power-saving mode (auto) across the board.

🚀 Usage
bash
Copy
Edit
git clone https://github.com/woshka/hpeg9-pcie-nvme
cd hpeg9-pcie-nvme
chmod +x fix.sh
sudo ./fix.sh
💡 Tip
To make this change persistent across reboots, you can add the command to a startup script like /etc/rc.local, or create a systemd service.

