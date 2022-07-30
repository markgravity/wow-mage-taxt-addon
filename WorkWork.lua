local AceEvent = LibStub('AceEvent-3.0')

WorkWork = CreateFrame('Frame', 'WorkWorkMainFrame', UIParent, BackdropTemplateMixin and 'BackdropTemplate' or nil)
WorkWorkAddon = LibStub('AceAddon-3.0'):NewAddon('WorkWork', 'AceConsole-3.0')

WORK_LIST_WIDTH = 200
WORK_LIST_HEIGHT = 400
WORK_WIDTH = 210
WORK_HEIGHT = 400

function WorkWorkAddon:OnInitialize()
	WorkWork:Init()
	MinimapButton:Init()
end

function WorkWork:Init()
	self:SetScript('OnEvent', function(self, event, ...)
        self[event](self, ...)
    end)
	self.isPaused = false
	self.isOn = false
	self:SetMovable(true)
	self:EnableMouse(true)
	self:SetUserPlaced(true)
	self:RegisterForDrag('LeftButton')
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", self.StopMovingOrSizing)
	self:SetSize(WORK_LIST_WIDTH + WORK_WIDTH - 11, WORK_HEIGHT)
	if not self:IsUserPlaced() then
		self:SetPoint('CENTER')
	end

	self.workList = CreateWorkList(self)
	self.workList:Hide()
	self.workList:TryAdd('Iina', nil, 'wtf port darn to if')

	self:On()
end

function WorkWork:On()
	self.isPaused = false
	self.isOn = true
    self:RegisterEvent('CHAT_MSG_SAY')
    self:RegisterEvent('CHAT_MSG_YELL')
    self:RegisterEvent('CHAT_MSG_WHISPER')
	self:RegisterEvent('CHAT_MSG_CHANNEL')
end

function WorkWork:Off()
	self.isOn = false
    self:UnregisterEvent('CHAT_MSG_SAY')
    self:UnregisterEvent('CHAT_MSG_YELL')
    self:UnregisterEvent('CHAT_MSG_WHISPER')
	self:UnregisterEvent('CHAT_MSG_CHANNEL')
end

function WorkWork:Toggle()
	self.isOn = not self.isOn
	if self.isOn then
		self:On()
	else
		self:Off()
	end
end

function WorkWork:Pause()
    self.isPaused = true
end

function WorkWork:Resume()
    self.isPaused = false
end

function WorkWork:CHAT_MSG_SAY(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    self:OnChat(playerName2, guid, text)
end

function WorkWork:CHAT_MSG_YELL(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    self:OnChat(playerName2, guid, text)
end

function WorkWork:CHAT_MSG_WHISPER(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    self:OnChat(playerName2, guid, text)
end

function WorkWork:CHAT_MSG_CHANNEL(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
	if zoneChannelID ~= 2 then
		return
	end
    self:OnChat(playerName2, guid, text)
end

function WorkWork:OnChat(playerName, guid, text)
	if self.isPaused then
		return
	end

	self.workList:TryAdd(playerName, guid, text)
end
