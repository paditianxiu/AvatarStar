using Luaon.Json;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using System.Text;

namespace AvatarStar.Server.Game;

public static class LuaSerializer
{
    private static readonly JsonSerializer serializer = JsonSerializer.CreateDefault(new JsonSerializerSettings
    {
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
            
            serializer.Serialize(jlw, obj);
        }
        
        return sw.ToString();
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
