
if GetLocale() ~= "ruRU" then return end

local AP = select(2, ...)

AP.L = setmetatable( {
	CONFIG_DESC = 	"Настройка параметров масштабирования AwesomePlates.\n" ..
					"Увеличьте 'nameplateDistance' для расширения дальности видимости (текущее: " .. GetCVar("nameplateDistance") .. ").\n" ..
					"   например:   /console nameplateDistance 100   затем   /reload\n\n" ..
					"Автор: |cffc41f3bKhal|r\n" ..
					"Версия: " .. AP.Version,
	CONFIG_LIMITS = "Пределы масштабирования индикаторов",
	CONFIG_MAXSCALE = "Масштаб по умолчанию",
	CONFIG_MAXSCALEENABLED = "Изменить размер по умолчанию",
	CONFIG_MAXSCALEENABLED_DESC = "Настраивает масштаб индикаторов по умолчанию на указанный множитель.",
	CONFIG_MINSCALE = "Минимальный масштаб",
	CONFIG_MINSCALE_DESC = "Определяет, насколько маленькими могут быть индикаторы на большом расстоянии. Максимальная дистанция — 100 ярдов, определяется переменной 'nameplateDistance'.",
	CONFIG_SCALENORMDIST = "Порог дистанции масштабирования",
	CONFIG_SCALENORMDIST_DESC = "Индикаторы, находящиеся ближе этой дистанции, отображаются в обычном размере. Дальше — постепенно уменьшаются.",
	CONFIG_SLIDER_FORMAT = "%.2f",
	CONFIG_SLIDERYARD_FORMAT = "%dм",
	CONFIG_TITLE = "AwesomePlates",
}, { __index = AP.L; } );
