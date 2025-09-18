
if GetLocale() ~= "deDE" then return end

local AP = select(2, ...)

AP.L = setmetatable( {
	CONFIG_DESC = 	"Konfiguriere die Skalierungsparameter von AwesomePlates.\n" ..
					"Erhöhe den 'nameplateDistance'-CVar, um die Sichtweite zu erweitern (aktueller Wert: " .. GetCVar("nameplateDistance") .. ").\n" ..
					"   z.B.:   /console nameplateDistance 100   dann   /reload\n\n" ..
					"Autor: |cffc41f3bKhal|r\n" ..
					"Version: " .. AP.Version,
	CONFIG_LIMITS = "Grenzen der Nameplate-Skalierung",
	CONFIG_MAXSCALE = "Standardgröße",
	CONFIG_MAXSCALEENABLED = "Standardgröße ändern",
	CONFIG_MAXSCALEENABLED_DESC = "Passt die Standardgröße der Nameplates um diesen Faktor an.",
	CONFIG_MINSCALE = "Minimale Skalierung",
	CONFIG_MINSCALE_DESC = "Legt fest, wie klein Nameplates auf große Entfernungen werden können. Die maximale Entfernung beträgt 100 Meter und wird durch den CVar 'nameplateDistance' bestimmt.",
	CONFIG_SCALENORMDIST = "Abstand für Skalierungsschwelle",
	CONFIG_SCALENORMDIST_DESC = "Nameplates, die näher als dieser Abstand sind, werden in Standardgröße angezeigt. Darüber hinaus schrumpfen sie allmählich.",
	CONFIG_SLIDER_FORMAT = "%.2f",
	CONFIG_SLIDERYARD_FORMAT = "%dm",
	CONFIG_TITLE = "AwesomePlates",
}, { __index = AP.L; } );
