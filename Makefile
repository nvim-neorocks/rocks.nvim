format:
	stylua -v --verify lua/rocks/ plugin/ installer.lua

check:
	luacheck lua/rocks plugin/ installer.lua

test-offline:
	NVIM_APPNAME=rocks-nvim-test busted -t online spec

docgen:
	mkdir -p doc
	vimcats lua/rocks/{init,commands,config/init,meta,api/{init,hooks},log}.lua > doc/rocks.txt

