fx_version "adamant"
games {"rdr3"}
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

version "0.1.0"

client_scripts {
	"client/client.lua",
	"client/nui.lua",
	"client/props.lua",
	"client/npc.lua",
	"client/proptest.lua",
}

server_scripts {
	"server/framework.lua",
	"server/npc.lua",
	"server/server.lua",
	"server/sv_command.lua",
	"server/proptest.lua",
	"@oxmysql/lib/MySQL.lua",
}

shared_scripts {
	"config.lua",
	"configNPC.lua",
	"configProps.lua",
	"configproptest.lua",
	"shared/*.lua",
	"shared/**/*.lua",
}

files {
	"ui/dist/*",
	"ui/dist/**/*",
	"ui/dist/img/card/*",
	"ui/public/*",
	"ui/public/**/*",
  }
ui_page "ui/dist/index.html"


author 'Nubetastic'
description 'License: GPL-3.0-only'
