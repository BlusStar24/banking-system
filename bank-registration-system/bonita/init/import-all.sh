#!/bin/sh

echo "⏳ Đợi Bonita sẵn sàng trên cổng 8080..."
for i in $(seq 1 120); do
  if curl -s http://bonita:8080/bonita > /dev/null; then
    echo "✅ Bonita đã sẵn sàng!"
    break
  fi
  echo "Bonita chưa sẵn sàng, thử lại sau 5 giây... ($i/120)"
  sleep 5
done
if [ $i -eq 120 ]; then
  echo "❌ Bonita không sẵn sàng sau 10 phút!"
  exit 1
fi

# Đăng nhập và lấy cookie
COOKIE=$(mktemp)
curl -s -c $COOKIE -X POST \
  -d "username=walter.bates&password=bpm" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  http://bonita:8080/bonita/loginservice

# Kiểm tra đăng nhập
if [ ! -s $COOKIE ]; then
  echo "❌ Đăng nhập thất bại!"
  exit 1
fi

# Import tổ chức
echo "📥 Import tổ chức..."
curl -b $COOKIE -X POST \
  -F "file=@/init/Organization_Data.xml" \
  http://bonita:8080/bonita/API/portal/organization/import

# Import BAR
if [ -f /init/CreateAccountBank--1.0.bar ]; then
  echo "📦 Import process BAR..."
  curl -b $COOKIE -X POST \
    -F "file=@/init/CreateAccountBank--1.0.bar" \
    http://bonita:8080/bonita/API/bpm/process
else
  echo "❌ Không tìm thấy file CreateAccountBank--1.0.bar"
  exit 1
fi

# Gán user vào profile
echo "🔐 Gán user william.jobs vào profile User + Admin..."

# Lấy ID của user william.jobs
USER_ID=$(curl -s -b $COOKIE "http://bonita:8080/bonita/API/identity/user?f=userName=william.jobs" | grep -o '"id":"[0-9]*"' | head -n1 | cut -d'"' -f4)

# Lấy ID profile "User"
USER_PROFILE_ID=$(curl -s -b $COOKIE "http://bonita:8080/bonita/API/profile?p=0&c=10" | grep -A2 '"name":"User"' | grep '"id":"' | grep -o '[0-9]\+')

# Lấy ID profile "Administrator"
ADMIN_PROFILE_ID=$(curl -s -b $COOKIE "http://bonita:8080/bonita/API/profile?p=0&c=10" | grep -A2 '"name":"Administrator"' | grep '"id":"' | grep -o '[0-9]\+')

# Gán profile "User"
curl -s -b $COOKIE -X POST \
  -H "Content-Type: application/json" \
  -d "{\"profile_id\":$USER_PROFILE_ID,\"user_id\":$USER_ID}" \
  http://bonita:8080/bonita/API/profileMember

# Gán profile "Administrator"
curl -s -b $COOKIE -X POST \
  -H "Content-Type: application/json" \
  -d "{\"profile_id\":$ADMIN_PROFILE_ID,\"user_id\":$USER_ID}" \
  http://bonita:8080/bonita/API/profileMember

echo "✅ Gán profile hoàn tất"
rm $COOKIE