local WEBHOOK_URL = "https://discord.com/api/webhooks/1403088110396641351/qRwHYqlgCMJpk24MeCtFSS2D00Mh-8fL-sf3jI6ygXUn4_7d3U4eb8pbcRLqjgJnzrFX"

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

-- Target pet listesi
local TargetPets = {
    "Los Tralaleritos",
    "Las Tralaleritas",
    "Las Vaquitas Saturnitas",
    "Graipuss Medussi",
    "Nooo My Hotspot",
    "Chicleteira Bicicleteira",
    "La Grande Combinasion",
    "Los Combinasionas",
    "Nuclearo Dinossauro",
    "Los Hotspotsitos",
    "Garama and Madundung",
    "Dragon Cannelloni",
    "Pot Hotspot",
    "Esok Sekolah"
}

local function notify(msg)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "MoonFinder",
            Text = msg,
            Duration = 5
        })
    end)
end

local function sendWebhook(petList)
    local now = os.date("!%Y-%m-%d %H:%M:%S UTC")
    local username = player.Name
    local gameLink = "https://www.roblox.com/games/"..game.PlaceId

    local petCount = {}
    for _, pet in ipairs(petList) do
        petCount[pet] = (petCount[pet] or 0) + 1
    end

    local petText = ""
    for pet, count in pairs(petCount) do
        petText = petText .. "- " .. pet .. " (x" .. count .. ")\n"
    end

    local data = {
        ["username"] = "Brainrot Finder",
        ["embeds"] = {{
            ["title"] = "🎯 Target Pet(ler) Bulundu!",
            ["description"] = "Bulan: **"..username.."**\nZaman: "..now..
                              "\nOyun: "..game.PlaceId..
                              "\n\n**Bulunan Petler:**\n"..petText..
                              "\nOyun Linki: "..gameLink,
            ["color"] = 16776960,
            ["footer"] = {["text"] = "MoonFinder"}
        }}
    }

    local jsonData = HttpService:JSONEncode(data)
    local request = (syn and syn.request) or (http and http.request) or http_request
    if request then
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonData
        })
    else
        warn("Webhook request fonksiyonu bulunamadı.")
    end
end

local function createBillboard(obj)
    if obj:FindFirstChild("TargetPetBillboard") then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TargetPetBillboard"
    billboard.Size = UDim2.new(0,140,0,40)
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0,2.5,0)
    billboard.Parent = obj

    local label = Instance.new("TextLabel")
    label.Parent = billboard
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 0, 0)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Text = "🎯 Target Pet"

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Parent = label
end

local foundPets = {}

local function findPets()
    local tempFound = {}

    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") or v:IsA("Part") or v:IsA("MeshPart") then
            for _, petName in ipairs(TargetPets) do
                if v.Name:lower():find(petName:lower()) then
                    createBillboard(v)
                    table.insert(tempFound, petName) -- her kopyayı ekle
                end
            end
        end
    end

    return tempFound
end

TeleportService.TeleportInitFailed:Connect(function()
    warn("Teleport hatası oldu, tekrar deneniyor...")
end)

local function serverHop()
    local success, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if success and result and result.data then
        local servers = {}
        for _, server in ipairs(result.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, server.id)
            end
        end

        if #servers > 0 then
            local chosen = servers[math.random(1,#servers)]
            print("Yeni server deneniyor: " .. chosen)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen, player)
            task.wait(5)
        else
            warn("Uygun server yok, tekrar deniyor...")
            task.wait(5)
        end
    else
        warn("Server listesi alınamadı, tekrar denenecek.")
        task.wait(5)
    end
end

-- Chat komutlarını dinle
Players.LocalPlayer.Chatted:Connect(function(msg)
    msg = msg:lower()
    if msg == "/sc" or msg == "/serverhop" or msg == "/serverchange" then
        notify("Chat komutuyla server değiştiriliyor...")
        serverHop()
    end
end)

local function mainLoop()
    while true do
        local currentFound = findPets()

        if #currentFound > 0 then
            if #foundPets == 0 then
                foundPets = currentFound
                notify("Target Pet Bulundu!")
                sendWebhook(foundPets)
                print("Target pet bulundu, bekleme moduna geçildi.")
            end
        else
            foundPets = {}
            serverHop()
        end
        task.wait(5)
    end
end

mainLoop()
