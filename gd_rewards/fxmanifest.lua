fx_version "cerulean"
game "gta5"

author "Ghost Developments"
description "Basic Daily Reward System For Male And Females"
version "1.0.0"

shared_scripts {
    "@ox_lib/init.lua",
    "config.lua",
}

client_scripts {
    "client/main.lua",
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/main.lua",
}

ui_page "html/ui.html"

files {
    "html/ui.html",
    "html/style.css",
    "html/script.js",
}

lua54 "yes"
