import 'package:bankapp/screens/login_screen.dart';
import 'package:bankapp/screens/transfer/transfer_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import 'create_account/fpt_ai_ekyc.dart';
import 'setting_screens/setting_screen.dart';
import 'setting_screens/create_pin_screen.dart';

class MainScreen extends StatefulWidget {
  final bool isLoggedIn;
  final Map<String, dynamic>? user;

  MainScreen({this.isLoggedIn = false, this.user});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? userProfile;
  bool _showBalance = false;
  bool _isRedirecting = false;
  late bool _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = widget.isLoggedIn; // Lấy trạng thái ban đầu từ tham số
    _checkPinAfterLogin();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await ApiService.instance.getUserProfile();
      setState(() {
        userProfile = profile;
      });
    } catch (e) {
      print("❌ Lỗi khi tải hồ sơ người dùng: $e");
    }
  }

  Future<void> _checkPinAfterLogin() async {
    if (!_isLoggedIn || _isRedirecting) return; // Sử dụng _isLoggedIn

    final accountId = await ApiService.instance.getAccountId();
    if (accountId == null) return;

    final hasPin = await ApiService.instance.checkIfPinExists(
      "account",
      accountId,
    );

    if (!hasPin && mounted) {
      setState(() {
        _isRedirecting = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CreatePinScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String username = widget.user?['username'] ?? 'NGUYEN XUAN CUONG';
    final String accountNumber = widget.user?['accountNumber'] ?? '1024849406';

    final List<Widget> screens = [
      _isLoggedIn // Sử dụng _isLoggedIn thay vì widget.isLoggedIn
          ? _buildDashboard(context, username, accountNumber)
          : _buildLoginPrompt(context),
      Center(child: Text('Giao dịch')),
      Center(child: Text('Tiết kiệm')),
      SettingScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.network(
              'https://res.cloudinary.com/dbwdohabb/image/upload/v1754010712/logosaigonbank_ffjsls.png',
              height: 40,
            ),
            SizedBox(width: 10),
            Text(
              'SAIGONBANK',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Color.fromARGB(255, 71, 114, 223),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await ApiService.instance.logout();
              setState(() {
                _isLoggedIn = false; // Cập nhật trạng thái đăng xuất
              });
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Color.fromARGB(255, 71, 114, 223),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Giao dịch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings),
            label: 'Tiết kiệm',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final LocalAuthentication auth = LocalAuthentication();

    Future<void> _authenticate() async {
      try {
        bool authenticated = await auth.authenticate(
          localizedReason: 'Vui lòng xác thực để đăng nhập',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
        if (authenticated) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Đăng nhập thành công!')));
          setState(() {
            _isLoggedIn =
                true; // Cập nhật trạng thái đăng nhập bằng _isLoggedIn
          });
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Xác thực thất bại')));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Chào mừng đến với SAIGONBANK Smart Banking',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 71, 114, 223),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          CustomButton(
            text: 'Đăng nhập bằng Face ID/Vân tay',
            onPressed: _authenticate,
          ),
          SizedBox(height: 10),
          CustomButton(
            text: 'Đăng nhập bằng mật khẩu',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chức năng đăng nhập đang phát triển')),
              );
            },
          ),
          SizedBox(height: 10),
          CustomButton(
            text: 'Đăng ký tài khoản',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FptAIEkycScreen()),
              );
            },
            isSecondary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    String username,
    String accountNumber,
  ) {
    final String displayName = userProfile?['customer']?['name'] ?? username;
    final String balance =
        userProfile?['account']?['balance']?.toString() ?? '0';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 71, 114, 223).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  child: Icon(Icons.person, color: Colors.white),
                  backgroundColor: Color.fromARGB(255, 71, 114, 223),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Số tài khoản: ${userProfile?['account']?['accountNumber'] ?? accountNumber}',
                      style: GoogleFonts.montserrat(fontSize: 14),
                    ),
                    Row(
                      children: [
                        Text(
                          'Số dư: ',
                          style: GoogleFonts.montserrat(fontSize: 14),
                        ),
                        Text(
                          _showBalance ? '$balance đ' : '******',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _showBalance
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                            color: Colors.grey[700],
                          ),
                          onPressed: () {
                            setState(() {
                              _showBalance = !_showBalance;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                Spacer(),
                IconButton(icon: Icon(Icons.qr_code), onPressed: () {}),
              ],
            ),
          ),
          SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildFunctionCard(
                Icons.signal_cellular_alt,
                'Nạp Data 4G/5G',
                () {},
              ),
              _buildFunctionCard(
                Icons.swap_horiz,
                'Chuyển tiền trong nước',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TransferScreen()),
                  );
                },
              ),
              _buildFunctionCard(Icons.group, 'Quản lý nhóm', () {}),
              _buildFunctionCard(Icons.card_giftcard, 'Quà tặng', () {}),
              _buildFunctionCard(Icons.savings, 'Mở tiết kiệm', () {}),
              _buildFunctionCard(Icons.settings, 'Cài đặt hạn mức', () {}),
            ],
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.chat, color: Colors.white),
              label: Text(
                'Chat với Digibot!',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 71, 114, 223),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionCard(IconData icon, String title, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Color.fromARGB(255, 71, 114, 223)),
            SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
