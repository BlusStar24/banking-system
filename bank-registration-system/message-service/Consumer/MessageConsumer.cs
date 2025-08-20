using System;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;
using System.Threading;
using Serilog;
using System.Net.Mail;
using System.Collections.Generic;
using System.Threading.Tasks;
using Twilio;
using Twilio.Rest.Api.V2010.Account;
using System.Net;
using StackExchange.Redis;

namespace MessageService
{
    public class MessageConsumer
    {
        private readonly string _hostname = "rabbitmq";
        private readonly string _queueName = "email_queue";
        private IConnection _connection;
        private IModel _channel;
        private EventingBasicConsumer _consumer;
        private readonly EmailSender _emailSender;
        private readonly IConnectionMultiplexer _redis; // Redis chỉ kết nối 1 lần

        public MessageConsumer()
        {
            _emailSender = new EmailSender();
            _redis = ConnectionMultiplexer.Connect("redis");
        }

        public void Start()
        {
            var factory = new ConnectionFactory { HostName = _hostname };
            int retries = 5;
            while (retries > 0)
            {
                try
                {
                    _connection = factory.CreateConnection();
                    _channel = _connection.CreateModel();
                    Log.Information("Connected to RabbitMQ successfully");
                    break;
                }
                catch (Exception ex)
                {
                    retries--;
                    Log.Warning($"Failed to connect to RabbitMQ. Retries left: {retries}. Error: {ex.Message}");
                    if (retries == 0)
                        throw new Exception("Could not connect to RabbitMQ after multiple attempts.", ex);
                    Thread.Sleep(5000);
                }
            }

            _channel.QueueDeclare(queue: _queueName,
                                 durable: true,
                                 exclusive: false,
                                 autoDelete: false,
                                 arguments: null);

            _consumer = new EventingBasicConsumer(_channel);
            _consumer.Received += async (model, ea) =>
            {
                var body = ea.Body.ToArray();
                var json = Encoding.UTF8.GetString(body);
                var message = JsonSerializer.Deserialize<MessageModel>(json);

                Log.Information($"[Consumer] Processing: {json}");

                try
                {
                    if (message.Method == "email")
                    {
                        // Fallback Subject và Body nếu bị rỗng
                        var subject = string.IsNullOrEmpty(message.Subject)
                            ? "Thông báo từ ngân hàng"
                            : message.Subject;

                        var bodyText = string.IsNullOrEmpty(message.Body)
                            ? (!string.IsNullOrEmpty(message.Otp)
                                ? $"Mã OTP của bạn là: {message.Otp} (hết hạn sau 5 phút)."
                                : "Thông báo từ ngân hàng.")
                            : message.Body;

                        await _emailSender.SendEmailAsync(new List<string> { message.Email }, subject, bodyText);

                        // Cập nhật trạng thái email trong Redis
                        if (!string.IsNullOrEmpty(message.MessageId))
                        {
                            var db = _redis.GetDatabase();
                            var key = $"email:{message.MessageId}";
                            var value = db.StringGet(key);
                            if (!value.IsNullOrEmpty)
                            {
                                var data = JsonSerializer.Deserialize<Dictionary<string, object>>(value);
                                data["Status"] = "sent";
                                db.StringSet(key, JsonSerializer.Serialize(data));
                            }
                        }
                    }
                    else if (message.Method == "sms")
                    {
                        // Gửi OTP qua SMS (nếu có)
                        const string accountSid = "YOUR_TWILIO_ACCOUNT_SID";
                        const string authToken = "YOUR_TWILIO_AUTH_TOKEN";
                        const string fromPhoneNumber = "YOUR_TWILIO_PHONE_NUMBER";

                        TwilioClient.Init(accountSid, authToken);
                        await MessageResource.CreateAsync(
                            body: $"Your OTP is: {message.Otp}",
                            from: new Twilio.Types.PhoneNumber(fromPhoneNumber),
                            to: new Twilio.Types.PhoneNumber(message.Phone)
                        );

                        Log.Information($"[SMS] Sent OTP {message.Otp} to {message.Phone}");
                    }
                }
                catch (Exception ex)
                {
                    Log.Error(ex, $"Failed to send message via {message.Method}. Error: {ex.Message}");
                }
            };

            _channel.BasicConsume(queue: _queueName,
                                 autoAck: true,
                                 consumer: _consumer);
        }
    }

    // Model message chung cho email và OTP
    public class MessageModel
    {
        public string Phone { get; set; }
        public string Email { get; set; }
        public string Method { get; set; } // email hoặc sms
        public string Otp { get; set; } // OTP nếu có
        public string Subject { get; set; } // Subject email
        public string Body { get; set; } // Body email
        public string MessageId { get; set; }
    }

    // Gửi email qua SMTP
    public class EmailSender
    {
        private const string smtpServer = "smtp.gmail.com";
        private const int smtpPort = 587;
        private const string smtpUser = "cuongvnabc@gmail.com";
        private const string smtpPass = "vqpz vqdg vgns ybeq";

        public async Task SendEmailAsync(List<string> toList, string subject, string body)
        {
            using (var message = new MailMessage())
            {
                message.From = new MailAddress(smtpUser);
                foreach (var to in toList)
                {
                    message.To.Add(to);
                }
                message.Subject = subject;
                message.Body = body;
                message.IsBodyHtml = false;

                using (var client = new SmtpClient(smtpServer, smtpPort))
                {
                    client.EnableSsl = true;
                    client.Credentials = new NetworkCredential(smtpUser, smtpPass);
                    await client.SendMailAsync(message);
                    Log.Information("Đã gửi email đến: {0}", string.Join(", ", toList));
                }
            }
        }
    }
}
