import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_tools/qr_code_tools.dart';

class UploadQRScreen extends StatefulWidget {
  @override
  _UploadQRScreenState createState() => _UploadQRScreenState();
}

class _UploadQRScreenState extends State<UploadQRScreen> {
  final ImagePicker picker = ImagePicker();

  Future<void> pickImageAndDecodeQR({required ImageSource source}) async {
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final length = await file.length();

      if (length < 1000) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ảnh quá nhỏ hoặc không hợp lệ")),
        );
        return;
      }

      try {
        String? result = await QrCodeToolsPlugin.decodeFrom(pickedFile.path);
        print("Raw QR content: $result");

        if (result == null || result.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Không đọc được dữ liệu QR")));
          return;
        }

        List<String> parts = result.split('|');
        print("QR parts: $parts");

        String? cccd, fullName, dob, address, gender;

        for (int i = 0; i < parts.length; i++) {
          String part = parts[i].trim();
          if (RegExp(r'^\d{12}$').hasMatch(part) && cccd == null) {
            cccd = part;
          } else if (RegExp(r'^\d{8}$').hasMatch(part) && dob == null) {
            dob = part;
          } else if ((part.toLowerCase().contains('nam') ||
                  part.toLowerCase().contains('nữ') ||
                  part.toLowerCase().contains('m') ||
                  part.toLowerCase().contains('f') ||
                  part.toLowerCase().contains('male') ||
                  part.toLowerCase().contains('female')) &&
              gender == null) {
            gender = _detectGender(part);
          } else if (part.contains(' ') &&
              !RegExp(r'^\d').hasMatch(part) &&
              fullName == null &&
              cccd != null) {
            fullName = part;
          } else if (part.contains(' ') &&
              address == null &&
              fullName != null &&
              dob != null) {
            address = part;
          }
        }

        if (cccd == null && parts.isNotEmpty) cccd = parts[0];
        if (fullName == null && parts.length > 2) fullName = parts[2];
        if (dob == null && parts.length > 3) dob = parts[3];
        if (gender == null) gender = "other";
        if (address == null && parts.length > 5) address = parts[5];

        if (dob != null && RegExp(r'^\d{8}$').hasMatch(dob)) {
          final d = dob.substring(0, 2);
          final m = dob.substring(2, 4);
          final y = dob.substring(4, 8);
          dob = "$d/$m/$y";
        }

        if (cccd == null || fullName == null || dob == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("QR thiếu CCCD, Họ tên hoặc Ngày sinh")),
          );
          return;
        }

        print("Detected gender from QR: $gender");

        Navigator.pop(context, {
          "cccd": cccd,
          "fullName": fullName,
          "dob": dob,
          "address": address ?? "",
          "gender": gender,
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi khi đọc QR: $e")));
      }
    }
  }

  String _detectGender(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('nam') ||
        lower.contains('m') ||
        lower.contains('male')) {
      return 'male';
    }
    if (lower.contains('nữ') ||
        lower.contains('nu') ||
        lower.contains('f') ||
        lower.contains('female')) {
      return 'female';
    }
    return 'other';
  }

  void _showPickOptionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Chọn nguồn ảnh"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text("Chụp ảnh"),
              onTap: () {
                Navigator.pop(context);
                pickImageAndDecodeQR(source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text("Chọn từ thư viện"),
              onTap: () {
                Navigator.pop(context);
                pickImageAndDecodeQR(source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quét CCCD từ ảnh")),
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.upload_file),
          label: Text("Upload/Chụp ảnh CCCD"),
          onPressed: _showPickOptionDialog,
        ),
      ),
    );
  }
}
