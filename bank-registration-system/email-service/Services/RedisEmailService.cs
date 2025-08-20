using StackExchange.Redis;
using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

public class RedisEmailService
{
    private readonly IDatabase _redis;
    private readonly IConnectionFactory _rabbitMQFactory;

    public RedisEmailService(IConnectionMultiplexer redis)
    {
        _redis = redis.GetDatabase();
        _rabbitMQFactory = new ConnectionFactory { HostName = "rabbitmq" };
    }

    public void SendEmail(string email, string subject, string body)
    {
        // 1. Tạo key và lưu vào Redis để tracking
        var messageId = Guid.NewGuid().ToString();
        var emailData = new { Email = email, Subject = subject, Body = body, Status = "pending" };
        _redis.StringSet($"email:{messageId}", JsonSerializer.Serialize(emailData), TimeSpan.FromMinutes(10));

        // 2. Publish message vào RabbitMQ
        using var connection = _rabbitMQFactory.CreateConnection();
        using var channel = connection.CreateModel();

        channel.QueueDeclare(queue: "email_queue",
                             durable: true,
                             exclusive: false,
                             autoDelete: false,
                             arguments: null);

        var message = new
        {
            Method = "email",
            Email = email,
            Subject = subject,
            Body = body,
            MessageId = messageId
        };
        var bodyBytes = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(message));

        channel.BasicPublish(exchange: "",
                             routingKey: "email_queue",
                             basicProperties: null,
                             body: bodyBytes);

        Console.WriteLine($"[EMAIL] Gửi thông báo cho {email} (MessageId={messageId})");
    }

    public void MarkAsSent(string messageId)
    {
        // Cập nhật trạng thái trong Redis
        var emailData = _redis.StringGet($"email:{messageId}");
        if (!emailData.IsNullOrEmpty)
        {
            var data = JsonSerializer.Deserialize<Dictionary<string, object>>(emailData);
            data["Status"] = "sent";
            _redis.StringSet($"email:{messageId}", JsonSerializer.Serialize(data));
        }
    }
}
