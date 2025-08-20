import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'main_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/session_manager.dart';
import '../screens/ForgotPasswordScreen.dart';
import 'create_account/fpt_ai_ekyc.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = viewInsets > 0; // true khi bàn phím mở

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_login.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Text(
                            'ĐĂNG NHẬP',
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: _usernameController,
                            label: 'Tài khoản',
                            validator: (value) => value!.isEmpty
                                ? 'Vui lòng nhập tài khoản'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: (value) => value!.isEmpty
                                ? 'Vui lòng nhập mật khẩu'
                                : null,
                            style: GoogleFonts.montserrat(color: Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Nhập mật khẩu',
                              labelStyle: GoogleFonts.montserrat(
                                color: Colors.black54,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Đăng nhập',
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      try {
                                        await ApiService.instance.login(
                                          _usernameController.text.trim(),
                                          _passwordController.text.trim(),
                                        );
                                        await SessionManager.saveLoginTime();
                                        final storage = FlutterSecureStorage();
                                        final username = await storage.read(
                                          key: 'username',
                                        );
                                        final customerId = await storage.read(
                                          key: 'customer_id',
                                        );
                                        final user = {
                                          'username': username,
                                          'customerId': customerId,
                                        };
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MainScreen(
                                              isLoggedIn: true,
                                              user: user,
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Lỗi đăng nhập: $e'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              InkWell(
                                onTap: () {
                                  // TODO: đăng nhập vân tay
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue[50],
                                  ),
                                  child: Icon(
                                    Icons.fingerprint,
                                    size: 36,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Quên mật khẩu?'),
                              ),
                              const Text(
                                '|',
                                style: TextStyle(color: Colors.black54),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FptAIEkycScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Đăng ký tài khoản'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isKeyboardOpen) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _bottomMenu('Tra cứu tỷ giá', Icons.swap_horiz),
                        _bottomMenu('Tra cứu lãi suất', Icons.bar_chart),
                        _bottomMenu(
                          'Tìm kiếm ATM/Chi nhánh',
                          Icons.location_on,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomMenu(String title, IconData icon) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
