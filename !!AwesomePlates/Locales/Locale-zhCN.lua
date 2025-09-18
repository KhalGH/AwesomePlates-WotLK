
if GetLocale() ~= "zhCN" then return end

local AP = select(2, ...)

AP.L = setmetatable( {
	CONFIG_DESC = 	"配置 AwesomePlates 缩放参数。\n" ..
					"提高 CVar 'nameplateDistance' 的值可扩展可见范围（当前值：" .. GetCVar("nameplateDistance") .. "）。\n" ..
					"   例如:   /console nameplateDistance 100   然后   /reload\n\n" ..
					"作者：|cffc41f3bKhal|r\n" ..
					"版本: " .. AP.Version,
	CONFIG_LIMITS = "姓名板缩放限制",
	CONFIG_MAXSCALE = "默认缩放",
	CONFIG_MAXSCALEENABLED = "更改默认大小",
	CONFIG_MAXSCALEENABLED_DESC = "通过该因子调整姓名板的默认大小。",
	CONFIG_MINSCALE = "最小缩放",
	CONFIG_MINSCALE_DESC = "定义在较远距离时姓名板的最小显示大小。此距离基于 'nameplateDistance' CVar，最大为100码。",
	CONFIG_SCALENORMDIST = "缩放距离阈值",
	CONFIG_SCALENORMDIST_DESC = "距离小于该值的姓名板将显示为默认大小，超过该距离则逐渐缩小。",
	CONFIG_SLIDER_FORMAT = "%.2f",
	CONFIG_SLIDERYARD_FORMAT = "%d码",
	CONFIG_TITLE = "AwesomePlates",
}, { __index = AP.L; } );
