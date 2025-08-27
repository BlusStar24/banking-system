# 🏦 Banking System – Core Banking Microservices with Bonita Workflow

Hệ thống ngân hàng mô phỏng bao gồm cả backend và frontend, hỗ trợ luồng đăng ký tài khoản, xác thực OTP, duyệt mở tài khoản, và chuyển khoản nội bộ/liên ngân hàng. Hệ thống triển khai kiến trúc microservices, tích hợp với Bonita BPM để quản lý quy trình duyệt.

---

## 🧩 Chức năng chính

- Đăng ký tài khoản ngân hàng
- Xác thực mã PIN và OTP qua email
- Duyệt tài khoản bởi nhân viên
- Tạo số tài khoản, sinh mã giao dịch
- Chuyển khoản nội bộ và liên ngân hàng
- Theo dõi và xử lý trạng thái giao dịch
- Giao diện web khách hàng + nhân viên

---

## 🏗 Kiến trúc tổng quan


Flutter/Web UI
     │
     ▼
Gateway API (Node.js) ──▶ Bonita BPM
     │                          │
     ├─▶ user-service (ASP.NET) │
     ├─▶ otp-service (ASP.NET)  │
     └─▶ transfer-service (ASP.NET)
📁 Cấu trúc thư mục
Thư mục	Vai trò
bankapp_flutter/	App Flutter cho khách hàng
gateway-api/	API trung gian Node.js (gọi Bonita + các service)
user-service/	Đăng ký, xác thực người dùng (ASP.NET)
otp-service/	Gửi và xác minh OTP qua email (ASP.NET)
transfer-service/	Chuyển khoản, xác thực PIN, kiểm tra blacklist (ASP.NET)
bonita/	Sơ đồ quy trình và khởi tạo Bonita BPM
frontend/	Giao diện web HTML cho khách hàng & nhân viên
database/	MySQL data & script
connectorDefs/	Cấu hình connectors Bonita

🚀 Hướng dẫn khởi động hệ thống
bash
Sao chép
Chỉnh sửa
git clone https://github.com/BlusStar24/banking-system.git
cd banking-system
docker-compose up --build
📌 Yêu cầu:

Docker + Docker Compose

Cổng mặc định: 5055, 5000, 5050, 8080, 8081, 3000

Tài khoản mẫu
Vai trò	SĐT (username)	Mật khẩu
Khách hàng	091200004444	123456
Nhân viên	0909123456	123456

👨‍💻 Tác giả
Nguyễn Xuân Cường – GitHub @BlusStar24

Trường: Đại học Công Thương

📌 Ghi chú
Tích hợp xác thực JWT + lưu trạng thái vào Redis.

Dữ liệu giao dịch được ghi xuống MySQL.

Hỗ trợ khôi phục lại quy trình bị lỗi qua Bonita.

📷 Screenshots (tùy chọn)
Bạn có thể thêm ảnh các màn hình vào đây:

Đăng ký tài khoản

Nhập OTP

Nhân viên duyệt

Chuyển khoản thành công

---

### ✅ Gợi ý tiếp theo:
Bạn nên lưu file này thành:

ThucTap/README.md

Rồi commit:

```bash
git add README.md
git commit -m "📝 Thêm README mô tả project"
git push
