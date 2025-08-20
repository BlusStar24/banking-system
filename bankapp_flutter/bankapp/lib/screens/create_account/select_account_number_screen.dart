import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// TODO: sửa lại import này cho đúng vị trí file login_screen.dart của bạn
// ví dụ: import '../auth/login_screen.dart'; hoặc '../../screens/login_screen.dart';
import '../login_screen.dart';

/// Chọn số tài khoản (gateway mode):
/// - Kiểm tra trùng qua user-service (5000)
/// - Gửi số qua gateway 5053 với caseId + taskId bắt buộc
class SelectAccountNumberScreen extends StatefulWidget {
  final String caseId;
  final String taskId;

  const SelectAccountNumberScreen({
    super.key,
    required this.caseId,
    required this.taskId,
  });

  @override
  State<SelectAccountNumberScreen> createState() =>
      _SelectAccountNumberScreenState();
}

class _SelectAccountNumberScreenState extends State<SelectAccountNumberScreen> {
  // Base URLs cho emulator Android / web/desktop
  static final String kGatewayBase = kIsWeb
      ? 'http://localhost:5053'
      : 'http://10.0.2.2:5053';
  static final String kUserServiceBase = kIsWeb
      ? 'http://localhost:5000'
      : 'http://10.0.2.2:5000';

  final _accCtrl = TextEditingController();
  Timer? _debounce;
  bool _checking = false;
  String _checkHint = '';
  bool _duplicate = false;
  bool _submitting = false;

  late final List<String> _niceNumbers = _generateNiceNumbers(
    prefix: '1024',
    count: 20,
  );

  @override
  void dispose() {
    _debounce?.cancel();
    _accCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caseId = widget.caseId.trim();
    final taskId = widget.taskId.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Chọn số tài khoản')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Case ID: $caseId\nTask ID: $taskId',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'Gợi ý số đẹp',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _niceNumbers
                  .map(
                    (num) => OutlinedButton(
                      onPressed: () => _pickCandidate(num),
                      child: Text(num),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            const Text(
              'Hoặc nhập tay',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _accCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'VD: 9704123456789',
                helperText: 'Định dạng hợp lệ: 8–20 chữ số',
                border: OutlineInputBorder(),
              ),
              onChanged: _onAccChanged,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (_checking)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (_checking) const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _checkHint,
                    style: TextStyle(
                      fontSize: 12,
                      color: _checkHint == 'Số đã tồn tại'
                          ? Colors.red
                          : (_checkHint == 'Có thể sử dụng'
                                ? Colors.green
                                : Colors.orange),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              onPressed: _submitting || _duplicate
                  ? null
                  : () => _submitSelected(caseId: caseId, taskId: taskId),
              label: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gửi vào workflow'),
            ),
          ],
        ),
      ),
    );
  }

  // ================= interactions =================
  void _pickCandidate(String num) {
    _accCtrl.text = num;
    _triggerCheck();
  }

  void _onAccChanged(String _) => _triggerCheck();

  void _triggerCheck() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _checkDuplicate);
  }

  Future<void> _checkDuplicate() async {
    final acc = _accCtrl.text.trim();
    if (acc.isEmpty) {
      setState(() {
        _checkHint = '';
        _duplicate = false;
      });
      return;
    }

    if (!RegExp(r'^\d{8,20}$').hasMatch(acc)) {
      setState(() {
        _checkHint = 'Số tài khoản không hợp lệ (8–20 chữ số).';
        _duplicate = true;
      });
      return;
    }

    setState(() {
      _checking = true;
      _checkHint = 'Đang kiểm tra...';
    });

    final exists = await _checkAccountNumberExists(acc);

    setState(() {
      _checking = false;
      if (exists == true) {
        _checkHint = 'Số đã tồn tại';
        _duplicate = true;
      } else if (exists == false) {
        _checkHint = 'Có thể sử dụng';
        _duplicate = false;
      } else {
        _checkHint = 'Không kiểm tra được';
        _duplicate = false;
      }
    });
  }

  Future<void> _submitSelected({
    required String caseId,
    required String taskId,
  }) async {
    final acc = _accCtrl.text.trim();

    if (caseId.isEmpty || taskId.isEmpty) {
      _toast('Thiếu caseId hoặc taskId.', error: true);
      return;
    }
    if (!RegExp(r'^\d{8,20}$').hasMatch(acc)) {
      _toast('Số tài khoản không hợp lệ (8–20 chữ số).', error: true);
      return;
    }

    // Pre-check lần nữa
    final exists = await _checkAccountNumberExists(acc);
    if (exists == true) {
      _toast('Số tài khoản đã tồn tại, vui lòng chọn số khác.', error: true);
      setState(() {
        _checkHint = 'Số đã tồn tại';
        _duplicate = true;
      });
      return;
    }

    setState(() => _submitting = true);
    final res = await _submitAccountNumberToGateway(
      caseId: caseId,
      taskId: taskId,
      accountNumber: acc,
    );
    setState(() => _submitting = false);

    if (res.$1) {
      // ✅ Hiển thị thông báo thành công + nút Đăng nhập ngay
      await _showSuccessSheet(
        message:
            'Tạo tài khoản thành công. Vui lòng kiểm tra thông tin chi tiết trong email.',
      );
    } else {
      _toast('Lỗi: ${res.$2}', error: true);
    }
  }

  // ================= HTTP helpers =================
  Future<bool?> _checkAccountNumberExists(String accountNumber) async {
    try {
      if (!RegExp(r'^\d{8,20}$').hasMatch(accountNumber)) return null;
      final uri = Uri.parse(
        '$kUserServiceBase/api/customers/check-account-number/$accountNumber',
      );
      final r = await http.get(uri);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['exists'] == true; // true = đã tồn tại
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Gửi vào workflow qua gateway 5053
  /// Body bắt buộc: { caseId, taskId, accountnumber }
  Future<(bool, String)> _submitAccountNumberToGateway({
    required String caseId,
    required String taskId,
    required String accountNumber,
  }) async {
    final uri = Uri.parse('$kGatewayBase/workflow/account/account-number');
    final body = jsonEncode({
      'caseId': caseId,
      'taskId': taskId,
      'accountnumber': accountNumber,
    });

    try {
      final r = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      final data = _safeJson(r.body);
      if (r.statusCode >= 200 && r.statusCode < 300) {
        return (true, data['message']?.toString() ?? 'Thành công');
      }
      if (r.statusCode == 409) {
        return (
          false,
          data['message']?.toString() ?? 'Số tài khoản đã tồn tại',
        );
      }
      return (false, data['error']?.toString() ?? 'HTTP ${r.statusCode}');
    } catch (e) {
      return (false, 'Lỗi kết nối: $e');
    }
  }

  Map<String, dynamic> _safeJson(String body) {
    try {
      final d = jsonDecode(body);
      return d is Map<String, dynamic> ? d : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  // ================= UI helpers =================
  Future<void> _showSuccessSheet({required String message}) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 34,
                backgroundColor: const Color(0xFF22C55E).withOpacity(.12),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF22C55E),
                  size: 38,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hoàn tất tạo tài khoản',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.login),
                      label: const Text('Đăng nhập ngay'),
                      onPressed: () {
                        // Đóng sheet
                        Navigator.pop(context);
                        // Điều hướng về màn Login: xoá toàn bộ stack để quay về màn đăng nhập
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  // ================= misc =================
  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  List<String> _generateNiceNumbers({required String prefix, int count = 20}) {
    final List<String> out = [];

    final base = <String>[
      '686868',
      '868686',
      '3999',
      '7999',
      '333333',
      '888888',
      '123456',
      '234567',
      '345678',
      '556688',
      '668899',
      '112233',
      '121212',
      '262626',
      '686886',
      '998899',
      '777999',
    ];

    int i = 0;
    while (out.length < count && i < base.length) {
      final cand = '$prefix${base[i]}';
      if (cand.length >= 8 && cand.length <= 20) out.add(cand);
      i++;
    }

    int tail = 1000;
    while (out.length < count) {
      final cand = '$prefix${tail}68';
      if (cand.length <= 20) out.add(cand);
      tail += 7;
    }
    return out.toSet().toList(); // unique
  }
}
