using RabbitMQ.Client;
using System.Text;
using System.Text.Json;
using System;
using System.Threading;
using Serilog;
namespace MessageService
{
    public class RabbitMQPublisher
    {
        private readonly string _hostname = "rabbitmq";
        private readonly string _queueName = "email_queue";
        private IConnection _connection;

        public RabbitMQPublisher()
        {
            CreateConnection();
        }

        private void CreateConnection()
        {
            var factory = new ConnectionFactory { HostName = _hostname };
            int retries = 5;
            while (retries > 0)
            {
                try
                {
                    _connection = factory.CreateConnection();
                    return;
                }
                catch (Exception ex)
                {
                    retries--;
                    Log.Warning($"Failed to connect to RabbitMQ. Retries left: {retries}. Error: {ex.Message}");
                    Thread.Sleep(5000); 
                }
            }
            throw new Exception("Could not connect to RabbitMQ after multiple attempts.");
        }
        public void SendMessage<T>(T message)
        {
            using var channel = _connection.CreateModel();
            channel.QueueDeclare(queue: _queueName,
                                 durable: true,
                                 exclusive: false,
                                 autoDelete: false,
                                 arguments: null);

            var json = JsonSerializer.Serialize(message);
            var body = Encoding.UTF8.GetBytes(json);

            channel.BasicPublish(exchange: "",
                                 routingKey: _queueName,
                                 basicProperties: null,
                                 body: body);
        }
    }
}
