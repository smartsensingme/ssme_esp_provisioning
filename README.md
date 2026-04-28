# ssme_esp_provisioning (Modernized Fork)

*Leia este arquivo em [Português do Brasil](README.br.md)*

![Pub Version](https://img.shields.io/badge/version-2.0.0-blue) ![Dart](https://img.shields.io/badge/Dart-3.0%2B-blue)

A modernized and fully null-safe Flutter library to provide network credentials (Wi-Fi) and custom data to an ESP32/ESP32-S3 over Bluetooth Low Energy (BLE).

The `ssme_esp_provisioning` library is a rigorous and **pure Dart** implementation of the official *ESP-IDF Unified Provisioning* protocol. It is composed exclusively of two mathematical and structural engines:
1. **Cryptography Engines:** Stateful implementation of the elliptic curve (`Curve25519`) combined with AES-CTR blocks.
2. **Structural Engines:** Compilation of the native `Protocol Buffers` (Protocomm) schemas established by Espressif.

**What does this mean in practice?**
* **Exclusive Protocol Coupling:** The library will only be able to "talk" to firmwares that implement the `wifi_prov_mgr` component of ESP-IDF. It "speaks" the strict dialect of the security protocol (`Security 1` / `Security 0`) by Espressif. It will not work for provisioning generic chips from other brands.
* **Total Transport (Hardware) Independence:** Unlike official libraries that rely on native bridges (Java/Swift) incompatible with Desktop computers, this package **does not know what Bluetooth, Wi-Fi, or Serial is**. The physical transfer of bytes is outsourced!

To use the library, the developer only needs to instantiate a class that respects the `ProvTransport` interface. `ssme_esp_provisioning` envelopes the encrypted payload and delivers it to the transport; whether the delivery is made via a BLE antenna using `flutter_blue_plus`, `flutter_reactive_ble`, or even a Serial cable, it is irrelevant to the core package. This ensures perfect compatibility on **any operating system** where Flutter can be compiled.

One of the greatest differentiators of this library is its hardware-agnostic architecture based on the *Separation of Concerns* design pattern.

## 1. Origin and Motivation for the Update

This package is an updated *fork* of the original project [sunshine-tech/esp_provisioning](https://github.com/sunshine-tech/esp_provisioning). 

The original package was essential to enable provisioning via Flutter, but became obsolete for modern applications for the following reasons:
* **Lack of support for Dart 3 and Null-Safety:** The old code caused severe compilation failures in recent Flutter projects.
* **Cryptographic Incompatibility (Sec1):** The original AES-CTR logic restarted the initialization vector (IV) with every BLE packet sent, breaking the handshake with recent ESP-IDF firmwares (`protocomm`) that require continuous maintenance of the *cipher* state during the session.
* **PoP (Proof of Possession) Failures:** The pairing key calculation using the MAC address did not take the "MAC Offset" into account (where the ESP32's Bluetooth MAC is slightly different from the Wi-Fi MAC, usually `MAC - 2`).
* **Coupling to abandoned libraries:** The package strictly required `flutter_ble_lib` (already abandoned and without desktop support).

## 2. Summary of Improvements and Fixes (Changelog)

The following architectural changes and bug fixes were applied in this version:
* **Migration to Dart 3 / Total Null-Safety:** Appropriate addition of `?` and `!` to handle asynchronous BLE disconnections and corrections in mandatory parameter passing.
* **Fixed Cryptography:** Replacement of the legacy `cryptography` package with an integration with the `pointycastle` package (`CTRStreamCipher`), ensuring that the sequential state of the AES-CTR stream is retained between read/write blocks, matching the exact ESP-IDF requirement.
* **Correction of "Mismatch in device verify":** Fixed logic to handle the derivation of the Wi-Fi MAC from the BLE MAC.
* **Abstract Transport Interface (`ProvTransport`):** Coupling with specific Bluetooth packages has been removed. You now inject *any* BLE plugin by implementing the transport interface (supporting Linux Desktop, Android, iOS, Windows, etc).

## 3. Usage Guide (Step-by-Step)

For the agnostic architecture to work, you need to implement the "legs" of the system (the Transport) and then orchestrate the "brain" (the Provisioning).

### Step 1: Implement the `ProvTransport` Interface
Create a class in your application that knows how to read and write bytes via Bluetooth using the plugin of your choice (e.g., `flutter_reactive_ble` or `flutter_blue_plus`).

```dart
import 'package:ssme_esp_provisioning/ssme_esp_provisioning.dart';

class MyBleTransport implements ProvTransport {
  // Initialize with your native BLE connection
  
  @override
  Future<bool> connect() async {
    // 1. Connect to the Bluetooth device
    // 2. Discover Services (Service UUID)
    // 3. Map the ESP32 Endpoints ('prov-session', 'prov-config') 
    //    via the 0x2901 Descriptor of each characteristic.
    return true;
  }

  @override
  Future<void> disconnect() async {
    // Physically disconnect the BLE antenna
  }

  @override
  Future<Uint8List> sendReceive(String endpointName, Uint8List data) async {
    // 1. Write the [data] bytes to the Characteristic mapped with the name [endpointName]
    // 2. Read and return the response sent by the ESP32
    return readResponse;
  }
}
```

### Step 2: Execute the Provisioning

With the transport ready, call the library to perform the cryptographic magic and configure the Wi-Fi.

```dart
import 'package:ssme_esp_provisioning/ssme_esp_provisioning.dart';

Future<void> configureBoard() async {
  // 1. Calculate the PoP (Proof of Possession). 
  // On the ESP32, this is usually a PIN or the last 4 letters of the Wi-Fi MAC.
  String calculatedPop = "C6A0"; 

  // 2. Inject your transport and the security protocol
  EspProv prov = EspProv(
    transport: MyBleTransport(),
    security: Security1(pop: calculatedPop),
  );

  try {
    // 3. Connects over BLE and performs the Curve25519 Handshake (AES keys generation)
    await prov.establishSession();

    // 4. (Optional) Scans for networks around the ESP32
    var networks = await prov.startScanWiFi();
    print("Networks seen by the ESP32: $networks");

    // 5. Sends the encrypted credentials
    await prov.sendWifiConfig(ssid: 'Your_Network', password: 'Your_Password');

    // 6. Commands the board to apply the network and attempt connection
    await prov.applyWifiConfig();
    
    print("Provisioning sent successfully!");
    
  } catch (e) {
    print("Security or communication failure: $e");
  } finally {
    await prov.dispose(); // Cleans up the session
  }
}
```

## 4. Protocol Communication Overview

Protocol Communication ([protocomm](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/provisioning/protocomm.html)) component manages secure sessions and provides framework for multiple transports. 
This Dart library acts as the client-side implementation of this protocol, focusing on `protocomm_security1` (Curve25519 key exchange + AES-CTR encryption).

---
![SmartSensing.me Logo](https://smartsensing.me/ssme-logo.png)

## 📝 Description

This project is part of the **SmartSensing.me** ecosystem and goes beyond the basic examples found on the internet. Here, we apply the real fundamentals of high-performance instrumentation and embedded systems engineering.

Unlike superficial content aimed solely at clicks, this repository delivers:
- **Novelty:** Original implementations based on nearly 30 years of academic experience.
- **Technical Density:** Professional use of the ESP-IDF framework and FreeRTOS.
- **Didactics:** Documented and structured code for those seeking real technical evolution.

> "We transform signals from the physical world into digital intelligence, without shortcuts."

---

## 🛠️ Technologies
- **Hardware Target:** ESP32 / ESP32-S3
- **Framework:** ESP-IDF v5.x
- **Language:** C / C++
- **Simulation:** LTSpice (Sensor Modeling)

---

## 👤 About the Author

**José Alexandre de França** *Adjunct Professor at the Department of Electrical Engineering, UEL*

Electrical Engineer with nearly three decades of experience in undergraduate and graduate teaching. PhD in Electrical Engineering, researcher in electronic instrumentation, and embedded systems developer. SmartSensing.me is my commitment to raising the level of technological education in Brazil.

- 🌐 **Website:** [smartsensing.me](https://smartsensing.me)
- 📧 **E-mail:** [info@smartsensing.me](mailto:info@smartsensing.me)
- 📺 **YouTube:** [@smartsensingme](https://youtube.com/@smartsensingme)
- 📸 **Instagram:** [@smartsensing.me](https://instagram.com/smartsensing.me)

---

## 📄 License

This project is licensed under the MIT license. See the [LICENSE](LICENSE) file for details.

### Library License
[Apache License Version 2.0](./LICENSE)