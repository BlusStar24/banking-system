using System.Net.Http;
using System.Text;
using System.Text.Json;

namespace user_service.Services
{
    public class BonitaService
    {
        private readonly HttpClient _http;

        public BonitaService(IHttpClientFactory factory)
        {
            _http = factory.CreateClient();
        }

        // Gọi quy trình Bonita với sessionId và csrfToken đã có
        public async Task<bool> StartProcessAsync(string sessionId, string csrfToken, Dictionary<string, string> variables)
        {
            const string processId = "8804631134987390237"; // Quy trình mà bạn muốn khởi chạy

            var payload = new
            {
                processDefinitionId = processId,
                variables = variables.Select(kv => new
                {
                    name = kv.Key,
                    value = kv.Value,
                    type = "java.lang.String"
                }).ToArray()
            };

            var request = new HttpRequestMessage(
                HttpMethod.Post,
                $"http://bonita:8080/bonita/API/bpm/process/{processId}/instantiation"
            )
            {
                Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json")
            };

            // Gắn session + csrf token vào headers
            request.Headers.Add("Cookie", sessionId);
            request.Headers.Add("X-Bonita-API-Token", csrfToken);

            // Gửi yêu cầu đến Bonita
            var res = await _http.SendAsync(request);
            Console.WriteLine("Status: " + res.StatusCode);
            return res.IsSuccessStatusCode;
        }
    }
}
