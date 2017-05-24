Marine.kWalkMaxSpeed = 5
Marine.kRunMaxSpeed = 5.75

function Marine:GetGroundFriction()
    return 5--5--3
end

function Marine:GetSlowOnLand()
    return true
end

function Marine:GetAirControl()
    return 0
end

function Marine:GetAcceleration()
    return 10--13
end

function Marine:GetMaxSpeed(possible)

    if possible then
        return Marine.kRunMaxSpeed
    end

    local sprintingScalar = self:GetSprintingScalar()
    local maxSprintSpeed = Marine.kWalkMaxSpeed + ( Marine.kRunMaxSpeed - Marine.kWalkMaxSpeed ) * sprintingScalar
    local maxSpeed = ConditionalValue( self:GetIsSprinting(), maxSprintSpeed, Marine.kWalkMaxSpeed )

    -- Take into account our weapon inventory and current weapon. Assumes a vanilla marine has a scalar of around .8.
    local inventorySpeedScalar = self:GetInventorySpeedScalar()-- + .17
    local useModifier = 1

    local activeWeapon = self:GetActiveWeapon()
    if self.isUsing and activeWeapon:GetMapName() == Builder.kMapName then
        useModifier = 0.5
    end

    if self.catpackboost then
        maxSpeed = maxSpeed + kCatPackMoveAddSpeed
    end

    return maxSpeed * self:GetSlowSpeedModifier() * inventorySpeedScalar  * useModifier

end

function Marine:ModifyJumpLandSlowDown(slowdownScalar)

    if self.strafeJumped then
        slowdownScalar = 0.2 + slowdownScalar --0.2
    end

    return slowdownScalar

end

--Strafe jumps

function Marine:ModifyVelocity(input, velocity, deltaTime)
    --Air Strafe testing...
    if not self.onGround then

      local laccelmod = 10--acceleration modifier
      local lAirAcceleration = self:GetMaxSpeed() --accelerate to maximum speed in one second
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
        --Because fuck ns2 physics

    end

end
