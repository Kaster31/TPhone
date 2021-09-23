--******[ Описание Скрипта ]*******
script_authors('Leon4ik')
script_version('1.0')
script_version_number(1)
-- [ Библиотеки ]
require ('lib.moonloader')
local vkeys = require ('vkeys')
local imgui = require('imgui')
local sampev = require 'lib.samp.events'
local fa = require 'fAwesome5'
local imadd = require 'imgui_addons'
local inicfg = require 'inicfg'
local encoding = require 'encoding'
local folder = require 'folder'
encoding.default = 'CP1251'
u8 = encoding.UTF8

--**********[ Работа с директориями ]************
if not doesDirectoryExist(getWorkingDirectory()..'\\config\\TPhone') then 
    createDirectory(getWorkingDirectory()..'\\config\\TPhone')
    createDirectory(getWorkingDirectory()..'\\config\\TPhone\\CallLog')  
end
local NumberLog = io.open(getWorkingDirectory()..'\\config\\TPhone\\NumberLog.txt',"r");
if NumberLog == nil then 
    NumberLog = io.open(getWorkingDirectory()..'\\config\\TPhone\\NumberLog.txt',"w"); 
    NumberLog:close()
end
local ini = 'TPhone/Settings.ini'
local mainini = inicfg.load(nil, ini)
if mainini == nil then 
    main =  {
        main = 
        {
			numlog = false,
            imagealpha = 25,
            imagename = 'image.png'
        }
    }
        inicfg.save(main, ini) 
        mainini = inicfg.load(nil, ini)
end
--**********[ Переменные ]************
local russian_characters = {
	[168] = 'Ё', [184] = 'ё', [192] = 'А', [193] = 'Б', [194] = 'В', [195] = 'Г', [196] = 'Д', [197] = 'Е', [198] = 'Ж', [199] = 'З', [200] = 'И', [201] = 'Й', [202] = 'К', [203] = 'Л', [204] = 'М', [205] = 'Н', [206] = 'О', [207] = 'П', [208] = 'Р', [209] = 'С', [210] = 'Т', [211] = 'У', [212] = 'Ф', [213] = 'Х', [214] = 'Ц', [215] = 'Ч', [216] = 'Ш', [217] = 'Щ', [218] = 'Ъ', [219] = 'Ы', [220] = 'Ь', [221] = 'Э', [222] = 'Ю', [223] = 'Я', [224] = 'а', [225] = 'б', [226] = 'в', [227] = 'г', [228] = 'д', [229] = 'е', [230] = 'ж', [231] = 'з', [232] = 'и', [233] = 'й', [234] = 'к', [235] = 'л', [236] = 'м', [237] = 'н', [238] = 'о', [239] = 'п', [240] = 'р', [241] = 'с', [242] = 'т', [243] = 'у', [244] = 'ф', [245] = 'х', [246] = 'ц', [247] = 'ч', [248] = 'ш', [249] = 'щ', [250] = 'ъ', [251] = 'ы', [252] = 'ь', [253] = 'э', [254] = 'ю', [255] = 'я',
}
local variables =
{
    imgui =
    {
        Imgui_PhoneCall = imgui.ImBool(false), -- меню для звонка
        Imgui_Window = imgui.ImBool(false),    -- Основное окно Имгуи
        Imgui_Call = imgui.ImBool(false),    -- Call окно Имгуи
        Imgui_Images = imgui.ImBool(false), -- Окно с настройкой фона
        Imgui_CallLog = imgui.ImBool(mainini.main.numlog),
        ButtonSize = imgui.ImVec2(40,40),
        NilButtonSize = imgui.ImVec2(-0.1, 0),
        Search_User = imgui.ImBuffer(32),
        ImageAlpha = imgui.ImInt(mainini.main.imagealpha) -- Прозрачность фона
    },
    default =
    {
        Settings = false, -- Включение настроек в телефоне
        UserCallText = {}, -- массив c Логом сообщений игрока
        RenderUserText = {}, -- отоброжаемый массив с логом сообщений игрока
        NowDate = 'nil', -- текущая дата Сообщения
        Render_Chat = false, -- Отображать чат с игроком
        NowNick = '', -- Ник текущего открытого Лога
        NowPhone = {}, -- текущий введёный номер телефона
        CheckBank = false, -- Проверка баланса банка
        CheckBalance = false, -- Проверка баланса телефона
        ImageNumber = 1 -- ID изображений фона imgui
    }
}

local image
local imgs
local logo = {}
local lib = folder.new(getWorkingDirectory() .. '\\lib\\')

--**********[ Main ]************
function main()
    while not isSampAvailable() do wait(100) end
    repeat wait(0) until sampIsLocalPlayerSpawned()
    Check_Mode()
	wait(1000)
	
    if doesFileExist(getWorkingDirectory().."/config/TPhone/Images/"..mainini.main.imagename) then
		image = imgui.CreateTextureFromFile(getWorkingDirectory().."/config/TPhone/Images/"..mainini.main.imagename)
	else
		image = nil
	end
    imgs = folder.new(getWorkingDirectory().."/config/TPhone/Images/")
    imgs:submit('*')
    info = {}
    local files = imgs:files()
    for i = 2, #files do
        if files[i]:type() == 'file' then
            info[#info + 1] = files[i]
            logo[#info+1] = imgui.CreateTextureFromFile(files[i]:get_path()..files[i]:get_name())
        end
    end
    sampRegisterChatCommand('ph',function()
        variables.imgui.Imgui_Window.v = not variables.imgui.Imgui_Window.v
        if variables.imgui.Imgui_Call.v then
            variables.imgui.Imgui_Call.v = false
        end
    end)
    while true do
        wait(0)
        imgui.Process = variables.imgui.Imgui_Window.v or variables.imgui.Imgui_Call.v or variables.imgui.Imgui_PhoneCall.v or variables.imgui.Imgui_Images.v
        
    end
end
--**********[ Imgui ]************

local fa_font = nil
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig() -- to use 'imgui.ImFontConfig.new()' on error
        font_config.MergeMode = true
        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 13.0, font_config, fa_glyph_ranges)
    end
end

function imgui.OnDrawFrame()
    local x,y = getScreenResolution()   
    if variables.imgui.Imgui_Window.v then
        imgui.SetNextWindowPos(imgui.ImVec2(x-210, y-410), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(200.0, 400.0), imgui.Cond.FirstUseEver)
        imgui.Begin('TPhone', variables.imgui.Imgui_Window,imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove)
        imgui.BeginChild('##Phone', imgui.ImVec2(180,390), true)

            Imgui_Phone() -- Телефон
            Imgui_Settings()  -- настройки телефона

        imgui.EndChild()
        imgui.End()
    end

    if variables.imgui.Imgui_Call.v then
        imgui.SetNextWindowPos(imgui.ImVec2(x/3, y/3), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(1000.0, 500.0), imgui.Cond.FirstUseEver)
        imgui.Begin('CallLog', variables.imgui.Imgui_Window,imgui.WindowFlags.NoTitleBar)
        imgui.BeginChild('##CallLog', imgui.ImVec2(200,490), true)

            Imgui_CallLogs()    -- Внесение списка игроков, с которыми был разговор

        imgui.EndChild()
        imgui.SameLine()

            Imgui_Chat()    -- Сам чат

        imgui.End()
    end
end

---- Функция внутри Imgui
function Imgui_Phone()
    imgui.SetCursorPos(imgui.ImVec2(1,1))
    local dates = os.date("*t")
    if imgui.ButtonHex('            '..fa.ICON_FA_PHONE_SLASH..'  '..fa.ICON_FA_WIFI..'  '..fa.ICON_FA_BATTERY_THREE_QUARTERS..'  '..dates.hour..':'..dates.min,0x808080,imgui.ImVec2(200,20))
    then
        variables.default.Settings = not variables.default.Settings
        variables.imgui.Imgui_PhoneCall.v = false
        variables.imgui.Imgui_Images.v = false
    end
    -- [ Главный экран ]
    if not variables.default.Settings and not variables.imgui.Imgui_PhoneCall.v and not variables.imgui.Imgui_Images.v then
        if image ~= nil then
            local size = imgui.GetWindowSize()
			local bColor = imgui.ImColor(255, 255, 255, mainini.main.imagealpha):GetU32()
            imgui.Image(image, imgui.ImVec2(size.x-20, size.y-90), imgui.ImVec2(0, 0), imgui.ImVec2(1, 1), imgui.ImColor(bColor):GetVec4())
        end
        imgui.SetCursorPos(imgui.ImVec2(20,40))
        -- [ 1 строка приложений - Такси | Скорая | Банк ]
        if imgui.ButtonHex(fa.ICON_FA_TAXI..'##Taxi',0xffff00,variables.imgui.ButtonSize) then
            sampSendChat('/service taxi')
        end
        imgui.SameLine(70)
        if imgui.ButtonHex(fa.ICON_FA_COMMENT_MEDICAL..'##Medic',0xff0000, variables.imgui.ButtonSize) then
            sampSendChat('/service medic')
        end
        imgui.SameLine(120)
        if imgui.ButtonHex(fa.ICON_FA_DOLLAR_SIGN..'##Bank',0x90ee90, variables.imgui.ButtonSize) then 
            sampSendChat('/stats') 
            variables.default.CheckBank = true
        end
        -- [ 2 строка приложений - Смена фона | | ]
        imgui.SetCursorPos(imgui.ImVec2(20,90))
        if imgui.ButtonHex(fa.ICON_FA_STICKY_NOTE..'##Scticky',0xffa500,variables.imgui.ButtonSize) then
            variables.imgui.Imgui_Images.v = true
        end
        imgui.SameLine(70)
        if imgui.ButtonHex(fa.ICON_FA_MOBILE..'##Balance',0xffa500, variables.imgui.ButtonSize) then
            sampSendChat('/invex')
            variables.default.CheckBalance = true
        end


    -- [ Набор телефона ]
    elseif not variables.default.Settings and variables.imgui.Imgui_PhoneCall.v and not variables.imgui.Imgui_Images.v then
        local space = 120

        imgui.NewLine()
        imgui.SetCursorPos(imgui.ImVec2(50,50))
        imgui.Text(table.concat( variables.default.NowPhone, "" ))

        imgui.SetCursorPos(imgui.ImVec2(30,space))
        for i=1,9 do
            if imgui.ButtonHex(tostring(i)..'##phone',0xffffff,variables.imgui.ButtonSize) then 
                table.insert(variables.default.NowPhone, tostring(i))
            end
            if i%3==0 then imgui.SetCursorPos(imgui.ImVec2(30,space+i*15)) else imgui.SameLine() end
        end
        if imgui.ButtonHex(fa.ICON_FA_PHONE..'##CALL',0x00ff00,variables.imgui.ButtonSize) then sampSetChatInputEnabled(true) sampSetChatInputText('/call '..table.concat( variables.default.NowPhone, "" )) end
        imgui.SameLine()
        if imgui.ButtonHex('0##phone',0xffffff,variables.imgui.ButtonSize) then 
            table.insert(variables.default.NowPhone, '0')
        end
        imgui.SameLine()
        if imgui.ButtonHex(fa.ICON_FA_BACKSPACE..'##BACKSPACE',0x0000ff,variables.imgui.ButtonSize) then 
            table.remove( variables.default.NowPhone,#variables.default.NowPhone)
        end

        imgui.SetCursorPos(imgui.ImVec2(1,350))
        imgui.Separator()
        imgui.SetCursorPos(imgui.ImVec2(1,360))
        if imgui.ButtonHex(fa.ICON_FA_LONG_ARROW_ALT_LEFT, 0x808080, imgui.ImVec2(200,20)) then
            variables.imgui.Imgui_PhoneCall.v = false
        end
    -- [ Смена фона ]
    elseif variables.imgui.Imgui_Images.v and not variables.default.Settings and not variables.imgui.Imgui_PhoneCall.v then
        local width, height = imgsize(info[variables.default.ImageNumber]:full_path_name())
        local size = imgui.GetWindowSize()
        local bColor = imgui.ImColor(255, 255, 255, 255):GetU32()
        imgui.Image(logo[variables.default.ImageNumber+1], imgui.ImVec2(size.x-20, size.y-90), imgui.ImVec2(0, 0), imgui.ImVec2(1, 1), imgui.ImColor(bColor):GetVec4())
        imgui.NewLine()
        if variables.default.ImageNumber > 1 then
            imgui.SameLine(20)
            if imgui.ButtonHex('<--', 0x808080, imgui.ImVec2(60,20)) then
                variables.default.ImageNumber = variables.default.ImageNumber - 1
            end
        end
        if variables.default.ImageNumber < #info and variables.default.ImageNumber > 1 then
            imgui.SameLine(100)
        end
        if variables.default.ImageNumber < #info then
            imgui.SameLine(100)
            if imgui.ButtonHex('-->', 0x808080, imgui.ImVec2(60,20)) then
                variables.default.ImageNumber = variables.default.ImageNumber + 1
            end
        end
        imgui.NewLine()
        imgui.SameLine(20)
        if imgui.ButtonHex(fa.ICON_FA_SAVE, 0x42aaff, imgui.ImVec2(60,20)) then
            mainini.main.imagename = info[variables.default.ImageNumber]:get_name()
            image = imgui.CreateTextureFromFile(getWorkingDirectory().."/config/TPhone/Images/"..mainini.main.imagename)
            inicfg.save(mainini, ini)
        end
        imgui.SameLine(100)
        if imgui.ButtonHex(fa.ICON_FA_LONG_ARROW_ALT_LEFT, 0x808080, imgui.ImVec2(60,20)) then
            variables.imgui.Imgui_Images.v = false
        end
    end
end

function Imgui_CallLogs()
    local NumberLog = io.open(getWorkingDirectory()..'\\config\\TPhone\\NumberLog.txt',"r");
    local Render_User = {}
    for line in NumberLog:lines() do
        table.insert( Render_User, line)
    end
    NumberLog:close()
    if variables.imgui.Search_User.v == '' then
        imgui.SetCursorPosX(80)
        imgui.Text(u8'Поиск')
    end
    imgui.PushItemWidth(180)
    imgui.InputText('##Search_User', variables.imgui.Search_User)
    imgui.PopItemWidth()
    imgui.Separator()
    if  variables.imgui.Search_User.v ~= '' then
        for key, value in pairs(Render_User) do
            if string.find(string.rlower(Render_User[key]), string.rlower(variables.imgui.Search_User.v)) then
                if imgui.Button(u8(value),variables.imgui.NilButtonSize) then
                    local User = io.open(getWorkingDirectory()..'\\config\\TPhone\\CallLog\\'..value..'.txt',"r")
                    variables.default.NowNick = value
                    variables.default.UserCallText = {}
                    for lines in  User:lines() do
                        table.insert(variables.default.UserCallText,lines)
                    end
                    variables.default.Render_Chat = not variables.default.Render_Chat
                    User:close()
                end
            end
        end
    else
        for key, value in pairs(Render_User) do
            if imgui.Button(u8(value),variables.imgui.NilButtonSize) then
                local User = io.open(getWorkingDirectory()..'\\config\\TPhone\\CallLog\\'..value..'.txt',"r")
                variables.default.NowNick = value
                variables.default.UserCallText = {}
                for lines in  User:lines() do
                    table.insert(variables.default.UserCallText,lines)
                end
                variables.default.Render_Chat = not variables.default.Render_Chat
                User:close()
            end
        end
    end
end

function Imgui_Chat()
    if variables.default.Render_Chat then
        imgui.BeginChild('##CallLogSMS', imgui.ImVec2(780,490), false)
        variables.default.RenderUserText = {} -- Массив Log сообщений с игроком
        for k,v in ipairs(variables.default.UserCallText) do  -- разделение строки на дату,время,текст
            local SMS, mySMS = '', ''
            if v:find('%(1%)%(%$%$') then
                SMS = split(v,'(1)($$')
                SMS = split(SMS[2],'$$)')
                SMS[1] = split(SMS[1],'&&')  
                table.insert(variables.default.RenderUserText,{1,SMS[1][1],SMS[1][2],SMS[2]})    
            else 
                mySMS = split(v,'(2)($$')
                mySMS = split(mySMS[2],'$$)')
                mySMS[1] = split(mySMS[1],'&&')
                table.insert(variables.default.RenderUserText,{2,mySMS[1][1],mySMS[1][2],mySMS[2]})
            end
        end
        ----------------------------------------------------
        imgui.BeginChild('##Names', imgui.ImVec2(760,35), true)
        if sampGetPlayerIdByNickname(variables.default.NowNick) ~= -1 then 
            imgui.Text(fa.ICON_FA_SIGNAL..' ID['..sampGetPlayerIdByNickname(variables.default.NowNick)..']')
        else imgui.Text(fa.ICON_FA_USER_ALT_SLASH.. '')
        end
        imgui.SameLine()
        imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8('Удалить переписку')).x)-50)
        ------------------ Удаление переписки
        if imgui.ButtonHex(u8('Удалить переписку'),'0xff0000',imgui.ImVec2(imgui.CalcTextSize(u8('Удалить переписку')).x +15,20)) then
            os.remove(getWorkingDirectory()..'\\config\\TPhone\\CallLog\\'..variables.default.NowNick..'.txt')
            local Delete_User = io.open(getWorkingDirectory()..'\\config\\TPhone\\NumberLog.txt',"r")
            local Nicks = {}
            for line in Delete_User:lines() do
                if line ~= variables.default.NowNick then
                    table.insert(Nicks,line)
                end
            end
            Delete_User:close()
            Delete_User = io.open(getWorkingDirectory()..'\\config\\TPhone\\NumberLog.txt',"w")
            for k,v in ipairs(Nicks) do
                Delete_User:write(v..'\n')
            end
            Delete_User:close()
            variables.default.Render_Chat = false
        end
        imgui.EndChild()

        imgui.BeginChild('##CallLogSMS', imgui.ImVec2(760,450), true)
        -------------------
        imgui.Separator()

        variables.default.NowDate = variables.default.RenderUserText[1][2]  -- Первая дата 
        imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8(variables.default.NowDate)).x) / 2)   -- центрирование
        imgui.Text(u8(variables.default.NowDate)) -- Вывод первой даты
        for k,v in ipairs(variables.default.RenderUserText) do
            if variables.default.NowDate ~= v[2] then
                variables.default.NowDate = v[2]
                imgui.NewLine()
                imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8(v[2])).x) / 2)
                imgui.Text(u8(v[2]))
            end
            if v[1] == 1 then
                imgui.ButtonHex(u8(v[4]),'0x008000',imgui.ImVec2(imgui.CalcTextSize(u8(v[4])).x+15,20))
            else
                imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8(v[4])).x)-50)
                imgui.ButtonHex(u8(v[4]),'0xff0000',imgui.ImVec2(imgui.CalcTextSize(u8(v[4])).x+15,20))
            end
        end
        imgui.EndChild()
        imgui.EndChild()
    end
end

function Imgui_Settings()
    if not variables.default.Settings and not variables.imgui.Imgui_PhoneCall.v and not variables.imgui.Imgui_Images.v then
        for i=1,11 do 
            imgui.NewLine()
        end
        imgui.Separator()
            -- ******** [ CallLog ]
        if imgui.ButtonHex(fa.ICON_FA_PHONE..'##PHONE',0x008000,variables.imgui.ButtonSize) then
            variables.imgui.Imgui_PhoneCall.v = not variables.imgui.Imgui_PhoneCall.v
        end
        ------------- Меню
        imgui.SameLine(70)
        if imgui.ButtonHex('...'..'##MENU',0xFFFFFF,variables.imgui.ButtonSize) then
            variables.imgui.Imgui_Window.v = false
            variables.imgui.Imgui_Call.v = false
        end
        imgui.SameLine(130)
        if imgui.Button(fa.ICON_FA_ID_CARD..'##CONTACT',variables.imgui.ButtonSize) then
            variables.imgui.Imgui_Call.v = not variables.imgui.Imgui_Call.v
        end
    elseif not variables.imgui.Imgui_PhoneCall.v and variables.default.Settings then -- ******** [ Если настройки телефона включены]
        if imadd.ToggleButton(u8'##CallLog', variables.imgui.Imgui_CallLog) then
            mainini.main.numlog = variables.imgui.Imgui_CallLog.v
            inicfg.save(mainini, ini)
        end
        imgui.SameLine()
        imgui.Text(variables.imgui.Imgui_CallLog.v and u8'Лог звонков включён' or u8'Лог звонков выключен')
        imgui.Separator()
        imgui.Text(u8'Смена прозрачности фона')
        if imgui.InputInt(u8'##Сменить VKID', variables.imgui.ImageAlpha) then
            if variables.imgui.ImageAlpha.v < 1 then variables.imgui.ImageAlpha.v = 1 elseif variables.imgui.ImageAlpha.v > 255 then variables.imgui.ImageAlpha.v = 255 end
            mainini.main.imagealpha = variables.imgui.ImageAlpha.v
            inicfg.save(mainini, ini)
        end
    end
end
--**********[ Хуки ]************
local BalanceGo = 0
function sampev.onShowDialog(id, stytle, title, btn1, btn2, text)
        if title:match('Статистика игрового аккаунта') and variables.default.CheckBank then
            for bank in text:gmatch("[^\r\n]+") do
                if bank:match("Счет в банке")then
                    local money = bank:match("{ffffff}Счет в банке.+{ffff00}(.+)")
                    sampAddChatMessage('{FFFFFF}[{1E90FF}TelePhone{FFFFFF}] Ваш банковский счёт составляет: {ffff00}'..money,-1)
                    sampSendDialogResponse(id,0,0,'')
                    variables.default.CheckBank = not variables.default.CheckBank
                    return false
                end
            end
        end
        if title:match('Ваш инвентарь') and variables.default.CheckBalance and BalanceGo == 0 then
            local i = 0
            for item in text:gmatch("[^\r\n]+") do
                i = i + 1
                if item:find("Телефон") ~= nil then
                    sampSendDialogResponse(id, 1, i-1, "")
                    return false
                end
            end
        end
        if title:match('Ваш инвентарь') and not variables.default.CheckBalance and BalanceGo == 2 then
            sampSendDialogResponse(id, 0, 0, "")
            BalanceGo = 0
            return false
        end
        if title:match('Выберите действие') and variables.default.CheckBalance and BalanceGo == 0 then
            sampSendDialogResponse(id, 1, 0, "")
            return false
        end
        if title:match('Выберите действие') and not variables.default.CheckBalance and BalanceGo == 1 then
            sampSendDialogResponse(id,btn2,0,'')
            BalanceGo = 2
            return false
        end
        if title:find('Информация') and variables.default.CheckBalance then
            local money
            for balance in text:gmatch("[^\r\n]+") do
                if balance:match("Баланс мобильного телефона:") then
                    money = balance:match("Баланс мобильного телефона:(.+)")
                    variables.default.CheckBalance = false
                    sampSendDialogResponse(id,btn2,0,'')
                    break
                end
            end
            sampAddChatMessage('{FFFFFF}[{1E90FF}TelePhone{FFFFFF}] Баланс мобильного телефона составляет:{ffff00}'..money,-1)
            BalanceGo = 1
            return false
        end
end

local nick = 'nil'
function sampev.onServerMessage(color,text)
    if mainini.main.numlog then -- Если Логирование включено
        if text:match('Абонент {66FF66}%a+_%a+.%d+.{ffffff} ответил на ваш звонок.') then 
            nick = text:match('Абонент {66FF66}(%a+_%a+).%d+.{ffffff} ответил на ваш звонок.')  
            WritelNumberLog(nick)
        elseif text:match('Абонент {66FF66}%a+_%a+{ffffff} ответил на ваш звонок.') then
            nick = text:match('Абонент {66FF66}(%a+_%a+){ffffff} ответил на ваш звонок.')
            WritelNumberLog(nick)
        elseif text:match('Вы ответили на звонок {66FF66}}%a+_%a+.%d+.{ffffff}. Используйте {fbec5d}/h{ffffff}, чтобы положить трубку.') then
            nick = text:match('Вы ответили на звонок {66FF66}}(%a+_%a+).%d+.{ffffff}. Используйте {fbec5d}/h{ffffff}, чтобы положить трубку.')
        elseif text:match('Вы ответили на звонок {66FF66}}%a+_%a+{ffffff}. Используйте {fbec5d}/h{ffffff}, чтобы положить трубку.') then 
            nick = text:match('Вы ответили на звонок {66FF66}}(%a+_%a+){ffffff}. Используйте {fbec5d}/h{ffffff}, чтобы положить трубку.')
        end
        if text:match('%a+_%a+.%d+. по телефону: .+') and nick ~= 'nil' then
            local nickNum,txt = text:match('(%a+_%a+).%d+. по телефону: (.+)')
            if nickNum == nick then
                WriteLog(nick,txt,true)
            elseif nickNum == sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) then
                WriteLog(nick,txt,false)
            end
        elseif text:match('.+ по телефону: .+') and nick ~= 'nil' then
            local nickNum,txt = text:match('(.+) по телефону: (.+)') 
            if nickNum == nick then
                WriteLog(nick,txt,true)
            elseif nickNum == sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) then
                WriteLog(nick,txt,false)
            end
        end
        if nick ~= 'nil' and text:match('Вы повесили трубку. Разговор с {66FF66}}%a+_%a+.%d+.{ffffff} окончен.')
        or text:match('Вы повесили трубку. Разговор с {66FF66}}%a+_%a+{ffffff} окончен.')
        or text:match('Абонент {66FF66}%a+_%a+.%d+.{ffffff} повесил трубку, разговор окончен.')
        or text:match('Абонент {66FF66}%a+_%a+{ffffff} повесил трубку, разговор окончен.')
        then
            nick = 'nil'
        end

    end
end

function WritelNumberLog(nick)
    local NumberLog = io.open(getWorkingDirectory()..'\\config\\TPhone\\NumberLog.txt',"a");
    NumberLog:write(nick..'\n')
    NumberLog:close()
end

function WriteLog(nick,text,mode)
    local dates = os.date("*t")
    local f = io.open(getWorkingDirectory()..'\\config\\TPhone\\CallLog\\'..nick..'.txt',"a")
    if f == nil then 
      f = io.open(getWorkingDirectory()..'\\config\\TPhone\\CallLog\\'..nick..'.txt',"w")
      f:close()
      f = io.open(getWorkingDirectory()..'\\config\\TPhone\\CallLog\\'..nick..'.txt',"a")
    end
    if mode then
        f:write('(1)($$'..dates.day..':'..dates.month..':'..dates.year..'&&'.. dates.hour..':'..dates.min..':'..dates.sec ..'$$)'..text..'\n')
    else  
        f:write('(2)($$'..dates.day..':'..dates.month..':'..dates.year..'&&'.. dates.hour..':'..dates.min..':'..dates.sec .. '$$)'..text..'\n')
    end
    f:close()
end
--**********[ Стиль ]************
function style() -- стиль
    imgui.SwitchContext()
    local style  = imgui.GetStyle()
    local colors = style.Colors
    local clr    = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2

    style.WindowPadding       = ImVec2(10, 10)
    style.WindowRounding      = 10
    style.ChildWindowRounding = 15
    style.FramePadding        = ImVec2(5, 4)
    style.FrameRounding       = 10
    style.ItemSpacing         = ImVec2(4, 4)
    style.TouchExtraPadding   = ImVec2(0, 0)
    style.IndentSpacing       = 21
    style.ScrollbarSize       = 16
    style.ScrollbarRounding   = 16
    style.GrabMinSize         = 11
    style.GrabRounding        = 16
    style.WindowTitleAlign    = ImVec2(0.5, 0.5)
    style.ButtonTextAlign     = ImVec2(0.5, 0.5)

    colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]         = ImVec4(0.73, 0.75, 0.74, 1.00)
    colors[clr.WindowBg]             = ImVec4(0.09, 0.09, 0.09, 1.00)
    colors[clr.ChildWindowBg]        = ImVec4(10.00, 10.00, 10.00, 0.01)
    colors[clr.PopupBg]              = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border]               = ImVec4(0.20, 0.20, 0.20, 0.50)
    colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg]              = ImVec4(0.00, 0.39, 1.00, 0.65)
    colors[clr.FrameBgHovered]       = ImVec4(0.11, 0.40, 0.69, 1.00)
    colors[clr.FrameBgActive]        = ImVec4(0.11, 0.40, 0.69, 1.00)
    colors[clr.TitleBg]              = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.TitleBgActive]        = ImVec4(0.00, 0.24, 0.54, 1.00)
    colors[clr.TitleBgCollapsed]     = ImVec4(0.00, 0.22, 1.00, 0.67)
    colors[clr.MenuBarBg]            = ImVec4(0.08, 0.44, 1.00, 1.00)
    colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]        = ImVec4(0.31, 0.31, 0.31, 1.00)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]  = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.ComboBg]              = ImVec4(0.20, 0.20, 0.20, 0.99)
    colors[clr.CheckMark]            = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.SliderGrab]           = ImVec4(0.34, 0.67, 1.00, 1.00)
    colors[clr.SliderGrabActive]     = ImVec4(0.84, 0.66, 0.66, 1.00)
    colors[clr.Button]               = ImVec4(0.00, 0.39, 1.00, 0.65)
    colors[clr.ButtonHovered]        = ImVec4(0.00, 0.64, 1.00, 0.65)
    colors[clr.ButtonActive]         = ImVec4(0.00, 0.53, 1.00, 0.50)
    colors[clr.Header]               = ImVec4(0.00, 0.62, 1.00, 0.54)
    colors[clr.HeaderHovered]        = ImVec4(0.00, 0.36, 1.00, 0.65)
    colors[clr.HeaderActive]         = ImVec4(0.00, 0.53, 1.00, 0.00)
    colors[clr.Separator]            = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.SeparatorHovered]     = ImVec4(0.71, 0.39, 0.39, 0.54)
    colors[clr.SeparatorActive]      = ImVec4(0.71, 0.39, 0.39, 0.54)
    colors[clr.ResizeGrip]           = ImVec4(0.71, 0.39, 0.39, 0.54)
    colors[clr.ResizeGripHovered]    = ImVec4(0.84, 0.66, 0.66, 0.66)
    colors[clr.ResizeGripActive]     = ImVec4(0.84, 0.66, 0.66, 0.66)
    colors[clr.CloseButton]          = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.CloseButtonHovered]   = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.CloseButtonActive]    = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.TextSelectedBg]       = ImVec4(0.26, 0.59, 0.98, 0.35)
    colors[clr.ModalWindowDarkening] = ImVec4(0.80, 0.80, 0.80, 0.35)
end
style()

--**********[ Функции ]************
function Check_Mode()   -- Проверка сервера
    local ip, port = sampGetCurrentServerAddress()
    if ip == '185.169.134.85' or ip == '185.169.134.84' or ip == '185.169.134.83' then
        sampAddChatMessage("{FFFFFF}[{1E90FF}TelePhone{FFFFFF}] Author:{42aaff} Leon4ik", -1)
    else 
        sampAddChatMessage('[{1E90FF}TelePhone{FFFFFF}] Вы находитесь не на сервере {008000}Trinity',-1)
        thisScript():unload()
    end
end


function string.rlower(s)
	s = s:lower()
	local strlen = s:len()
	if strlen == 0 then return s end
	s = s:lower()
	local output = ''
	for i = 1, strlen do
		 local ch = s:byte(i)
		 if ch >= 192 and ch <= 223 then -- upper russian characters
			  output = output .. russian_characters[ch + 32]
		 elseif ch == 168 then -- Ё
			  output = output .. russian_characters[184]
		 else
			  output = output .. string.char(ch)
		 end
	end
	return output
end

function imgui.ButtonHex(lable, rgb, size)
    local r = bit.band(bit.rshift(rgb, 16), 0xFF) / 255
    local g = bit.band(bit.rshift(rgb, 8), 0xFF) / 255
    local b = bit.band(rgb, 0xFF) / 255

    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(r, g, b, 0.6))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(r, g, b, 0.8))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(r, g, b, 1.0))
    local button = imgui.Button(lable, size)
    imgui.PopStyleColor(3) 
    return button
end

function split(str, delim, plain)
    local tokens, pos, plain = {}, 1, not (plain == false)
    repeat
        local npos, epos = string.find(str, delim, pos, plain)
        table.insert(tokens, string.sub(str, pos, npos and npos - 1))
        pos = epos and epos + 1
    until not pos
    return tokens
end

function sampGetPlayerIdByNickname(nick)
    nick = tostring(nick)
    local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if nick == sampGetPlayerNickname(myid) then return myid end
    for i = 0, 1003 do
      if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == nick then
        return i
      end
    end
    return -1
end

-- // Вырезано с imagesize. Определяет размер PNG картинки
function imgsize(filename)
    local TYPE_MAP = {
		["^GIF8[7,9]a"]          = "gif",
		["^\255\216"]            = "jpeg",
		["^\137PNG\13\10\26\10"] = "png",
		["^P[1-7]"]              = "pnm",   -- also XVpics
		["#define%s+%S+%s+%d+"]  = "xbm",
		["/%* XPM %*/"]          = "xpm",
		["^MM%z%*"]              = "tiff",
		["^II%*%z"]              = "tiff",
		["^BM"]                  = "bmp",
		["^8BPS"]                = "psd",
		["^PCD_OPA"]             = "pcd",
		["^[FC]WS"]              = "swf",
		["^\138MNG\13\10\26\10"] = "mng",
		["^gimp xcf "]           = "xcf",   -- TODO - usually gziped
	}
    local filetype = type(filename)
    local file, closefile, origoffset
    if filetype == "string" or filetype == "number" then
        file, err = io.open(filename, "rb")
        if not file then
            return nil, nil, "error opening file '" .. filename .. "': " .. err
        end
        closefile = true
    else
        file, closefile = filename, false
        origoffset = file:seek()
    end

    local header = file:read(256)
    if not header then return nil, nil, "file is empty" end
    local ok, err = file:seek("set")
    if not ok then return nil, nil, "error seeking in file: " .. err end

    for pattern, format in pairs(TYPE_MAP) do
        if header:find(pattern) then
            local x, y, id = sizefunc(file)
            if closefile then file:close() end
            if origoffset then file:seek("set", origoffset) end
            return x, y, id
        end
    end
    if closefile then file:close() end
    if origoffset then file:seek("set", origoffset) end
    return nil, nil, "file format not recognized"
end

function sizefunc(stream)
    local offset = 12
    local length = 4

    local ok, err = stream:seek("set", offset)
    if not ok then return nil, nil, "error seeking in PNG file: " .. err end

    local buf = stream:read(length)
    if not buf or buf:len() ~= length then
        return nil, nil, "PNG file not big enough to contain header data"
    end

    if buf == "IHDR" then
        length = 8
        buf = stream:read(length)
        if not buf or buf:len() ~= length then
            return nil, nil, "PNG file not big enough to contain header data"
        end
        return get_uint32_be(buf, 1), get_uint32_be(buf, 5), "image/png"
    else
        return nil, nil, "can't find header data in PNG file"
    end
end
