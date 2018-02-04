--movement sprite handling for all pokemon
local function moveSprites( xDiff, yDiff )
    if math.abs( xDiff ) > math.abs( yDiff ) and math.abs( xDiff ) > 1 then
        if xDiff < 0 then direction = "WalkLeft"
        elseif xDiff > 0 then direction = "WalkRight" end
    end
    if math.abs( yDiff ) > math.abs( xDiff ) and math.abs( yDiff ) > 1 then
        if yDiff > 0 then direction = "WalkDown"
        elseif yDiff < 0 then direction = "WalkUp" end
    end
    if math.abs( math.abs( yDiff ) + math.abs( xDiff ) ) < 1 then direction = "Idle" end
    return direction
end

return moveSprites
