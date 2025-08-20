import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class ApiService {
  static FlutterSecureStorage get storage => _storage;
  static const _storage = FlutterSecureStorage();
  ApiService._internal();
  static final ApiService instance = ApiService._internal();
  // HOST CHO ANDROID EMULATOR
  // LƯU Ý: đừng dùng localhost ở Android; phải là 10.0.2.2
  static const String userServiceUrl =
      'http://10.0.2.2:5000/api'; // user-service
  static const String otpServiceUrl =
      'http://10.0.2.2:5001/api/otp'; // otp-service
  static const String accountServiceUrl =
      'http://10.0.2.2:5053/workflow/account'; // gateway-api

  // Các biến cũ, vẫn giữ để tương thích
  static const String baseUrl = 'http://';

  // Gateway base cho các tiện ích chung
  static const String kGatewayBase = 'http://10.0.2.2:5053';
  static const String kUserServiceBase = 'http://10.0.2.2:5000';

  // Helper: build SSE URI cho state theo dõi phê duyệt
  static Uri sseStateUri(String caseId) => Uri.parse(
    '$kGatewayBase/workflow/account/state/stream?caseId=${Uri.encodeComponent(caseId)}',
  );

  //===============================auth service=================================
  Future<void> _saveToken(String token) async {
    _jwtToken = token;
    await _storage.write(key: 'auth_token', value: token);
    await _updateLastActive();
  }

  Future<void> _updateLastActive() async {
    await _storage.write(
      key: 'last_active_time',
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<String?> _getToken() async {
    final token = await _storage.read(key: 'auth_token');
    final lastActiveStr = await _storage.read(
      key: 'last_active_time',
    ); 
    if (token == null || lastActiveStr == null) return null;

    late DateTime lastActive;
    try {
      lastActive = DateTime.fromMillisecondsSinceEpoch(
        int.parse(lastActiveStr),
      );
    } catch (_) {
      return null; // sai format → xem như chưa đăng nhập
    }

    if (DateTime.now().difference(lastActive).inMinutes > 10) {
      await logout();
      return null;
    }

    // cập nhật lại mỗi lần dùng
    await _storage.write(
      key: 'last_active_time',
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    return token;
  }

  String? _jwtToken;

  /// Lấy JWT hiện tại (dùng trong transfer_api.dart)
  String? getToken() {
    return _jwtToken;
  }

  Future<void> keepSessionAlive() async {
    final token = await _getToken();
    if (token == null) return;
    final response = await http.get(
      Uri.parse('$userServiceUrl/customers/ping'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      print(' Ping thất bại: ${response.body}');
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$userServiceUrl/customers/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['accessToken']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception('Token không hợp lệ');
      }
      await _saveToken(token);
      await getUserProfile();
    } else {
      String message = 'Đăng nhập thất bại';
      try {
        final data = jsonDecode(response.body);
        message = data['message']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final token = await _getToken();
    if (token == null) throw Exception('Chưa đăng nhập');

    final response = await http.get(
      Uri.parse('$userServiceUrl/customers/user-profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storage.write(
        key: 'username',
        value: data['username']?.toString(),
      );
      await _storage.write(key: 'role', value: data['role']?.toString());
      await _storage.write(
        key: 'customer_id',
        value: data['customer']?['customerId']?.toString(),
      );
      if (data['customer'] != null) {
        final c = data['customer'];
        await _storage.write(
          key: 'customer_name',
          value: c['name']?.toString(),
        );
        await _storage.write(
          key: 'customer_cccd',
          value: c['cccd']?.toString(),
        );
        await _storage.write(
          key: 'customer_email',
          value: c['email']?.toString(),
        );
        await _storage.write(
          key: 'customer_phone',
          value: c['phone']?.toString(),
        );
        await _storage.write(key: 'customer_dob', value: c['dob']?.toString());
        await _storage.write(
          key: 'customer_hometown',
          value: c['hometown']?.toString(),
        );
        await _storage.write(
          key: 'customer_status',
          value: c['status']?.toString(),
        );
      }
      if (data['account'] != null) {
        final a = data['account'];
        await _storage.write(
          key: 'account_id',
          value: a['accountId']?.toString(),
        );
        await _storage.write(
          key: 'account_number',
          value: a['accountNumber']?.toString(),
        );
        await _storage.write(
          key: 'account_balance',
          value: a['balance']?.toString(),
        );
        await _storage.write(key: 'account_type', value: a['type']?.toString());
        await _storage.write(
          key: 'account_createdAt',
          value: a['createdAt']?.toString(),
        );
      } else {
        print('⚠️ account null trong response.');
      }
      return data;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Lấy thông tin người dùng thất bại');
    }
  }

  Future<String?> getCustomerId() async =>
      await _storage.read(key: 'customer_id');
  Future<String?> getAccountId() async =>
      await _storage.read(key: 'account_id');

  //===============================case and otp service=================================
  Future<Map<String, dynamic>> createCase(User user) async {
    final url = Uri.parse('$accountServiceUrl/start');

    String _formatDob(String dob) {
      if (dob.contains('/')) {
        final p = dob.split('/');
        if (p.length == 3)
          return '${p[2]}-${p[1].padLeft(2, '0')}-${p[0].padLeft(2, '0')}';
      }
      if (dob.length == 8 && RegExp(r'^\d{8}$').hasMatch(dob)) {
        final d = dob.substring(0, 2),
            m = dob.substring(2, 4),
            y = dob.substring(4, 8);
        return '$y-$m-$d';
      }
      return dob;
    }

    final body = {
      "accountDataInput1": {
        "phone": user.phone,
        "email": user.email,
        "name": user.fullName,
        "dob": _formatDob(user.dob),
        "cccd": user.idCard,
        "hometown": user.hometown,
        "gender": user.gender,
        "status": "pending",
        "customerId": "",
      },
    };

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Lỗi tạo Case: ${res.statusCode} - ${res.body}");
    }
  }

  Future<void> sendOtp(String phone, String email) async {
    final response = await http.post(
      Uri.parse('$otpServiceUrl/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'email': email}),
    );
    if (response.statusCode != 200) {
      throw Exception('Gửi OTP thất bại: ${response.statusCode}');
    }
  }

  Future<void> verifyOtp({
    required String caseId,
    required String phone,
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$accountServiceUrl/otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'caseId': caseId,
        'phone': phone,
        'email': email,
        'otp': otp,
      }),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(
        'Xác minh OTP thất bại: ${data['error'] ?? response.statusCode}',
      );
    }
  }

  Future<void> resendOtp({required String phone, required String email}) async {
    final response = await http.post(
      Uri.parse('$otpServiceUrl/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'email': email, 'method': 'email'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Gửi lại OTP thất bại: ${response.statusCode}');
    }
  }

  Future<bool?> checkAccountNumberExists(String accountNumber) async {
    try {
      if (!RegExp(r'^\d{8,20}$').hasMatch(accountNumber)) return null;
      final uri = Uri.parse(
        '$kUserServiceBase/api/accounts/check-number?accountNumber=$accountNumber',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['exists'] == true;
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  Future<({bool ok, String message, String? taskId})>
  submitAccountNumberToBonita({
    String? caseId,
    String? taskId,
    required String accountNumber,
  }) async {
    final uri = Uri.parse('$kGatewayBase/workflow/account/account-number');
    final body = taskId != null && taskId.isNotEmpty
        ? {'taskId': taskId, 'accountnumber': accountNumber}
        : {'caseId': caseId, 'accountnumber': accountNumber};

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return (
          ok: true,
          message: data['message']?.toString() ?? 'Thành công',
          taskId: data['taskId']?.toString(),
        );
      }
      if (res.statusCode == 409) {
        return (
          ok: false,
          message: data['message']?.toString() ?? 'Số tài khoản đã tồn tại',
          taskId: null,
        );
      }
      return (
        ok: false,
        message: data['error']?.toString() ?? 'Lỗi HTTP ${res.statusCode}',
        taskId: null,
      );
    } catch (e) {
      return (ok: false, message: 'Lỗi kết nối: $e', taskId: null);
    }
  }

  //===============================password=================================
  // Quên mật khẩu
  Future<String> changePassword({
    required String customerId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await getToken(); // Lấy token đã lưu
    debugPrint('[DEBUG] Access token: $token');
    final url = Uri.parse('$accountServiceUrl/change-password');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // Thêm dòng này
      },
      body: jsonEncode({
        "customerId": customerId,
        "oldPassword": oldPassword,
        "newPassword": newPassword,
      }),
    );
    return response.body;
  }

  Future<String> forgotPassword({
    required String cccd,
    required String email,
    required String phone,
  }) async {
    final token = await getToken(); // Nếu API cần xác thực
    debugPrint('[DEBUG] Access token: $token');
    final url = Uri.parse('$accountServiceUrl/forgot-password');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"cccd": cccd, "email": email, "phone": phone}),
    );
    return response.body;
  }

  //==================================set pin =================================
  // Thiết lập mã PIN cho account hoặc user
  Future<void> setPin({
    required String ownerType, // 'account' hoặc 'user'
    required String ownerId, // ID của account hoặc user
    required String pin, // mã PIN 6 số
  }) async {
    final token = await _getToken();
    if (token == null)
      throw Exception('Bạn chưa đăng nhập hoặc phiên đã hết hạn');

    final response = await http.post(
      Uri.parse('$userServiceUrl/customers/set-pin'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'ownerType': ownerType,
        'ownerId': ownerId,
        'pin': pin,
      }),
    );

    if (response.statusCode == 200) {
      print('Thiết lập mã PIN thành công');
    } else {
      print('Lỗi khi set PIN: ${response.statusCode} ${response.body}');
      throw Exception('Không thể thiết lập mã PIN');
    }
  }

  // Xác minh mã PIN
  Future<bool> verifyPin({
    required String ownerType,
    required String ownerId,
    required String pin,
  }) async {
    final token = await _getToken();
    if (token == null)
      throw Exception('Bạn chưa đăng nhập hoặc phiên đã hết hạn');

    final response = await http.post(
      Uri.parse('$userServiceUrl/customers/verify-pin'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'ownerType': ownerType,
        'ownerId': ownerId,
        'pin': pin,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Kết quả xác minh PIN: ${data['valid']}');
      return data['valid'] == true;
    } else {
      print('Lỗi khi verify PIN: ${response.statusCode} ${response.body}');
      throw Exception('Không thể xác minh mã PIN');
    }
  }

  Future<bool> checkIfPinExists(String ownerType, String ownerId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Chưa đăng nhập');

    final uri = Uri.parse(
      '$userServiceUrl/customers/has-pin?ownerType=$ownerType&ownerId=$ownerId',
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['hasPin'] == true;
    } else {
      throw Exception('Không kiểm tra được mã PIN');
    }
  }

  //===============================transaction=================================
  // Chuyển khoản
  Future<void> transfer(String recipient, double amount) async {
    final token = await _getToken();
    if (token == null) throw Exception('Chưa đăng nhập');

    final response = await http.post(
      Uri.parse('$baseUrl/transfer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'recipient': recipient, 'amount': amount}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to transfer: ${response.statusCode}');
    }
  }

  // Thanh toán QR
  Future<void> qrPay(String qrCode) async {
    final token = await _getToken();
    if (token == null) throw Exception('Chưa đăng nhập');

    final response = await http.post(
      Uri.parse('$baseUrl/qr-pay'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'qrCode': qrCode}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to process QR payment: ${response.statusCode}');
    }
  }

  // Lấy lịch sử giao dịch
  Future<List<dynamic>> getTransactions() async {
    final token = await _getToken();
    if (token == null) throw Exception('Chưa đăng nhập');

    final response = await http.get(
      Uri.parse('$baseUrl/transactions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch transactions: ${response.statusCode}');
    }
  }
}
