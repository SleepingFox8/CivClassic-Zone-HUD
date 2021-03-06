-- initialization 
    -- initialize tables
        --initialize GLBL table if needed
            if GLBL == nil then
                GLBL = {}
            end

        --initialize SCRIPT table
        --Stores global variables for just this script
            local SCRIPT = {}

    -- import denendancies
        local json = require ("./json.lua/json")
        local compTools = require ("./AM-CompTools/compTools")

    -- setup SCRIPT.slog()
        function SCRIPT.slog(str)
            log("&7[&6CivZoneHud&7]§f "..str)
        end

    -- toggle this script off if it is already running
        if compTools.anotherInstanceOfThisScriptIsRunning() then
            compTools.stopOtherInstancesOfThisScript()
            SCRIPT.slog("GUI stopped")
            GLBL.GUI.zone.disableDraw()
            -- silently end this script
                return 0
        end

-- function declaration

    function SCRIPT.pointInPolyPart(x,z,polygon)
        --function initialization
            --initialize function table
                local FUNC = {}
            --store arguments in known scoped table
                FUNC.x,FUNC.z,FUNC.polygon = x,z,polygon

        local oddNodes = false
        local j = #FUNC.polygon
        for i = 1, #FUNC.polygon do
            if (FUNC.polygon[i][2] < FUNC.z and FUNC.polygon[j][2] >= FUNC.z or FUNC.polygon[j][2] < FUNC.z and FUNC.polygon[i][2] >= FUNC.z) then
                if (FUNC.polygon[i][1] + ( FUNC.z - FUNC.polygon[i][2] ) / (FUNC.polygon[j][2] - FUNC.polygon[i][2]) * (FUNC.polygon[j][1] - FUNC.polygon[i][1]) < FUNC.x) then
                    oddNodes = not oddNodes;
                end
            end
            j = i;
        end
        return oddNodes 
    end

    --gets a file from a url and puts it in a table
    function SCRIPT.getFile(url, timeout)
        local settings={}
        if not timeout then
            settings.httpTimeout=10000
        else
            settings.httpTimeout=timeout
        end
        local http=httpRequest({url=url}, {url=url, requestMethod="GET", timeout=settings.httpTimeout})
        local file=http["input"]
        local err=http.getResponseCode()

        -- return error if http is not the 200 aka "OK" status
            if err ~= 200 then
                return false
            end

        local line=file:readLine()
        local output={}
        while line~=nil do
            table.insert(output, line)
            line=file:readLine()
        end
        return output
    end

    function SCRIPT.getFileStringFromURL(url)
        --function initialization
            --initialize function table
                local FUNC = {}
            --store arguments in known scoped table
                FUNC.url = url

        -- get file from URL and store each line in array
        local fileResults = SCRIPT.getFile(FUNC.url, 10000)
        -- propagate any errors to function caller
            if fileResults == false then
                return false
            end
        -- put all file lines into one string
            local fileString = ""
            for key,value in pairs(fileResults) do 
                fileString = fileString..value.."\n"
            end
        return fileString
    end

    function SCRIPT.pointInPolygon(x,z,polygon)
        --function initialization
            --initialize function table
                local FUNC = {}
            --store arguments in known scoped table
                FUNC.x,FUNC.z,FUNC.polygon = x,z,polygon

        -- count how many poly parts the point is inside of.
        -- odd == inside polygon. even == outside polygon
            FUNC.insidePolyParts = 0
            -- for each poly part
            for key,value in pairs(FUNC.polygon) do
                -- put args in safe table
                    FUNC.polyPart = value

                if SCRIPT.pointInPolyPart(FUNC.x, FUNC.z, FUNC.polyPart) then
                    FUNC.insidePolyParts = FUNC.insidePolyParts + 1
                end
            end

        -- if FUNC.insidePolyParts is odd
        if FUNC.insidePolyParts % 2 ~= 0 then
            return true
        else
            return false
        end
    end

-- Main program

    --initialize MAIN table
    --Stores variables for just MAIN function
        local MAIN = {}

    -- download data from GitHub

        SCRIPT.slog("Downloading zones")
        -- download land_claims
            MAIN.landClaimsString = SCRIPT.getFileStringFromURL("https://raw.githubusercontent.com/ccmap/data/master/land_claims.civmap.json")
            -- end script if download failed
                if MAIN.landClaimsString == false then
                    SCRIPT.slog("Failed to download land claims. Ending script.")
                    return 0
                end
            MAIN.landClaimsJson = json.decode(MAIN.landClaimsString)

        -- download exclusion zones
            MAIN.exclusionZonesString = SCRIPT.getFileStringFromURL("https://raw.githubusercontent.com/ccmap/data/master/exclusion_zones.civmap.json")
            -- end script if download failed
                if MAIN.exclusionZonesString == false then
                    SCRIPT.slog("Failed to download exclusion zones. Ending script.")
                    return 0
                end
            MAIN.exclusionZonesData = json.decode(MAIN.exclusionZonesString)

    SCRIPT.slog("Started displaying zones")

    -- provide link to player's current location on ccmap
        MAIN.x, _, MAIN.z = getPlayerBlockPos()
        MAIN.ccmapLink = "https://ccmap.github.io/#c=".. MAIN.x ..",".. MAIN.z ..",r200"
        log("&7[&6CivZoneHud&7]§f &L&ULocation on ccmap", MAIN.ccmapLink)
        
    -- initialize GUI table
        GLBL.GUI = GLBL.GUI or {}

    while true do
        -- render zone as text in top left of screen
            -- determine current zone

                MAIN.outputLandClaimsGuiString = "Unknown"

                -- get player's position
                    MAIN.pX, MAIN.pY, MAIN.pZ = getPlayerPos()

                -- make list of all zones the player is currently inside
                    MAIN.insideLandClaims = {}

                    -- for each polygon/feature
                    for key,value in pairs(MAIN.landClaimsJson.features) do
                        -- put args in safe table

                            MAIN.feature = value

                            MAIN.zoneName = MAIN.feature.name
                            MAIN.polygon = MAIN.feature.polygon

                        -- count how many poly parts player is inside of.
                        -- odd == inside polygon. even == outside polygon
                            MAIN.insidePolyParts = 0
                            -- for each poly part
                            for key,value in pairs(MAIN.polygon) do
                                -- put args in safe table
                                    MAIN.polyPart = value

                                if SCRIPT.pointInPolyPart(MAIN.pX, MAIN.pZ, MAIN.polyPart) then
                                    MAIN.insidePolyParts = MAIN.insidePolyParts + 1
                                end
                            end

                            -- if MAIN.insidePolyParts is odd
                            if MAIN.insidePolyParts % 2 ~= 0 then
                                -- add polygon to list of polygons player is inside of
                                    -- replace "\n"s in name with " "
                                    MAIN.zoneName = string.gsub(MAIN.zoneName, "\n", " ")
                                    MAIN.insideLandClaims[#MAIN.insideLandClaims+1] = MAIN.zoneName
                            end
                    end

                -- turn answers into string
                    if #MAIN.insideLandClaims > 0 then
                        MAIN.outputLandClaimsGuiString = ""
                        for key,value in pairs(MAIN.insideLandClaims) do
                            MAIN.zoneNameToAppend = value
                            MAIN.outputLandClaimsGuiString = MAIN.outputLandClaimsGuiString .. MAIN.zoneNameToAppend .. "\n"
                        end
                    end

            -- determine exclusion zone
                MAIN.insideExclusionZones = {}

                for key,value in pairs(MAIN.exclusionZonesData.features) do
                    -- put args in safe table
                        MAIN.feature = value

                    -- rectangular
                    if MAIN.feature.rectangle ~= nil then

                        -- find x range
                            if MAIN.feature.rectangle[1][1] >= MAIN.feature.rectangle[2][1] then
                                MAIN.highestX = MAIN.feature.rectangle[1][1]
                                MAIN.lowestX = MAIN.feature.rectangle[2][1]
                            else
                                MAIN.highestX = MAIN.feature.rectangle[2][1]
                                MAIN.lowestX = MAIN.feature.rectangle[1][1]
                            end
                        -- find z range
                            if MAIN.feature.rectangle[1][2] >= MAIN.feature.rectangle[2][2] then
                                MAIN.highestZ = MAIN.feature.rectangle[1][2]
                                MAIN.lowestZ = MAIN.feature.rectangle[2][2]
                            else
                                MAIN.highestZ = MAIN.feature.rectangle[2][2]
                                MAIN.lowestZ = MAIN.feature.rectangle[1][2]
                            end

                        -- determine if player inside exclusion zone
                            MAIN.px, _, MAIN.pz = getPlayerPos()

                            -- if player inside rectangle
                            if MAIN.px <= MAIN.highestX and MAIN.px >= MAIN.lowestX and MAIN.pz <= MAIN.highestZ and MAIN.pz >= MAIN.lowestZ then
                                -- replace "\n"s in name with " "
                                MAIN.exclusionZoneName = string.gsub(MAIN.feature.name, "\n", " ")
                                -- append name of exclusion zone to list of exclusion zones player is inside of
                                MAIN.insideExclusionZones[#MAIN.insideExclusionZones+1] = MAIN.exclusionZoneName
                            end
                    -- polygon
                    elseif MAIN.feature.polygon ~= nil then
                        MAIN.px, _, MAIN.pz = getPlayerPos()
                        if SCRIPT.pointInPolygon(MAIN.px, MAIN.pz, MAIN.feature.polygon) then
                            -- replace "\n"s in name with " "
                            MAIN.exclusionZoneName = string.gsub(MAIN.feature.name, "\n", " ")
                            -- append name of exclusion zone to list of exclusion zones player is inside of
                            MAIN.insideExclusionZones[#MAIN.insideExclusionZones+1] = MAIN.exclusionZoneName
                        end
                    end
                end

                -- determine exclusion zone string
                    if #MAIN.insideExclusionZones > 0 then
                        MAIN.outputExclusionZoneGuiString = "Exclusion Zone: "..MAIN.insideExclusionZones[1]
                    else
                        MAIN.outputExclusionZoneGuiString = ""
                    end

            -- erase old render if it was rendered
                if GLBL.GUI.zone ~= nil then
                    GLBL.GUI.zone.disableDraw()
                end
            -- render the HUD

                -- determine state of flashing symbol
                    if SCRIPT.flashing == nil then
                        SCRIPT.flashing = false
                    else
                        SCRIPT.flashing = not SCRIPT.flashing
                    end

                -- determine flash symbol character
                    if SCRIPT.flashing == true then
                        MAIN.flashingSymbol = "█"
                    else
                        MAIN.flashingSymbol = ":  "
                    end

                -- set exclusion zone color
                    if SCRIPT.flashing == false then
                        MAIN.exclusionZoneColorString = "&c"
                    else
                        MAIN.exclusionZoneColorString = "&f"
                    end
                

                MAIN.drawn = 5
                GLBL.GUI.zone = hud2D.newText("Land Claim"..MAIN.flashingSymbol.." "..MAIN.outputLandClaimsGuiString..MAIN.exclusionZoneColorString..MAIN.outputExclusionZoneGuiString, 5, MAIN.drawn)
                GLBL.GUI.zone.enableDraw()
        sleep(1000)
    end
    