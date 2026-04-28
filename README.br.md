# ssme_esp_provisioning (Modernized Fork)

*Read this in other languages: [English](README.md)*

![Pub Version](https://img.shields.io/badge/version-2.0.0-blue) ![Dart](https://img.shields.io/badge/Dart-3.0%2B-blue)

A modernized and fully null-safe Flutter library to provide network credentials (Wi-Fi) and custom data to an ESP32/ESP32-S3 over Bluetooth Low Energy (BLE).

A biblioteca `ssme_esp_provisioning` é uma implementação rigorosa e **puramente em Dart** do protocolo oficial *ESP-IDF Unified Provisioning*. Ela é composta exclusivamente por dois motores matemáticos e estruturais:
1. **Motores de Criptografia:** Implementação stateful da curva elíptica (`Curve25519`) combinada com blocos AES-CTR.
2. **Motores de Estruturação:** Compilação dos schemas nativos de `Protocol Buffers` (Protocomm) estabelecidos pela Espressif.

**O que isso significa na prática?**
* **Acoplamento Exclusivo ao Protocolo:** A biblioteca só conseguirá "conversar" com firmwares que implementem o componente `wifi_prov_mgr` do ESP-IDF. Ela "fala" o dialeto estrito do protocolo de segurança (`Security 1` / `Security 0`) da fabricante Espressif. Não funcionará para provisionar chips genéricos de outras marcas.
* **Independência Total de Transporte (Hardware):** Diferente das bibliotecas oficiais que dependem de pontes nativas (Java/Swift) incompatíveis com computadores Desktop, este pacote **não sabe o que é Bluetooth, Wi-Fi ou Serial**. A transferência física dos bytes é terceirizada!

Para utilizar a biblioteca, o desenvolvedor precisa apenas instanciar uma classe que respeite a interface `ProvTransport`. O `ssme_esp_provisioning` envelopa a carga criptografada e a entrega para o transporte; se a entrega é feita por uma antena BLE via `flutter_blue_plus`, via `flutter_reactive_ble`, ou até mesmo por um cabo Serial, é irrelevante para o pacote central. Isso garante compatibilidade perfeita em **qualquer sistema operacional** em que o Flutter possa ser compilado.

Um dos maiores diferenciais desta biblioteca é a sua arquitetura agnóstica de hardware baseada no padrão de projeto *Separation of Concerns* (Separação de Responsabilidades).

## 1. Origem e Motivação da Atualização

Este pacote é um *fork* atualizado do projeto original [sunshine-tech/esp_provisioning](https://github.com/sunshine-tech/esp_provisioning). 

O pacote original foi fundamental para permitir provisionamento via Flutter, mas tornou-se obsoleto para aplicações modernas pelos seguintes motivos:
* **Falta de suporte ao Dart 3 e Null-Safety:** O código antigo causava falhas severas de compilação em projetos Flutter recentes.
* **Incompatibilidade Criptográfica (Sec1):** A lógica do AES-CTR original reiniciava o vetor de inicialização (IV) a cada pacote BLE enviado, quebrando o handshake com firmwares recentes do ESP-IDF (`protocomm`) que exigem a manutenção contínua do estado do *cipher* durante a sessão.
* **Falhas no PoP (Proof of Possession):** O cálculo da chave de pareamento usando o endereço MAC não levava em conta o "MAC Offset" (onde o MAC do Bluetooth do ESP32 é ligeiramente diferente do MAC do Wi-Fi, geralmente `MAC - 2`).
* **Acoplamento a bibliotecas abandonadas:** O pacote exigia estritamente o `flutter_ble_lib` (já abandonado e sem suporte a desktop).

## 2. Resumo das Melhorias e Correções (Changelog)

As seguintes mudanças arquiteturais e correções de bugs foram aplicadas nesta versão:
* **Migração para Dart 3 / Null-Safety Total:** Adição de `?` e `!` adequados para lidar com desconexões assíncronas do BLE e correções nas passagens de parâmetros obrigatórios.
* **Criptografia Corrigida:** Substituição do pacote `cryptography` legado por uma integração com o pacote `pointycastle` (`CTRStreamCipher`) garantindo que o estado sequencial do fluxo AES-CTR seja retido entre blocos lidos/escritos, correspondendo à exata exigência do ESP-IDF.
* **Correção do "Mismatch in device verify":** Lógica consertada para lidar com a derivação do MAC de Wi-Fi a partir do MAC de BLE.
* **Interface Abstrata de Transporte (`ProvTransport`):** O acoplamento com pacotes de Bluetooth específicos foi removido. Agora você injeta *qualquer* plugin BLE implementando a interface de transporte (suportando Linux Desktop, Android, iOS, Windows, etc).

## 3. Exemplo de Utilização

## 3. Guia de Utilização (Passo a Passo)

Para que a arquitetura agnóstica funcione, você precisa implementar as "pernas" do sistema (o Transporte) e depois orquestrar o "cérebro" (o Provisionamento).

### Passo 1: Implemente a Interface `ProvTransport`
Crie uma classe no seu aplicativo que saiba como ler e escrever bytes via Bluetooth usando o plugin da sua escolha (ex: `flutter_reactive_ble` ou `flutter_blue_plus`).

```dart
import 'package:ssme_esp_provisioning/ssme_esp_provisioning.dart';

class MeuTransporteBle implements ProvTransport {
  // Inicialize com a sua conexão BLE nativa
  
  @override
  Future<bool> connect() async {
    // 1. Conecte ao dispositivo Bluetooth
    // 2. Descubra os Serviços (Service UUID)
    // 3. Mapeie os Endpoints do ESP32 ('prov-session', 'prov-config') 
    //    através do Descriptor 0x2901 de cada característica.
    return true;
  }

  @override
  Future<void> disconnect() async {
    // Desconecte fisicamente a antena BLE
  }

  @override
  Future<Uint8List> sendReceive(String endpointName, Uint8List data) async {
    // 1. Escreva os bytes [data] na Característica mapeada com o nome [endpointName]
    // 2. Leia e retorne a resposta enviada pelo ESP32
    return respostaLida;
  }
}
```

### Passo 2: Execute o Provisionamento

Com o transporte pronto, chame a biblioteca para fazer a mágica criptográfica e configurar o Wi-Fi.

```dart
import 'package:ssme_esp_provisioning/ssme_esp_provisioning.dart';

Future<void> configurarPlaca() async {
  // 1. Calcule o PoP (Proof of Possession). 
  // No ESP32, geralmente é um PIN ou as últimas 4 letras do MAC Wi-Fi.
  String popCalculado = "C6A0"; 

  // 2. Injete o seu transporte e o protocolo de segurança
  EspProv prov = EspProv(
    transport: MeuTransporteBle(),
    security: Security1(pop: popCalculado),
  );

  try {
    // 3. Conecta o BLE e faz o Handshake Curve25519 (Geração das chaves AES)
    await prov.establishSession();

    // 4. (Opcional) Escaneia redes ao redor do ESP32
    var redes = await prov.startScanWiFi();
    print("Redes vistas pelo ESP32: $redes");

    // 5. Envia as credenciais criptografadas
    await prov.sendWifiConfig(ssid: 'Sua_Rede', password: 'Sua_Senha');

    // 6. Manda a placa aplicar a rede e tentar conectar
    await prov.applyWifiConfig();
    
    print("Provisionamento enviado com sucesso!");
    
  } catch (e) {
    print("Falha na segurança ou comunicação: $e");
  } finally {
    await prov.dispose(); // Limpa a sessão
  }
}
```

## 5. Protocol Communication Overview

Protocol Communication ([protocomm](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/provisioning/protocomm.html)) component manages secure sessions and provides framework for multiple transports. 
This Dart library acts as the client-side implementation of this protocol, focusing on `protocomm_security1` (Curve25519 key exchange + AES-CTR encryption).

---
![SmartSensing.me Logo](https://smartsensing.me/ssme-logo.png)

## 📝 Descrição

Este projeto faz parte do ecossistema **SmartSensing.me** e vai além dos exemplos básicos encontrados na internet. Aqui, aplicamos os fundamentos reais da engenharia de instrumentação e sistemas embarcados de alta performance.

Diferente de conteúdos superficiais voltados apenas para cliques, este repositório entrega:
- **Ineditismo:** Implementações originais baseadas em quase 30 anos de experiência acadêmica.
- **Densidade Técnica:** Uso profissional do framework ESP-IDF e FreeRTOS.
- **Didática:** Código documentado e estruturado para quem busca evolução técnica real.

> "Transformamos sinais do mundo físico em inteligência digital, sem atalhos."

---

## 🛠️ Tecnologias
- **Hardware Target:** ESP32 / ESP32-S3
- **Framework:** ESP-IDF v5.x
- **Linguagem:** C / C++
- **Simulação:** LTSpice (Modelagem de Sensores)

---

## 👤 Sobre o Autor

**José Alexandre de França** *Professor Adjunto no Departamento de Engenharia Elétrica da UEL*

Engenheiro Eletricista com quase três décadas de experiência no ensino de graduação e pós-graduação. Doutor em Engenharia Elétrica, pesquisador em instrumentação eletrônica e desenvolvedor de sistemas embarcados. O SmartSensing.me é o meu compromisso de elevar o nível da educação tecnológica no Brasil.

- 🌐 **Website:** [smartsensing.me](https://smartsensing.me)
- 📧 **E-mail:** [info@smartsensing.me](mailto:info@smartsensing.me)
- 📺 **YouTube:** [@smartsensingme](https://youtube.com/@smartsensingme)
- 📸 **Instagram:** [@smartsensing.me](https://instagram.com/smartsensing.me)

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para detalhes.

### License
[Apache License Version 2.0](./LICENSE)