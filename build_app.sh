#!/bin/bash
set -e

APP_NAME="TTL 65"
BUNDLE_NAME="${APP_NAME}.app"
BUILD_DIR=".build/release"
BUNDLE_ID="com.metinmeliksah.ttl65"

echo "🔨 Proje Release modunda derleniyor..."
swift build -c release

echo "📦 Uygulama paketi (${BUNDLE_NAME}) oluşturuluyor..."
rm -rf "${BUNDLE_NAME}"
mkdir -p "${BUNDLE_NAME}/Contents/MacOS"
mkdir -p "${BUNDLE_NAME}/Contents/Resources"

# Binary'i kopyala
cp "${BUILD_DIR}/TTLChanger" "${BUNDLE_NAME}/Contents/MacOS/TTLChanger"
chmod +x "${BUNDLE_NAME}/Contents/MacOS/TTLChanger"

# İkonu kopyala
if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "${BUNDLE_NAME}/Contents/Resources/AppIcon.icns"
fi

# Logoyu kopyala
if [ -f "Resources/logo.png" ]; then
    cp "Resources/logo.png" "${BUNDLE_NAME}/Contents/Resources/logo.png"
elif [ -f "logo.png" ]; then
    cp "logo.png" "${BUNDLE_NAME}/Contents/Resources/logo.png"
fi

# PkgInfo dosyası (macOS LaunchServices'in uygulamayı tanıması için kritik)
echo -n "APPL????" > "${BUNDLE_NAME}/Contents/PkgInfo"

# Info.plist oluştur (Spotlight ve Launchpad indeksleme anahtarları dahil)
cat << EOF > "${BUNDLE_NAME}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>TTLChanger</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>TTL 65</string>
    <key>CFBundleDisplayName</key>
    <string>TTL 65</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>MDItemKeywords</key>
    <string>TTL, TTL65, TTL 65, Network, Sysctl, IPv4, macOS, Tethering, Utility</string>
</dict>
</plist>
EOF

echo "🔏 Uygulama imzalanıyor (ad-hoc)..."
codesign --force --deep --sign - "${BUNDLE_NAME}"

echo "✅ Tamamlandı! '${BUNDLE_NAME}' hazır."
