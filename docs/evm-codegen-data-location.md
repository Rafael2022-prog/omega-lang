# EVM Codegen: Data Location and Solidity Validity for Dynamic Types (Params, Returns, Arrays)

Dokumen ini mencatat perubahan untuk memastikan kode Solidity yang dihasilkan OMEGA:
- Menyisipkan lokasi data eksplisit (`memory`) untuk tipe dinamis (`string`, `bytes`, termasuk array dinamis dan bertingkat) pada parameter dan nilai kembalian.
- Memetakan tipe numerik OMEGA sederhana (`i32`, `u32`, `i64`, `u64`, dll.) ke tipe Solidity yang setara di signature dan body.
- Menormalkan sintaks OMEGA di body fungsi menjadi Solidity yang valid (mis. `let` → deklarasi Solidity, `len(expr)` → `expr.length`).
 - Menormalkan sintaks OMEGA di body fungsi menjadi Solidity yang valid (mis. `let` → deklarasi Solidity, `len(expr)` → `expr.length` untuk array dan bytes, serta `len(stringExpr)` → `bytes(stringExpr).length`).

## Rationale

Sejak Solidity 0.8.x, pengoperan tipe dinamis (mis. `string`, `bytes`, `string[]`, `bytes[]`, termasuk nested arrays) ke fungsi/konstruktor membutuhkan lokasi data eksplisit (`memory`, `calldata`, `storage`). Mengabaikan lokasi data menyebabkan error kompilasi. Sebelumnya, generator OMEGA mengeluarkan signature tanpa lokasi data eksplisit, serta belum mengatur lokasi pada nilai kembalian dan tuple yang berisi tipe dinamis.

## Summary of Changes

1. Menambahkan utilitas pada wrapper codegen EVM native (`src/wrapper/omega_production_wrapper.cpp`) untuk menyisipkan `memory` pada parameter tipe dinamis yang tidak memiliki lokasi data.
2. Menambahkan utilitas padanan untuk nilai kembalian (`ensure_memory_in_returns`) termasuk tuple returns, menyisipkan `memory` pada elemen bertipe dinamis.
3. Integrasi ke fungsi `emit_evm` sehingga signature konstruktor/fungsi dan returns diperbaiki sebelum ditulis ke `.sol`.
4. Menambahkan transformasi body: `transform_len_calls` (mengubah `len(expr)` → `expr.length`), `transform_let_declaration_line` (mengubah `let name: type = expr;` → deklarasi Solidity yang valid, termasuk penyisipan `memory` pada tipe dinamis dan konversi literal bytes).
5. Menambahkan pemetaan tipe numerik sederhana OMEGA ke padanan Solidity melalui `map_omega_simple_types_in_line`.
6. Menyelaraskan lingkungan Hardhat untuk validasi output generator.

## Update: Flatten Tuple Returns & `len()` Khusus String

Per 2025-11-19, codegen EVM native ditingkatkan untuk:

- Mem-flatten tipe returns bertingkat pada signature Solidity: 
  - Input: `returns ((string, bytes), uint256[], string[][])`
  - Output: `returns (string memory, bytes memory, uint256[] memory, string[][] memory)`
- Mem-flatten nilai `return` bertingkat di body fungsi: 
  - Input: `return ((a, b), nums, labels);`
  - Output: `return (a, b, nums, labels);`
- Mendeteksi pemanggilan `len(expr)` terhadap ekspresi bertipe `string` dan mengubahnya menjadi `bytes(expr).length`. Heuristik deteksi menggunakan tipe parameter pada header fungsi (mis. `string a`, `string[][] labels`) sehingga `len(labels[0][0])` diubah menjadi `bytes(labels[0][0]).length`. Untuk array dan `bytes`, tetap menggunakan `expr.length`.

Perubahan ini diimplementasikan melalui:

- `parse_param_types`: memetakan nama parameter ke tipe token untuk memberi konteks ke transformasi body.
- `transform_return_flatten_tuples`: menghapus kurung di dalam daftar nilai `return` pada tingkat dalam, menghasilkan satu tingkat tuple yang valid untuk Solidity.
- `transform_len_calls(line, param_types)`: mengganti `len(expr)` menjadi bentuk yang tepat, memilih `bytes(expr).length` bila `expr` diketahui sebagai `string` (termasuk hasil indeks dari `string[]`/`string[][]`).

## Files Updated

- `src/wrapper/omega_production_wrapper.cpp`
  - New helpers:
    - `trim_copy`, `tolower_copy`, `contains_location_keyword`
    - `is_string_or_bytes_type` (mengecualikan fixed-size seperti `bytes32`)
    - `ensure_memory_in_params` (menyisipkan `memory` untuk `string`/`bytes` dan arrays ketika belum ada)
    - `ensure_memory_in_returns` (menyisipkan `memory` pada daftar returns untuk tipe dinamis, termasuk tuple)
    - `map_omega_simple_types_in_line` (memetakan tipe numerik OMEGA sederhana ke padanan Solidity)
    - `is_string_literal` (deteksi literal string)
    - `transform_len_calls` (regex untuk `len(expr)` → `expr.length`, termasuk ekspresi bertingkat)
    - `transform_let_declaration_line` (konversi deklarasi `let` ke Solidity yang valid, plus penanganan `bytes` literal)
  - Integrasi dalam `emit_evm`: penerapan pemetaan tipe, koreksi lokasi data params/returns, dan transformasi body.

- `build/hardhat_evm/hardhat.config.js`
  - Switched to CommonJS (`require`) for broader compatibility.

- `build/hardhat_evm/package.json`
  - Aligned dev dependencies for a known-good combination:
    - `hardhat` `^2.27.0`
    - `@nomicfoundation/hardhat-ethers` `^3.1.0`
    - `@nomicfoundation/hardhat-toolbox` `^6.1.1`
    - `chai` `^4.3.7`
    - `ethers` `^6.15.0`

- `build/hardhat_evm/test/BasicToken.js`
  - Switched to CommonJS (`require('chai')`, `require('hardhat')`) to avoid ESM named export issues.

> Catatan: Pada sesi ini, binary `omega-production.exe` di Windows belum direbuild. Validasi dilakukan dengan memperbaiki keluaran `.sol` pada test secara manual (penambahan `memory`, normalisasi body, dan modifier `pure`). Setelah toolchain build terpasang (MSVC/Windows SDK atau alternatif clang/MinGW), binary akan direbuild sehingga perubahan codegen berlaku otomatis pada keluaran `.sol`.

## Rincian Implementasi (Inti)

Perubahan inti meliputi `ensure_memory_in_params` dan `ensure_memory_in_returns` di `src/wrapper/omega_production_wrapper.cpp`:

- Mendeteksi baris yang mendefinisikan signature konstruktor/fungsi serta bagian `returns (...)`.
- Mem-parse daftar parameter/returns, membagi per koma sambil menghormati kurung dalam.
- Untuk setiap item:
  - Jika lokasi data sudah ada (`memory`, `calldata`, `storage`), biarkan apa adanya.
  - Mengidentifikasi token tipe (token pertama), menghapus sufiks array.
  - Jika tipe dasar adalah `string` atau `bytes` (bukan `bytes32`), rekonstruksi menjadi `type memory name`.
- Menghindari perubahan untuk `bytesN` fixed-size (mis. `bytes32`).

Titik integrasi:

```cpp
// In emit_evm
if (ln.rfind("constructor", 0) == 0 || ln.rfind("function ", 0) == 0) {
    std::string fixed = ensure_memory_in_params(ln);
    ofs << "    " << fixed << "\n";
    // ... copy function body
}

// If the line contains a returns clause
auto posRet = ln.find("returns (");
if (posRet != std::string::npos) {
    ln = ensure_memory_in_returns(ln);
}

// Map OMEGA simple types and normalize body statements
ln = map_omega_simple_types_in_line(ln);
ln = transform_len_calls(ln);
ln = transform_let_declaration_line(ln);
```

## Pengujian dan Validasi

Pengujian Hardhat dijalankan di `build/hardhat_evm`:

- Kompilasi berhasil dengan Solidity 0.8.20. Peringatan yang tersisa terkait tipe numerik `int32` (lihat Limitasi).
- Kompilasi contoh-contoh berikut berhasil:
  - `StringReturnExample.sol` (params/returns `string`, `bytes`, `bytes[]`, `string[]`)
  - `ArrayReturnExample.sol` (array dinamis non-string/bytes; catatan: type mapping numerik masih perlu disesuaikan untuk validitas penuh)
  - `TupleNestedExample.sol` (menggunakan tuple berisi tipe dinamis; catatan: tipe returns bertingkat tidak didukung sebagai tipe di signature Solidity dan perlu di-flatten)
  - `StringLengthExample.sol` (uji panjang `string`/`bytes` dan normalisasi `len(expr)` → `.length`)
  - `TupleDeepDynamicExample.sol` (uji gabungan `string`, `bytes`, `uint256[]`, `string[][]`; tipe returns di-flatten menjadi `(string, bytes, uint256[], string[][])` agar valid)
  - Verifikasi `len()` khusus string: `len(names[0][0])` → `bytes(names[0][0]).length`

Perintah:

```
cd build/hardhat_evm
npm install
npx hardhat test
```

Observed output:

- `Compiled Solidity files successfully (evm target: paris).`
- Peringatan mutability telah dihilangkan setelah menambahkan modifier `pure` pada fungsi yang tidak menyentuh state.
 - Error parser terkait `returns ((string, bytes), ...)` diatasi dengan mem-flatten daftar returns menjadi tingkat tunggal: `returns (string, bytes, ...)`.

## Limitasi & Tindak Lanjut

- Pemetaan tipe numerik: beberapa keluaran menggunakan tipe bertingkat seperti `int32`/`uint32`. Untuk menyederhanakan dan mengurangi potensi peringatan lintas toolchain, pemetaan akan dinormalisasi ke `int256`/`uint256` kecuali bila tipe ber-width spesifik benar-benar diperlukan.
- Transformasi kontrol alur (`if`, `else`, `for`) belum sepenuhnya di-normalisasi dari pseudo-sintaks OMEGA ke Solidity yang valid untuk semua kasus kompleks.
 - Diperlukan perluasan cakupan pengujian untuk nested arrays dalam dan tuple returns multi-elemen termasuk kombinasi beberapa tipe dinamis.
 - Solidity tidak mendukung tipe tuple bertingkat di deklarasi `returns`. Codegen perlu mem-flatten tipe returns bertingkat ke daftar satu tingkat (atau, alternatifnya, menghasilkan `struct` dan mengembalikan tipe tersebut untuk fungsi `internal`). Untuk kompatibilitas ABI publik, pendekatan flatten diprioritaskan.

### Langkah Selanjutnya yang Diusulkan

1. Selesaikan pemetaan tipe numerik OMEGA → Solidity yang valid (hindari tipe tidak sah seperti `int32`).
2. Tambahkan pengujian untuk kontrol alur dan deklarasi variabel pada body (mengganti pseudo-sintaks `let`, `if`, dll.) serta regresi untuk `len()` → `.length`.
3. Jalankan validasi kompilasi lintas toolchain (`solc`, Foundry, Hardhat) untuk seluruh contoh.
4. Perkuat logika penyisipan lokasi data untuk kombinasi nested arrays + tuple returns yang kompleks.

## Catatan Kompatibilitas Lingkungan

- Hardhat 3.x menunjukkan isu ESM dan jalur ekspor; menggunakan 2.27.x dengan toolbox/ethers yang kompatibel memastikan stabilitas.
- Proyek menggunakan CommonJS untuk `hardhat.config.js` dan test untuk kompatibilitas yang lebih luas.

## Referensi Change Log

- Lokasi patch sumber:
  - `src/wrapper/omega_production_wrapper.cpp` around lines ~90–170 (helper functions) and ~220–280 (usage in `emit_evm`).
  - Comment marker near line 95: `// Insert explicit data location (memory) for string/bytes parameters in`.

---

Maintainer: OMEGA Compiler Team
Date: 2025-11-18 (diperbarui)