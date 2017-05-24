local kHealthWarningTrigger = 0.6

local kHealthCriticalTrigger = 0.4

local kWalkMaxSpeed = 5--3.7 when firing miniguns? Doesn't do anything
local kMaxSpeed = 5--5.75
local kViewOffsetHeight = 2.3
local kAcceleration = 50--20

local kThrustersCooldownTime = 2.5--2.5
local kThrusterDuration = 1 --1.5

local kThrusterMinimumFuel = 0.75--0.99

local kThrusterUpwardsAcceleration = 22--2
local kThrusterHorizontalAcceleration = 40--23
-- added to max speed when using thrusters
local kHorizontalThrusterAddSpeed = 2.5--2.5

local kExoEjectDuration = 0
local kExoDeployDuration = 1.4

local gHurtCinematic = nil

function Exo:GetAirControl()
    return 12--4
end

function Exo:GetAcceleration()
    return 10--13
end

function Exo:GetGroundFriction()
    return 5--3
end

Exo.kXZExtents = 0.55
Exo.kYExtents = 1.2

function Exo:GetMaxSpeed(possible)

    if possible then
        return kWalkMaxSpeed
    end

    local maxSpeed = kMaxSpeed * self:GetInventorySpeedScalar()

    if self.catpackboost then
        maxSpeed = maxSpeed + kCatPackMoveAddSpeed
    end

    return maxSpeed

end

-- for jetpack fuel display
function Exo:GetFuel()
    if self.thrustersActive then
        return Clamp(self.fuelAtChange - (Shared.GetTime() - self.timeFuelChanged) / kThrusterDuration, 0, 1)
    else
        return Clamp(self.fuelAtChange + (Shared.GetTime() - self.timeFuelChanged) / kThrustersCooldownTime, 0, 1)
    end
end

--Jump
local kUpVector = Vector(0, 1, 0)

function Exo:ModifyVelocity(input, velocity, deltaTime)

    if self.thrustersActive then

        if self.thrusterMode == kExoThrusterMode.Vertical then

            velocity:Add(kUpVector * kThrusterUpwardsAcceleration * deltaTime)
            velocity.y = math.min(1.5, velocity.y)

        else

            input.move.y = 0

            local maxSpeed,wishDir

            maxSpeed = self:GetMaxSpeed() + kHorizontalThrusterAddSpeed

            if self.thrusterMode == kExoThrusterMode.StrafeLeft then
                input.move.x = -1
            elseif self.thrusterMode == kExoThrusterMode.StrafeRight then
                input.move.x = 1
            elseif self.thrusterMode == kExoThrusterMode.DodgeBack then
                -- strafe buttons should have less effect when going forwards/backwards, should be more based on your look direction
                input.move.z = -2
            else
                -- strafe buttons should have less effect when going forwards/backwards, should be more based on your look direction
                input.move.z = 2
            end

            wishDir = self:GetViewCoords():TransformVector( input.move )
            wishDir.y = 0
            wishDir:Normalize()

            wishDir = wishDir * maxSpeed

            -- force should help correct velocity towards wishDir, this makes turning more responsive
            local forceDir = wishDir - velocity
            local forceLength = forceDir:GetLengthXZ()
            forceDir:Normalize()

            local accelSpeed = kThrusterHorizontalAcceleration * deltaTime
            accelSpeed = math.min(forceLength, accelSpeed)
            velocity:Add(forceDir * accelSpeed)


        end

    end
    --FIXME doesn't wor
    if not self.onGround then
      local laccelmod = 100--acceleration value
      local lAirAcceleration = self:GetMaxSpeed()--maxSpeedTable.maxSpeed --accelerate to maximum speed in one second
      local wishDir = self:GetViewCoords():TransformVector(input.move) --this is a unit vector
      wishDir.y = 0
      wishDir:Normalize()


      local wishDircurrentspeed = velocity:DotProduct(wishDir) --current velocity along wishdir axis

      lAirAcceleration = 0.9375--lAirAcceleration * 0.1875

      local addspeedlimit = lAirAcceleration - wishDircurrentspeed
      if addspeedlimit <= 0 then return end

      accelerationIncrement = laccelmod * deltaTime * 5--lAirAcceleration
      if accelerationIncrement > addspeedlimit then
        accelerationIncrement = addspeedlimit
      end

      velocity:Add(wishDir * accelerationIncrement)
    end
end

--
--junk
--

function Exo:GetCanEject()
    return self:GetIsPlaying() and not self.ejecting and self:GetIsOnGround() and not self:GetIsOnEntity()
        and self.creationTime + kExoDeployDuration < Shared.GetTime()
        and #GetEntitiesForTeamWithinRange("CommandStation", self:GetTeamNumber(), self:GetOrigin(), 4) == 0
end

function Exo:EjectExo()

    if self:GetCanEject() then

        self.ejecting = true
        self:TriggerEffects("eject_exo_begin")

        if Server then
            self:AddTimedCallback(Exo.PerformEject, kExoEjectDuration)
        end

    end

end

-- jumping is handled in a different way for exos
function Exo:GetCanJump()
    return false
end

local function HandleThrusterStart(self, thrusterMode)

    if thrusterMode == kExoThrusterMode.Vertical then
        self:DisableGroundMove(0.5) --this is where the bhop bug originates haha
    end

    self:SetFuel( self:GetFuel() )

    self.thrustersActive = true
    self.timeThrustersStarted = Shared.GetTime()
    self.thrusterMode = thrusterMode


end

local function HandleThrusterEnd(self)

    self:SetFuel( self:GetFuel() )

    self.thrustersActive = false
    self.timeThrustersEnded = Shared.GetTime()

end

function Exo:GetIsThrusterAllowed()

    local allowed = true

    for i = 0, self:GetNumChildren() - 1 do

        local child = self:GetChildAtIndex(i)
        if child.GetIsThrusterAllowed and not child:GetIsThrusterAllowed() then
            allowed = false
            break
        end

    end

    return allowed

end


function Exo:UpdateThrusters(input)

    local lastThrustersActive = self.thrustersActive
    local jumpPressed = bit.band(input.commands, Move.Jump) ~= 0
    local movementSpecialPressed = bit.band(input.commands, Move.MovementModifier) ~= 0
    local thrusterDesired = (jumpPressed or movementSpecialPressed) and self:GetIsThrusterAllowed()

    if thrusterDesired ~= lastThrustersActive then

        if thrusterDesired and not self.lastThrusterDesired then

            local desiredMode =
                jumpPressed and kExoThrusterMode.Vertical
                or input.move.x < 0 and kExoThrusterMode.StrafeLeft
                or input.move.x > 0 and kExoThrusterMode.StrafeRight
                or input.move.z < 0 and kExoThrusterMode.DodgeBack
                or input.move.z > 0 and kExoThrusterMode.Horizontal
                or nil

            if desiredMode and self:GetFuel() >= kThrusterMinimumFuel then
                HandleThrusterStart(self, desiredMode)
                self.lastThrusterDesired = true
            end

        else
            HandleThrusterEnd(self)
        end

    end

    if not thrusterDesired then
        self.lastThrusterDesired = false
    end

    if self.thrustersActive and self:GetFuel() == 0 then
        HandleThrusterEnd(self)
    end

end

function Exo:ModifyGravityForce(gravityTable)

    if self:GetIsOnGround() or ( self.thrustersActive and self.thrusterMode == kExoThrusterMode.Vertical ) then
        gravityTable.gravity = 0
    end

end

function Exo:GetArmorUseFractionOverride()
    return 1.0
end

local kMinigunDisruptTimeout = 5

function Exo:Disrupt()

    if not self.timeLastExoDisrupt then
        self.timeLastExoDisrupt = Shared.GetTime() - kMinigunDisruptTimeout
    end

    if self.timeLastExoDisrupt + kMinigunDisruptTimeout <= Shared.GetTime() then

        local weaponHolder = self:GetActiveWeapon()
        local leftWeapon = weaponHolder:GetLeftSlotWeapon()
        local rightWeapon = weaponHolder:GetRightSlotWeapon()

        if leftWeapon:isa("Minigun") then

            leftWeapon.overheated = true
            self:TriggerEffects("minigun_overheated_left")
            leftWeapon:OnPrimaryAttackEnd(self)

        end

        if rightWeapon:isa("Minigun") then

            rightWeapon.overheated = true
            self:TriggerEffects("minigun_overheated_left")
            rightWeapon:OnPrimaryAttackEnd(self)

        end

        StartSoundEffectForPlayer("sound/NS2.fev/marine/heavy/overheated", self)

        self.timeLastExoDisrupt = Shared.GetTime()

    end

end

function Exo:SetFuel(fuel)
   self.timeFuelChanged = Shared.GetTime()
   self.fuelAtChange = fuel
end

function Exo:OnUpdateAnimationInput(modelMixin)

    PROFILE("Exo:OnUpdateAnimationInput")

    Player.OnUpdateAnimationInput(self, modelMixin)

    if self.thrustersActive then
        modelMixin:SetAnimationInput("move", "jump")
    end

end
