# ============================================
# MedBook Makefile — Công cụ điều khiển dự án
# ============================================

.PHONY: help up up-d down build logs clean status

help: ## Hiển thị menu hướng dẫn
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

init: ## Khởi tạo dự án (Copy .env)
	@test -f .env || cp .env.example .env
	@echo "File .env đã sẵn sàng. Chạy 'make up' để bắt đầu."

up: ## Khởi động hệ thống (Build toàn bộ bằng Docker)
	docker compose up --build

up-d: ## Khởi động chế độ chạy ngầm (Detached)
	docker compose up --build -d

down: ## Dừng toàn bộ hệ thống
	docker compose down

clean: ## Xóa sạch mọi thứ (Container, Image, Volume) - Làm mới 100%
	docker compose down -v --rmi all --remove-orphans

status: ## Kiểm tra trạng thái các service
	docker compose ps

logs: ## Xem log thời gian thực
	docker compose logs -f
