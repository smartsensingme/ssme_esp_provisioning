import 'dart:async';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class Crypt {
  late CTRStreamCipher _cipher;

  Future<bool> init(Uint8List key, Uint8List iv) async {
    final engine = AESEngine();
    _cipher = CTRStreamCipher(engine);
    _cipher.init(true, ParametersWithIV(KeyParameter(key), iv));
    return true;
  }

  Future<Uint8List> crypt(Uint8List data) async {
    return _cipher.process(data);
  }
}
