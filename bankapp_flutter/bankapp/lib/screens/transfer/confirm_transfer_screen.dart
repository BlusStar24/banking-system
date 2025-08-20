import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/TransferInfo.dart';
import '../../services/transfer_api.dart';
import 'transfer_success_screen.dart';

const kBlue = Color(0xFF0A84FF);
const kBlueDark = Color(0xFF0B5ED7);

class ConfirmTransferScreen extends StatefulWidget {
  final TransferInfo info;
  final String caseId;

  const ConfirmTransferScreen({
    super.key,
    required this.info,
    required this.caseId,
  });

  @override
  State<ConfirmTransferScreen> createState() => _ConfirmTransferScreenState();
}

class _ConfirmTransferScreenState extends State<ConfirmTransferScreen> {
  bool showPinPopup = false;
  bool showOtpPopup = false;

  final TextEditingController pinController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  String? fromAccountNumber;
  int otpExpireSeconds = 30;
  final TransferGateway api = TransferGateway();
  bool _otpLoaded = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[DEBUG] ConfirmTransferScreen init:');
    debugPrint('[DEBUG] caseId: ${widget.caseId}');
    debugPrint('[DEBUG] TransferInfo: ${widget.info.toString()}');
    debugPrint('[DEBUG] Is external transfer: ${widget.info.bankId != null}');
  }

  @override
  void dispose() {
    pinController.dispose();
    otpController.dispose();
    super.dispose();
  }

  void _autoFillOtpIfNeeded() async {
    if (_otpLoaded || !mounted) return;
    _otpLoaded = true;

    final accountId = widget.info.fromAccountId ?? '';
    try {
      final fetchedOtp = await TransferServiceAPI.instance.fetchOtpFromBackend(
        accountId,
      );
      if (fetchedOtp != null && mounted) {
        setState(() {
          otpController.text = fetchedOtp;
        });
        debugPrint('[DEBUG] OTP tự động điền: $fetchedOtp');
      } else {
        debugPrint('[ERROR] Không lấy được OTP từ backend');
      }
    } catch (e) {
      debugPrint('[ERROR] Lỗi khi fetch OTP: $e');
    }
  }

  void _startOtpCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || otpExpireSeconds == 0) return false;
      setState(() => otpExpireSeconds--);
      return otpExpireSeconds > 0;
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    debugPrint('[ERROR] Showing error: $msg');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    debugPrint('[SUCCESS] Showing success: $msg');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.lightBlue),
    );
  }

  void _goToSuccess({String? txIdFromSettle}) {
    if (!mounted) return;
    final info = widget.info;

    final receipt = TransferReceipt(
      amount: info.amount.toInt(),
      currency: 'VND',
      time: DateTime.now(),
      receiverAccount: info.toAccount,
      receiverName: info.counterpartyName ?? '',
      bankName: (info.bankName?.isNotEmpty ?? false)
          ? info.bankName!
          : (info.bankId?.isNotEmpty ?? false)
          ? info.bankId!
          : 'SGB',
      description: info.description ?? '',
      referenceCode: info.clientRequestId ?? '',
      feeLabel: 'Miễn phí',
      methodLabel: 'Chuyển tiền nhanh',
      networkLabel: 'napas 247',
      transactionId: txIdFromSettle ?? info.clientRequestId ?? '',
    );

    setState(() => showOtpPopup = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TransferSuccessScreen(receipt: receipt),
      ),
    );
  }

  Future<void> _submitPin() async {
    final pin = pinController.text.trim();
    debugPrint('[DEBUG] PIN entered: $pin');
    if (pin.length != 6) {
      if (mounted) _showError('Mã PIN phải có 6 chữ số');
      return;
    }
    try {
      final accountId = widget.info.fromAccountId ?? '';
      debugPrint(
        '[DEBUG] Submitting PIN for caseId: ${widget.caseId}, accountId: $accountId',
      );
      await api.submitPin(
        caseId: int.parse(widget.caseId),
        pin: pin,
        accountId: accountId,
      );
      debugPrint('[DEBUG] PIN submitted successfully');
      if (mounted) {
        setState(() {
          showPinPopup = false;
          showOtpPopup = true;
          otpExpireSeconds = 30;
        });
        _startOtpCountdown();
        _autoFillOtpIfNeeded();
      }
    } catch (e, stackTrace) {
      debugPrint('[ERROR] PIN submission failed: $e\n$stackTrace');
      if (mounted) _showError('PIN không hợp lệ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuyển tiền trong nước'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildMainContent(),
          if (showPinPopup) _buildPinPopup(context),
          if (showOtpPopup) _buildOtpPopup(context),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(constraints.maxWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.lightBlueAccent,
                child: Padding(
                  padding: EdgeInsets.all(constraints.maxWidth * 0.03),
                  child: const Text(
                    'Quý khách vui lòng kiểm tra và xác nhận thông tin giao dịch',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: constraints.maxHeight * 0.02),
              _buildRow('Hình thức chuyển', 'Chuyển tiền nhanh napas 247'),
              _buildRow('Tài khoản nguồn', widget.info.accountNumber ?? '---'),
              _buildRow('Tài khoản nhận', widget.info.toAccount ?? '---'),
              _buildRow(
                'Tên người nhận',
                widget.info.counterpartyName ?? '---',
                highlight: true,
              ),
              _buildRow('Ngân hàng nhận', widget.info.bankName ?? '---'),
              _buildRow('Nội dung', widget.info.description ?? ''),
              _buildRow('Mã tham chiếu', widget.info.clientRequestId ?? ''),
              _buildRow('Phí chuyển tiền', 'Miễn phí'),
              _buildRow(
                'Số tiền',
                _formatAmount(widget.info.amount),
                highlight: true,
                isRed: true,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.04,
                  vertical: constraints.maxHeight * 0.01,
                ),
                child: Text(
                  _amountInWords(widget.info.amount),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              SizedBox(height: constraints.maxHeight * 0.04),
              const Text(
                'Phương thức xác thực',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: constraints.maxHeight * 0.015),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.035,
                  vertical: constraints.maxHeight * 0.02,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color.fromARGB(255, 232, 240, 245),
                ),
                child: const Text('Smart OTP'),
              ),
              SizedBox(height: constraints.maxHeight * 0.04),
              SizedBox(
                width: double.infinity,
                height: constraints.maxHeight * 0.07,
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint('[DEBUG] Confirm button pressed');
                    if (mounted) setState(() => showPinPopup = true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Xác nhận', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool highlight = false,
    bool isRed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                color: isRed ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} VND';
  }

  String _amountInWords(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '');
    return '(${formatter.format(amount).replaceAll('.', ',')} đồng)';
  }

  Widget _buildOverlay({required Widget child}) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPinPopup(BuildContext context) {
    return _buildOverlay(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info, color: Colors.blue, size: 36),
          const SizedBox(height: 12),
          const Text(
            'Xác thực giao dịch',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vui lòng nhập mã PIN SGB- Smart OTP',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          PinBoxes(controller: pinController, length: 6, obscure: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final pin = pinController.text.trim();
                debugPrint('[DEBUG] PIN entered: $pin');
                if (pin.length != 6) {
                  if (mounted) _showError('Mã PIN phải có 6 chữ số');
                  return;
                }
                try {
                  final accountId = widget.info.fromAccountId ?? '';
                  debugPrint(
                    '[DEBUG] Submitting PIN for caseId: ${widget.caseId}, accountId: $accountId',
                  );
                  await api.submitPin(
                    caseId: int.parse(widget.caseId),
                    pin: pin,
                    accountId: accountId,
                  );
                  debugPrint('[DEBUG] PIN submitted successfully');
                  if (mounted) {
                    setState(() {
                      showPinPopup = false;
                      showOtpPopup = true;
                      otpExpireSeconds = 30;
                    });
                    _startOtpCountdown();
                    _autoFillOtpIfNeeded();
                  }
                } catch (e, stackTrace) {
                  debugPrint('[ERROR] PIN submission failed: $e\n$stackTrace');
                  if (mounted) _showError('PIN không hợp lệ: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tiếp tục'),
            ),
          ),
          TextButton(
            onPressed: () {
              debugPrint('[DEBUG] PIN popup cancelled');
              if (mounted) setState(() => showPinPopup = false);
            },
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpPopup(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _autoFillOtpIfNeeded();
    });

    return _buildOverlay(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info, color: Colors.blue, size: 36),
          const SizedBox(height: 12),
          const Text(
            'Xác thực giao dịch',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mã xác thực giao dịch đang hiển thị trong ứng dụng Smart OTP. Vui lòng nhập và nhấn Xác nhận để hoàn tất.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: otpController,
            maxLength: 6,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 12),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                String otp = otpController.text.trim();
                final accountId = widget.info.fromAccountId ?? '';

                debugPrint('[DEBUG] OTP entered: $otp');
                if (otp.length == 6) {
                  try {
                    debugPrint(
                      '[DEBUG] Submitting OTP for caseId: ${widget.caseId}, accountId: $accountId',
                    );
                    await api.submitOtp(
                      caseId: int.parse(widget.caseId),
                      otp: otp,
                      accountId: accountId,
                    );
                    debugPrint('[DEBUG] OTP submitted successfully');
                    String txId = '';

                    if (widget.info.bankId != null) {
                      debugPrint(
                        '[DEBUG] Preparing submitExternalSettle for external transfer',
                      );
                      final clientRequestId = widget.info.clientRequestId ?? '';
                      debugPrint(
                        '[DEBUG] clientRequestId for settle: $clientRequestId',
                      );

                      for (var i = 0; i < 3; i++) {
                        try {
                          debugPrint(
                            '[DEBUG] Attempt ${i + 1} for submitExternalSettle',
                          );
                          final response = await api.submitExternalSettle(
                            caseId: int.parse(widget.caseId),
                            clientRequestId: clientRequestId,
                            success: true,
                          );
                          debugPrint(
                            '[DEBUG] submitExternalSettle response: $response',
                          );
                          txId = response['transactionId'] ?? clientRequestId;
                          debugPrint(
                            '[DEBUG] submitExternalSettle successful with txId: $txId',
                          );
                          break;
                        } catch (e, stackTrace) {
                          debugPrint(
                            '[ERROR] submitExternalSettle attempt ${i + 1} failed: $e\n$stackTrace',
                          );
                          if (i == 2 && mounted) {
                            _showError('Lỗi khi hoàn tất giao dịch: $e');
                            return;
                          }
                          await Future.delayed(const Duration(seconds: 1));
                        }
                      }
                    } else {
                      debugPrint(
                        '[DEBUG] Internal transfer, skipping submitExternalSettle',
                      );
                    }

                    if (mounted) {
                      setState(() => showOtpPopup = false);
                      _goToSuccess(txIdFromSettle: txId);
                    }
                  } catch (e, stackTrace) {
                    debugPrint(
                      '[ERROR] OTP submission or settle failed: $e\n$stackTrace',
                    );
                    if (mounted) _showError('Lỗi xử lý giao dịch: $e');
                  }
                } else {
                  debugPrint('[ERROR] Invalid OTP length: ${otp.length}');
                  if (mounted) _showError('Mã OTP phải có 6 chữ số');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Xác nhận'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '⏱ Thời gian hiệu lực của OTP còn $otpExpireSeconds giây',
            style: const TextStyle(fontSize: 12),
          ),
          TextButton(
            onPressed: () {
              debugPrint('[DEBUG] OTP popup cancelled');
              if (mounted) setState(() => showOtpPopup = false);
            },
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }
}

class PinBoxes extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final bool obscure;

  const PinBoxes({
    super.key,
    required this.controller,
    this.length = 6,
    this.obscure = true,
  });

  @override
  State<PinBoxes> createState() => _PinBoxesState();
}

class _PinBoxesState extends State<PinBoxes> {
  late List<TextEditingController> _boxes;
  late List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _boxes = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());

    _syncFromMaster(widget.controller.text);

    widget.controller.addListener(() {
      if (mounted) {
        final v = widget.controller.text;
        if (v.length <= widget.length) _syncFromMaster(v);
      }
    });
  }

  @override
  void dispose() {
    for (final c in _boxes) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  void _syncFromMaster(String v) {
    for (int i = 0; i < widget.length; i++) {
      final ch = (i < v.length) ? v[i] : '';
      if (_boxes[i].text != ch) {
        _boxes[i].text = ch;
      }
    }
    if (mounted) setState(() {});
  }

  void _updateMaster() {
    final v = _boxes.map((c) => c.text).join();
    if (widget.controller.text != v) {
      widget.controller.text = v;
    }
  }

  void _pasteInto(int startIndex, String paste) {
    final digits = paste.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    int i = startIndex;
    int j = 0;
    while (i < widget.length && j < digits.length) {
      _boxes[i].text = digits[j];
      i++;
      j++;
    }
    _updateMaster();
    final next = _boxes.indexWhere((c) => c.text.isEmpty);
    if (next != -1) {
      _nodes[next].requestFocus();
    } else {
      _nodes[widget.length - 1].unfocus();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Tính toán chiều rộng ô và margin dựa trên constraints
        final availableWidth = constraints.maxWidth;
        // Tổng margin ngang: 5 khoảng giữa * 2 * marginOneSide
        const marginOneSide = 3.0;
        const totalMargins = 5 * 2 * marginOneSide;
        // Chiều rộng mỗi ô = (chiều rộng khả dụng - tổng margin - tổng border) / 6
        const borderWidth = 2.0; // Border khi focus
        const totalBorders = 6 * 2 * borderWidth; // 6 ô, mỗi ô có 2 border
        final boxWidth =
            (availableWidth - totalMargins - totalBorders) / widget.length;

        debugPrint(
          '[DEBUG] PinBoxes: availableWidth=$availableWidth, boxWidth=$boxWidth',
        );

        return ClipRect(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.length, (i) {
              return Container(
                width: boxWidth,
                height: boxWidth * 1.2, // Tỷ lệ 1:1.2 cho hình chữ nhật
                margin: const EdgeInsets.symmetric(horizontal: marginOneSide),
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (evt) {
                    if (!mounted) return;
                    if (evt is! RawKeyDownEvent) return;
                    if (evt.logicalKey == LogicalKeyboardKey.backspace) {
                      if (_boxes[i].text.isEmpty && i > 0) {
                        _nodes[i - 1].requestFocus();
                        _boxes[i - 1].text = '';
                        _updateMaster();
                        if (mounted) setState(() {});
                      }
                    }
                  },
                  child: TextField(
                    controller: _boxes[i],
                    focusNode: _nodes[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    obscureText: widget.obscure,
                    obscuringCharacter: '•',
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFBFD6F9)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: kBlue,
                          width: borderWidth,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFEFF6FF),
                    ),
                    onChanged: (val) async {
                      if (!mounted) return;
                      if (val.length > 1) {
                        _boxes[i].text = '';
                        _pasteInto(i, val);
                        return;
                      }
                      if (val.isNotEmpty) {
                        if (i + 1 < widget.length) {
                          _nodes[i + 1].requestFocus();
                        } else {
                          _nodes[i].unfocus();
                        }
                      }
                      _updateMaster();
                      if (mounted) setState(() {});
                    },
                    onTap: () async {
                      // Hỗ trợ dán bằng long-press mặc định của TextField
                    },
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
