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

    -- setup slog()
        local function slog(str)
            log("&7[&6CivZoneHud&7]§f "..str)
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

    --gets a file from a url and puts it in a table
    local function getFile(url, timeout)
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

    local function getFileStringFromURL(url)
        --function initialization
            --initialize function table
                local FUNC = {}
            --store arguments in known scoped table
                FUNC.url = url

        -- get file from URL and store each line in array
        local fileResults = getFile(FUNC.url, 10000)
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

    local function formatGitZonesToUseable(gitZone)
        --function initialization
            --initialize function table
                local FUNC = {}
            --store arguments in known scoped table
                FUNC.gitZone = gitZone

        FUNC.useableZones = {}

        for key,value in pairs(FUNC.gitZone["features"]) do
            FUNC.i = key
            FUNC.name = FUNC.gitZone["features"][FUNC.i]["name"]
            FUNC.polygon = FUNC.gitZone["features"][FUNC.i]["polygon"]
            FUNC.useableZones[FUNC.name] = FUNC.polygon
        end

        return FUNC.useableZones
    end

-- Main program

    --initialize MAIN table
    --Stores variables for just MAIN function
        local MAIN = {}

    -- get zone data from GitHub

        slog("Downloading zones")
        MAIN.fileString = getFileStringFromURL("https://raw.githubusercontent.com/ccmap/data/master/land_claims.civmap.json")
        
        MAIN.fileString = false

        -- end script if download failed
            if MAIN.fileString == false then
                slog("Failed to download zones. Ending script.")
                return 0
            end

        slog("Parsing zones")
        MAIN.zoneJson = formatGitZonesToUseable(json.decode(MAIN.fileString))

        slog("Started displaying zones")
        
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

                -- make list of all zones the player is currently inside
                    MAIN.insideZones = {}

                    -- for each polygon
                    for key,value in pairs(MAIN.zoneJson) do
                        -- put args in safe table
                            MAIN.zoneName = key
                            MAIN.polygon = value

                        -- count how many poly parts player is inside of.
                        -- odd == inside polygon. even == outside polygon
                            MAIN.insidePolyParts = 0
                            -- for each poly part
                            for key,value in pairs(MAIN.polygon) do
                                -- put args in safe table
                                    MAIN.polyPart = value

                                if insidePolygon(MAIN.polyPart, MAIN.point) then
                                    MAIN.insidePolyParts = MAIN.insidePolyParts + 1
                                end
                            end

                            -- if MAIN.insidePolyParts is odd
                            if MAIN.insidePolyParts % 2 ~= 0 then
                                -- add polygon to list of polygons player is inside of
                                    -- replace "\n"s in name with " "
                                    MAIN.zoneName = string.gsub(MAIN.zoneName, "\n", " ")
                                    MAIN.insideZones[#MAIN.insideZones+1] = MAIN.zoneName
                            end
                    end

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
        sleep(1000)
    end
    