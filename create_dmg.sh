#!/bin/bash
# ==============================================================================
# TTL 65 - DMG Disk İmajı Oluşturucu
# ==============================================================================

set -e

APP_NAME="TTL 65"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="TTL-65-Kurulum.dmg"
STAGING_DIR="/tmp/ttl65_dmg_staging"

echo "🔨 Uygulama derleniyor..."
./build_app.sh

echo "📦 DMG hazırlık klasörü oluşturuluyor..."
rm -rf "$STAGING_DIR" "$DMG_NAME"
mkdir -p "$STAGING_DIR"

# Uygulamayı kopyala
cp -R "$APP_BUNDLE" "$STAGING_DIR/"

# Applications kısayolu oluştur (Drag & Drop için)
ln -s /Applications "$STAGING_DIR/Applications"

# Bilgilendirme notu ekle
cat << 'EOF' > "$STAGING_DIR/Beni Oku.txt"
==============================================
       TTL 65 Yöneticisi Kurulumu
==============================================

1. 'TTL 65.app' simgesini 'Applications' (Uygulamalar) klasörüne sürükleyip bırakın.
2. Uygulamayı ilk kez açtığınızda ekrandaki 'TTL'yi 65 Yap' butonuna basın.
3. Otomatik ve şifresiz çalışması için uygulama içerisindeki 'Şifresiz Tek Tık Modu'na bir kez izin verin.
4. Artık Mac'iniz her açıldığında ve Hotspot'a her bağlandığınızda TTL değeriniz otomatik olarak 65 olacaktır!

İyi kullanımlar!
EOF

echo "💿 DMG oluşturuluyor (${DMG_NAME})..."
hdiutil create \
    -volname "TTL 65 Kurulum" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_NAME"

rm -rf "$STAGING_DIR"

echo "✅ DMG başarıyla oluşturuldu: ${DMG_NAME}"
