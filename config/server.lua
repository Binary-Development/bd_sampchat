return {
    -- Which framework you run. Leave it on 'auto' and it gets detected.
    -- Options: 'auto', 'esx', 'qbcore', 'qbox', 'ox', 'nd', 'standalone'
    framework = 'auto',

    -- Seconds a player has to wait between messages. Stops chat spam.
    cooldown = 1.0,

    -- Blocks the same message being sent over and over.
    -- duplicateLimit: how many times in a row the same message can be sent. 0 turns this off.
    -- duplicateWindow: seconds until the same message counts as new again.
    duplicateLimit = 2,
    duplicateWindow = 60,

    -- Longest /chatmute staff can give, in minutes. Mutes stay through reconnects and restarts.
    maxMuteMinutes = 1440,

    -- Messages with any of these words are blocked and the player is told why.
    -- Matching ignores case, only matches whole words, and catches swaps like 4 for a or 0 for o.
    blockedWords = {
        'nigger', 'nigga', 'faggot', 'fag', 'retard', 'kys'
    },

    -- Staff ranks, highest first. group is the ace group from your server.cfg.
    -- 'admin' means group.admin, which ESX, Qbox, ox_core and txAdmin use.
    -- QBCore uses its own names, write the full name there, like 'qbcore.admin' or 'qbcore.god'.
    -- color is used for the rank name in chat. tester = true puts the rank in /testers instead of /admins.
    ranks = {
        { group = 'owner', label = 'Owner', color = '#FFFFFF' },
        { group = 'management', label = 'Management', color = '#F26BE8' },
        { group = 'admin', label = 'Administrator', color = '#D52727' },
        { group = 'moderator', label = 'Moderator', color = '#30B150' },
        { group = 'tester', label = 'Tester', color = '#33CCFF', tester = true },
    },

    -- Colors for system lines (errors, PMs, dice, staff notices).
    colors = {
        info = '#AFAFAF',
        error = '#FF6347',
        success = '#33AA33',
        pm = '#FCF545',
        games = '#FFFF91',
        staff = '#FF6347',
        action = '#C2A2DA'
    },

    -- Local chat. Only players within range (meters) see these.
    -- default = true: what a message without a command goes to.
    -- togsDefault = true: what a message without a command goes to after /togs.
    -- ooc = true: always shows the real character name, even with /maskname on.
    -- Placeholders: {name} character name, {player} FiveM name, {id} server id, {message}
    proximity = {
        { commands = { 'b' }, help = 'Local out of character chat', range = 20.0, color = '#B4AFC2', format = '(( [{id}] {player} [{name}]: {message} ))', default = true, ooc = true },
        { commands = { 'say', 's' }, help = 'Say something', range = 15.0, color = '#FFFFFF', format = '{name} says: {message}', togsDefault = true },
        { commands = { 'low', 'l' }, help = 'Say something quietly', range = 5.0, color = '#B4AFC2', format = '{name} [low] says: {message}' },
        { commands = { 'whisper', 'w' }, help = 'Whisper to players right next to you', range = 2.0, color = '#FCF545', format = '{name} whispers: {message}' },
        { commands = { 'shout', 'sh' }, help = 'Shout something', range = 30.0, color = '#FFFFFF', format = '{name} shouts: {message}' },
        { commands = { 'me' }, help = 'Describe an action', range = 15.0, color = '#C2A2DA', format = '* {name} {message}' },
        { commands = { 'melow' }, help = 'Describe an action quietly', range = 5.0, color = '#C2A2DA', format = '* {name} {message}' },
        { commands = { 'my' }, help = 'Describe something of yours', range = 15.0, color = '#C2A2DA', format = "* {name}'s {message}" },
        { commands = { 'do' }, help = 'Describe the scene', range = 20.0, color = '#C2A2DA', format = '* {message} (( {name} ))' },
    },

    -- Text above your head. It also shows in your own chat.
    actions = {
        range = 10.0,
        commands = {
            { command = 'ame', help = 'Show an action above your head', format = '* {name} {message}' },
            { command = 'amy', help = 'Show something of yours above your head', format = "* {name}'s {message}" },
        }
    },

    -- Paid adverts everyone sees.
    -- cost is in dollars (0 = free), cooldown is in seconds per player.
    -- allowedJobs: only these jobs can post. Leave empty to let every job post.
    -- blockedJobs: these jobs can never post.
    -- Placeholders: {name}, {id}, {job} job label, {message}
    adverts = {
        { command = 'ad', help = 'Post an advertisement', cost = 1000, cooldown = 60, color = '#FFD818', format = '[Advertisement] {name} ({id}): {message}', allowedJobs = {}, blockedJobs = { 'unemployed' } },
        { command = 'businessad', help = 'Post a business advertisement', cost = 1000, cooldown = 60, color = '#2ECC71', format = '[Business Advertisement] {job} | {name}: {message}', allowedJobs = {}, blockedJobs = { 'unemployed' } },
    },

    -- Where advert money comes from: 'cash' or 'bank'.
    payWith = 'cash',

    -- Staff messages.
    -- minRank: lowest rank from the ranks list above that can use it. Every rank above it can too.
    -- audience: 'everyone' or 'staff'.
    -- color: a color, or 'rank' to use the sender's rank color.
    -- log = true sends it to the staff webhook below.
    -- Placeholders: {name} character name, {player} FiveM name, {id}, {rank}, {message}
    broadcasts = {
        { command = 'sc', help = 'Staff chat', minRank = 'tester', audience = 'staff', color = 'rank', format = '[Staff] [{rank}] {player} [{name}] [ID: {id}]: {message}' },
        { command = 'aooc', help = 'Admin out of character message', minRank = 'moderator', audience = 'everyone', color = '#ED8936', format = '[Admin OOC] {player}: {message}', log = true },
        { command = 'announce', help = 'Server announcement', minRank = 'admin', audience = 'everyone', color = '#FF6347', format = '[Server Announcement | {rank} | {player}]: {message}', log = true },
        { command = 'cityevent', help = 'Announce a city event', minRank = 'moderator', audience = 'everyone', color = '#FF4FCD', format = '[City Event] {player}: {message}', log = true },
        { command = 'cityannounce', help = 'City announcement', minRank = 'moderator', audience = 'everyone', color = '#E74C3C', format = '[City Announcement] {player}: {message}', log = true },
    },

    -- /areannounce [range] [message] sends a staff message to players nearby.
    -- range is in meters. Staff can type a range, it gets kept between 5 and maxRange.
    areaAnnounce = {
        command = 'areannounce',
        help = 'Staff message to players nearby, you can start it with a range in meters',
        minRank = 'moderator',
        defaultRange = 50.0,
        maxRange = 250.0,
        color = '#FF6347',
        format = '[Area Announcement | {rank} | {player}]: {message}'
    },

    -- Lowest rank for each of these staff commands.
    -- adminDuty: /adminduty. dnd: /dnd (Do Not Disturb, blocks PMs from players). toggleAdverts: /togglead
    -- chatMute: /chatmute and /chatunmute. clearChat: /clearchat (clears chat for everyone)
    staffCommands = {
        adminDuty = 'tester',
        dnd = 'tester',
        toggleAdverts = 'management',
        chatMute = 'moderator',
        clearChat = 'admin'
    },

    -- Range of /dice, /flipcoin and /rps, in meters.
    gamesRange = 15.0,

    -- Discord webhooks. Leave one empty to turn that log off.
    -- adverts: every advert posted. staff: broadcasts with log = true. profanity: blocked messages.
    webhooks = {
        adverts = '',
        staff = '',
        profanity = ''
    },
}
