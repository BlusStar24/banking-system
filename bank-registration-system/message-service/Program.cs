using Serilog;
using MessageService;
using Microsoft.Extensions.Configuration;
using System;
using System.Threading.Tasks;

class Program
{
    public static async Task Main(string[] args)
    {
        Console.WriteLine("Starting application...");
        Log.Information("Starting application...");

        var configuration = new ConfigurationBuilder()
            .AddJsonFile("appsettings.json")
            .Build();
        Console.WriteLine("Configuration loaded");
        Log.Information("Configuration loaded");

        Log.Logger = new LoggerConfiguration()
            .ReadFrom.Configuration(configuration)
            .CreateLogger();
        Console.WriteLine("Logger initialized");
        Log.Information("Logger initialized");

        try
        {
            Log.Information("Starting Message Service...");
            Console.WriteLine("Creating MessageConsumer...");
            var consumer = new MessageConsumer();
            Console.WriteLine("Starting MessageConsumer...");
            Log.Information("Starting MessageConsumer...");
            consumer.Start();
            Console.WriteLine("Message service is running...");
            Log.Information("Message service is running...");
            await Task.Delay(-1); // Giữ app chạy mãi
        }
        catch (Exception ex)
        {
            Log.Fatal(ex, "Application terminated unexpectedly: {ErrorMessage}", ex.Message);
            Console.WriteLine($"Error: {ex.Message}");
            throw; // Để container dừng và hiển thị lỗi
        }
        finally
        {
            Log.Information("Closing application...");
            Console.WriteLine("Closing application...");
            Log.CloseAndFlush();
        }
    }
}