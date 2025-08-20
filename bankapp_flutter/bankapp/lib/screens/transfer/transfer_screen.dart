import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/transfer_api.dart';
import 'ThousandsSeparatorInputFormatter.dart';
import '../../models/TransferInfo.dart';
import 'confirm_transfer_screen.dart';

const kBlue = Color(0xFF0A84FF);
const kBlueDark = Color(0xFF0B5ED7);

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final TransferGateway api = TransferGateway();
  String? fromAccountNumber;
  String? fromAccountId;
  String? fromBalance;
  String? customerName;
  bool isExternal = true;
  String? receiverName;

  final _amountCtrl = TextEditingController(text: '0');
  final _descCtrl = TextEditingController();
  String? internalReceiverAccountId;

  String? toBankId;
  final _toExternalRefCtrl = TextEditingController();
  String? counterpartyName;

  final _toInternalAccountIdCtrl = TextEditingController();

  bool loading = false;
  String? errorText;
  String? infoText;

  String? _category;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _toExternalRefCtrl.addListener(() {
      _autoNameEnquiry();
      setState(() {}); // ← cập nhật nút nếu cần
    });
    _amountCtrl.addListener(
      () => setState(() {}),
    ); // ← cập nhật nếu người nhập tiền
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _toExternalRefCtrl.dispose();
    _toExternalRefCtrl.removeListener(_autoNameEnquiry);
    _toInternalAccountIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.instance.getUserProfile();
      final accountId = await ApiService.instance.getAccountId();
      setState(() {
        fromAccountId = accountId;
        fromAccountNumber = profile['account']?['accountNumber'];
        fromBalance = profile['account']?['balance']?.toString() ?? '0';
        customerName = profile['customer']?['name'] ?? '';
        _descCtrl.text = '$customerName chuyen tien';
        debugPrint('[DEBUG] accountId: $accountId');
        debugPrint(
          '[DEBUG] accountNumber: ${profile['account']?['accountNumber']}',
        );
      });
    } catch (e) {
      setState(() => errorText = 'Không tải được tài khoản nguồn: $e');
    }
  }

  String _generateClientRequestId() {
    final now = DateTime.now().toUtc();
    final ts =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final rand = Random().nextInt(900000) + 100000;
    return 'REQ_${ts}_$rand';
  }

  Future<void> _autoNameEnquiry() async {
    final ref = _toExternalRefCtrl.text.trim();

    if (ref.isEmpty) {
      setState(() {
        counterpartyName = null;
        infoText = null;
      });
      return;
    }

    final isInternal = toBankId == null;

    try {
      final result = await TransferServiceAPI.instance.nameEnquiry(
        bankId: isInternal ? null : toBankId,
        externalRef: ref,
      );

      final name = result['name'] as String?;
      final accountId = result['accountId'] as String?;

      setState(() {
        if (isInternal) {
          internalReceiverAccountId = accountId;
          receiverName = name;
          counterpartyName = null;
        } else {
          counterpartyName = name;
          receiverName = name;
        }

        infoText = (name != null)
            ? (isInternal
                  ? 'Đã tìm thấy tài khoản nội bộ: $name'
                  : 'Đã tra tên: $name')
            : 'Không tìm thấy người nhận';

        errorText = null;
      });
    } catch (e) {
      setState(() {
        counterpartyName = null;
        errorText = 'Lỗi tra cứu tên: $e';
      });
    }
  }

  bool _isValidToSubmit() {
    final amountStr = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '');
    final amount = double.tryParse(amountStr) ?? 0;

    return _toExternalRefCtrl.text.trim().isNotEmpty &&
        receiverName != null &&
        amount > 0;
  }

  Map<String, dynamic> _buildPayload() {
    final rawAmount = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '');
    final amt = double.tryParse(rawAmount) ?? 0.0;
    final description = _descCtrl.text.trim();
    final clientReqId = _generateClientRequestId();
    const currency = 'VND';

    final isInternal = toBankId == null;

    return {
      "fromAccountId_ct": fromAccountId,
      "currency_ct": currency,
      "transferType_ct": isInternal ? "INTERNAL" : "EXTERNAL",
      "description_ct": description,
      "clientRequestId_ct": clientReqId,
      "toAccountId_ct": isInternal ? internalReceiverAccountId : "external",
      "toBankId_ct": isInternal ? null : toBankId,
      "toExternalRef_ct": isInternal ? null : _toExternalRefCtrl.text.trim(),
      "counterpartyName_ct": isInternal ? null : counterpartyName,
      "amount_ct": amt,
    };
  }

  Future<void> _submit() async {
    if (fromAccountId == null) {
      setState(() => errorText = 'Chưa có tài khoản.');
      return;
    }

    final isInternal = toBankId == null;
    if (!isInternal && _toExternalRefCtrl.text.trim().isEmpty) {
      setState(() => errorText = 'Nhập số tài khoản đích.');
      return;
    }

    setState(() {
      loading = true;
      errorText = null;
      infoText = null;
    });

    try {
      final payload = _buildPayload();
      final caseId = await api.startCase();

      // Gửi thông tin giao dịch tới Bonita
      await api.submitInfo(
        caseId: caseId,
        fromAccountId: payload['fromAccountId_ct'],
        currency: payload['currency_ct'],
        transferType: payload['transferType_ct'],
        amount: payload['amount_ct'],
        description: payload['description_ct'] ?? '',
        clientRequestId: payload['clientRequestId_ct'],
        toAccountId: payload['toAccountId_ct'],
        toBankId: payload['toBankId_ct'],
        toExternalRef: payload['toExternalRef_ct'],
        counterpartyName: payload['counterpartyName_ct'],
      );

      print(
        'DEBUG PAYLOAD:\n${const JsonEncoder.withIndent('  ').convert(payload)}',
      );

      // Gọi màn hình xác nhận và truyền dữ liệu
      final info = TransferInfo(
        fromAccountId: payload['fromAccountId_ct'],
        toAccount: _toExternalRefCtrl.text.trim(),
        counterpartyName: receiverName, // biến dùng chung name enquiry
        bankId: toBankId,
        bankName: _getBankName(toBankId),
        description: payload['description_ct'],
        amount: payload['amount_ct'],
        clientRequestId: payload['clientRequestId_ct'],
        accountNumber: fromAccountNumber,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ConfirmTransferScreen(info: info, caseId: caseId.toString()),
        ),
      );
    } catch (e) {
      setState(() => errorText = 'Lỗi gửi yêu cầu: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  String _getBankName(String? bankId) {
    switch (bankId) {
      case 'VCB':
        return 'Vietcombank';
      case 'BIDV':
        return 'BIDV';
      case 'ACB':
        return 'ACB';
      case 'TCB':
        return 'Techcombank';
      case null:
        return 'SAIGONBANK';
      default:
        return bankId;
    }
  }

  String _formatBalance(String? balance) {
    if (balance == null) return '0';
    final number = double.tryParse(balance) ?? 0;
    return NumberFormat('#,###').format(number);
  }

  Widget _SourceAccountSlot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          fromAccountNumber ?? 'Chọn tài khoản',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Icon(Icons.arrow_drop_down, color: Colors.white),
      ],
    );
  }

  Widget _BalanceSlot() {
    return Text(
      '${_formatBalance(fromBalance)} VND',
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _ReceiverBankSlot() {
    return InputDecorator(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.blue.shade50.withOpacity(0.3),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: toBankId,
          hint: const Text('Chọn ngân hàng nhận'),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'VCB', child: Text('Vietcombank')),
            DropdownMenuItem(value: 'BIDV', child: Text('BIDV')),
            DropdownMenuItem(value: null, child: Text('Saigon Bank')),
            // Add more banks
          ],
          onChanged: (value) {
            setState(() {
              toBankId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _ReceiverAccountSlot() {
    return TextField(
      controller: _toExternalRefCtrl,
      decoration: InputDecoration(
        hintText: 'Chọn hoặc nhập số tài khoản/số thẻ n...',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.blue.shade50.withOpacity(0.3),
        suffixIcon: const Icon(Icons.book_outlined, color: kBlueDark),
      ),
    );
  }

  Widget _ReceiverNameSlot() {
    if (receiverName == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        enabled: false,
        controller: TextEditingController(text: receiverName),
        decoration: InputDecoration(
          labelText: 'Tên người nhận',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.blue.shade50.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _AmountSlot() {
    return TextField(
      controller: _amountCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [ThousandsSeparatorInputFormatter()],
      decoration: InputDecoration(
        hintText: 'Nhập số tiền',
        suffixText: 'VND',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.blue.shade50.withOpacity(0.3),
      ),
    );
  }

  Widget _NoteContentSlot() {
    return TextField(
      controller: _descCtrl,
      decoration: InputDecoration(
        hintText: 'Nội dung',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.blue.shade50.withOpacity(0.3),
      ),
    );
  }

  Widget _PurposeSlot() {
    return InputDecorator(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.blue.shade50.withOpacity(0.3),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          hint: const Text('Chọn giao dịch theo mục đích'),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'Khac', child: Text('Khác')),
            // Add more categories
          ],
          onChanged: (value) => setState(() => _category = value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuyển tiền trong nước'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thẻ tài khoản nguồn (gradient xanh)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kBlue, kBlueDark],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tài khoản nguồn',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    _SourceAccountSlot(),

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Số dư',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        _BalanceSlot(),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Nhóm: Thông tin người nhận
            _SectionCard(
              titleLeft: 'Thông tin người nhận',
              titleRight: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.receipt_long, size: 18, color: kBlue),
                  SizedBox(width: 6),
                  Text(
                    'Mẫu chuyển tiền',
                    style: TextStyle(color: kBlue, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _ReceiverBankSlot(),

                  const SizedBox(height: 12),
                  _ReceiverAccountSlot(),
                  _ReceiverNameSlot(),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Nhóm: Thông tin giao dịch
            _SectionCard(
              titleLeft: 'Thông tin giao dịch',
              titleRight: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.info_outline, size: 18, color: kBlue),
                  SizedBox(width: 6),
                  Text(
                    'Hạn mức',
                    style: TextStyle(color: kBlue, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  _AmountSlot(),

                  const SizedBox(height: 12),

                  _NoteContentSlot(),

                  const SizedBox(height: 12),

                  _PurposeSlot(),
                ],
              ),
            ),

            const SizedBox(height: 20),
            if (!_isValidToSubmit())
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _toExternalRefCtrl.text.trim().isEmpty
                      ? 'Vui lòng nhập số tài khoản người nhận'
                      : receiverName == null
                      ? 'Không tìm thấy tên người nhận. Vui lòng kiểm tra lại STK'
                      : 'Vui lòng nhập số tiền hợp lệ',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            // Nút Tiếp tục
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: loading || !_isValidToSubmit() ? null : _submit,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: kBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: kBlue.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [SizedBox(width: 8), Text('Tiếp tục')],
                      ),
              ),
            ),

            const SizedBox(height: 10),

            if (errorText != null)
              Text(
                errorText!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            if (infoText != null)
              Text(
                infoText!,
                style: const TextStyle(color: Colors.green),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String titleLeft;
  final Widget? titleRight;
  final Widget child;

  const _SectionCard({
    required this.titleLeft,
    this.titleRight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titleLeft,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kBlueDark,
              ),
            ),
            if (titleRight != null) titleRight!,
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ],
    );
  }
}
