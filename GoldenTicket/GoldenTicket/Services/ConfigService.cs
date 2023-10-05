using Microsoft.Extensions.Options;
using GoldenTicket.Models;

namespace GoldenTicket.Services;

public class ConfigService
{
    public OpenAISettings OpenAISettings { get; }

    public ConfigService(IOptionsMonitor<AppConfig> config)
    {
        var currentConfig = config.CurrentValue;
        OpenAISettings = currentConfig.OpenAISettings;
    }

}
