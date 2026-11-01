-- Jeu : trou noir, manches, progression et sauvegarde

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local PENCHE_MAX = math.rad(25)  -- les objets attirés penchent vers le trou, jusqu'à 25°
local FORCE_ATTRACTION = 0.6
local OR = Color3.fromRGB(255, 205, 60)

----------------------------------------------------------------
-- Communication avec l'interface des joueurs
----------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local function remote(nom)
	local r = Instance.new("RemoteEvent")
	r.Name = nom
	r.Parent = remotes
	return r
end
local evGain = remote("Gain")         -- un objet avalé
local evNiveau = remote("Niveau")     -- niveau supérieur
local evFin = remote("FinManche")     -- résultats de la manche
local evMessage = remote("Message")   -- messages divers (récompense du jour, joueur avalé...)
local evAction = remote("Action")     -- le joueur achète une amélioration ou choisit un skin
remotes.Parent = ReplicatedStorage

----------------------------------------------------------------
-- Sauvegarde des joueurs
----------------------------------------------------------------
local store
pcall(function()
	store = DataStoreService:GetDataStore("TrouNoir_v1")
end)
local donnees = {} -- [joueur] = ses données sauvegardées
local gains = {}   -- [joueur] = ce qu'il a gagné pendant la manche en cours

local function defaut()
	return {
		Niveau = 1, XP = 0, Pieces = 0, Record = 0, Skin = "Violet",
		DernierJour = 0, Serie = 0,
		Amel = { Taille = 0, Vitesse = 0, Aimant = 0, Bonus = 0 },
	}
end

local function charger(player)
	local d = defaut()
	if store then
		local ok, res = pcall(function()
			return store:GetAsync("J_" .. player.UserId)
		end)
		if ok and type(res) == "table" then
			for k, v in res do
				d[k] = v
			end
			if type(d.Amel) ~= "table" then
				d.Amel = {}
			end
			for id, v in defaut().Amel do
				if d.Amel[id] == nil then
					d.Amel[id] = v
				end
			end
		elseif not ok then
			warn("[Sauvegarde] indisponible : " .. tostring(res))
		end
	end
	donnees[player] = d
end

local function sauver(player)
	local d = donnees[player]
	if store and d then
		local ok, err = pcall(function()
			store:SetAsync("J_" .. player.UserId, d)
		end)
		if not ok then
			warn("[Sauvegarde] échec : " .. tostring(err))
		end
	end
end

-- Copie les données dans les attributs du joueur (l'interface les lit)
local function publier(player)
	local d = donnees[player]
	if not d then
		return
	end
	player:SetAttribute("Niveau", d.Niveau)
	player:SetAttribute("XP", d.XP)
	player:SetAttribute("XPRequis", Config.xpRequis(d.Niveau))
	player:SetAttribute("Pieces", d.Pieces)
	player:SetAttribute("Record", d.Record)
	player:SetAttribute("Skin", d.Skin)
	for id, niv in d.Amel do
		player:SetAttribute("Amel_" .. id, niv)
	end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Niveau.Value = d.Niveau
	end
end

----------------------------------------------------------------
-- Progression
----------------------------------------------------------------
local function donnerXP(player, xp)
	local d = donnees[player]
	if not d then
		return
	end
	d.XP += xp
	local ancien = d.Niveau
	while d.XP >= Config.xpRequis(d.Niveau) do
		d.XP -= Config.xpRequis(d.Niveau)
		d.Niveau += 1
	end
	if d.Niveau > ancien then
		local nouveauSkin
		for _, s in Config.Skins do
			if s.niveau > ancien and s.niveau <= d.Niveau then
				nouveauSkin = s.id
			end
		end
		evNiveau:FireClient(player, d.Niveau, nouveauSkin)
	end
end

local function ajouterMasse(player, s)
	local m = (player:GetAttribute("Masse") or 0) + s
	player:SetAttribute("Masse", m)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Masse.Value = math.floor(m)
	end
end

local function recompenseQuotidienne(player)
	local d = donnees[player]
	local jour = math.floor(os.time() / 86400)
	if d.DernierJour == jour then
		return
	end
	if d.DernierJour == jour - 1 then
		d.Serie += 1
	else
		d.Serie = 1
	end
	d.DernierJour = jour
	local gain = Config.recompenseJour(d.Serie)
	d.Pieces += gain
	publier(player)
	task.delay(4, function()
		if player.Parent then
			evMessage:FireClient(player, "quotidien", d.Serie, gain)
		end
	end)
end

----------------------------------------------------------------
-- La ville (reconstruite à chaque manche)
----------------------------------------------------------------
local dossier = workspace:WaitForChild("Absorbable")
local enChute = Instance.new("Folder")
enChute.Name = "EnChute"
enChute.Parent = workspace

-- copie intacte de la ville, prise au lancement du jeu
local modeleVille = dossier:Clone()
modeleVille.Name = "VilleModele"
modeleVille.Parent = ServerStorage

-- Objet doré : brille, rapporte 5x plus de pièces et 3x plus d'XP
local function rendreDore(m)
	m:SetAttribute("Dore", true)
	local base = m.PrimaryPart
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(OR)
	e.LightEmission = 1
	e.Size = NumberSequence.new(0.9, 0)
	e.Rate = 10
	e.Lifetime = NumberRange.new(1, 1.6)
	e.Speed = NumberRange.new(1, 3)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Parent = base
	local l = Instance.new("PointLight")
	l.Color = OR
	l.Range = math.min(10 + (m:GetAttribute("Taille") or 4), 30)
	l.Brightness = 2.5
	l.Shadows = false
	l.Parent = base
end

local function ajouterDores()
	for _, m in dossier:GetChildren() do
		if m.PrimaryPart and math.random() < 0.04 then
			rendreDore(m)
		end
	end
end

local function regenererVille()
	dossier:ClearAllChildren()
	enChute:ClearAllChildren()
	for i, m in modeleVille:GetChildren() do
		m:Clone().Parent = dossier
		if i % 60 == 0 then
			task.wait()
		end
	end
	ajouterDores()
end

----------------------------------------------------------------
-- Le trou noir
----------------------------------------------------------------
local function cacher(objet)
	if objet:GetAttribute("PartieTrou") then
		return
	end
	if objet:IsA("BasePart") or objet:IsA("Decal") then
		objet.Transparency = 1
	end
end

local function nouvellePiece(nom, couleur, matiere, transparence)
	local p = Instance.new("Part")
	p.Name = nom
	p.Shape = Enum.PartType.Cylinder
	p.Color = couleur
	p.Material = matiere
	p.Transparency = transparence or 0
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
	p:SetAttribute("PartieTrou", true)
	return p
end

local function dimensionner(trou, d)
	trou:SetAttribute("Diametre", d)
	trou.Size = Vector3.new(0.2, d, d)
	trou.Anneau.Size = Vector3.new(0.14, d * 1.12, d * 1.12)
	trou.Halo.Size = Vector3.new(0.06, d * 1.6, d * 1.6)
	trou.Aspiration.Size = Vector3.new(d * 1.7, 0.5, d * 1.7)
	trou.Aspiration.Particules.Speed = NumberRange.new(d * 0.75)
	trou.Aspiration.Particules.Rate = 40 + d * 3
	trou.Lumiere.Range = math.min(d * 1.5, 60)
end

local function appliquerSkin(trou, couleur)
	trou.Anneau.Color = couleur
	trou.Halo.Color = couleur:Lerp(Color3.new(0, 0, 0), 0.7)
	trou.Aspiration.Particules.Color = ColorSequence.new(Color3.fromRGB(255, 170, 90), couleur)
	trou.Lumiere.Color = couleur
end

local function vitesse(player, d)
	local data = donnees[player]
	return 16 + 1.5 * (data and data.Amel.Vitesse or 0) + d * 0.25
end

local function creerTrou(player, character)
	-- on attend les données du joueur et son avatar
	while not donnees[player] and player.Parent do
		task.wait()
	end
	if not player:HasAppearanceLoaded() then
		player.CharacterAppearanceLoaded:Wait()
	end
	if character.Parent == nil then
		return
	end

	local humanoid = character:WaitForChild("Humanoid")
	local racine = character:WaitForChild("HumanoidRootPart")
	local data = donnees[player]
	local depart = Config.TAILLE_DEPART + (data and data.Amel.Taille or 0)

	-- le perso devient invisible : on ne voit que le trou
	for _, objet in character:GetDescendants() do
		cacher(objet)
	end
	character.DescendantAdded:Connect(cacher)
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	local hauteur = humanoid.HipHeight + racine.Size.Y / 2
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		hauteur = 3
	end
	local sol = racine.CFrame * CFrame.new(0, -hauteur, 0)
	local aplat = CFrame.Angles(0, 0, math.rad(90))

	local trou = nouvellePiece("Trou", Color3.fromRGB(4, 0, 10), Enum.Material.SmoothPlastic)
	trou.CFrame = sol * CFrame.new(0, 0.1, 0) * aplat

	local anneau = nouvellePiece("Anneau", Color3.new(1, 1, 1), Enum.Material.Neon)
	anneau.CFrame = sol * CFrame.new(0, 0.07, 0) * aplat
	anneau.Parent = trou

	local halo = nouvellePiece("Halo", Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, 0.35)
	halo.CFrame = sol * CFrame.new(0, 0.035, 0) * aplat
	halo.Parent = trou

	local aspi = nouvellePiece("Aspiration", Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, 1)
	aspi.Shape = Enum.PartType.Block
	aspi.CFrame = sol * CFrame.new(0, 0.35, 0)
	aspi.Parent = trou

	local particules = Instance.new("ParticleEmitter")
	particules.Name = "Particules"
	particules.Shape = Enum.ParticleEmitterShape.Cylinder
	particules.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	particules.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
	particules.EmissionDirection = Enum.NormalId.Top
	particules.Lifetime = NumberRange.new(0.9, 1)
	particules.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0.1) })
	particules.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	particules.LightEmission = 1
	particules.Rotation = NumberRange.new(0, 360)
	particules.RotSpeed = NumberRange.new(-180, 180)
	particules.Parent = aspi

	local lumiere = Instance.new("PointLight")
	lumiere.Name = "Lumiere"
	lumiere.Brightness = 1.2
	lumiere.Shadows = false
	lumiere.Parent = trou

	for _, partie in { trou, anneau, halo, aspi } do
		local soudure = Instance.new("WeldConstraint")
		soudure.Part0 = racine
		soudure.Part1 = partie
		soudure.Parent = partie
	end

	appliquerSkin(trou, Config.skin(data and data.Skin).couleur)
	dimensionner(trou, depart)
	trou.Parent = character

	player:SetAttribute("Diametre", depart)
	humanoid.WalkSpeed = vitesse(player, depart)
	player.CameraMinZoomDistance = math.min(depart * 1.2, 300)
end

local function grandir(player, trou, surface)
	local d = math.sqrt(trou:GetAttribute("Diametre") ^ 2 + surface)
	dimensionner(trou, d)
	player:SetAttribute("Diametre", d)
	local hum = player.Character and player.Character:FindFirstChild("Humanoid")
	if hum then
		hum.WalkSpeed = vitesse(player, d)
	end
	-- la caméra recule toute seule quand le trou grandit
	player.CameraMinZoomDistance = math.min(d * 1.2, 300)
	player.CameraMaxZoomDistance = math.max(400, d * 3)
end

----------------------------------------------------------------
-- Gravité et absorption
----------------------------------------------------------------
local penche = {} -- angle déjà penché pour chaque objet attiré
local enManche = false

-- l'objet glisse vers le trou et penche vers lui
local function attirer(m, centre, d, distance, dt, zone)
	local pivot = m:GetPivot()
	local vers = Vector3.new(centre.X - pivot.X, 0, centre.Z - pivot.Z)
	if vers.Magnitude < 0.01 then
		return
	end
	local dir = vers.Unit
	local proximite = 1 - distance / (d / 2 * zone)
	local cf = pivot + dir * d * FORCE_ATTRACTION * proximite * dt
	local deja = penche[m] or 0
	if deja < PENCHE_MAX then
		local angle = math.rad(60) * dt
		cf = CFrame.fromAxisAngle(Vector3.yAxis:Cross(dir), angle) * cf.Rotation + cf.Position
		penche[m] = deja + angle
	end
	m:PivotTo(cf)
end

-- l'objet tombe dans le trou (vraie physique), le joueur gagne masse, pièces et XP
local function absorber(player, m, trou)
	penche[m] = nil
	local taille = m:GetAttribute("Taille") or 1
	local dore = m:GetAttribute("Dore") == true
	local centre = trou.Position
	m.Parent = enChute

	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
		end
	end
	local base = m.PrimaryPart
	local vers = Vector3.new(centre.X - base.Position.X, 0, centre.Z - base.Position.Z)
	base.AssemblyLinearVelocity = vers * 1.5 + Vector3.new(0, -8, 0)
	base.AssemblyAngularVelocity = Vector3.new(math.random() * 4 - 2, math.random() * 6 - 3, math.random() * 4 - 2)
	Debris:AddItem(m, 4)

	local surface = taille ^ 2 * Config.GAIN
	grandir(player, trou, surface)
	ajouterMasse(player, surface)

	local data = donnees[player]
	local bonus = 1 + 0.1 * (data and data.Amel.Bonus or 0)
	local pieces = math.max(1, math.floor(taille * bonus * (dore and 5 or 1) + 0.5))
	local xp = math.max(1, math.floor(surface * (dore and 3 or 1)))
	if data then
		data.Pieces += pieces
	end
	donnerXP(player, xp)
	local g = gains[player]
	if g then
		g.pieces += pieces
		g.xp += xp
		g.objets += 1
	end
	publier(player)
	evGain:FireClient(player, m.Name, pieces, dore, taille)
end

-- un gros trou avale un trou plus petit
local function mangerJoueur(chasseur, proie, trouChasseur, trouProie)
	local surface = trouProie:GetAttribute("Diametre") ^ 2 * 0.5 + (proie:GetAttribute("Masse") or 0) * 0.2
	trouProie:Destroy()
	grandir(chasseur, trouChasseur, surface)
	ajouterMasse(chasseur, surface)
	local xp = math.floor(surface)
	local data = donnees[chasseur]
	if data then
		data.Pieces += 50
	end
	donnerXP(chasseur, xp)
	local g = gains[chasseur]
	if g then
		g.pieces += 50
		g.xp += xp
	end
	publier(chasseur)
	evMessage:FireClient(chasseur, "mange", proie.DisplayName)
	evMessage:FireClient(proie, "mangePar", chasseur.DisplayName)
	task.delay(2, function()
		if proie.Parent then
			proie:LoadCharacter()
		end
	end)
end

RunService.Heartbeat:Connect(function(dt)
	if not enManche then
		return
	end
	local trous = {}
	for _, player in Players:GetPlayers() do
		local c = player.Character
		local trou = c and c:FindFirstChild("Trou")
		if trou then
			table.insert(trous, { player = player, trou = trou })
		end
	end

	-- objets de la ville
	for _, t in trous do
		local player, trou = t.player, t.trou
		local d = trou:GetAttribute("Diametre")
		local rayon = d / 2
		local centre = trou.Position
		local data = donnees[player]
		local zone = 2 + 0.15 * (data and data.Amel.Aimant or 0)
		for _, m in dossier:GetChildren() do
			local taille = m:GetAttribute("Taille")
			-- l'objet doit tenir dans le trou
			if taille and taille < d and m.PrimaryPart then
				local pos = m.PrimaryPart.Position
				local distance = Vector2.new(pos.X - centre.X, pos.Z - centre.Z).Magnitude
				if distance < rayon then
					-- son centre est au-dessus du trou : il tombe
					absorber(player, m, trou)
				elseif distance < rayon * zone then
					attirer(m, centre, d, distance, dt, zone)
				end
			end
		end
	end

	-- joueurs qui se mangent entre eux
	for _, a in trous do
		for _, b in trous do
			if a ~= b and a.trou.Parent and b.trou.Parent then
				local da, db = a.trou:GetAttribute("Diametre"), b.trou:GetAttribute("Diametre")
				if da > db * 1.15 then
					local pa, pb = a.trou.Position, b.trou.Position
					if Vector2.new(pa.X - pb.X, pa.Z - pb.Z).Magnitude < da / 2 * 0.8 then
						mangerJoueur(a.player, b.player, a.trou, b.trou)
					end
				end
			end
		end
	end
end)

----------------------------------------------------------------
-- Boutique (améliorations et skins)
----------------------------------------------------------------
evAction.OnServerEvent:Connect(function(player, genre, id)
	local d = donnees[player]
	if not d or typeof(genre) ~= "string" or typeof(id) ~= "string" then
		return
	end
	if genre == "acheter" then
		for _, a in Config.Ameliorations do
			if a.id == id then
				local niv = d.Amel[id] or 0
				local prix = Config.prix(a, niv)
				if niv < a.max and d.Pieces >= prix then
					d.Pieces -= prix
					d.Amel[id] = niv + 1
					publier(player)
					-- la vitesse s'applique tout de suite
					local hum = player.Character and player.Character:FindFirstChild("Humanoid")
					if hum then
						hum.WalkSpeed = vitesse(player, player:GetAttribute("Diametre") or Config.TAILLE_DEPART)
					end
				end
			end
		end
	elseif genre == "skin" then
		local s = Config.skin(id)
		if s.id == id and d.Niveau >= s.niveau then
			d.Skin = id
			publier(player)
			local trou = player.Character and player.Character:FindFirstChild("Trou")
			if trou then
				appliquerSkin(trou, s.couleur)
			end
		end
	end
end)

----------------------------------------------------------------
-- Arrivée et départ des joueurs
----------------------------------------------------------------
local function arrivee(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local masse = Instance.new("IntValue")
	masse.Name = "Masse"
	masse.Parent = ls
	local niv = Instance.new("IntValue")
	niv.Name = "Niveau"
	niv.Parent = ls
	ls.Parent = player

	player:SetAttribute("Masse", 0)
	gains[player] = { pieces = 0, xp = 0, objets = 0 }
	player.CameraMaxZoomDistance = 400
	player.CharacterAdded:Connect(function(character)
		creerTrou(player, character)
	end)
	if player.Character then
		task.spawn(creerTrou, player, player.Character)
	end

	charger(player)
	publier(player)
	local nouveau = donnees[player].Niveau == 1 and donnees[player].XP == 0
	recompenseQuotidienne(player)
	if nouveau then
		task.delay(1.5, function()
			if player.Parent then
				evMessage:FireClient(player, "aide")
			end
		end)
	end
end

Players.PlayerAdded:Connect(arrivee)
for _, p in Players:GetPlayers() do
	task.spawn(arrivee, p)
end

Players.PlayerRemoving:Connect(function(player)
	sauver(player)
	donnees[player] = nil
	gains[player] = nil
end)

game:BindToClose(function()
	for _, p in Players:GetPlayers() do
		sauver(p)
	end
end)

----------------------------------------------------------------
-- Les manches
----------------------------------------------------------------
local function lancerManche()
	for _, p in Players:GetPlayers() do
		p:SetAttribute("Masse", 0)
		local ls = p:FindFirstChild("leaderstats")
		if ls then
			ls.Masse.Value = 0
		end
		gains[p] = { pieces = 0, xp = 0, objets = 0 }
		task.spawn(function()
			p:LoadCharacter()
		end)
	end
	enManche = true
end

local function finirManche()
	enManche = false
	local liste = Players:GetPlayers()
	table.sort(liste, function(a, b)
		return (a:GetAttribute("Masse") or 0) > (b:GetAttribute("Masse") or 0)
	end)
	local classement = {}
	for i, p in liste do
		if i <= 5 then
			table.insert(classement, { nom = p.DisplayName, masse = math.floor(p:GetAttribute("Masse") or 0) })
		end
	end
	for i, p in liste do
		local d = donnees[p]
		local masse = math.floor(p:GetAttribute("Masse") or 0)
		local bonus = ({ 200, 100, 50 })[i] or 20
		local record = false
		if d then
			d.Pieces += bonus
			if masse > d.Record then
				d.Record = masse
				record = true
			end
			publier(p)
		end
		local g = gains[p] or { pieces = 0, xp = 0, objets = 0 }
		evFin:FireClient(p, {
			rang = i, joueurs = #liste, masse = masse, objets = g.objets,
			pieces = g.pieces + bonus, xp = g.xp, record = record, classement = classement,
		})
		task.spawn(sauver, p)
	end
end

task.spawn(function()
	local premiere = true
	while true do
		local duree = premiere and 3 or Config.DUREE_PAUSE
		ReplicatedStorage:SetAttribute("Etat", "Pause")
		ReplicatedStorage:SetAttribute("Fin", workspace:GetServerTimeNow() + duree)
		local debut = os.clock()
		if premiere then
			ajouterDores()
		else
			regenererVille()
		end
		premiere = false
		task.wait(math.max(0, duree - (os.clock() - debut)))

		lancerManche()
		ReplicatedStorage:SetAttribute("Etat", "Manche")
		ReplicatedStorage:SetAttribute("Fin", workspace:GetServerTimeNow() + Config.DUREE_MANCHE)
		task.wait(Config.DUREE_MANCHE)
		finirManche()
	end
end)
