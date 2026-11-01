-- Interface : chrono, niveau, pièces, boutique et effets à l'écran

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local sons = ReplicatedStorage:WaitForChild("Sons", 5)
local joueur = Players.LocalPlayer

local POLICE = Enum.Font.FredokaOne
local BLANC = Color3.new(1, 1, 1)
local SOMBRE = Color3.fromRGB(22, 14, 40)
local CARTE = Color3.fromRGB(45, 30, 75)
local VIOLET = Color3.fromRGB(150, 70, 255)
local LILAS = Color3.fromRGB(205, 190, 255)
local OR = Color3.fromRGB(255, 205, 60)
local VERT = Color3.fromRGB(70, 210, 110)
local ROUGE = Color3.fromRGB(240, 70, 80)

local gui = Instance.new("ScreenGui")
gui.Name = "Interface"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = joueur:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- Petits outils
----------------------------------------------------------------
local function creer(classe, props, parent)
	local o = Instance.new(classe)
	for k, v in props do
		o[k] = v
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function arrondi(o, r)
	creer("UICorner", { CornerRadius = UDim.new(0, r or 12) }, o)
end

local function bord(o, couleur, ep)
	creer("UIStroke", { Color = couleur or SOMBRE, Thickness = ep or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end

local function texte(parent, props)
	local t = creer("TextLabel", { BackgroundTransparency = 1, Font = POLICE, TextColor3 = BLANC, TextScaled = true })
	for k, v in props do
		t[k] = v
	end
	creer("UIStroke", { Color = SOMBRE, Thickness = 2 }, t)
	t.Parent = parent
	return t
end

local function panneau(parent, props)
	local f = creer("Frame", { BackgroundColor3 = SOMBRE, BackgroundTransparency = 0.12, BorderSizePixel = 0 })
	for k, v in props do
		f[k] = v
	end
	arrondi(f, 14)
	bord(f, VIOLET, 2)
	f.Parent = parent
	return f
end

local function bouton(parent, props, clic)
	local b = creer("TextButton", { Font = POLICE, TextColor3 = BLANC, TextScaled = true, BackgroundColor3 = VIOLET, BorderSizePixel = 0 })
	for k, v in props do
		b[k] = v
	end
	arrondi(b, 10)
	bord(b, SOMBRE, 2)
	creer("UIPadding", {
		PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5),
		PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
	}, b)
	b.Parent = parent
	b.Activated:Connect(clic)
	return b
end

local function nombre(n)
	local s = tostring(math.floor(n))
	local r = s:reverse():gsub("(%d%d%d)", "%1 "):reverse()
	return (r:gsub("^ ", ""))
end

local dernierPop = 0
local function jouer(nom, vitesse)
	local s = sons and sons:FindFirstChild(nom)
	if not s then
		return
	end
	local c = s:Clone()
	c.PlaybackSpeed = vitesse or 1
	c.Parent = SoundService
	c:Play()
	c.Ended:Connect(function()
		c:Destroy()
	end)
end

----------------------------------------------------------------
-- Chrono (en haut)
----------------------------------------------------------------
local chronoCadre = panneau(gui, { Size = UDim2.fromOffset(170, 64), Position = UDim2.new(0.5, 0, 0, 8), AnchorPoint = Vector2.new(0.5, 0) })
local chronoTexte = texte(chronoCadre, { Size = UDim2.new(1, -12, 0.6, 0), Position = UDim2.new(0, 6, 0, 4), Text = "0:00" })
local etatTexte = texte(chronoCadre, { Size = UDim2.new(1, -12, 0.28, 0), Position = UDim2.new(0, 6, 0.66, 0), Text = "", TextColor3 = LILAS })

----------------------------------------------------------------
-- Niveau et XP (en haut à gauche)
----------------------------------------------------------------
local nivCadre = panneau(gui, { Size = UDim2.fromOffset(250, 62), Position = UDim2.fromOffset(12, 12) })
local badge = creer("Frame", { Size = UDim2.fromOffset(50, 50), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = VIOLET }, nivCadre)
arrondi(badge, 25)
bord(badge, BLANC, 2)
local nivTexte = texte(badge, { Size = UDim2.fromScale(0.76, 0.76), Position = UDim2.fromScale(0.12, 0.12), Text = "1" })
texte(nivCadre, { Size = UDim2.fromOffset(172, 22), Position = UDim2.fromOffset(66, 6), Text = "NIVEAU", TextXAlignment = Enum.TextXAlignment.Left })
local barre = creer("Frame", { Size = UDim2.fromOffset(172, 20), Position = UDim2.fromOffset(66, 33), BackgroundColor3 = Color3.fromRGB(55, 38, 90), BorderSizePixel = 0 }, nivCadre)
arrondi(barre, 10)
local remplissage = creer("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = VERT, BorderSizePixel = 0 }, barre)
arrondi(remplissage, 10)
local xpTexte = texte(barre, { Size = UDim2.fromScale(1, 0.85), Position = UDim2.fromScale(0, 0.075), Text = "", ZIndex = 2 })

----------------------------------------------------------------
-- Pièces (sous le niveau)
----------------------------------------------------------------
local piecesCadre = panneau(gui, { Size = UDim2.fromOffset(190, 46), Position = UDim2.fromOffset(12, 82) })
local icone = creer("Frame", { Size = UDim2.fromOffset(32, 32), Position = UDim2.fromOffset(8, 7), BackgroundColor3 = OR }, piecesCadre)
arrondi(icone, 16)
bord(icone, Color3.fromRGB(170, 110, 20), 2)
texte(icone, { Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.15, 0.15), Text = "$", TextColor3 = Color3.fromRGB(255, 245, 200) })
local piecesTexte = texte(piecesCadre, { Size = UDim2.fromOffset(136, 30), Position = UDim2.fromOffset(48, 8), Text = "0", TextXAlignment = Enum.TextXAlignment.Left })

----------------------------------------------------------------
-- Taille et masse (en bas)
----------------------------------------------------------------
local tailleCadre = panneau(gui, { Size = UDim2.fromOffset(250, 58), Position = UDim2.new(0.5, 0, 1, -14), AnchorPoint = Vector2.new(0.5, 1) })
local tailleTexte = texte(tailleCadre, { Size = UDim2.new(1, -14, 0.58, 0), Position = UDim2.fromOffset(7, 4), Text = "TAILLE 7.0 m" })
local masseTexte = texte(tailleCadre, { Size = UDim2.new(1, -14, 0.3, 0), Position = UDim2.new(0, 7, 0.64, 0), Text = "Masse 0", TextColor3 = LILAS })

----------------------------------------------------------------
-- Boutique
----------------------------------------------------------------
local boutique = panneau(gui, { Size = UDim2.fromScale(0.85, 0.8), Position = UDim2.fromScale(0.5, 0.52), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 5 })
creer("UIAspectRatioConstraint", { AspectRatio = 1.15 }, boutique)
creer("UISizeConstraint", { MaxSize = Vector2.new(500, 440) }, boutique)
texte(boutique, { Size = UDim2.new(1, -90, 0.09, 0), Position = UDim2.new(0, 16, 0.025, 0), Text = "BOUTIQUE", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = OR })
bouton(boutique, { Size = UDim2.fromScale(0.09, 0.1), Position = UDim2.new(1, -10, 0.02, 0), AnchorPoint = Vector2.new(1, 0), Text = "X", BackgroundColor3 = ROUGE }, function()
	boutique.Visible = false
end)

local function page()
	return creer("ScrollingFrame", {
		Size = UDim2.new(1, -24, 0.7, 0), Position = UDim2.new(0, 12, 0.27, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
	}, boutique)
end
local pageAmel = page()
creer("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, pageAmel)
local pageSkins = page()
pageSkins.Visible = false
creer("UIGridLayout", { CellSize = UDim2.fromOffset(100, 112), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }, pageSkins)

local ongletAmel, ongletSkins
local function choisirOnglet(skins)
	pageAmel.Visible = not skins
	pageSkins.Visible = skins
	ongletAmel.BackgroundColor3 = skins and CARTE or VIOLET
	ongletSkins.BackgroundColor3 = skins and VIOLET or CARTE
end
ongletAmel = bouton(boutique, { Size = UDim2.new(0.5, -18, 0.1, 0), Position = UDim2.new(0, 12, 0.14, 0), Text = "AMÉLIORATIONS" }, function()
	choisirOnglet(false)
end)
ongletSkins = bouton(boutique, { Size = UDim2.new(0.5, -18, 0.1, 0), Position = UDim2.new(0.5, 6, 0.14, 0), Text = "SKINS", BackgroundColor3 = CARTE }, function()
	choisirOnglet(true)
end)

-- une ligne par amélioration
local lignes = {}
for i, a in Config.Ameliorations do
	local ligne = creer("Frame", { Size = UDim2.new(1, -10, 0, 74), BackgroundColor3 = CARTE, BorderSizePixel = 0, LayoutOrder = i }, pageAmel)
	arrondi(ligne, 10)
	local nom = texte(ligne, { Size = UDim2.new(0.6, 0, 0, 28), Position = UDim2.fromOffset(12, 8), Text = a.nom, TextXAlignment = Enum.TextXAlignment.Left })
	texte(ligne, { Size = UDim2.new(0.6, 0, 0, 20), Position = UDim2.fromOffset(12, 42), Text = a.desc, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = LILAS })
	local achat = bouton(ligne, { Size = UDim2.new(0.32, 0, 0, 50), Position = UDim2.new(1, -10, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Text = "", BackgroundColor3 = VERT }, function()
		remotes.Action:FireServer("acheter", a.id)
	end)
	lignes[a.id] = { def = a, nom = nom, achat = achat }
end

-- une carte par skin
local cartesSkin = {}
for i, s in Config.Skins do
	local carte = creer("TextButton", { Text = "", BackgroundColor3 = CARTE, BorderSizePixel = 0, LayoutOrder = i }, pageSkins)
	arrondi(carte, 12)
	local cercle = creer("Frame", { Size = UDim2.fromOffset(56, 56), Position = UDim2.new(0.5, 0, 0, 10), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = s.couleur }, carte)
	arrondi(cercle, 28)
	local centre = creer("Frame", { Size = UDim2.fromScale(0.68, 0.68), Position = UDim2.fromScale(0.16, 0.16), BackgroundColor3 = Color3.new(0, 0, 0) }, cercle)
	arrondi(centre, 19)
	texte(carte, { Size = UDim2.new(1, -8, 0, 20), Position = UDim2.fromOffset(4, 70), Text = s.id })
	local etat = texte(carte, { Size = UDim2.new(1, -8, 0, 16), Position = UDim2.fromOffset(4, 92), Text = "", TextColor3 = LILAS })
	carte.Activated:Connect(function()
		remotes.Action:FireServer("skin", s.id)
	end)
	cartesSkin[s.id] = { def = s, cercle = cercle, etat = etat }
end

local function majBoutique()
	local pieces = joueur:GetAttribute("Pieces") or 0
	local achetable = false
	for id, l in lignes do
		local n = joueur:GetAttribute("Amel_" .. id) or 0
		l.nom.Text = l.def.nom .. "  -  niv " .. n
		if n >= l.def.max then
			l.achat.Text = "MAX"
			l.achat.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
		else
			local prix = Config.prix(l.def, n)
			l.achat.Text = nombre(prix) .. " $"
			l.achat.BackgroundColor3 = pieces >= prix and VERT or Color3.fromRGB(110, 70, 80)
			if pieces >= prix then
				achetable = true
			end
		end
	end
	local niveau = joueur:GetAttribute("Niveau") or 1
	local actuel = joueur:GetAttribute("Skin") or "Violet"
	for id, c in cartesSkin do
		if niveau < c.def.niveau then
			c.etat.Text = "Niveau " .. c.def.niveau
			c.cercle.BackgroundTransparency = 0.7
		elseif id == actuel then
			c.etat.Text = "ÉQUIPÉ"
			c.etat.TextColor3 = VERT
			c.cercle.BackgroundTransparency = 0
		else
			c.etat.Text = "Choisir"
			c.etat.TextColor3 = LILAS
			c.cercle.BackgroundTransparency = 0
		end
	end
	return achetable
end

-- bouton qui ouvre la boutique, avec une pastille quand on peut acheter
local boutonBoutique = bouton(gui, { Size = UDim2.fromOffset(160, 54), Position = UDim2.new(1, -12, 0.45, 0), AnchorPoint = Vector2.new(1, 0.5), Text = "BOUTIQUE", BackgroundColor3 = Color3.fromRGB(255, 160, 40) }, function()
	boutique.Visible = not boutique.Visible
	majBoutique()
end)
local pastille = creer("Frame", { Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, 4, 0, -10), AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = ROUGE, Visible = false }, boutonBoutique)
arrondi(pastille, 11)
bord(pastille, BLANC, 2)
texte(pastille, { Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), Text = "!" })

----------------------------------------------------------------
-- Effets : popups, bannières
----------------------------------------------------------------
local nbPopups = 0
local function popup(txt, couleur, grand)
	if nbPopups > 12 then
		return
	end
	nbPopups += 1
	local t = texte(gui, {
		Text = txt, TextColor3 = couleur or BLANC, ZIndex = 3,
		Size = UDim2.fromOffset(grand and 340 or 170, grand and 50 or 34),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, math.random(-140, 140), 0.42, math.random(-40, 30)),
	})
	local echelle = creer("UIScale", { Scale = 0.4 }, t)
	TweenService:Create(echelle, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local monte = TweenService:Create(t, info, { Position = t.Position - UDim2.fromOffset(0, 80), TextTransparency = 1 })
	TweenService:Create(t.UIStroke, info, { Transparency = 1 }):Play()
	monte:Play()
	monte.Completed:Connect(function()
		t:Destroy()
		nbPopups -= 1
	end)
end

local function banniere(titre, sousTitre, couleur, duree)
	local f = creer("Frame", { Size = UDim2.fromOffset(560, 110), Position = UDim2.fromScale(0.5, 0.27), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 6 }, gui)
	local t = texte(f, { Size = UDim2.fromScale(1, 0.6), Text = titre, TextColor3 = couleur or OR })
	local s = texte(f, { Size = UDim2.fromScale(1, 0.3), Position = UDim2.fromScale(0, 0.66), Text = sousTitre or "" })
	local echelle = creer("UIScale", { Scale = 0.3 }, f)
	TweenService:Create(echelle, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(duree or 2.2, function()
		local info = TweenInfo.new(0.4)
		for _, x in { t, s } do
			TweenService:Create(x, info, { TextTransparency = 1 }):Play()
			TweenService:Create(x.UIStroke, info, { Transparency = 1 }):Play()
		end
		task.wait(0.45)
		f:Destroy()
	end)
end

----------------------------------------------------------------
-- Écran de fin de manche
----------------------------------------------------------------
local finCadre = panneau(gui, { Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.5, 0.52), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 8 })
creer("UIAspectRatioConstraint", { AspectRatio = 1 }, finCadre)
creer("UISizeConstraint", { MaxSize = Vector2.new(440, 440) }, finCadre)
texte(finCadre, { Size = UDim2.new(1, -20, 0.1, 0), Position = UDim2.new(0, 10, 0.03, 0), Text = "FIN DE LA MANCHE", TextColor3 = OR })
local finRang = texte(finCadre, { Size = UDim2.new(1, -20, 0.13, 0), Position = UDim2.new(0, 10, 0.14, 0), Text = "" })
local finStats = texte(finCadre, { Size = UDim2.new(1, -50, 0.26, 0), Position = UDim2.new(0, 25, 0.29, 0), Text = "", TextXAlignment = Enum.TextXAlignment.Left })
local finRecord = texte(finCadre, { Size = UDim2.new(1, -20, 0.07, 0), Position = UDim2.new(0, 10, 0.56, 0), Text = "NOUVEAU RECORD !", TextColor3 = VERT, Visible = false })
local finClassement = texte(finCadre, { Size = UDim2.new(1, -50, 0.2, 0), Position = UDim2.new(0, 25, 0.64, 0), Text = "", TextColor3 = LILAS, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top })
bouton(finCadre, { Size = UDim2.fromScale(0.5, 0.1), Position = UDim2.fromScale(0.5, 0.97), AnchorPoint = Vector2.new(0.5, 1), Text = "CONTINUER", BackgroundColor3 = VERT }, function()
	finCadre.Visible = false
end)

----------------------------------------------------------------
-- Mise à jour de l'affichage
----------------------------------------------------------------
local function majStats()
	local niv = joueur:GetAttribute("Niveau") or 1
	local xp = joueur:GetAttribute("XP") or 0
	local req = joueur:GetAttribute("XPRequis") or 200
	nivTexte.Text = tostring(niv)
	xpTexte.Text = nombre(xp) .. " / " .. nombre(req)
	TweenService:Create(remplissage, TweenInfo.new(0.2), { Size = UDim2.fromScale(math.clamp(xp / req, 0, 1), 1) }):Play()
	piecesTexte.Text = nombre(joueur:GetAttribute("Pieces") or 0)
	tailleTexte.Text = string.format("TAILLE %.1f m", joueur:GetAttribute("Diametre") or Config.TAILLE_DEPART)
	masseTexte.Text = "Masse " .. nombre(joueur:GetAttribute("Masse") or 0)
	pastille.Visible = majBoutique()
end
joueur.AttributeChanged:Connect(majStats)
majStats()

local dernierEtat
local dernierBip = -1
RunService.RenderStepped:Connect(function()
	local etat = ReplicatedStorage:GetAttribute("Etat") or "Pause"
	local reste = math.max(0, math.ceil((ReplicatedStorage:GetAttribute("Fin") or 0) - workspace:GetServerTimeNow()))
	chronoTexte.Text = string.format("%d:%02d", reste // 60, reste % 60)
	if etat == "Manche" then
		etatTexte.Text = "MANCHE"
		chronoTexte.TextColor3 = reste <= 10 and ROUGE or BLANC
		if reste <= 5 and reste > 0 and reste ~= dernierBip then
			dernierBip = reste
			jouer("Pop", 0.6)
		end
	else
		etatTexte.Text = "PROCHAINE MANCHE"
		chronoTexte.TextColor3 = OR
	end
	if etat ~= dernierEtat then
		if etat == "Manche" and dernierEtat ~= nil then
			finCadre.Visible = false
			banniere("C'EST PARTI !", "Avale tout ce qui est plus petit que toi", VERT, 2)
		end
		dernierEtat = etat
	end
end)

----------------------------------------------------------------
-- Événements envoyés par le serveur
----------------------------------------------------------------
remotes.Gain.OnClientEvent:Connect(function(nom, pieces, dore, taille)
	if dore then
		popup("OBJET DORÉ ! +" .. pieces, OR, true)
		jouer("Or")
	elseif taille and taille >= 8 then
		popup(string.upper(nom) .. " +" .. pieces, BLANC, true)
	else
		popup("+" .. pieces, Color3.fromRGB(255, 230, 120))
	end
	if os.clock() - dernierPop > 0.05 then
		dernierPop = os.clock()
		jouer("Pop", 0.85 + math.random() * 0.4)
	end
end)

remotes.Niveau.OnClientEvent:Connect(function(niveau, nouveauSkin)
	banniere("NIVEAU " .. niveau .. " !", nouveauSkin and ("Nouveau skin débloqué : " .. nouveauSkin) or "Continue comme ça !", OR, 2.5)
	jouer("Niveau")
end)

remotes.Message.OnClientEvent:Connect(function(genre, a, b)
	if genre == "quotidien" then
		banniere("RÉCOMPENSE DU JOUR", "Série de " .. a .. " jour(s) : +" .. nombre(b) .. " pièces", OR, 3.5)
		jouer("Or")
	elseif genre == "mange" then
		banniere("MIAM !", "Tu as avalé " .. a, VERT, 2)
	elseif genre == "mangePar" then
		banniere("AVALÉ !", a .. " t'a mangé", ROUGE, 2.5)
	elseif genre == "aide" then
		banniere("BIENVENUE !", "Avale les petits objets pour grandir, évite les gros trous", BLANC, 4)
	end
end)

remotes.FinManche.OnClientEvent:Connect(function(r)
	finRang.Text = "#" .. r.rang .. (r.joueurs > 1 and (" sur " .. r.joueurs) or "")
	finRang.TextColor3 = r.rang == 1 and OR or BLANC
	finStats.Text = string.format(
		"Masse : %s\nObjets avalés : %s\nPièces : +%s\nXP : +%s",
		nombre(r.masse), nombre(r.objets), nombre(r.pieces), nombre(r.xp)
	)
	finRecord.Visible = r.record
	local l = {}
	for i, c in r.classement do
		table.insert(l, i .. ". " .. c.nom .. "   " .. nombre(c.masse))
	end
	finClassement.Text = table.concat(l, "\n")
	finCadre.Visible = true
	jouer("Niveau", 0.8)
end)
