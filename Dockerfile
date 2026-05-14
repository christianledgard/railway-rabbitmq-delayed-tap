# Stage 1: Download the plugin
FROM ubuntu:20.04 AS builder

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y curl

RUN mkdir -p /plugins && \
    curl -fsSL \
    -o "/plugins/rabbitmq_delayed_message_exchange-4.1.0.ez" \
    https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v4.1.0/rabbitmq_delayed_message_exchange-4.1.0.ez

# Stage 2: Main RabbitMQ image
FROM rabbitmq:4-management

# Copy plugin with proper ownership
COPY --from=builder --chown=rabbitmq:rabbitmq \
    /plugins/rabbitmq_delayed_message_exchange-4.1.0.ez \
    /plugins/rabbitmq_delayed_message_exchange-4.1.0.ez

# Enable the plugin during build
RUN rabbitmq-plugins enable --offline rabbitmq_delayed_message_exchange

# Expose the standard RabbitMQ ports
# 5672 - AMQP port
# 15672 - Management UI port
EXPOSE 5672 15672
