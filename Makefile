include make/common.mk

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
CLEANUP := 🧹
INFO := ℹ️

.PHONY: start stop status check-kafka check-kafka-ui check-flink validate-all

# Default target
all: start validate-all

# Start all services
start:
	$(call MSG_START,Starting all services...)
	$(call MSG_CLEANUP,Cleaning up existing containers...)
	$(DOCKER_COMPOSE) down --volumes --remove-orphans
	$(call MSG_START,Launching containers...)
	$(DOCKER_COMPOSE) up -d

# Stop all services
stop:
	$(call MSG_CLEANUP,Stopping all services...)
	$(DOCKER_COMPOSE) down --volumes --remove-orphans
	$(call MSG_SUCCESS,All services stopped)

# Show status of all services
status:
	$(call MSG_INFO,Current services status:)
	$(DOCKER_COMPOSE) ps

# Check Kafka health
check-kafka:
	$(call MSG_INFO,Checking Kafka...)
	@$(TIMEOUT) bash -c 'until $(NC) localhost 9092; do sleep 1; echo -n "."; done' || ($(call MSG_ERROR,Failed to connect to Kafka) && exit 1)
	@echo ""
	$(call MSG_SUCCESS,Kafka is up and running)

# Check Kafka UI health
check-kafka-ui:
	$(call MSG_INFO,Checking Kafka UI...)
	@$(TIMEOUT) bash -c 'until $(CURL) -f http://localhost:8080/api/clusters > /dev/null; do sleep 1; echo -n "."; done' || ($(call MSG_ERROR,Failed to connect to Kafka UI) && exit 1)
	@echo ""
	$(call MSG_SUCCESS,Kafka UI is up and running)

# Check Flink health
check-flink:
	$(call MSG_INFO,Checking Flink...)
	@$(TIMEOUT) bash -c 'until $(CURL) -f http://localhost:8081/config | grep -q "flink-version"; do sleep 1; echo -n "."; done' || ($(call MSG_ERROR,Failed to connect to Flink) && exit 1)
	@FLINK_VERSION=$$($(CURL) http://localhost:8081/config | jq -r '.["flink-version"]'); \
	echo ""; \
	$(call MSG_SUCCESS,Flink is up and running \(version: $$FLINK_VERSION\))

# Validate all components are running
validate-all: check-kafka check-kafka-ui check-flink
	@echo "$(GREEN)$(BOLD)$(ROCKET) All components are up and running!$(RESET)"
