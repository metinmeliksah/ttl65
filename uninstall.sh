#!/bin/bash
# ==============================================================================
# TTL 65 - Kaldırma (Uninstall) Scripti
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "\n${RED}${BOLD}======================================================${NC}"
echo -e "${RED}${BOLD}        🗑️  TTL 65 Kaldırma Sihirbazı                 ${NC}"
echo -e "${RED}${BOLD}======================================================${NC}\n"

# 1. Uygulamayı durdur
if pgrep -x "TTLChanger" > /dev/null 2>&1; then
    echo -e "${YELLOW}🛑 Çalışan TTL 65 kapatılıyor...${NC}"
    killall "TTLChanger" 2>/dev/null || true
fi

# 2. LaunchAgent kaldır
for PLIST_FILE in "$HOME/Library/LaunchAgents/com.metinmeliksah.ttl65.plist" "$HOME/Library/LaunchAgents/com.metin.ttlchanger.plist"; do
    if [ -f "$PLIST_FILE" ]; then
        echo -e "${CYAN}🧹 Başlangıç ögesi (${PLIST_FILE}) kaldırılıyor...${NC}"
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
        rm -f "$PLIST_FILE"
    fi
done

# 3. /Applications klasöründen sil
TARGET_APP="/Applications/TTL 65.app"
if [ -d "$TARGET_APP" ]; then
    echo -e "${CYAN}🗑️  '${TARGET_APP}' siliniyor...${NC}"
    rm -rf "$TARGET_APP"
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$TARGET_APP" 2>/dev/null || true
    killall Dock 2>/dev/null || true
fi

# 4. Sudoers dosyasını sil
if [ -f "/etc/sudoers.d/ttl_changer" ]; then
    echo -e "${CYAN}🔐 Sudoers yetkilendirme dosyası kaldırılıyor...${NC}"
    sudo rm -f "/etc/sudoers.d/ttl_changer" 2>/dev/null || osascript -e 'do shell script "rm -f /etc/sudoers.d/ttl_changer" with administrator privileges' 2>/dev/null || true
fi

# 5. TTL'yi standart 64'e geri çevir
echo -e "${CYAN}🔄 TTL değeri varsayılan macOS değerine (64) döndürülüyor...${NC}"
if [ "$EUID" -eq 0 ]; then
    sysctl -w net.inet.ip.ttl=64 >/dev/null 2>&1 || true
else
    sudo sysctl -w net.inet.ip.ttl=64 >/dev/null 2>&1 || osascript -e 'do shell script "sysctl -w net.inet.ip.ttl=64" with administrator privileges' >/dev/null 2>&1 || true
fi

echo -e "\n${GREEN}${BOLD}======================================================${NC}"
echo -e "${GREEN}${BOLD}     ✅ TTL 65 ve tüm bileşenleri tamamen kaldırıldı.  ${NC}"
echo -e "${GREEN}${BOLD}======================================================${NC}"
echo -e "⚡ Güncel TTL: $(sysctl -n net.inet.ip.ttl) (macOS Varsayılanı)\n"
