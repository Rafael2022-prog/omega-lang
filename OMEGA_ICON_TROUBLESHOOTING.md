# OMEGA IDE Icon Troubleshooting Guide

## Masalah: Ikon OMEGA Muncul di VS Code Tapi Tidak di TRAE IDE

### Penyebab Utama
Perbedaan konfigurasi antara VS Code dan TRAE IDE:
- **VS Code**: Menggunakan ekstensi resmi dengan `package.json` yang terkonfigurasi dengan benar
- **TRAE IDE**: Menggunakan konfigurasi manual yang perlu diatur secara khusus

### Solusi yang Telah Diterapkan

1. **File Konfigurasi yang telah dibuat/diperbarui:**
   - `.trae/file-associations.json` - Asosiasi file untuk ekstensi .mega
   - `.trae/icon-theme.json` - Tema ikon khusus untuk OMEGA
   - `.trae/settings.json` - Pengaturan IDE untuk bahasa OMEGA
   - `.trae/extension.json` - Konfigurasi ekstensi TRAE
   - `.trae/language-configuration.json` - Konfigurasi sintaksis OMEGA

2. **File Ikon yang Tersedia:**
   - `omega-vscode-extension/images/omega-file-icon-mega.svg` - Ikon utama file
   - `omega-vscode-extension/images/omega-file-icon-light.svg` - Ikon tema terang
   - `omega-vscode-extension/images/omega-file-icon-dark.svg` - Ikon tema gelap
   - `omega-vscode-extension/images/omega-icon.svg` - Logo OMEGA

### Langkah-langkah untuk Mengaktifkan Ikon di TRAE IDE

1. **Restart TRAE IDE**
   - Tutup dan buka kembali TRAE IDE
   - Atau gunakan: `Ctrl+Shift+P` → ketik "Reload Window" → Enter

2. **Verifikasi Konfigurasi**
   - File `.mega` harusnya sekarang menampilkan ikon OMEGA
   - Jika belum muncul, cek apakah tema ikon sudah aktif

3. **Setting Tema Ikon Manual (jika diperlukan)**
   - Buka Settings (Ctrl+,)
   - Cari "File Icon Theme"
   - Pilih "omega-icons" dari daftar

4. **Verifikasi File Test**
   - File `test-icon.mega` telah dibuat untuk testing
   - Lihat apakah file ini menampilkan ikon OMEGA

### Perbedaan Antara VS Code dan TRAE IDE

| Fitur | VS Code | TRAE IDE |
|-------|---------|----------|
| Ekstensi | Menggunakan marketplace | Konfigurasi manual |
| Ikon | Otomatis dari `package.json` | Perlu konfigurasi manual |
| Tema | Banyak pilihan | Terbatas, perlu custom |
| File Association | Otomatis | Manual di `.trae/` |

### File yang Menentukan Ikon

1. **VS Code Extension** (`omega-vscode-extension/package.json`):
```json
{
  "contributes": {
    "languages": [{
      "id": "omega",
      "extensions": [".mega"],
      "icon": {
        "light": "./images/omega-file-icon-light.svg",
        "dark": "./images/omega-file-icon-dark.svg"
      }
    }]
  }
}
```

2. **TRAE IDE Configuration** (`.trae/settings.json`):
```json
{
  "trae.fileIcons": {
    "omega": "./omega-vscode-extension/images/omega-file-icon-mega.svg"
  },
  "trae.languages": {
    "omega": {
      "icon": "./omega-vscode-extension/images/omega-file-icon-mega.svg"
    }
  }
}
```

### Troubleshooting Tambahan

Jika ikon masih tidak muncul:

1. **Clear Cache TRAE IDE**
   - Tutup TRAE IDE
   - Hapus folder cache jika ada
   - Buka kembali

2. **Check File Path**
   - Pastikan semua path di konfigurasi benar
   - File SVG harus valid dan bisa dibaca

3. **Manual Override**
   - Gunakan settings.json TRAE IDE untuk override tema ikon
   - Set secara eksplisit tema ikon ke "omega-icons"

4. **Extension Development**
   - Jika perlu, buat ekstensi TRAE IDE khusus untuk OMEGA
   - Ikuti pola yang sama seperti VS Code extension

### Script Bantuan
Gunakan `reload-omega-config.ps1` untuk memverifikasi konfigurasi:
```powershell
powershell -ExecutionPolicy Bypass -File reload-omega-config.ps1
```

Script ini akan mengecek:
- ✅ Icon theme configuration
- ✅ File associations configuration  
- ✅ Settings configuration
- ✅ OMEGA icon files

### Kesimpulan
Perbedaan utama adalah VS Code memiliki sistem ekstensi yang otomatis, sementara TRAE IDE memerlukan konfigurasi manual. Dengan file konfigurasi yang telah dibuat, ikon OMEGA seharusnya dapat muncul di TRAE IDE setelah restart atau reload window.