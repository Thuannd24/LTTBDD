#!/usr/bin/env bash
# scripts/test-registration.sh
# ==============================================================================
# Script kiểm tra luồng đăng ký người dùng (Identity Service -> Profile Service)
# Usage: bash scripts/test-registration.sh
# ==============================================================================

set -euo pipefail

# Địa chỉ API (Mặc định qua Gateway ở cổng 8080)
GATEWAY_URL="http://localhost:8080/api/v1/identity"
TIMESTAMP=$(date +%s)
USERNAME="testuser_${TIMESTAMP}"
PASSWORD="password123"
EMAIL="test_${TIMESTAMP}@clinic.com"

echo "🚀 Bắt đầu kiểm tra luồng đăng ký người dùng..."
echo "-------------------------------------------"
echo "👤 Username: ${USERNAME}"
echo "📧 Email: ${EMAIL}"

# 1. Thực hiện đăng ký User mới
echo -e "\n[1/2] Đang gọi API Đăng ký (/identity/users/registration)..."
RESPONSE=$(curl -s -X POST "${GATEWAY_URL}/users/registration" \
     -H "Content-Type: application/json" \
     -d "{
          \"username\": \"${USERNAME}\",
          \"password\": \"${PASSWORD}\",
          \"email\": \"${EMAIL}\",
          \"firstName\": \"Nguyen\",
          \"lastName\": \"Van A\",
          \"dob\": \"1995-01-01\",
          \"city\": \"Hanoi\"
         }")

# Kiểm tra nếu response chứa kết quả thành công
if echo "$RESPONSE" | grep -q "\"code\":1000" || echo "$RESPONSE" | grep -q "\"result\""; then
    echo "✅ Đăng ký thành công!"
    USER_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4 || echo "N/A")
    echo "🆔 User ID (Keycloak): ${USER_ID}"
else
    echo "❌ Đăng ký thất bại. Chi tiết lỗi:"
    echo "$RESPONSE"
    exit 1
fi

# 2. Hướng dẫn bước tiếp theo
echo -e "\n[2/2] Kiểm tra đồng bộ dữ liệu:"
echo "👉 Hãy kiểm tra logs của 'profile-service' để xác nhận Profile đã được tạo:"
echo "   Lệnh: docker compose logs profile-service"
echo "👉 Hãy đăng nhập Keycloak Admin (http://localhost:8181) để kiểm tra User trong realm 'clinic-realm'."
echo "-------------------------------------------"
echo "✨ Hoàn tất kiểm thử luồng Identity."
