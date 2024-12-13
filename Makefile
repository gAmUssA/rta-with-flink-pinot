include make/common.mk

.PHONY: start stop status check-kafka check-kafka-ui check-flink validate-all urls create-topics debug-network debug-shell debug-kafka debug-flink debug-all pinot-init pinot-validate

# Default target
all: start validate-all urls

# Start all services
start:
	$(call MSG_START,Starting all services...)
	$(call MSG_CLEANUP,Cleaning up existing containers...)
	$(DOCKER_COMPOSE) down --volumes --remove-orphans
	$(call MSG_START,Launching containers...)
	$(DOCKER_COMPOSE) up -d --build
	$(call MSG_SUCCESS,All services started)

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
	@$(TIMEOUT) bash -c 'until $(CURL) -f http://localhost:8081/config > /dev/null 2>&1; do sleep 1; printf "."; done' || ($(call MSG_ERROR,Failed to connect to Flink) && exit 1)
	@FLINK_VERSION=$$($(CURL) -s http://localhost:8081/config | grep -o '"flink-version":"[^"]*' | cut -d'"' -f4); \
	echo ""; \
	echo "$(GREEN)$(CHECK) Flink is up and running (version: $$FLINK_VERSION)$(RESET)"

# Create Kafka topics for Flink SQL
create-topics:
	$(call MSG_INFO,Creating Kafka topics...)
	$(DOCKER_COMPOSE) exec kafka /opt/kafka/bin/kafka-topics.sh --create --if-not-exists --topic raw-events --bootstrap-server kafka:29092 --partitions 1 --replication-factor 1
	$(DOCKER_COMPOSE) exec kafka /opt/kafka/bin/kafka-topics.sh --create --if-not-exists --topic active-users-per-minute --bootstrap-server kafka:29092 --partitions 1 --replication-factor 1
	$(DOCKER_COMPOSE) exec kafka /opt/kafka/bin/kafka-topics.sh --create --if-not-exists --topic product-analytics --bootstrap-server kafka:29092 --partitions 1 --replication-factor 1
	$(DOCKER_COMPOSE) exec kafka /opt/kafka/bin/kafka-topics.sh --create --if-not-exists --topic user-session-analytics --bootstrap-server kafka:29092 --partitions 1 --replication-factor 1
	$(call MSG_SUCCESS,Kafka topics created successfully)

# Print component URLs
urls:
	@echo "$(INFO) $(BOLD)Component URLs:$(RESET)"
	@echo "$(KAFKA) $(BOLD)Kafka UI:$(RESET)        $(BLUE)http://localhost:8080$(RESET)"
	@echo "$(KAFKA) $(BOLD)Bootstrap Servers:$(RESET) $(BLUE)localhost:9092$(RESET) (external), $(BLUE)kafka:29092$(RESET) (internal)"
	@echo "$(FLINK) $(BOLD)Flink Dashboard:$(RESET) $(BLUE)http://localhost:8081$(RESET)"

# Validate all components are running
validate-all: check-kafka check-kafka-ui check-flink pinot-validate create-topics
	@echo "$(GREEN)$(BOLD)$(ROCKET) All components are up and running!$(RESET)"

# Pinot targets
.PHONY: pinot-init pinot-validate

pinot-init: ## Initialize Pinot schemas and tables
	@echo "Initializing Pinot schemas and tables..."
	$(DOCKER_COMPOSE) up pinot-init

pinot-validate: ## Validate Pinot setup
	@echo "Validating Pinot setup..."
	$(DOCKER_COMPOSE) exec pinot-controller curl -s http://localhost:9000/health || (echo "Pinot controller is not running" && exit 1)
	@echo "Controller: OK"
	$(DOCKER_COMPOSE) exec pinot-broker curl -s http://localhost:8099/health || (echo "Pinot broker is not running" && exit 1)
	@echo "Broker: OK"
	$(DOCKER_COMPOSE) exec pinot-server curl -s http://localhost:8098/health || (echo "Pinot server is not running" && exit 1)
	@echo "Server: OK"
	@echo "Checking tables..."
	$(DOCKER_COMPOSE) exec pinot-controller curl -s http://localhost:9000/tables | jq -r '.tables[]' || (echo "Failed to get tables" && exit 1)
	@echo "Tables: OK"
	@echo "Pinot validation complete "

# Debug network connectivity
debug-network:
	@$(call MSG_INFO,Testing network connectivity...)
	@echo "$(INFO) Testing Kafka connections:"
	@$(DOCKER_COMPOSE) exec debug nc -zv kafka 9092 || true
	@$(DOCKER_COMPOSE) exec debug nc -zv kafka 29092 || true
	@$(DOCKER_COMPOSE) exec debug nc -zv kafka 9093 || true
	@echo "\n$(INFO) Testing Flink JobManager connection:"
	@$(DOCKER_COMPOSE) exec debug nc -zv jobmanager 8081 || true

# Interactive debug shell
debug-shell:
	@$(call MSG_INFO,Starting debug shell...)
	@$(DOCKER_COMPOSE) exec debug bash

# Test Kafka connectivity with telnet
debug-kafka:
	@$(call MSG_INFO,Testing Kafka with telnet...)
	@$(DOCKER_COMPOSE) exec debug timeout 2 telnet kafka 9092 || true

# Test Flink UI
debug-flink:
	@$(call MSG_INFO,Testing Flink UI...)
	@$(DOCKER_COMPOSE) exec debug curl -I http://jobmanager:8081/config || true

# Run all debug checks
debug-all: debug-network debug-kafka debug-flink
	@$(call MSG_SUCCESS,All debug checks completed)
