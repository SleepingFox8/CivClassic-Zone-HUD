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

    -- setup slog
        local function slog(str)
            log("&7[&6polyTest&7]§f "..str)
        end

    -- toggle this script off if it is already running
        if compTools.anotherInstanceOfThisScriptIsRunning() then
            compTools.stopOtherInstancesOfThisScript()
            slog("GUI stopped")
            GLBL.GUI.zone.disableDraw()
            -- silently end this script
                return 0
        end

-- function declaration

    local function insidePolygon(polygon, point)
        local oddNodes = false
        local j = #polygon
        for i = 1, #polygon do
            if (polygon[i][2] < point.z and polygon[j][2] >= point.z or polygon[j][2] < point.z and polygon[i][2] >= point.z) then
                if (polygon[i][1] + ( point.z - polygon[i][2] ) / (polygon[j][2] - polygon[i][2]) * (polygon[j][1] - polygon[i][1]) < point.x) then
                    oddNodes = not oddNodes;
                end
            end
            j = i;
        end
        return oddNodes 
    end

-- Main program

    --initialize MAIN table
    --Stores variables for just MAIN function
        local MAIN = {}


    slog("Started displaying current zones")

    -- get zone data from file
        MAIN.zoneJson = json.decode(compTools.readAll("./Public-CivClassic-Nodes/zones.json"))

        -- for key,value in pairs(MAIN.zoneJson) do
        --     log(key)
        -- end

    -- initialize GUI table
        GLBL.GUI = GLBL.GUI or {}

    while true do
        -- render zone as text in top left of screen
            -- determine current zone

                MAIN.outputGuiString = "Unknown"

                -- get and format player's position
                    MAIN.pX, MAIN.pY, MAIN.pZ = getPlayerPos()
                    MAIN.point = {}
                    MAIN.point.x = MAIN.pX
                    MAIN.point.z = MAIN.pZ

                MAIN.insideZones = {}
                for key,value in pairs(MAIN.zoneJson) do
                    -- put args in safe table
                        MAIN.zoneName = key
                        MAIN.polygon = value
                    MAIN.isInsideZone = insidePolygon(MAIN.polygon, MAIN.point)

                    if MAIN.isInsideZone then
                        MAIN.insideZones[#MAIN.insideZones+1] = MAIN.zoneName
                    end
                end

                -- MAIN.insideZones = compTools.sortTableByKeys(MAIN.insideZones)

                -- log(MAIN.insideZones)

                -- turn answers into string
                    if #MAIN.insideZones > 0 then
                        MAIN.outputGuiString = ""
                        for key,value in pairs(MAIN.insideZones) do
                            MAIN.zoneNameToAppend = value
                            MAIN.outputGuiString = MAIN.outputGuiString .. MAIN.zoneNameToAppend .. "\n"
                        end
                    end
                

            -- erase old render if it was rendered
                if GLBL.GUI.zone ~= nil then
                    GLBL.GUI.zone.disableDraw()
                end
            -- render the HUD
                MAIN.drawn = 5
                GLBL.GUI.zone = hud2D.newText("Current location: " .. MAIN.outputGuiString, 5, MAIN.drawn)
                GLBL.GUI.zone.enableDraw()
        sleep(100)
    end
    