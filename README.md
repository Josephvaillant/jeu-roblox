# Trou Noir – jeu Roblox

Projet perso de L3 Sciences du Numérique (FGES).
Le joueur incarne un trou noir qui avale une ville, grandit et devient capable d'avaler des objets de plus en plus gros.

## Le jeu

- **Manches de 2 min 30** : on démarre petit, on avale tout ce qui est plus petit que soi, classement à la fin.
- **Gravité** : les objets proches glissent et penchent vers le trou, puis tombent dedans avec la physique Roblox.
- **Taille du trou** : un objet tombe si son centre est au-dessus du trou et s'il est plus petit que le diamètre.
- **Progression sauvegardée** : niveaux et XP, pièces, record.
- **Boutique** : 4 améliorations permanentes (taille de départ, vitesse, aimant, bonus de pièces) et 7 skins de trou débloqués par niveau.
- **Objets dorés** (4 % des objets) : ×5 pièces, ×3 XP.
- **Récompense quotidienne** qui augmente avec la série de jours.
- **Multijoueur** : un trou 15 % plus gros peut avaler un autre joueur.

## Organisation du code

| Fichier | Où il va dans Roblox Studio | Rôle |
| --- | --- | --- |
| `src/shared/Config.luau` | `ReplicatedStorage` → ModuleScript `Config` | Réglages : durées, croissance, prix, skins |
| `src/server/Jeu.server.luau` | `ServerScriptService` → Script `Jeu` | Trou noir, absorption, manches, progression, sauvegarde |
| `src/client/Interface.client.luau` | `StarterPlayer.StarterPlayerScripts` → LocalScript `Interface` | Interface : chrono, niveau, pièces, boutique, effets |

Le reste est dans la place Roblox, pas dans ce dépôt :

- la ville (dossier `Workspace.Absorbable` pour les objets avalables, `Workspace.Ville` pour les routes et trottoirs) ;
- les sons (`ReplicatedStorage.Sons`) ;
- les textures de façades, routes et trottoirs (`MaterialService`) ;
- l'éclairage (`Lighting`).

Pour la sauvegarder ici aussi : dans Studio, **File → Save to File As…**, enregistrer `trou-noir.rbxl` à la racine du dépôt, puis le committer.

## Régler le jeu

Tout se règle dans `Config.luau` :

- `DUREE_MANCHE`, `DUREE_PAUSE` : durées en secondes ;
- `TAILLE_DEPART` : diamètre du trou au début ;
- `GAIN` : vitesse de croissance ;
- `Ameliorations`, `Skins`, `xpRequis`, `recompenseJour` : économie et progression.

## Pour que la sauvegarde marche dans Studio

Game Settings → Security → activer **Enable Studio Access to API Services**.

## Synchronisation avec Rojo (optionnel)

Le fichier `default.project.json` permet de synchroniser ce dossier avec Studio grâce à [Rojo](https://rojo.space), au lieu de copier-coller les scripts.
