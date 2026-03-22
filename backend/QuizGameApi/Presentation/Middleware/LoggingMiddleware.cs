namespace QuizGame.Presentation.Middleware;

/// <summary>
/// Logs every HTTP request: method, path, response status, and duration.
/// Added to the pipeline in Program.cs before controllers.
/// </summary>
public class LoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<LoggingMiddleware> _logger;

    public LoggingMiddleware(RequestDelegate next, ILogger<LoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var start = DateTime.UtcNow;
        var method = context.Request.Method;
        var path = context.Request.Path;

        try
        {
            await _next(context);
        }
        finally
        {
            var elapsed = (DateTime.UtcNow - start).TotalMilliseconds;
            var status = context.Response.StatusCode;
            _logger.LogInformation("[{Method}] {Path} → {Status} ({Elapsed:0}ms)",
                method, path, status, elapsed);
        }
    }
}
