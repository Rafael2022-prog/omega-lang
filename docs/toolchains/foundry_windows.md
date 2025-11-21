# Foundry di Windows (WSL/Git Bash)

Foundry adalah toolkit EVM (forge/cast/anvil/chisel) yang direkomendasikan untuk testing dan deploy di target EVM. Pada Windows, Foundry tidak mendukung PowerShell/CMD secara native dan membutuhkan WSL atau Git Bash.

## Opsi Instalasi yang Direkomendasikan (WSL)

1. Install WSL dan distro Linux (Ubuntu direkomendasikan):
   ```powershell
   wsl --install
   ```
   Reboot setelah instalasi selesai.

2. Buka terminal WSL (Ubuntu) dan jalankan:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   ~/.foundry/bin/foundryup -y
   forge --version
   ```

3. Jalankan perintah OMEGA dari Windows. OMEGA otomatis mendeteksi WSL dan menggunakan `forge` di WSL jika tidak tersedia di PATH Windows.
   ```powershell
   R:\OMEGA\omega-production.exe test --target evm --input R:\OMEGA\tests\test_contracts\BasicToken.omega
   ```

Jika Anda ingin menjalankan perintah `forge` secara manual, gunakan terminal WSL:
```bash
cd /mnt/r/OMEGA/build/foundry_evm
forge test -q
```

## Alternatif: Git Bash

Jika Anda menggunakan Git Bash, jalankan perintah instalasi Foundry yang sama:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup -y
forge --version
```

## Skrip Bantuan

Repository OMEGA menyediakan skrip `scripts/setup_foundry_windows.ps1` untuk mendeteksi WSL dan mencoba instalasi Foundry secara otomatis (best-effort). Jika WSL belum tersedia, skrip menampilkan panduan langkah demi langkah.

## Troubleshooting

- `WSL ERROR: execvpe(/bin/bash) failed`: WSL belum terpasang atau distro Linux belum dikonfigurasi. Jalankan `wsl --install` lalu reboot.
- `forge: command not found` di WSL: Pastikan Anda mengeksekusi `~/.foundry/bin/foundryup -y` setelah instalasi. Coba buka ulang terminal WSL.
- PATH Windows tidak mengenali `forge`: Ini normal. Gunakan WSL fallback dari OMEGA (otomatis) atau jalankan perintah di WSL.

## Integrasi dengan OMEGA

- `omega-production.exe test --target evm`: Menyiapkan scaffolding Foundry dan menjalankan test minimal (constructor, totalSupply, mint) pada kontrak hasil kompilasi dari OMEGA.
- `omega-production.exe deploy --target evm`: Menyiapkan scaffolding Foundry untuk deploy. Buat skrip `script/Deploy.s.sol` lalu jalankan `forge script --broadcast` dari WSL.

Untuk detail lebih lanjut, lihat `README.md` dan `docs/evm-integration.md`.