// transfer_api.dart (đã sửa hoàn chỉnh, tách 2 baseURL)
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Lưu JWT sau khi đăng nhập (gán ở login_screen)
class AuthStore {
  static String? accessToken;
}

/// API Gateway (Node 5060) cho flow chuyển khoản qua Bonita
class TransferGateway {
  TransferGateway({this.overrideBase});
  final String? overrideBase;

  TransferGateway._internal() : overrideBase = null;
  static final TransferGateway instance = TransferGateway._internal();

  String get _base {
    if (overrideBase != null && overrideBase!.isNotEmpty) return overrideBase!;
    if (kIsWeb) return 'http://localhost:5060';
    if (Platform.isAndroid) return 'http://10.0.2.2:5060';
    return 'http://localhost:5060';
  }

  dynamic _decodeAndCheck(http.Response r) {
    if (r.statusCode >= 400) {
      throw Exception('Lỗi HTTP ${r.statusCode}');
    }

    if (r.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(r.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('success') && decoded['success'] == false) {
            throw Exception(decoded['message'] ?? 'Thao tác thất bại');
          }
          return decoded;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<int> startCase() async {
    final url = Uri.parse('$_base/transfer/start');
    final r = await http.post(url);
    final j = _decodeAndCheck(r);
    final caseId = (j['caseId'] ?? j['processInstance']?['caseId']) as int?;
    if (caseId == null) throw Exception('Không lấy được caseId');
    return caseId;
  }

  Future<void> submitInfo({
    required int caseId,
    required String fromAccountId,
    required String currency,
    required String transferType,
    required double amount,
    String description = '',
    required String clientRequestId,
    String? toAccountId,
    String? toBankId,
    String? toExternalRef,
    String? counterpartyName,
  }) async {
    final jwt = ApiService.instance.getToken();
    if (jwt == null || jwt.isEmpty) {
      throw Exception('Chưa có JWT. Hãy đăng nhập trước.');
    }

    final url = Uri.parse('$_base/transfer/submit-info');
    final payload = {
      "caseId": caseId,
      "payload": {
        "fromAccountId_ct": fromAccountId,
        "toAccountId_ct": toAccountId,
        "currency_ct": currency,
        "transferType_ct": transferType,
        "description_ct": description,
        "clientRequestId_ct": clientRequestId,
        "amount_ct": amount,
        "jwt_ct": jwt,
        "toBankId_ct": toBankId,
        "toExternalRef_ct": toExternalRef,
        "counterpartyName_ct": counterpartyName,
      },
    };

    final r = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );
    _decodeAndCheck(r);
  }

  Future<void> submitPin({
    required int caseId,
    required String accountId,
    required String pin,
  }) async {
    final url = Uri.parse('$_base/transfer/submit-pin');
    final body = {
      "caseId": caseId,
      "payload": {
        "ownerType_ct": "account",
        "accountid_ct": accountId,
        "pin_ct": pin,
      },
    };
    final r = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    _decodeAndCheck(r);
  }

  Future<void> submitOtp({
    required int caseId,
    required String accountId,
    required String otp,
  }) async {
    final url = Uri.parse('$_base/transfer/submit-otp');
    final body = {
      "caseId": caseId,
      "payload": {"accountID_ct": accountId, "otp_ct": otp},
    };

    final r = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    debugPrint('[DEBUG] OTP response: ${r.statusCode} - ${r.body}');

    // Gọi hàm decode như cũ
    _decodeAndCheck(r);
  }

  Future<Map<String, dynamic>> submitExternalSettle({
    required int caseId,
    required String clientRequestId,
    bool success = true,
    String? failureCode,
    String? failureDetail,
  }) async {
    // Đảm bảo dùng đúng base cho Android emulator
    final url = Uri.parse('$_base/transfer/submit-external');
    final body = {
      "caseId": caseId,
      "payload": {
        "clientRequestId_ct": clientRequestId,
        "success_ct": success,
        "failureCode_ct": failureCode,
        "failureDetail_ct": failureDetail,
      },
    };

    // DEBUG FULL: In mọi thứ liên quan
    debugPrint('========== [DEBUG: submitExternalSettle] ==========');
    debugPrint('[SETTLE] URL: $url');
    debugPrint('[SETTLE] caseId: $caseId');
    debugPrint('[SETTLE] clientRequestId: $clientRequestId');
    debugPrint('[SETTLE] Payload: ${jsonEncode(body)}');

    try {
      final r = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      debugPrint('[SETTLE] Response: ${r.statusCode} - ${r.body}');

      _decodeAndCheck(r);
      final response = jsonDecode(r.body) as Map<String, dynamic>;
      return response;
    } catch (e, stack) {
      debugPrint('[SETTLE] Exception khi gọi API: $e\n$stack');
      rethrow;
    } finally {
      debugPrint('========== [END DEBUG: submitExternalSettle] ==========');
    }
  }
}

/// API cho dịch vụ kiểm tra tên người nhận & xác thực (5055)
class TransferServiceAPI {
  TransferServiceAPI._internal();
  static final TransferServiceAPI instance = TransferServiceAPI._internal();

  String get _base {
    if (kIsWeb) return 'http://localhost:5055';
    if (Platform.isAndroid) return 'http://10.0.2.2:5055';
    return 'http://localhost:5055';
  }

  /// Kiểm tra tên người nhận dựa trên mã ngân hàng và mã tham chiếu bên ngoài
  Future<Map<String, dynamic>> nameEnquiry({
    required String? bankId,
    required String externalRef,
  }) async {
    final url = Uri.parse('$_base/api/transfers/name-enquiry');
    final payload = {
      "toBankId": bankId, // null được encode thành null hợp lệ
      "toExternalRef": externalRef,
    };

    final r = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (r.statusCode != 200) {
      throw Exception('Lỗi HTTP ${r.statusCode}: ${r.body}');
    }

    final json = jsonDecode(r.body);
    return json as Map<String, dynamic>;
  }

  /// Kiểm tra xem người nhận có hợp lệ không
  Future<bool> checkBeneficiary({
    required String bankId,
    required String externalRef,
    required String counterpartyName,
  }) async {
    final url = Uri.parse('$_base/api/transfers/check-beneficiary');
    final payload = {
      "toBankId": bankId,
      "toExternalRef": externalRef,
      "counterpartyName": counterpartyName,
    };
    final r = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );
    final json = jsonDecode(r.body);
    return json['success'] == true;
  }

  Future<String?> fetchOtpFromBackend(String accountId) async {
    final token = await ApiService.instance.getToken();
    debugPrint('[DEBUG] Gọi fetchOtpFromBackend với token: $token');
    if (token == null) {
      debugPrint('[ERROR] Không lấy được JWT token');
      return null;
    }
    await Future.delayed(const Duration(seconds: 1)); // Giả lập delay
    final url = Uri.parse('http://10.0.2.2:5055/api/transfers/otp/$accountId');

    final res = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    debugPrint('[DEBUG] OTP response: ${res.statusCode} ${res.body}');
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return json['otp']?.toString();
    } else {
      debugPrint('[ERROR] OTP GET failed: ${res.statusCode} - ${res.body}');
      return null;
    }
  }
}
