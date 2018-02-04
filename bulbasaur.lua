moveSprites = require( "movement" )

local bulbasaur = { } --where bulbasaur functions and vars live

bulbasaur.type = Isaac.GetEntityTypeByName( "Bulbasaur" )
bulbasaur.variant = Isaac.GetEntityVariantByName( "Bulbasaur" )
bulbasaur.item = Isaac.GetItemIdByName( "Bulbasaur" )
bulbatick = 0 --the api is bullshit so i have to use a god awful global tick value for initiating bulbasaur's attacks

function bulbasaur:Make( bulba )
    setDebug( "Initializing bulbasaur" )
    bulba.tick = 0
end

function bulbasaur:Update( bulba )
    setDebug( tostring( round( bulba.Velocity.X ) ) .. " " .. tostring( round( bulba.Velocity.Y ) ) )
    --setDebug( tostring( ref ) .. " " .. tostring( EntityRef( bulba ) ) )
    local player = Isaac.GetPlayer( 0 )
    local sprite = bulba:GetSprite( )

    if not sprite:IsPlaying( "Poisonpowder" ) then bulba:FollowParent( ) end
    --if bulba.Velocity.X > 4 or bulba.Velocity.Y > 4 then bulba.Velocity = Vector( 4, 4 ) end
    direction = moveSprites( bulba.Velocity.X, bulba.Velocity.Y )
    if not sprite:IsPlaying( "Poisonpowder" ) then sprite:Play( direction ) end

    --setDebug( tostring( round( xDiff ) ) .. " " .. tostring( round( yDiff ) ) .. " " .. direction )
    bulbatick = bulbatick + 1
    if bulbatick >= 60 then
        local entities = Isaac.GetRoomEntities( )
        for i = 1, #entities do
            ent = entities[i]
            if ent:IsVulnerableEnemy( ) then
                distance = { x = math.abs( ent.Position.X - bulba.Position.X ), y = math.abs( ent.Position.Y - bulba.Position.Y ) }
                setDebug( tostring( round( distance.x ) ) .. " " .. tostring( round( distance.y ) ) )
                if distance.x < 100 and distance.y < 100 then
                    sprite:Play( "Poisonpowder", true ) --true is there to force play the animation
                    bulba.Velocity = Vector( 0, 0 )
                    ent:AddPoison( EntityRef( bulba ), 30, 2 )
                    bulba.tick = 0
                end
            end
        end
    end
end

return bulbasaur
