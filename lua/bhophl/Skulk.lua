function Skulk:GetAcceleration()
    return 10--13
end

function Skulk:GetGroundFriction()

    return 7.25--7.25--4.35

end

function Skulk:GetAirControl()
    return 0
end

function Skulk:ModifyVelocity(input, velocity, deltaTime)
    --Air Strafe testing...
    if not self.onGround then

      --initialisin
      local laccelmod = 10--acceleration modifier
      local lAirAcceleration = self:GetMaxSpeed()--accelerate to maximum speed in one second
      local wishDir = self:GetViewCoords():TransformVector(input.move) --this is a unit vector

      --remove vertical direction, UWE fucked something up again
      wishDir.y = 0
      wishDir:Normalize()

      local wishDircurrentspeed = velocity:DotProduct(wishDir) --current velocity along wishdir axis

      lAirAcceleration = 0.9375--lAirAcceleration * 0.1875

      local addspeedlimit = lAirAcceleration - wishDircurrentspeed
      if addspeedlimit <= 0 then return end

      accelerationIncrement = laccelmod * deltaTime * 7.25--lAirAcceleration
      if accelerationIncrement > addspeedlimit then
        accelerationIncrement = addspeedlimit
      end

      velocity:Add(wishDir * accelerationIncrement)

  end

end

function Skulk:GetAirFriction()
    return 0
end
