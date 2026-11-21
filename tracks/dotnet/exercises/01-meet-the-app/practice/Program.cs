// Launch the CatNip Cola "Summer Splash" campaign. What could go wrong?
//
// Run it:
//   dotnet run --project exercises/01-meet-the-app/practice/CampaignApp.csproj

using System.Net.Http.Json;
using System.Text.Json.Nodes;

string[] channels = ["meowta", "catstagram", "pettok"];
using var http = new HttpClient
{
    BaseAddress = new Uri("http://localhost:9999"),
    Timeout = TimeSpan.FromSeconds(5),
};

async Task<JsonObject> PostAsync(string path, object body)
{
    var response = await http.PostAsJsonAsync(path, body);
    var text = await response.Content.ReadAsStringAsync();
    if (!response.IsSuccessStatusCode)
    {
        throw new HttpRequestException($"{(int)response.StatusCode} {response.ReasonPhrase}: {text}");
    }
    return JsonNode.Parse(text)!.AsObject();
}

async Task<string> ValidateCreativeAsync(string campaign)
{
    var body = await PostAsync("/validate-creative", new { campaign });
    var creativeId = (string)body["creative_id"]!;
    Console.WriteLine($"  ✅ Creative approved: {creativeId}");
    return creativeId;
}

async Task<string> ReserveBudgetAsync(string campaign)
{
    var body = await PostAsync("/reserve-budget", new { campaign });
    var reservationId = (string)body["reservation_id"]!;
    Console.WriteLine($"  💸 Budget reserved: ${(int)body["amount"]!:N0} ({reservationId})");
    return reservationId;
}

async Task<string> PublishToChannelAsync(string campaign, string channel)
{
    var body = await PostAsync($"/publish/{channel}", new { campaign });
    var placementId = (string)body["placement_id"]!;
    Console.WriteLine($"  📣 Live on {channel}: {placementId}");
    return placementId;
}

object GenerateLaunchReport(
    string campaign, string creativeId, string reservationId, List<string> placements)
{
    var report = new
    {
        campaign,
        status = "LIVE",
        creative_id = creativeId,
        reservation_id = reservationId,
        placements,
        channels_live = placements.Count,
    };
    Console.WriteLine($"  📊 Launch report: {report}");
    return report;
}

async Task<object> LaunchCampaignAsync(string campaign)
{
    Console.WriteLine($"🚀 Launching campaign '{campaign}' for CatNip Cola...");
    var creativeId = await ValidateCreativeAsync(campaign);
    await Task.Delay(TimeSpan.FromSeconds(1));
    var reservationId = await ReserveBudgetAsync(campaign);
    await Task.Delay(TimeSpan.FromSeconds(1));

    // This list lives only in process memory.
    var placements = new List<string>();
    foreach (var channel in channels)
    {
        placements.Add(await PublishToChannelAsync(campaign, channel));
        await Task.Delay(TimeSpan.FromSeconds(1));
    }

    return GenerateLaunchReport(campaign, creativeId, reservationId, placements);
}

await LaunchCampaignAsync("summer-splash");
