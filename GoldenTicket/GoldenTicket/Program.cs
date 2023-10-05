using GoldenTicket.Extensions;
using GoldenTicket.Hubs;
using GoldenTicket.Models;
using GoldenTicket.Services;
using GoldenTicket.Utilities;
using Hangfire;
using Microsoft.Extensions.FileProviders;
using OpenAIApp.Services;

var builder = WebApplication.CreateBuilder(args);

// Add json file to the Configuration Cointainer
builder.Configuration
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("Config/appconfig.json", optional: false, reloadOnChange: true)
    .AddJsonFile("Config/prompt.json", optional: false, reloadOnChange: true)
    .AddJsonFile("Config/secret.json", optional: false, reloadOnChange: true)
    .AddJsonFile("Config/config.json", optional: false, reloadOnChange: true)
    .AddEnvironmentVariables();

// Add services to the container.
builder.Services.Configure<AppConfig>(builder.Configuration.GetSection("AppConfig"));

builder.Services.AddApplicationServices(builder.Configuration);

var app = builder.Build();

var serviceProvider = app.Services;
var configService = serviceProvider.GetRequiredService<ConfigService>();
var openAIService = serviceProvider.GetRequiredService<OpenAIService>();
var promptService = serviceProvider.GetRequiredService<PromptService>();
var loggerFactory = serviceProvider.GetRequiredService<ILoggerFactory>();

// Configure the HTTP request pipeline.
await AIUtil.Initialize(configService, openAIService, promptService, loggerFactory.CreateLogger<AIUtil>());

//app.UseHangfireDashboard();


HangfireExtensions.UseHangfire(app);
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var hangfireService = services.GetRequiredService<HangFireService>();

    // ✅ Initialize Recurring Jobs Here
    hangfireService.InitializeRecurringJobs();
}

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "app"))
});


app.Use(async (context, next) =>
{
    PathString path = context.Request.Path;
    if (!path.StartsWithSegments("/api") && !path.StartsWithSegments("/GTHub") && !Path.HasExtension(path))
    {
        context.Request.Path = "/index.html";
    }

    await next();
});

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

// app.UseHttpsRedirection();
//app.UseStaticFiles();

app.UseRouting();

app.UseCors("GoldenTicket");

app.UseAuthorization();

app.MapControllers();
app.MapHub<GTHub>("/GTHub").RequireCors("GoldenTicket");


// app.MapControllerRoute(
//     name: "default",
//     pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
