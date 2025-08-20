using Microsoft.AspNetCore.Http;
using StackExchange.Redis;
using System.Security.Claims;
using System.Threading.Tasks;

namespace user_service.Middleware
{
    public class LastActiveMiddleware
    {
        private readonly RequestDelegate _next;

        public LastActiveMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task InvokeAsync(HttpContext context, IConnectionMultiplexer redis)
        {
            var user = context.User;
            if (user.Identity?.IsAuthenticated == true)
            {
                var userId = user.FindFirst("UserId")?.Value;
                if (!string.IsNullOrEmpty(userId))
                {
                    var db = redis.GetDatabase();
                    var key = $"last_active:{userId}";

                    var active = await db.StringGetAsync(key);

                    // Nếu key tồn tại → reset TTL 10 phút
                    if (!active.IsNullOrEmpty)
                    {
                        await db.StringSetAsync(key, "active", TimeSpan.FromMinutes(20));
                    }

                    // Nếu key mất → KHÔNG trả 401 nữa, chỉ log cảnh báo
                    else
                    {
                        Console.WriteLine($"Phiên Redis của user {userId} đã hết hạn.");
                    }
                }
            }

            await _next(context);
        }
    }
}
