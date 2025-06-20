#!/bin/sh
#
# Perform basic settings on a known IP camera
#
#
# Set custom upgrade url
#
fw_setenv upgrade 'https://github.com/OpenIPC/builder/releases/download/latest/gk7205v300_lite_camhi-RTL8188.tgz'
#
#
# Set wlan device and credentials if need
#
fw_setenv wlandev rtl8188fu-generic
#fw_setenv wlanssid Router
#fw_setenv wlanpass 12345678
#
# Set majestic settings
#
cli -s .nightMode.irCutPin1 11
cli -s .nightMode.irCutPin2 10
#cli -s .nightMode.backlightPin 14
#cli -s .nightMode.lightMonitor true
#cli -s .nightMode.minThreshold 2000
#cli -s .nightMode.maxThreshold 14000
#cli -s .audio.speakerPin 55
cli -s .video0.codec h264

echo "[customizer] Enabling USB power for WiFi module..."
devmem 0x100C0080 32 0x530
gpio clear 7
sleep 3

echo "[customizer] Loading rtl8188fu driver..."
modprobe 8188fu

# Проверка наличия интерфейса wlan0
if ip link show wlan0 > /dev/null 2>&1; then
    echo "[customizer] wlan0 detected, preparing Wi-Fi config..."

    SSID=$(fw_printenv -n wlanssid)
    PASS=$(fw_printenv -n wlanpass)

    if [ -n "$SSID" ] && [ -n "$PASS" ]; then
        echo "[customizer] Using SSID=$SSID"

        WPA_CONF="/tmp/wpa.conf"
        wpa_passphrase "$SSID" "$PASS" > "$WPA_CONF"

        echo "[customizer] Starting wpa_supplicant..."
        wpa_supplicant -B -i wlan0 -c "$WPA_CONF"

        sleep 3

        echo "[customizer] Requesting DHCP..."
        udhcpc -i wlan0
    else
        echo "[customizer] Missing wlanssid or wlanpass env variables."
    fi
else
    echo "[customizer] wlan0 not detected — check USB or driver"
fi

exit 0
