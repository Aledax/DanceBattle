-- print("Application.lua")

switch = require("switch")
-- dofile("request.lua")
-- dofile("server.lua")
dofile("ws.lua")
-- dofile("uart.lua")

DEBUG = true

stateMachine = switch()
    :case("c", function(command, ip)
        ws_connect(ip)
    end)
    :case("r", function(command)
        print("Resetting ESP...")
        node.restart()
    end)
    :case("q", function(command) 
        print("Closing UART")
        uart.on("data")
    end)
    :default(function(command, ...)
        ws:send(command .. table.concat({...} or {}, ","))
    end)

uart.on("data", "\r", function(data)
    local command = string.sub(data, 1, 1)
    local args = {}
    for i in string.gmatch(string.sub(data, 2, -1), "[^ ]+") do
        table.insert(args, i)
    end

    if (DEBUG) then
        uart.write(0, "----- Echo -----\n");
        uart.write(0, "Command: " .. command .. "\n")
        uart.write(0, "Args: " .. table.concat(args, ",") .. "\n")
    end

    if (command) then
        stateMachine(command, unpack(args))
    end
end, 0)

gpio.write(led, gpio.HIGH)
uart.write(0, "i\n");


