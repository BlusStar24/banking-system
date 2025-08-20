using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using user_service.Data;
using user_service.DTOs;
using user_service.Models;
using Microsoft.EntityFrameworkCore;

namespace user_service.Services
{
    public class AuthService
    {
        private readonly IConfiguration _config;
        private readonly UserDbContext _context;
        private readonly ILogger<AuthService> _logger;

        public AuthService(IConfiguration config, UserDbContext context, ILogger<AuthService> logger)
        {
            _config = config;
            _context = context;
            _logger = logger;
        }

        public async Task<TokenDto> GenerateTokensAsync(User user)
        {
            var accessToken = GenerateAccessToken(user);
            var refreshToken = await GenerateAndStoreRefreshTokenAsync(user);

            return new TokenDto
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken
            };
        }

        private string GenerateAccessToken(User user)
        {
            var key = Encoding.UTF8.GetBytes(_config["Jwt:Key"]!);

            var claims = new List<Claim>
        {
            new Claim(ClaimTypes.Name, user.Username),
            new Claim(ClaimTypes.Role, user.Role),
            new Claim("UserId", user.UserId)
        };

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.UtcNow.AddMinutes(int.Parse(_config["Jwt:AccessTokenExpirationMinutes"]!)),
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);

            return tokenHandler.WriteToken(token);
        }


        private async Task<string> GenerateAndStoreRefreshTokenAsync(User user)
        {
            var token = Guid.NewGuid().ToString();
            var expiry = DateTime.UtcNow.AddDays(int.Parse(_config["Jwt:RefreshTokenExpirationDays"]!));

            var existing = await _context.RefreshTokens.FirstOrDefaultAsync(r => r.UserId == user.UserId);
            if (existing != null)
            {
                _context.RefreshTokens.Remove(existing);
            }

            _context.RefreshTokens.Add(new RefreshToken
            {
                Token = token,
                ExpiryDate = expiry,
                UserId = user.UserId
            });

            await _context.SaveChangesAsync();
            return token;
        }

        public async Task<TokenDto?> RefreshTokenAsync(TokenDto dto)
        {
            var existing = await _context.RefreshTokens
                .Include(r => r.User)
                .FirstOrDefaultAsync(r => r.Token == dto.RefreshToken);

            if (existing == null || existing.ExpiryDate < DateTime.UtcNow || existing.User == null)
            {
                _logger.LogWarning("Refresh token không hợp lệ hoặc đã hết hạn");
                return null;
            }

            // Cấp token mới
            return await GenerateTokensAsync(existing.User);
        }
        // Xoá refresh token khi người dùng đăng xuất
        public async Task RevokeRefreshTokenAsync(string userId)
        {
            var tokens = _context.RefreshTokens.Where(t => t.UserId == userId);
            _context.RefreshTokens.RemoveRange(tokens);
            await _context.SaveChangesAsync();
        }

        
    }
}
