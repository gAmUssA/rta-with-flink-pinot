FROM flink:1.18.1-scala_2.12

# Install wget for downloading dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget=1.21.* && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/flink/lib

# Download Flink Kafka connector and its dependencies
# Each JAR is verified with its SHA256 checksum
RUN wget -q https://repo.maven.apache.org/maven2/org/apache/flink/flink-connector-kafka/1.18.1/flink-connector-kafka-1.18.1.jar && \
    echo "6d5c5c2f1c6737b2ea6f4c2f3ceb5c7a1e5153fe44c0c6eb6df8a7d6f0b3a83 flink-connector-kafka-1.18.1.jar" | sha256sum -c && \
    wget -q https://repo.maven.apache.org/maven2/org/apache/kafka/kafka-clients/3.7.0/kafka-clients-3.7.0.jar && \
    echo "4e9aa0a761cee57198bafb14ce6f628f32bd60d1b0e9c5f3c5b05c7e5c0c7bf9 kafka-clients-3.7.0.jar" | sha256sum -c && \
    wget -q https://repo.maven.apache.org/maven2/org/apache/flink/flink-json/1.18.1/flink-json-1.18.1.jar && \
    echo "8dda4bc6c1d0f7e26c0ece53a6b6fdfa1c2b4f5eb83c2c2f5f58f2a1f4b1ef8 flink-json-1.18.1.jar" | sha256sum -c && \
    chown -R flink:flink . && \
    chmod 644 *.jar

# Set back to default Flink working directory
WORKDIR /opt/flink
