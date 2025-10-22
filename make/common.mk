# Colors
BLUE := \033[34m
GREEN := \033[32m
RED := \033[31m
YELLOW := \033[33m
RESET := \033[0m
BOLD := \033[1m

# Emojis
ROCKET := 🚀
CHECK := ✅
WARN := ⚠️
ERROR := ❌
KAFKA := 📬
FLINK := 🌊
UI := 🖥️
PINOT := 🍷
CLEANUP := 🧹
INFO := ℹ️

# Common commands
DOCKER_COMPOSE := docker compose
CURL := curl -s
TIMEOUT := timeout 60
NC := nc -z

# Common messages
define MSG_SUCCESS
	@echo "$(GREEN)$(CHECK) $(1)$(RESET)"
endef

define MSG_INFO
	@echo "$(BLUE)$(INFO) $(1)$(RESET)"
endef

define MSG_WARN
	@echo "$(YELLOW)$(WARN) $(1)$(RESET)"
endef

define MSG_ERROR
	@echo "$(RED)$(ERROR) $(1)$(RESET)"
endef

define MSG_START
	@echo "$(BLUE)$(ROCKET) $(1)$(RESET)"
endef

define MSG_CLEANUP
	@echo "$(YELLOW)$(CLEANUP) $(1)$(RESET)"
endef
