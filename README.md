# 🏦 Banking System – Core Banking Microservices with Bonita Workflow

Hệ thống ngân hàng mô phỏng bao gồm cả backend và frontend, hỗ trợ luồng đăng ký tài khoản, xác thực OTP, duyệt mở tài khoản, và chuyển khoản nội bộ/liên ngân hàng. Hệ thống triển khai kiến trúc microservices, tích hợp với Bonita BPM để quản lý quy trình duyệt.

---

## 🧩 Chức năng chính

- ✅ Đăng ký tài khoản ngân hàng
- ✅ Xác thực mã PIN và OTP qua email
- ✅ Duyệt tài khoản bởi nhân viên
- ✅ Tạo số tài khoản, sinh mã giao dịch
- ✅ Chuyển khoản nội bộ và liên ngân hàng
- ✅ Theo dõi và xử lý trạng thái giao dịch
- ✅ Giao diện web khách hàng + nhân viên

---

## 🏗 Kiến trúc tổng quan

```text
Flutter/Web UI
     │
     ▼
Gateway API (Node.js) ──▶ Bonita BPM
     │                          │
     ├─▶ user-service (ASP.NET) │
     ├─▶ otp-service (ASP.NET)  │
     └─▶ transfer-service (ASP.NET)
