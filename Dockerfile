# Stage 1: Download the plugin (avoid ubuntu:20.04 — EOL and heavy for a single curl)
FROM curlimages/curl:8.11.1 AS builder
USER root
RUN install -d /plugins && \
    curl -fsSL \
    -o /plugins/rabbitmq_delayed_message_exchange-4.2.0.ez \
    https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v4.2.0/rabbitmq_delayed_message_exchange-4.2.0.ez

# Stage 2: Main RabbitMQ image
# Pin 4.2.x: upstream delayed-exchange v4.2.0 targets RabbitMQ 4.2.x only (4.3+ has no matching release; repo archived).
FROM rabbitmq:4.2-management

# Copy plugin with proper ownership
COPY --from=builder --chown=rabbitmq:rabbitmq \
    /plugins/rabbitmq_delayed_message_exchange-4.2.0.ez \
    /plugins/rabbitmq_delayed_message_exchange-4.2.0.ez

# Enable the plugin during build
RUN rabbitmq-plugins enable --offline rabbitmq_delayed_message_exchange

# Expose the standard RabbitMQ ports
# 5672 - AMQP port
# 15672 - Management UI port
EXPOSE 5672 15672
