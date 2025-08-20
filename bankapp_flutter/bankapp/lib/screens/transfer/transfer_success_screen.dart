import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'transfer_screen.dart';

/// Model dữ liệu biên lai
class TransferReceipt {
  final int amount;
  final String currency;
  final DateTime time;
  final String receiverAccount; // ví dụ: "1234567890"
  final String receiverName; // ví dụ: "TRAN VAN KHANH"
  final String bankName; // ví dụ: "SAIGONBANK"
  final String bankSubName; // ví dụ: "Ngân hàng Sài Gòn Công Thương"
  final String description; // nội dung chuyển tiền
  final String referenceCode; // mã tham chiếu (copy)
  final String feeLabel; // "Miễn phí" hoặc "1,100 VND"
  final String methodLabel; // ví dụ: "Chuyển tiền nhanh"
  final String networkLabel; // ví dụ: "napas 247"
  final String transactionId; // mã giao dịch

  const TransferReceipt({
    required this.amount,
    this.currency = "VND",
    required this.time,
    required this.receiverAccount,
    required this.receiverName,
    required this.bankName,
    this.bankSubName = "",
    required this.description,
    required this.referenceCode,
    this.feeLabel = "Miễn phí",
    this.methodLabel = "Chuyển tiền nhanh",
    this.networkLabel = "napas 247",
    required this.transactionId,
  });
}

/// Màn hình hiển thị biên lai giao dịch thành công
class TransferSuccessScreen extends StatelessWidget {
  const TransferSuccessScreen({super.key, required this.receipt});

  final TransferReceipt receipt;

  // Palette BLUE (thay GREEN -> BLUE)
  static const Color kBlueDark = Color(0xFF0F5EFF);
  static const Color kBlue = Color(0xFF2F7BFF);
  static const Color kBlueLight = Color(0xFFEFF5FF);

  String _fmtMoney(int vnd, String ccy) {
    final f = NumberFormat.decimalPattern(); // 36,000
    return "${f.format(vnd)} $ccy";
  }

  String _fmtDateTime(DateTime dt) {
    // 13:13 Thứ Tư 13/08/2025
    final weekdayVi = [
      "Thứ Hai",
      "Thứ Ba",
      "Thứ Tư",
      "Thứ Năm",
      "Thứ Sáu",
      "Thứ Bảy",
      "Chủ Nhật",
    ];
    final wd = weekdayVi[(dt.weekday + 5) % 7]; // map Mon->0 ... Sun->6
    final hhmm = DateFormat("HH:mm").format(dt);
    final dmy = DateFormat("dd/MM/yyyy").format(dt);
    return "$hhmm $wd $dmy";
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem có dữ liệu biên lai không
    return Scaffold(
      backgroundColor: kBlueLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kBlueLight,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "Giao dịch",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header + icon check
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kBlue, kBlueDark],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 18,
                ),
                child: Column(
                  children: [
                    Container(
                      height: 68,
                      width: 68,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: kBlue, size: 40),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Giao dịch thành công!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fmtMoney(receipt.amount, receipt.currency),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fmtDateTime(receipt.time),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Card chi tiết
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    _rowItem(
                      "Tài khoản nhận",
                      receipt.receiverAccount,
                      bold: false,
                    ),
                    _divider(),
                    _rowItem(
                      "Tên người nhận",
                      receipt.receiverName,
                      bold: true,
                    ),
                    _divider(),
                    _bankRow(receipt.bankName, receipt.bankSubName),
                    _divider(),
                    _rowItem("Nội dung", receipt.description, bold: false),
                    _divider(),
                    _refRow(context, "Mã tham chiếu", receipt.referenceCode),
                    _divider(),
                    _rowItem("Phí chuyển tiền", receipt.feeLabel, bold: false),
                    _divider(),
                    _methodRow(receipt.methodLabel, receipt.networkLabel),
                    _divider(),
                    _rowItem(
                      "Mã giao dịch",
                      receipt.transactionId,
                      bold: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Nút hành động
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (!context.mounted) return;

                    // Dẹp mọi SnackBar/overlay còn treo
                    ScaffoldMessenger.of(context).clearSnackBars();

                    // Quay về màn tạo giao dịch mới và xóa sạch stack để không bị “dính” route cũ
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TransferScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text("Thực hiện giao dịch mới"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 20, thickness: 0.7);

  Widget _rowItem(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankRow(String bankName, String bankSub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Text(
              "Ngân hàng nhận",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  bankName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (bankSub.isNotEmpty)
                  Text(
                    bankSub,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodRow(String method, String network) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Text(
              "Hình thức chuyển",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  method,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kBlueLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBlue.withOpacity(0.25)),
                  ),
                  child: Text(
                    network,
                    style: const TextStyle(
                      color: kBlueDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _refRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Đã sao chép mã tham chiếu"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  child: const Icon(Icons.copy, size: 18, color: kBlueDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
