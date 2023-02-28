--[[
    https://wiki.facepunch.com/gmod/Calling_net.Start_with_unpooled_message_name
    "Ideally you'd do this when your Lua files are being loaded - but where that's not
    possible you need to do it at least a couple of seconds before calling the message
    to be sure that it'll work."

    That's why I'm joining the AddNetworkString here. People with VERY slow computers
    have had severe problems with unpooled messages even with me doing extra checks.
]]

-- Note: 37 net strings were removed from here after we created SEv.Net:Start and
--       SEv.Net:Receive, which use the net string sev_cheap.

-- Net
util.AddNetworkString("sev_cheap")
