local base = {}
base.Enabled = true

function base:SetEnableLoop(bool)
    self.loop_enabled = bool

    if bool then
        self:Internal_CreateLoop()
    else
        self:Internal_DestroyLoop()
    end
end

function base:SetLoopInterval(bool)
    self.loop_interval = bool
end

function base:Internal_CreateLoop()
    self.loop_interval = self.loop_interval or 1

    if not self.Loop then
        self:SetEnableLoop(false)

        return
    end

    timer.Create(self.ID, self.loop_interval, 0, function()
        self:Loop()
    end)
end

function base:Internal_DestroyLoop()
    timer.Remove(self.ID)
end

Synergon.PluginsExtensions = base