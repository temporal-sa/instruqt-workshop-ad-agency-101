using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Temporalio.Activities;
using Temporalio.Exceptions;

namespace Workshop;

public class PublishActivities
{
    private static readonly HttpClient Http = new()
    {
        BaseAddress = new Uri("http://localhost:9999"),
        Timeout = TimeSpan.FromSeconds(5),
    };

    [Activity]
    public async Task<string> PublishPostAsync(string channel)
    {
        var attempt = ActivityExecutionContext.Current.Info.Attempt;
        Console.WriteLine($"Publishing to {channel} (attempt {attempt})");
        var response = await Http.PostAsJsonAsync(
            $"/publish/{channel}", new { campaign = "summer-splash" });
        var text = await response.Content.ReadAsStringAsync();

        // TODO: Part D — 4xx is a permanent business failure. Detect it and:
        //
        // throw new ApplicationFailureException(
        //     "human-readable message",
        //     errorType: "ChannelPolicyError",
        //     nonRetryable: true);

        if (!response.IsSuccessStatusCode)
        {
            throw new HttpRequestException($"{(int)response.StatusCode} {response.ReasonPhrase}: {text}");
        }
        return (string)JsonNode.Parse(text)!["placement_id"]!;
    }
}
