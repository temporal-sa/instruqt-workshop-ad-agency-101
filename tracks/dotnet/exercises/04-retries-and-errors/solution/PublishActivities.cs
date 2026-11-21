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

        var status = (int)response.StatusCode;
        if (status >= 400 && status < 500)
        {
            var error = (string?)JsonNode.Parse(text)?["error"] ?? response.ReasonPhrase;
            throw new ApplicationFailureException(
                $"{channel} rejected the post: {error}",
                errorType: "ChannelPolicyError",
                nonRetryable: true);
        }
        if (!response.IsSuccessStatusCode)
        {
            throw new HttpRequestException($"{(int)response.StatusCode} {response.ReasonPhrase}: {text}");
        }
        return (string)JsonNode.Parse(text)!["placement_id"]!;
    }
}
