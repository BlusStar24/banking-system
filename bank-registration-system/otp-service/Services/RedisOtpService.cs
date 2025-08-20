using StackExchange.Redis;
using System;
using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

public class RedisOtpService
{
    private readonly IDatabase _redis;
    private readonly IConnectionFactory _rabbitMQFactory;

    public RedisOtpService(IConnectionMultiplexer redis)
    {
        _redis = redis.GetDatabase();
        _rabbitMQFactory = new ConnectionFactory { HostName = "rabbitmq" };
    }

    public void Send(string phone, string email, string method)
    {
        var otp = new Random().Next(100000, 999999).ToString();
        _redis.StringSet($"otp:{phone}", otp, TimeSpan.FromMinutes(5));

        // Gửi thông điệp OTP vào RabbitMQ
        using var connection = _rabbitMQFactory.CreateConnection();
        using var channel = connection.CreateModel();
        channel.QueueDeclare(queue: "email_queue",
                             durable: true,
                             exclusive: false,
                             autoDelete: false,
                             arguments: null);

        var message = new
        {
            Phone = phone,
            Email = email,
            Method = method,
            Otp = otp,
            Subject = "Mã OTP xác thực đăng ký",
            Body = $"Mã OTP của bạn là: {otp} (hết hạn sau 5 phút)."
        };

        var body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(message));
        channel.BasicPublish(exchange: "",
                            routingKey: "email_queue",
                            basicProperties: null,
                            body: body);

        Console.WriteLine($"[OTP] Gửi mã OTP {otp} cho {phone} qua {method}");
    }

    public bool Verify(string phone, string code)
    {
        var stored = _redis.StringGet($"otp:{phone}");
        return stored == code;
    }
}