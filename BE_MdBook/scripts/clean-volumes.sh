#!/usr/bin/env bash
# scripts/clean-volumes.sh
# ==============================================================================
# Script dọn dẹp sạch toàn bộ môi trường (Docker Container, Volumes, Images)
# Cẩn thận: Lệnh này sẽ xóa trắng dữ liệu đã lưu trong Database và Keycloak!
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🧹 Đang dọn dẹp toàn bộ Database, Keycloak volumes và các container..."
echo "========================================================================"

cd "$PROJECT_DIR"

# -v xóa volumes để reset sạch DB và Keycloak
# --remove-orphans xóa các container cũ không còn trong file compose
docker compose down -v --remove-orphans

echo ""
echo "✅ Dọn dẹp hoàn tất. Môi trường của bạn đã được reset về ban đầu."
echo "👉 Để khởi động lại hệ thống, hãy chạy: make up"
echo "========================================================================"
