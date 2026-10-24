fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'bd_sampchat'
author 'eugene'
description 'SA:MP style chat with proximity roleplay, staff and advert commands'
version '1.0.0'

provide 'chat'

ox_libs { 'locale' }

ui_page 'web/dist/index.html'

shared_script '@ox_lib/init.lua'

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

files {
    'config/shared.lua',
    'shared/*.lua',
    'locales/*.json',
    'web/dist/index.html',
    'web/dist/assets/*'
}
