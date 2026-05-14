FROM heidiks/rabbitmq-delayed-message-exchange:4.2.0-management

# Expose the standard RabbitMQ ports
# 5672 - AMQP port
# 15672 - Management UI port
EXPOSE 5672 15672
