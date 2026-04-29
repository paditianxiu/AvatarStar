module("BattleTeamMemList", package.seeall)
local colw = ComFuc.colw
local memberDt = {}
local temDt = {}
local TeamList = {}
local raceTeamList = {}
local BattleModeType = 0
local menu_ui = {}
local MainParent
local ctrl_scr = Gui.Control({
  Location = Vector2(0, 32),
  Size = Vector2(400, 273),
  BackgroundColor = colw,
  Skin = SkinF.personalInfo_pet_005,
  ComFuc.ComMenu("menu_1")
})(nil, menu_ui)
local scr = Gui.ScrollableControl({Dock = "kDockFill"})(ctrl_scr, nil)
local fl_price = Gui.FlowLayout({
  LineSpace = 1,
  Padding = Vector4(7, 5, 0, 0),
  Align = "kAlignTopMiddle"
})(scr, nil)
local SelItem, table_clone = function(k)
  for i = 1, #TeamList do
    raceTeamList[i].member.PushDown = i == k
    if i == k then
      raceTeamList[i].level.TextColor = ComFuc.colt
      raceTeamList[i].name.TextColor = ComFuc.colt
    else
      raceTeamList[i].level.TextColor = colw
      raceTeamList[i].name.TextColor = colw
    end
  end
  if k and 0 < k then
    temDt = memberDt[k]
    menu_ui.menu_1:SetEnable(0, temDt.playerId ~= SelectCharacter.roleServerId and TeamList.headerId == SelectCharacter.roleServerId)
    menu_ui.menu_1:SetEnable(1, temDt.playerId ~= SelectCharacter.roleServerId)
    menu_ui.menu_1:SetEnable(2, temDt.playerId ~= SelectCharacter.roleServerId)
  end
end, function(k)
  for i = 1, #TeamList do
    raceTeamList[i].member.PushDown = i == k
    if i == k then
      raceTeamList[i].level.TextColor = ComFuc.colt
      raceTeamList[i].name.TextColor = ComFuc.colt
    else
      raceTeamList[i].level.TextColor = colw
      raceTeamList[i].name.TextColor = colw
    end
  end
  if k and 0 < k then
    temDt = memberDt[k]
    menu_ui.menu_1:SetEnable(0, temDt.playerId ~= SelectCharacter.roleServerId and TeamList.headerId == SelectCharacter.roleServerId)
    menu_ui.menu_1:SetEnable(1, temDt.playerId ~= SelectCharacter.roleServerId)
    menu_ui.menu_1:SetEnable(2, temDt.playerId ~= SelectCharacter.roleServerId)
  end
end
local table_clone, SetMenuItem = function(dst, src)
  for k, v in pairs(src) do
    dst[k] = v
  end
end, nil

function SetMenuItem()
  menu_ui.menu_1:RemoveAll()
  if BattleModeType == 1 then
    menu_ui.menu_1:AddItem(GetUTF8Text("UI_datalist_consortia_troop_33"))
  end
  menu_ui.menu_1:AddItem(GetUTF8Text("button_common_Add_Friends"))
  menu_ui.menu_1:AddItem(GetUTF8Text("button_common_Info"))
  menu_ui.menu_1:Close()
end

function DealBattleTeamMem(data, clear, modeType, mainParent, TeamMemId)
  TeamList = data.teamList[1]
  BattleModeType = modeType
  ctrl_scr.Parent = mainParent
  SetMenuItem()
  fl_price.Size = Vector2(519, #TeamList * 41 + (#TeamList - 1) * 1 + 5)
  if clear then
    Gui.Clear(fl_price)
  end
  local List = {}
  memberDt = {}
  local k = 2
  for j, v in ipairs(TeamList) do
    if TeamList.headerId == v.playerId then
      List[1] = v
    else
      List[k] = v
      k = k + 1
    end
  end
  for i, v in ipairs(List) do
    memberDt[i] = v
    if clear then
      if not raceTeamList[i] then
        local t = {}
        Gui.LcButton("member")({
          Size = Vector2(360, 41),
          BackgroundColor = colw,
          Skin = SkinF.guild_039,
          CanPushDown = true,
          Visible = true,
          ComFuc.ComControl(nil, Vector2(360, 41), Vector2(0, 0), 255, SkinF.guild_040, i == 1, false),
          ComFuc.ComControl("job", Vector2(30, 30), Vector2(30, 5), 255, SkinF.personalInfo_job[1]),
          ComFuc.ComControl("rank", Vector2(30, 30), Vector2(64, 5), 255, SkinF.rank_006[1][1]),
          ComFuc.ComLabel("level", "", Vector2(210, 30), Vector2(98, 5), 0, 16, colw),
          ComFuc.ComLabel("name", "", Vector2(170, 30), Vector2(138, 5), 0, 16, colw),
          ComFuc.ComControl("vip", Vector2(30, 30), Vector2(312, 5), 255, SkinF.vipPadShow_009),
          EventClick = function(sender, e)
            SelItem(i)
          end,
          EventRightClick = function(sender, e)
            menu_ui.menu_1.Location = sender.CurrentCursorPosition
            menu_ui.menu_1:Open()
            SelItem(i)
          end
        })(nil, t)
        raceTeamList[i] = {}
        table_clone(raceTeamList[i], t)
      end
      raceTeamList[i].member.Parent = fl_price
    end
    if v then
      if TeamMemId then
        TeamMemId[i] = v.playerId
      end
      raceTeamList[i].job.Skin = SkinF.personalInfo_job[tonumber(v.occupation) + 1]
      raceTeamList[i].rank.Skin = SkinF.rank_006[v.rankType][v.rankLevel]
      raceTeamList[i].level.Text = "LV" .. v.level
      raceTeamList[i].name.Text = v.name
      if 1 <= tonumber(v.vipLevel) then
        raceTeamList[i].vip.Skin = SkinF.vipPadShow_004[tonumber(v.vipLevel) + 1]
      elseif tonumber(v.vipLevel) == -1 then
        raceTeamList[i].vip.Skin = SkinF.vipPadShow_009
      else
        raceTeamList[i].vip.Skin = SkinF.skin_touming
      end
    end
  end
end

function menu_ui.menu_1.EventClick(sender, e)
  local t = sender.SelectedIndex
  if t == 0 and BattleModeType == 1 then
    rpc.safecall("racing_kick_member", {
      playerId = temDt.playerId
    }, nil)
    rpc.safecall("racing_team_list", {
      headerId = SelectCharacter.roleServerId
    }, function(data)
      DealBattleTeamMem(data, true, 1, ctrl_scr.Parent)
    end)
  elseif t == 1 then
    Sociality.AddFriend(temDt.playerId, temDt.level)
  elseif t == 2 then
    LookInfo.Show(temDt.playerId)
  end
end
