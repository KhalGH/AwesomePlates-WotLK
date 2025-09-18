local AddonName, AP = ...
AP.Version = GetAddOnMetadata(AddonName, "Version"):match("^([%d.]+)")

AP.L = setmetatable( {
	CONFIG_DESC = 	"Configure AwesomePlates scaling parameters.\n" ..
					"Increase 'nameplateDistance' CVar to extend visibility range (current value: " .. GetCVar("nameplateDistance") .. ").\n" ..
					"   e.g.:   /console nameplateDistance 100   then   /reload\n\n" ..
					"Author: |cffc41f3bKhal|r\n" ..
					"Version: " .. AP.Version,
	CONFIG_LIMITS = "Nameplate Scale Limits",
	CONFIG_MAXSCALE = "Default Scale",
	CONFIG_MAXSCALEENABLED = "Change default size",
	CONFIG_MAXSCALEENABLED_DESC = "Adjusts the default nameplate size by this factor.",
	CONFIG_MINSCALE = "Minimum Scale",
	CONFIG_MINSCALE_DESC = "Defines how small nameplates can appear at long distances. The distance used for the minimum scale is based on the 'nameplateDistance' CVar, capped at 100 yds.",
	CONFIG_SCALENORMDIST = "Scaling Distance Threshold",
	CONFIG_SCALENORMDIST_DESC = "Nameplates closer than this distance show at default size. Beyond it, they gradually shrink.",
	CONFIG_SLIDER_FORMAT = "%.2f",
	CONFIG_SLIDERYARD_FORMAT = "%dyd",
	CONFIG_TITLE = "AwesomePlates",
}, {
	__index = function ( self, Key )
		if ( Key ~= nil ) then
			rawset( self, Key, Key );
			return Key;
		end
	end;
} );
