-- +1 Venom Evolution | School Hub diagnostic setup v0.1.1 | read-only, no gameplay actions
local SchoolHubTheme = (function()
-- School Hub Design v2. Canonical visual system for every game adapter.
-- Pure presentation: no IO, input hooks, game services or gameplay settings.
local Theme = {}
Theme.Version = "2.1.0"
Theme.Design = {
    windowWidth=760, windowHeight=680, headerHeight=72, sidebarWidth=152,
    headerInset=20, pageInset=20, gap=12,
    windowRadius=14, cardRadius=10, controlRadius=8, touchSize=44,
    titleSize=22, headingSize=22, bodySize=14, captionSize=12, motion=.16,
    strokeInset=1, accentOutlineTransparency=.32, tabOutlineTransparency=.22,
    rowPadding=12, rowGap=4, minRowHeight=56, minTouch=44,
}
Theme.Order = {"Citron", "Mint", "Blue", "Rose", "Violet", "Amber", "Custom"}
Theme.Presets = {Citron="#D3EF70", Mint="#75DEBD", Blue="#82B9FF", Rose="#F59CB6", Violet="#BB9BFA", Amber="#F3C46F"}

function Theme.Font(weight)
    if weight=="bold" then return Enum.Font.GothamBold end
    if weight=="medium" then return Enum.Font.GothamMedium end
    return Enum.Font.Gotham
end

local function finite(value)
    return type(value)=="number" and value==value and value~=math.huge and value~=-math.huge
end

-- A small presentation-only tween owner. Adapters inject the optional native
-- service; no timers, render hooks, service lookups or background tasks run here.
function Theme.CreateMotion(options)
    options=type(options)=="table" and options or {}
    local service,records,alive=options.TweenService,{},true
    local defaultDuration=finite(options.duration) and options.duration or Theme.Design.motion
    local function duration(value)
        value=finite(value) and value or defaultDuration
        return math.max(.05,math.min(.35,value))
    end
    local function same(a,b,depth)
        if a==b then return true end
        if type(a)~="table" or type(b)~="table" or depth<=0 then return false end
        for key,value in pairs(a) do if not same(value,b[key],depth-1) then return false end end
        for key in pairs(b) do if a[key]==nil then return false end end
        return true
    end
    local function apply(item,properties)
        for key,value in pairs(properties or {}) do pcall(function() item[key]=value end) end
    end
    local function stop(record)
        if record.connection then pcall(function() record.connection:Disconnect() end);record.connection=nil end
        local tween=record.tween;record.tween=nil
        if tween then pcall(function() tween:Cancel() end) end
    end
    local function transition(item,properties,seconds,initial)
        if not alive or item==nil or type(properties)~="table" then return false end
        local record=records[item]
        if not record then record={goals={}};records[item]=record end
        local changed=initial~=nil
        for key,value in pairs(properties) do
            if not same(record.goals[key],value,3) then changed=true end
            record.goals[key]=value
        end
        if not changed then return false end
        stop(record)
        if initial then apply(item,initial) end
        local info=TweenInfo
        if service and info and type(info.new)=="function" and Enum and Enum.EasingStyle and Enum.EasingDirection then
            local goals={}
            for key,value in pairs(record.goals) do goals[key]=value end
            local ok,tween=pcall(function()
                return service:Create(item,info.new(duration(seconds),Enum.EasingStyle.Quad,Enum.EasingDirection.Out),goals)
            end)
            if ok and tween then
                record.tween=tween
                if tween.Completed and type(tween.Completed.Connect)=="function" then
                    record.connection=tween.Completed:Connect(function()
                        if record.tween~=tween then return end
                        record.tween=nil
                        if record.connection then record.connection:Disconnect();record.connection=nil end
                    end)
                end
                local played=pcall(function() tween:Play() end)
                if played then return true end
                stop(record)
            end
        end
        apply(item,record.goals)
        return false
    end
    local motion={}
    function motion:To(item,properties,seconds) return transition(item,properties,seconds) end
    function motion:Start(item,initial,properties,seconds) return transition(item,properties,seconds,initial or {}) end
    function motion:Settle(item)
        local record=records[item]
        if record then stop(record);apply(item,record.goals) end
    end
    function motion:Clear(settle)
        for item,record in pairs(records) do
            stop(record)
            if settle then apply(item,record.goals) end
        end
        records={}
    end
    function motion:Destroy()
        if not alive then return end
        self:Clear(true);alive=false
    end
    return motion
end

-- Optional native measurement is supplied by the adapter. This module never
-- fetches a service; the fallback keeps offline and executor-limited UIs usable.
function Theme.MeasureText(value,size,width,font,service)
    local text=type(value)=="string" and value or tostring(value or "")
    if text=="" then return 0 end
    size=finite(size) and size>0 and math.min(size,256) or Theme.Design.bodySize
    width=finite(width) and math.max(1,width) or 1
    if service and Vector2 and type(Vector2.new)=="function" then
        local ok,height=pcall(function()
            local bounds=service:GetTextSize(text,size,font or Theme.Font(),Vector2.new(width,10000))
            return bounds and bounds.Y
        end)
        if ok and finite(height) and height>=0 then return math.ceil(height) end
    end
    local function advance(byte)
        if byte>=128 and byte<192 then return 0 end -- UTF-8 continuation byte.
        if byte>=192 then return size end -- Reserve a full glyph for non-ASCII text.
        local character=string.char(byte)
        if character:match("[ilI1%.,:;!|'`]") then return size*.3 end
        if character:match("[MW@#%%&]") then return size*.9 end
        return size*.56
    end
    local function wordWidth(word)
        local extent=0
        for index=1,#word do extent=extent+advance(word:byte(index)) end
        return extent
    end
    local lines=0
    for paragraph in (text.."\n"):gmatch("(.-)\n") do
        local lineWidth,paragraphLines=0,1
        for word in paragraph:gmatch("%S+") do
            local extent=wordWidth(word)
            local space=lineWidth>0 and size*.34 or 0
            if lineWidth>0 and lineWidth+space+extent>width then
                paragraphLines,lineWidth=paragraphLines+1,0
                space=0
            end
            if extent>width then
                for index=1,#word do
                    local glyph=advance(word:byte(index))
                    if glyph>0 then
                        if lineWidth>0 and lineWidth+glyph>width then paragraphLines,lineWidth=paragraphLines+1,0 end
                        lineWidth=lineWidth+glyph
                    end
                end
            else
                lineWidth=lineWidth+space+extent
            end
        end
        lines=lines+paragraphLines
    end
    return lines*math.ceil(size*1.2)
end

function Theme.ValidHex(value)
    return type(value)=="string" and value:match("^#%x%x%x%x%x%x$") and value:upper() or nil
end

local function channel(value)
    value=value/255
    return value<=.04045 and value/12.92 or ((value+.055)/1.055)^2.4
end
local function luminance(r,g,b)
    return .2126*channel(r)+.7152*channel(g)+.0722*channel(b)
end
local function contrast(a,b)
    return (math.max(a,b)+.05)/(math.min(a,b)+.05)
end

function Theme.Resolve(state)
    state=type(state)=="table" and state or {}
    local name=state.theme
    if name~="Custom" and not Theme.Presets[name] then name="Citron" end
    local hex=name=="Custom" and Theme.ValidHex(state.customAccent) or Theme.Presets[name]
    hex=hex or Theme.Presets.Citron
    local r,g,b=tonumber(hex:sub(2,3),16),tonumber(hex:sub(4,5),16),tonumber(hex:sub(6,7),16)
    local accent=Color3.fromRGB(r,g,b)
    local light=Color3.fromRGB(241,243,245)
    local dark=Color3.fromRGB(21,23,25)
    local accentLum=luminance(r,g,b)
    local lightLum,darkLum=luminance(241,243,245),luminance(21,23,25)
    local onAccent=contrast(accentLum,lightLum)>contrast(accentLum,darkLum) and light or dark
    if math.max(contrast(accentLum,lightLum),contrast(accentLum,darkLum))<4.5 then
        onAccent=accentLum>.179 and Color3.fromRGB(0,0,0) or Color3.fromRGB(255,255,255)
    end
    -- A dark custom color remains available on filled controls, while labels
    -- use readable foreground text rather than disappearing into the panel.
    local accentText=contrast(accentLum,luminance(30,33,37))>=4.5 and accent or light
    return {
        name=name, hex=hex, design=Theme.Design, CreateMotion=Theme.CreateMotion,
        panel=dark, sidebar=Color3.fromRGB(25,28,31),
        surface=Color3.fromRGB(30,33,37), hover=Color3.fromRGB(39,43,48),
        border=Color3.fromRGB(57,62,69), text=light,
        muted=Color3.fromRGB(184,191,200), quiet=Color3.fromRGB(157,166,178),
        input=Color3.fromRGB(24,27,30), danger=Color3.fromRGB(255,164,145),
        accent=accent, accentText=accentText, darkAccent=onAccent,
        accentSurface=Color3.fromRGB(math.floor(30*.86+r*.14),math.floor(33*.86+g*.14),math.floor(37*.86+b*.14)),
    }
end
return Theme

end)()

local SchoolHubBrand = (function()
-- Generated mark payload; local optional image support, no network dependency.
local Brand = {}
Brand.DiscordInvite = "https://discord.gg/tHwdHTyjyg"
local PNG = "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAMAAAD04JH5AAACRlBMVEVMaXH////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////59SwqAAAAwXRSTlMAVMB/0cLS1NmkRjfVgDvBhMM2hTiOvLpT1p88ordVgczfRUeqvpy/qD01SNh2eqUdPxHaE2Kb0HxsdA5y6eMu82Hl0+bXSrRdFiTLUPCnUqG7DFcSzmcrFKMXq+SCyZciDzR1iBgvnicbKvFkLR+mg0+wZg3iJY+YGpPglq7onSaZfbZN27EQWx69HJKR8kCQLDAhuMRx693qY8cyaZTvs2iVecV+IE54oF6MWWXNrCiv7DkzS6lJWntDXOcjOhWaKcqZ1AAAAAlwSFlzAAAD6AAAA+gBtXtSawAABN9JREFUeNrtm4dfFEcUx5c7POS4k+snHOROIFRBQAi9dxEEBQwq2LsxaoxKsSaaXu3GkthN7NH0tv9Zdu8ElZndfbszs+vHz/4+7N6Wd/O+n9nZmzdvBo4zZcqUKVMS2uuryj41Gh8fb7MJW3xMNlv0LLqfviTejl6Yuv78dvRKJJBaWPKRSvf/fL6Qp6p52SUq3N+y8AxkeQp07/mUZ6SOhxD/N3h26vlB0f1YgGeqVAX/ixJ4xvp+qaz/4zxzpcv4L73P6yCZp7CA10W1Uv7f43VSPt5/8Sq9APrxAPt53fQbzv/Nx/oBXMcBrOd1VAEG4Ds9ATCv4jsS3WiCIwEqhwNz0oovdgABKMfZ9Yb2kgY2b/+K7V3+QAz9GKsqOsEVrugixGoPauSnFd5loWUnIkZoEFS3lRYApn3lIEaz0PiFXoSLFt4CsEmlB4D2crMRGzdis4ceQCIAAK2BujGDAei9BRiAhRAAzMvKsAaScb9X7h2+Jx5fksfjE3ZJgqY+hUvCgS8pP8mzrYYhAESN8wJF29i0ARU66CMGSCfsYMdrCAGuknbxkS1qAOYzCImb1xHVwHIKOYA1JADEjUDQm0QAcymEeoUkAFyQHOBQMQmAh0IVVGrvCwQNkQMkkNQAx42QE+QRAXCVxAC3yQC4xa1Msg/DYACueLKRQQIGXgOC9oUHCQCSyQHEn+XdtWGr1em0ihI+nLFjcecUT53hcNjV24xNh1IBAI76XMxqAKrFRgNw1UYDLJ1Nrw0s23VRA8FP9ACEoVnFfnuZSoBOegCxsPz9tI+L1QC8AQNYoCYs3x6o/hYMsGxmwbPIAUTZ/MCHEQeLyvo0DEzqe5tOKgMsmVlwty8vb860QiFhmxPaFNQ2MurJKcpXWwNQgYdmtssflhkKIL4ZueWLqAPMVzc4/TJQuA72GmqvAbfSV2xft3cZ8wieq3XlhSPMANzAb7p//9m4GnimijgWbUBVhsRvNABvNfQRiGowGsBvNEC30QATXQYDrNpIllYhBqjXoQYqDsoVsBYPMOHa5fW6vC5R3phcGyorNAFMckfKsw5JAHwg0Qjx89JpmgAOi5f/3b26DQfwowRADhbgXU3xwNGpWyUbuqWib2BQmqgJ4L8X7n5zJtjzwi3HGikAC8V0/VsvG3zyZ279sztpKySzmwwBxEUuBa6+rL7CBpl4IJkpACC/S7MGjnIaBiaW16kGsumNjtkBzKXXCNGoOA0AUM7yLYgAAO5QTdHMVIai/7+vsHwEfKRUCWAlD8uQQCYscHNWlp2y7lc80J6otCE2m3Gd7tkDdzMyM+12e3Rnz4j+RQ8KMuP8zQSp2iBic4ynIugjOIDYtNMBCAIBdiA2G/+iApALBMBMNOdSAfDCAAKw3LsGLYEBDOGsBin4P/8ZCODcAM7qHgWAX2ATlxLrak+TA7SDAEYlftnymM3fzwCQ/FcDKynAVyCA9aoW/qmRC7SA4bBM97LWTeK/A7SGZFi2gysjWMXQXwoBGFfq4jdr9f+oBrCMp/GScpTVVKfJvxWyksqyCTINs/UL9e4D8jMbsfxAWxN0KmrfSJsa79tPFCgUKOYH3J2qJgRD17LcLSniCunYKukWcZV0ikM4FLaUlOiiaeHDEQmu7typWFpVTnUDZ8qUKVOmXlH9DzOnV/zHley1AAAAAElFTkSuQmCC"
local FILE = "school_hub_brand.6c09f310ccf0.png"
local cachedAsset, attempted
local currentAccent
local tinted = setmetatable({}, {__mode = "k"})
local function decode(value)
    local alphabet, lookup = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", {}
    for index = 1, #alphabet do lookup[alphabet:sub(index, index)] = index - 1 end
    local chunks = {}
    for index = 1, #value, 4 do
        local a, b = lookup[value:sub(index, index)], lookup[value:sub(index + 1, index + 1)]
        local c, d = lookup[value:sub(index + 2, index + 2)], lookup[value:sub(index + 3, index + 3)]
        if not a or not b then return nil end
        local number = a * 262144 + b * 4096 + (c or 0) * 64 + (d or 0)
        chunks[#chunks + 1] = string.char(math.floor(number / 65536) % 256)
        if c then chunks[#chunks + 1] = string.char(math.floor(number / 256) % 256) end
        if d then chunks[#chunks + 1] = string.char(number % 256) end
    end
    return table.concat(chunks)
end
local function asset()
    if attempted then return cachedAsset end
    attempted = true
    local env = _G
    if type(getgenv) == "function" then
        local ok, value = pcall(getgenv)
        if ok and type(value) == "table" then env = value end
    end
    local function first(names)
        for _, scope in ipairs({env, _G}) do
            for _, name in ipairs(names) do if type(scope[name]) == "function" then return scope[name] end end
        end
    end
    local writer, register = first({"writefile"}), first({"getcustomasset", "getsynasset"})
    if not writer or not register then return end
    local ok, value = pcall(function()
        local binary = decode(PNG)
        if not binary or binary:sub(1, 8) ~= "\137PNG\13\10\26\10" then return end
        writer(FILE, binary)
        local id = register(FILE)
        if type(id) == "string" and #id > 0 and #id <= 4096 then return id end
    end)
    if ok then cachedAsset = value end
    return cachedAsset
end
function Brand.SetAccent(color)
    if color == currentAccent then return end
    currentAccent = color
    for item, property in pairs(tinted) do
        local ok, attached = pcall(function() return item.Parent ~= nil end)
        if not ok or not attached then tinted[item] = nil
        else pcall(function() item[property] = color end) end
    end
end
function Brand.CreateMark(parent, x, y, size, color)
    local mark = Instance.new("Frame")
    mark.Name, mark.BackgroundTransparency, mark.BorderSizePixel = "SchoolHubMark", 1, 0
    mark.Position, mark.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(size, size)
    mark.Parent = parent
    local id = asset()
    if id then
        local logo = Instance.new("ImageLabel")
        logo.Name, logo.BackgroundTransparency, logo.BorderSizePixel = "SchoolHubLogo", 1, 0
        logo.Position, logo.Size = UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1)
        logo.Image, logo.ImageColor3 = id, color or currentAccent or Color3.fromRGB(211, 239, 112)
        if Enum.ScaleType then logo.ScaleType = Enum.ScaleType.Fit end
        logo.Parent = mark
        tinted[logo] = "ImageColor3"
    else
        local label = Instance.new("TextLabel")
        label.Name, label.BackgroundTransparency, label.BorderSizePixel = "SchoolHubMonogram", 1, 0
        label.Size, label.Text = UDim2.fromScale(1, 1), "SH"
        label.Font, label.TextSize = Enum.Font.GothamBold, math.floor(size * .49)
        label.TextColor3 = color or currentAccent or Color3.fromRGB(211, 239, 112)
        label.Parent = mark
        tinted[label] = "TextColor3"
    end
    return mark
end

-- One local community card is shared by every game and the license screen.
-- Joining is always a user action; this component only copies a public invite.
function Brand.CreateDiscord(parent, options)
    options = options or {}
    local alive, connections, bindings = true, {}, {}
    local colors = options.colors or {
        surface=Color3.fromRGB(30,33,37), input=Color3.fromRGB(24,27,30),
        border=Color3.fromRGB(57,62,69), text=Color3.fromRGB(241,243,245),
        muted=Color3.fromRGB(184,191,200), accent=Color3.fromRGB(211,239,112),
        darkAccent=Color3.fromRGB(21,23,25),
    }
    local function make(class, owner, properties, tokens)
        local item=Instance.new(class)
        for key,value in pairs(properties or {}) do item[key]=value end
        item.Parent=owner
        if tokens then bindings[item]=tokens end
        return item
    end
    local function connect(signal, callback)
        if signal and type(signal.Connect)=="function" then connections[#connections+1]=signal:Connect(callback) end
    end
    local function round(item, radius) make("UICorner",item,{CornerRadius=UDim.new(0,radius)}) end
    local function label(owner,name,value,size,token)
        return make("TextLabel",owner,{Name=name,BackgroundTransparency=1,BorderSizePixel=0,
            Text=value,TextSize=size,Font=Enum.Font.Gotham,TextColor3=colors[token],
            TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},
            {TextColor3=token})
    end
    local card=make("Frame",parent,{Name="DiscordCommunity",Position=UDim2.fromOffset(0,0),
        Size=UDim2.fromOffset(526,172),BackgroundColor3=colors.surface,BorderSizePixel=0},
        {BackgroundColor3="surface"})
    round(card,10)
    local title=label(card,"DiscordTitle","School Hub Discord",15,"text")
    title.Font=Enum.Font.GothamMedium
    local description=label(card,"DiscordDescription","Updates, key help and giveaways.",12,"muted")
    local invite=make("TextBox",card,{Name="DiscordInvite",Text=Brand.DiscordInvite,TextSize=14,
        Font=Enum.Font.Gotham,TextColor3=colors.text,BackgroundColor3=colors.input or colors.surface,
        BorderSizePixel=0,TextEditable=false,ClearTextOnFocus=false,MultiLine=false,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
        TextWrapped=true,Selectable=true},{TextColor3="text",BackgroundColor3=colors.input and "input" or "surface"})
    round(invite,8)
    make("UIStroke",invite,{Color=colors.border,Thickness=1,
        ApplyStrokeMode=Enum.ApplyStrokeMode and Enum.ApplyStrokeMode.Border or nil},{Color="border"})
    make("UIPadding",invite,{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)})
    local copy=make("TextButton",card,{Name="CopyDiscordInvite",Text="Copy invite",TextSize=14,
        Font=Enum.Font.GothamMedium,TextColor3=colors.darkAccent,BackgroundColor3=colors.accent,
        BorderSizePixel=0,AutoButtonColor=true},{TextColor3="darkAccent",BackgroundColor3="accent"})
    round(copy,8)
    local feedback=label(card,"DiscordFeedback","Copy the invite, then open Discord to join.",12,"muted")
    local api={frame=card}
    local currentWidth=526
    local function height(value,size,width,font)
        if type(options.measure)=="function" then return options.measure(value,size,width,font) end
        return math.ceil(math.max(1,#value*size*.56/math.max(1,width)))*math.ceil(size*1.2)
    end
    function api.Resize(width)
        if not alive then return 0 end
        currentWidth=math.max(180,tonumber(width) or currentWidth)
        local inner=currentWidth-24
        local titleHeight=math.max(20,height(title.Text,15,inner,title.Font))
        local descriptionHeight=math.max(16,height(description.Text,12,inner,description.Font))
        title.Position=UDim2.fromOffset(12,12);title.Size=UDim2.fromOffset(inner,titleHeight)
        local y=12+titleHeight+4
        description.Position=UDim2.fromOffset(12,y);description.Size=UDim2.fromOffset(inner,descriptionHeight)
        y=y+descriptionHeight+8
        local wide=inner>=420
        invite.Position=UDim2.fromOffset(12,y)
        invite.Size=UDim2.fromOffset(wide and inner-128 or inner,44)
        copy.Position=UDim2.fromOffset(wide and currentWidth-132 or 12,wide and y or y+52)
        copy.Size=UDim2.fromOffset(wide and 120 or inner,44)
        y=y+(wide and 52 or 104)
        local feedbackHeight=math.max(16,height("Clipboard unavailable. Select and copy the invite above.",12,inner,feedback.Font))
        feedback.Position=UDim2.fromOffset(12,y);feedback.Size=UDim2.fromOffset(inner,feedbackHeight)
        card.Size=UDim2.fromOffset(currentWidth,y+feedbackHeight+12)
        return card.Size.Y.Offset
    end
    function api.SetTheme(value)
        if not alive or type(value)~="table" then return end
        colors=value
        for item,tokens in pairs(bindings) do
            for property,token in pairs(tokens) do
                if colors[token] then item[property]=colors[token] end
            end
        end
    end
    local function clipboard()
        if type(options.clipboard)=="function" then return options.clipboard end
        local env
        if type(getgenv)=="function" then local ok,value=pcall(getgenv);if ok and type(value)=="table" then env=value end end
        for _,scope in ipairs({env or {},_G or {}}) do
            for _,name in ipairs({"setclipboard","toclipboard"}) do if type(scope[name])=="function" then return scope[name] end end
        end
        if type(setclipboard)=="function" then return setclipboard end
        if type(toclipboard)=="function" then return toclipboard end
    end
    function api.Copy()
        if not alive then return false end
        local writer=clipboard()
        local ok,result=false,nil
        if writer then ok,result=pcall(writer,Brand.DiscordInvite) end
        local copied=ok and result~=false
        feedback.Text=copied and "Invite copied. Open Discord to join." or "Clipboard unavailable. Select and copy the invite above."
        if not copied then
            pcall(function() invite:CaptureFocus();invite.SelectionStart=1;invite.CursorPosition=#Brand.DiscordInvite+1 end)
        end
        -- Reserve the longer fallback text from the beginning so feedback never
        -- changes the surrounding page's scroll extent after a click.
        return copied
    end
    local function destroy(remove)
        if not alive then return end
        alive=false
        for _,connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
        if remove then card:Destroy() end
    end
    function api.Destroy() destroy(true) end
    connect(copy.Activated,api.Copy)
    connect(card.Destroying,function() destroy(false) end)
    api.Resize(options.width or 526)
    return api
end
return Brand

end)()

local VenomEvolutionInspector = (function()
-- Read-only +1 Venom Evolution discovery. No native module execution or gameplay actions.
local Inspector = {}
local EXPECTED_PLACE, EXPECTED_UNIVERSE = 116448925875915, 10769464063
local VERIFIED_PLACES={[116448925875915]=true}
local FILE, STOP_KEY = "school_hub_venom_evolution_inspect.json", "StopSchoolHubVenomEvolutionInspect"
local BOUNDS = {processed=7000, queued=7800, children=192, childNames=2048, depth=14, records=1200, players=512,
    remotes=320, scripts=256, categoryCandidates=8, generalCandidates=128, chunk=32,
    sourceCount=64, sourceBytes=266240, totalSourceBytes=3145728,
    sourceTimeout=4, scanSeconds=65, reportBytes=6291456}

local CATEGORY_ORDER={"training","combat","evolution","purchase","inventory","reward","stats","movement","core","bootstrap","ui"}
local CATEGORIES={
 training={"train","sound","save","strength","power","energy","level","experience","xp","boost","click","gain"},
 combat={"combat","attack","fight","enemy","enemies","npc","boss","stage","damage","health","hit","battle","target","wave","arena"},
 evolution={"evolution","evolve","venom","form","transform","symbiote","rebirth","prestige","rank"},
 purchase={"upgrade","purchase","buy","shop","store","price","cost","unlock","product","pass","multiplier","boost","sell","capacity","tier"},
 inventory={"inventory","owned","equipped","equip","selected","loadout","backpack","pet","egg","hatch"},
 reward={"reward","claim","quest","mission","daily","playtime","achievement","gift","code","halloween","pumpkin","candy"},
 stats={"leaderstats","playerdata","profile","stats","cash","money","coins","currency","wins","win","level","experience","xp","strength","power","save"},
 movement={"movement","teleport","spawn","respawn","protection","safezone","zone","world","area","map","portal","stage","door"},
 core={"network","knit","registry","gameconfig","config","data","place","cooldown","replica"},
 bootstrap={"bootstrap","loader","client","init","main"},
 ui={"ui","gui","menu","button","screen","hud"},
}
-- Requested features are a brief, not a claim of implemented game support.
local REQUESTED_FEATURES={"Auto Training","Auto Stages","Auto Evolution","Shared Hub Anti-AFK"}
local ATTRS,PERSONAL={},{}
for _,name in ipairs({"money","cash","coins","currency","balance","wins","win","level","experience","xp",
 "strength","maxstrength","power","energy","maxenergy","soundsaves","saves","sound","venom","evolution","evolutionid","evolutions",
 "formequipped","form","currentform","selectedevolution","currentevolution","transformation","rebirth","rebirths","prestige","rank",
 "selected","equipped","owned","unlocked","inventory","pets","eggs","kills","deaths","streak","candy","pumpkins",
 "health","maxhealth","damage","range","attacking","blocking","stunned","ragdolled","invincible","immune","spawnprotected","safezone",
 "stage","stageid","currentstage","world","worldid","area","areaid","zone","zoneid","boss","target","enemy","enemyid",
 "price","cost","currencytype","requiredwins","requiredstrength","requiredlevel","requirement","requires","multiplier","gain","boost",
 "purchased","gamepass","productid","ability","skill","cooldown","enabled","active","available","claimed","claimable","rewardid","nextclaim","rewardtime","nextreward"}) do ATTRS[name]=true end
for _,name in ipairs({"money","cash","coins","currency","balance","wins","win","level","experience","xp","strength","maxstrength","power","energy","maxenergy",
 "soundsaves","saves","sound","venom","evolution","evolutionid","evolutions","formequipped","form","currentform","selectedevolution","currentevolution","transformation",
 "rebirth","rebirths","prestige","rank","selected","equipped","owned","unlocked","inventory","pets","eggs","kills","deaths","streak","candy","pumpkins","health","maxhealth",
 "stage","stageid","currentstage","world","worldid","area","areaid","zone","zoneid"}) do PERSONAL[name]=true end
local CORE_PATHS={
 "Shared.Network","Shared.Config","Shared.Data","Shared.Place","Shared.Shop","Shared.Training","Shared.Combat","Shared.Evolutions","Shared.Rewards",
 "Controllers.TrainingController","Controllers.CombatController","Controllers.EvolutionController","Controllers.ShopController","Controllers.DataController","Controllers.RewardController",
 "Modules.Training","Modules.SoundSaves","Modules.Combat","Modules.Enemies","Modules.Evolutions","Modules.Shop","Modules.Upgrades","Modules.Rewards","Modules.Zones",
 "Files.Client.Controllers","Files.Shared.Core","Files.Shared.Managers","Files.Client._Client_Initializers",
 "Packages.Knit","Config.GameConfig","GameConfig","Network","Data","Config","Controllers",
}
local CORE_FULL={}
for _,path in ipairs(CORE_PATHS) do CORE_FULL[("ReplicatedStorage."..path):lower()]=true end

local function finite(value) return type(value)=="number" and value==value and math.abs(value)<math.huge end
local function safeRead(object,key)
    local ok,value=pcall(function() return object[key] end)
    if ok then return value end
    return nil
end
local function isA(object,class)
    local ok,value=pcall(function() return object:IsA(class) end)
    return ok and value==true
end
local function find(root,path)
    for piece in path:gmatch("[^.]+") do
        if not root then return nil end
        local ok,child=pcall(function() return root:FindFirstChild(piece) end)
        if not ok then return nil end
        root=child
    end
    return root
end
local function categories(value)
    value=type(value)=="string" and value:lower() or ""
    local result={}
    for category,words in pairs(CATEGORIES) do
        for _,word in ipairs(words) do
            if value:find(word,1,true) then result[#result+1]=category;break end
        end
    end
    table.sort(result)
    return result
end
-- A byte limit must not split a UTF-8 sequence before JSON encoding.
local function prefix(value,limit)
    if #value<=limit then return value end
    local last=limit
    while last>0 do
        local byte=value:byte(last+1)
        if not byte or byte<128 or byte>=192 then break end
        last=last-1
    end
    return value:sub(1,last)
end

function Inspector.Create(options)
    options=options or {}
    local env=options.env or _G
    local tasks=options.task or task
    local clock=options.clock or os.clock
    local player,http=options.player,options.HttpService
    local alive,busy,generation=true,false,0
    local report,reportText,worker,pending,stop,savedGeneration
    local previous=env[STOP_KEY]
    if type(previous)=="function" then pcall(previous) end
    local identities,identitySeen={},{}
    local function addIdentity(value,marker)
        if value==nil then return end
        value=tostring(value)
        if #value<3 or identitySeen[value] then return end
        identitySeen[value]=true;identities[#identities+1]={value=value,marker=marker}
    end
    local function resetIdentities()
        identities,identitySeen={},{}
        for _,key in ipairs({"Name","DisplayName","UserId"}) do addIdentity(safeRead(player,key),"$LocalPlayer") end
    end
    resetIdentities()
    local function redact(value,limit)
        value=tostring(value or "")
        for _,identity in ipairs(identities) do
            value=value:gsub(identity.value:gsub("([^%w])","%%%1"),identity.marker)
        end
        return prefix(value,limit or 320)
    end
    local function path(object)
        local ok,value=pcall(function() return object:GetFullName() end)
        return redact(ok and value or safeRead(object,"Name"),512)
    end
    local function plain(value)
        if type(value)=="boolean" then return value end
        if finite(value) then return value end
        if type(value)=="string" then return redact(value,256) end
        return nil
    end
    local function attrs(object,localScope)
        local result,omitted,count,inspected={},{},0,0
        local ok,values=pcall(function() return object:GetAttributes() end)
        if ok and type(values)=="table" then
            for name,value in pairs(values) do
                inspected=inspected+1
                if count>=24 or inspected>64 then break end
                if type(name)=="string" and ATTRS[name:lower():gsub("[%s_]","")] then
                    local converted=plain(value)
                    if converted~=nil then
                        if PERSONAL[name:lower():gsub("[%s_]","")] and not localScope then
                            omitted[redact(name,64)]=type(value)
                        else result[redact(name,64)]=converted end
                        count=count+1
                    end
                end
            end
        end
        return result,omitted
    end
    local function vector(value)
        if not value then return nil end
        local x,y,z=safeRead(value,"X"),safeRead(value,"Y"),safeRead(value,"Z")
        if finite(x) and finite(y) and finite(z) then return {x,y,z} end
    end
    local function describe(object,localScope)
        local attributes,omitted=attrs(object,localScope)
        local entry={path=path(object),name=redact(safeRead(object,"Name"),96),
            class=redact(safeRead(object,"ClassName"),48),attributes=attributes}
        if next(omitted) then entry.omittedPersonalAttributeTypes=omitted end
        entry.categories=categories(entry.path)
        if isA(object,"BasePart") then
            entry.position=vector(safeRead(object,"Position"));entry.size=vector(safeRead(object,"Size"))
            for _,key in ipairs({"Transparency","LocalTransparencyModifier","CanTouch","CanCollide","CanQuery","Anchored"}) do
                entry[key]=plain(safeRead(object,key))
            end
            if isA(object,"Seat") or isA(object,"VehicleSeat") then
                entry.seat={maxSpeed=plain(safeRead(object,"MaxSpeed")),torque=plain(safeRead(object,"Torque")),
                    turnSpeed=plain(safeRead(object,"TurnSpeed")),throttle=plain(safeRead(object,"ThrottleFloat")),
                    steer=plain(safeRead(object,"SteerFloat")),occupied=safeRead(object,"Occupant")~=nil}
                local parent=safeRead(object,"Parent")
                if parent and isA(parent,"Model") then entry.seat.model=path(parent) end
            end
        elseif isA(object,"Model") then
            local primary=safeRead(object,"PrimaryPart")
            if primary and isA(primary,"BasePart") then entry.primaryPart=path(primary) end
            -- Spatial model metadata is retained only for relevant game models.
            if #entry.categories>0 then
                local ok,pivot=pcall(function() return object:GetPivot() end)
                if ok and pivot then entry.pivot=vector(safeRead(pivot,"Position")) end
            end
        elseif isA(object,"Humanoid") then
            entry.health=plain(safeRead(object,"Health"))
            entry.maxHealth=plain(safeRead(object,"MaxHealth"))
            entry.walkSpeed=plain(safeRead(object,"WalkSpeed"))
        elseif isA(object,"ProximityPrompt") then
            entry.action=redact(safeRead(object,"ActionText"),96)
            entry.object=redact(safeRead(object,"ObjectText"),96)
            entry.distance=plain(safeRead(object,"MaxActivationDistance"))
            entry.hold=plain(safeRead(object,"HoldDuration"))
            entry.enabled=plain(safeRead(object,"Enabled"))
            local parent=safeRead(object,"Parent")
            if parent then entry.parent=path(parent) end
        elseif isA(object,"TouchTransmitter") or isA(object,"ClickDetector") then
            local parent=safeRead(object,"Parent")
            if parent then entry.parent=path(parent) end
            if isA(object,"ClickDetector") then entry.distance=plain(safeRead(object,"MaxActivationDistance")) end
        elseif isA(object,"ValueBase") then
            local value=safeRead(object,"Value")
            local key=tostring(safeRead(object,"Name") or ""):lower():gsub("[%s_]","")
            if ATTRS[key] and (finite(value) or type(value)=="boolean" or localScope and type(value)=="string") then
                if PERSONAL[key] and not localScope then entry.omittedPersonalValueType=type(value)
                else entry.value=plain(value) end
            end
            if isA(object,"ObjectValue") and #categories(key)>0 and value~=nil then
                local class=safeRead(value,"ClassName")
                if type(class)=="string" then entry.reference={path=path(value),class=redact(class,48)} end
            end
        end
        if isA(object,"ScreenGui") then entry.enabled=plain(safeRead(object,"Enabled")) end
        if isA(object,"TextLabel") or isA(object,"TextButton") or isA(object,"ImageButton") then
            entry.visible=plain(safeRead(object,"Visible"))
            entry.active=plain(safeRead(object,"Active"))
            -- TextBox/chat/private roots are excluded before this read. Only
            -- observed mechanic UI labels/buttons are retained, with identities redacted.
            if #entry.categories>0 and not isA(object,"ImageButton") then
                entry.text=redact(safeRead(object,"Text"),192)
            end
        end
        return entry
    end
    local function current(token) return alive and generation==token and env[STOP_KEY]==stop end
    local function status(message,kind)
        if alive and type(options.onStatus)=="function" then pcall(options.onStatus,message,kind) end
    end
    local function encode(token)
        if not current(token) or not report or not http then return nil end
        local ok,value=pcall(http.JSONEncode,http,report)
        if not ok or type(value)~="string" or #value>BOUNDS.reportBytes or not current(token) then return nil end
        reportText=value;return value
    end
    local function save(token)
        local value=encode(token)
        if not value or type(options.writer)~="function" or not current(token) then return false end
        local ok,result=pcall(options.writer,FILE,value)
        local saved=ok and result~=false and current(token)
        if saved then savedGeneration=token end
        return saved
    end
    local function collect(token,withSources)
        local started=clock()
        local deadline=started+BOUNDS.scanSeconds
        resetIdentities()
        local result={version=1,revision=2,diagnosticOnly=true,completed=false,game="+1 Venom Evolution",
            placeId=options.placeId,universeId=options.universeId,expectedPlaceId=EXPECTED_PLACE,
            expectedUniverseId=EXPECTED_UNIVERSE,verifiedPlaceIds={116448925875915},
            objects={},remotes={},scripts={},roots={},stats={},limits={},
            skipped={privateRoots=0,duplicateNodes=0,depth=0,children=0,childNames=0,queue=0,objects=0,remotes=0,scripts=0,sourceCandidates=0},
            unavailable={children=0,source=0},truncation={},sourceOptIn=withSources==true,requestedFeatures=REQUESTED_FEATURES,requestedFeaturesPending=false,
            capabilities={decompile=type(options.decompile)=="function",writefile=type(options.writer)=="function",
                clipboard=type(options.clipboard)=="function",
                getloadedmodules=type(options.getloadedmodules or env.getloadedmodules or getloadedmodules)=="function",
                fireproximityprompt=type(options.fireproximityprompt or env.fireproximityprompt or fireproximityprompt)=="function",
                firetouchinterest=type(options.firetouchinterest or env.firetouchinterest or firetouchinterest)=="function",
                fireclickdetector=type(options.fireclickdetector or env.fireclickdetector or fireclickdetector)=="function"}}
        for key,value in pairs(BOUNDS) do result.limits[key]=value end
        report,reportText=result,nil
        if not VERIFIED_PLACES[options.placeId] or options.universeId~=EXPECTED_UNIVERSE then
            result.wrongPlace=not VERIFIED_PLACES[options.placeId]
            result.wrongUniverse=options.universeId~=EXPECTED_UNIVERSE
            result.completed=true;save(token)
            status("Open a verified +1 Venom Evolution place in universe 10769464063, then collect again.","error")
            return
        end
        local excluded={}
        local schemaSeen={}
        result.playerFieldSchema={policy="field-names-and-types-only",sampledPlayers=0,fields={}}
        local function addSchema(name,valueType,location)
            if type(name)~="string" or not ATTRS[name:lower():gsub("[%s_]","")] then return end
            if valueType~="number" and valueType~="boolean" and valueType~="string" then return end
            local key=location..":"..name..":"..valueType
            if schemaSeen[key] or #result.playerFieldSchema.fields>=80 then return end
            schemaSeen[key]=true
            result.playerFieldSchema.fields[#result.playerFieldSchema.fields+1]={name=redact(name,64),type=valueType,location=location}
        end
        local function sampleSchema(other)
            if result.playerFieldSchema.sampledPlayers>=16 then return end
            result.playerFieldSchema.sampledPlayers=result.playerFieldSchema.sampledPlayers+1
            local got,attributes=pcall(function() return other:GetAttributes() end)
            if got and type(attributes)=="table" then
                local count=0
                for name,value in pairs(attributes) do
                    count=count+1;if count>64 then break end
                    addSchema(name,type(value),"Player.attributes")
                end
            end
            local gotChildren,children=pcall(function() return other:GetChildren() end)
            if gotChildren and type(children)=="table" then
                for index,child in ipairs(children) do
                    if index>64 then break end
                    local name=tostring(safeRead(child,"Name") or "")
                    if name:lower()=="leaderstats" or name:lower()=="stats" then
                        local gotValues,values=pcall(function() return child:GetChildren() end)
                        if gotValues and type(values)=="table" then
                            for valueIndex,field in ipairs(values) do
                                if valueIndex>32 then break end
                                if isA(field,"ValueBase") then addSchema(safeRead(field,"Name"),type(safeRead(field,"Value")),"Player."..name) end
                            end
                        end
                    end
                end
            end
        end
        local ok,players=pcall(function() return options.Players:GetPlayers() end)
        if ok and type(players)=="table" then
            for index,other in ipairs(players) do
                if index>BOUNDS.players then result.truncation.players=true;break end
                for _,key in ipairs({"Name","DisplayName","UserId"}) do
                    addIdentity(safeRead(other,key),other==player and "$LocalPlayer" or "$OtherPlayer")
                end
                if other~=player then
                    local character=safeRead(other,"Character")
                    if character then excluded[character]=true end
                end
                sampleSchema(other)
                if index%32==0 then tasks.wait();if not current(token) then return end end
            end
        end
        table.sort(identities,function(a,b) return #a.value>#b.value end)
        local function skip(object)
            if excluded[object] then return true end
            -- Check native character ownership too, so a large server's omitted
            -- player-list tail or a character replaced mid-scan stays private.
            if object~=safeRead(player,"Character") and isA(object,"Model") then
                local ownerOK,owner=pcall(function() return options.Players:GetPlayerFromCharacter(object) end)
                if ownerOK and owner and owner~=player then return true end
            end
            local name=tostring(safeRead(object,"Name") or ""):lower()
            return name:find("schoolhub",1,true) or name:find("school_hub",1,true)
                or name:find("platoboost",1,true) or name:find("scriptrblx",1,true)
                or name:find("privateauth",1,true) or name:find("authsecret",1,true)
                or isA(object,"TextBox") or name:find("chat",1,true)
                or name=="playerlist"
        end
        local scriptSeen,candidates,general,byCategory={},{},{},{}
        result.excludedSourceCandidates=0
        local function systemSource(object)
            local full=path(object):lower()
            if full:find(".playermodule",1,true) or full:find("rbxcharactersounds",1,true)
                or full:find(".cmdr",1,true) or full:find("profilestore",1,true)
                or full:find(".icon.",1,true) or full:match("%.icon$") or full:find(".topbarplus.",1,true)
                or full:find(".react.",1,true) or full:find(".roact.",1,true) then return true end
            if full:find(".packages.",1,true) and full~="replicatedstorage.packages.knit" then return true end
            return false
        end
        for _,category in ipairs(CATEGORY_ORDER) do byCategory[category]={} end
        local function sourceScore(object,rootName)
            local name=tostring(safeRead(object,"Name") or ""):lower()
            local full=path(object):lower()
            local ownCategories,fullCategories=categories(name),categories(full)
            local score=#ownCategories*24+math.min(#fullCategories,4)*5
            local priority=CORE_FULL[full] or full:match("playerscripts%.client$") or full:match("playerscripts%.main$") or full:match("playerscripts%.init$")
            if priority then score=score+1000 end
            if name:find("controller",1,true) or name:find("manager",1,true) or name:find("config",1,true) then
                for _,category in ipairs(ownCategories) do
                    if category=="training" or category=="combat" or category=="evolution" or category=="purchase" or category=="reward" then
                        score=score+140;break
                    end
                end
            end
            if rootName=="LocalCharacter" then score=score+45 end
            if score>0 and (full:find("config",1,true) or full:find("controller",1,true)) then score=score+12 end
            if rootName=="PlayerScripts" and score>0 then score=score+10 end
            if isA(object,"LocalScript") and score>0 then score=score+4 end
            return score,fullCategories,ownCategories,priority==true or type(priority)=="string"
        end
        local function better(a,b)
            if a.score==b.score then return a.entry.path<b.entry.path end
            return a.score>b.score
        end
        local function retain(bucket,candidate,limit)
            bucket[#bucket+1]=candidate
            table.sort(bucket,better)
            if #bucket>limit then bucket[#bucket]=nil end
        end
        local function scriptCandidate(object,rootName)
            if scriptSeen[object] or not (isA(object,"ModuleScript") or isA(object,"LocalScript")) then return end
            scriptSeen[object]=true
            if systemSource(object) then result.excludedSourceCandidates=result.excludedSourceCandidates+1;return end
            local score,fullCategories,ownCategories,directPriority=sourceScore(object,rootName)
            local entry={path=path(object),class=redact(safeRead(object,"ClassName"),48),status="not-selected",
                priority=score,categories=fullCategories,root=rootName,directPriority=directPriority}
            local candidate={object=object,entry=entry,score=score}
            retain(general,candidate,BOUNDS.generalCandidates)
            -- Per-mechanic reservations keep combat, evolution and training evidence
            -- alongside inventory, rewards and UI controllers.
            local own={}
            for _,category in ipairs(ownCategories) do own[category]=true end
            for _,category in ipairs(fullCategories) do
                local bucketCandidate={object=object,entry=entry,score=score+(own[category] and 40 or 0)}
                retain(byCategory[category],bucketCandidate,BOUNDS.categoryCandidates)
            end
            result.discoveredScripts=(result.discoveredScripts or 0)+1
        end

local own=safeRead(player,"Character")
local humanoid=find(own,"Humanoid")
-- Live map, local state and client UI always receive their own quotas first.
-- Replicated assets cannot consume those quotas and hide live game evidence.
local roots={
    {object=options.workspace,name="Workspace",budget=1500,recordBudget=280},
    {object=find(player,"PlayerScripts"),name="PlayerScripts",budget=1400,recordBudget=180},
    {object=find(player,"PlayerGui"),name="PlayerGui",budget=1300,recordBudget=240},
    {object=find(player,"leaderstats"),name="LocalStats",budget=160,recordBudget=80},
    {object=own,name="LocalCharacter",budget=450,recordBudget=140},
    {object=find(player,"Backpack"),name="LocalBackpack",budget=200,recordBudget=60},
}
-- Native lookups are discovery only. Existing mechanic folders are traversed
-- before the fallback asset tree, and absent names are never reported as evidence.
for _,name in ipairs({"Remotes","RemoteEvents","RemoteFunctions","Events","Network",
    "Modules","Shared","Controllers","Client","Config","Configs","Files","Framework","Services","Training","Combat","Enemies","Evolutions","Forms","Shop","Rewards","Zones"}) do
    local object=find(options.ReplicatedStorage,name)
    if object then roots[#roots+1]={object=object,name="ReplicatedStorage."..name,budget=420,recordBudget=80} end
end
roots[#roots+1]={object=options.ReplicatedStorage,name="ReplicatedStorage",budget=1400,recordBudget=220}
result.stats.player=attrs(player,true);result.stats.character=own and attrs(own,true) or {}
result.runtime={streamingEnabled=plain(safeRead(options.workspace,"StreamingEnabled")),
    playerPosition=vector(safeRead(find(own,"HumanoidRootPart"),"Position")),
    localHealth=plain(safeRead(humanoid,"Health")),localMaxHealth=plain(safeRead(humanoid,"MaxHealth"))}
local priorityNames={"Training","SoundSaves","Sounds","Combat","Enemies","NPCs","Bosses","Stages","Evolutions","Evolution","Forms","Transformations",
 "Shop","Shops","Upgrades","Rewards","DailyRewards","Quests","Halloween","Pets","Eggs","Zones","Worlds","Areas","Files","Services","Framework","PlayerData",
 "Remotes","RemoteEvents","RemoteFunctions","Network","Events","Modules","Shared","Controllers","Client","Config","Configs","Inventory","Data","Profile","Leaderstats","leaderstats",
 "Spawns","SafeZones","Hotbar","HUD","Play","Lobby","Map","Portals"}
        local function prioritizeChildren(object,children,depth)
            local ranked,selected={},{}
            local function add(child,index,priority)
                if not child then return end
                if selected[child] then
                    if priority then selected[child].score=selected[child].score+priority end
                    return
                end
                local name=tostring(safeRead(child,"Name") or "")
                local score=#categories(name)*10+(priority or 0)
                if isA(child,"ModuleScript") or isA(child,"LocalScript") then score=score+15 end
                if isA(child,"RemoteEvent") or isA(child,"RemoteFunction") then score=score+8 end
                local item={object=child,index=index,score=score}
                selected[child]=item;ranked[#ranked+1]=item
            end
            for index=1,math.min(#children,BOUNDS.childNames) do
                add(children[index],index)
                if index%128==0 then
                    tasks.wait()
                    if not current(token) or clock()>=deadline then break end
                end
            end
            -- Native name lookup also discovers common mechanic folders beyond
            -- the bounded name-sampling window in unusually wide maps.
            for index,name in ipairs(priorityNames) do
                local childOK,child=pcall(function() return object:FindFirstChild(name) end)
                if childOK then add(child,BOUNDS.childNames+index,100) end
            end
            if #children>BOUNDS.childNames then
                result.skipped.childNames=result.skipped.childNames+(#children-BOUNDS.childNames)
                result.truncation.childNames=true
            end
            table.sort(ranked,function(a,b)
                if a.score==b.score then return a.index<b.index end
                return a.score>b.score
            end)
            local ordered={}
            for _,item in ipairs(ranked) do ordered[#ordered+1]=item.object end
            return ordered
        end
        -- Bounded direct discovery: absent paths are never reported as evidence.
        -- No Source property, require, callbacks or gameplay calls occur here.
        result.directSourceDiscovery={};result.childNames={}
        for _,relative in ipairs(CORE_PATHS) do
            if not current(token) or clock()>=deadline then return end
            local object=find(options.ReplicatedStorage,relative)
            if object and not skip(object) then
                result.directSourceDiscovery[#result.directSourceDiscovery+1]={path=path(object),class=redact(safeRead(object,"ClassName"),48)}
                scriptCandidate(object,"DirectFirstParty")
            end
        end
        for _,name in ipairs({"Client","Main","Init","Bootstrap"}) do
            local object=find(player,"PlayerScripts."..name)
            if object and not skip(object) then scriptCandidate(object,"PlayerScripts") end
        end
        local nameRoots={
            {object=find(player,"PlayerScripts"),name="PlayerScripts"},
            {object=find(player,"PlayerScripts.Client"),name="PlayerScripts.Client"},
        }
        for _,relative in ipairs({"Shared","Shared.Client","Controllers","Modules","Config","Remotes","Events","Training","Combat","Evolutions","Enemies","Zones","Rewards","Files","Files.Client","Files.Client.Controllers","Files.Client._Client_Initializers","Files.Shared","Files.Shared.Core","Files.Shared.Managers"}) do
            nameRoots[#nameRoots+1]={object=find(options.ReplicatedStorage,relative),name="ReplicatedStorage."..relative}
        end
        for _,item in ipairs(nameRoots) do
            if not current(token) or clock()>=deadline then return end
            if item.object and not skip(item.object) then
                local record={path=path(item.object),names={}};result.childNames[#result.childNames+1]=record
                local ok,children=pcall(function() return item.object:GetChildren() end)
                if ok and type(children)=="table" then
                    for index,child in ipairs(children) do
                        if index>192 then record.truncated=true;break end
                        if not skip(child) then
                            record.names[#record.names+1]={name=redact(safeRead(child,"Name"),96),class=redact(safeRead(child,"ClassName"),48)}
                            scriptCandidate(child,"FirstPartyNames")
                        end
                    end
                end
            end
        end

        local seen,processed,queued={},0,0
        for _,root in ipairs(roots) do
            if not current(token) or clock()>=deadline then break end
            local rootReport={name=root.name,budget=root.budget,recordBudget=root.recordBudget,
                records=0,processed=0,queued=0,unavailable=root.object==nil}
            result.roots[#result.roots+1]=rootReport
            local queue,head={},1
            local function enqueue(object,depth)
                if not object then return end
                -- Inspect the local character in its dedicated, private scope.
                -- Workspace-first traversal must not consume it as public map data.
                if root.name=="Workspace" and object==own then return end
                if seen[object] then result.skipped.duplicateNodes=result.skipped.duplicateNodes+1;return end
                if skip(object) then result.skipped.privateRoots=result.skipped.privateRoots+1;return end
                if depth>BOUNDS.depth then result.skipped.depth=result.skipped.depth+1;result.truncation.depth=true;return end
                if queued>=BOUNDS.queued or #queue>=root.budget then
                    result.skipped.queue=result.skipped.queue+1;rootReport.truncated=true;result.truncation.queue=true;return
                end
                seen[object]=true;queued=queued+1
                queue[#queue+1]={object=object,depth=depth};rootReport.queued=rootReport.queued+1
            end
            enqueue(root.object,0)
            while head<=#queue and processed<BOUNDS.processed and current(token) and clock()<deadline do
                local job=queue[head];head=head+1
                local object=job.object
                processed=processed+1;rootReport.processed=rootReport.processed+1
                local name=tostring(safeRead(object,"Name") or "")
                local prompt=isA(object,"ProximityPrompt") or isA(object,"TouchTransmitter") or isA(object,"ClickDetector")
                local interesting=#categories(name)>0 or root.name=="LocalStats" or prompt
                    or root.name=="PlayerGui" and (#categories(path(object))>0)
                    or isA(object,"VehicleSeat") or isA(object,"Seat") or isA(object,"Humanoid")
                    or isA(object,"Model") and #categories(path(object))>0
                if job.depth<=1 or interesting then
                    if #result.objects<BOUNDS.records and rootReport.records<root.recordBudget then
                        local localScope=root.name=="CurrentVehicle" or root.name=="LocalStats" or root.name=="LocalCharacter" or root.name=="LocalBackpack"
                        local entry=describe(object,localScope);entry.root=root.name
                        result.objects[#result.objects+1]=entry;rootReport.records=rootReport.records+1
                    else result.skipped.objects=result.skipped.objects+1;result.truncation.objects=true end
                end
                if isA(object,"RemoteEvent") or isA(object,"RemoteFunction") then
                    if #result.remotes<BOUNDS.remotes then
                        result.remotes[#result.remotes+1]={path=path(object),class=redact(safeRead(object,"ClassName"),48),
                            categories=categories(path(object))}
                    else result.skipped.remotes=result.skipped.remotes+1;result.truncation.remotes=true end
                end
                scriptCandidate(object,root.name)
                local childOK,children=pcall(function() return object:GetChildren() end)
                if childOK and type(children)=="table" then
                    if job.depth>=BOUNDS.depth then
                        if #children>0 then result.skipped.depth=result.skipped.depth+#children;result.truncation.depth=true end
                    else
                        local originalCount=#children
                        children=prioritizeChildren(object,children,job.depth)
                        if not current(token) then return end
                        for index,child in ipairs(children) do
                            if index>BOUNDS.children then
                                result.skipped.children=result.skipped.children+(originalCount-BOUNDS.children)
                                result.truncation.children=true;rootReport.truncated=true;break
                            end
                            enqueue(child,job.depth+1)
                        end
                    end
                else result.unavailable.children=result.unavailable.children+1 end
                if processed%BOUNDS.chunk==0 then status("Scanning game objects: "..processed);tasks.wait() end
            end
            if head<=#queue then rootReport.truncated=true;result.truncation.nodes=true end
        end
        if not current(token) then return end
        if clock()>=deadline then result.truncation.time=true end
        result.processedNodes,result.queuedNodes=processed,queued
        -- Only observed scripts are candidates. No guessed path is ever treated
        -- as evidence that a mechanic, remote or module exists in this game.
        local retained={}
        local function retainUnique(candidate)
            if retained[candidate.object] or #candidates>=BOUNDS.scripts then return end
            retained[candidate.object]=true;candidates[#candidates+1]=candidate
        end
        for _,category in ipairs(CATEGORY_ORDER) do
            for _,candidate in ipairs(byCategory[category]) do retainUnique(candidate) end
        end
        for _,candidate in ipairs(general) do retainUnique(candidate) end
        table.sort(candidates,better)
        for _,candidate in ipairs(candidates) do result.scripts[#result.scripts+1]=candidate.entry end
        result.skipped.scripts=math.max(0,(result.discoveredScripts or 0)-#candidates)
        if result.skipped.scripts>0 then result.truncation.scripts=true end
        local jobs,selected={},{}
        result.sourceSelection={policy="round-robin-per-mechanic",categories={}}
        local function select(candidate,category)
            if not candidate or candidate.score<=0 or selected[candidate.object] or #jobs>=BOUNDS.sourceCount then return end
            selected[candidate.object]=true
            candidate.entry.selectedFor=category
            jobs[#jobs+1]=candidate
            result.sourceSelection.categories[category]=(result.sourceSelection.categories[category] or 0)+1
        end
        local directSelected=0
        for _,candidate in ipairs(candidates) do
            if candidate.entry.directPriority and directSelected<20 then
                select(candidate,"native-core");directSelected=directSelected+1
            end
        end
        for rank=1,BOUNDS.categoryCandidates do
            for _,category in ipairs(CATEGORY_ORDER) do select(byCategory[category][rank],category) end
        end
        for _,candidate in ipairs(candidates) do select(candidate,"general") end
        for _,candidate in ipairs(candidates) do
            if candidate.score<=0 then result.skipped.sourceCandidates=result.skipped.sourceCandidates+1 end
        end
        if #candidates>#jobs then result.truncation.sourceCount=true end
        local bytes,sources,attempts=0,0,0
        if withSources then
            for index,job in ipairs(jobs) do
                if index>BOUNDS.sourceCount then result.truncation.sourceCount=true;break end
                if clock()>=deadline then result.truncation.time=true;break end
                if not current(token) then return end
                attempts=attempts+1
                local finished,accepting,readOK,value,method=false,true,false,nil,"Source"
                status("Reading selected client source "..index.."/"..math.min(#jobs,BOUNDS.sourceCount))
                local nativeJob=tasks.spawn(function()
                    local read,source=pcall(function() return job.object.Source end)
                    local used="Source"
                    if (not read or type(source)~="string" or source=="") and type(options.decompile)=="function" then
                        read,source=pcall(options.decompile,job.object);used="decompile"
                    end
                    if accepting and current(token) then readOK,value,method,finished=read,source,used,true end
                end)
                pending=nativeJob
                local untilTime=math.min(deadline,clock()+BOUNDS.sourceTimeout)
                while current(token) and not finished and clock()<untilTime do tasks.wait(.05) end
                accepting=false
                if not finished and type(tasks.cancel)=="function" then pcall(tasks.cancel,nativeJob) end
                if pending==nativeJob then pending=nil end
                if not current(token) then return end
                job.entry.method=method
                if not finished then
                    job.entry.status="timeout";result.stoppedAfterTimeout=true;result.truncation.sourceTimeout=true
                    result.unavailable.source=result.unavailable.source+1;break
                elseif readOK and type(value)=="string" and #value>0 then
                    job.entry.originalSourceBytes=#value
                    if #value>BOUNDS.sourceBytes or bytes+#value>BOUNDS.totalSourceBytes then
                        job.entry.status="over-budget";result.truncation.sourceBytes=true
                    else
                        local retained=redact(value,BOUNDS.sourceBytes)
                        if bytes+#retained>BOUNDS.totalSourceBytes then
                            job.entry.status="over-budget";result.truncation.sourceBytes=true
                        else
                            job.entry.source=retained;job.entry.sourceBytes=#retained;job.entry.status="ok"
                            sources=sources+1;bytes=bytes+#retained
                        end
                    end
                else job.entry.status="unavailable";result.unavailable.source=result.unavailable.source+1 end
                tasks.wait()
            end
        end
        if not current(token) then return end
        if clock()>=deadline then result.truncation.time=true end
        result.truncated=next(result.truncation)~=nil
        result.completed,result.successfulSources,result.sourceBytes,result.attemptedSources=true,sources,bytes,attempts
        result.durationSeconds=math.max(0,clock()-started)
        local saved=save(token)
        if not current(token) then return end
        status("Done: "..#result.objects.." objects, "..#result.remotes.." remotes, "..sources
            .." sources. "..(saved and FILE.." saved." or "Use Copy report."),"success")
        if type(options.onComplete)=="function" then pcall(options.onComplete,result,saved) end
    end
    local controller={}
    function controller.Start(withSources)
        if not alive or env[STOP_KEY]~=stop then return false end
        if busy then status("A scan is already running.");return false end
        busy,generation=true,generation+1
        local token=generation
        status("Collecting read-only +1 Venom Evolution report…")
        worker=tasks.spawn(function()
            local ok=pcall(collect,token,withSources==true)
            if not current(token) then return end
            busy=false
            if not ok then
                if report then report.interrupted=true;report.completed=false;save(token) end
                status("Scan interrupted. Copy the partial report or collect again.","error")
            end
        end)
        return true
    end
    function controller.CopyReport()
        if not alive or env[STOP_KEY]~=stop or not report then status("Collect a report first.");return false end
        local token=generation
        local value=encode(token)
        if not value or not current(token) then status("Could not encode report.","error");return false end
        if type(options.clipboard)=="function" then
            local ok,result=pcall(options.clipboard,value)
            if ok and result~=false and current(token) then status(busy and "Partial report copied." or "Report copied.");return true end
        end
        if savedGeneration==token or save(token) then
            status("Clipboard unavailable. Read "..FILE.." in the executor workspace.","error")
        else status("No report file was saved and clipboard is unavailable. Report remains in memory.","error") end
        return false
    end
    function controller.GetReport() return report end
    function controller.GetText() return reportText end
    function controller.IsBusy() return busy end
    stop=function()
        if not alive then return end
        alive,busy,generation=false,false,generation+1
        if pending and type(tasks.cancel)=="function" then pcall(tasks.cancel,pending) end
        if worker and type(tasks.cancel)=="function" then pcall(tasks.cancel,worker) end
        pending,worker=nil,nil
        if env[STOP_KEY]==stop then env[STOP_KEY]=nil end
        if type(options.onStop)=="function" then pcall(options.onStop) end
    end
    env[STOP_KEY]=stop;controller.Stop=stop
    return controller
end
return Inspector

end)()

local VenomEvolutionInspectUI = (function()
-- School Hub diagnostic presentation only; no game actions or network calls.
local UI={}
function UI.Create(options)
    options=options or {}
    local Theme=assert(options.Theme,"School Hub theme is required")
    local Brand=options.Brand
    local factory=options.Instance or Instance
    local world=options.workspace or workspace
    local input=options.UserInputService
    local palette=Theme.Resolve({theme="Citron"})
    local design=Theme.Design
    local alive,busy=true,false
    local connections,cameraConnection={},nil
    local dragging,dragStart,dragPosition
    local statusMessage,statusKind="Ready. Spawn in the game, then collect a report.",nil
    local function create(class,parent,properties)
        local item=factory.new(class)
        for key,value in pairs(properties or {}) do item[key]=value end
        item.Parent=parent
        return item
    end
    local function connect(event,callback)
        if not event then return end
        local connection=event:Connect(callback)
        connections[#connections+1]=connection
        return connection
    end
    local function round(item,radius) create("UICorner",item,{CornerRadius=UDim.new(0,radius)}) end
    local function stroke(item,color,transparency)
        return create("UIStroke",item,{Color=color,Transparency=transparency or 0,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
    end
    local function label(parent,name,value,size,color,bold)
        return create("TextLabel",parent,{Name=name,Text=value,TextSize=size,
            Font=Theme.Font(bold and "medium" or nil),TextColor3=color,BackgroundTransparency=1,
            BorderSizePixel=0,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
            TextYAlignment=Enum.TextYAlignment.Top})
    end
    local gui=create("ScreenGui",options.parent,{Name="SchoolHubVenomEvolutionInspect",ResetOnSpawn=false,
        IgnoreGuiInset=true,DisplayOrder=1400,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
    local panel=create("Frame",gui,{Name="VenomEvolutionInspectPanel",BackgroundColor3=palette.panel,BorderSizePixel=0,
        Size=UDim2.fromOffset(560,440),Position=UDim2.fromOffset(24,80)})
    round(panel,design.windowRadius or 14);stroke(panel,palette.border)
    local header=create("Frame",panel,{Name="DragArea",BackgroundTransparency=1,Active=true,
        Size=UDim2.new(1,-84,0,72)})
    if Brand and type(Brand.CreateMark)=="function" then Brand.CreateMark(header,20,18,36,palette.accent) end
    local title=label(header,"Title","School Hub",22,palette.text,true)
    title.Font=Theme.Font("bold")
    title.Position=UDim2.fromOffset(68,14);title.TextWrapped=false
    local subtitle=label(header,"Subtitle",options.subtitle or "+1 VENOM EVOLUTION · GAME REPORT",10,palette.muted)
    subtitle.Position=UDim2.fromOffset(68,43);subtitle.TextWrapped=false
    subtitle.TextTruncate=Enum.TextTruncate.AtEnd
    create("Frame",panel,{Name="HeaderRule",Position=UDim2.fromOffset(1,71),Size=UDim2.new(1,-2,0,1),
        BackgroundColor3=palette.border,BorderSizePixel=0})
    local close=create("TextButton",panel,{Name="Close",Text="",AutoButtonColor=true,
        Size=UDim2.fromOffset(44,44),BackgroundColor3=palette.surface,BorderSizePixel=0})
    round(close,8)
    for _,rotation in ipairs({45,-45}) do
        create("Frame",close,{Name="CloseGlyph",AnchorPoint=Vector2.new(.5,.5),
            Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(14,2),Rotation=rotation,
            BackgroundColor3=palette.text,BorderSizePixel=0})
    end
    local body=create("ScrollingFrame",panel,{Name="ReportBody",BackgroundTransparency=1,
        BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=palette.quiet,
        CanvasSize=UDim2.fromOffset(0,0),CanvasPosition=Vector2.new(0,0),
        ScrollingDirection=Enum.ScrollingDirection.Y,Active=true,ClipsDescendants=true})
    local intro=label(body,"Introduction",options.introduction or "Collects training, enemy areas, evolution menus, shops, rewards and local player UI metadata, plus selected client sources when available.",13,palette.muted)
    local card=create("Frame",body,{Name="ScanStatus",BackgroundColor3=palette.surface,BorderSizePixel=0})
    round(card,design.cardRadius or 10)
    local statusOutline=stroke(card,palette.accentText,design.accentOutlineTransparency or .32)
    local cardTitle=label(card,"StatusTitle","Game discovery",15,palette.text,true)
    local status=label(card,"Status",statusMessage,13,palette.accentText)
    local instruction=label(body,"Instructions",options.instructions or "Train once, start a stage and open the evolution menu. Visit shop and reward menus if available, then collect a report. The scanner does not activate anything.",13,palette.muted)
    local filename=label(body,"ReportFilename",options.fileName or "school_hub_venom_evolution_inspect.json",11,palette.text,true)
    local note=label(body,"ReportNote","Saved in the executor workspace. Collect report reads available client sources. Nothing is uploaded and no gameplay actions are performed.",12,palette.muted)
    local buttons={}
    local function button(name,value,primary)
        local item=create("TextButton",panel,{Name=name,Text=value,TextSize=13,Font=Theme.Font("medium"),
            TextWrapped=true,BackgroundColor3=primary and palette.accent or palette.surface,
            TextColor3=primary and palette.darkAccent or palette.text,BorderSizePixel=0,AutoButtonColor=true})
        round(item,8)
        if not primary then stroke(item,palette.border) end
        buttons[#buttons+1]=item
        return item
    end
    local collect=button("CollectReport","Collect report",true)
    local copy=button("CopyReport","Copy report",false)
    local positioned=false
    local api={gui=gui}
    local function measure(item,width)
        return Theme.MeasureText(item.Text,item.TextSize,width,item.Font,options.TextService)
    end
    local function fit()
        if not alive then return end
        local camera=world and world.CurrentCamera
        local viewport=camera and camera.ViewportSize or Vector2.new(1280,800)
        local width=math.min(560,math.max(200,viewport.X-24))
        local height
        close.Position=UDim2.fromOffset(width-64,14)
        title.TextSize=width<320 and 20 or 22
        title.Size=UDim2.fromOffset(math.max(70,width-144),28)
        subtitle.Size=UDim2.fromOffset(math.max(70,width-144),16)
        local bodyWidth=width-40
        local contentWidth=bodyWidth-10
        body.Position=UDim2.fromOffset(20,92)
        local y=1
        local function place(item,padding)
            local h=measure(item,contentWidth)
            item.Position=UDim2.fromOffset(1,y);item.Size=UDim2.fromOffset(contentWidth,h)
            y=y+h+(padding or 12)
        end
        place(intro,12)
        local inner=contentWidth-24
        local headingHeight=math.max(20,measure(cardTitle,inner))
        local statusHeight=math.max(18,measure(status,inner))
        local cardHeight=12+headingHeight+4+statusHeight+12
        card.Position=UDim2.fromOffset(1,y);card.Size=UDim2.fromOffset(contentWidth,cardHeight)
        cardTitle.Position=UDim2.fromOffset(12,12);cardTitle.Size=UDim2.fromOffset(inner,headingHeight)
        status.Position=UDim2.fromOffset(12,12+headingHeight+4);status.Size=UDim2.fromOffset(inner,statusHeight)
        y=y+cardHeight+12
        place(instruction,16);place(filename,4);place(note,1)
        height=math.min(640,math.max(320,y+170),math.max(180,viewport.Y-24))
        panel.Size=UDim2.fromOffset(width,height)
        body.Size=UDim2.fromOffset(bodyWidth,math.max(1,height-168))
        body.CanvasSize=UDim2.fromOffset(0,y+2)
        body.CanvasPosition=Vector2.new(0,math.max(0,math.min(body.CanvasPosition.Y,y+2-body.Size.Y.Offset)))
        local buttonWidth=(width-52)/2
        for index,item in ipairs(buttons) do
            item.Position=UDim2.fromOffset(20+(index-1)*(buttonWidth+12),height-64)
            item.Size=UDim2.fromOffset(buttonWidth,44)
        end
        local x=positioned and panel.Position.X.Offset or (viewport.X-width)/2
        local py=positioned and panel.Position.Y.Offset or math.min(80,(viewport.Y-height)/2)
        panel.Position=UDim2.fromOffset(math.max(12,math.min(x,math.max(12,viewport.X-width-12))),
            math.max(12,math.min(py,math.max(12,viewport.Y-height-12))))
        positioned=true
    end
    function api.SetStatus(message,kind)
        if not alive then return end
        statusMessage=tostring(message or ""):sub(1,4096);statusKind=kind
        status.Text=statusMessage
        status.TextColor3=kind=="error" and Color3.fromRGB(255,160,140) or palette.accentText
        statusOutline.Color=status.TextColor3
        fit()
    end
    function api.SetBusy(value)
        if not alive then return end
        busy=value==true
        collect.Active=not busy;collect.AutoButtonColor=not busy
        collect.Text=busy and "Collecting..." or "Collect report"
    end
    function api.Destroy()
        if not alive then return end
        alive=false
        for _,connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
        if cameraConnection then pcall(function() cameraConnection:Disconnect() end);cameraConnection=nil end
        gui:Destroy()
    end
    connect(collect.Activated,function() if alive and not busy and type(options.onCollect)=="function" then options.onCollect() end end)
    connect(copy.Activated,function() if alive and type(options.onCopy)=="function" then options.onCopy() end end)
    connect(close.Activated,function()
        if not alive then return end
        if type(options.onClose)=="function" then pcall(options.onClose) end
        api.Destroy()
    end)
    local function watchCamera()
        if cameraConnection then cameraConnection:Disconnect();cameraConnection=nil end
        local camera=world and world.CurrentCamera
        if camera then cameraConnection=camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
        fit()
    end
    if world then connect(world:GetPropertyChangedSignal("CurrentCamera"),watchCamera) end
    connect(header.InputBegan,function(event)
        if dragging then return end
        if event.UserInputType==Enum.UserInputType.MouseButton1 or event.UserInputType==Enum.UserInputType.Touch then
            dragging,dragStart,dragPosition=event,Vector2.new(event.Position.X,event.Position.Y),panel.Position
        end
    end)
    if input then
        connect(input.InputChanged,function(event)
            if not alive or not dragging then return end
            if event==dragging or dragging.UserInputType==Enum.UserInputType.MouseButton1 and event.UserInputType==Enum.UserInputType.MouseMovement then
                local delta=Vector2.new(event.Position.X,event.Position.Y)-dragStart
                panel.Position=UDim2.fromOffset(dragPosition.X.Offset+delta.X,dragPosition.Y.Offset+delta.Y);fit()
            end
        end)
        connect(input.InputEnded,function(event)
            if event==dragging or dragging and dragging.UserInputType==Enum.UserInputType.MouseButton1 and event.UserInputType==Enum.UserInputType.MouseButton1 then
                dragging,dragStart,dragPosition=nil,nil,nil
            end
        end)
    end
    watchCamera()
    return api
end
return UI

end)()

-- Local setup report only. Working public hubs are not stopped or changed.
-- Explicit places verified through Roblox's universe places API. This allowlist
-- belongs only to the read-only diagnostic; it is not published game support.
local VERIFIED_PLACES={[116448925875915]=true}
if not VERIFIED_PLACES[game.PlaceId] or game.GameId~=10769464063 then
    local placeId,universeId=game.PlaceId,game.GameId
    warn("+1 Venom Evolution scan: unexpected place/universe. Actual PlaceId="..tostring(placeId)
        ..", GameId="..tostring(universeId)..". Expected a verified +1 Venom Evolution place in GameId=10769464063.")
    -- Identity-only evidence on a mismatch: no services, map/client reads, GUI,
    -- source collection, HTTP or gameplay. The complete scan gate stays strict.
    local function validId(value)
        return type(value)=="number" and value==value and value>=0 and value<=9007199254740991
            and value==math.floor(value)
    end
    if validId(placeId) and validId(universeId) then
        local identityEnv=_G
        if type(getgenv)=="function" then
            local ok,value=pcall(getgenv)
            if ok and type(value)=="table" then identityEnv=value end
        end
        local writer=type(identityEnv)=="table" and identityEnv.writefile or nil
        if type(writer)~="function" then writer=writefile end
        if type(writer)=="function" then
            pcall(writer,"school_hub_venom_evolution_identity.json",
                string.format('{"placeId":%.0f,"universeId":%.0f}',placeId,universeId))
        end
    end
    return
end
local env=_G
if type(getgenv)=="function" then
    local ok,value=pcall(getgenv)
    if ok and type(value)=="table" then env=value end
end
if type(env.StopSchoolHubVenomEvolutionInspect)=="function" then pcall(env.StopSchoolHubVenomEvolutionInspect) end
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local world=game:GetService("Workspace")
-- Some executor built-ins are available as globals but absent from getgenv/_G.
local builtinCapabilities={writefile=writefile,setclipboard=setclipboard,toclipboard=toclipboard,decompile=decompile}
local function capability(names)
    for _,scope in ipairs({env,_G,builtinCapabilities}) do
        for _,name in ipairs(names) do if type(scope[name])=="function" then return scope[name] end end
    end
end
local textService
pcall(function() textService=game:GetService("TextService") end)
local guiParent=player:WaitForChild("PlayerGui",10)
if not guiParent then warn("School Hub: PlayerGui is unavailable. Spawn, then run the scan again.");return end
local controller,ui
ui=VenomEvolutionInspectUI.Create({parent=guiParent,UserInputService=game:GetService("UserInputService"),
    workspace=world,Theme=SchoolHubTheme,Brand=SchoolHubBrand,TextService=textService,
    onCollect=function()
        if controller and not controller.IsBusy() then
            ui.SetBusy(true)
            if not controller.Start(true) then ui.SetBusy(false) end
        end
    end,
    onCopy=function() if controller then controller.CopyReport() end end,
    onClose=function() if controller then controller.Stop() end end})
controller=VenomEvolutionInspector.Create({env=env,player=player,Players=Players,
    ReplicatedStorage=game:GetService("ReplicatedStorage"),workspace=world,
    HttpService=game:GetService("HttpService"),task=task,clock=os.clock,
    placeId=game.PlaceId,universeId=game.GameId,writer=capability({"writefile"}),
    clipboard=capability({"setclipboard","toclipboard"}),decompile=capability({"decompile"}),
    onStop=function() ui.Destroy() end,
    onStatus=function(message,kind)
        ui.SetStatus(message,kind)
        if kind=="error" and controller and not controller.IsBusy() then ui.SetBusy(false) end
    end,
    onComplete=function() ui.SetBusy(false) end})
