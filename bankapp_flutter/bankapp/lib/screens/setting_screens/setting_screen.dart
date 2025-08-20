import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ChangePinScreen.dart';
import '../ChangePasswordScreen.dart';
import '../../services/api_service.dart';

class SettingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text(
          'Cài đặt',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        _buildHeader(),
        SizedBox(height: 20),
        _buildSectionTitle('Bảo mật'),
        _buildGridItems([
          _buildGridItem(
            Icons.lock,
            'Đổi mật khẩu đăng nhập',
            onTap: () async {
              final api = ApiService.instance;
              final customerId = await api.getCustomerId();

              if (customerId == null || customerId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Không tìm thấy customer_id trong storage'),
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChangePasswordScreen(customerId: customerId),
                ),
              );
            },
          ),

          _buildGridItem(Icons.face, 'Cài đặt Face ID'),
          _buildGridItem(Icons.account_balance_wallet, 'Tài khoản mặc định'),
          _buildGridItem(
            Icons.lock_outline,
            'Cài đặt mã PIN',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChangePinScreen()),
              );
            },
          ),
          _buildGridItem(Icons.phone_android, 'Số điện thoại SMS OTP'),
          _buildGridItem(Icons.phone, 'Cấp mật khẩu Phone Banking'),
          _buildGridItem(Icons.face_retouching_natural, 'Quản lý Facepay'),
        ]),
        SizedBox(height: 20),
        _buildSectionTitle('Quản lý và thiết lập'),
        _buildGridItems([
          _buildGridItem(Icons.payment, 'Quản lý đề nghị thanh toán'),
          _buildGridItem(Icons.notifications, 'Quản lý thông báo'),
          _buildGridItem(Icons.email, 'Quản lý email'),
          _buildGridItem(Icons.help, 'Quản lý thông báo tra soát'),
          _buildGridItem(Icons.login, 'Quản lý đăng nhập kênh'),
          _buildGridItem(Icons.volume_up, 'Voice OTT'),
          _buildGridItem(Icons.wallpaper, 'Cài đặt hình nền'),
          _buildGridItem(Icons.edit, 'Chữ ký số'),
        ]),
        SizedBox(height: 20),
        _buildSectionTitle('Thông tin hỗ trợ'),
        _buildGridItems([
          _buildGridItem(Icons.format_size, 'Thay đổi cỡ chữ'),
          _buildGridItem(Icons.menu_book, 'Hướng dẫn sử dụng'),
          _buildGridItem(Icons.question_answer, 'Câu hỏi thường gặp'),
          _buildGridItem(Icons.shield, 'Giao dịch an toàn'),
          _buildGridItem(Icons.swap_horiz, 'Tỷ giá'),
          _buildGridItem(Icons.percent, 'Lãi suất'),
          _buildGridItem(Icons.calculate, 'Tính toán lãi suất'),
          _buildGridItem(Icons.cancel, 'Đóng tài khoản'),
        ]),
        SizedBox(height: 30),
        Divider(),
        ListTile(
          title: Text('Liên hệ với SCB'),
          subtitle: Text(
            '1900 5555 11',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: Icon(Icons.phone, color: Colors.blue[700]),
        ),
        SizedBox(height: 10),
        Center(
          child: Text(
            'Phiên bản sử dụng 6.2.1',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, size: 30, color: Colors.grey[700]),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Xin chào,', style: TextStyle(color: Colors.grey[600])),
                Text(
                  'NGUYEN XUAN CUONG',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.palette, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Giao diện: ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'Tiêu chuẩn',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    TextButton(onPressed: () {}, child: Text('Thay đổi')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildGridItems(List<Widget> items) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: items,
    );
  }

  Widget _buildGridItem(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.blue[800]),
          SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.montserrat(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
