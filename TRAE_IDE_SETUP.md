# Trae AI IDE Setup untuk File .mega

## Masalah
File dengan ekstensi `.mega` tidak menampilkan ikon OMEGA secara otomatis di Trae AI IDE.

## Solusi yang Diimplementasikan

### 1. File Konfigurasi Trae AI IDE

#### `.trae/file-associations.json`
Konfigurasi file association khusus untuk Trae AI IDE:
```json
{
  "fileAssociations": {
    "*.mega": {
      "language": "omega",
      "icon": {
        "path": "./temp-logo.svg",
        "type": "svg"
      },
      "description": "OMEGA Blockchain Source File"
    }
  }
}
```

#### `.trae/settings.json`
Pengaturan IDE untuk file association dan ikon:
```json
{
  "trae.fileAssociations": {
    "*.mega": "omega"
  },
  "trae.fileIcons": {
    "mega": {
      "iconPath": "./temp-logo.svg"
    }
  }
}
```

#### `trae.config.json`
Konfigurasi proyek level root:
```json
{
  "fileTypes": {
    ".mega": {
      "language": "omega",
      "icon": {
        "path": "./temp-logo.svg"
      }
    }
  }
}
```

### 2. Konfigurasi omega.toml

Ditambahkan section `[ide]` untuk integrasi IDE:
```toml
[ide]
file_associations = {
    "*.mega" = "omega"
}

file_icons = {
    "mega" = {
        "icon_path" = "./temp-logo.svg",
        "description" = "OMEGA Source File"
    }
}

[ide.trae]
enabled = true
file_icon_theme = "omega-icons"
syntax_highlighting = true
```

### 3. Windows Registry (Fallback)

File `install/windows/omega-file-association.reg` diperbarui untuk menunjuk ke ikon yang benar:
```reg
[HKEY_CLASSES_ROOT\OmegaSourceFile\DefaultIcon]
@="r:\\OMEGA\\omega-icon.ico,0"
```

## Cara Menggunakan

### Metode 1: Restart Trae AI IDE
1. Tutup Trae AI IDE
2. Buka kembali Trae AI IDE
3. File `.mega` seharusnya menampilkan ikon OMEGA

### Metode 2: Reload Konfigurasi
1. Buka Command Palette di Trae AI
2. Jalankan "Reload Window" atau "Reload Configuration"
3. Verifikasi ikon file `.mega`

### Metode 3: Manual Registry (Windows)
1. Jalankan `install/windows/omega-file-association.reg`
2. Restart Windows Explorer atau reboot sistem
3. File `.mega` akan memiliki ikon OMEGA di File Explorer

## Verifikasi

Untuk memverifikasi bahwa setup berhasil:

1. **Buat file test:**
   ```bash
   echo "blockchain Test { }" > test.mega
   ```

2. **Periksa di Trae AI IDE:**
   - File `test.mega` harus menampilkan ikon OMEGA
   - Ikon harus muncul di file explorer dan tab editor

3. **File test yang sudah dibuat:**
   - `test-icon-display.mega`
   - `contracts/SimpleToken.mega`
   - `examples/CrossChainBridge.mega`

## Troubleshooting

### Ikon Tidak Muncul
1. Pastikan file `temp-logo.svg` ada di root directory
2. Restart Trae AI IDE
3. Periksa console Trae AI untuk error messages
4. Verifikasi path ikon di file konfigurasi

### Konfigurasi Tidak Terbaca
1. Periksa syntax JSON di file konfigurasi
2. Pastikan file konfigurasi berada di lokasi yang benar
3. Coba reload window di Trae AI IDE

### Windows Registry Issues
1. Jalankan Command Prompt sebagai Administrator
2. Import file registry: `regedit /s omega-file-association.reg`
3. Restart Windows Explorer

## File yang Dibuat/Dimodifikasi

- `.trae/file-associations.json` (baru)
- `.trae/settings.json` (baru)
- `trae.config.json` (baru)
- `omega.toml` (diperbarui)
- `install/windows/omega-file-association.reg` (diperbarui)
- `omega-icon.ico` (baru)
- `test-icon-display.mega` (baru)

## Catatan

- Konfigurasi ini mendukung berbagai metode yang mungkin digunakan Trae AI IDE
- File `temp-logo.svg` digunakan sebagai ikon utama (background transparan)
- Fallback ke Windows registry untuk kompatibilitas sistem
- Konfigurasi dapat disesuaikan sesuai kebutuhan proyek