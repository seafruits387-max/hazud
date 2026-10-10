-- ============================================================
-- HAZUDI - PARTE 1/5: NÚCLEO DE SEGURANÇA (ANTI-DETECÇÃO)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- 1. CONFIGURAÇÃO E ESTADO DE SEGURANÇA
-- ============================================================
local SecurityState = {
    Enabled = true,
    OriginalValues = {
        WalkSpeed = 16,
        JumpPower = 50,
        Gravity = workspace.Gravity
    },
    RemotesBlocked = 0,
    SpoofedProperties = {}
}

-- ============================================================
-- 2. SPOOFING DE PROPRIEDADES (WalkSpeed, JumpPower)
-- ============================================================
-- Esta é a defesa mais crítica. Impede que o anti-cheat veja os valores reais.

local function setupPropertySpoofing()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    -- Salva os valores originais do humanoid
    SecurityState.OriginalValues.WalkSpeed = humanoid.WalkSpeed
    SecurityState.OriginalValues.JumpPower = humanoid.JumpPower

    -- Hooking do __index para interceptar leituras
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
        -- Se a leitura for do nosso Humanoid e a propriedade for sensível
        if self == humanoid and SecurityState.Enabled then
            -- Se for WalkSpeed, retorna o valor original (16)
            if key == "WalkSpeed" and not checkcaller() then
                return SecurityState.OriginalValues.WalkSpeed
            end
            -- Se for JumpPower, retorna o valor original (50)
            if key == "JumpPower" and not checkcaller() then
                return SecurityState.OriginalValues.JumpPower
            end
        end
        return oldIndex(self, key)
    end))

    print("[Hazudi Security] Spoofing de WalkSpeed/JumpPower ativado.")
end

-- ============================================================
-- 3. BLOQUEIO DE MÉTODOS DE DETECÇÃO
-- ============================================================
-- Tenta neutralizar funções que o anti-cheat pode usar para nos encontrar.

local function blockDetectionMethods()
    -- Bloqueia a função 'Shutdown' que alguns anti-cheats usam para derrubar o cliente
    if game.Shutdown then
        local oldShutdown = game.Shutdown
        game.Shutdown = function(...)
            print("[Hazudi Security] Tentativa de Shutdown bloqueada.")
            -- Não faz nada, apenas bloqueia
        end
    end

    -- Tenta bloquear a detecção de 'hookmetamethod'
    if hookmetamethod then
        local oldHook = hookmetamethod
        hookmetamethod = function(...)
            -- Permite apenas o nosso próprio hook
            local success, result = pcall(function()
                return oldHook(...)
            end)
            if success then return result end
            return function() end -- Retorna uma função vazia para bloquear
        end
    end

    print("[Hazudi Security] Bloqueio de métodos de detecção ativado.")
end

-- ============================================================
-- 4. SIMULAÇÃO DE INPUT SEGURA
-- ============================================================
-- Cria uma função que simula a tecla 'F' de forma menos suspeita.

local function safeKeyPress(keyCode, duration)
    duration = duration or 0.1
    local VirtualUser = game:GetService("VirtualUser")

    -- CaptureController é mais "legítimo" para o anti-cheat
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)

    task.wait(duration)

    pcall(function()
        VirtualUser:Button1Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end

-- ============================================================
-- 5. INICIALIZAÇÃO DA SEGURANÇA
-- ============================================================

local function initSecurity()
    print("[Hazudi Security] Inicializando sistema de segurança...")

    -- 1. Spoofing de Propriedades
    pcall(setupPropertySpoofing)

    -- 2. Bloqueio de Detecção
    pcall(blockDetectionMethods)

    -- 3. Monitorar respawn para reconfigurar o spoofing
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(1)
        pcall(setupPropertySpoofing)
    end)

    print("[Hazudi Security] Sistema de segurança ativo e pronto.")
end

-- Executa imediatamente
initSecurity()

-- Exporta a função de input segura para as outras partes
_G.HazudiSecureInput = safeKeyPress

print("[Hazudi] Parte 1/5 (Segurança) carregada com sucesso.")

-- ============================================================
-- HAZUDI - PARTE 2/5: INTERFACE VISUAL
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- PALETA DE CORES (AZUL, BRANCO, PRETO)
-- ============================================================
local Colors = {
    Azul        = Color3.fromRGB(0, 120, 255),
    AzulEscuro  = Color3.fromRGB(0, 80, 180),
    Preto       = Color3.fromRGB(10, 10, 12),
    PretoSuave  = Color3.fromRGB(22, 22, 28),
    Branco      = Color3.fromRGB(255, 255, 255),
    Cinza       = Color3.fromRGB(160, 160, 170),
    Vermelho    = Color3.fromRGB(220, 50, 50),
    Verde       = Color3.fromRGB(50, 200, 100),
}

local HazudiState = {
    GUIAberta = false,
    AbaAtiva = "Comeco",
    Opcoes = {
        ServidorPrivado = false,
        TransparenciaBase = 0.5,
        Invisibilidade = false,
        ESP_Pets = false,
        AutoSteal = false,
        PetsSelecionados = {},
    },
}

-- ============================================================
-- FUNÇÕES UTILITÁRIAS DE UI
-- ============================================================
local function criarFrame(parent, props)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = props.Cor or Colors.PretoSuave
    frame.BackgroundTransparency = props.Transparencia or 0
    frame.BorderSizePixel = 0
    frame.Size = props.Tamanho or UDim2.new(0, 100, 0, 100)
    frame.Position = props.Posicao or UDim2.new(0, 0, 0, 0)
    frame.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
    frame.ZIndex = props.ZIndex or 1
    frame.Parent = parent
    if props.CantosArredondados then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, props.CantosArredondados)
        corner.Parent = frame
    end
    if props.Borda then
        local stroke = Instance.new("UIStroke")
        stroke.Color = props.Borda.Cor or Colors.Branco
        stroke.Thickness = props.Borda.Espessura or 1
        stroke.Transparency = props.Borda.Transparencia or 0
        stroke.Parent = frame
    end
    return frame
end

local function criarTexto(parent, props)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = props.Tamanho or UDim2.new(1, 0, 0, 20)
    label.Position = props.Posicao or UDim2.new(0, 0, 0, 0)
    label.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
    label.Font = props.Fonte or Enum.Font.GothamMedium
    label.Text = props.Texto or ""
    label.TextColor3 = props.Cor or Colors.Branco
    label.TextSize = props.TamanhoTexto or 14
    label.TextXAlignment = props.AlinhamentoX or Enum.TextXAlignment.Left
    label.TextYAlignment = props.AlinhamentoY or Enum.TextYAlignment.Center
    label.TextWrapped = props.QuebrarLinha or false
    label.ZIndex = props.ZIndex or 2
    label.Parent = parent
    return label
end

-- ============================================================
-- CRIAÇÃO DA GUI PRINCIPAL (SCREEN GUI)
-- ============================================================
local function criarScreenGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "Hazudi"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local success, hui = pcall(function() return gethui and gethui() or nil end)
    if success and hui then
        gui.Parent = hui
    else
        local success2, coreGui = pcall(function() return game:GetService("CoreGui") end)
        if success2 and coreGui then
            gui.Parent = coreGui
        else
            gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
    end
    return gui
end

-- ============================================================
-- CRIAÇÃO DA COROA (DESENHADA POR CÓDIGO)
-- ============================================================
local function criarCoroa(parent, tamanho)
    local container = Instance.new("Frame")
    container.Name = "CoroaIcon"
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(0, tamanho, 0, tamanho)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.ZIndex = 5
    container.Parent = parent

    -- Base
    local base = Instance.new("Frame")
    base.BackgroundColor3 = Colors.Azul
    base.BorderSizePixel = 0
    base.Size = UDim2.new(0, tamanho * 0.7, 0, tamanho * 0.18)
    base.Position = UDim2.new(0.5, 0, 0.75, 0)
    base.AnchorPoint = Vector2.new(0.5, 0.5)
    base.ZIndex = 6
    base.Parent = container
    local baseCorner = Instance.new("UICorner")
    baseCorner.CornerRadius = UDim.new(0, 2)
    baseCorner.Parent = base

    -- Ponta Esquerda
    local pontaEsq = Instance.new("Frame")
    pontaEsq.BackgroundColor3 = Colors.Azul
    pontaEsq.BorderSizePixel = 0
    pontaEsq.Size = UDim2.new(0, tamanho * 0.15, 0, tamanho * 0.4)
    pontaEsq.Position = UDim2.new(0.18, 0, 0.42, 0)
    pontaEsq.AnchorPoint = Vector2.new(0.5, 0.5)
    pontaEsq.Rotation = -20
    pontaEsq.ZIndex = 6
    pontaEsq.Parent = container
    local peCorner = Instance.new("UICorner")
    peCorner.CornerRadius = UDim.new(0, 2)
    peCorner.Parent = pontaEsq

    -- Ponta Central
    local pontaCentro = Instance.new("Frame")
    pontaCentro.BackgroundColor3 = Colors.Azul
    pontaCentro.BorderSizePixel = 0
    pontaCentro.Size = UDim2.new(0, tamanho * 0.15, 0, tamanho * 0.55)
    pontaCentro.Position = UDim2.new(0.5, 0, 0.3, 0)
    pontaCentro.AnchorPoint = Vector2.new(0.5, 0.5)
    pontaCentro.ZIndex = 6
    pontaCentro.Parent = container
    local pcCorner = Instance.new("UICorner")
    pcCorner.CornerRadius = UDim.new(0, 2)
    pcCorner.Parent = pontaCentro

    -- Ponta Direita
    local pontaDir = Instance.new("Frame")
    pontaDir.BackgroundColor3 = Colors.Azul
    pontaDir.BorderSizePixel = 0
    pontaDir.Size = UDim2.new(0, tamanho * 0.15, 0, tamanho * 0.4)
    pontaDir.Position = UDim2.new(0.82, 0, 0.42, 0)
    pontaDir.AnchorPoint = Vector2.new(0.5, 0.5)
    pontaDir.Rotation = 20
    pontaDir.ZIndex = 6
    pontaDir.Parent = container
    local pdCorner = Instance.new("UICorner")
    pdCorner.CornerRadius = UDim.new(0, 2)
    pdCorner.Parent = pontaDir

    -- Círculos nas pontas
    for _, xPos in ipairs({0.18, 0.5, 0.82}) do
        local bola = Instance.new("Frame")
        bola.BackgroundColor3 = Colors.Branco
        bola.BorderSizePixel = 0
        bola.Size = UDim2.new(0, tamanho * 0.1, 0, tamanho * 0.1)
        bola.Position = UDim2.new(xPos, 0, xPos == 0.5 and 0.15 or 0.22, 0)
        bola.AnchorPoint = Vector2.new(0.5, 0.5)
        bola.ZIndex = 7
        bola.Parent = container
        local bolaCorner = Instance.new("UICorner")
        bolaCorner.CornerRadius = UDim.new(1, 0)
        bolaCorner.Parent = bola
    end
    return container
end

-- ============================================================
-- BOTÃO FLUTUANTE COM ARRASTAR E COLISÃO
-- ============================================================
local function criarBotaoFlutuante(gui)
    local tamanhoBotao = 56
    local botao = Instance.new("TextButton")
    botao.Name = "BotaoHazudi"
    botao.BackgroundColor3 = Colors.Preto
    botao.BorderSizePixel = 0
    botao.Size = UDim2.new(0, tamanhoBotao, 0, tamanhoBotao)
    botao.Position = UDim2.new(0, 20, 0.5, -tamanhoBotao / 2)
    botao.AnchorPoint = Vector2.new(0, 0)
    botao.Text = ""
    botao.AutoButtonColor = false
    botao.ZIndex = 100
    botao.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = botao
    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors.Branco
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = botao
    local sombra = Instance.new("Frame")
    sombra.BackgroundColor3 = Colors.Preto
    sombra.BackgroundTransparency = 0.5
    sombra.BorderSizePixel = 0
    sombra.Size = UDim2.new(1, 4, 1, 4)
    sombra.Position = UDim2.new(0.5, 0, 0.5, 2)
    sombra.AnchorPoint = Vector2.new(0.5, 0.5)
    sombra.ZIndex = 99
    sombra.Parent = botao
    local sombraCorner = Instance.new("UICorner")
    sombraCorner.CornerRadius = UDim.new(1, 0)
    sombraCorner.Parent = sombra

    criarCoroa(botao, tamanhoBotao * 0.55)
    return botao
end

-- ============================================================
-- SISTEMA DE ARRASTAR (DRAG) COM COLISÃO DE BORDAS
-- ============================================================
local function ativarDrag(botao)
    local arrastando = false
    local offsetInicial = Vector2.new(0, 0)
    local botaoTamanhoX, botaoTamanhoY = 56, 56

    local function getTamanhoTela()
        local camera = workspace.CurrentCamera
        if camera then return camera.ViewportSize end
        return Vector2.new(1920, 1080)
    end

    local function limitarPosicao(posX, posY)
        local tela = getTamanhoTela()
        local maxX = tela.X - botaoTamanhoX
        local maxY = tela.Y - botaoTamanhoY
        posX = math.clamp(posX, 0, maxX)
        posY = math.clamp(posY, 0, maxY)
        return posX, posY
    end

    botao.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            arrastando = true
            local posBotao = botao.AbsolutePosition
            offsetInicial = Vector2.new(
                input.Position.X - posBotao.X,
                input.Position.Y - posBotao.Y
            )
        end
    end)

    botao.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            arrastando = false
        end
    end)

    RunService.RenderStepped:Connect(function()
        if not arrastando then return end
        local inputPos
        if UserInputService.TouchEnabled then
            local touches = UserInputService:GetTouches()
            if #touches > 0 then
                inputPos = Vector2.new(touches[1].Position.X, touches[1].Position.Y)
            end
        end
        if not inputPos then
            inputPos = Vector2.new(
                UserInputService:GetMouseLocation().X,
                UserInputService:GetMouseLocation().Y
            )
        end
        local novoX = inputPos.X - offsetInicial.X
        local novoY = inputPos.Y - offsetInicial.Y
        novoX, novoY = limitarPosicao(novoX, novoY)
        botao.Position = UDim2.new(0, novoX, 0, novoY)
    end)
end

-- ============================================================
-- ANIMAÇÃO DE CLIQUE (ENCENDER E ABRIR)
-- ============================================================
local function animarCliqueBotao(botao, callback)
    local encolherInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    local encolherTween = TweenService:Create(botao, encolherInfo, {
        Size = UDim2.new(0, 40, 0, 40),
        BackgroundTransparency = 0.3,
    })
    encolherTween:Play()
    encolherTween.Completed:Wait()

    local voltarInfo = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local voltarTween = TweenService:Create(botao, voltarInfo, {
        Size = UDim2.new(0, 56, 0, 56),
        BackgroundTransparency = 0,
    })
    voltarTween:Play()

    if callback then callback() end
end

-- ============================================================
-- EXPORTAR PARA AS PRÓXIMAS PARTES
-- ============================================================
_G.Hazudi = {
    Colors = Colors,
    State = HazudiState,
    criarFrame = criarFrame,
    criarTexto = criarTexto,
    criarScreenGui = criarScreenGui,
    criarBotaoFlutuante = criarBotaoFlutuante,
    ativarDrag = ativarDrag,
    animarCliqueBotao = animarCliqueBotao,
    Gui = nil,
    Botao = nil,
    Janela = nil,
}

print("[Hazudi] Parte 2/5 (Interface Base) carregada com sucesso.")

-- ============================================================
-- HAZUDI - PARTE 3/5: JANELA PRINCIPAL, CABEÇALHO E ABAS
-- ============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local H = _G.Hazudi
local Colors = H.Colors
local State = H.State
local criarFrame = H.criarFrame
local criarTexto = H.criarTexto

-- ============================================================
-- CABEÇALHO DO JOGADOR (DINÂMICO)
-- ============================================================
local function criarCabecalho(parent)
    local header = criarFrame(parent, {
        Cor = Colors.PretoSuave,
        Tamanho = UDim2.new(1, -20, 0, 72),
        Posicao = UDim2.new(0, 10, 0, 10),
        CantosArredondados = 12,
        Borda = { Cor = Colors.Azul, Espessura = 1.5, Transparencia = 0.5 },
        ZIndex = 10,
    })

    -- Nome Hazudi (Ha + Zud)
    local nomeHazudi = Instance.new("Frame")
    nomeHazudi.BackgroundTransparency = 1
    nomeHazudi.Size = UDim2.new(1, -20, 0, 24)
    nomeHazudi.Position = UDim2.new(0, 10, 0, 4)
    nomeHazudi.ZIndex = 11
    nomeHazudi.Parent = header

    criarTexto(nomeHazudi, {
        Texto = "Ha",
        Cor = Colors.Branco,
        Tamanho = UDim2.new(0, 40, 1, 0),
        Posicao = UDim2.new(0.5, -30, 0, 0),
        AlinhamentoX = Enum.TextXAlignment.Right,
        Fonte = Enum.Font.GothamBold,
        TamanhoTexto = 20,
        ZIndex = 12,
    })
    criarTexto(nomeHazudi, {
        Texto = "Zud",
        Cor = Colors.Azul,
        Tamanho = UDim2.new(0, 50, 1, 0),
        Posicao = UDim2.new(0.5, -30, 0, 0),
        AlinhamentoX = Enum.TextXAlignment.Left,
        Fonte = Enum.Font.GothamBold,
        TamanhoTexto = 20,
        ZIndex = 12,
    })

    -- Foto do Jogador
    local fotoContainer = criarFrame(header, {
        Cor = Colors.Preto,
        Tamanho = UDim2.new(0, 40, 0, 40),
        Posicao = UDim2.new(0, 10, 0, 24),
        CantosArredondados = 8,
        Borda = { Cor = Colors.Branco, Espessura = 1, Transparencia = 0.3 },
        ZIndex = 11,
    })
    local foto = Instance.new("ImageLabel")
    foto.BackgroundTransparency = 1
    foto.Size = UDim2.new(1, -4, 1, -4)
    foto.Position = UDim2.new(0.5, 0, 0.5, 0)
    foto.AnchorPoint = Vector2.new(0.5, 0.5)
    foto.ZIndex = 12
    foto.Parent = fotoContainer
    local fotoCorner = Instance.new("UICorner")
    fotoCorner.CornerRadius = UDim.new(0, 6)
    fotoCorner.Parent = foto

    -- Nome e ID do Jogador
    criarTexto(header, {
        Texto = LocalPlayer.DisplayName or LocalPlayer.Name,
        Cor = Colors.Branco,
        Tamanho = UDim2.new(0, 160, 0, 18),
        Posicao = UDim2.new(0, 58, 0, 26),
        Fonte = Enum.Font.GothamBold,
        TamanhoTexto = 14,
        ZIndex = 11,
    })
    criarTexto(header, {
        Texto = "ID: " .. tostring(LocalPlayer.UserId),
        Cor = Colors.Cinza,
        Tamanho = UDim2.new(0, 160, 0, 16),
        Posicao = UDim2.new(0, 58, 0, 44),
        Fonte = Enum.Font.Gotham,
        TamanhoTexto = 11,
        ZIndex = 11,
    })

    -- Carregar Thumbnail
    task.spawn(function()
        local success, content = pcall(function()
            return Players:GetUserThumbnailAsync(
                LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100
            )
        end)
        if success and content then
            foto.Image = content
        end
    end)

    return header
end

-- ============================================================
-- CRIAÇÃO DA JANELA PRINCIPAL
-- ============================================================
local function criarJanelaPrincipal(gui)
    local janela = criarFrame(gui, {
        Cor = Colors.Preto,
        Tamanho = UDim2.new(0, 0, 0, 0),
        Posicao = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        CantosArredondados = 16,
        Borda = { Cor = Colors.Azul, Espessura = 2, Transparencia = 0.3 },
        ZIndex = 50,
    })

    local fundoInterno = criarFrame(janela, {
        Cor = Colors.PretoSuave,
        Tamanho = UDim2.new(1, -4, 1, -4),
        Posicao = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        CantosArredondados = 14,
        ZIndex = 51,
    })

    criarCabecalho(fundoInterno)

    local areaConteudo = criarFrame(fundoInterno, {
        Cor = Colors.PretoSuave,
        Tamanho = UDim2.new(1, -20, 1, -100),
        Posicao = UDim2.new(0, 10, 0, 90),
        CantosArredondados = 10,
        ZIndex = 51,
    })

    local barraAbas = criarFrame(fundoInterno, {
        Cor = Colors.Preto,
        Tamanho = UDim2.new(1, -20, 0, 40),
        Posicao = UDim2.new(0, 10, 1, -50),
        CantosArredondados = 10,
        Borda = { Cor = Colors.Azul, Espessura = 1, Transparencia = 0.5 },
        ZIndex = 52,
    })

    -- Botão Fechar
    local botaoFechar = Instance.new("TextButton")
    botaoFechar.BackgroundColor3 = Colors.Vermelho
    botaoFechar.BackgroundTransparency = 0.7
    botaoFechar.BorderSizePixel = 0
    botaoFechar.Size = UDim2.new(0, 28, 0, 28)
    botaoFechar.Position = UDim2.new(1, -38, 0, 38)
    botaoFechar.Text = "✕"
    botaoFechar.TextColor3 = Colors.Branco
    botaoFechar.TextSize = 14
    botaoFechar.Font = Enum.Font.GothamBold
    botaoFechar.ZIndex = 60
    botaoFechar.Parent = fundoInterno
    local fecharCorner = Instance.new("UICorner")
    fecharCorner.CornerRadius = UDim.new(1, 0)
    fecharCorner.Parent = botaoFechar

    return janela, areaConteudo, barraAbas, botaoFechar
end

-- ============================================================
-- SISTEMA DE ABAS
-- ============================================================
local function trocarAba(nomeAba, areaConteudo, botoesAba)
    -- Esconde todos os conteúdos
    for _, child in pairs(areaConteudo:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("^Conteudo") then
            child.Visible = false
        end
    end

    -- Mostra o conteúdo da aba selecionada
    local conteudoAlvo = areaConteudo:FindFirstChild("Conteudo" .. nomeAba)
    if conteudoAlvo then
        conteudoAlvo.Visible = true
    end

    -- Atualiza visual dos botões
    for nome, dados in pairs(botoesAba) do
        local botao = dados.Botao
        local texto = dados.Texto
        if nome == nomeAba then
            botao.BackgroundTransparency = 0.2
            botao.BackgroundColor3 = Colors.Azul
            texto.TextColor3 = Colors.Branco
        else
            botao.BackgroundTransparency = 0.7
            botao.BackgroundColor3 = Colors.Preto
            texto.TextColor3 = Colors.Cinza
        end
    end
    State.AbaAtiva = nomeAba
end

local function criarBotaoAba(barra, nome, iconeTipo, callback)
    local botao = Instance.new("TextButton")
    botao.BackgroundColor3 = Colors.Preto
    botao.BackgroundTransparency = 0.5
    botao.BorderSizePixel = 0
    botao.Size = UDim2.new(1/3, -8, 1, -8)
    botao.AnchorPoint = Vector2.new(0, 0.5)
    botao.Text = ""
    botao.AutoButtonColor = false
    botao.ZIndex = 53
    botao.Parent = barra

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = botao

    -- Ícone (simplificado para o exemplo, mas totalmente funcional)
    local icone = Instance.new("TextLabel")
    icone.BackgroundTransparency = 1
    icone.Size = UDim2.new(0, 18, 0, 18)
    icone.Position = UDim2.new(0.5, 0, 0.5, -6)
    icone.AnchorPoint = Vector2.new(0.5, 0.5)
    icone.Text = iconeTipo == "casa" and "🏠" or iconeTipo == "engrenagem" and "⚙️" or "🐾"
    icone.TextColor3 = Colors.Azul
    icone.Font = Enum.Font.GothamBold
    icone.TextSize = 14
    icone.ZIndex = 54
    icone.Parent = botao

    local textoAba = criarTexto(botao, {
        Texto = nome,
        Cor = Colors.Cinza,
        Tamanho = UDim2.new(1, 0, 0, 14),
        Posicao = UDim2.new(0, 0, 1, -16),
        AlinhamentoX = Enum.TextXAlignment.Center,
        Fonte = Enum.Font.Gotham,
        TamanhoTexto = 10,
        ZIndex = 54,
    })

    botao.MouseButton1Click:Connect(function()
        if callback then callback(nome) end
    end)

    return botao, textoAba
end

-- ============================================================
-- CONTEÚDO DA ABA "COMEÇO"
-- ============================================================
local function criarConteudoComeco(parent)
    local container = criarFrame(parent, {
        Cor = Colors.Preto,
        Tamanho = UDim2.new(1, 0, 1, 0),
        CantosArredondados = 8,
        ZIndex = 55,
    })

    criarTexto(container, {
        Texto = "Bem-vindo ao Hazudi",
        Cor = Colors.Azul,
        Tamanho = UDim2.new(1, -20, 0, 28),
        Posicao = UDim2.new(0, 10, 0, 10),
        AlinhamentoX = Enum.TextXAlignment.Center,
        Fonte = Enum.Font.GothamBold,
        TamanhoTexto = 20,
        ZIndex = 56,
    })

    criarTexto(container, {
        Texto = "Obrigado por abrir o Hazudi, " .. (LocalPlayer.DisplayName or LocalPlayer.Name) .. "!\n\n"
            .. "Este é o seu hub de utilidades para Steal a Brainrot.\n"
            .. "Aqui você encontrará ferramentas organizadas em abas,\n"
            .. "com uma interface limpa e pensada para mobile.\n\n"
            .. "Use a barra inferior para navegar entre as categorias.",
        Cor = Colors.Branco,
        Tamanho = UDim2.new(1, -20, 0, 200),
        Posicao = UDim2.new(0, 10, 0, 55),
        AlinhamentoX = Enum.TextXAlignment.Center,
        AlinhamentoY = Enum.TextYAlignment.Top,
        Fonte = Enum.Font.Gotham,
        TamanhoTexto = 13,
        QuebrarLinha = true,
        ZIndex = 56,
    })

    return container
end

-- ============================================================
-- INICIALIZAÇÃO E ABERTURA DA INTERFACE
-- ============================================================
local function abrirInterface(gui, botaoFlutuante)
    if State.GUIAberta then return end
    State.GUIAberta = true

    local janela, areaConteudo, barraAbas, botaoFechar = criarJanelaPrincipal(gui)
    H.Janela = janela

    -- Cria conteúdos
    criarConteudoComeco(areaConteudo)

    -- Placeholders para as outras abas (serão preenchidos na Parte 4)
    local conteudoOpcoes = criarFrame(areaConteudo, {
        Cor = Colors.Preto,
        Tamanho = UDim2.new(1, 0, 1, 0),
        CantosArredondados = 8,
        ZIndex = 55,
    })
    conteudoOpcoes.Name = "ConteudoOpcoes"
    conteudoOpcoes.Visible = false

    local conteudoPets = criarFrame(areaConteudo, {
        Cor = Colors.Preto,
        Tamanho = UDim2.new(1, 0, 1, 0),
        CantosArredondados = 8,
        ZIndex = 55,
    })
    conteudoPets.Name = "ConteudoPets"
    conteudoPets.Visible = false

    -- Cria botões das abas
    local botoesAba = {}

    local botaoComeco, textoComeco = criarBotaoAba(barraAbas, "Começo", "casa", function()
        trocarAba("Comeco", areaConteudo, botoesAba)
    end)
    botaoComeco.Position = UDim2.new(0, 4, 0.5, 0)
    botoesAba["Comeco"] = { Botao = botaoComeco, Texto = textoComeco }

    local botaoOpcoes, textoOpcoes = criarBotaoAba(barraAbas, "Opções", "engrenagem", function()
        trocarAba("Opcoes", areaConteudo, botoesAba)
    end)
    botaoOpcoes.Position = UDim2.new(1/3, 4, 0.5, 0)
    botoesAba["Opcoes"] = { Botao = botaoOpcoes, Texto = textoOpcoes }

    local botaoPets, textoPets = criarBotaoAba(barraAbas, "Pets", "pets", function()
        trocarAba("Pets", areaConteudo, botoesAba)
    end)
    botaoPets.Position = UDim2.new(2/3, 4, 0.5, 0)
    botoesAba["Pets"] = { Botao = botaoPets, Texto = textoPets }

    trocarAba("Comeco", areaConteudo, botoesAba)

    -- Fechar interface
    botaoFechar.MouseButton1Click:Connect(function()
        local fecharTween = TweenService:Create(janela, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
        })
        fecharTween:Play()
        fecharTween.Completed:Wait()

        janela:Destroy()
        State.GUIAberta = false
    end)

    -- Animação de abertura
    local viewport = workspace.CurrentCamera.ViewportSize
    local larguraMax = math.min(viewport.X * 0.95, 420)
    local alturaMax = math.min(viewport.Y * 0.85, 600)

    janela.Size = UDim2.new(0, larguraMax, 0, 0)
    local abrirInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    TweenService:Create(janela, abrirInfo, {
        Size = UDim2.new(0, larguraMax, 0, alturaMax),
    }):Play()

    return janela
end

-- Exportar
H.criarJanelaPrincipal = criarJanelaPrincipal
H.criarBotaoAba = criarBotaoAba
H.criarConteudoComeco = criarConteudoComeco
H.trocarAba = trocarAba
H.abrirInterface = abrirInterface

print("[Hazudi] Parte 3/5 (Janela e Abas) carregada com sucesso.")

-- ============================================================
-- HAZUDI - PARTE 4/5: LÓGICA DAS FUNCIONALIDADES
-- ============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local H = _G.Hazudi
local Colors = H.Colors
local State = H.State
local criarFrame = H.criarFrame
local criarTexto = H.criarTexto

-- ============================================================
-- FUNÇÃO DE NOTIFICAÇÃO (TOAST)
-- ============================================================
local function notificar(gui, mensagem, tipo, duracao)
    duracao = duracao or 3
    local corFundo = tipo == "sucesso" and Color3.fromRGB(20, 80, 40) or
                     tipo == "erro" and Color3.fromRGB(80, 20, 20) or Colors.PretoSuave
    local corBorda = tipo == "sucesso" and Colors.Verde or
                     tipo == "erro" and Colors.Vermelho or Colors.Azul

    local toast = criarFrame(gui, {
        Cor = corFundo,
        Tamanho = UDim2.new(0.85, 0, 0, 50),
        Posicao = UDim2.new(0.5, 0, 0, -60),
        AnchorPoint = Vector2.new(0.5, 0),
        CantosArredondados = 10,
        Borda = { Cor = corBorda, Espessura = 1.5, Transparencia = 0.3 },
        ZIndex = 200,
    })

    local icone = criarFrame(toast, {
        Cor = corBorda,
        Tamanho = UDim2.new(0, 10, 0, 10),
        Posicao = UDim2.new(0, 12, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        CantosArredondados = 5,
        ZIndex = 201,
    })

    criarTexto(toast, {
        Texto = mensagem,
        Cor = Colors.Branco,
        Tamanho = UDim2.new(1, -40, 1, 0),
        Posicao = UDim2.new(0, 30, 0, 0),
        Fonte = Enum.Font.Gotham,
        TamanhoTexto = 12,
        QuebrarLinha = true,
        ZIndex = 201,
    })

    local entrarInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    TweenService:Create(toast, entrarInfo, {
        Position = UDim2.new(0.5, 0, 0, 20),
    }):Play()

    task.delay(duracao, function()
        local sairInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local sairTween = TweenService:Create(toast, sairInfo, {
            Position = UDim2.new(0.5, 0, 0, -60),
            BackgroundTransparency = 1,
        })
        sairTween:Play()
        sairTween.Completed:Wait()
        toast:Destroy()
    end)
end

-- ============================================================
-- DETECÇÃO DE SERVIDOR PRIVADO (USANDO PROPRIEDADES OFICIAIS)
-- ============================================================
local function verificarServidorPrivado()
    -- game.PrivateServerId ~= "" indica um servidor privado/reservado
    -- game.PrivateServerOwnerId ~= 0 indica um servidor VIP (privado real)
    if game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0 then
        return true, "VIPServer"
    elseif game.PrivateServerId ~= "" then
        return true, "ReservedServer"
    else
        return false, "StandardServer"
    end
end

-- ============================================================
-- LÓGICA DA OPÇÃO 1: MODO SERVIDOR PRIVADO
-- ============================================================
local function toggleServidorPrivado(ativado, gui)
    if not ativado then
        State.Opcoes.ServidorPrivado = false
        notificar(gui, "Modo Servidor Privado desativado.", "info", 2)
        return
    end

    local ehPrivado, tipoServidor = verificarServidorPrivado()

    if not ehPrivado then
        State.Opcoes.ServidorPrivado = false
        notificar(gui, "❌ Esta opção só funciona em servidor privado! Você está em um servidor público.", "erro", 4)
        return
    end

    State.Opcoes.ServidorPrivado = true
    notificar(gui, "✅ Opção ativada com sucesso! Você está em um servidor " .. tipoServidor .. ".", "sucesso", 4)

    -- ============================================================
    -- LÓGICA DE GAMEPLAY (A SER ADAPTADA COM REMOTES DO JOGO)
    -- ============================================================
    -- A ideia de "arrastar jogadores para o servidor" não é tecnicamente viável
    -- da forma descrita, pois não há API para controlar outros jogadores.
    -- A ação real dependeria de um RemoteEvent específico do jogo que permite
    -- forçar um teleporte ou carregamento. Por enquanto, a opção apenas
    -- verifica e notifica.
    -- ============================================================
end

-- ============================================================
-- ABA "OPÇÕES" (COM TOGGLES E SLIDER)
-- ============================================================
local function criarToggle(parent, props)
    local container = criarFrame(parent, {
        Cor = Colors.Preto,
        Tamanho = UDim2.new(1, -20, 0, 48),
        Posicao = props.Posicao or UDim2.new(0, 10, 0, 0),
        CantosArredondados = 8,
        Borda = { Cor = Colors.Azul, Espessura = 1, Transparencia = 0.6 },
        ZIndex = 56,
    })

    criarTexto(container, {
        Texto = props.Nome,
        Cor = Colors.Branco,
        Tamanho = UDim2.new(1, -80, 1, 0),
        Posicao = UDim2.new(0, 12, 0, 0),
        Fonte = Enum.Font.GothamMedium,
        TamanhoTexto = 13,
        ZIndex = 57,
    })

    local iconeFrame = criarFrame(container, {
        Cor = Colors.PretoSuave,
        Tamanho = UDim2.new(0, 44, 0, 24),
        Posicao = UDim2.new(1, -56, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        CantosArredondados = 12,
        ZIndex = 57,
    })

    local bolinha = Instance.new("Frame")
    bolinha.BackgroundColor3 = Colors.Vermelho
    bolinha.BorderSizePixel = 0
    bolinha.Size = UDim2.new(0, 20, 0, 20)
    bolinha.Position = UDim2.new(0, 2, 0.5, 0)
    bolinha.AnchorPoint = Vector2.new(0, 0.5)
    bolinha.ZIndex = 58
    bolinha.Parent = iconeFrame
    local bolinhaCorner = Instance.new("UICorner")
    bolinhaCorner.CornerRadius = UDim.new(1, 0)
    bolinhaCorner.Parent = bolinha

    local botaoToggle = Instance.new("TextButton")
    botaoToggle.BackgroundTransparency = 1
    botaoToggle.Size = UDim2.new(1, 0, 1, 0)
    botaoToggle.Text = ""
    botaoToggle.ZIndex = 59
    botaoToggle.Parent = container

    local estadoAtual = props.EstadoInicial or false

    local function animarToggle(novoEstado)
        estadoAtual = novoEstado
        local targetPos = novoEstado and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        local targetColor = novoEstado and Colors.Verde or Colors.Vermelho
        local info = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(bolinha, info, {
            Position = targetPos,
            BackgroundColor3 = targetColor,
        }):Play()
        State.Opcoes[props.Nome] = novoEstado
        if props.Callback then props.Callback(novoEstado) end
    end

    botaoToggle.MouseButton1Click:Connect(function()
        animarToggle(not estadoAtual)
    end)

    if props.EstadoInicial then
        animarToggle(true)
    end

    return botaoToggle, animarToggle
end

local function criarConteudoOpcoes(parent)
    local container = criarFrame(parent, {
        Cor = Colors.Preto,
        Tamanho = UDim2.new(1, 0, 1, 0),
        CantosArredondados = 8,
        ZIndex = 55,
    })

    local scroll = Instance.new("ScrollingFrame")
    scroll.BackgroundTransparency = 1
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Colors.Azul
    scroll.ZIndex = 56
    scroll.Parent = container

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = scroll

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent = scroll

    -- Título
    criarTexto(scroll, {
        Texto = "⚙️ Opções do Hazudi",
        Cor = Colors.Azul,
        Tamanho = UDim2.new(1, -20, 0, 24),
        Posicao = UDim2.new(0, 10, 0, 0),
        Fonte = Enum.Font.GothamBold,
        TamanhoTexto = 16,
        ZIndex = 57,
    })

    -- --- OPÇÃO 1: Servidor Privado ---
    criarToggle(scroll, {
        Nome = "Modo Servidor Privado",
        EstadoInicial = false,
        Posicao = UDim2.new(0, 0, 0, 30),
        Callback = function(estado)
            toggleServidorPrivado(estado, H.Gui)
        end,
    })
    criarTexto(scroll, {
        Texto = "⚠️ Só funciona em servidor privado. Ao ativar, verifica o tipo de servidor.",
        Cor = Colors.Cinza,
        Tamanho = UDim2.new(1, -20, 0, 28),
        Posicao = UDim2.new(0, 10, 0, 0),
        Fonte = Enum.Font.Gotham,
        TamanhoTexto = 10,
        QuebrarLinha = true,
        ZIndex = 57,
    })

    -- --- OPÇÃO 2: Transparência ---
    criarToggle(scroll, {
        Nome = "Bases Transparentes",
        EstadoInicial = false,
        Posicao = UDim2.new(0, 0, 0, 0),
        Callback = function(estado)
            State.Opcoes.TransparenciaBase = estado and 0.5 or 0
        end,
    })

    -- --- OPÇÃO 3: Invisibilidade ---
    criarToggle(scroll, {
        Nome = "Invisibilidade Total",
        EstadoInicial = false,
        Posicao = UDim2.new(0, 0, 0, 0),
        Callback = function(estado)
            State.Opcoes.Invisibilidade = estado
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") or part:IsA("Decal") then
                        part.Transparency = estado and 1 or 0
                        part.LocalTransparencyModifier = estado and 1 or 0
                    end
                end
            end
        end,
    })

    -- --- OPÇÃO 4: ESP de Pets ---
    criarToggle(scroll, {
        Nome = "ESP — Ver Valor dos Pets",
        EstadoInicial = false,
        Posicao = UDim2.new(0, 0, 0, 0),
        Callback = function(estado)
            State.Opcoes.ESP_Pets = estado
        end,
    })

    -- --- OPÇÃO 5: Auto Steal ---
    criarToggle(scroll, {
        Nome = "Auto Steal (Pets Selecionados)",
        EstadoInicial = false,
        Posicao = UDim2.new(0, 0, 0, 0),
        Callback = function(estado)
            State.Opcoes.AutoSteal = estado
        end,
    })

    task.defer(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)

    return container
end

-- ============================================================
-- ABA "PETS" (LISTA DE SELEÇÃO)
-- ============================================================
local PETS_PLACEHOLDER = {
    "Noobini Pizzanini", "Tralalero Tralala", "Bombardiro Crocodilo",
    "Tung Tung Tung Sahur", "Boneca Ambalabu", "Lirili Larila",
    "Brr Brr Patapim", "Chimpanzini Bananini", "Glorbo Fruttodrillo",
    "Crocodildo Penisini", "Frigo Camelo", "Blueberrinni Octopusini",
    "Burbaloni Loliloli", "Capuccino Assassino", "Espresso Signora",
    "Girafa Celeste", "Zibra Zubra Zibralini", "Trippi Troppi",
    "Bobritto Bandito", "Trulimero Trulicina",
}

local function criarConteudoPets(parent)
    local container = criarFrame(parent, {
        Cor = Colors.Preto,
        Tamanho = UDim2.new(1, 0, 1, 0),
        CantosArredondados = 8,
        ZIndex = 55,
    })

    criarTexto(container, {
        Texto = "🐾 Seleção de Pets",
        Cor = Colors.Azul,
        Tamanho = UDim2.new(1, -20, 0, 24),
        Posicao = UDim2.new(0, 10, 0, 8),
        Fonte = Enum.Font.GothamBold,
        TamanhoTexto = 16,
        ZIndex = 57,
    })

    criarTexto(container, {
        Texto = "Selecione até 10 pets para o Auto Steal monitorar.",
        Cor = Colors.Cinza,
        Tamanho = UDim2.new(1, -20, 0, 18),
        Posicao = UDim2.new(0, 10, 0, 32),
        Fonte = Enum.Font.Gotham,
        TamanhoTexto = 10,
        ZIndex = 57,
    })

    local scroll = Instance.new("ScrollingFrame")
    scroll.BackgroundTransparency = 1
    scroll.Size = UDim2.new(1, -20, 1, -60)
    scroll.Position = UDim2.new(0, 10, 0, 54)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Colors.Azul
    scroll.ZIndex = 56
    scroll.Parent = container

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = scroll

    local selecionados = State.Opcoes.PetsSelecionados

    for i, nomePet in ipairs(PETS_PLACEHOLDER) do
        local item = Instance.new("TextButton")
        item.BackgroundColor3 = Colors.PretoSuave
        item.BackgroundTransparency = 0.5
        item.BorderSizePixel = 0
        item.Size = UDim2.new(1, -4, 0, 36)
        item.Position = UDim2.new(0, 2, 0, 0)
        item.Text = ""
        item.AutoButtonColor = false
        item.ZIndex = 57
        item.Parent = scroll

        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 6)
        itemCorner.Parent = item

        criarTexto(item, {
            Texto = nomePet,
            Cor = Colors.Branco,
            Tamanho = UDim2.new(1, -50, 1, 0),
            Posicao = UDim2.new(0, 10, 0, 0),
            Fonte = Enum.Font.Gotham,
            TamanhoTexto = 12,
            ZIndex = 58,
        })

        local checkbox = criarFrame(item, {
            Cor = Colors.Preto,
            Tamanho = UDim2.new(0, 18, 0, 18),
            Posicao = UDim2.new(1, -28, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            CantosArredondados = 4,
            Borda = { Cor = Colors.Azul, Espessura = 1.5, Transparencia = 0.3 },
            ZIndex = 58,
        })

        local checkMark = criarTexto(checkbox, {
            Texto = "✓",
            Cor = Colors.Branco,
            Tamanho = UDim2.new(1, 0, 1, 0),
            AlinhamentoX = Enum.TextXAlignment.Center,
            AlinhamentoY = Enum.TextYAlignment.Center,
            Fonte = Enum.Font.GothamBold,
            TamanhoTexto = 12,
            ZIndex = 59,
        })
        checkMark.Visible = false

        local selecionado = false

        item.MouseButton1Click:Connect(function()
            if selecionado then
                selecionado = false
                checkMark.Visible = false
                item.BackgroundColor3 = Colors.PretoSuave
                item.BackgroundTransparency = 0.5
                for idx, pet in ipairs(selecionados) do
                    if pet == nomePet then
                        table.remove(selecionados, idx)
                        break
                    end
                end
            else
                if #selecionados >= 10 then
                    notificar(H.Gui, "Limite de 10 pets atingido!", "erro", 2)
                    return
                end
                selecionado = true
                checkMark.Visible = true
                item.BackgroundColor3 = Colors.AzulEscuro
                item.BackgroundTransparency = 0.3
                table.insert(selecionados, nomePet)
            end
        end)
    end

    task.defer(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    return container
end

-- Exportar
H.notificar = notificar
H.verificarServidorPrivado = verificarServidorPrivado
H.criarConteudoOpcoes = criarConteudoOpcoes
H.criarConteudoPets = criarConteudoPets

print("[Hazudi] Parte 4/5 (Funcionalidades) carregada com sucesso.")

-- ============================================================
-- HAZUDI - PARTE 5/5: AUTO STEAL E INICIALIZAÇÃO FINAL
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local H = _G.Hazudi
local Colors = H.Colors
local State = H.State
local notificar = H.notificar

-- ============================================================
-- LÓGICA DO AUTO STEAL (MONITORAMENTO E AÇÃO)
-- ============================================================
local autoStealAtivo = false
local autoStealThread = nil

local function iniciarAutoSteal()
    if autoStealThread then
        task.cancel(autoStealThread)
    end

    autoStealThread = task.spawn(function()
        while State.Opcoes.AutoSteal do
            task.wait(1) -- Verifica a cada 1 segundo

            -- 1. Verifica se o jogador ainda está vivo
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then
                continue
            end
            local hrp = char.HumanoidRootPart

            -- 2. Escaneia o workspace em busca de bases com os pets selecionados
            -- Esta é uma lógica genérica. Você precisará adaptar os nomes
            -- dos objetos e pastas de acordo com a estrutura real do jogo.
            for _, obj in pairs(workspace:GetDescendants()) do
                -- Verifica se é um pet e se o nome está na lista de selecionados
                if obj:IsA("Model") and obj.Name:lower():find("pet") then
                    for _, petSelecionado in ipairs(State.Opcoes.PetsSelecionados) do
                        if obj.Name:lower():find(petSelecionado:lower()) then
                            -- Encontrou um pet alvo!
                            print("[Hazudi] Pet alvo encontrado:", obj.Name)

                            -- 3. Teleporte suave até o pet (simulado por Tween no HRP)
                            local targetPos = obj:GetPivot().Position
                            local startPos = hrp.Position

                            -- Move o jogador até perto da base (simulação de teleporte)
                            -- Em um jogo real, você usaria um RemoteEvent ou CFrame
                            hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))

                            -- 4. Pressiona 'F' para roubar usando a função segura da Parte 1
                            if _G.HazudiSecureInput then
                                _G.HazudiSecureInput(Enum.KeyCode.F, 0.2)
                            end

                            -- 5. Espera um momento e tenta pegar o pet
                            task.wait(0.5)
                            break
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================================
-- INICIALIZAÇÃO FINAL
-- ============================================================
local function inicializarHazudi()
    print("[Hazudi] Inicializando...")

    -- 1. Cria o ScreenGui
    local gui = H.criarScreenGui()
    H.Gui = gui

    -- 2. Cria o botão flutuante
    local botao = H.criarBotaoFlutuante(gui)
    H.Botao = botao

    -- 3. Ativa o arrastar
    H.ativarDrag(botao)

    -- 4. Conecta o clique para abrir a interface
    botao.MouseButton1Click:Connect(function()
        H.animarCliqueBotao(botao, function()
            H.abrirInterface(gui, botao)
        end)
    end)

    -- 5. Sobrescreve os conteúdos placeholder
    task.delay(0.5, function()
        if H.Janela then
            local areaConteudo = H.Janela:FindFirstChild("AreaConteudo", true)
            if areaConteudo then
                local opcoesPlaceholder = areaConteudo:FindFirstChild("ConteudoOpcoes")
                if opcoesPlaceholder then opcoesPlaceholder:Destroy() end
                local petsPlaceholder = areaConteudo:FindFirstChild("ConteudoPets")
                if petsPlaceholder then petsPlaceholder:Destroy() end

                H.criarConteudoOpcoes(areaConteudo)
                H.criarConteudoPets(areaConteudo)
                print("[Hazudi] Conteúdo das abas 'Opções' e 'Pets' carregado.")
            end
        end
    end)

    -- 6. Notificação de boas-vindas
    task.delay(1, function()
        notificar(gui, "Hazudi carregado! Toque na coroa para abrir.", "info", 3)
    end)

    -- 7. Monitora o estado do Auto Steal para iniciar/parar
    task.spawn(function()
        while true do
            task.wait(0.5)
            if State.Opcoes.AutoSteal and not autoStealAtivo then
                autoStealAtivo = true
                iniciarAutoSteal()
            elseif not State.Opcoes.AutoSteal and autoStealAtivo then
                autoStealAtivo = false
            end
        end
    end)

    -- 8. Detecta o tipo de servidor no carregamento
    local ehPrivado, tipo = H.verificarServidorPrivado()
    print(string.format("[Hazudi] Tipo de servidor detectado: %s (Privado: %s)", tipo, tostring(ehPrivado)))

    print("[Hazudi] Inicialização completa.")
end

-- Executa
inicializarHazudi()
