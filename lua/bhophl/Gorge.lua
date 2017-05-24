local kStartSlideSpeed = 8.9

local kMaxSlidingSpeed = 13


function Gorge:GetGroundFriction()

    if self:GetIsBellySliding() then
        return self:GetGameEffectMask(kGameEffect.OnInfestation) and Gorge.kBellyFrictionOnInfestation or Gorge.kBellyFriction
    end

    return 6--3.6--7

end

function Gorge:GetAirControl()
    return 0
end

function Gorge:GetAirFriction()
    return 0
end

function Gorge:GetAcceleration()
    return 10--13
end

function Gorge:PostUpdateMove(input, runningPrediction)

    if self:GetIsBellySliding() and self:GetIsOnGround() then

        local velocity = self:GetVelocity()

        local yTravel = self:GetOrigin().y - self.prevY
        local xzSpeed = velocity:GetLengthXZ()

        xzSpeed = xzSpeed + yTravel * -4

        if xzSpeed < kMaxSlidingSpeed or yTravel > 0 then

            local directionXZ = GetNormalizedVectorXZ(velocity)
            directionXZ:Scale(xzSpeed)

            velocity.x = directionXZ.x
            velocity.z = directionXZ.z

            self:SetVelocity(velocity)

        end

        self.verticalVelocity = yTravel / input.time

    end

end

function Gorge:ModifyVelocity(input, velocity, deltaTime)

    -- Give a little push forward to make sliding useful
    if self.startedSliding then

        if self:GetIsOnGround() then

            local pushDirection = GetNormalizedVectorXZ(self:GetViewCoords().zAxis)

            local currentSpeed = math.max(0, pushDirection:DotProduct(velocity))

            local maxSpeedTable = { maxSpeed = kStartSlideSpeed }
            self:ModifyMaxSpeed(maxSpeedTable, input)

            local addSpeed = math.max(0, maxSpeedTable.maxSpeed - currentSpeed)
            local impulse = pushDirection * addSpeed

            velocity:Add(impulse)

        end

        self.startedSliding = false

    end

    if self:GetIsBellySliding() then

        local currentSpeed = velocity:GetLengthXZ()
        local prevY = velocity.y
        velocity.y = 0

        local addVelocity = self:GetViewCoords():TransformVector(input.move)
        addVelocity.y = 0
        addVelocity:Normalize()
        addVelocity:Scale(deltaTime * 10)

        velocity:Add(addVelocity)
        velocity:Normalize()
        velocity:Scale(currentSpeed)
        velocity.y = prevY

    end

    if not self.onGround then

      --initialisin
      local laccelmod = 10--acceleration value
      local lAirAcceleration = self:GetMaxSpeed() --accelerate to maximum speed in one second
      local wishDir = self:GetViewCoords():TransformVector(input.move) --this is a unit vector
      wishDir.y = 0
      wishDir:Normalize()


      local wishDircurrentspeed = velocity:DotProduct(wishDir) --current velocity along wishdir axis

      lAirAcceleration = 0.9375--lAirAcceleration * 0.1875

      local addspeedlimit = lAirAcceleration - wishDircurrentspeed
      if addspeedlimit <= 0 then return end

      accelerationIncrement = laccelmod * deltaTime * 6--lAirAcceleration
      if accelerationIncrement > addspeedlimit then
        accelerationIncrement = addspeedlimit
      end

      velocity:Add(wishDir * accelerationIncrement)
   end

end
