using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using StackExchange.Redis;

var builder = WebApplication.CreateBuilder(args);

// Đăng ký controller
builder.Services.AddControllers();

// Kết nối Redis (Singleton)
builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
{
    var redisHost = builder.Configuration["Redis:Host"] ?? "redis";
    return ConnectionMultiplexer.Connect(redisHost);
});

// Đăng ký RedisEmailService (lưu vào Redis + publish RabbitMQ)
builder.Services.AddScoped<RedisEmailService>();

// Swagger (nếu cần)
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Swagger UI
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthorization();
app.MapControllers();

app.Run();
