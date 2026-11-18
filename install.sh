#!/bin/bash
# ==============================================================================
# TTL 65 - macOS Otomatik Kurulum ve Yapılandırma Scripti
# ==============================================================================

set -e

# Renkler
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "\n${BLUE}${BOLD}======================================================${NC}"
echo -e "${CYAN}${BOLD}        🚀 TTL 65 Yöneticisi Kurulum Sihirbazı         ${NC}"
echo -e "${BLUE}${BOLD}======================================================${NC}\n"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="TTL 65"
APP_BUNDLE="${APP_NAME}.app"
TARGET_DIR="/Applications"
TARGET_APP="${TARGET_DIR}/${APP_BUNDLE}"
BUNDLE_ID="com.metinmeliksah.ttl65"

# 1. Uygulama derlenmiş mi kontrol et, yoksa derle
if [ ! -d "$APP_BUNDLE" ]; then
    echo -e "${YELLOW}⚡ '${APP_BUNDLE}' bulunamadı, önce Release modunda derleniyor...${NC}"
    ./build_app.sh
fi

# 2. Çalışan eski instance varsa kapat
if pgrep -x "TTLChanger" > /dev/null 2>&1; then
    echo -e "${YELLOW}🔄 Çalışmakta olan eski TTL 65 uygulaması kapatılıyor...${NC}"
    killall "TTLChanger" 2>/dev/null || true
    sleep 1
fi

# 3. /Applications klasörüne kopyala
echo -e "${CYAN}📦 Uygulama '${TARGET_DIR}' dizinine yükleniyor...${NC}"
rm -rf "$TARGET_APP"
cp -R "$APP_BUNDLE" "$TARGET_DIR/"

# 4. macOS LaunchServices ve Spotlight İndeksleme (Aramada çıkması için kritik adımlar)
echo -e "${CYAN}🔍 macOS Spotlight ve Launchpad dizini güncelleniyor...${NC}"
echo -n "APPL????" > "${TARGET_APP}/Contents/PkgInfo"
xattr -cr "$TARGET_APP" 2>/dev/null || true
codesign --force --deep --sign - "$TARGET_APP" 2>/dev/null || true
touch "$TARGET_APP"

# LaunchServices veritabanına doğrudan kaydet
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R -trusted "$TARGET_APP" 2>/dev/null || true

# Spotlight'a uygulamayı anında indekslet
mdimport "$TARGET_APP" 2>/dev/null || true

# Finder ve Launchpad arayüzünü yenile
osascript -e 'tell application "Finder" to update (POSIX file "/Applications/TTL 65.app")' 2>/dev/null || true
killall Dock 2>/dev/null || true

# 5. Sudoers Yetkilendirmesi (Şifresiz Tek Tık Modu)
echo -e "\n${BOLD}🔐 Şifresiz TTL Değiştirme Yetkisi (Önerilen)${NC}"
echo -e "macOS'in açılışta ve ağ değişiminde her seferinde şifre sormaması için"
echo -e "sadece TTL değiştirme komutuna özel güvenli bir sudoers kuralı eklensin mi? (E/h)"
read -r -p "Seçiminiz [E/h]: " sudo_choice
sudo_choice=${sudo_choice:-E}

if [[ "$sudo_choice" =~ ^[EeYy]$ ]]; then
    echo -e "${CYAN}🔑 Tek seferlik yönetici şifreniz istenebilir...${NC}"
    sudo mkdir -p /etc/sudoers.d
    echo '%admin ALL=(ALL) NOPASSWD: /usr/sbin/sysctl -w net.inet.ip.ttl=*' | sudo tee /etc/sudoers.d/ttl_changer > /dev/null
    sudo chmod 0440 /etc/sudoers.d/ttl_changer
    echo -e "${GREEN}✓ Şifresiz mod yetkilendirmesi başarıyla yapıldı.${NC}"
else
    echo -e "${YELLOW}⚠️  Şifresiz mod atlandı. TTL değiştiğinde macOS şifre/Touch ID soracaktır.${NC}"
fi

# 6. Sistem Açılışında Otomatik Başlatma (LaunchAgent)
echo -e "\n${BOLD}🚀 Sistem Başlangıcında Çalıştırma${NC}"
echo -e "Mac'inizi her açtığınızda uygulamanın otomatik olarak başlamasını ister misiniz? (E/h)"
read -r -p "Seçiminiz [E/h]: " autostart_choice
autostart_choice=${autostart_choice:-E}

LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="${LAUNCH_AGENTS_DIR}/${BUNDLE_ID}.plist"

if [[ "$autostart_choice" =~ ^[EeYy]$ ]]; then
    mkdir -p "$LAUNCH_AGENTS_DIR"
    cat << EOF > "$PLIST_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${BUNDLE_ID}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${TARGET_APP}/Contents/MacOS/TTLChanger</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
EOF
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    launchctl load "$PLIST_FILE" 2>/dev/null || true
    echo -e "${GREEN}✓ Mac başlangıcına eklendi (${PLIST_FILE}).${NC}"
else
    if [ -f "$PLIST_FILE" ]; then
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
        rm -f "$PLIST_FILE"
    fi
    echo -e "${YELLOW}⚠️  Otomatik başlangıç devre dışı bırakıldı.${NC}"
fi

# 7. TTL'yi 65 yap ve Uygulamayı Başlat
echo -e "\n${CYAN}⚡ TTL değeri doğrudan 65 yapılıyor...${NC}"
if [ -f "/etc/sudoers.d/ttl_changer" ]; then
    sudo -n sysctl -w net.inet.ip.ttl=65 >/dev/null 2>&1 || true
else
    osascript -e 'do shell script "sysctl -w net.inet.ip.ttl=65" with administrator privileges' >/dev/null 2>&1 || true
fi

echo -e "${GREEN}✓ Güncel TTL: $(sysctl -n net.inet.ip.ttl)${NC}"

# 8. Uygulamayı Aç
echo -e "${CYAN}🖥️  '${TARGET_APP}' başlatılıyor...${NC}"
open "$TARGET_APP"

echo -e "\n${GREEN}${BOLD}======================================================${NC}"
echo -e "${GREEN}${BOLD}       🎉 TEBRİKLER! KURULUM BAŞARIYLA TAMAMLANDI     ${NC}"
echo -e "${GREEN}${BOLD}======================================================${NC}"
echo -e "📍 Uygulama Konumu : ${BOLD}${TARGET_APP}${NC}"
echo -e "⚡ Güncel TTL       : ${BOLD}$(sysctl -n net.inet.ip.ttl)${NC}"
echo -e "🔍 Arama Adı       : Spotlight veya Launchpad'e 'TTL' veya 'TTL 65' yazarak bulabilirsiniz."
echo -e "💡 Menü Çubuğu     : Ekranın sağ üst köşesinde kalkan simgesi yer alır."
echo -e "🗑️  Kaldırmak için  : ${BOLD}./uninstall.sh${NC}\n"
