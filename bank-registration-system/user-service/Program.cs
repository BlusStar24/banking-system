using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.IdentityModel.Logging;
using System.Text;
using user_service.Data;
using user_service.Services;
using StackExchange.Redis;
using user_service.Middleware;
using System.Security.Claims;
// user-service/Program.cs
var builder = WebApplication.CreateBuilder(args);
IdentityModelEventSource.ShowPII = true;
// ==================================CORS cho phép frontend gọi API============================
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins("http://localhost:3000")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// ==========================================Add DbContext=========================================
builder.Services.AddDbContext<UserDbContext>(options =>
    options.UseMySql(
    builder.Configuration.GetConnectionString("DefaultConnection"),
    new MySqlServerVersion(new Version(8, 0, 0)),
    mySqlOptions => mySqlOptions.EnableRetryOnFailure()));

// ========== Thêm Redis (sử dụng StackExchange.Redis) ==========
builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
{
    var config = builder.Configuration["Redis:Connection"] ?? "redis:6379";
    return ConnectionMultiplexer.Connect(config);
});

// ==========================================Add services==========================================
builder.Services.AddScoped<UserService>();
builder.Services.AddScoped<BonitaService>();
builder.Services.AddScoped<AuthService>();
builder.Services.AddHttpClient();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpContextAccessor();
// ==============================Lấy JWT Key từ appsettings.json===================================
var jwtKey = builder.Configuration["Jwt:Key"] ??
             "super_secure_key_32_chars_long_minimum!!";
var keyBytes = Encoding.UTF8.GetBytes(jwtKey);

// ==============================Cấu hình Authentication cho JWT===================================
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(keyBytes),
        ValidateIssuer = false,
        ValidateAudience = false,
        ClockSkew = TimeSpan.FromSeconds(60),
        // Cấu hình ClaimTypes cho JWT
        NameClaimType = ClaimTypes.Name,
        RoleClaimType = ClaimTypes.Role
    };

  options.Events = new JwtBearerEvents
    {
        OnTokenValidated = context =>
        {
            var identity = context.Principal?.Identity as ClaimsIdentity;
            var userIdClaim = identity?.FindFirst("UserId");

            if (userIdClaim != null && identity != null)
            {
                // ⚠️ Cần gắn UserId vào NameIdentifier để hệ thống xem là user đã đăng nhập
                identity.AddClaim(new Claim(ClaimTypes.NameIdentifier, userIdClaim.Value));
            }

            Console.WriteLine("✅ Claims sau khi xử lý:");
            foreach (var claim in identity!.Claims)
            {
                Console.WriteLine($"- {claim.Type}: {claim.Value}");
            }

            return Task.CompletedTask;
        },
        OnAuthenticationFailed = context =>
        {
            Console.WriteLine($"❌ Token lỗi: {context.Exception.Message}");
            return Task.CompletedTask;
        }
    };


});

var app = builder.Build();
//

// ========================================Middleware================================================
app.UseCors("AllowFrontend");
app.UseSwagger();
app.UseSwaggerUI();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();
app.UseMiddleware<LastActiveMiddleware>();
app.MapControllers();
app.Run();
