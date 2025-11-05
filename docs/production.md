# Panduan Deploy Produksi OMEGA Native Runner

> Catatan (Windows Native-Only, Compile-Only): Dokumen ini berfokus pada Native Runner dan endpoint `POST /compile` yang cocok dengan status CLI wrapper saat ini. Perintah `omega build/test/deploy` bersifat forward-looking dan belum aktif di wrapper.

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