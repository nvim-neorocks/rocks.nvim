format:
	stylua -v --verify lua/rocks/ plugin/ installer.lua

check:
	luacheck lua/rocks plugin/ installer.lua

docgen:
	docgen
