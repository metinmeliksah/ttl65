<a id="english"></a>

<div align="center">

<img src="Resources/logo.png" alt="Melikşah" width="220" />

# ⚡ TTL 65 Manager (macOS)

### *Lightweight macOS Utility for IPv4 TTL (`net.inet.ip.ttl`) Management & Network Inspection*

[![Swift](https://img.shields.io/badge/Swift-6.0%2B-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-000000?style=for-the-badge&logo=apple&logoColor=white)](https://apple.com/macos)
[![Release](https://img.shields.io/github/v/release/metinmeliksah/ttl65?style=for-the-badge&color=007AFF)](https://github.com/metinmeliksah/ttl65/releases)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=for-the-badge)](#english)

<p align="center">
  <b>A clean, native macOS window & menu bar utility for inspecting network interfaces and configuring the system's IPv4 Time-to-Live (<code>net.inet.ip.ttl</code>) kernel parameter between <code>64</code> and <code>65</code>.</b>
</p>

🇬🇧 **English** • [🇹🇷 Türkçe](#turkce)

[Overview](#overview) • [How It Works](#how-ttl-works) • [Features](#features) • [Installation](#installation) • [Build from Source](#build-from-source) • [Disclaimer](#disclaimer)

---

</div>

<a id="overview"></a>
## 💡 Overview

**TTL 65 Manager** provides an effortless GUI and menu bar controller for macOS users who frequently work with multi-hop network topologies, bridged routers, lab environments, or mobile tethering setups and want to monitor or adjust the system's default IPv4 TTL value without manually running terminal commands.

<a id="how-ttl-works"></a>
### 🔍 How TTL Works (RFC 791)

Under the IPv4 specification (**RFC 791**), **Time to Live (TTL)** is a standard IP header field that limits a packet's hop count across routers and gateways. Each router or intermediary hop along the path decrements the packet's TTL by `1`:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 🟠 DEFAULT macOS CONFIGURATION (TTL = 64)                                   │
│                                                                             │
│  [ Mac (TTL: 64) ] ──(Packet)──> [ Intermediate Hop / Gateway (-1) ]        │
│                                      └──> Outbound Packet TTL = 63          │
├─────────────────────────────────────────────────────────────────────────────┤
│ 🟢 CUSTOM TTL PROFILE (TTL = 65)                                            │
│                                                                             │
│  [ Mac (TTL: 65) ] ──(Packet)──> [ Intermediate Hop / Gateway (-1) ]        │
│                                      └──> Outbound Packet TTL = 64          │
└─────────────────────────────────────────────────────────────────────────────┘
```

1. **Standard macOS Default:** macOS initializes outgoing IPv4 packets with `net.inet.ip.ttl = 64`.
2. **Intermediary Hop Behavior:** When traffic passes through an intermediary router, bridge, or Personal Hotspot gateway, that device decrements the TTL by `1`, resulting in an outbound TTL of `63`.
3. **One-Hop Offset (`TTL = 65`):** Setting `net.inet.ip.ttl = 65` compensates for a single local routing hop, keeping outbound downstream packets at `64`. You can also revert to the macOS default (`64`) in one click at any time.

---

<a id="features"></a>
## ✨ Features

- ⚡ **Auto-Apply on Launch:** Optionally configures TTL to `65` as soon as the app starts.
- 🌐 **Smart Network Listener:** Uses Apple's `NWPathMonitor` to detect network transitions and automatically verify or apply TTL `65` on reconnect.
- 📱 **Gateway & Tethering Link Detection:** Identifies Wi-Fi, Wired Ethernet, and Personal Hotspot / tethering gateways (`172.20.10.x`, `192.168.43.x`, `192.168.44.x`, or constrained/expensive paths).
- 📊 **Live Network Inspector:** Displays live TTL value, connection status, active interface (`en0`, etc.), local IPv4 address, and default gateway.
- 🛡️ **Menu Bar Widget:** Lives quietly in the macOS menu bar for instant status checks and one-click toggling.
- 🔑 **Optional Passwordless Mode (`sudoers`):** Grants tightly scoped permission strictly for `/usr/sbin/sysctl -w net.inet.ip.ttl=*` via `/etc/sudoers.d/ttl_changer`, eliminating repeated Touch ID or password prompts (with an AppleScript admin prompt fallback if disabled).
- 🚀 **Launch at Login:** Native macOS login item integration via `SMAppService`.
- 🔄 **One-Click Reset (`64`):** Restore the standard macOS TTL value anytime.

---

<a id="installation"></a>
## 🚀 Installation

### Method 1: DMG Disk Image (Recommended) 💿

<p align="left">
  <a href="https://github.com/metinmeliksah/ttl65/releases/latest/download/TTL-65-Kurulum.dmg">
    <img src="https://img.shields.io/badge/Download-TTL--65--Kurulum.dmg-007AFF?style=for-the-badge&logo=apple&logoColor=white" alt="Download TTL 65 DMG" />
  </a>
  <a href="https://github.com/metinmeliksah/ttl65/releases">
    <img src="https://img.shields.io/badge/All_Releases-GitHub-333333?style=for-the-badge&logo=github&logoColor=white" alt="GitHub Releases" />
  </a>
</p>

1. Download the latest **`TTL-65-Kurulum.dmg`** from [**Direct Download**](https://github.com/metinmeliksah/ttl65/releases/latest/download/TTL-65-Kurulum.dmg) or the [**Releases**](https://github.com/metinmeliksah/ttl65/releases) page.
2. Open the downloaded `.dmg` file.
3. Drag **`TTL 65.app`** into the **Applications** folder.
4. Launch the app and click **"TTL'yi 65 Yap"** (*Set TTL to 65*).

> [!NOTE]
> The application user interface is currently in Turkish.

### Method 2: Terminal Setup Wizard ⚡

Clone the repository and run the automated installation script:

```bash
git clone https://github.com/metinmeliksah/ttl65.git
cd ttl65
./install.sh
```

**What does `install.sh` do?**
- Builds the project in Release mode and installs it to `/Applications/TTL 65.app`.
- Clears quarantine attributes, applies ad-hoc code signing, and refreshes LaunchServices / Spotlight indexing.
- Optionally creates `/etc/sudoers.d/ttl_changer` for passwordless `sysctl` TTL updates.
- Optionally registers a `LaunchAgent` (`~/Library/LaunchAgents/com.metinmeliksah.ttl65.plist`) to run at login.
- Applies `TTL = 65` and launches the application.

---

## 🖥️ Interface Overview

- **TTL Status Card:** Large numeric readout showing `65` (Custom TTL Profile Active) or `64` (Standard macOS Default), with primary **Set TTL to 65** and **Reset to Default (64)** controls.
- **Current Network Card:** Live connection badge, connection type, network interface, Mac local IPv4 address, and default gateway IP.
- **Automation & Settings Card:** Toggles for *Auto-set on launch*, *Auto-set on network connect*, *Launch at login*, and *Passwordless One-Click Mode* (`İzin Ver` / `İzni Kaldır`).

---

<a id="build-from-source"></a>
## 🛠️ Build from Source

To compile and package the application manually:

```bash
# Build Swift binary in release mode
swift build -c release

# Create the .app bundle with icons and Info.plist
./build_app.sh

# Optionally package into a distributable DMG
./create_dmg.sh
```

---

## 🗑️ Uninstall

To completely remove the app, login configuration, and `sudoers` rule, and restore the default macOS TTL (`64`):

```bash
./uninstall.sh
```

---

## 🔬 Technical Details

- **Language & Concurrency:** Swift 6.0+ (`Strict Concurrency` compliant, tested with Swift 6.2)
- **UI Framework:** SwiftUI & AppKit (`macOS 14.0+` Sonoma or later)
- **Reading TTL:** Direct kernel C API via `sysctlbyname("net.inet.ip.ttl", ...)` with zero subprocess overhead
- **Writing TTL:** `sudo -n /usr/sbin/sysctl -w net.inet.ip.ttl=<value>` (if configured) or `NSAppleScript` administrator privilege fallback
- **Network Monitoring:** Apple `Network.framework` (`NWPathMonitor`), BSD `getifaddrs`, and `/sbin/route -n get default`
- **Privacy & Security:** Runs 100% offline. Contains zero telemetry, analytics, or external network requests.

---

<a id="disclaimer"></a>
## ⚖️ Disclaimer

This software is developed strictly for **educational, network diagnostic, research, and local system parameter configuration** purposes. Time-to-Live (TTL) is a standard IPv4 header parameter defined in **RFC 791**. Users are solely responsible for ensuring that their use of this software complies with all applicable laws, network policies, and third-party Terms of Service (ToS) or carrier agreements. This software is provided **"AS IS"** without warranty of any kind, and the developer assumes no liability for any consequences arising from its use.

---

## 📄 License

Distributed under the [MIT License](LICENSE).

---
---

<a id="turkce"></a>

<div align="center">

# ⚡ TTL 65 Yöneticisi (macOS)

### *macOS İçin Hafif IPv4 TTL (`net.inet.ip.ttl`) Yapılandırma ve Ağ İzleme Aracı*

[🇬🇧 English (Default)](#english) • 🇹🇷 **Türkçe**

[Genel Bakış](#tr-overview) • [Nasıl Çalışır?](#tr-how-ttl-works) • [Özellikler](#tr-features) • [Kurulum](#tr-installation) • [Kaynak Koddan Derleme](#tr-build) • [Yasal Uyarı](#tr-disclaimer)

</div>

<a id="tr-overview"></a>
## 💡 Genel Bakış

**TTL 65 Yöneticisi**, çoklu atlamalı (multi-hop) ağ topolojileri, köprülenmiş yönlendiriciler, test/laboratuvar ortamları veya Kişisel Erişim Noktası (Hotspot / Tethering) bağlantılarıyla çalışan macOS kullanıcılarının, terminal komutlarıyla uğraşmadan sistemin IPv4 TTL parametresini (`net.inet.ip.ttl`) anlık olarak izlemesini ve yönetmesini sağlayan modern bir menü çubuğu ve kontrol paneli aracıdır.

<a id="tr-how-ttl-works"></a>
### 🔍 TTL Nasıl Çalışır? (RFC 791)

IPv4 standardında (**RFC 791**) tanımlanan **TTL (Time to Live)**, bir ağ paketinin yönlendiriciler üzerinden geçebileceği maksimum atlama (hop) sayısını belirleyen standart IP başlık alanıdır. Paket geçtiği her yönlendirici veya ağ geçidinde TTL değeri `1` azaltılır:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 🟠 VARSAYILAN macOS YAPILANDIRMASI (TTL = 64)                               │
│                                                                             │
│  [ Mac (TTL: 64) ] ──(Paket)──> [ Aracı Ağ Geçidi / Hotspot (-1) ]          │
│                                     └──> Çıkan Paket TTL = 63               │
├─────────────────────────────────────────────────────────────────────────────┤
│ 🟢 ÖZEL TTL PROFİLİ (TTL = 65)                                              │
│                                                                             │
│  [ Mac (TTL: 65) ] ──(Paket)──> [ Aracı Ağ Geçidi / Hotspot (-1) ]          │
│                                     └──> Çıkan Paket TTL = 64               │
└─────────────────────────────────────────────────────────────────────────────┘
```

1. **Standart macOS Değeri:** macOS, giden IPv4 paketlerini varsayılan olarak `net.inet.ip.ttl = 64` ile gönderir.
2. **Aracı Ağ Geçidi Davranışı:** Paket bir yönlendirici veya erişim noktası üzerinden aktarılırken TTL değeri `1` eksilerek `63` olur.
3. **Tek Atlama Telafisi (`TTL = 65`):** Çıkış TTL değerini `65` olarak ayarladığınızda, tek bir yerel atlama sonrasında giden paketlerin TTL değeri `64` olarak devam eder. İstediğiniz an tek tıkla macOS varsayılanı olan `64` değerine dönebilirsiniz.

---

<a id="tr-features"></a>
## ✨ Özellikler

- ⚡ **Otomatik Açılış:** İsteğe bağlı olarak uygulama açılır açılmaz TTL değerini otomatik `65` yapar.
- 🌐 **Akıllı Ağ Dinleyicisi:** Apple `NWPathMonitor` altyapısıyla ağ değişimlerini izler ve bağlantıda TTL'yi otomatik kontrol edip ayarlar.
- 📱 **Ağ ve Hotspot Algılama:** Wi-Fi, Kablolu Ethernet ve Kişisel Erişim Noktası ağ geçitlerini (`172.20.10.x`, `192.168.43.x`, `192.168.44.x` veya kısıtlı/tarifeli yollar) otomatik tespit eder.
- 📊 **Canlı Ağ Kartı:** Mevcut TTL değerini, bağlantı durumunu, arayüzü (`en0` vb.), yerel IPv4 adresini ve ağ geçidini (Gateway) anlık gösterir.
- 🛡️ **Menü Çubuğu (Menu Bar) Simgesi:** Ekranın üst menü çubuğundan tek tıkla TTL durumunu görmenizi ve değiştirmenizi sağlar.
- 🔑 **İsteğe Bağlı Şifresiz Tek Tık Modu (`sudoers`):** Sadece `/usr/sbin/sysctl -w net.inet.ip.ttl=*` komutu için `/etc/sudoers.d/ttl_changer` üzerinden yetki vererek sonraki tüm işlemlerde Touch ID veya şifre sormadan sessizce çalışır.
- 🚀 **Mac Başlangıcında Çalıştırma:** `SMAppService` üzerinden yerel giriş ögesi desteği sunar.
- 🔄 **Tek Tıkla Varsayılana Dönüş (`64`):** İstediğiniz zaman macOS standart değeri olan `64`'e geri dönebilirsiniz.

---

<a id="tr-installation"></a>
## 🚀 Kurulum

### Yöntem 1: DMG Disk İmajı ile (Önerilen) 💿

<p align="left">
  <a href="https://github.com/metinmeliksah/ttl65/releases/latest/download/TTL-65-Kurulum.dmg">
    <img src="https://img.shields.io/badge/İndir-TTL--65--Kurulum.dmg-007AFF?style=for-the-badge&logo=apple&logoColor=white" alt="TTL 65 İndir" />
  </a>
  <a href="https://github.com/metinmeliksah/ttl65/releases">
    <img src="https://img.shields.io/badge/Tüm_Sürümler-Releases-333333?style=for-the-badge&logo=github&logoColor=white" alt="GitHub Sürümleri" />
  </a>
</p>

1. [**Doğrudan İndir**](https://github.com/metinmeliksah/ttl65/releases/latest/download/TTL-65-Kurulum.dmg) bağlantısından veya [**Releases**](https://github.com/metinmeliksah/ttl65/releases) sayfasından güncel **`TTL-65-Kurulum.dmg`** dosyasını indirin.
2. İndirilen DMG dosyasına çift tıklayın.
3. **`TTL 65.app`** simgesini **Applications (Uygulamalar)** klasörüne sürükleyip bırakın.
4. Uygulamayı açın ve **"TTL'yi 65 Yap"** butonuna basın.

### Yöntem 2: Terminal Kurulum Sihirbazı ⚡

```bash
git clone https://github.com/metinmeliksah/ttl65.git
cd ttl65
./install.sh
```

**`install.sh` neler yapar?**
- Projeyi Release modunda derler ve `/Applications/TTL 65.app` dizinine yükler.
- Karantina özniteliklerini temizler, ad-hoc imzalar ve LaunchServices / Spotlight dizinini yeniler.
- İsteğe bağlı olarak şifresiz TTL değişimi için `/etc/sudoers.d/ttl_changer` kuralını ekler.
- İsteğe bağlı olarak Mac açılışında başlatma (`LaunchAgent`) tanımlar.
- TTL'yi `65` yapar ve uygulamayı başlatır.

---

## 🖥️ Arayüz Özeti

- **TTL Durum Kartı:** Büyük puntoyla mevcut TTL değerini (`65` Özel TTL Profili Aktif veya `64` Standart macOS Değeri) ve ana aksiyon butonlarını gösterir.
- **Mevcut Ağ Bağlantısı:** Bağlantı durumu, bağlantı tipi, ağ arayüzü, yerel IP (Mac) ve ağ geçidi (Gateway) bilgilerini canlı sunar.
- **Otomasyon & Kurulum Ayarları:** *Uygulama açılınca otomatik 65 yap*, *Ağa bağlanınca otomatik 65 yap*, *Mac açıldığında otomatik başlat* ve *Şifresiz Tek Tık Modu* seçeneklerini içerir.

---

<a id="tr-build"></a>
## 🛠️ Kaynak Koddan Manuel Derleme

```bash
# Projeyi release modunda derle
swift build -c release

# Uygulama paketini (.app) ve ikonları hazırla
./build_app.sh

# DMG disk imajı oluştur
./create_dmg.sh
```

---

## 🗑️ Kaldırma (Uninstall)

Uygulamayı, başlangıç servisini ve `sudoers` iznini sistemden tamamen kaldırıp TTL değerini `64`'e döndürmek için:

```bash
./uninstall.sh
```

---

## 🔬 Teknik Detaylar

- **Dil & Eşzamanlılık:** Swift 6.0+ (`Strict Concurrency` uyumlu, Swift 6.2 ile test edildi)
- **Arayüz:** SwiftUI & AppKit (`macOS 14.0+` Sonoma ve üzeri)
- **TTL Okuma:** `sysctlbyname("net.inet.ip.ttl", ...)` çekirdek C API'si ile sıfır alt işlem maliyeti
- **TTL Yazma:** `sudo -n /usr/sbin/sysctl -w net.inet.ip.ttl=<değer>` veya `NSAppleScript` yönetici yetkisi fallback
- **Ağ İzleme:** Apple `Network.framework` (`NWPathMonitor`), BSD `getifaddrs` ve `/sbin/route -n get default`
- **Gizlilik:** Tamamen çevrimdışı (offline) çalışır. Telemetri, analitik veya dış ağ isteği içermez.

---

<a id="tr-disclaimer"></a>
## ⚖️ Yasal Uyarı

Bu yazılım yalnızca **eğitim, ağ tanılama (diagnostics), araştırma ve yerel sistem ağ parametrelerini yapılandırma** amacıyla geliştirilmiştir. Time-to-Live (TTL), **RFC 791** standardında tanımlanmış standart bir IPv4 başlık parametresidir. Yazılımın kullanımının yürürlükteki mevzuata, ağ politikalarına ve üçüncü taraf hizmet/abonelik sözleşmelerine (ToS) uygunluğunu sağlamak tamamen kullanıcının kendi sorumluluğundadır. Yazılım [MIT Lisansı](LICENSE) kapsamında **"OLDUĞU GİBİ"** sunulmakta olup geliştirici hiçbir sorumluluk kabul etmez.

---

<div align="center">
  <sub>MIT License • Built for clean, native macOS networking control.</sub>
</div>
