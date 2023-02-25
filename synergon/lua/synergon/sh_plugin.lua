local format = string.format

if SERVER then
    util.AddNetworkString("Synergon.ReloadPlugins")

    concommand.Add("synergon_reload", function(ply)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end
        Synergon:Reload()
        net.Start("Synergon.ReloadPlugins")
        net.Broadcast()
    end)
end

if CLIENT then
    net.Receive("Synergon.ReloadPlugins", function()
        Synergon:Reload()
    end)
end

function Synergon:Register(name, contents)
    local id = format("Synergon:%s", name)

    if not istable(contents) then
        print(format("%s [Synergon:Register] Attempted to register ID: ['%s'] with empty contents value.", self.Prefix, id))

        return
    end

    contents.ID = id
    self.Plugins[id] = contents
    self.Constructors[id] = contents.Constructor
    print(format("%s [Synergon:Register] Registered Plugin: ['%s']", self.Prefix, id))
end

function Synergon:Reload()
    self:PreInit()
    self:Init()
end