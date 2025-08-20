import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String customerId;
  ChangePasswordScreen({required this.customerId});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đổi mật khẩu')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _oldPasswordController,
                label: 'Mật khẩu cũ',
                validator: (v) => v!.isEmpty ? 'Nhập mật khẩu cũ' : null,
                obscureText: true,
              ),
              CustomTextField(
                controller: _newPasswordController,
                label: 'Mật khẩu mới',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nhập mật khẩu mới';
                  if (v.length < 6) return 'Mật khẩu phải từ 6 ký tự';
                  return null;
                },
                obscureText: true,
              ),
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Nhập lại mật khẩu mới',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nhập lại mật khẩu mới';
                  if (v != _newPasswordController.text)
                    return 'Mật khẩu không khớp';
                  return null;
                },
                obscureText: true,
              ),
              SizedBox(height: 20),
              CustomButton(
                text: 'Xác nhận đổi',
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final msg = await ApiService.instance.changePassword(
                        customerId: widget.customerId,
                        oldPassword: _oldPasswordController.text,
                        newPassword: _newPasswordController.text,
                      );
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(msg)));
                      Navigator.pop(context); // Quay lại sau khi đổi thành công
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
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
