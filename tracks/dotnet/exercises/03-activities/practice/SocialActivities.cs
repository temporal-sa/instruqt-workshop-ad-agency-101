using System.Text.Json.Nodes;
using Temporalio.Activities;

namespace Workshop;

public class SocialActivities
{
    private static readonly HttpClient Http = new()
    {
        BaseAddress = new Uri("http://localhost:9999"),
        Timeout = TimeSpan.FromSeconds(5),
    };

    private static async Task<JsonObject> GetJsonAsync(string path)
    {
        var response = await Http.GetAsync(path);
        var text = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode)
        {
            throw new HttpRequestException($"{(int)response.StatusCode} {response.ReasonPhrase}: {text}");
        }
        return JsonNode.Parse(text)!.AsObject();
    }

    // The worked example: an Activity is an ordinary method marked [Activity].
    // Activities contain fallible, non-deterministic work such as network I/O.
    [Activity]
    public async Task<string> GenerateTaglineAsync(string brand)
    {
        var body = await GetJsonAsync($"/tagline?brand={Uri.EscapeDataString(brand)}");
        return (string)body["tagline"]!;
    }

    // TODO: Part B — add an [Activity] method FetchHashtagsAsync.
    // It takes a channel name and returns Task<List<string>>.
    // AdNet endpoint: GET http://localhost:9999/trending/<channel>
}
