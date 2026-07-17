import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EncryptionService {
  // Static key derived for emergency app local testing. In production, 
  // key derivation would combine user credentials with secure hardware keys (Keystore/Keychain).
  static final _iv = encrypt.IV.fromLength(16);

  static encrypt.Key _getKey(String salt) {
    // Generate a 32-byte key derived from a static signature and the user's unique UID
    final rawKey = (salt + "RapidAidSecureSignatureSaltKey").substring(0, 32);
    return encrypt.Key.fromUtf8(rawKey);
  }

  /// Encrypts plain text content using AES-256 and writes to local file system.
  static Future<File> encryptAndWriteFile(String fileName, String plainText) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? "default_local_user";
    
    final key = _getKey(uid);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(plainText, iv: _iv);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');

    return await file.writeAsString(encrypted.base64);
  }

  /// Reads local encrypted file and returns decrypted plain text.
  static Future<String> readAndDecryptFile(String fileName) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? "default_local_user";

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');

    if (!await file.exists()) {
      return "";
    }

    final encryptedBase64 = await file.readAsString();

    final key = _getKey(uid);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    try {
      final decrypted = encrypter.decrypt(encrypt.Encrypted.fromBase64(encryptedBase64), iv: _iv);
      return decrypted;
    } catch (e) {
      print("❌ Decryption failed for $fileName: $e");
      // If decryption fails, clear the corrupted file
      await file.delete();
      return "";
    }
  }
}
