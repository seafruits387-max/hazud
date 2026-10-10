--[[
================================================================================
  HAZUDI — SCRIPT PRINCIPAL
  Parte 1/4: Estrutura Base, Botão Flutuante e Cabeçalho
  Executor: Delta (Android/Mobile)
  Jogo alvo: Steal a Brainrot
================================================================================
  Esta parte contém:
  - Serviços e variáveis globais
  - Criação do ScreenGui principal
  - Botão flutuante circular com coroa desenhada por código
  - Sistema de arrastar (drag) com colisão de bordas
  - Animação de clique (encolher + desaparecer)
  - Cabeçalho com foto, nome e ID do jogador
================================================================================
]]

-- ============================================================
-- 1. SERVIÇOS
-- ============================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- 2. PALETA DE CORES (Azul, Branco, Preto)
-- ============================================================
local Colors = {
	Azul        = Color3.fromRGB(0, 120, 255),
	AzulEscuro  = Color3.fromRGB(0, 80, 180),
	AzulClaro   = Color3.fromRGB(80, 170, 255),
	Preto       = Color3.fromRGB(10, 10, 12),
	PretoSuave  = Color3.fromRGB(22, 22, 28),
	Branco      = Color3.fromRGB(255, 255, 255),
	Cinza       = Color3.fromRGB(160, 160, 170),
	Vermelho    = Color3.fromRGB(220, 50, 50),
	Verde       = Color3.fromRGB(50, 200, 100),
}

-- ============================================================
-- 3. VARIÁVEIS DE ESTADO
-- ============================================================
local HazudiState = {
	GUIAberta = false,
	AbaAtiva = "Comeco", -- "Comeco", "Opcoes", "Pets"
	-- Estado das opções (serão usadas nas Partes 3 e 4)
	Opcoes = {
		ServidorPrivado = false,
		TransparenciaBase = 0.5,
		Invisibilidade = false,
		ESP_Pets = false,
		AutoSteal = false,
		PetsSelecionados = {},
	},
}

-- Referências aos objetos da GUI (preenchidas durante a criação)
local HazudiGui = nil
local BotaoFlutuante = nil
local JanelaPrincipal = nil
local Abas = {}

-- ============================================================
-- 4. FUNÇÕES UTILITÁRIAS
-- ============================================================

--- Cria um Frame com propriedades comuns.
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

--- Cria um TextLabel com propriedades comuns.
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
-- 5. CRIAÇÃO DO SCREEN GUI PRINCIPAL
-- ============================================================

local function criarScreenGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Hazudi"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Parent: tenta gethui() (Delta-safe), depois CoreGui, depois PlayerGui
	local parentOk = false
	local parentResult

	local success1, hui = pcall(function()
		return gethui and gethui() or nil
	end)
	if success1 and hui then
		gui.Parent = hui
		parentOk = true
		parentResult = "gethui()"
	end

	if not parentOk then
		local success2, coreGui = pcall(function()
			return game:GetService("CoreGui")
		end)
		if success2 and coreGui then
			gui.Parent = coreGui
			parentOk = true
			parentResult = "CoreGui"
		end
	end

	if not parentOk then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
		parentResult = "PlayerGui"
	end

	print("[Hazudi] ScreenGui criado em: " .. tostring(parentResult))
	return gui
end

-- ============================================================
-- 6. BOTÃO FLUTUANTE COM COROA DESENHADA POR CÓDIGO
-- ============================================================

--- Desenha uma coroa estilizada usando Frames.
-- Retorna um Frame container com a coroa.
local function criarCoroa(parent, tamanho)
	local container = Instance.new("Frame")
	container.Name = "CoroaIcon"
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(0, tamanho, 0, tamanho)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.ZIndex = 5
	container.Parent = parent

	-- Base da coroa (retângulo inferior)
	local base = Instance.new("Frame")
	base.Name = "Base"
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

	-- Ponta esquerda
	local pontaEsq = Instance.new("Frame")
	pontaEsq.Name = "PontaEsq"
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

	-- Ponta central (mais alta)
	local pontaCentro = Instance.new("Frame")
	pontaCentro.Name = "PontaCentro"
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

	-- Ponta direita
	local pontaDir = Instance.new("Frame")
	pontaDir.Name = "PontaDir"
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

	-- Detalhe: círculos nas pontas
	for _, xPos in ipairs({0.18, 0.5, 0.82}) do
		local bola = Instance.new("Frame")
		bola.Name = "BolaPonta"
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

--- Cria o botão flutuante circular com a coroa.
local function criarBotaoFlutuante(gui)
	local tamanhoBotao = 56 -- Tamanho em pixels (discreto para mobile)

	local botao = Instance.new("TextButton")
	botao.Name = "BotaoHazudi"
	botao.BackgroundColor3 = Colors.Preto
	botao.BorderSizePixel = 0
	botao.Size = UDim2.new(0, tamanhoBotao, 0, tamanhoBotao)
	botao.Position = UDim2.new(0, 20, 0.5, -tamanhoBotao / 2) -- Posição inicial: esquerda, centro
	botao.AnchorPoint = Vector2.new(0, 0)
	botao.Text = ""
	botao.AutoButtonColor = false
	botao.ZIndex = 100
	botao.Parent = gui

	-- Círculo (UICorner)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = botao

	-- Borda branca
	local stroke = Instance.new("UIStroke")
	stroke.Color = Colors.Branco
	stroke.Thickness = 2
	stroke.Transparency = 0.2
	stroke.Parent = botao

	-- Sombra sutil (Frame atrás)
	local sombra = Instance.new("Frame")
	sombra.Name = "Sombra"
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

	-- Coroa desenhada
	criarCoroa(botao, tamanhoBotao * 0.55)

	return botao
end

-- ============================================================
-- 7. SISTEMA DE ARRASTAR (DRAG) COM COLISÃO DE BORDAS
-- ============================================================

--- Ativa o sistema de arrastar no botão.
local function ativarDrag(botao)
	local arrastando = false
	local offsetInicial = Vector2.new(0, 0)
	local posicaoInicial = UDim2.new(0, 0, 0, 0)

	-- Tamanho do botão em pixels (para cálculo de bordas)
	local botaoTamanhoX = 56
	local botaoTamanhoY = 56

	-- Função para obter o tamanho da tela (compatível com mobile)
	local function getTamanhoTela()
		local camera = workspace.CurrentCamera
		if camera then
			return camera.ViewportSize
		end
		return Vector2.new(1920, 1080) -- fallback
	end

	-- Função para limitar posição dentro da tela
	local function limitarPosicao(posX, posY)
		local tela = getTamanhoTela()
		local maxX = tela.X - botaoTamanhoX
		local maxY = tela.Y - botaoTamanhoY

		posX = math.clamp(posX, 0, maxX)
		posY = math.clamp(posY, 0, maxY)

		return posX, posY
	end

	-- Input iniciado (mouse ou toque)
	botao.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			arrastando = true

			-- Offset entre o dedo/mouse e o canto do botão
			local posBotao = botao.AbsolutePosition
			offsetInicial = Vector2.new(
				input.Position.X - posBotao.X,
				input.Position.Y - posBotao.Y
			)
		end
	end)

	-- Input terminado
	botao.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			arrastando = false
		end
	end)

	-- Movimento contínuo via RunService (mais suave que InputChanged sozinho)
	RunService.RenderStepped:Connect(function()
		if not arrastando then return end

		-- Obtém posição atual do input
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

		-- Calcula nova posição
		local novoX = inputPos.X - offsetInicial.X
		local novoY = inputPos.Y - offsetInicial.Y

		-- Limita às bordas da tela
		novoX, novoY = limitarPosicao(novoX, novoY)

		botao.Position = UDim2.new(0, novoX, 0, novoY)
	end)
end

-- ============================================================
-- 8. ANIMAÇÃO DE CLIQUE DO BOTÃO
-- ============================================================

--- Executa a animação de encolhimento e some o botão.
local function animarCliqueBotao(botao, callback)
	-- Fase 1: Encolher
	local encolherInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local encolherTween = TweenService:Create(botao, encolherInfo, {
		Size = UDim2.new(0, 40, 0, 40),
		BackgroundTransparency = 0.3,
	})

	encolherTween:Play()
	encolherTween.Completed:Wait()

	-- Fase 2: Desaparecer
	local desaparecerInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local desaparecerTween = TweenService:Create(botao, desaparecerInfo, {
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
	})

	desaparecerTween:Play()
	desaparecerTween.Completed:Wait()

	botao.Visible = false

	-- Callback para abrir a interface
	if callback then
		callback()
	end
end

-- ============================================================
-- 9. CABEÇALHO DO JOGADOR
-- ============================================================

--- Cria o cabeçalho com foto, nome e ID do jogador.
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
	nomeHazudi.Name = "NomeHazudi"
	nomeHazudi.BackgroundTransparency = 1
	nomeHazudi.Size = UDim2.new(1, -20, 0, 24)
	nomeHazudi.Position = UDim2.new(0, 10, 0, 4)
	nomeHazudi.ZIndex = 11
	nomeHazudi.Parent = header

	local haTexto = criarTexto(nomeHazudi, {
		Texto = "Ha",
		Cor = Colors.Branco,
		Tamanho = UDim2.new(0, 40, 1, 0),
		Posicao = UDim2.new(0.5, -30, 0, 0),
		AlinhamentoX = Enum.TextXAlignment.Right,
		Fonte = Enum.Font.GothamBold,
		TamanhoTexto = 20,
		ZIndex = 12,
	})

	local zudTexto = criarTexto(nomeHazudi, {
		Texto = "Zud",
		Cor = Colors.Azul,
		Tamanho = UDim2.new(0, 50, 1, 0),
		Posicao = UDim2.new(0.5, -30, 0, 0),
		AlinhamentoX = Enum.TextXAlignment.Left,
		Fonte = Enum.Font.GothamBold,
		TamanhoTexto = 20,
		ZIndex = 12,
	})

	-- Foto do jogador (usando ImageLabel com thumbnail)
	local fotoContainer = criarFrame(header, {
		Cor = Colors.Preto,
		Tamanho = UDim2.new(0, 40, 0, 40),
		Posicao = UDim2.new(0, 10, 0, 24),
		CantosArredondados = 8,
		Borda = { Cor = Colors.Branco, Espessura = 1, Transparencia = 0.3 },
		ZIndex = 11,
	})

	local foto = Instance.new("ImageLabel")
	foto.Name = "FotoJogador"
	foto.BackgroundTransparency = 1
	foto.Size = UDim2.new(1, -4, 1, -4)
	foto.Position = UDim2.new(0.5, 0, 0.5, 0)
	foto.AnchorPoint = Vector2.new(0.5, 0.5)
	foto.ZIndex = 12
	foto.Parent = fotoContainer

	local fotoCorner = Instance.new("UICorner")
	fotoCorner.CornerRadius = UDim.new(0, 6)
	fotoCorner.Parent = foto

	-- Nome do jogador
	local nomeJogador = criarTexto(header, {
		Texto = LocalPlayer.DisplayName or LocalPlayer.Name,
		Cor = Colors.Branco,
		Tamanho = UDim2.new(0, 160, 0, 18),
		Posicao = UDim2.new(0, 58, 0, 26),
		Fonte = Enum.Font.GothamBold,
		TamanhoTexto = 14,
		ZIndex = 11,
	})

	-- ID do jogador
	local idJogador = criarTexto(header, {
		Texto = "ID: " .. tostring(LocalPlayer.UserId),
		Cor = Colors.Cinza,
		Tamanho = UDim2.new(0, 160, 0, 16),
		Posicao = UDim2.new(0, 58, 0, 44),
		Fonte = Enum.Font.Gotham,
		TamanhoTexto = 11,
		ZIndex = 11,
	})

	-- Carregar thumbnail do jogador
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
-- 10. RETORNO DE MÓDULO (para uso nas Partes 2, 3 e 4)
-- ============================================================

-- Torna as referências e funções disponíveis globalmente para as outras partes
_G.Hazudi = {
	Colors = Colors,
	State = HazudiState,
	criarFrame = criarFrame,
	criarTexto = criarTexto,
	criarCoroa = criarCoroa,
	criarCabecalho = criarCabecalho,
	criarScreenGui = criarScreenGui,
	criarBotaoFlutuante = criarBotaoFlutuante,
	ativarDrag = ativarDrag,
	animarCliqueBotao = animarCliqueBotao,
	Gui = nil, -- será preenchido na inicialização
	Botao = nil,
	Janela = nil,
	Abas = {},
}

print("[Hazudi] Parte 1 carregada — Estrutura base, botão flutuante e cabeçalho definidos.")

--[[
================================================================================
  HAZUDI — SCRIPT PRINCIPAL
  Parte 2/4: Interface Principal — Janela, Abas e Categoria "Começo"
================================================================================
  Esta parte contém:
  - Criação da janela principal com animação de abertura
  - Sistema de abas (Começo, Opções, Pets)
  - Categoria "Começo" com mensagem de boas-vindas
  - Cabeçalho integrado na janela
================================================================================
]]

-- ============================================================
-- 1. REFERÊNCIAS DA PARTE 1
-- ============================================================
local H = _G.Hazudi
local Colors = H.Colors
local State = H.State
local criarFrame = H.criarFrame
local criarTexto = H.criarTexto
local criarCabecalho = H.criarCabecalho

-- ============================================================
-- 2. CRIAÇÃO DA JANELA PRINCIPAL
-- ============================================================

--- Cria a janela principal do Hazudi com animação de abertura.
local function criarJanelaPrincipal(gui)
	local janela = criarFrame(gui, {
		Nome = "JanelaHazudi",
		Cor = Colors.Preto,
		Tamanho = UDim2.new(0, 0, 0, 0), -- começa em 0 para animar
		Posicao = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		CantosArredondados = 16,
		Borda = { Cor = Colors.Azul, Espessura = 2, Transparencia = 0.3 },
		ZIndex = 50,
	})

	-- Fundo semi-transparente interno
	local fundoInterno = criarFrame(janela, {
		Cor = Colors.PretoSuave,
		Tamanho = UDim2.new(1, -4, 1, -4),
		Posicao = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		CantosArredondados = 14,
		ZIndex = 51,
	})

	-- Cabeçalho do jogador
	local header = criarCabecalho(fundoInterno)

	-- Área de conteúdo (onde as abas serão renderizadas)
	local areaConteudo = criarFrame(fundoInterno, {
		Nome = "AreaConteudo",
		Cor = Colors.PretoSuave,
		Tamanho = UDim2.new(1, -20, 1, -100),
		Posicao = UDim2.new(0, 10, 0, 90),
		CantosArredondados = 10,
		ZIndex = 51,
	})

	-- Barra de abas (na parte inferior)
	local barraAbas = criarFrame(fundoInterno, {
		Nome = "BarraAbas",
		Cor = Colors.Preto,
		Tamanho = UDim2.new(1, -20, 0, 40),
		Posicao = UDim2.new(0, 10, 1, -50),
		CantosArredondados = 10,
		Borda = { Cor = Colors.Azul, Espessura = 1, Transparencia = 0.5 },
		ZIndex = 52,
	})

	-- Botão de fechar (X no canto superior direito)
	local botaoFechar = Instance.new("TextButton")
	botaoFechar.Name = "Fechar"
	botaoFechar.BackgroundColor3 = Colors.Vermelho
	botaoFechar.BackgroundTransparency = 0.7
	botaoFechar.BorderSizePixel = 0
	botaoFechar.Size = UDim2.new(0, 28, 0, 28)
	botaoFechar.Position = UDim2.new(1, -38, 0, 38)
	botaoFechar.AnchorPoint = Vector2.new(0, 0)
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
-- 3. CRIAÇÃO DAS ABAS
-- ============================================================

--- Cria um botão de aba na barra inferior.
local function criarBotaoAba(barra, nome, iconeTipo, callback)
	local botao = Instance.new("TextButton")
	botao.Name = "Aba_" .. nome
	botao.BackgroundColor3 = Colors.Preto
	botao.BackgroundTransparency = 0.5
	botao.BorderSizePixel = 0
	botao.Size = UDim2.new(1/3, -8, 1, -8)
	botao.Position = UDim2.new(0, 0, 0.5, 0)
	botao.AnchorPoint = Vector2.new(0, 0.5)
	botao.Text = ""
	botao.AutoButtonColor = false
	botao.ZIndex = 53
	botao.Parent = barra

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = botao

	-- Ícone desenhado (simples, por código)
	local iconeContainer = Instance.new("Frame")
	iconeContainer.Name = "Icone"
	iconeContainer.BackgroundTransparency = 1
	iconeContainer.Size = UDim2.new(0, 18, 0, 18)
	iconeContainer.Position = UDim2.new(0.5, 0, 0.5, -6)
	iconeContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	iconeContainer.ZIndex = 54
	iconeContainer.Parent = botao

	if iconeTipo == "casa" then
		-- Ícone de casa (triângulo + retângulo)
		local triangulo = Instance.new("Frame")
		triangulo.BackgroundColor3 = Colors.Azul
		triangulo.BorderSizePixel = 0
		triangulo.Size = UDim2.new(0, 14, 0, 8)
		triangulo.Position = UDim2.new(0.5, 0, 0.3, 0)
		triangulo.AnchorPoint = Vector2.new(0.5, 0.5)
		triangulo.Rotation = 45
		triangulo.ZIndex = 55
		triangulo.Parent = iconeContainer

		local baseCasa = Instance.new("Frame")
		baseCasa.BackgroundColor3 = Colors.Azul
		baseCasa.BorderSizePixel = 0
		baseCasa.Size = UDim2.new(0, 10, 0, 8)
		baseCasa.Position = UDim2.new(0.5, 0, 0.65, 0)
		baseCasa.AnchorPoint = Vector2.new(0.5, 0.5)
		baseCasa.ZIndex = 55
		baseCasa.Parent = iconeContainer

	elseif iconeTipo == "engrenagem" then
		-- Ícone de engrenagem (círculo com dentes)
		local centro = Instance.new("Frame")
		centro.BackgroundColor3 = Colors.Azul
		centro.BorderSizePixel = 0
		centro.Size = UDim2.new(0, 10, 0, 10)
		centro.Position = UDim2.new(0.5, 0, 0.5, 0)
		centro.AnchorPoint = Vector2.new(0.5, 0.5)
		centro.ZIndex = 55
		centro.Parent = iconeContainer

		local centroCorner = Instance.new("UICorner")
		centroCorner.CornerRadius = UDim.new(1, 0)
		centroCorner.Parent = centro

		for i = 1, 6 do
			local dente = Instance.new("Frame")
			dente.BackgroundColor3 = Colors.Azul
			dente.BorderSizePixel = 0
			dente.Size = UDim2.new(0, 4, 0, 8)
			dente.Position = UDim2.new(0.5, 0, 0.5, 0)
			dente.AnchorPoint = Vector2.new(0.5, 0.5)
			dente.Rotation = i * 60
			dente.ZIndex = 54
			dente.Parent = iconeContainer
		end

	elseif iconeTipo == "pets" then
		-- Ícone de pata (círculos)
		local mainCircle = Instance.new("Frame")
		mainCircle.BackgroundColor3 = Colors.Azul
		mainCircle.BorderSizePixel = 0
		mainCircle.Size = UDim2.new(0, 10, 0, 10)
		mainCircle.Position = UDim2.new(0.5, 0, 0.55, 0)
		mainCircle.AnchorPoint = Vector2.new(0.5, 0.5)
		mainCircle.ZIndex = 55
		mainCircle.Parent = iconeContainer

		local mcCorner = Instance.new("UICorner")
		mcCorner.CornerRadius = UDim.new(1, 0)
		mcCorner.Parent = mainCircle

		for _, offset in ipairs({{-5, -4}, {0, -6}, {5, -4}}) do
			local dedo = Instance.new("Frame")
			dedo.BackgroundColor3 = Colors.Azul
			dedo.BorderSizePixel = 0
			dedo.Size = UDim2.new(0, 5, 0, 5)
			dedo.Position = UDim2.new(0.5, offset[1], 0.5, offset[2])
			dedo.AnchorPoint = Vector2.new(0.5, 0.5)
			dedo.ZIndex = 54
			dedo.Parent = iconeContainer

			local dCorner = Instance.new("UICorner")
			dCorner.CornerRadius = UDim.new(1, 0)
			dCorner.Parent = dedo
		end
	end

	-- Texto da aba
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

	-- Callback de clique
	botao.MouseButton1Click:Connect(function()
		if callback then
			callback(nome)
		end
	end)

	return botao, textoAba
end

-- ============================================================
-- 4. CATEGORIA "COMEÇO"
-- ============================================================

--- Cria o conteúdo da aba "Começo".
local function criarConteudoComeco(parent)
	local container = criarFrame(parent, {
		Nome = "ConteudoComeco",
		Cor = Colors.Preto,
		Tamanho = UDim2.new(1, 0, 1, 0),
		Posicao = UDim2.new(0, 0, 0, 0),
		CantosArredondados = 8,
		ZIndex = 55,
	})

	-- Título de boas-vindas
	local titulo = criarTexto(container, {
		Texto = "Bem-vindo ao Hazudi",
		Cor = Colors.Azul,
		Tamanho = UDim2.new(1, -20, 0, 28),
		Posicao = UDim2.new(0, 10, 0, 10),
		AlinhamentoX = Enum.TextXAlignment.Center,
		Fonte = Enum.Font.GothamBold,
		TamanhoTexto = 20,
		ZIndex = 56,
	})

	-- Linha decorativa
	local linha = criarFrame(container, {
		Cor = Colors.Azul,
		Tamanho = UDim2.new(0.3, 0, 0, 2),
		Posicao = UDim2.new(0.5, 0, 0, 42),
		AnchorPoint = Vector2.new(0.5, 0),
		ZIndex = 56,
		CantosArredondados = 1,
	})

	-- Texto de agradecimento
	local texto = criarTexto(container, {
		Texto = "Obrigado por abrir o Hazudi, " .. (LocalPlayer.DisplayName or LocalPlayer.Name) .. "!\n\n"
			.. "Este é o seu hub de utilidades para Steal a Brainrot.\n"
			.. "Aqui você encontrará ferramentas organizadas em abas,\n"
			.. "com uma interface limpa e pensada para mobile.\n\n"
			.. "Use a barra inferior para navegar entre as categorias.\n\n"
			.. "— Equipe Hazudi",
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

	-- Ícone decorativo (estrela simples desenhada)
	local estrela = Instance.new("Frame")
	estrela.Name = "Estrela"
	estrela.BackgroundColor3 = Colors.Azul
	estrela.BorderSizePixel = 0
	estrela.Size = UDim2.new(0, 20, 0, 20)
	estrela.Position = UDim2.new(0.5, 0, 1, -30)
	estrela.AnchorPoint = Vector2.new(0.5, 1)
	estrela.Rotation = 45
	estrela.ZIndex = 56
	estrela.Parent = container

	local estrelaCorner = Instance.new("UICorner")
	estrelaCorner.CornerRadius = UDim.new(0, 4)
	estrelaCorner.Parent = estrela

	return container
end

-- ============================================================
-- 5. SISTEMA DE TROCA DE ABAS
-- ============================================================

--- Troca a aba ativa, escondendo o conteúdo anterior e mostrando o novo.
local function trocarAba(nomeAba, areaConteudo, botoesAba)
	-- Esconde todos os conteúdos
	for childName, child in pairs(areaConteudo:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^Conteudo") then
			child.Visible = false
		end
	end

	-- Mostra o conteúdo da aba selecionada
	local conteudoAlvo = areaConteudo:FindFirstChild("Conteudo" .. nomeAba)
	if conteudoAlvo then
		conteudoAlvo.Visible = true
	end

	-- Atualiza visual dos botões de aba
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

-- ============================================================
-- 6. INICIALIZAÇÃO DA INTERFACE PRINCIPAL
-- ============================================================

--- Abre a interface principal com animação.
local function abrirInterface(gui, botaoFlutuante)
	-- Evita abrir duas vezes
	if State.GUIAberta then return end
	State.GUIAberta = true

	-- Torna o botão invisível (já foi animado)
	botaoFlutuante.Visible = false

	-- Cria a janela principal
	local janela, areaConteudo, barraAbas, botaoFechar = criarJanelaPrincipal(gui)
	H.Janela = janela

	-- Cria os conteúdos das abas
	local conteudoComeco = criarConteudoComeco(areaConteudo)

	-- Placeholder para Opções (será preenchido na Parte 3)
	local conteudoOpcoes = criarFrame(areaConteudo, {
		Nome = "ConteudoOpcoes",
		Cor = Colors.Preto,
		Tamanho = UDim2.new(1, 0, 1, 0),
		Posicao = UDim2.new(0, 0, 0, 0),
		CantosArredondados = 8,
		ZIndex = 55,
	})
	conteudoOpcoes.Visible = false

	criarTexto(conteudoOpcoes, {
		Texto = "Opções carregando...",
		Cor = Colors.Cinza,
		Tamanho = UDim2.new(1, 0, 1, 0),
		AlinhamentoX = Enum.TextXAlignment.Center,
		AlinhamentoY = Enum.TextYAlignment.Center,
		Fonte = Enum.Font.Gotham,
		TamanhoTexto = 14,
		ZIndex = 56,
	})

	-- Placeholder para Pets (será preenchido na Parte 3)
	local conteudoPets = criarFrame(areaConteudo, {
		Nome = "ConteudoPets",
		Cor = Colors.Preto,
		Tamanho = UDim2.new(1, 0, 1, 0),
		Posicao = UDim2.new(0, 0, 0, 0),
		CantosArredondados = 8,
		ZIndex = 55,
	})
	conteudoPets.Visible = false

	criarTexto(conteudoPets, {
		Texto = "Lista de Pets carregando...",
		Cor = Colors.Cinza,
		Tamanho = UDim2.new(1, 0, 1, 0),
		AlinhamentoX = Enum.TextXAlignment.Center,
		AlinhamentoY = Enum.TextYAlignment.Center,
		Fonte = Enum.Font.Gotham,
		TamanhoTexto = 14,
		ZIndex = 56,
	})

	-- Cria os botões das abas
	local botoesAba = {}

	local botaoComeco, textoComeco = criarBotaoAba(barraAbas, "Começo", "casa", function(nome)
		trocarAba("Comeco", areaConteudo, botoesAba)
	end)
	botaoComeco.Position = UDim2.new(0, 4, 0.5, 0)
	botoesAba["Comeco"] = { Botao = botaoComeco, Texto = textoComeco }

	local botaoOpcoes, textoOpcoes = criarBotaoAba(barraAbas, "Opções", "engrenagem", function(nome)
		trocarAba("Opcoes", areaConteudo, botoesAba)
	end)
	botaoOpcoes.Position = UDim2.new(1/3, 4, 0.5, 0)
	botoesAba["Opcoes"] = { Botao = botaoOpcoes, Texto = textoOpcoes }

	local botaoPets, textoPets = criarBotaoAba(barraAbas, "Pets", "pets", function(nome)
		trocarAba("Pets", areaConteudo, botoesAba)
	end)
	botaoPets.Position = UDim2.new(2/3, 4, 0.5, 0)
	botoesAba["Pets"] = { Botao = botaoPets, Texto = textoPets }

	-- Estado inicial: aba Começo ativa
	trocarAba("Comeco", areaConteudo, botoesAba)

	-- Botão de fechar
	botaoFechar.MouseButton1Click:Connect(function()
		-- Animação de fechamento
		local fecharTween = TweenService:Create(janela, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
		})
		fecharTween:Play()
		fecharTween.Completed:Wait()

		janela:Destroy()
		State.GUIAberta = false

		-- Restaura o botão flutuante
		botaoFlutuante.Visible = true
		botaoFlutuante.Size = UDim2.new(0, 56, 0, 56)
		botaoFlutuante.BackgroundTransparency = 0
	end)

	-- Animação de abertura da janela
	janela.Size = UDim2.new(0, 0, 0, 0)
	janela.BackgroundTransparency = 1

	local abrirInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local abrirTween = TweenService:Create(janela, abrirInfo, {
		Size = UDim2.new(0.9, 0, 0.8, 0),
		BackgroundTransparency = 0,
	})

	-- Ajusta o tamanho máximo para telas menores
	local viewport = workspace.CurrentCamera.ViewportSize
	local larguraMax = math.min(viewport.X * 0.95, 420)
	local alturaMax = math.min(viewport.Y * 0.85, 600)

	janela.Size = UDim2.new(0, larguraMax, 0, 0) -- começa com altura 0
	abrirTween = TweenService:Create(janela, abrirInfo, {
		Size = UDim2.new(0, larguraMax, 0, alturaMax),
		BackgroundTransparency = 0,
	})
	abrirTween:Play()

	return janela
end

-- ============================================================
-- 7. EXPORTAÇÃO PARA AS PRÓXIMAS PARTES
-- ============================================================

H.criarJanelaPrincipal = criarJanelaPrincipal
H.criarBotaoAba = criarBotaoAba
H.criarConteudoComeco = criarConteudoComeco
H.trocarAba = trocarAba
H.abrirInterface = abrirInterface

print("[Hazudi] Parte 2 carregada — Janela principal, abas e categoria 'Começo' definidas.")

--[[
================================================================================
  HAZUDI — SCRIPT PRINCIPAL
  Parte 3/4: Conteúdo das Abas "Opções" e "Pets" — Interface Visual
================================================================================
  Esta parte contém:
  - Aba "Opções": toggles visuais para as funcionalidades
  - Aba "Pets": lista de pets para seleção (placeholder)
  - Todos os ícones desenhados por código
  - Animações de toggle (deslizante)

  IMPORTANTE: As funções de gameplay são apenas estruturas visuais.
  A lógica real de cada opção será implementada na Parte 4.
================================================================================
]]

-- ============================================================
-- 1. REFERÊNCIAS
-- ============================================================
local H = _G.Hazudi
local Colors = H.Colors
local State = H.State
local criarFrame = H.criarFrame
local criarTexto = H.criarTexto

-- ============================================================
-- 2. COMPONENTE: TOGGLE DESLIZANTE
-- ============================================================

--- Cria um toggle deslizante (estilo iOS) com animação.
-- Retorna o botão e uma função para definir o estado.
local function criarToggle(parent, props)
	local nome = props.Nome or "Toggle"
	local estadoInicial = props.EstadoInicial or false

	-- Container
	local container = criarFrame(parent, {
		Nome = "Toggle_" .. nome,
		Cor = Colors.Preto,
		Tamanho = UDim2.new(1, -20, 0, 48),
		Posicao = props.Posicao or UDim2.new(0, 10, 0, 0),
		CantosArredondados = 8,
		Borda = { Cor = Colors.Azul, Espessura = 1, Transparencia = 0.6 },
		ZIndex = 56,
	})

	-- Label do nome
	local label = criarTexto(container, {
		Texto = nome,
		Cor = Colors.Branco,
		Tamanho = UDim2.new(1, -80, 1, 0),
		Posicao = UDim2.new(0, 12, 0, 0),
		Fonte = Enum.Font.GothamMedium,
		TamanhoTexto = 13,
		ZIndex = 57,
	})

	-- Ícone do toggle (desenhado)
	local iconeFrame = criarFrame(container, {
		Cor = Colors.PretoSuave,
		Tamanho = UDim2.new(0, 44, 0, 24),
		Posicao = UDim2.new(1, -56, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		CantosArredondados = 12,
		ZIndex = 57,
	})

	-- Bolinha deslizante
	local bolinha = Instance.new("Frame")
	bolinha.Name = "Bolinha"
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

	-- Botão invisível sobre o toggle
	local botaoToggle = Instance.new("TextButton")
	botaoToggle.BackgroundTransparency = 1
	botaoToggle.Size = UDim2.new(1, 0, 1, 0)
	botaoToggle.Text = ""
	botaoToggle.ZIndex = 59
	botaoToggle.Parent = container

	-- Estado
	local estadoAtual = estadoInicial

	local function animarToggle(novoEstado)
		estadoAtual = novoEstado

		local targetPos
		local targetColor
		if novoEstado then
			targetPos = UDim2.new(1, -22, 0.5, 0)
			targetColor = Colors.Verde
		else
			targetPos = UDim2.new(0, 2, 0.5, 0)
			targetColor = Colors.Vermelho
		end

		local info = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		TweenService:Create(bolinha, info, {
			Position = targetPos,
			BackgroundColor3 = targetColor,
		}):Play()

		-- Atualiza estado global
		State.Opcoes[nome] = novoEstado

		-- Callback personalizado
		if props.Callback then
			props.Callback(novoEstado)
		end
	end

	botaoToggle.MouseButton1Click:Connect(function()
		animarToggle(not estadoAtual)
	end)

	-- Define estado inicial
	if estadoInicial then
		animarToggle(true)
	end

	return botaoToggle, animarToggle, container
end

-- ============================================================
-- 3. ABA "OPÇÕES"
-- ============================================================

--- Cria o conteúdo da aba "Opções".
local function criarConteudoOpcoes(parent)
	local container = criarFrame(parent, {
		Nome = "ConteudoOpcoes",
		Cor = Colors.Preto,
		Tamanho = UDim2.new(1, 0, 1, 0),
		Posicao = UDim2.new(0, 0, 0, 0),
		CantosArredondados = 8,
		ZIndex = 55,
	})

	-- ScrollFrame para comportar muitas opções
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "ScrollOpcoes"
	scroll.BackgroundTransparency = 1
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.Position = UDim2.new(0, 0, 0, 0)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0) -- ajustado depois
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Colors.Azul
	scroll.ZIndex = 56
	scroll.Parent = container

	-- Layout automático vertical
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = scroll

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 0)
	padding.PaddingRight = UDim.new(0, 0)
	padding.Parent = scroll

	-- Título
	local titulo = criarTexto(scroll, {
		Texto = "⚙️ Opções do Hazudi",
		Cor = Colors.Azul,
		Tamanho = UDim2.new(1, -20, 0, 24),
		Posicao = UDim2.new(0, 10, 0, 0),
		Fonte = Enum.Font.GothamBold,
		TamanhoTexto = 16,
		ZIndex = 57,
	})

	-- --- OPÇÃO 1: Servidor Privado ---
	local togglePrivado, setPrivado = criarToggle(scroll, {
		Nome = "Modo Servidor Privado",
		EstadoInicial = false,
		Posicao = UDim2.new(0, 0, 0, 30),
		Callback = function(estado)
			-- A lógica real será conectada na Parte 4
			print("[Hazudi] Servidor Privado:", estado)
		end,
	})

	-- Descrição da opção
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

	-- --- OPÇÃO 2: Transparência das Bases ---
	local toggleTransp, setTransp = criarToggle(scroll, {
		Nome = "Bases Transparentes",
		EstadoInicial = false,
		Posicao = UDim2.new(0, 0, 0, 0),
		Callback = function(estado)
			print("[Hazudi] Transparência:", estado)
		end,
	})

	-- Slider de transparência
	local sliderContainer = criarFrame(scroll, {
		Cor = Colors.Preto,
		Tamanho = UDim2.new(1, -20, 0, 40),
		Posicao = UDim2.new(0, 10, 0, 0),
		CantosArredondados = 8,
		Borda = { Cor = Colors.Azul, Espessura = 1, Transparencia = 0.6 },
		ZIndex = 56,
	})

	criarTexto(sliderContainer, {
		Texto = "Transparência: 50%",
		Cor = Colors.Branco,
		Tamanho = UDim2.new(1, -20, 0, 20),
		Posicao = UDim2.new(0, 10, 0, 2),
		Fonte = Enum.Font.Gotham,
		TamanhoTexto = 11,
		ZIndex = 57,
	})

	-- Barra do slider
	local sliderBar = criarFrame(sliderContainer, {
		Cor = Colors.PretoSuave,
		Tamanho = UDim2.new(1, -20, 0, 8),
		Posicao = UDim2.new(0, 10, 0, 24),
		CantosArredondados = 4,
		ZIndex = 57,
	})

	local sliderFill = criarFrame(sliderBar, {
		Cor = Colors.Azul,
		Tamanho = UDim2.new(0.5, 0, 1, 0),
		Posicao = UDim2.new(0, 0, 0, 0),
		CantosArredondados = 4,
		ZIndex = 58,
	})

	-- Botão do slider
	local sliderBtn = Instance.new("TextButton")
	sliderBtn.BackgroundColor3 = Colors.Branco
	sliderBtn.BorderSizePixel = 0
	sliderBtn.Size = UDim2.new(0, 16, 0, 16)
	sliderBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
	sliderBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	sliderBtn.Text = ""
	sliderBtn.ZIndex = 59
	sliderBtn.Parent = sliderBar

	local sliderBtnCorner = Instance.new("UICorner")
	sliderBtnCorner.CornerRadius = UDim.new(1, 0)
	sliderBtnCorner.Parent = sliderBtn

	-- --- OPÇÃO 3: Invisibilidade ---
	criarToggle(scroll, {
		Nome = "Invisibilidade Total",
		EstadoInicial = false,
		Posicao = UDim2.new(0, 0, 0, 0),
		Callback = function(estado)
			print("[Hazudi] Invisibilidade:", estado)
		end,
	})

	criarTexto(scroll, {
		Texto = "Torna você invisível para outros jogadores (nome e corpo).",
		Cor = Colors.Cinza,
		Tamanho = UDim2.new(1, -20, 0, 24),
		Posicao = UDim2.new(0, 10, 0, 0),
		Fonte = Enum.Font.Gotham,
		TamanhoTexto = 10,
		QuebrarLinha = true,
		ZIndex = 57,
	})

	-- --- OPÇÃO 4: ESP de Pets ---
	criarToggle(scroll, {
		Nome = "ESP — Ver Valor dos Pets",
		EstadoInicial = false,
		Posicao = UDim2.new(0, 0, 0, 0),
		Callback = function(estado)
			print("[Hazudi] ESP Pets:", estado)
		end,
	})

	criarTexto(scroll, {
		Texto = "Mostra nome e valor dos pets na base de outros jogadores.",
		Cor = Colors.Cinza,
		Tamanho = UDim2.new(1, -20, 0, 24),
		Posicao = UDim2.new(0, 10, 0, 0),
		Fonte = Enum.Font.Gotham,
		TamanhoTexto = 10,
		QuebrarLinha = true,
		ZIndex = 57,
	})

	-- --- OPÇÃO 5: Auto Steal ---
	criarToggle(scroll, {
		Nome = "Auto Steal (Pets Selecionados)",
		EstadoInicial = false,
		Posicao = UDim2.new(0, 0, 0, 0),
		Callback = function(estado)
			print("[Hazudi] Auto Steal:", estado)
		end,
	})

	criarTexto(scroll, {
		Texto = "Monitora a base dos jogadores e rouba automaticamente pets da lista.",
		Cor = Colors.Cinza,
		Tamanho = UDim2.new(1, -20, 0, 24),
		Posicao = UDim2.new(0, 10, 0, 0),
		Fonte = Enum.Font.Gotham,
		TamanhoTexto = 10,
		QuebrarLinha = true,
		ZIndex = 57,
	})

	-- Ajusta o canvas do scroll
	task.defer(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	end)

	return container, scroll, togglePrivado, setPrivado
end

-- ============================================================
-- 4. ABA "PETS" — LISTA DE SELEÇÃO
-- ============================================================

--- Lista de pets placeholder (será substituída por dados reais).
local PETS_PLACEHOLDER = {
	"Noobini Pizzanini", "Tralalero Tralala", "Bombardiro Crocodilo",
	"Tung Tung Tung Sahur", "Boneca Ambalabu", "Lirili Larila",
	"Brr Brr Patapim", "Chimpanzini Bananini", "Glorbo Fruttodrillo",
	"Crocodildo Penisini", "Frigo Camelo", "Blueberrinni Octopusini",
	"Burbaloni Loliloli", "Capuccino Assassino", "Espresso Signora",
	"Girafa Celeste", "Zibra Zubra Zibralini", "Trippi Troppi",
	"Bobritto Bandito", "Trulimero Trulicina",
}

--- Cria o conteúdo da aba "Pets".
local function criarConteudoPets(parent)
	local container = criarFrame(parent, {
		Nome = "ConteudoPets",
		Cor = Colors.Preto,
		Tamanho = UDim2.new(1, 0, 1, 0),
		Posicao = UDim2.new(0, 0, 0, 0),
		CantosArredondados = 8,
		ZIndex = 55,
	})

	-- Título
	criarTexto(container, {
		Texto = "🐾 Seleção de Pets",
		Cor = Colors.Azul,
		Tamanho = UDim2.new(1, -20, 0, 24),
		Posicao = UDim2.new(0, 10, 0, 8),
		Fonte = Enum.Font.GothamBold,
		TamanhoTexto = 16,
		ZIndex = 57,
	})

	-- Instrução
	criarTexto(container, {
		Texto = "Selecione até 10 pets para o Auto Steal monitorar.",
		Cor = Colors.Cinza,
		Tamanho = UDim2.new(1, -20, 0, 18),
		Posicao = UDim2.new(0, 10, 0, 32),
		Fonte = Enum.Font.Gotham,
		TamanhoTexto = 10,
		ZIndex = 57,
	})

	-- ScrollFrame
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "ScrollPets"
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

	-- Cria item para cada pet
	local selecionados = State.Opcoes.PetsSelecionados

	for i, nomePet in ipairs(PETS_PLACEHOLDER) do
		local item = Instance.new("TextButton")
		item.Name = "Pet_" .. i
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

		local itemLabel = criarTexto(item, {
			Texto = nomePet,
			Cor = Colors.Branco,
			Tamanho = UDim2.new(1, -50, 1, 0),
			Posicao = UDim2.new(0, 10, 0, 0),
			Fonte = Enum.Font.Gotham,
			TamanhoTexto = 12,
			ZIndex = 58,
		})

		-- Checkbox visual
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

		-- Lógica de seleção
		local selecionado = false

		item.MouseButton1Click:Connect(function()
			if selecionado then
				-- Desmarcar
				selecionado = false
				checkMark.Visible = false
				item.BackgroundColor3 = Colors.PretoSuave
				item.BackgroundTransparency = 0.5

				-- Remove da lista
				for idx, pet in ipairs(selecionados) do
					if pet == nomePet then
						table.remove(selecionados, idx)
						break
					end
				end
			else
				-- Limite de 10
				if #selecionados >= 10 then
					print("[Hazudi] Limite de 10 pets atingido!")
					return
				end

				-- Marcar
				selecionado = true
				checkMark.Visible = true
				item.BackgroundColor3 = Colors.AzulEscuro
				item.BackgroundTransparency = 0.3

				table.insert(selecionados, nomePet)
			end

			print("[Hazudi] Pets selecionados:", #selecionados, table.concat(selecionados, ", "))
		end)
	end

	-- Ajusta canvas
	task.defer(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end)

	return container
end

-- ============================================================
-- 5. EXPORTAÇÃO
-- ============================================================

H.criarToggle = criarToggle
H.criarConteudoOpcoes = criarConteudoOpcoes
H.criarConteudoPets = criarConteudoPets

print("[Hazudi] Parte 3 carregada — Abas 'Opções' e 'Pets' (visual) definidas.")

--[[
================================================================================
  HAZUDI — SCRIPT PRINCIPAL
  Parte 4/4: Inicialização Completa e Lógica de Detecção de Servidor
================================================================================
  Esta parte contém:
  - Função de inicialização completa do Hazudi
  - Detecção de servidor privado (game.PrivateServerId)
  - Conexão do botão flutuante com a interface
  - Sistema de notificações (toast) para feedback
  - Lógica de ativação da Opção 1 (Servidor Privado)

  IMPORTANTE: A lógica de gameplay (steal, ESP, etc.) NÃO está implementada
  porque depende de RemoteEvents internos do jogo "Steal a Brainrot" que
  não estão documentados publicamente. As funções abaixo são estruturas
  que você poderá adaptar quando tiver os nomes corretos.
================================================================================
]]

-- ============================================================
-- 1. REFERÊNCIAS
-- ============================================================
local H = _G.Hazudi
local Colors = H.Colors
local State = H.State
local criarFrame = H.criarFrame
local criarTexto = H.criarTexto
local criarScreenGui = H.criarScreenGui
local criarBotaoFlutuante = H.criarBotaoFlutuante
local ativarDrag = H.ativarDrag
local animarCliqueBotao = H.animarCliqueBotao
local abrirInterface = H.abrirInterface

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- 2. SISTEMA DE NOTIFICAÇÕES (TOAST)
-- ============================================================

--- Cria uma notificação toast no topo da tela.
-- @param gui: ScreenGui onde a notificação será criada
-- @param mensagem: Texto da notificação
-- @param tipo: "sucesso", "erro", "info"
-- @param duracao: Duração em segundos
local function notificar(gui, mensagem, tipo, duracao)
	duracao = duracao or 3
	tipo = tipo or "info"

	-- Cores baseadas no tipo
	local corFundo, corBorda
	if tipo == "sucesso" then
		corFundo = Color3.fromRGB(20, 80, 40)
		corBorda = Colors.Verde
	elseif tipo == "erro" then
		corFundo = Color3.fromRGB(80, 20, 20)
		corBorda = Colors.Vermelho
	else
		corFundo = Colors.PretoSuave
		corBorda = Colors.Azul
	end

	-- Container da notificação
	local toast = criarFrame(gui, {
		Nome = "Notificacao",
		Cor = corFundo,
		Tamanho = UDim2.new(0.85, 0, 0, 50),
		Posicao = UDim2.new(0.5, 0, 0, -60),
		AnchorPoint = Vector2.new(0.5, 0),
		CantosArredondados = 10,
		Borda = { Cor = corBorda, Espessura = 1.5, Transparencia = 0.3 },
		ZIndex = 200,
	})

	-- Ícone (bolinha colorida)
	local icone = criarFrame(toast, {
		Cor = corBorda,
		Tamanho = UDim2.new(0, 10, 0, 10),
		Posicao = UDim2.new(0, 12, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		CantosArredondados = 5,
		ZIndex = 201,
	})

	-- Texto
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

	-- Animação de entrada
	local entrarInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(toast, entrarInfo, {
		Position = UDim2.new(0.5, 0, 0, 20),
	}):Play()

	-- Animação de saída e destruição
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
-- 3. DETECÇÃO DE SERVIDOR PRIVADO
-- ============================================================

--- Verifica se o jogador está em um servidor privado (VIP).
-- @return boolean, string — true se for VIP, e o tipo de servidor.
local function verificarServidorPrivado()
	-- Documentação oficial Roblox:
	-- game.PrivateServerId ~= "" → servidor privado ou reservado
	-- game.PrivateServerOwnerId ~= 0 → servidor VIP (privado real)
	-- game.PrivateServerOwnerId == 0 → servidor reservado
	-- game.PrivateServerId == "" → servidor público/standard

	local privateServerId = game.PrivateServerId
	local privateServerOwnerId = game.PrivateServerOwnerId

	if privateServerId ~= "" then
		if privateServerOwnerId ~= 0 then
			return true, "VIPServer" -- Servidor privado VIP
		else
			return true, "ReservedServer" -- Servidor reservado
		end
	else
		return false, "StandardServer" -- Servidor público
	end
end

-- ============================================================
-- 4. LÓGICA DA OPÇÃO 1: MODO SERVIDOR PRIVADO
-- ============================================================

--- Ativa ou desativa o Modo Servidor Privado.
-- @param ativado: boolean
-- @param gui: ScreenGui para notificações
local function toggleServidorPrivado(ativado, gui)
	if not ativado then
		-- Desativando
		State.Opcoes.ServidorPrivado = false
		notificar(gui, "Modo Servidor Privado desativado.", "info", 2)
		return
	end

	-- Verifica se está em servidor privado
	local ehPrivado, tipoServidor = verificarServidorPrivado()

	if not ehPrivado then
		-- Não é servidor privado → mostra erro e reverte o toggle
		State.Opcoes.ServidorPrivado = false
		notificar(
			gui,
			"❌ Esta opção só pode ser ativada em servidor privado! Você está em um servidor público.",
			"erro",
			4
		)
		print("[Hazudi] Servidor Privado negado. Tipo detectado:", tipoServidor)
		return
	end

	-- É servidor privado → ativa com sucesso
	State.Opcoes.ServidorPrivado = true
	notificar(
		gui,
		"✅ Opção ativada com sucesso! Parabéns, você está em um servidor privado.",
		"sucesso",
		4
	)
	print("[Hazudi] Servidor Privado ativado. Tipo:", tipoServidor)

	-- ============================================================
	-- [NÃO IMPLEMENTADO] Lógica de gameplay do Modo Servidor Privado
	-- ============================================================
	-- A ideia original era: "arrastar jogadores para o servidor",
	-- forçando-os a ficar presos na tela de carregamento.
	--
	-- Isso NÃO é tecnicamente viável da forma descrita, porque:
	-- 1. Não existe uma API Roblox para "arrastar" jogadores de outros servidores.
	-- 2. O script rodaria apenas no cliente local, sem autoridade sobre
	--    o teleporte de outros jogadores.
	-- 3. Mesmo com RemoteEvents, seria necessário acesso a funções de servidor
	--    que não estão expostas ao cliente.
	--
	-- Uma abordagem possível (mas ainda dependente de RemoteEvents específicos)
	-- seria detectar jogadores com pets valiosos e, se o jogo tiver um sistema
	-- de servidor privado com teleporte, usar TeleportService. Mas isso exigiria
	-- que o jogo tivesse essa funcionalidade implementada no servidor.
	--
	-- Por ora, esta opção apenas verifica o tipo de servidor e notifica o jogador.
	-- ============================================================
end

-- ============================================================
-- 5. INICIALIZAÇÃO COMPLETA
-- ============================================================

--- Inicializa o Hazudi: cria GUI, botão flutuante e conecta tudo.
local function inicializarHazudi()
	print("[Hazudi] Inicializando...")

	-- 1. Cria o ScreenGui
	local gui = criarScreenGui()
	H.Gui = gui

	-- 2. Cria o botão flutuante
	local botao = criarBotaoFlutuante(gui)
	H.Botao = botao

	-- 3. Ativa o sistema de arrastar
	ativarDrag(botao)

	-- 4. Conecta o clique do botão para abrir a interface
	botao.MouseButton1Click:Connect(function()
		animarCliqueBotao(botao, function()
			abrirInterface(gui, botao)
		end)
	end)

	-- 5. Sobrescreve o conteúdo placeholder das abas Opções e Pets
	--    (criados na Parte 2 com "carregando...")
	task.delay(0.1, function()
		if H.Janela then
			local areaConteudo = H.Janela:FindFirstChild("AreaConteudo", true)
			if areaConteudo then
				-- Remove placeholders
				local opcoesPlaceholder = areaConteudo:FindFirstChild("ConteudoOpcoes")
				if opcoesPlaceholder then
					opcoesPlaceholder:Destroy()
				end

				local petsPlaceholder = areaConteudo:FindFirstChild("ConteudoPets")
				if petsPlaceholder then
					petsPlaceholder:Destroy()
				end

				-- Cria conteúdo real
				H.criarConteudoOpcoes(areaConteudo)
				H.criarConteudoPets(areaConteudo)

				print("[Hazudi] Conteúdo das abas 'Opções' e 'Pets' carregado.")
			end
		end
	end)

	-- 6. Detecta o tipo de servidor no carregamento e mostra no console
	local ehPrivado, tipo = verificarServidorPrivado()
	print(string.format("[Hazudi] Tipo de servidor detectado: %s (Privado: %s)", tipo, tostring(ehPrivado)))

	-- 7. Notificação de boas-vindas (após pequeno delay)
	task.delay(1, function()
		notificar(
			gui,
			"Hazudi carregado! Toque na coroa para abrir.",
			"info",
			3
		)
	end)

	print("[Hazudi] Inicialização completa.")
end

-- ============================================================
-- 6. CONECTA A LÓGICA DO TOGGLE "SERVIDOR PRIVADO"
-- ============================================================

-- Aguarda a interface ser aberta para conectar o callback real
task.spawn(function()
	-- Espera até que a janela seja criada
	while not H.Janela do
		task.wait(0.5)
	end

	-- Procura o toggle na interface
	local areaConteudo = H.Janela:FindFirstChild("AreaConteudo", true)
	if areaConteudo then
		local opcoesFrame = areaConteudo:FindFirstChild("ConteudoOpcoes")
		if opcoesFrame then
			local scroll = opcoesFrame:FindFirstChild("ScrollOpcoes")
			if scroll then
				local togglePrivado = scroll:FindFirstChild("Toggle_Modo Servidor Privado")
				if togglePrivado then
					-- Reconecta o clique para usar a lógica real
					-- (O toggle visual já existe; aqui adicionamos a lógica extra)
					local botaoToggle = togglePrivado:FindFirstChild("Toggle") or togglePrivado

					-- Como o toggle já tem seu próprio sistema de estado,
					-- vamos apenas adicionar um observador para o estado global
					-- A lógica de verificação de servidor será executada
					-- sempre que o estado mudar
					print("[Hazudi] Toggle 'Servidor Privado' conectado à lógica de verificação.")

					-- Hook no callback original usando um loop de verificação
					-- (Abordagem simples para garantir compatibilidade)
					local ultimoEstado = State.Opcoes.ServidorPrivado

					task.spawn(function()
						while true do
							task.wait(0.2)
							local estadoAtual = State.Opcoes.ServidorPrivado
							if estadoAtual ~= ultimoEstado then
								ultimoEstado = estadoAtual
								toggleServidorPrivado(estadoAtual, H.Gui)
							end
						end
					end)
				end
			end
		end
	end
end)

-- ============================================================
-- 7. EXECUÇÃO
-- ============================================================

inicializarHazudi()
