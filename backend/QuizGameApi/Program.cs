using Microsoft.EntityFrameworkCore;
using QuizGame.Application.Interfaces;
using QuizGame.Application.Mappings;
using QuizGame.Application.Services;
using QuizGame.Domain.Entities;
using QuizGame.Domain.Interfaces;
using QuizGame.Infrastructure.Data;
using QuizGame.Infrastructure.Repositories;
using QuizGame.Presentation.Hubs;
using QuizGame.Presentation.Middleware;

var builder = WebApplication.CreateBuilder(args);

// ─── Services ────────────────────────────────────────────────────────────────

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "QuizGame API", Version = "v1" });
});

// ── EF Core InMemory (swap to SQL by changing this line + adding migrations)
builder.Services.AddDbContext<QuizGameDbContext>(opt =>
    opt.UseInMemoryDatabase("QuizGameDb"));

// ── AutoMapper
builder.Services.AddAutoMapper(typeof(MappingProfile));

// ── Repositories (generic — one registration covers all entity types)
builder.Services.AddScoped(typeof(IRepository<>), typeof(Repository<>));

// ── Application Services
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IGameRoomService, GameRoomService>();

// ── Game Manager: Singleton because it holds active game loop Tasks
//    IServiceScopeFactory lets it create scoped DbContext instances per round
builder.Services.AddSingleton<IGameManager, GameManager>();

// ── SignalR
builder.Services.AddSignalR(opts =>
{
    opts.EnableDetailedErrors = builder.Environment.IsDevelopment();
    opts.MaximumReceiveMessageSize = 32 * 1024; // 32 KB
});

// ── CORS (allow Flutter app on any origin in dev; tighten for production)
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy
            .SetIsOriginAllowed(_ => true) // Allow all origins in dev
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials(); // Required for SignalR
    });
});

// ── Logging
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.SetMinimumLevel(LogLevel.Information);

// ─── Build ────────────────────────────────────────────────────────────────────

var app = builder.Build();

// ── Seed database on startup
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<QuizGameDbContext>();
    await DataSeeder.SeedAsync(db);
}

// ─── Middleware Pipeline ──────────────────────────────────────────────────────

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "QuizGame API v1"));
}

// Global exception handler (first in pipeline — catches all downstream errors)
app.UseMiddleware<ExceptionHandlingMiddleware>();

// Request logger
app.UseMiddleware<LoggingMiddleware>();

app.UseCors();
app.UseRouting();
app.MapControllers();

// ── SignalR Hub endpoint
app.MapHub<GameHub>("/gamehub");

app.Run();
