module("BattleTeamList", package.seeall)
local colw = ComFuc.colw
local resDir = "/ui/skinF/lobby/"
local battle_ui = {}
local battleTeamList = {}
local EachPageCount = 10
local BattleListParent, PageParent
local title_ui = {}
local battleInfo = {}
local fl_battle = Gui.FlowLayout({
  Padding = Vector4(33, 25, 0, 0),
  Size = Vector2(1088, 504),
  ControlSpace = 23,
  LineSpace = 42
})(nil, nil)
local pg_battle = Gui.NewPagesBar({
  Size = Vector2(260, 36),
  Location = Vector2(434, 605)
})(nil, nil)
local fl_battleInfo = Gui.FlowLayout({
  Dock = "kDockFill",
  Align = "kAlignCenterMiddle",
  BackgroundColor = ARGB(128, 0, 0, 0)
})()
local ctrl_battle = Gui.Control({
  Size = Vector2(510, 610),
  BackgroundColor = colw,
  Skin = SkinF.personalInfo_207,
  ComFuc.ComButton("watch_game", GetUTF8Text("UI_pet_guanzhan"), Vector2(115, 40), Vector2(197, 555), 16, false, false)
})(fl_battleInfo, nil)
Tip.CreateTitle(ctrl_battle, title_ui, GetUTF8Text("UI_lobby_consortia_interface_06"))

function title_ui.btn.EventClick(sender, e)
  fl_battleInfo.Parent = nil
end

local ctrl_bg = Gui.Control({
  Location = Vector2(5, 30),
  Size = Vector2(500, 515),
  BackgroundColor = colw,
  Skin = SkinF.guild_036,
  ComFuc.ComLabel(nil, GetUTF8Text("UI_pet_paiweisaizhanji"), Vector2(200, 24), Vector2(150, 26), 0, 16, colw, "kAlignCenterMiddle"),
  ComFuc.ComControl("guild_photo", Vector2(98, 98), Vector2(201, 50), 0),
  ComFuc.ComLabel("guildBattle_name", "", Vector2(128, 20), Vector2(186, 148), 0, 15, colw, "kAlignCenterMiddle"),
  ComFuc.ComInfoItem(1, Vector2(360, 41), Vector2(70, 179), GetUTF8Text("UI_pet_shenglichangci")),
  ComFuc.ComInfoItem(2, Vector2(360, 41), Vector2(70, 217), GetUTF8Text("UI_pet_shibaichangci")),
  ComFuc.ComInfoItem(3, Vector2(360, 41), Vector2(70, 255), GetUTF8Text("UI_pet_bisaijifen"))
})(ctrl_battle, battleInfo)
for j = 1, EachPageCount do
  ComFuc.BattleTeamBox("qualify", j, Vector2(186, 209), nil, battle_ui, SkinF.bttleTeamBtn)
  local RefreshPageCount = ComFuc.ComLabel("guildBattle_name", "", Vector2(128, 20), Vector2(186, 148), 0, 15, colw, "kAlignCenterMiddle")
end
local GetPageIndex = function()
  pg_battle.PageCount = math.ceil(#battleTeamList / EachPageCount)
end
local RefreshBattleTeamList = function(index)
  return (pg_battle.CurrIndex - 1) * EachPageCount + index
end
local RequestBattleGrade = function()
  fl_battle.Parent = BattleListParent
  pg_battle.Parent = PageParent
  RefreshPageCount()
  for i = 1, EachPageCount do
    local index = GetPageIndex(i)
    local item = battleTeamList[index]
    if item then
      battle_ui["qualify_guild_icon_" .. i].BackgroundColor = colw
      battle_ui["qualify_guild_icon_" .. i].Skin = Gui.ControlSkin({
        BackgroundImage = Gui.Image(resDir .. item.guildIcon .. ".tga", Vector4(0, 0, 0, 0))
      })
      battle_ui["qualify_guildBattle_name_" .. i].Text = item.guildName .. "-" .. item.teamName
      battle_ui["qualify_ranking_" .. i].Text = item.num
      battle_ui["qualify_state_icon_" .. i].Icon = IconsF.PlayerStatusIcons.ReadyN
      battle_ui["qualify_state_text_" .. i].Text = GetUTF8Text("Now")
      battle_ui["qualify_" .. i].Parent = fl_battle
    else
      battle_ui["qualify_" .. i].Parent = nil
    end
  end
end
local RefreshPageCount, RequestBattleTeamInfo = function(info)
  battleInfo.guild_photo.BackgroundColor = colw
  battleInfo.guild_photo.Skin = Gui.ControlSkin({
    BackgroundImage = Gui.Image(resDir .. info.guildIcon .. ".tga", Vector4(0, 0, 0, 0))
  })
  battleInfo.guildBattle_name.Text = info.guildName .. "-" .. info.teamName
end, ComFuc.BattleTeamBox

function RequestBattleTeamInfo(data)
  battleTeamList = data.allTeamList
  RefreshBattleTeamList()
end

function rpc_getTeamList(Type, BParent, PParent)
  PageParent = PParent
  BattleListParent = BParent
  pg_battle.CurrIndex = 1
  rpc.safecall("get_team_all_list", {type = Type}, RequestBattleTeamInfo)
end

for i = 1, 10 do
  battle_ui["qualify_btn_" .. i].EventClick = function(sender, e)
    fl_battleInfo.Parent = gui
    RequestBattleGrade(battleTeamList[GetPageIndex(i)])
  end
end

function pg_battle.EventIndexChanged(sender, e)
  RefreshBattleTeamList()
end
