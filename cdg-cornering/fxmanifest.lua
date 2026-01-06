fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'cdg-cornering'
author 'CodyDaGrizz'
description 'Cornering / street dealing (anywhere) for QBOX + ox_lib + ox_target + ox_inventory'
version '1.1.0'

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua',
}

client_scripts {
  'client/main.lua',
}

server_scripts {
  'server/main.lua',
}

ui_page 'web/index.html'

files {
  'web/index.html',
  'web/style.css',
  'web/app.js',
  'web/assets/*',
}

dependencies {
  'ox_lib',
  'ox_target',
  'ox_inventory',
  'qbx_core'
}
