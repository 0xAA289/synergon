local plugin = {}

function plugin:GetEntityDimensions(ent, model)
    if self.model_scale_cache[model] then
        return self.model_scale_cache[model]
    else
        self.model_scale_cache[model] = ent:OBBMins():DistToSqr(ent:OBBMaxs())
    end

    return self.model_scale_cache[model]
end

function plugin:FlagAsDangerous(ent)
    ent.synergon_is_dangerous = true
    local phys = ent:GetPhysicsObject()

    if IsValid(phys) and phys.PhysicsDestroy then
        phys:PhysicsDestroy()
    end
end

function plugin:GetEntityDangerLevel(phys, mdl)
    if not IsValid(phys) then return end
    if self.model_cache[mdl] then return self.model_cache[mdl] end
    local data, _ = util.GetModelMeshes(mdl, 0, 0)
    if not data or not data[1] then return end
    if not data[1].triangles then return end
    local convexes = phys:GetMeshConvexes()
    if not istable(convexes) then return end
    self.model_cache[mdl] = #data[1].triangles * (istable(convexes) and #convexes)

    return self.model_cache[mdl]
end

function plugin:TestUnsafeEntity(ent)
    if not IsValid(ent) then return end
    local connected = constraint.GetAllConstrainedEntities(ent)
    local total = 0
    if table.Count(connected) < 5 then return true end

    for e1, e2 in pairs(connected) do
        if e1.synergon_is_dangerous or e2.synergon_is_dangerous then return false end
        local phys = e1:GetPhysicsObject()
        if not IsValid(phys) then continue end
        local x = self:GetEntityDangerLevel(phys, e1:GetModel())
        total = total + (x * (phys:IsPenetrating() and 2 or 1) or 0)
        if e2.synergon_is_dangerous then return false end
        local phys = e2:GetPhysicsObject()
        if not IsValid(phys) then continue end
        local x = self:GetEntityDangerLevel(phys, e2:GetModel())
        total = total + (x * (phys:IsPenetrating() and 2 or 1) or 0)
    end

    if total < 300000 then return true end
    self:FlagAsDangerous(ent)

    for e1, e2 in pairs(connected) do
        self:FlagAsDangerous(e1)
        self:FlagAsDangerous(e2)
    end

    return false
end

function plugin:RemoveAttachedEntities(ent)
    if not IsValid(ent) then return end
    local connected = constraint.GetAllConstrainedEntities(ent)

    for e1, e2 in pairs(connected) do
        if IsValid(e1) then
            e1:Remove()
        end

        if IsValid(e2) then
            e2:Remove()
        end
    end
end

function plugin:Constructor()
    self:SetLoopInterval(0)
    self:SetEnableLoop(true)
    self.last_reset = SysTime()
    self.tickrate = 1 / engine.TickInterval()
    self.lagticks = 0
    self.model_cache = {}
    self.model_scale_cache = {}

    hook.Add("OnEntityCreated", self.ID, function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) then return end
            local phys = ent:GetPhysicsObject()
            if not IsValid(phys) then return end
            local mdl = ent:GetModel()
            if not mdl then return end
            local danger = self:GetEntityDangerLevel(phys, mdl)
            if jlib then end -- jlib.broadcast(mdl .. " model complexity: " .. string.Comma(self.model_cache[mdl]) .. " size: " .. self:GetEntityDimensions(ent, mdl) .. " total: " .. total)
        end)
    end)

    hook.Add("PhysgunPickup", self.ID, function(ply, ent)
        if ent.synergon_is_dangerous then return false end
        local is_safe = self:TestUnsafeEntity(ent)

        if not is_safe then
            self:FlagAsDangerous(ent)

            if isnumber(ply.last_warn_msg) and ply.last_warn_msg > CurTime() or not ply.last_warn_msg then
                ply:jlib_message("no")
                ply.last_warn_msg = CurTime() + 0.1
            end

            return false
        end
    end)

    hook.Add("OnPhysgunReload", self.ID, function(_, ply)
        local ent = ply:GetEyeTrace().Entity
        if not IsValid(ent) then return end
        local is_safe = self:TestUnsafeEntity(ent)
        if is_safe then return end
        ply:jlib_message("Unfreeze blocked due to unsafe props.")
        ply:ConCommand("play buttons/button10.wav")

        return false
    end)
    -- self:RemoveAttachedEntities(ent)
    -- local physobj = FindMetaTable("PhysObj")
    -- physobj.oEnableMotion = physobj.oEnableMotion or physobj.EnableMotion
    -- function physobj:EnableMotion(enable)
    --     if enable and self:GetEntity().synergon_is_dangerous then return end
    --     self:oEnableMotion(enable)
    -- end
end

function plugin:Deconstruct()
    self:SetEnableLoop(false)
    hook.Remove("OnPhysgunReload", self.ID)
    hook.Remove("PhysgunPickup", self.ID)
    hook.Remove("OnEntityCreated", self.ID)
    local physobj = FindMetaTable("PhysObj")
    physobj.EnableMotion = physobj.oEnableMotion
    physobj.oEnableMotion = nil
    self.last_reset = nil
    self.tickrate = nil
    self.lagticks = nil
    self.model_cache = nil
    self.model_scale_cache = nil
end

function plugin:Loop()
    local now = SysTime()
    local deviation = 1 / (now - self.last_reset)
    local delayed_ticks = math.floor(self.tickrate - deviation)

    if delayed_ticks > 0 then
        local ticks = math.Round(delayed_ticks / self.tickrate, 1)
        self.lagticks = ticks > 0 and self.lagticks + 1 or 0
    end

    if self.lagticks > 20 then
        local props = ents.FindByClass("prop_physics")

        for _, prop in ipairs(props) do
            if prop.synergon_is_dangerous then
                prop:Remove()
                continue
            end

            local phys = prop:GetPhysicsObject()
            if not IsValid(phys) or not phys:IsMotionEnabled() or IsValid(prop:GetParent()) then continue end
            phys:EnableMotion(false)
        end

        jlib.broadcast("Lagfix Measures Running.")
        self.lagticks = 0
    end

    self.last_reset = now
end

Synergon:Register("TestPlugin", plugin)