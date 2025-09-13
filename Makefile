# TODO(vhyrro): Change to use `lx` commands
format:
	stylua -v --verify lua/rocks/ plugin/ installer.lua

check:
	luacheck lua/rocks plugin/ installer.lua

docgen:
	mkdir -p doc
	vimcats lua/rocks/{init,commands,config/init,meta,api/{init,hooks},log}.lua > doc/rocks.txt

