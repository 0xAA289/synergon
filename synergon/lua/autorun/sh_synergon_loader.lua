local synergon_signature = [[
 ________       ___    ___ ________   _______   ________  ________  ________  ________
|\   ____\     |\  \  /  /|\   ___  \|\  ___ \ |\   __  \|\   ____\|\   __  \|\   ___  \
\ \  \___|_    \ \  \/  / | \  \\ \  \ \   __/|\ \  \|\  \ \  \___|\ \  \|\  \ \  \\ \  \
 \ \_____  \    \ \    / / \ \  \\ \  \ \  \_|/_\ \   _  _\ \  \  __\ \  \\\  \ \  \\ \  \
  \|____|\  \    \/  /  /   \ \  \\ \  \ \  \_|\ \ \  \\  \\ \  \|\  \ \  \\\  \ \  \\ \  \
    ____\_\  \ __/  / /      \ \__\\ \__\ \_______\ \__\\ _\\ \_______\ \_______\ \__\\ \__\
   |\_________\\___/ /        \|__| \|__|\|_______|\|__|\|__|\|_______|\|_______|\|__| \|__|
   \|_________\|___|/


    * Synergon Anti-Lag Utilities
    * Created by Strange#0856
    * Version: %s
]]
Synergon = {}
Synergon.Version = "1.0 - 1/12/2023"
Synergon.Prefix = "[/Synergon/]:"
local include = include
local AddCSLuaFile = AddCSLuaFile

Synergon.Rules = {
    ["sv"] = function(f)
        include(f)
    end,
    ["sh"] = function(f)
        if SERVER then
            AddCSLuaFile(f)
        end

        include(f)
    end,
    ["cl"] = function(f)
        if SERVER then
            AddCSLuaFile(f)

            return
        end

        include(f)
    end,
}

local format = string.format
local sub = string.sub
local find = file.Find
local print = print
local upper = string.upper
local attach = hook.Add

function Synergon:Execute(r, f)
    if not self.Rules[r] then return end
    self.Rules[r](f)
end

function Synergon:PreInit()
    print(format(synergon_signature, self.Version))
    print(format("%s [Synergon:?] Hello There!", self.Prefix))
    print(format("%s [Synergon:PreInit] Executing PreInitialization Preperations.", self.Prefix))
    print(format("%s [Synergon:PreInit] Allocating self.Plugins {}", self.Prefix))
    self.Plugins = {}
    print(format("%s [Synergon:PreInit] Allocated self.Plugins {}", self.Prefix))
    print(format("%s [Synergon:PreInit] Allocating self.Constructors {}", self.Prefix))
    self.Constructors = {}
    print(format("%s [Synergon:PreInit] Allocated self.Constructors {}", self.Prefix))
    print(format("%s [Synergon:PreInit] Loading plugins... self:Loader('synergon')", self.Prefix))
    self:Loader("synergon")
    hook.Run("Synergon:PreInit")
end

function Synergon:Init()
    print(format("%s [Synergon:Init] Executing Constructors...", self.Prefix))

    for id, f in pairs(self.Constructors) do
        print(format("%s [Synergon:Init] Executing Constructor ID: [%s].", self.Prefix, id))
        self.Plugins[id] = table.Merge(table.Copy(self.PluginsExtensions), self.Plugins[id])

        if self.Plugins[id].Enabled then
            self.Plugins[id]:Constructor(self)
            print(format("%s [Synergon:Init] Enabling [%s].", self.Prefix, id))
        else
            self.Plugins[id]:Deconstruct(self)
            print(format("%s [Synergon:Init] Disabling [%s].", self.Prefix, id))
        end
    end

    print(format("%s [Synergon:Init] Constructor Execution Finished.", self.Prefix))
    self.Constructors = {}
    print(format("%s [Synergon:Init] Cleaned self.Constructors {}", self.Prefix))
    collectgarbage()
    collectgarbage()
    hook.Run("Synergon:Init")
end

function Synergon:Loader(dir)
    local files_list, folders_list = find(format("%s/*", dir), "LUA")

    for _, f in ipairs(files_list) do
        local realm, path = sub(f, 0, 2), format("%s/%s", dir, f)
        self:Execute(realm, path)
        print(format("%s [Synergon:Loader] Loading [%s] as [%s] plugin...", self.Prefix, path, upper(realm)))
    end

    for _, f in ipairs(folders_list) do
        self:Loader(format("%s/%s", dir, f))
    end
end

attach("Initialize", "Synergon.Init()", function()
    Synergon:Init()
end)

Synergon:PreInit()