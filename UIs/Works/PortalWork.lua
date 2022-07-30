local PortalWork = {}
PortalWork.__index = PortalWork

function CreatePortalWork(targetName, message, portal, parent, workList)
	local info = {
		targetName = targetName,
		sellingPortal = portal
	}
	local work = {}
	setmetatable(work, PortalWork)
	work.isAutoInvite = true
	work.info = info
	work:SetState('INITIALIZED')

	local frame = CreateFrame('Frame', 'WorkWorkPortalWork'..targetName..portal.name, parent, BackdropTemplateMixin and 'BackdropTemplate' or nil)
	frame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
	frame:RegisterEvent('CHAT_MSG_SYSTEM')
	frame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	frame:SetSize(WORK_WIDTH, WORK_HEIGHT)
	frame:SetBackdrop(BACKDROP_DIALOG_32_32)
	frame:SetPoint('TOPLEFT', workList.frame, 'TOPRIGHT', -11, 0)
	frame:Hide()
	work.frame = frame

    local header = frame:CreateTexture('$parentHeader', 'OVERLAY')
    header:SetPoint('TOP', 0, 12)
    header:SetTexture(131080) -- 'Interface\\DialogFrame\\UI-DialogBox-Header'
    header:SetSize(290, 64)

    local headerText = frame:CreateFontString('$parentHeaderText', 'OVERLAY', 'GameFontNormal')
    headerText:SetPoint('TOP', header, 0, -14)
    headerText:SetText('Portal')

	local divider = frame:CreateTexture(nil, 'OVERLAY')
	divider:SetPoint('TOP', 0, -139)
	divider:SetPoint('LEFT', 10, 0)
	divider:SetPoint('RIGHT', 52, 0)
    divider:SetTexture('Interface\\DialogFrame\\UI-DialogBox-Divider')
	work.divider = divider

	local background = frame:CreateTexture(nil, 'ARTWORK')
    background:SetPoint('TOPLEFT', 11, -11)
    background:SetWidth(257)
    background:SetHeight(138)
    background:SetTexture('Interface\\PaperDollInfoFrame\\UI-Character-Reputation-DetailBackground')

	local portrait = CreateFrame('Button', nil, frame, 'ActionButtonTemplate')
	portrait:SetHeight(40)
	portrait:SetWidth(40)
	portrait:SetPoint('TOPLEFT', 32, -36)
	portrait:SetEnabled(false)

	local texture = GetSpellTexture(portal.portalSpellID)
	getglobal(frame:GetName() .. "Icon"):SetTexture(texture)

	local targetNameText = frame:CreateFontString()
	targetNameText:SetFontObject('GameFontNormal')
	targetNameText:ClearAllPoints()
	targetNameText:SetPoint('LEFT', portrait, 'RIGHT', 10, 8)
	targetNameText:SetText(targetName)

	local toText = frame:CreateFontString()
	toText:SetFontObject('GameFontNormal')
	toText:SetTextColor(0.7, 0.7, 0.7)
	toText:SetText('port to')
	toText:ClearAllPoints()
	toText:SetPoint('TOPLEFT', targetNameText, 'BOTTOMLEFT', 0, -8)

	local portalText = frame:CreateFontString()
	portalText:SetFontObject('GameFontNormal')
	portalText:SetTextColor(1, 1, 1)
	portalText:ClearAllPoints()
	portalText:SetPoint('TOPLEFT', toText, 'TOPRIGHT', 4, 0)
	portalText:SetText(portal.name)

	local messageText = frame:CreateFontString()
	messageText:SetFontObject('GameFontNormalSmall')
	messageText:SetTextColor(0.75, 0.75, 0.75)
	messageText:ClearAllPoints()
	messageText:SetPoint('TOP', portrait, 'BOTTOM', 0, -8)
	messageText:SetPoint('LEFT', 20, 0)
	messageText:SetPoint('RIGHT', -20, 0)
	messageText:SetText('"'..message..'"')

	local endButton = CreateFrame('Button', nil, frame, 'GameMenuButtonTemplate')
	endButton:SetSize(64, 24)
	endButton:ClearAllPoints()
	endButton:SetPoint('TOP', frame, 'TOP', 0, -110)
	endButton:SetText('End')
	endButton:SetScript('OnClick', function(self)
		work:Complete()
	end)
	work.endButton = endButton

	local taskLists = CreateFrame('Frame', nil, frame, 'InsetFrameTemplate')
	taskLists:SetPoint('TOPLEFT', 10, -150)
	taskLists:SetPoint('BOTTOMRIGHT', -10, 10)

	-- Create tasks
	work.contactTask = CreateWorkTask(frame, 'Contact', '|c60808080Invite |r|cffffd100'..info.targetName..'|r|c60808080 into the party|r')
	work.contactTask:SetScript('OnClick', function(self)
		work:SetState('WAITING_FOR_INVITE_RESPONSE')
	end)
	work.contactTask:SetPoint('TOP', divider, 'BOTTOM', 0, 16)

	work.moveTask = CreateWorkTask(frame, 'Move', '|c60808080Waiting for contact|r', work.contactTask)
	work.moveTask:HookScript('OnClick', function(self)
		work:SetState('CREATING_PORTAL')
	end)

	work.makeTask = CreateWorkTask(frame, 'Make', '|c60808080Create a |r|cffffd100'..info.sellingPortal.name..'|r|c60808080 portal|r', work.moveTask)
	work.makeTask:SetSpell(info.sellingPortal.portalSpellName)
	work.makeTask:HookScript('OnClick', function(self)
		work:SetState('CREATING_PORTAL')
	end)

	work.finishTask = CreateWorkTask(frame, 'Finish', '|c60808080Waiting for |r|cffffd100'..info.targetName..'|r|c60808080 to enter the portal|r', work.makeTask)

	work.moveTask:Disable()
	work.makeTask:Disable()
	work.finishTask:Disable(true)
	work.contactTask:Enable()

    frame:SetScript('OnEvent', function(self, event, ...)
        work[event](work, ...)
    end)

	return work
end

function DetectPortalWork(playerName, guid, message, parent, workList)
	-- if playerName == UnitName('player') then
    --     return nil
    -- end

    -- local _, playerClass = GetPlayerInfoByGUID(guid)
    -- if playerClass == 'MAGE' then
    --     return nil
    -- end

	local message = string.lower(message)
	if message:match('wts') then
		return
	end

    if message:match('port') == nil and message:match('portal') == nil then
		return nil
	end


	for _, portal in ipairs(WorkWork.portals) do
		for _, keyword in ipairs(portal.keywords) do
			if message:match('to '..keyword)
				or message:match('> '..keyword)
				or message:match('port '..keyword)
				or message:match(keyword..' port') then
				if not IsSpellKnown(portal.portalSpellID) then
					return nil
				end
				return CreatePortalWork(playerName, message, portal, parent, workList)
			end
		end
	end
    return nil
end

function PortalWork:Start()
	PlaySound(5274)
	FlashClientIcon()
	if self.isAutoInvite then
		self.contactTask:Run()
	end
end

function PortalWork:Hide()
	self.frame:Hide()
end

function PortalWork:Show()
	self.frame:Show()
end

function PortalWork:Complete()
	if UnitIsGroupLeader('player') then
		UninviteUnit(self.info.targetName)
	else
		LeaveParty()
	end

	self.info = nil
	self:SetState('ENDED')
	self.frame:Hide()

	if self.onComplete then
		self.onComplete()
	end
end

function PortalWork:SetState(state)
	self.state = state
	if self.onStateChange then
		self.onStateChange()
	end

	local work = self

	if state == 'WAITING_FOR_INVITE_RESPONSE' then
		InviteUnit(self.info.targetName)
		return
	end

	if state == 'INVITED_TARGET' then
		SendPartyMessage('Hi, I\'m coming!!')
		self.contactTask:Complete()
		C_Timer.After(1, function() work:DetectTargetZone() end)
		return
	end

	if state == 'MOVING_TO_TARGET_ZONE' then
		return
	end

	if state == 'MOVED_TO_TARGET_ZONE' then
		self.moveTask:Complete()
		self.makeTask:Enable()
		return
	end

	if state == 'CREATING_PORTAL' then
		return
	end

	if state == 'WAITING_FOR_TARGET_ENTER_PORTAL' then
		self.makeTask:Complete()
		self.finishTask:Enable()
		self:WaitingForTargetEnterPortal()
		return
	end
end

function PortalWork:GetState()
	return self.state
end

function PortalWork:GetStateText()
	local state = self.state
	if state == 'WAITING_FOR_INVITE_RESPONSE' then
		return 'Contacting'
	end

	if state == 'INVITED_TARGET' then
		return 'Contacted'
	end

	if state == 'MOVING_TO_TARGET_ZONE' then
		return 'Moving'
	end

	if state == 'MOVED_TO_TARGET_ZONE' then
		return 'Moved'
	end

	if state == 'CREATING_PORTAL' then
		return 'Making'
	end

	if state == 'WAITING_FOR_TARGET_ENTER_PORTAL' then
		return 'Finishing'
	end

	return ''
end

function PortalWork:GetPriorityLevel()
	if self.state == 'WAITING_FOR_INVITE_RESPONSE'
	 	or self.state == 'WAITING_FOR_TARGET_ENTER_PORTAL' then
		return 'low'
	end

	if self.state == 'INVITED_TARGET'
	 	or self.state == 'MOVING_TO_TARGET_ZONE' then
		return 'medium'
	end

	if self.state == 'MOVED_TO_TARGET_ZONE'
	 	or self.state == 'CREATING_PORTAL' then
		return 'high'
	end

	return 'low'
end

function PortalWork:SendWho(command)
	C_FriendList.SetWhoToUi(true)
	FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE")
	C_FriendList.SendWho(command);
end

function PortalWork:FindPortal(zoneName)
	for _, portal in ipairs(WorkWork.portals) do
		if portal.zoneName == zoneName then
			return portal
		end
	end
	return nil
end

function PortalWork:DetectTargetZone()
	local work = self
	local targetZone = GetPartyMemberZone(self.info.targetName)
	if targetZone == nil then
		C_Timer.After(1, function() work:DetectTargetZone() end)
		return
	end

	local playerZone = GetRealZoneText()
	local work = self

	if playerZone == targetZone then
		self:SetState('MOVED_TO_TARGET_ZONE')
		return
	end

	local portal = self:FindPortal(targetZone)
	if portal == nil then
		self:SetState('MOVING_TO_TARGET_ZONE')
		self.moveTask:SetDescription('|c60808080Move to |r|cffffd100'..targetZone..'|r|c60808080 manually|r')
		self.moveTask:Enable()
		return
	end

	self.info.movingPortal = portal
	self.moveTask:SetSpell(portal.teleportSpellName)
	self.moveTask:HookScript('OnClick', function()
		work:SetState('MOVING_TO_TARGET_ZONE')
	end)
	self.moveTask:SetDescription('|c60808080Teleport to |r|cffffd100'..portal.name..'|r')
	self.moveTask:Enable()
end

function PortalWork:WaitingForTargetEnterPortal()
	if self.info == nil then
		return
	end

	local targetZone = GetPartyMemberZone(self.info.targetName)
	if targetZone ~= self.info.sellingPortal.zoneName then
		local work = self
		C_Timer.After(1, function() work:WaitingForTargetEnterPortal() end)
		return
	end
	self.endButton:Click()
end

function PortalWork:SetScript(event, script)
	if event == 'OnStateChange' then
		self.onStateChange = script
		return
	end

	if event == 'OnComplete' then
		self.onComplete = script
		return
	end
end

-- EVENTS
function PortalWork:UNIT_SPELLCAST_SUCCEEDED(target, castGUID, spellID)
	if self.state == 'CREATING_PORTAL'
		and spellID == self.info.sellingPortal.portalSpellID then
		self:SetState('WAITING_FOR_TARGET_ENTER_PORTAL')
		return
	end

	if self.state == 'MOVING_TO_TARGET_ZONE'
		and spellID == self.info.movingPortal.teleportSpellID then
		self:SetState('MOVED_TO_TARGET_ZONE')
		return
	end
end

function PortalWork:CHAT_MSG_SYSTEM(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
	local work = self
	if self.state == 'WAITING_FOR_INVITE_RESPONSE' then
		if text == self.info.targetName..' is already in a group.' then
			Whisper(self.info.targetName, "Hey, please invite me for a portal to "..self.info.sellingPortal.name)
			self.contactTask:SetDescription('|c60808080Waiting for |r|cffffd100'..self.info.targetName..'|r|c60808080 invites you into the party|r')
			WorkWorkAutoAcceptInvite:SetEnabled(true, function ()
				work:SetState('INVITED_TARGET')
			end)
			return
		end

		if text == self.info.targetName..' joins the party.' then
			work:SetState('INVITED_TARGET')
			return
		end
		return
	end


	if self.state == 'WAITING_FOR_TARGET_ENTER_PORTAL' then
		if text == 'Your group has been disbanded.' then
			self.endButton:Click()
			return
		end
	end
end

function PortalWork:ZONE_CHANGED_NEW_AREA()
	if self.state == 'MOVING_TO_TARGET_ZONE' then
		local playerZone = GetRealZoneText()
		local targetZone = GetPartyMemberZone(self.info.targetName)

		if playerZone == targetZone then
			self:SetState('MOVED_TO_TARGET_ZONE')
		end
	end
end
