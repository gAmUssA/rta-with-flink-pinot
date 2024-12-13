-- Create source table for raw events from Kafka
CREATE TABLE raw_events (
    event_id STRING,
    event_timestamp TIMESTAMP(3),
    event_type STRING,
    user_id STRING,
    session_id STRING,
    device_type STRING,
    os STRING,
    browser STRING,
    location STRING,
    -- PageViewEvent specific fields
    page_url STRING,
    referrer_url STRING,
    time_spent DOUBLE,
    -- ProductViewEvent specific fields
    product_id STRING,
    product_name STRING,
    product_category STRING,
    price DOUBLE,
    -- AddToCartEvent and PurchaseEvent specific fields
    quantity INT,
    total_amount DOUBLE,
    -- PurchaseEvent specific field
    order_id STRING,
    -- Metadata fields
    WATERMARK FOR event_timestamp AS event_timestamp - INTERVAL '5' SECONDS
) WITH (
    'connector' = 'kafka',
    'topic' = 'raw-events',
    'properties.bootstrap.servers' = 'kafka:9092',
    'properties.group.id' = 'flink-analytics-consumer',
    'format' = 'json',
    'json.ignore-parse-errors' = 'true',
    'json.timestamp-format.standard' = 'ISO-8601',
    'scan.startup.mode' = 'earliest-offset'
);
-- Create result tables with upsert-kafka connector
-- Active users per minute
CREATE TABLE active_users_per_minute (
    window_start TIMESTAMP(3),
    window_end TIMESTAMP(3),
    active_users BIGINT,
    PRIMARY KEY (window_start, window_end) NOT ENFORCED
) WITH (
    'connector' = 'upsert-kafka',
    'topic' = 'active-users-per-minute',
    'properties.bootstrap.servers' = 'kafka:9092',
    'key.format' = 'json',
    'value.format' = 'json'
);
-- Product analytics
CREATE TABLE product_analytics (
    product_id STRING,
    product_name STRING,
    product_category STRING,
    view_count BIGINT,
    cart_adds BIGINT,
    purchases BIGINT,
    revenue DOUBLE,
    update_time TIMESTAMP(3),
    PRIMARY KEY (product_id) NOT ENFORCED
) WITH (
    'connector' = 'upsert-kafka',
    'topic' = 'product-analytics',
    'properties.bootstrap.servers' = 'kafka:9092',
    'key.format' = 'json',
    'value.format' = 'json'
);
-- User session analytics
CREATE TABLE user_session_analytics (
    session_id STRING,
    user_id STRING,
    session_start TIMESTAMP(3),
    session_end TIMESTAMP(3),
    page_views BIGINT,
    product_views BIGINT,
    cart_adds BIGINT,
    purchases BIGINT,
    total_spent DOUBLE,
    PRIMARY KEY (session_id) NOT ENFORCED
) WITH (
    'connector' = 'upsert-kafka',
    'topic' = 'user-session-analytics',
    'properties.bootstrap.servers' = 'kafka:9092',
    'key.format' = 'json',
    'value.format' = 'json'
);
-- Insert queries to populate the result tables
-- Active users per minute
INSERT INTO active_users_per_minute
SELECT TUMBLE_START(event_timestamp, INTERVAL '1' MINUTE) as window_start,
    TUMBLE_END(event_timestamp, INTERVAL '1' MINUTE) as window_end,
    COUNT(DISTINCT user_id) as active_users
FROM raw_events
GROUP BY TUMBLE(event_timestamp, INTERVAL '1' MINUTE);
-- Product analytics
INSERT INTO product_analytics
SELECT product_id,
    MAX(product_name) as product_name,
    MAX(product_category) as product_category,
    COUNT(
        DISTINCT CASE
            WHEN event_type = 'product_view' THEN event_id
        END
    ) as view_count,
    COUNT(
        DISTINCT CASE
            WHEN event_type = 'add_to_cart' THEN event_id
        END
    ) as cart_adds,
    COUNT(
        DISTINCT CASE
            WHEN event_type = 'purchase' THEN event_id
        END
    ) as purchases,
    SUM(
        CASE
            WHEN event_type = 'purchase' THEN total_amount
            ELSE 0
        END
    ) as revenue,
    MAX(event_timestamp) as update_time
FROM raw_events
WHERE product_id IS NOT NULL
GROUP BY product_id;
-- User session analytics
INSERT INTO user_session_analytics
SELECT session_id,
    user_id,
    MIN(event_timestamp) as session_start,
    MAX(event_timestamp) as session_end,
    COUNT(
        CASE
            WHEN event_type = 'page_view' THEN 1
        END
    ) as page_views,
    COUNT(
        CASE
            WHEN event_type = 'product_view' THEN 1
        END
    ) as product_views,
    COUNT(
        CASE
            WHEN event_type = 'add_to_cart' THEN 1
        END
    ) as cart_adds,
    COUNT(
        CASE
            WHEN event_type = 'purchase' THEN 1
        END
    ) as purchases,
    SUM(
        CASE
            WHEN event_type = 'purchase' THEN total_amount
            ELSE 0
        END
    ) as total_spent
FROM raw_events
GROUP BY session_id,
    user_id;

-- Select all events with basic information
SELECT event_id,
    event_timestamp,
    event_type,
    user_id,
    session_id,
    device_type,
    os,
    browser,
    location
FROM raw_events;