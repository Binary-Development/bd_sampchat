local serverConfig = require 'config.server'

local profanity = {}

local swaps = {
    ['0'] = 'o',
    ['1'] = 'i',
    ['3'] = 'e',
    ['4'] = 'a',
    ['5'] = 's',
    ['7'] = 't',
    ['@'] = 'a',
    ['$'] = 's',
    ['!'] = 'i'
}

---@class BlockedWord
---@field word string
---@field pattern string

---@type BlockedWord[]
local blocked = {}

for i = 1, #serverConfig.blockedWords do
    local word = serverConfig.blockedWords[i]

    assert(type(word) == 'string' and word ~= '', ('config/server.lua: blockedWords[%d] must be a word in quotes'):format(i))

    word = word:lower()
    blocked[i] = {
        word = word,
        pattern = ('%%f[%%w]%s%%f[%%W]'):format((word:gsub('%p', '%%%0')))
    }
end

---@param message string
---@return string? word the first blocked word found
function profanity.find(message)
    if #blocked == 0 then return end

    local normalized = message:lower():gsub('[013457@%$!]', swaps)

    for i = 1, #blocked do
        if normalized:find(blocked[i].pattern) then
            return blocked[i].word
        end
    end
end

return profanity
