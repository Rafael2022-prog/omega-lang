# VS Code Extension Update - Activation Events Fix

## Perubahan yang Dilakukan

### File: `omega-vscode-extension/package.json`

#### Masalah
Peringatan dari VS Code Extension Editing:
```
This activation event can be removed for extensions targeting engine version ^1.75 as VS Code will generate these automatically from your package.json contribution declarations.
```

#### Solusi
1. **Menghapus activation event manual**:
   ```diff
   - "activationEvents": [
   -   "onLanguage:omega"
   - ],
   + "activationEvents": [],
   ```

2. **Meningkatkan engine version**:
   ```diff
   - "vscode": "^1.74.0"
   + "vscode": "^1.75.0"
   ```

3. **Update dependencies yang sesuai**:
   ```diff
   - "@types/vscode": "^1.74.0"
   + "@types/vscode": "^1.75.0"
   ```

#### Alasan Perubahan
- VS Code 1.75+ secara otomatis menghasilkan activation events dari contribution declarations
- Menghapus activation event manual mengikuti best practices VS Code
- Meningkatkan engine version memastikan kompatibilitas dengan fitur otomatis ini

#### Hasil
✅ Extension sekarang mengikuti best practices VS Code 1.75+
✅ Activation events dihasilkan otomatis dari language contributions
✅ Tidak ada peringatan saat mengedit extension
✅ Kode lebih bersih dan lebih maintainable

### Informasi Tambahan
- Language contribution tetap ada di `contributes.languages`
- VS Code akan otomatis mengaktifkan extension saat file `.mega` dibuka
- Tidak perlu maintenance manual activation events lagi