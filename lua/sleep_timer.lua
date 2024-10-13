local timeout = 60  -- in seconds
local action = "quit"  -- "pause" or "quit"

function sleep_handler()
    if action == "pause" then
        mp.set_property("pause", "yes")
    elseif action == "quit" then
        mp.command("quit")
    end
end

local timer = nil

function reset_timer()
    if timer then
        timer:kill()
    end
    timer = mp.add_timeout(timeout, sleep_handler)
end

mp.register_event("file-loaded", reset_timer)

reset_timer()