# Panduan Deploy Produksi OMEGA Native Runner

> Catatan: Selain Native Runner `POST /compile`, CLI wrapper kini menyediakan perintah dasar `omega-production.exe test|deploy` untuk target EVM (Foundry). Pada Windows, OMEGA mendukung fallback WSL bila Foundry tidak tersedia di PATH.
> Mulai rilis ini, jika Foundry tidak tersedia, OMEGA mendukung fallback otomatis ke Hardhat bila Node.js/npm/npx terdeteksi di PATH.

Dokumen ini menjelaskan cara menjalankan OMEGA Native Runner untuk kebutuhan produksi, termasuk konfigurasi lingkungan, fitur pembatasan laju (rate limiting), dan skrip pendukung.

## Ringkasan Perubahan Siap Produksi
- Respons `/info` telah dibersihkan (debug_marker dihapus)
- Rate limiting stabil dengan jendela tetap 1 detik
- Header HTTP rate limit ditambahkan untuk kompatibilitas klien:
  - `X-RateLimit-Limit`
  - `X-RateLimit-Remaining`
  - `X-RateLimit-Reset` (ms hingga jendela reset)
  - `Retry-After` (detik untuk percobaan ulang pada 429)
- Logging disederhanakan; 429 tetap dilog agar mudah ditelusuri
- Shutdown listener dibuat defensif untuk menghindari error saat proses berhenti

### Pembaruan Wrapper & Diagnostik (Januari 2025)
- Titik masuk wrapper produksi direlokasi ke `src/wrapper/omega_production_wrapper.cpp` untuk konsistensi sumber.
- Skrip build dan E2E kini memprioritaskan sumber wrapper di `src/wrapper/` (fallback ke `build/` untuk kompatibilitas sementara).
- Ditambahkan handler `std::set_terminate` global yang aktif sebelum `main()` untuk mencatat exception tak-tertangani (mis. `std::out_of_range`) dari jalur emitter EVM. Log akan terlihat di stderr dengan awalan `[FATAL]`.
- Normalisasi line ending melalui `.gitattributes` (`text=auto`, skrip PowerShell CRLF) guna mengurangi peringatan LF/CRLF di Windows.

## Konfigurasi Lingkungan
Anda dapat mengatur konfigurasi melalui environment variable:
- `OMEGA_SERVER_IP` (default: `127.0.0.1`)
  - Disarankan menggunakan `localhost` untuk menghindari masalah urlacl pada Windows
  - `0.0.0.0` akan otomatis dipetakan ke `localhost` untuk HttpListener
- `OMEGA_SERVER_PORT` (default: `8080`)
- `OMEGA_RATE_LIMIT` (default: `10` req/detik)

Contoh menjalankan server secara langsung:
```
$env:OMEGA_SERVER_IP = "localhost"
$env:OMEGA_SERVER_PORT = "8091"
$env:OMEGA_RATE_LIMIT = "10"
powershell -NoProfile -ExecutionPolicy Bypass -File r:\OMEGA\scripts\omega_native_runner.ps1
```

Atau dengan parameter CLI:
```
powershell -NoProfile -ExecutionPolicy Bypass -File r:\OMEGA\scripts\omega_native_runner.ps1 -BindHost localhost -Port 8091 -RateLimit 10
```

## Menghentikan Runner
Gunakan skrip berikut untuk menghentikan runner yang berjalan di port tertentu:
```
powershell -NoProfile -ExecutionPolicy Bypass -File r:\OMEGA\scripts\stop_omega_runner.ps1 -BindHost localhost -Port 8091
```
Skrip akan mencoba menghentikan proses berdasarkan command-line yang sesuai dan melaporkan PID yang dihentikan.

## Endpoint
- `GET /health`  → status server
- `GET /version` → versi compiler
- `GET /info`    → info server (termasuk `rate_limit`)
- `POST /compile`→ kompilasi/parse sederhana (native runner)
 - `omega-production.exe test --target evm` → menyiapkan scaffolding Foundry dan menjalankan test minimal
 - `omega-production.exe deploy --target evm` → menyiapkan scaffolding Foundry untuk deploy
  - Fallback otomatis: bila Foundry tidak tersedia namun Node/npm/npx terdeteksi, OMEGA membuat scaffolding Hardhat dan menjalankan `npx hardhat test`

## Rate Limiting
- Model: fixed window 1 detik
- Jika batas tercapai, server mengembalikan `429` dengan payload:
  ```json
  {"error":"rate_limited","limit_per_sec":10}
  ```
- Header yang dikirim:
  - `X-RateLimit-Limit`: batas per detik
  - `X-RateLimit-Remaining`: sisa kuota pada jendela saat ini
  - `X-RateLimit-Reset`: milidetik hingga reset jendela
  - `Retry-After`: detik hingga aman untuk mencoba lagi

## Pengujian E2E
Skrip E2E dapat dijalankan untuk memverifikasi fungsionalitas:
```
powershell -NoProfile -ExecutionPolicy Bypass -File r:\OMEGA\scripts\http_e2e_tests.ps1
```
Skrip ini:
- Menghentikan runner sebelumnya pada port pengujian
- Menjalankan server baru pada `localhost`
- Memverifikasi `/health`, `/version`, `/info`, dan `POST /compile`
- Menangani rate limit agar tidak mengganggu pengujian fungsional

## Rekomendasi Operasional
- Gunakan `localhost` untuk binding HttpListener, atau jalankan sebagai admin jika butuh host lain
- Set `OMEGA_RATE_LIMIT` cukup tinggi untuk lalu lintas normal (mis. 10–50 req/detik) dan gunakan mekanisme burst control di layer atas jika diperlukan
- Pantau log 429 untuk memastikan tidak ada throttling yang tidak diinginkan
- Pertimbangkan menambahkan variabel `OMEGA_LOG_LEVEL` bila diperlukan untuk kontrol verbosity (opsional)

## Catatan
Runner ini bersifat native dan sederhana, cocok untuk demo/QA/servis internal. Untuk beban produksi yang lebih tinggi, pertimbangkan fronting dengan reverse proxy (mis. Nginx/IIS) dan pengelolaan proses sebagai Windows Service atau scheduler yang sesuai.

### Panduan Data Location (EVM)
- Pada Solidity >= 0.8.x, tipe dinamis (`string`, `bytes`, termasuk array dinamis/bertingkatnya) memerlukan lokasi data eksplisit pada parameter dan nilai kembalian.
- OMEGA codegen kini menyisipkan `memory` otomatis pada signature dan returns untuk tipe dinamis (termasuk elemen tuple yang berisi tipe dinamis dan nested arrays seperti `string[][]`).
- Catatan: Solidity tidak mendukung tipe tuple bertingkat di deklarasi `returns`. Output akan di-flatten menjadi daftar satu tingkat agar valid (mis. `returns ((string, bytes), uint256[] )` → `returns (string, bytes, uint256[] )`).
- Rekomendasi umum:
  - Gunakan `memory` untuk parameter fungsi dan nilai kembalian yang bersifat dinamis.
  - Hindari `storage` pada parameter kecuali kasus khusus (mis. referensi state) yang tidak umum untuk kontrak hasil codegen.
  - `calldata` dapat digunakan untuk parameter di fungsi `external` yang tidak dimodifikasi, namun saat ini codegen default ke `memory` untuk konsistensi.
Lihat dokumen rinci: `docs/evm-codegen-data-location.md`.

#### Normalisasi `len()`
- OMEGA menormalkan `len(expr)` menjadi bentuk yang sesuai di Solidity:
  - Untuk array dan `bytes`: `len(expr)` → `expr.length`
  - Untuk `string`: `len(expr)` → `bytes(expr).length`
- Deteksi khusus `string` memanfaatkan tipe parameter pada header fungsi, sehingga ekspresi seperti `len(names[0][0])` (dengan `names: string[][]`) ditransformasikan menjadi `bytes(names[0][0]).length`.

### Pengujian EVM dengan Foundry
Jika Foundry terpasang (Linux/macOS atau Windows via WSL/Git Bash):
```
R:\OMEGA\omega-production.exe test --target evm --input R:\OMEGA\tests\test_contracts\BasicToken.omega
```
Pada Windows tanpa Foundry di PATH, OMEGA akan mencoba mendeteksi WSL dan menjalankan `forge` di dalam WSL. Lihat `docs/toolchains/foundry_windows.md` atau jalankan `scripts/setup_foundry_windows.ps1` untuk panduan instalasi.

### Fallback Hardhat untuk EVM
Jika Foundry tidak terdeteksi, namun Node.js, npm, dan npx tersedia:
- OMEGA menyiapkan proyek di `build/hardhat_evm`
- Menghasilkan `contracts/<Module>.sol` dari input `.omega`
- Menulis `hardhat.config.js` minimal serta test JS
- Menginstal dev dependencies `hardhat`, `@nomicfoundation/hardhat-ethers`, `ethers`, `chai`
- Menjalankan `npx hardhat test` secara otomatis

Validasi kompilasi contoh (Hardhat):
- `StringReturnExample.sol`, `ArrayReturnExample.sol`, `TupleNestedExample.sol` berhasil dikompilasi.
- Catatan: beberapa peringatan terkait tipe numerik (mis. `int32`) dapat muncul; akan diselesaikan oleh pemetaan tipe numerik OMEGA → Solidity yang diperbarui.
 - Tambahan terbaru: `NestedArraysExample.sol` dan `TupleMultipleDynamicExample.sol` juga berhasil dikompilasi.
   - Kami menambahkan modifier `pure` pada fungsi yang tidak menyentuh state untuk menghilangkan peringatan "Function state mutability can be restricted to pure".
  - Parameter dan nilai kembalian bertipe dinamis telah menggunakan `memory` secara eksplisit (termasuk tuple dan array bertingkat), serta normalisasi `length` untuk array.
  - Tambahan uji terbaru: `StringLengthExample.sol` dan `TupleDeepDynamicExample.sol` (tipe returns di-flatten) berhasil dikompilasi.
    - Transformasi `len()` khusus `string` terverifikasi: `len(s)` → `bytes(s).length`, `len(names[0][0])` → `bytes(names[0][0]).length`.

Deploy lokal dengan Hardhat:
```
npx hardhat run scripts/deploy.js --network hardhat
```
Catatan: Skrip menggunakan Ethers v6 API (`waitForDeployment()`, `getAddress()`). Pastikan Node.js >= 16.