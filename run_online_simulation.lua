function CreateFakeLoginData()
    print("MOD: Creating NEW fake login data (First Run)...")
    local herosConfig = DataCacheManager:GetInstance().heros
    local unlockedHeroInfo, unlockedSkinInfo = {}, {}
    for id, config in pairs(herosConfig) do
        if config.isPublish == 1 or config.isPublish == true then
            if config.type == 1 then
                table.insert(unlockedHeroInfo, { heroId = id, isUnlock = true, isPublish = true, equipedSkin = id, inningCount = 0, inningWinCount = 0 })
            end
            table.insert(unlockedSkinInfo, { heroSkinId = id, isUnlock = true, isPublish = true })
        end
    end
    print("MOD: Unlocked " .. #unlockedHeroInfo .. " heroes and " .. #unlockedSkinInfo .. " skins.")

    local fakeRecvJson = {
        code = 0,
        userInfo = { userId = 1337, userName = "游客-1337", changeNameTimes = 1, tagline = "我就是服务器！", level = 99, exp = 9999, vipGrade = 9 },
        currency = { [DataConfig.Virtual.Copper] = 999999, [DataConfig.Virtual.Diamond] = 999999, [DataConfig.Virtual.Dobi] = 99 },
        heroInfo = unlockedHeroInfo,
        heroSkinInfo = unlockedSkinInfo,
        arenaInfo = { eloScore = 2500, operateScore = 2500 },
        avatarInfo = { avatar = { type = 1, avatarId = 30001, frameId = 40001, customAvatar = "" }, sysAvatar = { 30001, 30002, 30003 }, sysAvatarFrame = { 40001, 40002 } },
        shopInfo = { emoji = {}, hero = {}, heroSkin = {}, ornaments = {} },
        achievement = {},
        dobi = { todayAdCount = 0, timestamp = LuaUtils:GetSysTime() },
        weeklyInfo = { matchGold = 0 },
        dailyInfo = { checkInAcitivty = false },
        emojiInfo = {},
        ornamentsInfo = {},
        remindInfo = "",
        guideInfo = "1;",
        storyInfo = {}, -- 剧情信息由下面的补丁动态解锁，此处留空
        userStatInfo = { battle = { allMatch = { inningCount = 0, inningWinCount = 0, perfectRoundWinCount = 0, highestInningWinStreak = 0 } }, time = { onlineTime = 0 }, hero = { all = { maxComboCount = {} } } },
        battleVersion = UserData:GetInstance().battleVersion,
        timestamp = LuaUtils:GetSysTime(),
        battleServers = { { serverId = 1, serverName = "模拟服务器", friendlyName = "模拟服务器", name = "simulated-server-1", ip = "127.0.0.1", port = 1, city = "本地" } },
        audioSettings = { effect = { isOpen = true, volume = 80 }, music = { isOpen = true, volume = 80 }, hero = { isOpen = true } },
        videoSettings = { isAA = true, isHalo = true, isNoise = true, isFps = true, isRefract = true, resolutionLevel = 1 },
        matchSettings = { fast = { select = 30, unlimit = false, section = { 20, 300 } } },
    }
    -- Dynamically populate shop prices
    local allEmojis = DataCacheManager:GetInstance().emoji; if allEmojis then for id in pairs(allEmojis) do table.insert(fakeRecvJson.shopInfo.emoji, { emojiId = id, price = { [DataConfig.Virtual.Copper] = 0 } }) end end
    local allItems = DataCacheManager:GetInstance().heros; if allItems then for id, data in pairs(allItems) do if data.type == 1 then table.insert(fakeRecvJson.shopInfo.hero, { heroId = id, price = { [DataConfig.Virtual.Copper] = 0 } }) elseif data.type == 2 then table.insert(fakeRecvJson.shopInfo.heroSkin, { heroSkinId = id, price = { [DataConfig.Virtual.Copper] = 0 } }) end end end
    local allOrnaments = DataCacheManager:GetInstance().item_ornaments; if allOrnaments then for id in pairs(allOrnaments) do table.insert(fakeRecvJson.shopInfo.ornaments, { oid = id, price = { [DataConfig.Virtual.Copper] = 0 } }) end end
    print("MOD: Added fake prices for shop items.")

    -- Unlock all emojis
    if allEmojis then
        for id, _ in pairs(allEmojis) do
            table.insert(fakeRecvJson.emojiInfo, { emojiId = id })
        end
        print("MOD: Unlocked " .. #fakeRecvJson.emojiInfo .. " emojis.")
    end

    -- Unlock all ornaments
    if allOrnaments then
        for id, _ in pairs(allOrnaments) do
            table.insert(fakeRecvJson.ornamentsInfo, { oid = id, heroId = 0 })
        end
        print("MOD: Unlocked " .. #fakeRecvJson.ornamentsInfo .. " ornaments.")
    end

    return fakeRecvJson
end

-- *** 补丁 14 (新增): 强制开启AR功能按钮 ***
-- 这个补丁会修改英雄皮肤界面的 `OnEnable` 函数，
-- 无论C#层检测结果如何，都强制显示AR按钮。
function Patch_EnableAR()
    print("MOD: Applying AR Button Patch...")
    -- 确保 UIHeroSkinView 已经加载
    local UIHeroSkinView = require "UI.shop.View.UIHeroSkinView"
    
    if UIHeroSkinView and UIHeroSkinView.OnEnable then
        local orig_OnEnable = UIHeroSkinView.OnEnable -- 保存原始函数
        
        -- 创建一个新的 OnEnable 函数
        UIHeroSkinView.OnEnable = function(self, ...)
            -- 1. 首先，执行所有原始的 OnEnable 逻辑，确保界面正常初始化
            orig_OnEnable(self, ...)
            
            -- 2. 然后，执行我们的补丁逻辑
            if self.Button_AR ~= nil then
                -- 强制将AR按钮设置为可见
                print("MOD: (AR Patch) Forcing AR button to be visible.")
                self.Button_AR:SetActive(true)
            end
        end
        print("MOD: UIHeroSkinView.OnEnable patched successfully for AR.")
    else
        print("MOD ERROR: Could not find UIHeroSkinView.OnEnable to patch for AR.")
    end
end

-- Comprehensive game logic patching function
function PatchGameLogic()
    print("MOD: Applying all game logic patches...")
    
    -- 1. Patch Story Mode
    local storyManager = StoryManager:GetInstance()
    if storyManager then
        print("MOD: Patching StoryManager...")
        storyManager.StageStart = function(self, isNext, isReStart)
            print("MOD: Intercepted StoryManager:StageStart.")
            local stageInfo = self:GetHeroStageInfo()
            stageInfo = table.sequencevaluebyindex(stageInfo, self.selectStageIndex)
            if stageInfo == nil then UIManager:GetInstance():Toast(LuaUtils:TranslateString("关卡数据出错")); return end
            stageInfo = stageInfo[self.selectStageGrade]
            if stageInfo.isLock ~= true then
                self.isStoryFightStart = true;
                if isReStart == true then FightMatchManager:GetInstance().gameManager:ReStartFight()
                else
                    local mission = MissionManager:GetInstance():SelectMission(self.selectStageId)
                    mission.Ailevel = stageInfo.Ailevel
                    if stageInfo.skin ~= 0 and HeroSkinManager:GetInstance().heroSkinConfig[stageInfo.skin] ~= nil then self.selectSkinId = stageInfo.skin; end
                    FightMatchManager:GetInstance():SetPlayerHpMultiple(1, stageInfo.hp)
                    FightMatchManager:GetInstance():StoryFight()
                end
            else UIManager:GetInstance():Toast(LuaUtils:TranslateString("关卡尚未解锁")) end
        end

        if storyManager.heroStoryStageInfoList then
            print("MOD: Forcibly unlocking all story difficulties.")
            for heroId, stageList in pairs(storyManager.heroStoryStageInfoList) do
                table.sequenceforeach(stageList, function(i, stageId, difficulties)
                    for _, difficultyInfo in ipairs(difficulties) do
                        difficultyInfo.isLock = false
                        difficultyInfo.isClear = true
                    end
                end)
            end
            print("MOD: All story difficulties unlocked.")
        end
    end

    -- 2. Patch Settings UI
    if UserData then
        print("MOD: Patching UserData...")
        UserData.GetMatchSettings = function(self, cb) if cb ~= nil then cb() end end
    end

    -- 3. Patch Shop UI
    local shopManager = ShopManager:GetInstance()
    if shopManager then
        print("MOD: Patching ShopManager...")
        shopManager.GetGiftPackageInfo = function(self, cb) self.giftPackageInfo = { code = 0 }; if cb ~= nil then cb() end end
    end

    -- 4. Patch Announcement UI
    local announcementManager = AnnouncementManager:GetInstance()
    if announcementManager then
        print("MOD: Patching AnnouncementManager...")
        announcementManager.Request = function(self, callback) if self.entranceData == nil then self.entranceData, self.data = {}, {} end; if callback ~= nil then callback(true) end end
    end

    -- 5. Patch Qualifying Match UI
    local qualifyManager = QualifyManager:GetInstance()
    if qualifyManager then
        print("MOD: Patching QualifyManager...")
        qualifyManager.GetRankingTop = function(self, seasonId, callback) if callback then callback() end end
        qualifyManager.OpenQualifyUI = function(self, reMatch, cb)
            coroutine.start(function()
                self:GetRankingTop(nil, function()
                    if self:IsQualifyEnable() then UIManager:GetInstance():OpenWindow(UIWindowNames.UIQualify, reMatch)
                    else UIManager:GetInstance():Toast(LuaUtils:TranslateString("排位赛尚未开启")) end
                    if cb ~= nil then cb() end
                end)
            end)
        end
    end

    -- 6. Patch Guest Login
    local loginManager = LoginManager:GetInstance()
    if loginManager then
        print("MOD: Patching LoginManager...")
        loginManager.GuestLogin = function(self)
            print("MOD: Intercepted LoginManager:GuestLogin.")
            local fakeLoginData = CreateFakeLoginData()
            local userDataManager = UserData:GetInstance()
            if self and fakeLoginData.battleServers and #fakeLoginData.battleServers > 0 then self.selectServer = fakeLoginData.battleServers[1] end
            userDataManager:initLoginData(fakeLoginData, false, false)
            userDataManager.isSingleMode = false
            NetWaitViewManager:GetInstance():RemoveWait("UserLogin");
        end
    end

    -- 7. Patch Fast Match
    local fightMatchManager = FightMatchManager:GetInstance()
    if fightMatchManager then
        print("MOD: Patching FightMatchManager...")
        fightMatchManager.CheckNetStatus = function(self, funCallBack)
            print("MOD: Intercepted and bypassed FightMatchManager:CheckNetStatus.")
            if funCallBack then
                funCallBack(true) -- Always return success immediately
            end
        end
    end

    -- 8. Patch Chat UI
    local openPrepareManager = UIOpenPrepareManager:GetInstance()
    if openPrepareManager then
        print("MOD: Patching UIOpenPrepareManager...")
        local orig_IsNeedPrepare = openPrepareManager.IsNeedPrepare
        openPrepareManager.IsNeedPrepare = function(self, ui_name, ...)
            if ui_name == UIWindowNames.UIChatMain then
                print("MOD: Intercepted UIOpenPrepareManager for UIChatMain.")
                UIManager:GetInstance():CreateWindow(UIWindowNames.UIChatMain)
                return true
            end
            return orig_IsNeedPrepare(self, ui_name, ...)
        end
    end

    -- 9. Patch Hero/Skin Actions
    local heroSkinManager = HeroSkinManager:GetInstance()
    if heroSkinManager then
        print("MOD: Patching HeroSkinManager...")
        heroSkinManager.WearSkin = function(self)
            print("MOD: Intercepted HeroSkinManager:WearSkin.")
            local fakeUpdateInfo = { heroInfo = { { heroId = self.heroId, equipedSkin = self.skinId } } }
            self:OnHeroInfoUpdate("MOD_WearSkin", fakeUpdateInfo)
            UIManager:GetInstance():Broadcast(UIMessageNames.UISHOP_BUYHEROSKIN_REFRESH)
        end
        heroSkinManager.EquipedAnim = function(self)
            print("MOD: Intercepted HeroSkinManager:EquipedAnim.")
            local fakeUpdateInfo = { heroInfo = { { heroId = self.heroId, equipedAnim = { [self.selectAnimType] = self.selectAnimId } } } }
            self:OnHeroInfoUpdate("MOD_EquipAnim", fakeUpdateInfo)
        end
    end

    -- 10. Patch General Purchase Logic
    local purchaseManager = PurchaseManager:GetInstance()
    if purchaseManager then
        print("MOD: Patching PurchaseManager...")
        local function simulatePurchase(self, itemId, cb)
            print("MOD: Intercepted Purchase for item: " .. itemId)
            local itemData = DataCacheManager:GetInstance().items[itemId]
            if not itemData then return end

            local fakeRecvJson = { code = 0 }
            if itemData.type == 1 or itemData.type == 2 then -- Hero or Skin
                fakeRecvJson.heroSkinInfo = { { heroSkinId = itemId, isUnlock = true, isPublish = true } }
            elseif itemData.type == DataConfig.ItemDataType.Expression then -- Emoji
                fakeRecvJson.emojiInfo = { { emojiId = itemId } }
            elseif itemData.type == DataConfig.ItemDataType.Ornaments then -- Ornaments
                fakeRecvJson.ornamentsInfo = { { oid = itemId, heroId = 0 } }
            end
            if cb then cb("MOD_BuyItem", fakeRecvJson) end
        end
        purchaseManager.BuyItem = function(self, itemId, currencyId, itemCount, cb) simulatePurchase(self, itemId, cb) end
        purchaseManager.BuyItems = function(self, items, cb) 
            for _, item in ipairs(items) do simulatePurchase(self, item.itemId, nil) end
            if cb then cb() end
        end
    end
    
    -- 11. Patch Mail System
    local mailManager = MailManager:GetInstance()
    if mailManager then
        print("MOD: Patching MailManager...")
        local fakeSuccess = function(cb) if cb then cb("MOD_Mail", {code=0}) end end
        mailManager.ReadMail = function(self, index) self.selectMail = table.sequencevaluebyindex(self.mailData, index); self.selectIndex = index; __ReadMail(self, self.selectMail); __MailCallback(self, self.MailBehavior.OnMailUpdate, self.selectIndex) end
        mailManager.DeleteMail = function(self) if self.selectMail then __DeleteMail(self, {self.selectMail.mailId}) end end
        mailManager.ReciveMailAttachment = function(self) if self.selectMail and self.selectMail.buttonConfig and self.selectMail.buttonConfig.type == DataCacheManager:GetInstance().hyperlink_type.Item and self.selectMail.isReceived ~= true then __ReceivedMail(self, self.selectMail); __MailCallback(self, self.MailBehavior.OnMailUpdate, self.selectIndex) end end
        mailManager.ReciveAllMailAttachment = function(self) table.sequenceforeach(self.mailData, function(index, mailId, mail) if mail.isReceived ~= true then __ReceivedMail(self, mail) end end); __MailCallback(self, self.MailBehavior.OnMailUpdate, self.selectIndex) end
    end
    
    -- 12. Patch User Info Editing
    if UIEditNameCtrl then
        print("MOD: Patching UIEditNameCtrl...")
        UIEditNameCtrl.SendEditName = function(self, userName)
            if not userName or string.len(userName) < 1 then return end
            local fakeUpdate = { userInfo = { userName = userName, changeNameTimes = (UserData:GetInstance().userInfo.changeNameTimes or 0) + 1 } }
            UserData:GetInstance():OnUserInfoUpdate(fakeUpdate)
            KTPlayManager:GetInstance():UpdateUserInfo("UserName", userName)
            UIManager:GetInstance():Toast(LuaUtils:TranslateString("修改成功"))
            UIManager:GetInstance():CloseWindow(UIWindowNames.UIEditName)
        end
    end

    -- 13. Patch GameMain for Auto-Saving
    if GameMain then
        print("MOD: Patching GameMain:OnApplicationQuit for auto-saving...")
        local orig_OnApplicationQuit = GameMain.OnApplicationQuit
        GameMain.OnApplicationQuit = function()
            print("MOD: Intercepted GameMain:OnApplicationQuit. Saving game state...")
            
            local userData = UserData:GetInstance()
            if userData then
                local strJson = LuaUtils:TableToJson(userData)
                CS.UnityEngine.PlayerPrefs.SetString("UserLoginData", strJson)
                CS.UnityEngine.PlayerPrefs.Save()
                print("MOD: Game state saved successfully!")
            else
                print("MOD ERROR: Could not get UserData instance to save.")
            end

            if orig_OnApplicationQuit then
                orig_OnApplicationQuit()
            end
        end
        print("MOD: GameMain:OnApplicationQuit has been patched.")
    end

    -- 14. Patch AR Button Visibility
    Patch_EnableAR()
end

-- Main execution coroutine
function ExecuteCoroutine()
    print("MOD: Starting clean transition with Save/Load logic...")
    local uiManager = UIManager:GetInstance()
    if not uiManager then print("MOD ERROR: UIManager not found."); return end
    
    uiManager:CloseTip()
    local singleDeskTop = uiManager:GetWindow(UIWindowNames.UISingleDeskTop, true)
    if singleDeskTop then
        print("MOD: Destroying UISingleDeskTop...")
        uiManager:DestroyWindow(UIWindowNames.UISingleDeskTop)
    end
    coroutine.waitforframes(2)
    
    -- Core modification: Load/Create save logic
    local loginData = nil
    local savedDataJson = CS.UnityEngine.PlayerPrefs.GetString("UserLoginData", "0")

    if savedDataJson ~= "0" and savedDataJson ~= "" then
        print("MOD: Found saved data. Loading from PlayerPrefs...")
        loginData = LuaUtils:JsonToTable(savedDataJson)
    else
        print("MOD: No saved data found. Creating a new 'God Mode' save file...")
        loginData = CreateFakeLoginData()
    end

    if not loginData then print("MOD ERROR: Failed to load or create login data."); return end

    local loginManager = LoginManager:GetInstance()
    if loginManager and loginData.battleServers and #loginData.battleServers > 0 then
        loginManager.selectServer = loginData.battleServers[1]
        print("MOD: Manually set LoginManager.selectServer.")
    end

    local userDataManager = UserData:GetInstance()
    print("MOD: Calling UserData:initLoginData()...")
    userDataManager:initLoginData(loginData, false, false) -- isSave is false to prevent re-saving during init
    
    userDataManager.isSingleMode = false
    print("MOD: Manually set isSingleMode to false.")
    
    -- *** 补丁 (关键): 修复快速匹配 ***
    if loginManager then
        loginManager.isLogin = true
        print("MOD: Manually set LoginManager.isLogin to true.")
    end

    coroutine.waitforframes(1)
    PatchGameLogic() -- Must apply patches every time
    
    AnnouncementManager:GetInstance():Request(function(success)
        if success then print("MOD: AnnouncementManager initialized successfully.") end
    end)
    print("MOD: Simulation complete. If successful, you are now in the main lobby.")
end

-- Start the coroutine
coroutine.start(ExecuteCoroutine)