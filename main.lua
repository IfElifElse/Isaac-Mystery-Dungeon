local IMD = RegisterMod( "Isaac Mystery Dungeon", 1 )

local abs = math.abs --i kinda got tired ot typing out math.abs
local str = tostring --and tostring
local log = Isaac.DebugString --and this

--------------------
-- initialization --
--------------------

--modified assert
local function exists( obj, kind )
    assert( type( obj ), type( kind )) --makes sure the object is the expected type
end
local isfloat = 1.0
local isstr = ""
local isdict = { }
local isplayer = Isaac.GetPlayer( 0 )

--used in movement, basically chops off decimals from floats
local function round( num, numDecimalPlaces )
    exists(num, isfloat)
    local mult = 10 ^ ( numDecimalPlaces or 0 )
    return math.floor( num * mult + 0.5 ) / mult
end --this isnt my code, i stole it from stackexchange because i dont actually know how to use lua :)

--debugging tool, works with IMD:onRender to display text
local function setDebug( newDebugText )
    cleardebug = 0
    debug_text = newDebugText
end

--movement sprite handling for all pokemon
local function moveSprites( xDiff, yDiff )
    exists( xDiff, isfloat ) --difference between position in last frame and the current frame
    exists( yDiff, isfloat ) --same as above

    if abs( xDiff ) > abs( yDiff ) and abs( xDiff ) > 1 then
        if xDiff < 0 then direction = "WalkLeft"
        elseif xDiff > 0 then direction = "WalkRight" end
    end
    if abs( yDiff ) > abs( xDiff ) and abs( yDiff ) > 1 then
        if yDiff > 0 then direction = "WalkDown"
        elseif yDiff < 0 then direction = "WalkUp" end
    end
    if abs( abs( yDiff ) + abs( xDiff ) ) < 1 then direction = "Idle" end
    return direction
end

local function move( familiar, player, radius, attackname, sprite, spd )
    assert( familiar ) --ref to familiar, what will be moving
    exists( player, isplayer ) --ref to player, used to calculate distance
    exists( radius, isfloat ) --float, stops the familiar from moving to close to the player
    exists( attackname, isstr ) --string, the name of a sprite in the familiar's anm2 file that will stop it from moving
    assert( sprite ) --ref to sprite, to test if attackname is playing
    exists( spd, isfloat ) --float, limits the familiar's speed

    local wait = false
    if type( attackname ) == type( { } ) then --supporting multiple attack animations
        for i = 1, #attackname do
            if sprite:IsPlaying( attackname[ i ] ) then wait = true end
        end
    else
        if sprite:IsPlaying( attackname ) then wait = true end
    end
    --distance from player
    local distX = abs( abs( player.Position.X ) - abs( familiar.Position.X ) ) --you're only good at math if you can nest abs functions like this
    local distY = abs( abs( player.Position.Y ) - abs( familiar.Position.Y ) )
    --setDebug( str( round( distX ) ) .. " " .. str( round( distY ) ) )
    --pythagorean theorem stuff to make the stopping range circular
    local dist = distX^2 + distY^2
    if dist < radius^2 then wait = true end
    if not wait then familiar:FollowParent( ) end
    --limiting speed
    if familiar.Velocity.X > spd then velX = spd else velX = familiar.Velocity.X end
    if familiar.Velocity.Y > spd then velY = spd else velY = familiar.Velocity.Y end
    if familiar.Velocity.X < -spd and familiar.Velocity.X < 0 then velX = -spd end
    if familiar.Velocity.Y < -spd and familiar.Velocity.Y < 0 then velY = -spd end
    return Vector( velX, velY )
end

---------------
-- bulbasaur --
---------------

local bulbasaur = { } --where bulbasaur functions and vars live

bulbasaur.type = Isaac.GetEntityTypeByName( "Bulbasaur" )
bulbasaur.variant = Isaac.GetEntityVariantByName( "Bulbasaur" )
bulbasaur.item = Isaac.GetItemIdByName( "Bulbasaur" )
bulbatick = 0 --the api is bullshit so i have to use a god awful global tick value for initiating attacks
--while on topic the documentation makes me want to fly a jetliner into a tall building
log( str( bulbasaur.type ) )
log( str( bulbasaur.variant ) )
log( str( bulbasaur.item ) )

function bulbasaur:Make( bulba )
    setDebug( "Initializing bulbasaur" )
    bulba.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
end

function bulbasaur:Update( bulba )
    --setDebug( str( round( bulba.Velocity.X ) ) .. " " .. str( round( bulba.Velocity.Y ) ) )
    local player = Isaac.GetPlayer( 0 )
    local sprite = bulba:GetSprite( )

    local speed = 14
    local loyalty = 80
    bulba.Velocity = move( bulba, player, 80, "Poisonpowder", sprite, 14)
    direction = moveSprites( bulba.Velocity.X, bulba.Velocity.Y )
    if not sprite:IsPlaying( "Poisonpowder" ) then sprite:Play( direction ) end

    --setDebug( str( round( xDiff ) ) .. " " .. str( round( yDiff ) ) .. " " .. direction )
    bulbatick = bulbatick + 1
    if bulbatick >= 60 then
        local entities = Isaac.GetRoomEntities( )
        for i = 1, #entities do
            ent = entities[i]
            if ent:IsVulnerableEnemy( ) then
                local distX = abs( ent.Position.X - bulba.Position.X )
                local distY = abs( ent.Position.Y - bulba.Position.Y )
                local range = 100
                --setDebug( str( round( distance.x ) ) .. " " .. str( round( distance.y ) ) )
                dist = distX^2 + distY^2
                if dist < range^2 then
                    sprite:Play( "Poisonpowder", true ) --true is there to force play the animation
                    bulba.Velocity = Vector( 0, 0 )
                    ent:AddPoison( EntityRef( bulba ), 30, 2 )
                    bulbatick = 0
                end
            end
        end
    end
end

IMD:AddCallback( ModCallbacks.MC_FAMILIAR_INIT, bulbasaur.Make, bulbasaur.variant ) --for every new bulbasaur entity, call Make
IMD:AddCallback( ModCallbacks.MC_FAMILIAR_UPDATE, bulbasaur.Update, bulbasaur.variant ) --for every frame a bulbasaur entity is in, call Update

----------------
-- charmander --
----------------

local charmander = { }

charmander.type = Isaac.GetEntityTypeByName( "Charmander" )
charmander.variant = Isaac.GetEntityVariantByName( "Charmander" )
charmander.item = Isaac.GetItemIdByName( "Charmander" )
charmtick = 0 --i want to end my life but the government won't let me, save me from this existential nightmare
charmsprites = { "EmberUp", "EmberDown", "EmberLeft", "EmberRight" }
log( str( charmander.type ) )
log( str( charmander.variant ) )
log( str( charmander.item ) )

function charmander:Make( charm )
    setDebug( "Initializing charmander" )
    charm.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
end

function charmander:Update( charm )
    local player = Isaac.GetPlayer( 0 )
    local sprite = charm:GetSprite( )

    local speed = 10
    local loyalty = 50
    charm.Velocity = move( charm, player, loyalty, charmsprites, sprite, speed)
    direction = moveSprites( charm.Velocity.X, charm.Velocity.Y )
    --different sprite handling since there are 4 different attack animations for charmander
    playsprite = true
    ember = charmsprites
    for i = 1, #ember do
        if sprite:IsPlaying( ember[ i ] ) then playsprite = false end
    end
    if playsprite then sprite:Play( direction ) end
end

IMD:AddCallback( ModCallbacks.MC_FAMILIAR_INIT, charmander.Make, charmander.variant ) --for every new charmander entity, call Make
IMD:AddCallback( ModCallbacks.MC_FAMILIAR_UPDATE, charmander.Update, charmander.variant ) --for every frame a charmander entity is in, call Update

----------
-- main --
----------

local function spawnFamiliar( player, type, variant, num )
    local count = 0
    local entities = Isaac.GetRoomEntities()
    for i=1, #entities do
        local e = entities[ i ]
        if e.Type == type and e.Variant == variant then
            count = count + 1
        end
    end
    for i=count+1, num do
        local ent = Isaac.Spawn( type, variant, 0, player.Position, Vector(0, 0), player ):ToFamiliar( )
        --ent:ClearEntityFlags( EntityFlag.FLAG_APPEAR )
    end
end

function IMD:onCache( _, cacheFlag ) --called whenever an item changes a stat
    local player = Isaac.GetPlayer( 0 )
	if cacheFlag == CacheFlag.CACHE_FAMILIARS then
        setDebug( "cache familiars" )
        local count = 1
		local bulbanum = player:GetCollectibleNum( bulbasaur.item )
		if bulbanum > 0 then
            spawnFamiliar( player, bulbasaur.type, bulbasaur.variant, count )
		end
        local charmnum = player:GetCollectibleNum( charmander.item )
        if charmnum > 0 then
            spawnFamiliar( player, charmander.type, charmander.variant, count )
        end
	end
end

debug_text = "this works"
cleardebug = 0
function IMD:onRender( ) --solely for debugging purposes
    Isaac.RenderText( str( debug_text ), 100, 100, 255, 0, 0, 255 )
    cleardebug = cleardebug + 1 --ticking up cleardebug so that it clears the debug text every 5 seconds
    ptr = 0
    if cleardebug == 60 and (debug_text == ">" or debug_text == " ") then --every second
        cleardebug = 0
        if debug_text == ">" then debug_text = " " --toggle off the ">"
        elseif debug_text == " " then debug_text = ">" --makes it blink with a ">" every second if no other debug text is being displayed
        end
    end
    if cleardebug == 300 then --every 5 seconds
        debug_text = ">"
        cleardebug = 0
    end
end

IMD:AddCallback( ModCallbacks.MC_POST_RENDER, IMD.onRender ) --for every frame rendered, call onRender
IMD:AddCallback( ModCallbacks.MC_EVALUATE_CACHE, IMD.onCache ) --for every item the player picks up, call onCache
