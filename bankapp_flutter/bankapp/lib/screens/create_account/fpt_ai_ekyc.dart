import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:qr_code_tools/qr_code_tools.dart';

import 'case_init_screen.dart';

class FptAIEkycScreen extends StatefulWidget {
  const FptAIEkycScreen({super.key});
  @override
  State<FptAIEkycScreen> createState() => _FptAIEkycScreenState();
}

class _FptAIEkycScreenState extends State<FptAIEkycScreen> {
  File? frontCCCDFile; // bắt buộc
  File? backCCCDFile; // tùy chọn
  File? selfieFile; // bắt buộc

  String result = '';
  int step = 0;

  // Cache URL upload Cloudinary theo key
  final Map<String, String> uploadCache = {};

  // ========= Config Cloudinary =========
  final String cloudinaryApi =
      'https://api.cloudinary.com/v1_1/dbwdohabb/image/upload';
  final String uploadPreset = 'ml_default';

  // ========= Config FPT.AI =========
  final String fptEndpoint = 'https://api.fpt.ai/dmp/checkface/v1';
  final String fptApiKey = 'hTXhmB1lVQMBk7xEZiXEFKqHisALSEiX'; // FPT.AI API Key

  Map<String, dynamic> qrData = {};

  // ======================== UI HELPERS ========================
  void _showNiceProgress(String title, {String? note}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: 8),
                Text(
                  note,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _updateNiceProgress(String newTitle, {String? note}) {
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    _showNiceProgress(newTitle, note: note);
  }

  void _closeNiceProgress() {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _showResultSheet({
    required bool success,
    required String title,
    String? subtitle,
    List<String> bulletLines = const [],
    String primaryText = 'OK',
    VoidCallback? onPrimary,
    String? secondaryText,
    VoidCallback? onSecondary,
  }) {
    final color = success ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final icon = success ? Icons.verified_rounded : Icons.error_rounded;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 32,
                backgroundColor: color.withOpacity(.12),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
              if (bulletLines.isNotEmpty) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: bulletLines
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('•  ', style: TextStyle(fontSize: 14)),
                              Expanded(
                                child: Text(
                                  t,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  if (secondaryText != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onSecondary?.call();
                        },
                        child: Text(secondaryText),
                      ),
                    ),
                  if (secondaryText != null) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onPrimary?.call();
                      },
                      child: Text(primaryText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  // ======================== UTILS ========================
  String _detectGender(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('nam') || lower == 'm' || lower.contains('male')) {
      return 'male';
    }
    if (lower.contains('nữ') ||
        lower.contains('nu') ||
        lower == 'f' ||
        lower.contains('female')) {
      return 'female';
    }
    return 'other';
  }

  bool _looksLikeImage(File f) {
    final name = f.path.toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.heic');
  }

  Future<Uint8List> resizeImageOptimal(
    File file, {
    String purpose = 'upload',
  }) async {
    final args = {'file': file.path, 'purpose': purpose};
    return compute(_resizeImageIsolate, args);
  }

  static Uint8List _resizeImageIsolate(Map<String, dynamic> args) {
    final filePath = args['file'] as String;
    final purpose = args['purpose'] as String;
    final originalBytes = File(filePath).readAsBytesSync();
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) return originalBytes;

    img.Image image = decoded;

    // Min 640x480 cho FPT
    if (purpose == 'fpt_api') {
      if (image.width < 640 || image.height < 480) {
        final scale = math.max(640 / image.width, 480 / image.height);
        image = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
        );
      }
    }

    // Resize nếu quá lớn
    int maxWidth = (purpose == 'fpt_api')
        ? 1024
        : (purpose == 'upload' ? 1200 : 800);
    if (image.width > maxWidth) image = img.copyResize(image, width: maxWidth);

    // Luôn encode JPEG
    int quality = (purpose == 'fpt_api') ? 85 : (purpose == 'upload' ? 80 : 75);
    Uint8List out = Uint8List.fromList(img.encodeJpg(image, quality: quality));

    // ≤5MB cho FPT
    if (purpose == 'fpt_api') {
      while (out.length > 5 * 1024 * 1024 && quality > 60) {
        quality -= 5;
        out = Uint8List.fromList(img.encodeJpg(image, quality: quality));
      }
    }
    return out;
  }

  IOClient _newIoClient() {
    final io = HttpClient()
      // ⬇ tăng timeout kết nối để tránh lỗi 10s trên emulator
      ..connectionTimeout = const Duration(seconds: 25)
      ..idleTimeout = const Duration(seconds: 20);
    return IOClient(io);
  }

  // UPDATED: backoff + jitter dùng chung
  Duration _backoffWithJitter(
    int attempt, {
    int baseMs = 600,
    int maxMs = 5000,
  }) {
    final expo = baseMs * math.pow(2, attempt - 1).toInt();
    final jitter = math.Random().nextInt(250);
    return Duration(milliseconds: math.min(expo + jitter, maxMs));
  }

  // Tạo mới MultipartRequest cho mỗi attempt bằng builder
  Future<http.StreamedResponse> _sendFptWithRetry(
    http.MultipartRequest Function() buildRequest,
  ) async {
    final client = _newIoClient();
    const maxRetries = 3;
    try {
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        final req = buildRequest();
        try {
          req.persistentConnection = false;
          req.headers['Connection'] = 'close';
          req.headers['Cache-Control'] = 'no-cache';
          req.headers['Expect'] = '';
          return await client.send(req).timeout(const Duration(seconds: 60));
        } on TimeoutException {
          if (attempt == maxRetries) rethrow;
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        } on SocketException {
          if (attempt == maxRetries) rethrow;
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        } on http.ClientException {
          if (attempt == maxRetries) rethrow;
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
      throw Exception('Không thể gửi yêu cầu tới FPT sau nhiều lần thử.');
    } finally {
      client.close();
    }
  }

  // ======================== QR từ ảnh CCCD mặt trước ========================
  Future<void> _scanQRCode(File file) async {
    try {
      final decoded = await QrCodeToolsPlugin.decodeFrom(file.path);
      if (decoded != null && decoded.contains('|')) {
        final parts = decoded.split('|');
        String? cccd, fullName, dob, address, gender;

        for (final raw in parts) {
          final part = raw.trim();
          if (RegExp(r'^\d{12}$').hasMatch(part) && cccd == null) {
            cccd = part;
          } else if (RegExp(r'^\d{8}$').hasMatch(part) && dob == null) {
            dob = part;
          } else if ((part.toLowerCase().contains('nam') ||
                  part.toLowerCase().contains('nữ') ||
                  part.toLowerCase().contains('male') ||
                  part.toLowerCase().contains('female') ||
                  part.toLowerCase() == 'm' ||
                  part.toLowerCase() == 'f') &&
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

        qrData = {
          "cccd": cccd ?? "",
          "fullName": fullName ?? "",
          "dob": dob ?? "",
          "address": address ?? "",
          "gender": gender ?? "other",
        };
        setState(() => result = 'Đã quét QR thành công.');
      } else {
        setState(() => result = 'Không đọc được mã QR từ ảnh.');
      }
    } catch (e) {
      setState(() => result = 'Lỗi quét mã QR: $e');
    }
  }

  // ======================== Pick file ========================
  Future<void> pickFile(int index) async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image);
    if (picked == null) return;
    final file = File(picked.files.single.path!);

    setState(() {
      if (index == 0) {
        frontCCCDFile = file;
      } else if (index == 1) {
        backCCCDFile = file;
      } else if (index == 2) {
        selfieFile = file;
      }
    });

    if (index == 0) await _scanQRCode(file);
  }

  // ======================== Cloudinary Upload ========================
  // UPDATED: Retry thông minh + tôn trọng Retry-After + cache theo nội dung
  // Trả về tuple dạng (url, error). url != null là OK; error != null là có lỗi chi tiết.
  Future<(String?, String?)> uploadToCloudinaryOptimizedWithError(
    File file,
    String folder, {
    String purpose = 'upload',
  }) async {
    final bytesForHash = await file.readAsBytes();
    final hash =
        bytesForHash.length ^
        bytesForHash.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    final cacheKey = '${hash}_$folder\_$purpose';
    if (uploadCache.containsKey(cacheKey)) return (uploadCache[cacheKey], null);

    final client = _newIoClient();
    const int maxRetries = 4;
    String? lastError;

    final resizedBytes = await resizeImageOptimal(file, purpose: purpose);
    try {
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          final req = http.MultipartRequest('POST', Uri.parse(cloudinaryApi))
            ..persistentConnection = false
            ..headers['Connection'] = 'close'
            ..headers['Expect'] = ''
            ..fields['upload_preset'] = uploadPreset
            ..fields['folder'] = folder
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                resizedBytes,
                filename: 'img_${DateTime.now().microsecondsSinceEpoch}.jpg',
                contentType: MediaType('image', 'jpeg'),
              ),
            );

          final streamed = await client
              .send(req)
              .timeout(const Duration(seconds: 60));
          final status = streamed.statusCode;
          final body = await streamed.stream.bytesToString();

          if (kDebugMode) {
            debugPrint('Cloudinary attempt $attempt -> $status');
            if (status != 200) debugPrint('Body: $body');
          }
          if (kDebugMode) {
            debugPrint(
              'Cloudinary payload bytes: front=${frontCCCDFile?.lengthSync()} selfie=${selfieFile?.lengthSync()}',
            );
          }

          if (status == 200) {
            try {
              final jsonData = json.decode(body);
              final url = jsonData['secure_url'] as String?;
              if (url != null) {
                uploadCache[cacheKey] = url;
                return (url, null);
              } else {
                lastError = '200 nhưng thiếu secure_url: $body';
              }
            } catch (e) {
              lastError = 'JSON parse error: $e';
            }
          } else if (status == 429 || (status >= 500 && status < 600)) {
            // tôn trọng Retry-After
            final retryAfterHeader = streamed.headers['retry-after'];
            if (retryAfterHeader != null) {
              final secs = int.tryParse(retryAfterHeader.trim());
              if (secs != null && secs > 0) {
                await Future.delayed(Duration(seconds: secs));
                continue;
              }
            }
            lastError = 'HTTP $status: $body';
            if (attempt < maxRetries) {
              await Future.delayed(_backoffWithJitter(attempt));
              continue;
            } else {
              return (null, lastError);
            }
          } else if (status >= 400 && status < 500) {
            // lỗi cấu hình/preset/file → trả ngay
            lastError = 'HTTP $status: $body';
            return (null, lastError);
          } else {
            lastError = 'HTTP $status: $body';
            if (attempt < maxRetries) {
              await Future.delayed(_backoffWithJitter(attempt));
              continue;
            }
            return (null, lastError);
          }
        } on TimeoutException {
          lastError = 'Timeout';
          if (attempt == maxRetries) return (null, lastError);
          await Future.delayed(_backoffWithJitter(attempt));
        } on SocketException catch (e) {
          lastError = 'SocketException: $e';
          if (attempt == maxRetries) return (null, lastError);
          await Future.delayed(_backoffWithJitter(attempt));
        } on http.ClientException catch (e) {
          lastError = 'ClientException: $e';
          if (attempt == maxRetries) return (null, lastError);
          await Future.delayed(_backoffWithJitter(attempt));
        } catch (e) {
          lastError = 'Exception: $e';
          if (attempt == maxRetries) return (null, lastError);
          await Future.delayed(_backoffWithJitter(attempt));
        }
      }

      return (null, lastError ?? 'Unknown error');
    } finally {
      client.close(); // <-- QUAN TRỌNG
    }
  }

  // ======================== Gửi FPT.AI (chuẩn tài liệu) ========================
  Future<void> sendToFPT() async {
    // Validate đầu vào
    if (frontCCCDFile == null || selfieFile == null) {
      await _showResultSheet(
        success: false,
        title: 'Không thể tiếp tục',
        subtitle: 'Thiếu ảnh hoặc ảnh không hợp lệ',
        bulletLines: [
          'Cần đúng 2 ảnh: CCCD mặt trước và Selfie.',
          'Định dạng JPEG, dung lượng ≤ 5MB, ≥ 640×480.',
        ],
        primaryText: 'Hiểu rồi',
      );
      return;
    }
    if (!_looksLikeImage(frontCCCDFile!) || !_looksLikeImage(selfieFile!)) {
      await _showResultSheet(
        success: false,
        title: 'Tệp không phải ảnh',
        subtitle: 'Vui lòng chọn file ảnh JPG/JPEG/PNG/HEIC',
        primaryText: 'Đã hiểu',
      );
      return;
    }

    _showNiceProgress(
      'Chuẩn bị ảnh...',
      note: 'Tối ưu dung lượng & độ phân giải',
    );
    try {
      // Size raw >10MB: cảnh báo sớm
      final frontRaw = frontCCCDFile!.lengthSync();
      final selfieRaw = selfieFile!.lengthSync();
      if (frontRaw > 10 * 1024 * 1024 || selfieRaw > 10 * 1024 * 1024) {
        _closeNiceProgress();
        await _showResultSheet(
          success: false,
          title: 'Ảnh quá lớn',
          subtitle: 'File gốc > 10MB, hãy chọn ảnh nhỏ hơn.',
          primaryText: 'Đã hiểu',
        );
        return;
      }

      // Chuẩn hóa ảnh cho FPT
      _updateNiceProgress(
        'Đang chuẩn hóa ảnh...',
        note: 'JPEG • ≥640×480 • ≤5MB',
      );
      final preparedImages = await Future.wait<Uint8List>([
        resizeImageOptimal(frontCCCDFile!, purpose: 'fpt_api'),
        resizeImageOptimal(selfieFile!, purpose: 'fpt_api'),
      ]);
      final frontSizeMB = preparedImages[0].length / (1024 * 1024);
      final selfieSizeMB = preparedImages[1].length / (1024 * 1024);
      if (frontSizeMB > 5.0 || selfieSizeMB > 5.0) {
        _closeNiceProgress();
        await _showResultSheet(
          success: false,
          title: 'Ảnh quá lớn',
          subtitle: 'Sau khi nén vẫn > 5MB, FPT sẽ từ chối.',
          primaryText: 'Đã hiểu',
        );
        return;
      }

      // Gửi FPT
      _updateNiceProgress(
        'Đang gửi FPT.AI...',
        note: 'Kiểm tra khuôn mặt (FaceMatch)',
      );
      final uri = Uri.parse(fptEndpoint);

      http.MultipartRequest _buildReq() {
        final r = http.MultipartRequest('POST', uri)
          ..persistentConnection = false
          ..headers['Expect'] = ''
          ..headers['Connection'] = 'close'
          ..headers['Cache-Control'] = 'no-cache'
          ..headers['api_key'] = fptApiKey
          ..files.add(
            http.MultipartFile.fromBytes(
              'file[]',
              preparedImages[0],
              filename: 'front_${DateTime.now().millisecondsSinceEpoch}.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          )
          ..files.add(
            http.MultipartFile.fromBytes(
              'file[]',
              preparedImages[1],
              filename: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        return r;
      }

      final streamed = await _sendFptWithRetry(_buildReq);
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode != 200) {
        _closeNiceProgress();
        await _showResultSheet(
          success: false,
          title: 'FPT HTTP ${streamed.statusCode}',
          subtitle: body,
          primaryText: 'Đã hiểu',
        );
        return;
      }

      final data = json.decode(body);
      final code = data['code']?.toString() ?? '200';
      if (code != '200') {
        _closeNiceProgress();
        String msg;
        switch (code) {
          case '407':
            msg = 'Không nhận dạng được khuôn mặt (407).';
            break;
          case '408':
            msg = 'Ảnh đầu vào không đúng định dạng JPEG (408).';
            break;
          case '409':
            msg = 'Cần đúng 2 ảnh để xác thực (409).';
            break;
          default:
            msg = 'Lỗi FPT ($code): ${data['message'] ?? 'Unknown'}';
        }
        await _showResultSheet(
          success: false,
          title: 'Xác thực thất bại',
          subtitle: msg,
          bulletLines: [
            'Chụp selfie rõ mặt, đủ sáng.',
            'Khuôn mặt nên chiếm ≥ 1/4 khung hình.',
            'Tránh che mặt / ngược sáng.',
          ],
          primaryText: 'Thử lại',
        );
        return;
      }

      final bool isMatch = data['data']?['isMatch'] == true;
      final double similarity = (data['data']?['similarity'] ?? 0).toDouble();
      final bool isBothImgIDCard = data['data']?['isBothImgIDCard'] == true;

      _closeNiceProgress();

      if (!isMatch || similarity < 80.0) {
        await _showResultSheet(
          success: false,
          title: 'Không khớp khuôn mặt',
          subtitle: 'Similarity: ${similarity.toStringAsFixed(2)}%',
          bulletLines: [
            if (isBothImgIDCard)
              'Cả 2 ảnh đều là CMND/CCCD (không phải selfie).',
            'Thử chụp lại selfie rõ hơn, đủ sáng.',
          ],
          primaryText: 'Thử lại',
        );
        return;
      }

      // Thành công → hỏi tiếp để upload
      final proceed = Completer<void>();
      await _showResultSheet(
        success: true,
        title: 'Xác thực khuôn mặt thành công',
        subtitle: 'Độ tương đồng: ${similarity.toStringAsFixed(2)}%',
        bulletLines: [
          'Ảnh 1: CCCD mặt trước (hợp lệ)',
          'Ảnh 2: Selfie (hợp lệ)',
          if (isBothImgIDCard) 'Lưu ý: Hệ thống nhận thấy cả hai ảnh là CCCD.',
        ],
        primaryText: 'Tiếp tục',
        onPrimary: () => proceed.complete(),
      );
      await proceed.future;

      // UPDATED: Upload tuần tự (thay vì Future.wait song song)
      _showNiceProgress('Đang upload ảnh...', note: 'Cloudinary • tuần tự');
      final stopwatch = Stopwatch()..start();
      final cccdNumber = qrData['cccd'] ?? extractCCCD(frontCCCDFile!);
      final folder = 'thuctap/$cccdNumber';

      // 1/3
      _updateNiceProgress('Đang upload ảnh (1/3)...');
      final (frontUrl, frontErr) = await uploadToCloudinaryOptimizedWithError(
        frontCCCDFile!,
        folder,
        purpose: 'upload',
      );

      // 2/3
      String? backUrl;
      String? backErr;
      if (backCCCDFile != null) {
        _updateNiceProgress('Đang upload ảnh (2/3)...');
        (backUrl, backErr) = await uploadToCloudinaryOptimizedWithError(
          backCCCDFile!,
          folder,
          purpose: 'upload',
        );
      }

      // 3/3
      _updateNiceProgress('Đang upload ảnh (3/3)...');
      final (selfieUrl, selfieErr) = await uploadToCloudinaryOptimizedWithError(
        selfieFile!,
        folder,
        purpose: 'upload',
      );

      final uploads = [frontUrl, backUrl, selfieUrl];
      final errors = [frontErr, backErr, selfieErr];

      // Bổ sung default field nếu QR thiếu
      qrData['cccd'] ??= cccdNumber;
      qrData['fullName'] ??= 'Nguyen Van A';
      qrData['dob'] ??= '20000101';
      qrData['address'] ??= 'Hà Nội';
      qrData['gender'] ??= 'male';
      qrData['images'] = {
        'front': uploads[0],
        'back': uploads[1],
        'selfie': uploads[2],
      };

      _closeNiceProgress();

      if (!mounted) return;
      await _showResultSheet(
        success: (frontUrl != null || selfieUrl != null),
        title: 'Hoàn tất eKYC',
        subtitle: 'Upload xong trong ${stopwatch.elapsed.inSeconds}s',
        bulletLines: [
          'Front: ${uploads[0] != null ? "OK" : "Lỗi"}'
              '${uploads[0] == null && errors[0] != null ? " — ${errors[0]}" : ""}',
          'Back: ${backCCCDFile == null ? "Bỏ qua" : (uploads[1] != null ? "OK" : "Lỗi")}'
              '${uploads[1] == null && errors[1] != null ? " — ${errors[1]}" : ""}',
          'Selfie: ${uploads[2] != null ? "OK" : "Lỗi"}'
              '${uploads[2] == null && errors[2] != null ? " — ${errors[2]}" : ""}',
        ],
        primaryText: 'Tiếp tục hồ sơ',
        onPrimary: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CaseInitScreen(initialData: qrData),
            ),
          );
        },
      );
    } catch (e) {
      _closeNiceProgress();
      await _showResultSheet(
        success: false,
        title: 'Có lỗi xảy ra',
        subtitle: e.toString(),
        primaryText: 'Đã hiểu',
      );
    }
  }

  // ======================== Helpers khác ========================
  String extractCCCD(File file) {
    final fileName = file.path.split('/').last;
    final match = RegExp(r'\d{9,12}').firstMatch(fileName);
    return match?.group(0) ?? '012345678901';
  }

  Widget imagePreview(
    File? file,
    String label, {
    bool isCCCD = false,
    bool isSelfie = false,
  }) {
    final cacheKeyFront =
        '${file?.path}_thuctap/${qrData['cccd'] ?? ''}_upload';
    final isCached = file != null && uploadCache.containsKey(cacheKeyFront);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: isCCCD ? 85.6 / 53.98 : (isSelfie ? 1 : 1.2),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                isCCCD ? 12 : (isSelfie ? 100 : 8),
              ),
              border: Border.all(color: Colors.grey.shade400, width: 1),
              boxShadow: isCCCD || isSelfie
                  ? [
                      const BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ]
                  : [],
            ),
            clipBehavior: Clip.hardEdge,
            child: file != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(file, fit: BoxFit.cover),
                      if (isCached)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            Icons.cloud_done,
                            color: Colors.green,
                            size: 18,
                          ),
                        ),
                    ],
                  )
                : const Center(child: Text('Chưa chọn ảnh')),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'title': 'Chọn ảnh CCCD mặt trước',
        'file': frontCCCDFile,
        'onPick': () => pickFile(0),
        'isCCCD': true,
        'isSelfie': false,
      },
      {
        'title': 'Chọn ảnh CCCD mặt sau (tùy chọn)',
        'file': backCCCDFile,
        'onPick': () => pickFile(1),
        'isCCCD': true,
        'isSelfie': false,
      },
      {
        'title': 'Chọn ảnh chân dung (selfie)',
        'file': selfieFile,
        'onPick': () => pickFile(2),
        'isCCCD': false,
        'isSelfie': true,
      },
    ];
    final current = steps[step];

    return Scaffold(
      appBar: AppBar(
        title: const Text('eKYC Xác thực FPT.AI'),
        backgroundColor: const Color(0xFF2872C6),
        actions: [
          IconButton(
            icon: const Icon(Icons.cached),
            tooltip: 'Xóa cache upload',
            onPressed: () => setState(() {
              uploadCache.clear();
              result = 'Đã xóa cache upload.';
            }),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              current['title'] as String,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            imagePreview(
              current['file'] as File?,
              '',
              isCCCD: current['isCCCD'] as bool,
              isSelfie: current['isSelfie'] as bool,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: current['onPick'] as VoidCallback,
              icon: const Icon(Icons.image),
              label: const Text('Chọn ảnh'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (step > 0)
                  ElevatedButton(
                    onPressed: () => setState(() => step -= 1),
                    child: const Text('Quay lại'),
                  ),
                if (step < steps.length - 1)
                  ElevatedButton(
                    onPressed: () => setState(() => step += 1),
                    child: const Text('Tiếp theo'),
                  ),
                if (step == 2)
                  ElevatedButton.icon(
                    onPressed: sendToFPT,
                    icon: const Icon(Icons.verified),
                    label: const Text('Xác minh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (kDebugMode && result.isNotEmpty) // chỉ show log khi debug
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      result,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
