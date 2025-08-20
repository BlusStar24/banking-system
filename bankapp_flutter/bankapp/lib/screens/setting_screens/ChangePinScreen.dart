import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ChangePinScreen extends StatefulWidget {
  @override
  _ChangePinScreenState createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isLoading = false;

  Future<void> _changePin() async {
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
      // Bước 1: Xác minh mã PIN cũ
      final isValid = await ApiService.instance.verifyPin(
        ownerType: "account",
        ownerId: accountId,
        pin: _oldPinController.text,
      );

      if (!mounted) return;

      if (!isValid) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Mã PIN cũ không chính xác.')));
        setState(() => _isLoading = false);
        return;
      }

      // Bước 2: Thiết lập mã PIN mới
      await ApiService.instance.setPin(
        ownerType: "account",
        ownerId: accountId,
        pin: _newPinController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đổi mã PIN thành công.')));

      Navigator.pop(context);
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
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đổi mã PIN')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _oldPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Mã PIN cũ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'Vui lòng nhập đúng 6 số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _newPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Mã PIN mới',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'Vui lòng nhập đúng 6 số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _confirmPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Nhập lại mã PIN mới',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != _newPinController.text) {
                    return 'Mã PIN nhập lại không khớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _changePin,
                      child: Text('Đổi mã PIN'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
