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
        local line=file:readLine()
        local output={}
        while line~=nil do
            table.insert(output, line)
            line=file:readLine()
        end
        return output
    end

    local function getFileStringFromURL(url)
        local fileResults = getFile(url, 10000)
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

            -- log zones with multiple polygons
                -- if #FUNC.gitZone["features"][FUNC.i]["polygon"] ~= 1 then
                --     slog(FUNC.name)
                --     slog(#FUNC.gitZone["features"][FUNC.i]["polygon"])
                -- end
            
            FUNC.polygon = FUNC.gitZone["features"][FUNC.i]["polygon"][1]

            FUNC.useableZones[FUNC.name] = FUNC.polygon
        end

        return FUNC.useableZones
    end

-- Main program

    --initialize MAIN table
    --Stores variables for just MAIN function
        local MAIN = {}


    slog("Started displaying current zones")

    -- get zone data from file
        -- MAIN.zoneJson = json.decode(compTools.readAll("./Public-CivClassic-Nodes/zones.json"))

    -- get zone data from GitHub

        slog("downloading zones")
        MAIN.fileString = getFileStringFromURL("https://raw.githubusercontent.com/SleepingFox8/data/master/land_claims.civmap.json")

        slog("parsing git zones")
        MAIN.zoneJson = formatGitZonesToUseable(json.decode(MAIN.fileString))
        slog("done parsing git")
        

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

                        -- replace "\n"s in name with " "
                        MAIN.zoneName = string.gsub(MAIN.zoneName, "\n", " ")
                        MAIN.insideZones[#MAIN.insideZones+1] = MAIN.zoneName
                    end
                end

                -- MAIN.insideZones = compTools.sortTableByKeys(MAIN.insideZones)

                -- slog(MAIN.insideZones)

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
        -- slog("rendered")
    end
    