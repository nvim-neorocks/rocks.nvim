format:
	stylua -v --verify lua/rocks/

check:
	luacheck lua/
