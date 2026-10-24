return {
    -- Longest message a player can type, in characters.
    maxLength = 400,

    -- Default keys. Players can change them in Settings > Key Bindings > FiveM.
    -- openKey opens the chat box. toggleKey switches between: show when active, always show, always hide.
    openKey = 'T',
    toggleKey = 'L',

    -- How long the chat stays on screen after a new message, in seconds.
    fadeTime = 7,

    -- How many messages the chat window keeps. Older ones get removed so the chat stays fast.
    history = 100,

    -- Text above heads from /ame and /amy.
    -- color is red, green, blue (0 to 255). duration is in seconds.
    action = {
        color = { 194, 162, 218 },
        duration = 7,
        scale = 0.5
    },

    -- Shows "..." above players who have the chat open, so people nearby can see they're typing.
    -- Uses the same color and size as /ame. range is in meters. Set enabled = false to turn it off.
    typing = {
        enabled = true,
        range = 10.0
    },
}
