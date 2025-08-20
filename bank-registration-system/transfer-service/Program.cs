using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.IdentityModel.Logging;
using System.Text;
using transfer_service.Data;
using transfer_service.Services;
using StackExchange.Redis;
// transfer-service/Program.cs
IdentityModelEventSource.ShowPII = true;
var builder = WebApplication.CreateBuilder(args);

// DB
builder.Services.AddDbContext<TransferDbContext>(options =>
    options.UseMySql(builder.Configuration.GetConnectionString("BankDb"),
        new MySqlServerVersion(new Version(8, 0, 42))));

// JWT 
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        var config = builder.Configuration;
        var key = Encoding.UTF8.GetBytes(config["Jwt:Key"]!);

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(key),

            ValidateIssuer = false,        // phải tắt nếu user-service không gán issuer
            ValidateAudience = false,      // phải tắt nếu user-service không gán audience
            ClockSkew = TimeSpan.FromSeconds(60)

        };

        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = context =>
            {
                Console.WriteLine($"Token không hợp lệ: {context.Exception.Message}");
                return Task.CompletedTask;
            },
            OnTokenValidated = context =>
            {
                Console.WriteLine("Token hợp lệ");
                foreach (var claim in context.Principal?.Claims!)
                    Console.WriteLine($"- {claim.Type}: {claim.Value}");
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
    ConnectionMultiplexer.Connect("redis:6379") // Tên service trong Docker Compose
);
builder.Services.AddAuthorization();

// HttpClient
builder.Services.AddHttpClient<TransferService>();

// Services + Controllers
builder.Services.AddScoped<transfer_service.Services.TransferService>();
builder.Services.AddControllers();
builder.Services.AddHttpContextAccessor();
builder.Services.AddMemoryCache();

var app = builder.Build();

app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.Run();
