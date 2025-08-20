import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'select_account_number_screen.dart';

class ChooseAccountNumberModeScreen extends StatefulWidget {
  final String caseId;
  final String taskId;

  const ChooseAccountNumberModeScreen({
    super.key,
    required this.caseId,
    required this.taskId,
  });

  @override
  State<ChooseAccountNumberModeScreen> createState() =>
      _ChooseAccountNumberModeScreenState();
}

class _ChooseAccountNumberModeScreenState
    extends State<ChooseAccountNumberModeScreen> {
  static final String kGatewayBase = kIsWeb
      ? 'http://localhost:5053'
      : 'http://10.0.2.2:5053';

  bool _loading = false;
  String? _taskId; // có thể được cập nhật từ fallback

  @override
  void initState() {
    super.initState();
    _taskId = widget.taskId.trim();
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : null),
    );
  }

  Future<void> _ensureTaskId() async {
    if (_taskId != null && _taskId!.isNotEmpty) return;
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
        '$kGatewayBase/workflow/account/next-create-account-task?caseId=${Uri.encodeQueryComponent(widget.caseId)}',
      );
      final r = await http.get(uri);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is Map &&
            data['ready'] == true &&
            data['taskId'] != null &&
            data['taskId'].toString().isNotEmpty) {
          _taskId = data['taskId'].toString();
          return;
        }
      }
      _toast('Chưa sẵn sàng hoặc không lấy được taskId', error: true);
    } catch (e) {
      _toast('Lỗi lấy taskId: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goManual() async {
    if (_taskId == null || _taskId!.isEmpty) {
      await _ensureTaskId();
      if (_taskId == null || _taskId!.isEmpty) return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SelectAccountNumberScreen(caseId: widget.caseId, taskId: _taskId!),
      ),
    );
  }

  // Nếu bạn có thêm chế độ “tự động gợi ý & đặt số” thì dùng _taskId tương tự:
  Future<void> _autoSuggestAndSet() async {
    if (_taskId == null || _taskId!.isEmpty) {
      await _ensureTaskId();
      if (_taskId == null || _taskId!.isEmpty) return;
    }
    // TODO: gọi endpoint auto-assign nếu bạn triển khai (ví dụ /workflow/account/auto-assign)
    _toast('Chức năng auto-assign chưa được cấu hình.', error: false);
  }

  @override
  Widget build(BuildContext context) {
    final caseId = widget.caseId.trim();
    final taskIdDisplay = (_taskId?.isNotEmpty == true)
        ? _taskId
        : 'Đang lấy...';

    return Scaffold(
      appBar: AppBar(title: const Text('Chọn cách tạo số tài khoản')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Case ID: $caseId\nTask ID: $taskIdDisplay',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Nhập số thủ công'),
              subtitle: const Text(
                'Tự chọn số, kiểm tra trùng rồi gửi vào workflow',
              ),
              trailing: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _loading ? null : _goManual,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.auto_fix_high),
              title: const Text('Gợi ý & đặt số tự động'),
              subtitle: const Text(
                '(Tuỳ chọn) cần endpoint auto-assign ở gateway',
              ),
              onTap: _loading ? null : _autoSuggestAndSet,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Lấy lại Task ID'),
                onPressed: _loading ? null : _ensureTaskId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
