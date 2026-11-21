using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Temporalio.Activities;
using Temporalio.Exceptions;

namespace Workshop;

public class CampaignActivities
{
    private static readonly HttpClient Http = new()
    {
        BaseAddress = new Uri("http://localhost:9999"),
        Timeout = TimeSpan.FromSeconds(5),
    };

    private static async Task<(HttpStatusCode Status, JsonObject Body)> PostJsonAsync(
        string path, object body)
    {
        var response = await Http.PostAsJsonAsync(path, body);
        var parsed = JsonNode.Parse(await response.Content.ReadAsStringAsync())!.AsObject();
        return (response.StatusCode, parsed);
    }

    private static bool IsSuccess(HttpStatusCode status) => (int)status is >= 200 and < 300;

    [Activity]
    public async Task<string> ValidateCreativeAsync(string campaign)
    {
        var (status, body) = await PostJsonAsync("/validate-creative", new { campaign });
        if (!IsSuccess(status)) throw new HttpRequestException($"{(int)status}: {body.ToJsonString()}");
        return (string)body["creative_id"]!;
    }

    [Activity]
    public async Task<string> ReserveBudgetAsync(string campaign)
    {
        var (status, body) = await PostJsonAsync("/reserve-budget", new { campaign });
        if (!IsSuccess(status)) throw new HttpRequestException($"{(int)status}: {body.ToJsonString()}");
        return (string)body["reservation_id"]!;
    }

    [Activity]
    public async Task<string> PublishToChannelAsync(string campaign, string channel)
    {
        var attempt = ActivityExecutionContext.Current.Info.Attempt;
        Console.WriteLine($"Publishing to {channel} (attempt {attempt})");
        var (status, body) = await PostJsonAsync($"/publish/{channel}", new { campaign });
        if ((int)status >= 400 && (int)status < 500)
        {
            throw new ApplicationFailureException(
                $"{channel} rejected the campaign: {(string?)body["error"] ?? status.ToString()}",
                errorType: "ChannelPolicyError",
                nonRetryable: true);
        }
        if (!IsSuccess(status)) throw new HttpRequestException($"{(int)status}: {body.ToJsonString()}");
        return (string)body["placement_id"]!;
    }

    [Activity]
    public Task<LaunchReport> GenerateLaunchReportAsync(
        string campaign, string creativeId, string reservationId, List<string> placements)
    {
        return Task.FromResult(new LaunchReport(
            campaign, "LIVE", creativeId, reservationId, placements, placements.Count));
    }
}
