module("VoteKick", package.seeall)
local colw = ComFuc.colw
local colt = ComFuc.colt
local uiS = Vector2(402, 565)
local selCurr = 0
local vote_type = 0
local character_table = {}
local report_reason = 0
escWindow = nil
local button1_key = {
  GetUTF8Text("UI_inGame_vote_08"),
  GetUTF8Text("button_inGame_report")
}
local vote_type_key = {
  GetUTF8Text("UI_inGame_toupiaotiren"),
  GetUTF8Text("button_inGame_report")
}
local report_reason_key = {
  GetUTF8Text("UI_inGame_jubao_waigua"),
  GetUTF8Text("UI_inGame_jubao_kabug")
}
local title_key, ComEscButton = {
  {
    GetUTF8Text("button_inGame_vote_04"),
    GetUTF8Text("UI_inGame_vote_09")
  },
  {
    GetUTF8Text("UI_social_jubao_wanjia"),
    GetUTF8Text("UI_social_jubao_liyou")
  }
}, {
  GetUTF8Text("button_inGame_vote_04"),
  GetUTF8Text("UI_inGame_vote_09")
}
local ComEscButton, ItemButton = function(i, text, size, lc, skin, fuc)
  return Gui.Button("btn_" .. i)({
    Size = size or Vector2(84, 40),
    Location = lc,
    Text = text,
    FontSize = 16,
    CanMove = true,
    Skin = skin,
    EventClick = function()
      escWindow.screen.Visible = false
      gui.Focused = true
      if fuc then
        fuc()
      end
      local state = ptr_cast(game.CurrentState, "Client.StateMainGame")
      if state then
        state.EscHasFocus = false
      end
    end
  })
end, {
  GetUTF8Text("UI_social_jubao_wanjia"),
  GetUTF8Text("UI_social_jubao_liyou")
}
local ItemButton, PlayerList = function(i)
  return Gui.Button("itemB_" .. i)({
    Style = "",
    Size = Vector2(320, 32),
    Location = Vector2(0, 32 * (i - 1)),
    BackgroundColor = colw,
    Skin = SkinF.newLead_002,
    Visible = false,
    CanPushDown = true,
    EventClick = function(sender, e)
      SelectOne(i)
    end,
    Gui.Control({
      Size = Vector2(772, 32),
      ComFuc.ComControl("rank_job_" .. i, Vector2(30, 29), Vector2(7, 1), 255),
      ComFuc.ComLabel("rank_level_" .. i, "", Vector2(60, 30), Vector2(43, 1), 0, 16, colw),
      ComFuc.ComLabel("rank_name_" .. i, "", Vector2(220, 33), Vector2(105, 1), 0, 16, colw)
    })
  })
end, GetUTF8Text("UI_social_jubao_wanjia")
local PlayerList, AddVoteReason = function()
  return Gui.Control({
    Size = Vector2(360, 212),
    Location = Vector2(7, 55),
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_068,
    Gui.ScrollableControl({
      Size = Vector2(345, 192),
      Location = Vector2(5, 10),
      HScrollBarDisplay = "kHide",
      VScrollBarDisplay = "kVisible",
      VScrollBarWidth = 22,
      AutoScroll = true,
      AutoSize = true,
      AutoScrollMinSize = Vector2(345, 192),
      Gui.Control("goos_Content")({
        Size = Vector2(345, 192),
        ItemButton(1),
        ItemButton(2),
        ItemButton(3),
        ItemButton(4),
        ItemButton(5),
        ItemButton(6),
        ItemButton(7),
        ItemButton(8),
        ItemButton(9),
        ItemButton(10),
        ItemButton(11),
        ItemButton(12),
        ItemButton(13),
        ItemButton(14),
        ItemButton(15)
      })
    })
  })
end, GetUTF8Text("UI_social_jubao_liyou")
local AddVoteReason, Report = function()
  return Gui.Control("reason")({
    Size = Vector2(360, 30),
    Location = Vector2(7, 55),
    ComFuc.ComCheckBox("reason_1", report_reason_key[1], Vector2(100, 24), Vector2(0, 4), 16, ComFuc.colt, "Gui.CheckBox_01"),
    ComFuc.ComCheckBox("reason_2", report_reason_key[2], Vector2(100, 24), Vector2(100, 4), 16, ComFuc.colt, "Gui.CheckBox_01")
  })
end, GetUTF8Text("UI_social_jubao_liyou")

function Report()
  if vote_type == 1 then
    game:VoteKickByCid(selCurr - 1, ui.kickReason.Text)
  elseif vote_type == 2 then
    local report_cd = game:GetPlayerReportCD()
    if 0 < report_cd then
      MessageBox.ShowError(GetMatchedUTF8Text("msgbox_common_jubao_guoyupinfan," .. 15))
    else
      game:ResetReportCD()
      rpc.safecall("player_report", {
        reporterId = 0,
        targetId = character_table[selCurr].character_id,
        content = ui.kickReason.Text,
        type = report_reason
      })
    end
  end
end

ui = Gui.Create()({
  Gui.Control("main")({
    Size = uiS,
    BackgroundColor = colw,
    Skin = SkinF.personalInfo_207,
    ComFuc.ComLabel(nil, GetUTF8Text("button_inGame_tirenhejubao"), Vector2(uiS.x - 40, 30), Vector2(10, 0), 0, 16, colw),
    ComEscButton(0, nil, Vector2(24, 24), Vector2(uiS.x - 33, 4), SkinF.lookInfo_002),
    ComEscButton(1, button1_key[1], nil, Vector2(92, uiS.y - 60), nil, Report),
    ComEscButton(2, GetUTF8Text("button_common_Cancel"), nil, Vector2(226, uiS.y - 60)),
    ComFuc.MainTabBtn("vote_type_1", vote_type_key[1], Vector2(21, 42), Vector2(129, 31), SkinF.level_master_btn, true),
    ComFuc.MainTabBtn("vote_type_2", vote_type_key[2], Vector2(150, 42), Vector2(129, 31), SkinF.level_master_btn, true),
    Gui.Control("info")({
      Location = Vector2(8, 72),
      Size = Vector2(384, 424),
      BackgroundColor = colw,
      Skin = SkinF.setting_03,
      ComFuc.ComLabel("title_1", title_key[1][1], Vector2(360, 44), Vector2(12, 10), 0, 16, colt, "kAlignLeftMiddle"),
      PlayerList(),
      ComFuc.ComControl("color", Vector2(360, 44), Vector2(12, 272), 255, SkinF.activity_line, false, true, ComFuc.coly),
      ComFuc.ComLabel("title_2", title_key[1][2], Vector2(360, 25), Vector2(12, 272), 0, 16, colt, "kAlignLeftMiddle"),
      AddVoteReason(),
      ComFuc.ComTextArea("kickReason", Vector2(360, 84), Vector2(12, 318), 16, colw, 50)
    })
  })
})
ui.title_1.AutoWrap = true
ui.title_2.AutoWrap = true
ui.kickReason.Location = Vector2(12, ui.info.Size.y - 95)
ui.color.Location = ui.title_2.Location
ui.color.Size = ui.title_2.Size
local ui.reason.Location, LoadCharaters = Vector2(ui.title_2.Location.x, ui.title_2.Location.y + 25), ui.reason

function LoadCharaters()
  local k = 0
  character_table = {}
  if vote_type == 1 then
    k = game:GetTabTeamSizeByIndex(0)
  elseif vote_type == 2 then
    k = game:GetAllTeamSize()
  end
  for i = 1, k do
    ui["rank_job_" .. i].Skin = SkinF.personalInfo_job[game:GetTabCareerByIndex(i - 1) + 1]
    ui["rank_level_" .. i].Text = GetUTF8Text("UI_inGame_additional_string_129") .. game:GetTabLevelByIndex(i - 1)
    ui["rank_name_" .. i].Text = game:GetTabNameByIndex(i - 1)
    ui["itemB_" .. i].Visible = true
    character_table[i] = {}
    character_table[i].character_id = game:GetTabCharacterId(i - 1)
  end
  for i = k + 1, 15 do
    ui["itemB_" .. i].Visible = false
  end
  ui.goos_Content.Size = Vector2(345, math.max(192, k * 32))
  ui.btn_1.Enable = 0 < k
  report_reason = 0
end

local SelectOne, SelectVoteType = function(k)
  for i = 1, 15 do
    ui["itemB_" .. i].PushDown = i == k
    if i == k then
      ui["rank_level_" .. i].TextColor = colt
      ui["rank_name_" .. i].TextColor = colt
    else
      ui["rank_level_" .. i].TextColor = colw
      ui["rank_name_" .. i].TextColor = colw
    end
  end
  selCurr = k
end, function(k)
  for i = 1, 15 do
    ui["itemB_" .. i].PushDown = i == k
    if i == k then
      ui["rank_level_" .. i].TextColor = colt
      ui["rank_name_" .. i].TextColor = colt
    else
      ui["rank_level_" .. i].TextColor = colw
      ui["rank_name_" .. i].TextColor = colw
    end
  end
  selCurr = k
end

function SelectVoteType(type)
  if vote_type == type or type < 0 or 2 < type then
    return
  end
  vote_type = type
  for i = 1, 2 do
    ui["vote_type_" .. i].PushDown = i == type
  end
  if vote_type == 1 then
    ui.title_2.Location = ui.reason.Location
    ui.reason.Visible = false
    for i = 1, 2 do
      ui["reason_" .. i].Check = false
    end
  elseif vote_type == 2 then
    ui.title_2.Location = Vector2(12, 272)
    ui.reason.Visible = true
  end
  ui.color.Location = ui.title_2.Location
  ui.btn_1.Text = button1_key[vote_type]
  ui.title_1.Text = title_key[vote_type][1]
  ui.title_2.Text = title_key[vote_type][2]
  LoadCharaters()
  SelectOne(1)
end

for i = 1, 2 do
  ui["vote_type_" .. i].EventClick = function(sender, e)
    SelectVoteType(i)
  end
end
for i = 1, 2 do
  ui["reason_" .. i].EventCheckChanged = function(sender, e)
    if not ui["reason_" .. i].Check then
      return
    end
    if i == 1 then
      report_reason = 1
    else
      report_reason = 0
    end
    for j = 1, 2 do
      if j ~= i then
        ui["reason_" .. j].Check = false
      end
    end
  end
end

function InitEscMenu()
  escWindow = ModalWindow.GetNew("transparent")
  escWindow.screen.AllowEscToExit = false
  escWindow.screen.Visible = false
  
  function escWindow.screen.EventEscPressed()
    escWindow.screen.Visible = false
    gui.Focused = true
    local state = ptr_cast(game.CurrentState, "Client.StateMainGame")
    if state then
      state.EscHasFocus = false
    end
  end
  
  gui.Focused = true
  escWindow.root.Size = uiS
  ui.main.Parent = escWindow.root
  ui.kickReason.Text = ""
  SelectVoteType(1)
end

function SwitchEscMenu()
  if escWindow and escWindow.screen then
    escWindow.screen.Visible = not escWindow.screen.Visible
    if escWindow.screen.Visible then
      escWindow.root.Focused = true
    else
      gui.Focused = true
    end
  end
end
