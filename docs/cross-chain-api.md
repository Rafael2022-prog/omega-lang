# OMEGA Cross-Chain API (std.bridge)

Ringkasan API final untuk primitif lintas rantai berdasarkan standar saat ini di wiki/API-Reference.md (≈506–542). Dokumen ini mengunci antarmuka untuk stabilisasi dan implementasi uji lintas target.

## Modul dan Tipe

import std.bridge.{CrossChainMessage, BridgeValidator}

- CrossChainMessage
  - source_chain: uint32
  - dest_chain: uint32
  - sender: address
  - recipient: bytes
  - payload: bytes
  - nonce: uint256

- BridgeValidator (library)
  - validate_message(message: CrossChainMessage) -> bool
  - verify_signatures(message_hash: bytes32, signatures: bytes[]) -> bool
  - encode_message(message: CrossChainMessage) -> bytes
  - decode_message(data: bytes) -> CrossChainMessage

## Contoh Penggunaan (Ringkas)

```omega
import std.bridge.{CrossChainMessage, BridgeValidator};

blockchain CrossChainBridge {
    mapping(bytes32 => bool) processed_messages;
    
    function process_message(
        CrossChainMessage memory message,
        bytes[] memory signatures
    ) public {
        bytes32 message_hash = hash.keccak256(BridgeValidator.encode_message(message));
        require(!processed_messages[message_hash], "Message already processed");
        require(BridgeValidator.verify_signatures(message_hash, signatures), "Invalid signatures");
        
        processed_messages[message_hash] = true;
        _execute_message(message);
    }
}
```

## Kompatibilitas Lintas Target

- EVM
  - hash: keccak256 kompatibel
  - address: EVM address
  - bytes32: native
  - rekomendasi: tanda tangan ECDSA/secp256k1

- Solana
  - recipient: bytes (wakil pubkey 32-byte)
  - payload: bytes (serdes via Borsh/serde)
  - hash: keccak256 tersedia via std.hash jika diaktifkan atau gunakan SHA256 (per modul target)

- Cosmos/Substrate/Move/NEAR (perencanaan)
  - tipe penerima dan skema tanda tangan disesuaikan modul target

## Kontrak Stabilisasi

- Tidak ada perubahan nama fungsi/field tanpa bump versi mayor
- Tambah fungsi utilitas baru diperbolehkan selama backward-compatible
- Validasi tanda tangan: harus deterministik dan tidak bergantung pada state global

## Checklist Implementasi

- [x] Struktur CrossChainMessage
- [x] Library BridgeValidator dengan 4 fungsi inti
- [ ] Implementasi utilitas hashing cross-target konsisten (keccak256/SHA256)
- [ ] Uji lintas target (compile-only + network harness) untuk EVM/Solana
- [ ] Dokumentasi contoh eksekusi payload lintas rantai

## Catatan

- Mengacu pada BLOCKCHAIN_TARGETS_RESTORATION_REPORT.md: lingkungan saat ini bersifat Windows native-only, compile-only. E2E on-chain akan disediakan melalui harness terpisah saat runner jaringan siap.