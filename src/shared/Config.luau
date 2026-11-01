-- Config : réglages partagés entre le serveur et l'interface
local Config = {}

Config.DUREE_MANCHE = 150 -- secondes
Config.DUREE_PAUSE = 12   -- pause entre deux manches
Config.TAILLE_DEPART = 7  -- diamètre du trou au début d'une manche
Config.GAIN = 0.5         -- la surface du trou augmente de (taille de l'objet)² x GAIN

-- Améliorations permanentes (achetées avec les pièces)
Config.Ameliorations = {
	{ id = "Taille", nom = "Taille de départ", desc = "+1 de diamètre au début de chaque manche", prixBase = 60, max = 20 },
	{ id = "Vitesse", nom = "Vitesse", desc = "Tu te déplaces plus vite", prixBase = 45, max = 20 },
	{ id = "Aimant", nom = "Aimant", desc = "Attire les objets de plus loin", prixBase = 80, max = 15 },
	{ id = "Bonus", nom = "Bonus de pièces", desc = "+10 % de pièces par objet", prixBase = 120, max = 20 },
}

function Config.prix(amel, niveau)
	return math.floor(amel.prixBase * 1.6 ^ niveau)
end

-- XP nécessaire pour passer au niveau suivant
function Config.xpRequis(niveau)
	return math.floor(200 * niveau ^ 1.45)
end

-- Skins du trou, débloqués par niveau
Config.Skins = {
	{ id = "Violet", niveau = 1, couleur = Color3.fromRGB(150, 70, 255) },
	{ id = "Cyan", niveau = 3, couleur = Color3.fromRGB(40, 200, 255) },
	{ id = "Vert", niveau = 5, couleur = Color3.fromRGB(60, 255, 120) },
	{ id = "Rouge", niveau = 8, couleur = Color3.fromRGB(255, 50, 60) },
	{ id = "Or", niveau = 12, couleur = Color3.fromRGB(255, 195, 40) },
	{ id = "Rose", niveau = 16, couleur = Color3.fromRGB(255, 80, 200) },
	{ id = "Blanc", niveau = 20, couleur = Color3.fromRGB(235, 240, 255) },
}

function Config.skin(id)
	for _, s in Config.Skins do
		if s.id == id then
			return s
		end
	end
	return Config.Skins[1]
end

-- Récompense quotidienne : 100 pièces le 1er jour, +50 par jour de série (jusqu'à 7 jours)
function Config.recompenseJour(serie)
	return 100 + 50 * (math.min(serie, 7) - 1)
end

return Config
