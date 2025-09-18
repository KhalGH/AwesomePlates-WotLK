
if GetLocale() ~= "frFR" then return end

local AP = select(2, ...)

AP.L = setmetatable( {
	CONFIG_DESC = 	"Configurez les paramètres de mise à l’échelle d’AwesomePlates.\n" ..
					"Augmentez la variable CVar 'nameplateDistance' pour étendre la portée de visibilité (valeur actuelle : " .. GetCVar("nameplateDistance") .. ").\n" ..
					"   par ex.:   /console nameplateDistance 100   puis   /reload\n\n" ..
					"Auteur : |cffc41f3bKhal|r\n" ..
					"Version: " .. AP.Version,
	CONFIG_LIMITS = "Limites d'échelle des barres de nom",
	CONFIG_MAXSCALE = "Échelle par défaut",
	CONFIG_MAXSCALEENABLED = "Modifier la taille par défaut",
	CONFIG_MAXSCALEENABLED_DESC = "Ajuste la taille par défaut des barres de nom selon ce facteur.",
	CONFIG_MINSCALE = "Échelle minimale",
	CONFIG_MINSCALE_DESC = "Définit la taille minimale des barres de nom à longue distance. La distance utilisée pour l’échelle minimale est basée sur la CVar 'nameplateDistance', plafonnée à 100 yards.",
	CONFIG_SCALENORMDIST = "Seuil de distance pour la mise à l'échelle",
	CONFIG_SCALENORMDIST_DESC = "Les barres de nom plus proches que cette distance s'affichent à taille normale. Au-delà, elles rétrécissent progressivement.",
	CONFIG_SLIDER_FORMAT = "%.2f",
	CONFIG_SLIDERYARD_FORMAT = "%dm",
	CONFIG_TITLE = "AwesomePlates",
}, { __index = AP.L; } );
