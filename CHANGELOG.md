## 2.0.0

- **Major Architectural Overhaul & Modernization**
- **Breaking Change**: Migrated to Dart 3 with complete Null-Safety support.
- **Breaking Change**: Removed hardcoded dependency on the legacy `flutter_ble_lib` and introduced the `ProvTransport` abstract interface. This allows developers to inject any BLE library (e.g., `flutter_reactive_ble`) and adds full support for Linux Desktop and other unsupported platforms.
- **Fix**: Resolved the "Mismatch in device verify" error by migrating AES-CTR cryptography to `pointycastle`. The state of the cipher is now correctly maintained across sequential BLE packets, strictly aligning with ESP-IDF `protocomm` specifications.
- **Fix**: Corrected the *Proof of Possession (PoP)* derivation logic to properly handle the MAC address offset (-2) between the BLE MAC and the internal Wi-Fi MAC broadcasted by ESP32 devices.
- **Fix**: Addressed race conditions and `Null check operator` crashes in the provisioning state machine.

## 1.0.0+6

- Support flutter 2.0

## 1.0.0+5

- Dependency bump

## 1.0.0+1

- Support BLE Provisioning Security1

## 1.0.0+2

- Using github image URL & add homepage