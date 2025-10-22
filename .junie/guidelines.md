Project Development Guidelines (Advanced)

Scope and intent
- This document records project-specific practices to build, run, test, and extend this repository. It assumes you are familiar with Docker, Kafka, Flink, Pinot, Python/Poetry, Kotlin/Gradle.
- All external library and tool behaviors referenced here were consulted via Context7 MCP (see Sources consulted). Do not rely on assumptions; re-check Context7 for versions you use.

1) Build and configuration
Infrastructure (Docker Compose + Makefile)
- Orchestration: docker-compose.yaml provisions:
  - Kafka 3.8.0 (KRaft mode). External bootstrap: localhost:29092, internal: kafka:9092.
  - Pinot (controller:9000, broker:8099, server:8097) with Zookeeper for Pinot.
  - Kafka UI at http://localhost:8080.
  - Optional generator container that runs the Python event generator against kafka:9092.
- Top-level Makefile targets (see make/common.mk for helpers):
  - make start: Rebuilds/starts the stack (docker compose up -d --build) after clean down.
  - make stop: Stops and removes containers/volumes/orphans.
  - make status: docker compose ps snapshot.
  - make urls: Prints useful endpoints and connection strings.
  - make check-kafka / check-kafka-ui / check-flink: Basic readiness checks for core services.
  - make create-topics: Creates Kafka topics used by Flink SQL: raw-events, active-users-per-minute, product-analytics, user-session-analytics.
  - make pinot-init: Runs Pinot schema/table initialization job.
  - make pinot-validate: Verifies Pinot controller/broker/server health and lists tables.
  - make validate-all: Aggregates checks and topic creation.
Notes
- Flink dashboard at http://localhost:8081 (exposed by the flink service when present). Kafka UI at http://localhost:8080. Pinot Web UI at http://localhost:9000. Pinot Broker SQL endpoint at http://localhost:8099/query/sql.
- The flink/sql/flink.sql file defines source/sinks over Kafka and inserts for three result tables. Kafka topic names in that SQL match the Makefile’s create-topics target.

Python apps (Poetry)
- Dashboard (dashboard/):
  - Python constraint: ">=3.9,<3.9.7 || >3.9.7,<4.0". Dependencies include streamlit, plotly, pandas, pinotdb.
  - Env: PINOT_HOST (default localhost) and PINOT_PORT (default 8099) are read by src/analytics_dashboard/app.py to connect via pinotdb.connect(host, port, path='/query/sql', scheme='http').
  - Run: poetry install, then poetry run streamlit run src/analytics_dashboard/app.py. See Streamlit CLI details in Context7.
- Generator (generator/):
  - Python 3.9, dependencies: kafka-python, faker, pydantic, python-dotenv. Dev group: pytest, black, isort, flake8, mypy, pytest-cov.
  - Entrypoint: python -m analytics_generator.generator. Container runs this module by default.
  - Env: KAFKA_BOOTSTRAP_SERVERS (default localhost:9092 when run on host; kafka:9092 in Docker), KAFKA_TOPIC (default analytics_events in code, overridden to raw-events in docker-compose), EVENTS_PER_SECOND (default 1).
  - Producer construction follows kafka-python’s KafkaProducer(bootstrap_servers=[...]) with JSON serialization (Context7: /dpkp/kafka-python). See generator/src/analytics_generator/generator.py.


3) Additional development information
Code style and static checks
- Generator (Python): black, isort, flake8, mypy are declared in dev dependencies.
  - Formatting: poetry run black .
  - Imports: poetry run isort .
  - Linting: poetry run flake8
  - Type checks: poetry run mypy src
- Dashboard (Python): black and flake8 are declared. Similar usage via Poetry.
- Keep tests deterministic: use Faker seeding where appropriate for reproducible snapshots if asserting exact values.

Runtime configuration tips (project-specific)
- Kafka connectivity (generator):
  - In Docker: KAFKA_BOOTSTRAP_SERVERS=kafka:9092 (see docker-compose). On host: localhost:29092 (external listener). The generator uses kafka-python’s KafkaProducer with JSON serialization; see Context7 for producer retries/flush and callbacks.
- Pinot connectivity (dashboard):
  - PINOT_HOST and PINOT_PORT feed pinotdb.connect(host, port, path='/query/sql', scheme='http'). The broker SQL endpoint is mapped to localhost:8099. Ensure Pinot tables are initialized (make pinot-init) and ingestion is flowing (Flink SQL jobs, or the generator + Kafka + Flink pipeline).
- Flink SQL pipeline
  - The flink/sql/flink.sql file creates:
    - raw_events source (kafka, topic=raw-events, json, watermark on event_timestamp)
    - active_users_per_minute, product_analytics, user_session_analytics sinks (upsert-kafka)
  - Ensure topics exist (make create-topics) before submitting jobs.

Submitting/running components
- Local dev loop (host tools):
  1) make start
  2) make validate-all and make urls
  3) (Optional) Submit Flink SQL job via Flink UI or CLI (jobmanager at 8081). Ensure create-topics ran.
  4) In generator/: poetry install && poetry run python -m analytics_generator.generator
  5) In dashboard/: poetry install && poetry run streamlit run src/analytics_dashboard/app.py
- Containerized loop:
  - The generator container is wired to kafka:9092 and raw-events topic per docker-compose.yaml and will start after Kafka is healthy.

Troubleshooting notes
- Kafka UI has no clusters listed: Wait for kafka to be healthy; check docker compose logs kafka.
- Pinot tables missing: make pinot-init, then make pinot-validate. Ensure schemas/tables in pinot/config/... are mounted.
- Dashboard shows no data: Verify Pinot Broker at http://localhost:8099/health, and that product_analytics table has rows. Trace back to Flink job and generator activity.

Sources consulted via Context7 MCP (non-exhaustive)
- Poetry: /websites/python-poetry — topics: poetry install, poetry run, env management.
- Kafka Python client: /dpkp/kafka-python — topics: KafkaProducer usage, retries/flush, basic producer patterns.
- Streamlit: /streamlit/streamlit — topics: CLI run, hello, basic session state and environment.
- Apache Flink: /apache/flink and /websites/nightlies_apache_flink_flink-docs-master — general reference for dashboard/CLI and SQL connectors.
- Apache Pinot: /apache/pinot and /websites/pinot_apache — general reference for broker/controller endpoints and SQL.

Change management
- This document is the only artifact added in this change. A temporary test file was created and executed to validate instructions, then removed to avoid repo noise.
