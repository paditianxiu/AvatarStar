using Luaon.Json;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using System.Text;
using System.Text.Json;

namespace AvatarStar.Server.Game;

public static class LuaSerializer
{
    private static readonly Newtonsoft.Json.JsonSerializer serializer = Newtonsoft.Json.JsonSerializer.CreateDefault(new JsonSerializerSettings
    {
        Converters = [new JsonElementLuaConverter()],
        ContractResolver = new CamelCasePropertyNamesContractResolver(),
        NullValueHandling = NullValueHandling.Ignore
    });

    public static string Serialize(object obj)
    {
        using var sw = new StringWriter();
        using (var jlw = new JsonLuaWriter(sw))
        {
            jlw.CloseOutput = false;
            // Keep payload compact to reduce packet size and client-side parse pressure.
            jlw.Formatting = Formatting.None;

            serializer.Serialize(jlw, NormalizeJsonElement(obj));
        }

        return sw.ToString();
    }

    public static object? NormalizeJsonElement(object? value)
    {
        return value is JsonElement element ? ConvertJsonElement(element) : value;
    }

    private static object? ConvertJsonElement(JsonElement element)
    {
        return element.ValueKind switch
        {
            JsonValueKind.Object => element.EnumerateObject()
                .ToDictionary(property => property.Name, property => ConvertJsonElement(property.Value), StringComparer.OrdinalIgnoreCase),
            JsonValueKind.Array => element.EnumerateArray().Select(ConvertJsonElement).ToArray(),
            JsonValueKind.String => element.GetString(),
            JsonValueKind.Number when element.TryGetInt64(out var longValue) => longValue,
            JsonValueKind.Number when element.TryGetDouble(out var doubleValue) => doubleValue,
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            _ => null
        };
    }

    private sealed class JsonElementLuaConverter : JsonConverter
    {
        public override bool CanConvert(Type objectType)
        {
            return objectType == typeof(JsonElement);
        }

        public override void WriteJson(JsonWriter writer, object? value, Newtonsoft.Json.JsonSerializer serializer)
        {
            if (value is JsonElement element)
            {
                serializer.Serialize(writer, ConvertJsonElement(element));
                return;
            }

            writer.WriteNull();
        }

        public override object? ReadJson(
            JsonReader reader,
            Type objectType,
            object? existingValue,
            Newtonsoft.Json.JsonSerializer serializer)
        {
            throw new NotSupportedException();
        }
    }

    /// <summary>
    /// Serializes a sequence into a Lua table with contiguous numeric indices (1..n),
    /// so client code using <c>ipairs</c> always iterates all elements.
    /// </summary>
    public static string SerializeSequential(IEnumerable<object?> values)
    {
        var sb = new StringBuilder();
        sb.Append('{');

        var i = 0;
        foreach (var v in values)
        {
            if (i > 0)
            {
                sb.Append(',');
            }
            sb.Append(Serialize(v ?? string.Empty));
            i++;
        }
        sb.Append('}');
        return sb.ToString();
    }
}
