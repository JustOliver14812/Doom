-- Webhook Sender with HTTP Fallbacks
-- Works even without HTTP support

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Load RayField UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create Window
local Window = Rayfield:CreateWindow({
   Name = "Webhook Sender",
   LoadingTitle = "Webhook Sender",
   LoadingSubtitle = "with HTTP Fallbacks",
   ConfigurationSaving = {
      Enabled = false,
   },
   Discord = {
      Enabled = false,
   },
   KeySystem = false,
})

-- Store webhook data
local WebhookData = {
    URL = "",
    Content = "",
    Username = "",
    AvatarURL = "",
    EmbedTitle = "",
    EmbedDescription = "",
    EmbedColor = ""
}

-- Main Tab
local MainTab = Window:CreateTab("Webhook", 4483361688)

-- Webhook Configuration Section
local WebhookSection = MainTab:CreateSection("Webhook Configuration")

local WebhookInput = MainTab:CreateInput({
   Name = "Webhook URL",
   PlaceholderText = "https://discord.com/api/webhooks/...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       WebhookData.URL = Text
   end,
})

-- Message Section
local MessageSection = MainTab:CreateSection("Message")

local ContentInput = MainTab:CreateInput({
   Name = "Message Content", 
   PlaceholderText = "Your message here...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       WebhookData.Content = Text
   end,
})

local UsernameInput = MainTab:CreateInput({
   Name = "Username",
   PlaceholderText = "Custom username",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       WebhookData.Username = Text
   end,
})

local AvatarInput = MainTab:CreateInput({
   Name = "Avatar URL",
   PlaceholderText = "https://example.com/avatar.png",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       WebhookData.AvatarURL = Text
   end,
})

-- Embed Section
local EmbedSection = MainTab:CreateSection("Embed Settings")

local TitleInput = MainTab:CreateInput({
   Name = "Embed Title",
   PlaceholderText = "Embed title",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       WebhookData.EmbedTitle = Text
   end,
})

local DescriptionInput = MainTab:CreateInput({
   Name = "Embed Description",
   PlaceholderText = "Embed description",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       WebhookData.EmbedDescription = Text
   end,
})

local ColorInput = MainTab:CreateInput({
   Name = "Embed Color (Hex)",
   PlaceholderText = "FF0000",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       WebhookData.EmbedColor = Text
   end,
})

-- Actions Section
local ActionsSection = MainTab:CreateSection("Actions")

-- Test if HTTP is available
local function testHTTP()
    local methods = {"syn.request", "request", "http.request", "http_request"}
    for _, method in ipairs(methods) do
        if method == "syn.request" and syn and syn.request then
            return true, "syn.request"
        elseif method == "request" and request then
            return true, "request"
        elseif method == "http.request" and http and http.request then
            return true, "http.request"
        elseif method == "http_request" and http_request then
            return true, "http_request"
        end
    end
    return false, "No HTTP methods available"
end

-- Generate cURL command (for manual use)
local function generateCurlCommand(data, url)
    local jsonData = game:GetService("HttpService"):JSONEncode(data)
    local curlCommand = string.format(
        "curl -X POST -H \"Content-Type: application/json\" -d '%s' \"%s\"",
        jsonData:gsub("'", "'\\''"),
        url
    )
    return curlCommand
end

-- Generate PowerShell command
local function generatePowerShellCommand(data, url)
    local jsonData = game:GetService("HttpService"):JSONEncode(data)
    local psCommand = string.format(
        "Invoke-RestMethod -Uri \"%s\" -Method Post -ContentType \"application/json\" -Body '%s'",
        url,
        jsonData:gsub("'", "''")
    )
    return psCommand
end

-- Generate direct JSON for manual sending
local function generateJSONPayload(data)
    return game:GetService("HttpService"):JSONEncode(data)
end

-- Send Webhook Function with fallbacks
local function sendWebhook()
    if not WebhookData.URL or WebhookData.URL == "" then
        Rayfield:Notify({
            Title = "Error",
            Content = "Webhook URL is required!",
            Duration = 3,
            Image = 4483362458,
        })
        return
    end

    -- Prepare data
    local data = {}
    if WebhookData.Content and WebhookData.Content ~= "" then
        data.content = WebhookData.Content
    end
    if WebhookData.Username and WebhookData.Username ~= "" then
        data.username = WebhookData.Username
    end
    if WebhookData.AvatarURL and WebhookData.AvatarURL ~= "" then
        data.avatar_url = WebhookData.AvatarURL
    end

    -- Embed data
    local hasEmbed = (WebhookData.EmbedTitle and WebhookData.EmbedTitle ~= "") or 
                    (WebhookData.EmbedDescription and WebhookData.EmbedDescription ~= "") or
                    (WebhookData.EmbedColor and WebhookData.EmbedColor ~= "")

    if hasEmbed then
        local embed = {}
        if WebhookData.EmbedTitle and WebhookData.EmbedTitle ~= "" then
            embed.title = WebhookData.EmbedTitle
        end
        if WebhookData.EmbedDescription and WebhookData.EmbedDescription ~= "" then
            embed.description = WebhookData.EmbedDescription
        end
        if WebhookData.EmbedColor and WebhookData.EmbedColor ~= "" then
            local color = tonumber(WebhookData.EmbedColor, 16)
            if color then
                embed.color = color
            end
        end
        embed.timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        data.embeds = {embed}
    end

    -- Test HTTP first
    local httpAvailable, httpMethod = testHTTP()
    
    if httpAvailable then
        -- Try to send via available HTTP method
        Rayfield:Notify({
            Title = "Sending...",
            Content = "Using " .. httpMethod,
            Duration = 2,
            Image = 4483362458,
        })

        local success, response = pcall(function()
            if httpMethod == "syn.request" then
                return syn.request({
                    Url = WebhookData.URL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = game:GetService("HttpService"):JSONEncode(data)
                })
            elseif httpMethod == "request" then
                return request({
                    Url = WebhookData.URL,
                    Method = "POST", 
                    Headers = {["Content-Type"] = "application/json"},
                    Body = game:GetService("HttpService"):JSONEncode(data)
                })
            elseif httpMethod == "http.request" then
                return http.request({
                    Url = WebhookData.URL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = game:GetService("HttpService"):JSONEncode(data)
                })
            elseif httpMethod == "http_request" then
                return http_request({
                    Url = WebhookData.URL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = game:GetService("HttpService"):JSONEncode(data)
                })
            end
        end)

        if success and response then
            if response.StatusCode == 200 or response.StatusCode == 204 then
                Rayfield:Notify({
                    Title = "Success!",
                    Content = "Webhook sent via " .. httpMethod,
                    Duration = 5,
                    Image = 4483362458,
                })
                return
            else
                Rayfield:Notify({
                    Title = "HTTP Error " .. tostring(response.StatusCode),
                    Content = "Webhook URL might be invalid",
                    Duration = 5,
                    Image = 4483362458,
                })
            end
        end
    end

    -- If HTTP failed or not available, provide manual methods
    local curlCmd = generateCurlCommand(data, WebhookData.URL)
    local psCmd = generatePowerShellCommand(data, WebhookData.URL)
    local jsonPayload = generateJSONPayload(data)
    
    -- Copy JSON to clipboard for manual sending
    if setclipboard then
        setclipboard(jsonPayload)
    end
    
    -- Show manual options
    Rayfield:Notify({
        Title = "HTTP Not Available",
        Content = "JSON copied to clipboard. Use manual methods below.",
        Duration = 8,
        Image = 4483362458,
    })

    -- Create a dialog with manual options
    local ManualTab = Window:CreateTab("Manual Send", 4483362458)
    
    ManualTab:CreateSection("Manual Webhook Sending")
    
    ManualTab:CreateParagraph({
        Title = "Your executor doesn't support direct HTTP requests",
        Content = "Use one of these methods to send your webhook manually:"
    })
    
    -- JSON Payload
    ManualTab:CreateInput({
        Name = "JSON Payload (copied to clipboard)",
        PlaceholderText = "Copy this JSON",
        RemoveTextAfterFocusLost = false,
        Callback = function() end,
    })
    
    -- Set the JSON value (this is a workaround)
    spawn(function()
        wait(1)
        -- This would need to be set in the actual input field
        print("📋 JSON Payload for manual sending:")
        print(jsonPayload)
    end)
    
    ManualTab:CreateButton({
        Name = "Copy cURL Command",
        Callback = function()
            if setclipboard then
                setclipboard(curlCmd)
                Rayfield:Notify({
                    Title = "Copied!",
                    Content = "cURL command copied to clipboard",
                    Duration = 3,
                    Image = 4483362458,
                })
            end
            print("🖥️ cURL Command:")
            print(curlCmd)
        end,
    })
    
    ManualTab:CreateButton({
        Name = "Copy PowerShell Command", 
        Callback = function()
            if setclipboard then
                setclipboard(psCmd)
                Rayfield:Notify({
                    Title = "Copied!",
                    Content = "PowerShell command copied to clipboard",
                    Duration = 3,
                    Image = 4483362458,
                })
            end
            print("💻 PowerShell Command:")
            print(psCmd)
        end,
    })
    
    ManualTab:CreateSection("Online Tools")
    
    ManualTab:CreateParagraph({
        Title = "Web-Based Solutions",
        Content = "Use these websites to send your webhook:"
    })
    
    ManualTab:CreateButton({
        Name = "Open Webhook Tester",
        Callback = function()
            if setclipboard then
                setclipboard(jsonPayload)
            end
            Rayfield:Notify({
                Title = "JSON Copied",
                Content = "Paste at: discord.com/webhook-tester",
                Duration = 5,
                Image = 4483362458,
            })
            print("🌐 Visit: https://discohook.org/")
            print("🌐 Visit: https://webhook.site/")
        end,
    })
end

-- Test Data Function
local function loadTestData()
    WebhookData.Content = "Test webhook from RayField!"
    WebhookData.Username = "RayField Bot" 
    WebhookData.AvatarURL = ""
    WebhookData.EmbedTitle = "Test Embed"
    WebhookData.EmbedDescription = "This is a test embed"
    WebhookData.EmbedColor = "00FF00"
    
    Rayfield:Notify({
        Title = "Test Data Loaded",
        Content = "Remember to add your webhook URL!",
        Duration = 4,
        Image = 4483362458,
    })
end

-- Clear Data Function
local function clearData()
    WebhookData.URL = ""
    WebhookData.Content = ""
    WebhookData.Username = ""
    WebhookData.AvatarURL = ""
    WebhookData.EmbedTitle = ""
    WebhookData.EmbedDescription = ""
    WebhookData.EmbedColor = ""
    
    Rayfield:Notify({
        Title = "Cleared",
        Content = "All fields cleared",
        Duration = 3,
        Image = 4483362458,
    })
end

-- Create Buttons
MainTab:CreateButton({
   Name = "Send Webhook",
   Callback = sendWebhook,
})

MainTab:CreateButton({
   Name = "Load Test Data", 
   Callback = loadTestData,
})

MainTab:CreateButton({
   Name = "Clear All",
   Callback = clearData,
})

-- Check HTTP support on startup
local httpAvailable, httpMethod = testHTTP()
if httpAvailable then
    Rayfield:Notify({
        Title = "HTTP Available",
        Content = "Using " .. httpMethod .. " for webhooks",
        Duration = 4,
        Image = 4483362458,
    })
else
    Rayfield:Notify({
        Title = "No HTTP Support",
        Content = "Will use manual methods",
        Duration = 6,
        Image = 4483362458,
    })
end

print("🔍 HTTP Support: " .. (httpAvailable and "YES (" .. httpMethod .. ")" or "NO"))
print("📝 If HTTP fails, check the 'Manual Send' tab for alternatives")