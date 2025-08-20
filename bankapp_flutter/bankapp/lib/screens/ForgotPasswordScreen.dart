import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cccdController = TextEditingController();
  final _emailController = TextEditingController();
  final _PhoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quên mật khẩu')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _cccdController,
                label: 'CCCD/CMND đã đăng ký',
                validator: (v) => v!.isEmpty ? 'Nhập CCCD' : null,
              ),
              CustomTextField(
                controller: _emailController,
                label: 'Email đã đăng ký',
                validator: (v) => v!.isEmpty ? 'Nhập email' : null,
              ),
              CustomTextField(
                controller: _PhoneController,
                label: 'Số điện thoại đã đăng ký',
                validator: (v) => v!.isEmpty ? 'Nhập số điện thoại' : null,
              ),
              SizedBox(height: 20),
              CustomButton(
                text: 'Gửi lại mật khẩu',
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final msg = await ApiService.instance.forgotPassword(
                      cccd: _cccdController.text,
                      email: _emailController.text,
                      phone: _PhoneController.text,
                    );
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(msg)));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
