# Stage 1: Download the delayed-message-exchange plugin
FROM curlimages/curl:8.11.1 AS builder
USER root
RUN install -d /plugins && \
    curl -fsSL \
    -o /plugins/rabbitmq_delayed_message_exchange-4.2.0.ez \
    https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v4.2.0/rabbitmq_delayed_message_exchange-4.2.0.ez

# Stage 2: RabbitMQ image.
# Pin 4.2.x: upstream delayed-exchange v4.2.0 targets RabbitMQ 4.2.x only.
# (4.3.x has no matching plugin release at time of writing.)
FROM rabbitmq:4.2-management

# Copy the plugin with proper ownership for the rabbitmq user.
COPY --from=builder --chown=rabbitmq:rabbitmq \
    /plugins/rabbitmq_delayed_message_exchange-4.2.0.ez \
    /plugins/rabbitmq_delayed_message_exchange-4.2.0.ez

# Enable the plugin at build time (offline).
RUN rabbitmq-plugins enable --offline rabbitmq_delayed_message_exchange rabbitmq_shovel rabbitmq_shovel_management

# 5672 = AMQP, 15672 = Management UI.
# Runtime config (hosts entry, management bind, metrics) is applied by
# the Railway start command in railway.json — keep the image stock.
EXPOSE 5672 15672
