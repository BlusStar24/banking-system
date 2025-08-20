import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../main_screen.dart';

class CreatePinScreen extends StatefulWidget {
  @override
  _CreatePinScreenState createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _submitPin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final accountId = await ApiService.instance.getAccountId();
    if (!mounted) return;

    if (accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tìm thấy tài khoản ngân hàng.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      await ApiService.instance.setPin(
        ownerType: "account",
        ownerId: accountId,
        pin: _pinController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tạo mã PIN thành công')));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(isLoggedIn: true),
        ), // Truyền isLoggedIn: true
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tạo mã PIN')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Nhập mã PIN 6 số',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'Mã PIN phải đủ 6 số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitPin,
                      child: Text('Xác nhận'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
