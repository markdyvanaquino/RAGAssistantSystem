using GoldenTicket.Entities;
using GoldenTicket.Utilities;
namespace GoldenTicket.Services;

public class ApiConfig
{
    private readonly ILogger<ApiConfig> _logger;

    public ApiConfig(ILogger<ApiConfig> logger)
    {
        _logger = logger;
    }

    public static List<APIKeyDTO>? OpenAIKeys;
    public static List<APIKeyDTO>? AvailableKeys;
    public static List<APIKeyDTO>? LeastUsedKeys;


    public async Task<APIKeyDTO> GetOpenAIKey(int index = 0)
    {
        OpenAIKeys = await DBUtil.GetAPIKeys();
        
        if (OpenAIKeys == null || OpenAIKeys.Count == 0)
            throw new InvalidOperationException($"[ApiConfig] [ERROR] OpenAIKeys is not initialized or is empty. (index = {index})");

        AvailableKeys = OpenAIKeys.Where(a => a.LastRateLimit < DateTime.UtcNow.AddHours(-24) || a.LastRateLimit == null).ToList();
        LeastUsedKeys = OpenAIKeys.Where(a => a.LastRateLimit < DateTime.UtcNow.AddHours(-24) || a.LastRateLimit == null).OrderBy(a => a.Usage).ToList();
        if (AvailableKeys == null || AvailableKeys.Count == 0)
            throw new InvalidOperationException($"[ApiConfig] [ERROR] All Keys are exhausted for today!");
        return AvailableKeys[index]!;
    }

    public async Task<APIKeyDTO> GetLeastUsedAPI(int lastID = 0,int index = 0)
    {
        OpenAIKeys = await DBUtil.GetAPIKeys();
        if( OpenAIKeys == null || OpenAIKeys.Count == 0)
        {
            if (OpenAIKeys == null || OpenAIKeys.Count == 0)
            _logger.LogWarning("[ApiConfig] [ERROR] OpenAIKeys is not initialized or is empty.");
            return null!;
        }
        AvailableKeys = OpenAIKeys.Where(a => a.LastRateLimit < DateTime.UtcNow.AddHours(-24) || a.LastRateLimit == null).ToList();
        LeastUsedKeys = OpenAIKeys.Where(a => a.LastRateLimit < DateTime.UtcNow.AddHours(-24) || a.LastRateLimit == null).OrderBy(a => a.Usage).ToList();

        APIKeyDTO? leastUsedKeyEntity;

        leastUsedKeyEntity = LeastUsedKeys.ElementAtOrDefault(index)!;
        if (leastUsedKeyEntity != null && leastUsedKeyEntity?.APIKeyID == lastID && index != 0)
        {
            leastUsedKeyEntity = LeastUsedKeys.ElementAtOrDefault(index - 1)!;
        }

        if (leastUsedKeyEntity == null || !leastUsedKeyEntity.APIKeyID.HasValue)
            _logger.LogWarning("[ApiConfig] [ERROR] Unable to determine the least used API key.");
        return leastUsedKeyEntity ?? null!;
    }
}
