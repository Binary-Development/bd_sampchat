# bd_sampchat

A SA:MP style chat for FiveM. It has the classic look (bold white text with a black outline, no boxes), proximity roleplay commands, `/ame` text above your head, PMs, paid adverts and staff tools. Everything is in one resource.

It replaces the default `chat` resource and works with anything that already sends messages to chat, so your other scripts keep working.

Works with ESX, QBCore, Qbox, ox_core and ND_Core, or standalone.

## Why I made this

We (Me & Noah) mostly work on semi-serious and serious RP servers. A lot of them run a SA:MP style chat, and they all run into the same problems. It's usually a chat resource, a separate `/me` script and one or two `/ame` scripts that fight over the same command. Text above heads gets sent to the whole server, and each player's game works out whether to show it. People paste weird text and the chat breaks. So I rebuilt it as one resource that does it properly.

## What it does

- SA:MP look, and it fades out when nobody is talking. Press **L** to switch between show when active, always show and hidden.
- Press **Tab** to finish a command. The rest of the command shows faded while you type, and Tab cycles if more than one matches.
- Command suggestions only show commands you're allowed to use.
- Proximity chat: `/b`, `/say`, `/low`, `/whisper`, `/shout`, `/me`, `/melow`, `/my`, `/do`. Only players in range and in the same routing bucket get the message.
- `/togs` switches plain typing between local OOC and in character.
- `/maskname` hides your name in local chat.
- `/ignore` hides a player's local OOC chat and stops their PMs. Type `/ignore` on its own to see your list.
- `/ame` and `/amy` show text above your head for nearby players who can actually see you.
- A "..." shows above nearby players who have the chat open. You can turn it off in the config.
- Close the chat halfway through a message and it's still there next time you open it.
- Private messages, with Do Not Disturb for staff.
- Paid adverts with job limits and a cooldown. Staff can turn them off server-wide.
- Staff chat, announcements, admin OOC, city events, area announcements, admin duty, and `/admins` and `/testers` lists.
- Chat mutes with a time limit. They stick through reconnects and restarts, so leaving and rejoining doesn't get around them.
- `/clearchat` wipes the chat for everyone after a spam wave.
- `/dice`, `/flipcoin` and `/rps`.
- Word filter that blocks the message. It matches whole words and catches swaps like 4 for a.
- Message cooldown, and the same message can't be sent over and over.
- Discord logs for adverts, staff messages, mutes, chat clears and blocked messages.
- Up and down arrows go through your sent messages, and Page Up and Page Down scroll the chat.
- Tells you in the console when there's an update.
- All text is in `locales/en.json` if you want to change the wording.

### Safe by default

- Player messages can't carry HTML, so nobody can inject images, links or scripts into other people's chat.
- Invisible characters, backwards-text tricks and broken text get stripped before anything is shown.
- The server decides who receives a message. Clients never get messages they shouldn't see.
- Every command checks permissions on the server.

## What you need

- [ox_lib](https://github.com/overextended/ox_lib)

## Install

1. Drop `bd_sampchat` into your resources folder.
2. In your `server.cfg`, remove `ensure chat` and add the line below. This resource replaces the default chat, and the line turns off the copy that comes built into FXServer. Having both running will break things.

```cfg
set resources_useSystemChat "false"
```

3. Start it after ox_lib and your framework:

```cfg
ensure ox_lib
ensure bd_sampchat
```

4. Look through `config/server.lua` and `config/shared.lua`, then restart.

## Config

Both config files have a comment on every setting. The ones people usually change:

- **Ranks:** `ranks` in `config/server.lua`, highest first. Each rank is an ace group, so `admin` means anyone in `group.admin`. ESX, Qbox, ox_core and txAdmin already use those groups. QBCore uses its own, so write the full name there, like `qbcore.admin`. To give someone a rank by hand:

```cfg
add_principal identifier.fivem:123456 group.moderator
```

- **Proximity chat:** `proximity` in `config/server.lua`. You can change the commands, ranges, colors and formats.
- **Adverts:** `adverts` in `config/server.lua`. Set the cost (0 is free), cooldown, and which jobs can or can't post. Change `payWith` to pick cash or bank.
- **Staff messages:** `broadcasts` in `config/server.lua`. Set who can use each one and who sees it.
- **Word filter:** `blockedWords` in `config/server.lua`.
- **Spam:** `cooldown`, `duplicateLimit` and `duplicateWindow` in `config/server.lua`. `maxMuteMinutes` caps how long staff can mute for.
- **Typing indicator:** `typing` in `config/shared.lua`. Set `enabled = false` to turn it off.
- **Logs:** paste Discord webhooks into `webhooks` in `config/server.lua`. Leave one empty to turn that log off.
- **Keys:** `openKey` and `toggleKey` in `config/shared.lua` are the defaults. Players can rebind them in Settings > Key Bindings > FiveM.

Framework is set to `auto`. Only change it if it picks the wrong one.

### Running standalone?

Without a framework there are no character names, jobs or money. Names come from FiveM and adverts are free. Leave `allowedJobs` empty on your adverts, or nobody will be able to post them.

## Commands

Players:

| Command | What it does |
|---------|--------------|
| `/b` | Local out of character chat (also what plain typing goes to) |
| `/say` `/s` | Talk in character |
| `/low` `/l` | Talk quietly |
| `/whisper` `/w` | Whisper to players right next to you |
| `/shout` `/sh` | Shout |
| `/me` `/melow` `/my` `/do` | Describe actions and the scene |
| `/ame` `/amy` | Show an action above your head |
| `/togs` | Switch plain typing between OOC and in character |
| `/maskname` | Hide your name in local chat |
| `/pm [id or name] [message]` | Private message |
| `/ignore [id or name]` | Hide a player's OOC chat and PMs. Leave it empty to see your list |
| `/ad` `/businessad` | Post an advert |
| `/id [id or name]` | Look up a player |
| `/players` | How many players are online |
| `/dice [1-3]` `/flipcoin` `/rps` | Games |
| `/admins` `/testers` | See which staff are online |

Staff:

| Command | What it does |
|---------|--------------|
| `/sc` | Staff chat |
| `/aooc` | Admin OOC message to everyone |
| `/announce` | Server announcement |
| `/cityevent` `/cityannounce` | City event and city announcement |
| `/areannounce [range] [message]` | Message to players near you |
| `/adminduty` | Go on or off admin duty |
| `/dnd` | Block PMs from players |
| `/togglead` | Turn adverts on or off for everyone |
| `/chatmute [id or name] [minutes] [reason]` | Mute a player from chat |
| `/chatunmute [id or name]` | Unmute a player |
| `/clearchat` | Clear the chat for everyone |

## For developers

Everything the default chat supports still works. That covers `chat:addMessage`, `chatMessage`, `chat:addSuggestion`, `chat:addSuggestions`, `chat:removeSuggestion`, `chat:addTemplate`, `chat:clear`, and the `addMessage` and `addSuggestion` exports. Color codes like `^1` and `~r~` work too.

To check if a staff member is on duty from another resource:

```lua
local onDuty = exports.bd_sampchat:isOnDuty(source)
```

The UI is React and ships already built in `web/dist`. If you want to change it, run `npm install` and then `npm run build` inside `web`.

## Support

Found a bug or have an idea? Open an issue here or come find us on Discord.

**Discord:** [discord.gg/binary](https://discord.gg/binary)  
**Website and store:** [binarydevs.xyz](https://binarydevs.xyz/)
