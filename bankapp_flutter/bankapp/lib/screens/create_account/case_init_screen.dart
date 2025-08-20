import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'otp_screen.dart';

class CaseInitScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const CaseInitScreen({Key? key, this.initialData}) : super(key: key);

  @override
  _CaseInitScreenState createState() => _CaseInitScreenState();
}

class _CaseInitScreenState extends State<CaseInitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _idCardController = TextEditingController();
  final _hometownController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final result = widget.initialData;
    if (result != null) {
      _idCardController.text = result["cccd"]?.toString() ?? "";
      _fullNameController.text = result["fullName"]?.toString() ?? "";
      _rawDob = result["dob"]?.toString();
      _dobController.text = formatDisplayDob(_rawDob ?? "");
      _hometownController.text = result["address"]?.toString() ?? "";
      _selectedGender = result["gender"] ?? "other";

      if (!["male", "female", "other"].contains(_selectedGender)) {
        _selectedGender = "other";
      }
    }
  }

  String? _rawDob;

  String? _selectedGender;

  String formatDisplayDob(String rawDob) {
    if (RegExp(r'^\d{8}$').hasMatch(rawDob)) {
      final day = rawDob.substring(0, 2);
      final month = rawDob.substring(2, 4);
      final year = rawDob.substring(4, 8);

      // Nếu ngày và tháng hợp lệ (1–31 và 1–12) → giả định là ddMMyyyy
      final dayInt = int.tryParse(day) ?? 0;
      final monthInt = int.tryParse(month) ?? 0;
      if (dayInt >= 1 && dayInt <= 31 && monthInt >= 1 && monthInt <= 12) {
        return "$day/$month/$year";
      }

      // Ngược lại giả định yyyyMMdd
      final year2 = rawDob.substring(0, 4);
      final month2 = rawDob.substring(4, 6);
      final day2 = rawDob.substring(6, 8);
      return "$day2/$month2/$year2";
    }

    return rawDob;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Đăng Ký Tài Khoản',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red[800],
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Thông tin'),
                  content: Text(
                    'Vui lòng điền đầy đủ thông tin để tạo tài khoản.',
                  ),
                  actions: [
                    TextButton(
                      child: Text('Đóng'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              CustomTextField(
                controller: _phoneController,
                label: 'Số điện thoại',
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập số điện thoại' : null,
                keyboardType: TextInputType.phone,
              ),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập email' : null,
                keyboardType: TextInputType.emailAddress,
              ),
              CustomTextField(
                controller: _fullNameController,
                label: 'Họ tên',
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),
              CustomTextField(
                controller: _dobController,
                label: 'Ngày sinh',
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập ngày sinh' : null,
                keyboardType: TextInputType.datetime,
              ),
              DropdownButtonFormField<String>(
                value: ["male", "female", "other"].contains(_selectedGender)
                    ? _selectedGender
                    : null,
                decoration: InputDecoration(labelText: 'Giới tính'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Nam')),
                  DropdownMenuItem(value: 'female', child: Text('Nữ')),
                  DropdownMenuItem(value: 'other', child: Text('Khác')),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedGender = val ?? 'other';
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Vui lòng chọn giới tính'
                    : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _idCardController,
                      label: 'CCCD',
                      validator: (value) =>
                          value!.isEmpty ? 'Vui lòng nhập CCCD' : null,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              CustomTextField(
                controller: _hometownController,
                label: 'Quê quán',
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập quê quán' : null,
              ),
              SizedBox(height: 20),
              CustomButton(
                text: 'Tạo Tài Khoản',
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final user = User(
                      phone: _phoneController.text,
                      email: _emailController.text,
                      fullName: _fullNameController.text,
                      dob: _rawDob ?? _dobController.text,
                      idCard: _idCardController.text,
                      hometown: _hometownController.text,
                      gender: _selectedGender ?? 'other',
                    );
                    try {
                      final result = await ApiService.instance.createCase(user);
                      final caseId = result['caseId']?.toString() ?? '';
                      final customerId = result['customerId']?.toString() ?? '';

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OtpScreen(
                            caseId: caseId,
                            phone: user.phone,
                            email: user.email,
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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
