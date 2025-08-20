using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/email")]
public class EmailController : ControllerBase
{
    private readonly RedisEmailService _service;

    public EmailController(RedisEmailService service)
    {
        _service = service;
    }

    [HttpPost("send")]
    public IActionResult SendEmail([FromBody] EmailRequest req)
    {
        _service.SendEmail(req.Email, req.Subject, req.Body);
        return Ok(new { message = "Email queued for delivery" });
    }
}

public class EmailRequest
{
    public string Email { get; set; }
    public string Subject { get; set; }
    public string Body { get; set; }
}
