import 'dart:io';

import 'package:crypto/crypto.dart';

class BookFingerprintService {
  const BookFingerprintService();

  Future<String> fingerprint(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }
}
