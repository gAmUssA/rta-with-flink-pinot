FROM flink:1.20-scala_2.12

# Download Flink SQL connectors
RUN wget -P /opt/flink/lib https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/3.4.0-1.20/flink-sql-connector-kafka-3.4.0-1.20.jar && \
    wget -P /opt/flink/lib https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.6.1/kafka-clients-3.6.1.jar

RUN chown -R flink:flink /opt/flink/lib

# Copy logging configuration
COPY log4j-console.properties /opt/flink/conf/log4j-console.properties

# Set environment variable for logging configuration
ENV LOG4J_CONSOLE_PROPERTIES=/opt/flink/conf/log4j-console.properties

# Set back to default Flink working directory
WORKDIR /opt/flink
