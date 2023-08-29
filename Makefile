format:
	stylua -v --verify lua/rocks/ plugin/

check:
	luacheck lua/rocks plugin/
