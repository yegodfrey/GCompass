local PI = math.pi

-- Localization
local L = {
    CONFIG_TITLE = {
        enUS = "GCompass Configuration",
        zhCN = "GCompass 配置"
    },
    MINIMAP_LINE = {
        enUS = "Enable Minimap Line",
        zhCN = "启用小地图线"
    },
    WORLD_MAP_LINE = {
        enUS = "Enable World Map Line",
        zhCN = "启用世界地图线"
    },
    MINIMAP_THICKNESS = {
        enUS = "Minimap Line Thickness",
        zhCN = "小地图线粗细"
    },
    WORLD_MAP_THICKNESS = {
        enUS = "World Map Line Thickness",
        zhCN = "世界地图线粗细"
    },
    LINE_COLOR = {
        enUS = "Line Color",
        zhCN = "线条颜色"
    },
    CLOSE = {
        enUS = "Close",
        zhCN = "关闭"
    },
    MINIMAP_ENABLED = {
        enUS = "Minimap line enabled",
        zhCN = "小地图线已启用"
    },
    MINIMAP_DISABLED = {
        enUS = "Minimap line disabled",
        zhCN = "小地图线已禁用"
    },
    WORLD_MAP_ENABLED = {
        enUS = "World map line enabled",
        zhCN = "世界地图线已启用"
    },
    WORLD_MAP_DISABLED = {
        enUS = "World map line disabled",
        zhCN = "世界地图线已禁用"
    }
}

local function GetLocalizedString(key)
    return L[key][GetLocale()] or L[key].enUS
end

-- Initialize saved variables
GCompassDB = GCompassDB or {
    minimapEnabled = true,
    worldMapEnabled = true,
    minimapLineThickness = 2,
    worldMapLineThickness = 2,
    lineColor = { r = 1, g = 0, b = 0, a = 0.8 }
}

-- Minimap Line Setup
local minimapFrame = CreateFrame('Frame', nil, Minimap)
minimapFrame:SetAllPoints()

local minimapTexture = minimapFrame:CreateTexture(nil, 'BACKGROUND')
minimapTexture:SetTexture('Interface/Buttons/WHITE8x8')
minimapTexture:SetSize(GCompassDB.minimapLineThickness, minimapFrame:GetWidth() / 2)
minimapTexture:SetPoint('BOTTOM', minimapFrame, 'CENTER')

local function UpdateMinimapTexture()
    minimapTexture:SetVertexColor(GCompassDB.lineColor.r, GCompassDB.lineColor.g, GCompassDB.lineColor.b, GCompassDB.lineColor.a)
    minimapTexture:SetSize(GCompassDB.minimapLineThickness, minimapFrame:GetWidth() / 2)
end
UpdateMinimapTexture()

local minimapAnimGroup = minimapFrame:CreateAnimationGroup()
local minimapRotation = minimapAnimGroup:CreateAnimation('Rotation')
minimapRotation:SetOrigin('BOTTOM', 0, 0)
minimapRotation:SetDuration(0)
minimapRotation:SetEndDelay(1)

local function MinimapOnUpdate(self)
    self:Pause()
    self:SetScript('OnUpdate', nil)
end

local function MinimapOnPlay(self)
    self:SetScript('OnUpdate', MinimapOnUpdate)
end

minimapRotation:SetScript('OnPlay', MinimapOnPlay)
minimapAnimGroup:Play()
minimapRotation:Play()

-- World Map Line Setup
local cachedMapData = {}
local function GetMapSize()
    if cachedMapData.isValid then
        return unpack(cachedMapData)
    end
    local currentMapID = WorldMapFrame:GetMapID()
    if not currentMapID then return end
    
    local mapID, topleft = C_Map.GetWorldPosFromMapPos(currentMapID, {x = 0, y = 0})
    local mapID, bottomright = C_Map.GetWorldPosFromMapPos(currentMapID, {x = 1, y = 1})
    if not mapID then return end
    
    local left, top = topleft.y, topleft.x
    local right, bottom = bottomright.y, bottomright.x
    local width, height = left - right, top - bottom
    cachedMapData = { left, top, right, bottom, width, height, mapID, isValid = true }
    return left, top, right, bottom, width, height, mapID
end

local function GetIntersect(px, py, a, sx, sy, ex, ey)
    if a then 
        a = (a + PI / 2) % (PI * 2)
        local dx, dy = -math.cos(a), math.sin(a)
        local d = dx * (sy - ey) + dy * (ex - sx)
        if d ~= 0 and dx ~= 0 then
            local s = (dx * (sy - py) - dy * (sx - px)) / d
            if s >= 0 and s <= 1 then
                local r = (sx + (ex - sx) * s - px) / dx
                if r >= 0 then
                    return sx + (ex - sx) * s, sy + (ey - sy) * s, r, s
                end
            end
        end
    end
end

local worldMapButton = WorldMapFrame:GetCanvas()
local lineFrame = CreateFrame('Frame', nil, worldMapButton)
lineFrame:SetAllPoints()
lineFrame:SetFrameLevel(15000)

local startPoint = CreateFrame('Frame', nil, lineFrame)
startPoint:SetSize(1, 1)
local endPoint = CreateFrame('Frame', nil, lineFrame)
endPoint:SetSize(1, 1)

local worldMapLine = lineFrame:CreateLine(nil, 'OVERLAY')
worldMapLine:Hide()
worldMapLine:SetTexture('Interface/Buttons/WHITE8x8')
worldMapLine:SetThickness(GCompassDB.worldMapLineThickness)
worldMapLine:SetStartPoint('CENTER', startPoint, 0, 0)
worldMapLine:SetEndPoint('CENTER', endPoint, 0, 0)

local function UpdateWorldMapLine()
    worldMapLine:SetVertexColor(GCompassDB.lineColor.r, GCompassDB.lineColor.g, GCompassDB.lineColor.b, GCompassDB.lineColor.a)
    worldMapLine:SetThickness(GCompassDB.worldMapLineThickness / WorldMapFrame:GetCanvas():GetScale())
end
UpdateWorldMapLine()

local worldMapUpdated, playerFacing = false, 0

-- Configuration Panel
local configFrame = CreateFrame("Frame", "GCompassConfigFrame", UIParent, "BasicFrameTemplateWithInset")
configFrame:SetSize(400, 450)
configFrame:SetPoint("CENTER")
configFrame:Hide()
configFrame:SetMovable(true)
configFrame:EnableMouse(true)
configFrame:RegisterForDrag("LeftButton")
configFrame:SetScript("OnDragStart", configFrame.StartMoving)
configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)

local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -10)
title:SetText(GetLocalizedString("CONFIG_TITLE"))

local minimapToggle = CreateFrame("CheckButton", nil, configFrame, "UICheckButtonTemplate")
minimapToggle:SetPoint("TOPLEFT", 20, -50)
minimapToggle.Text:SetText(GetLocalizedString("MINIMAP_LINE"))
minimapToggle:SetChecked(GCompassDB.minimapEnabled)
minimapToggle:SetScript("OnClick", function(self)
    GCompassDB.minimapEnabled = self:GetChecked()
    print(GetLocalizedString(GCompassDB.minimapEnabled and "MINIMAP_ENABLED" or "MINIMAP_DISABLED"))
end)

local worldMapToggle = CreateFrame("CheckButton", nil, configFrame, "UICheckButtonTemplate")
worldMapToggle:SetPoint("TOPLEFT", 20, -80)
worldMapToggle.Text:SetText(GetLocalizedString("WORLD_MAP_LINE"))
worldMapToggle:SetChecked(GCompassDB.worldMapEnabled)
worldMapToggle:SetScript("OnClick", function(self)
    GCompassDB.worldMapEnabled = self:GetChecked()
    print(GetLocalizedString(GCompassDB.worldMapEnabled and "WORLD_MAP_ENABLED" or "WORLD_MAP_DISABLED"))
end)

local minimapThicknessSlider = CreateFrame("Slider", nil, configFrame, "OptionsSliderTemplate")
minimapThicknessSlider:SetPoint("TOPLEFT", 20, -120)
minimapThicknessSlider:SetWidth(360)
minimapThicknessSlider:SetMinMaxValues(1, 5)
minimapThicknessSlider:SetValueStep(0.1)
minimapThicknessSlider:SetValue(GCompassDB.minimapLineThickness)
minimapThicknessSlider.Text:SetText(GetLocalizedString("MINIMAP_THICKNESS"))
minimapThicknessSlider.Low:SetText("1")
minimapThicknessSlider.High:SetText("5")
minimapThicknessSlider:SetScript("OnValueChanged", function(self, value)
    GCompassDB.minimapLineThickness = value
    minimapTexture:SetSize(value, minimapFrame:GetWidth() / 2)
end)

local worldMapThicknessSlider = CreateFrame("Slider", nil, configFrame, "OptionsSliderTemplate")
worldMapThicknessSlider:SetPoint("TOPLEFT", 20, -180)
worldMapThicknessSlider:SetWidth(360)
worldMapThicknessSlider:SetMinMaxValues(1, 5)
worldMapThicknessSlider:SetValueStep(0.1)
worldMapThicknessSlider:SetValue(GCompassDB.worldMapLineThickness)
worldMapThicknessSlider.Text:SetText(GetLocalizedString("WORLD_MAP_THICKNESS"))
worldMapThicknessSlider.Low:SetText("1")
worldMapThicknessSlider.High:SetText("5")
worldMapThicknessSlider:SetScript("OnValueChanged", function(self, value)
    GCompassDB.worldMapLineThickness = value
    worldMapLine:SetThickness(value / WorldMapFrame:GetCanvas():GetScale())
end)

local colorLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
colorLabel:SetPoint("TOPLEFT", 20, -240)
colorLabel:SetText(GetLocalizedString("LINE_COLOR"))

local function ShowColorPicker(color, callback)
    ColorPickerFrame:SetupColorPickerAndShow({
        r = color.r, g = color.g, b = color.b, opacity = color.a,
        hasOpacity = true,
        swatchFunc = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local a = ColorPickerFrame:GetColorAlpha()
            color.r, color.g, color.b, color.a = r, g, b, a
            callback()
        end,
        opacityFunc = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local a = ColorPickerFrame:GetColorAlpha()
            color.r, color.g, color.b, color.a = r, g, b, a
            callback()
        end,
        cancelFunc = function(previous)
            color.r, color.g, color.b, color.a = previous.r, previous.g, previous.b, previous.a
            callback()
        end
    })
end

local colorButton = CreateFrame("Button", nil, configFrame)
colorButton:SetPoint("TOPLEFT", 20, -270)
colorButton:SetSize(20, 20)
colorButton:SetNormalTexture("Interface/Buttons/WHITE8x8")
colorButton:GetNormalTexture():SetVertexColor(GCompassDB.lineColor.r, GCompassDB.lineColor.g, GCompassDB.lineColor.b, GCompassDB.lineColor.a)
colorButton:SetScript("OnClick", function()
    ShowColorPicker(GCompassDB.lineColor, function()
        colorButton:GetNormalTexture():SetVertexColor(GCompassDB.lineColor.r, GCompassDB.lineColor.g, GCompassDB.lineColor.b, GCompassDB.lineColor.a)
        UpdateMinimapTexture()
        UpdateWorldMapLine()
    end)
end)

local closeButton = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
closeButton:SetPoint("BOTTOM", 0, 20)
closeButton:SetSize(100, 25)
closeButton:SetText(GetLocalizedString("CLOSE"))
closeButton:SetScript("OnClick", function() configFrame:Hide() end)

-- Slash Command Handler
SLASH_GCOMPASS1 = "/gcompass"
SlashCmdList["GCOMPASS"] = function()
    configFrame:SetShown(not configFrame:IsShown())
end

-- Combined Update Logic
local lastUpdate = 0
local UPDATE_INTERVAL = 0.1
local updateFrame = CreateFrame('Frame')
updateFrame:SetScript('OnUpdate', function(self, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate < UPDATE_INTERVAL then return end
    lastUpdate = 0

    -- Early exit for instances, scenarios, or vehicles
    if IsInInstance() or C_Scenario.IsInScenario() or UnitInVehicle("player") then
        if GCompassDB.minimapEnabled then minimapFrame:Hide() end
        if GCompassDB.worldMapEnabled then worldMapLine:Hide() end
        return
    end

    local facing = GetPlayerFacing()
    if not facing then
        if GCompassDB.minimapEnabled then minimapFrame:Hide() end
        if GCompassDB.worldMapEnabled then worldMapLine:Hide() end
        return
    end

    -- Minimap Update
    if GCompassDB.minimapEnabled and Minimap:IsShown() then
        minimapFrame:Show()
        minimapRotation:SetRadians(GetCVarBool('rotateMinimap') and 0 or facing)
    else
        minimapFrame:Hide()
    end

    -- World Map Update (only when world map is open)
    if GCompassDB.worldMapEnabled and WorldMapFrame:IsShown() then
        local isGliding, canGlide, forwardSpeed = C_PlayerInfo.GetGlidingInfo()
        local speed = isGliding and forwardSpeed or GetUnitSpeed("player")

        if worldMapUpdated or speed > 0 or facing ~= playerFacing then
            worldMapUpdated = false
            playerFacing = facing
            worldMapLine:Hide()

            if UnitOnTaxi('player') then
                return
            end

            local bestMap = C_Map.GetBestMapForUnit("player")
            if not bestMap then
                return
            end

            local playerMapPos = C_Map.GetPlayerMapPosition(bestMap, "player")
            if not playerMapPos then
                return
            end

            local pMapID, loc = C_Map.GetWorldPosFromMapPos(bestMap, {x=playerMapPos.x, y=playerMapPos.y})
            local px, py = loc.y, loc.x
            if not px then
                return
            end

            local left, top, right, bottom, width, height, mapMapID = GetMapSize()
            if not width or width == 0 then
                return
            end

            local sameInstanceish = pMapID == mapMapID
            local onMap = false
            local mx, my = 0, 0
            if sameInstanceish and (px <= left and px >= right and py <= top and py >= bottom) then
                mx, my = (left - px) / width, (top - py) / height
                onMap = true
            end

            if mapMapID == pMapID or onMap or sameInstanceish then
                local topX, topY, topRi, topSi = GetIntersect(px, py, facing, left, top, right, top)
                local bottomX, bottomY, bottomRi, bottomSi = GetIntersect(px, py, facing, left, bottom, right, bottom)
                local leftX, leftY, leftRi, leftSi = GetIntersect(px, py, facing, left, top, left, bottom)
                local rightX, rightY, rightRi, rightSi = GetIntersect(px, py, facing, right, top, right, bottom)

                local mx1, my1, mr1, ms1
                local mx2, my2, mr2, ms2
                local m1Side, m2Side

                if topX then
                    mx1, my1, mr1, ms1 = topX, topY, topRi, topSi
                    m1Side = 'top'
                end
                if bottomX then
                    if not mx1 then
                        mx1, my1, mr1, ms1 = bottomX, bottomY, bottomRi, bottomSi
                        m1Side = 'bottom'
                    else
                        mx2, my2, mr2, ms2 = bottomX, bottomY, bottomRi, bottomSi
                        m2Side = 'bottom'
                    end
                end
                if leftX then
                    if not mx1 then
                        mx1, my1, mr1, ms1 = leftX, leftY, leftRi, leftSi
                        m1Side = 'left'
                    else
                        mx2, my2, mr2, ms2 = leftX, leftY, leftRi, leftSi
                        m2Side = 'left'
                    end
                end
                if rightX then
                    if not mx1 then
                        mx1, my1, mr1, ms1 = rightX, rightY, rightRi, rightSi
                        m1Side = 'right'
                    else
                        mx2, my2, mr2, ms2 = rightX, rightY, rightRi, rightSi
                        m2Side = 'right'
                    end
                end

                local mWidth, mHeight = worldMapButton:GetSize()
                if m1Side and m2Side then
                    startPoint:ClearAllPoints()
                    endPoint:ClearAllPoints()
                    if mr1 < mr2 then
                        if m1Side == 'top' then
                            startPoint:SetPoint('CENTER', worldMapButton, 'TOPLEFT', mWidth * ms1, 0)
                        elseif m1Side == 'bottom' then
                            startPoint:SetPoint('CENTER', worldMapButton, 'BOTTOMLEFT', mWidth * ms1, 0)
                        elseif m1Side == 'left' then
                            startPoint:SetPoint('CENTER', worldMapButton, 'TOPLEFT', 0, -mHeight * ms1)
                        elseif m1Side == 'right' then
                            startPoint:SetPoint('CENTER', worldMapButton, 'TOPRIGHT', 0, -mHeight * ms1)
                        end

                        if m2Side == 'top' then
                            endPoint:SetPoint('CENTER', worldMapButton, 'TOPLEFT', mWidth * ms2, 0)
                        elseif m2Side == 'bottom' then
                            endPoint:SetPoint('CENTER', worldMapButton, 'BOTTOMLEFT', mWidth * ms2, 0)
                        elseif m2Side == 'left' then
                            endPoint:SetPoint('CENTER', worldMapButton, 'TOPLEFT', 0, -mHeight * ms2)
                        elseif m2Side == 'right' then
                            endPoint:SetPoint('CENTER', worldMapButton, 'TOPRIGHT', 0, -mHeight * ms2)
                        end
                    else
                        if m2Side == 'top' then
                            startPoint:SetPoint('CENTER', worldMapButton, 'TOPLEFT', mWidth * ms2, 0)
                        elseif m2Side == 'bottom' then
                            startPoint:SetPoint('CENTER', worldMapButton, 'BOTTOMLEFT', mWidth * ms2, 0)
                        elseif m2Side == 'left' then
                            startPoint:SetPoint('CENTER', worldMapButton, 'TOPLEFT', 0, -mHeight * ms2)
                        elseif m2Side == 'right' then
                            startPoint:SetPoint('CENTER', worldMapButton, 'TOPRIGHT', 0, -mHeight * ms2)
                        end
                        
                        if m1Side == 'top' then
                            endPoint:SetPoint('CENTER', worldMapButton, 'TOPLEFT', mWidth * ms1, 0)
                        elseif m1Side == 'bottom' then
                            endPoint:SetPoint('CENTER', worldMapButton, 'BOTTOMLEFT', mWidth * ms1, 0)
                        elseif m1Side == 'left' then
                            endPoint:SetPoint('CENTER', worldMapButton, 'TOPLEFT', 0, -mHeight * ms1)
                        elseif m1Side == 'right' then
                            endPoint:SetPoint('CENTER', worldMapButton, 'TOPRIGHT', 0, -mHeight * ms1)
                        end
                    end
                    worldMapLine:Show()
                elseif m1Side and onMap then
                    startPoint:SetPoint('CENTER', worldMapButton, 'TOPLEFT', mWidth * mx, -mHeight * my)
                    if m1Side == 'top' then
                        endPoint:SetPoint('CENTER', worldMapButton, 'TOPLEFT', mWidth * ms1, 0)
                    elseif m1Side == 'bottom' then
                        endPoint:SetPoint('CENTER', worldMapButton, 'BOTTOMLEFT', mWidth * ms1, 0)
                    elseif m1Side == 'left' then
                        endPoint:SetPoint('CENTER', worldMapButton, 'TOPLEFT', 0, -mHeight * ms1)
                    elseif m1Side == 'right' then
                        endPoint:SetPoint('CENTER', worldMapButton, 'TOPRIGHT', 0, -mHeight * ms1)
                    end
                    worldMapLine:Show()
                end
            end
        end
    elseif GCompassDB.worldMapEnabled then
        worldMapLine:Hide()
    end
end)

hooksecurefunc(WorldMapFrame, 'OnMapChanged', function()
    worldMapUpdated = true
    cachedMapData.isValid = false
end)

hooksecurefunc(WorldMapFrame, 'OnCanvasScaleChanged', function(self)
    local scale = self:GetCanvas():GetScale()
    worldMapLine:SetThickness(GCompassDB.worldMapLineThickness / scale)
end)