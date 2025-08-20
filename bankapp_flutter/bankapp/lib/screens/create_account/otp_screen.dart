import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'choose_account_number_mode_screen.dart';

class OtpScreen extends StatefulWidget {
  final String caseId;
  final String phone;
  final String email;

  const OtpScreen({
    super.key,
    required this.caseId,
    required this.phone,
    required this.email,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // Bật workflow: OtpScreen sẽ gọi gateway 5053 + SSE như otp.html
  static final String kGatewayBase = kIsWeb
      ? 'http://localhost:5053'
      : 'http://10.0.2.2:5053';

  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  String _statusText = '';
  bool _working = false;

  // SSE
  http.Client? _sseClient;
  StreamSubscription<String>? _sseSub;
  Timer? _watchdog;
  int _reconnectAttempt = 0;
  bool _navigated = false;

  @override
  void dispose() {
    _otpController.dispose();
    _stopWatchdog();
    _closeSse();
    super.dispose();
  }

  // ---------- helpers ----------
  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : null),
    );
  }

  String _sanitizeOtp(String s) => s
      .replaceAll('\u0000', '')
      .replaceAll('\x00', '')
      .replaceAll(RegExp(r'[^0-9]'), '')
      .trim();

  Map<String, dynamic> _safeJson(String body) {
    try {
      final d = jsonDecode(body);
      return d is Map<String, dynamic> ? d : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  bool _truthy(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  String? _str(dynamic v) => v?.toString();

  // ---------- flow ----------
  Future<void> _submitOtpThenListen() async {
    final otp = _sanitizeOtp(_otpController.text);
    if (otp.isEmpty) {
      _toast('Vui lòng nhập OTP hợp lệ', error: true);
      return;
    }
    setState(() => _working = true);

    try {
      // 1) verify OTP (giống otp.html gọi /workflow/account/otp)
      final uri = Uri.parse('$kGatewayBase/workflow/account/otp');
      final body = jsonEncode({
        'caseId': widget.caseId,
        'phone': widget.phone,
        'email': widget.email,
        'otp': otp,
      });
      final r = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (r.statusCode < 200 || r.statusCode >= 300) {
        final data = _safeJson(r.body);
        throw HttpException(
          data['error']?.toString() ?? 'HTTP ${r.statusCode}',
        );
      }

      _toast('OTP hợp lệ. Đang theo dõi phê duyệt...');
      setState(() => _statusText = 'Hồ sơ đang chờ phê duyệt...');

      // 2) mở SSE: /workflow/account/state/stream?caseId=...
      _navigated = false;
      _reconnectAttempt = 0;
      _startSseLoop();
    } catch (e) {
      _toast('Lỗi xác minh: $e', error: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Uri _sseStateUri(String caseId) =>
      Uri.parse('$kGatewayBase/workflow/account/state/stream?caseId=$caseId');

  void _startSseLoop() async {
    _closeSse();
    final sseUrl = _sseStateUri(widget.caseId);
    _sseClient = http.Client();

    try {
      final req = http.Request('GET', sseUrl)
        ..headers['Accept'] = 'text/event-stream'
        ..headers['Cache-Control'] = 'no-cache';

      final resp = await _sseClient!.send(req);
      if (resp.statusCode != 200) {
        _toast('Không mở được realtime (HTTP ${resp.statusCode})', error: true);
        setState(() => _statusText = 'Không mở được realtime. Đang thử lại...');
        _scheduleReconnect();
        return;
      }

      _reconnectAttempt = 0;
      _startWatchdog();

      final controller = StreamController<String>();
      _sseSub = resp.stream
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())
          .listen(
            (line) {
              _startWatchdog();
              if (line.startsWith('data:')) {
                controller.add(line.substring(5).trim());
              } else if (line.isEmpty) {
                controller.add('\n__END__\n');
              }
            },
            onError: (e) {
              _stopWatchdog();
              if (!mounted) return;
              setState(() => _statusText = 'Mất kết nối realtime: $e');
              _scheduleReconnect();
            },
            onDone: () {
              _stopWatchdog();
              if (!mounted) return;
              setState(() => _statusText = 'Realtime đã đóng. Đang thử lại...');
              _scheduleReconnect();
            },
            cancelOnError: true,
          );

      StringBuffer buf = StringBuffer();
      controller.stream.listen((chunk) async {
        if (chunk == '\n__END__\n') {
          final payload = buf.toString().trim();
          buf.clear();
          if (payload.isNotEmpty) await _handleSsePayload(payload);
        } else {
          if (buf.isNotEmpty) buf.write('\n');
          buf.write(chunk);
        }
      });
    } catch (e) {
      if (!mounted) return;
      _stopWatchdog();
      setState(() => _statusText = 'Không mở được realtime: $e');
      _scheduleReconnect();
    }
  }

  Future<void> _handleSsePayload(String payload) async {
    Map<String, dynamic>? obj;
    try {
      final dynamic parsed = jsonDecode(payload);
      if (parsed is Map<String, dynamic>) obj = parsed;
    } catch (_) {
      return;
    }
    if (obj == null || !mounted) return;

    final bool approvalPending = _truthy(obj['approvalPending']);
    final bool createAccountReady = _truthy(obj['createAccountReady']);
    String? taskId = _str(obj['taskId']);
    final String? error = _str(obj['error']);

    if (error != null && error.isNotEmpty) {
      setState(() => _statusText = 'Lỗi từ server: $error');
      _toast('Lỗi: $error', error: true);
      return;
    }

    if (approvalPending) {
      setState(() => _statusText = 'Hồ sơ đang chờ Nhân viên phê duyệt...');
      return;
    }

    if (createAccountReady) {
      // Fallback: nếu SSE chưa kịp trả taskId ⇒ hỏi API lấy taskId
      if (taskId == null || taskId.isEmpty) {
        try {
          final q = await http.get(
            Uri.parse(
              '$kGatewayBase/workflow/account/next-create-account-task?caseId=${Uri.encodeQueryComponent(widget.caseId)}',
            ),
          );
          if (q.statusCode == 200) {
            final jd = _safeJson(q.body);
            if (jd['ready'] == true && jd['taskId'] != null) {
              taskId = jd['taskId'].toString();
            }
          }
        } catch (_) {
          /* ignore */
        }
      }

      if (taskId != null && taskId.isNotEmpty) {
        if (_navigated) return;
        _navigated = true;

        _closeSse();
        _stopWatchdog();
        _toast('Đã phê duyệt. Sang bước nhập số tài khoản.');
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChooseAccountNumberModeScreen(
              caseId: widget.caseId,
              taskId: taskId!,
            ),
          ),
        );
      } else {
        setState(() => _statusText = 'Đã sẵn sàng tạo số, đang lấy taskId...');
      }
      return;
    }

    setState(
      () => _statusText = 'Đang chờ chuyển sang bước "Tạo số tài khoản"...',
    );
  }

  void _closeSse() {
    try {
      _sseSub?.cancel();
    } catch (_) {}
    _sseSub = null;
    try {
      _sseClient?.close();
    } catch (_) {}
    _sseClient = null;
  }

  void _scheduleReconnect() {
    if (!mounted || _navigated) return;
    _reconnectAttempt++;
    final delayMs = _expBackoffMs(_reconnectAttempt);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted || _navigated) return;
      setState(
        () => _statusText = 'Thử kết nối lại (lần $_reconnectAttempt)...',
      );
      _startSseLoop();
    });
  }

  int _expBackoffMs(int attempt) {
    final base = 600;
    final v = base * (1 << (attempt - 1)) + (attempt * 73) % 250;
    return v > 5000 ? 5000 : v;
    // cap 5s như otp.html reconnect tự nhiên
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer(const Duration(seconds: 90), () {
      if (!mounted || _navigated) return;
      _closeSse();
      setState(
        () => _statusText =
            'Mất tín hiệu realtime (timeout). Đang kết nối lại...',
      );
      _startSseLoop();
    });
  }

  void _stopWatchdog() {
    _watchdog?.cancel();
    _watchdog = null;
  }

  Future<void> _resendOtp() async {
    // Tuỳ bạn có proxy resend OTP ở 5053 hay không; nếu chưa, ẩn nút này.
    _toast('Resend OTP: cần endpoint proxy ở gateway (chưa cấu hình).');
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác minh OTP'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            tooltip: 'Kết nối lại realtime',
            onPressed: () {
              _stopWatchdog();
              _startSseLoop();
              setState(() => _statusText = 'Đang nối lại realtime...');
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Case ID: ${widget.caseId}\nSĐT: ${widget.phone}\nEmail: ${widget.email}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      labelText: 'Mã OTP',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => _sanitizeOtp(v ?? '').isEmpty
                        ? 'Vui lòng nhập OTP'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _working
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            await _submitOtpThenListen();
                          },
                    child: _working
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Xác minh OTP'),
                  ),
                  TextButton(
                    onPressed: _resendOtp,
                    child: const Text('Gửi lại OTP'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _statusText,
                style: TextStyle(
                  color:
                      _statusText.contains('phê duyệt') &&
                          !_statusText.contains('chờ')
                      ? Colors.green[700]
                      : Colors.orange[800],
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Nút đi thẳng (debug): gọi khi bạn chắc chắn server đã ready
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      // fallback thủ công: tự hỏi taskId rồi đi tiếp
                      try {
                        final q = await http.get(
                          Uri.parse(
                            '$kGatewayBase/workflow/account/next-create-account-task?caseId=${Uri.encodeQueryComponent(widget.caseId)}',
                          ),
                        );
                        if (q.statusCode == 200) {
                          final jd = _safeJson(q.body);
                          if (jd['ready'] == true && jd['taskId'] != null) {
                            if (!mounted) return;
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => ChooseAccountNumberModeScreen(
                                  caseId: widget.caseId,
                                  taskId: jd['taskId'].toString(),
                                ),
                              ),
                            );
                            return;
                          }
                        }
                        _toast(
                          'Chưa sẵn sàng hoặc không lấy được taskId',
                          error: true,
                        );
                      } catch (e) {
                        _toast('Lỗi: $e', error: true);
                      }
                    },
                    child: const Text('Đi tới bước Tạo số (thủ công)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
