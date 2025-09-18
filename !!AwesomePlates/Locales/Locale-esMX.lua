
if GetLocale() ~= "esMX" then return end

local AP = select(2, ...)

AP.L = setmetatable( {
	CONFIG_DESC = 	"Configura los parámetros de escalado de AwesomePlates.\n" ..
					"Aumenta el CVar 'nameplateDistance' para extender el rango de visibilidad (valor actual: " .. GetCVar("nameplateDistance") .. ").\n" ..
					"   p.ej.:   /console nameplateDistance 100   luego   /reload\n\n" ..
					"Autor: |cffc41f3bKhal|r\n" ..
					"Versión: " .. AP.Version,
	CONFIG_LIMITS = "Límites de Escalado de Nameplates",
	CONFIG_MAXSCALE = "Escala por defecto",
	CONFIG_MAXSCALEENABLED = "Cambiar el tamaño por defecto",
	CONFIG_MAXSCALEENABLED_DESC = "Ajusta el tamaño por defecto de los nameplates usando este factor",
	CONFIG_MINSCALE = "Escala Mínima",
	CONFIG_MINSCALE_DESC = "Define la escala mínima para nameplates a grandes distancias. La distancia asociada a la escala mínima es el CVar 'nameplateDistance' con un cap de 100 m.",
	CONFIG_SCALENORMDIST = "Distancia Umbral de Escalado",
	CONFIG_SCALENORMDIST_DESC = "Los nameplates más cercanos que esta distancia se mostrarán con su tamaño por defecto, y se reducirán gradualmente a medida que aumente la distancia por encima del umbral.",
	CONFIG_SLIDER_FORMAT = "%.2f",
	CONFIG_SLIDERYARD_FORMAT = "%dm",
	CONFIG_TITLE = "AwesomePlates",
}, { __index = AP.L; } );
