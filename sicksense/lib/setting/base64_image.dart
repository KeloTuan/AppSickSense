import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class Base64ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Converts a [File] or image in [Uint8List] format to a base64 string
  String encodeImageToBase64(Uint8List imageBytes) {
    return base64Encode(imageBytes);
  }

  /// Decodes a base64 string back into image bytes ([Uint8List])
  Uint8List decodeBase64Image(String base64String) {
    return base64Decode(base64String);
  }

  /// Uploads a base64 encoded image to Firebase Storage
  Future<String> uploadBase64Image(String base64String, String fileName) async {
    try {
      // Decode the base64 string to get the image bytes
      Uint8List imageBytes = decodeBase64Image(base64String);

      // Reference to Firebase Storage
      Reference storageRef = _storage.ref().child('images/$fileName');

      // Upload the image bytes to Firebase Storage
      UploadTask uploadTask = storageRef.putData(imageBytes);

      // Wait for the upload to complete and get the download URL
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  /// Uploads an image from [Uint8List] format directly to Firebase Storage
  Future<String> uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      // Reference to Firebase Storage
      Reference storageRef = _storage.ref().child('images/$fileName');

      // Upload the image bytes to Firebase Storage
      UploadTask uploadTask = storageRef.putData(imageBytes);

      // Wait for the upload to complete and get the download URL
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }
}
