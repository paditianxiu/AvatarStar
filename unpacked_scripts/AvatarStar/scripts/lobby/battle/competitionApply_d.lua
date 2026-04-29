module("CompetitionApply", package.seeall)
require("BattleTeamMemList.lua")
local colw = ComFuc.colw
local colt = ComFuc.colt
local resDir = "/ui/skinF/lobby/"
local FRIEND_TYPE = 2
local MYFRIEND_GROUP = 1
local OFFLINE = 1
local ONLINE = 2
local INGAMING = 3
local title_ui = {}
local CurrentAddPid, GuildId
local TeamMemId = {}
local AddedMemList = {}
local TeamList = {}
ui = Gui.Create()({
  Gui.FlowLayout("apply_fl")({
    Dock = "kDockFill",
    Align = "kAlignCenterMiddle",
    BackgroundColor = ARGB(128, 0, 0, 0),
    Gui.Control("area_main")({
      Size = Vector2(900, 600),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.personalInfo_207,
      ComFuc.ComLabel("apply_rule", GetUTF8Text("UI_pet_baomingxuzhi"), Vector2(100, 20), Vector2(30, 40), 0, 17, ARGB(255, 62, 26, 1), "kAlignLeftMiddle"),
      ComFuc.ComTextArea("apply_ruleContent", Vector2(450, 510), Vector2(20, 62), 16, colw, 3000),
      ComFuc.ComControl(nil, Vector2(110, 115), Vector2(475, 43), 255, SkinF.guild_019),
      ComFuc.ComControl("guild_photo", Vector2(98, 98), Vector2(478, 43), 0),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_pet_gonghuiming"), Vector2(100, 20), Vector2(595, 70), 0, 17, colt),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_pet_zhanduiming"), Vector2(100, 20), Vector2(595, 100), 0, 17, colt),
      ComFuc.ComLabel("guild_name", nil, Vector2(342, 20), Vector2(695, 70), 0, 17, colt),
      ComFuc.ComLabel("team_name", nil, Vector2(342, 20), Vector2(695, 100), 0, 17, colt),
      Gui.Control("addTeammate_main")({
        Size = Vector2(400, 400),
        Location = Vector2(480, 200),
        Gui.Button("btn_addTeammate")({
          Style = "ButtonApplyFriend",
          Size = Vector2(29, 29),
          Location = Vector2(350, 0)
        }),
        ComFuc.ComLabel("match_num", GetUTF8Text("UI_pet_tianjiacanshuduiyuan"), Vector2(342, 20), Vector2(15, 5), 0, 17, colt),
        ComFuc.ComButton("change_team", GetUTF8Text("change"), Vector2(114, 40), Vector2(150, 310), 16, false, false),
        ComFuc.ComButton("apply_btn", GetUTF8Text("UI_pet_baoming"), Vector2(114, 40), Vector2(280, 310), 16, false, false),
        Gui.Control("friend_list")({
          Location = Vector2(60, 0),
          Size = Vector2(288, 331),
          BackgroundColor = ARGB(255, 255, 255, 255),
          Skin = SkinF.personalInfo_131,
          Gui.Control({
            Location = Vector2(5, 5),
            Size = Vector2(278, 273),
            BackgroundColor = ARGB(255, 255, 255, 255),
            Skin = SkinF.personalInfo_068,
            Padding = Vector4(5, 6, 5, 6),
            Gui.ListTreeView("list")({
              Dock = "kDockFill",
              Style = "Sociality.FriendsList"
            })
          }),
          Gui.Button("btn_confirm")({
            Location = Vector2(100, 278),
            Size = Vector2(84, 43),
            Text = GetUTF8Text("UI_pet_tianjia"),
            FontSize = 16,
            CanMove = true,
            TextColor = crTextColor,
            DisabledTextColor = crDisabledTextColor,
            TextShadowWhenNormal = true,
            TextShadowColor = ARGB(150, 0, 0, 0)
          })
        })
      })
    })
  })
})
local friend_list, RequestTeamList = ui.friend_list, {
  Gui.FlowLayout("apply_fl")({
    Dock = "kDockFill",
    Align = "kAlignCenterMiddle",
    BackgroundColor = ARGB(128, 0, 0, 0),
    Gui.Control("area_main")({
      Size = Vector2(900, 600),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.personalInfo_207,
      ComFuc.ComLabel("apply_rule", GetUTF8Text("UI_pet_baomingxuzhi"), Vector2(100, 20), Vector2(30, 40), 0, 17, ARGB(255, 62, 26, 1), "kAlignLeftMiddle"),
      ComFuc.ComTextArea("apply_ruleContent", Vector2(450, 510), Vector2(20, 62), 16, colw, 3000),
      ComFuc.ComControl(nil, Vector2(110, 115), Vector2(475, 43), 255, SkinF.guild_019),
      ComFuc.ComControl("guild_photo", Vector2(98, 98), Vector2(478, 43), 0),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_pet_gonghuiming"), Vector2(100, 20), Vector2(595, 70), 0, 17, colt),
      ComFuc.ComLabel(nil, GetUTF8Text("UI_pet_zhanduiming"), Vector2(100, 20), Vector2(595, 100), 0, 17, colt),
      ComFuc.ComLabel("guild_name", nil, Vector2(342, 20), Vector2(695, 70), 0, 17, colt),
      ComFuc.ComLabel("team_name", nil, Vector2(342, 20), Vector2(695, 100), 0, 17, colt),
      Gui.Control("addTeammate_main")({
        Size = Vector2(400, 400),
        Location = Vector2(480, 200),
        Gui.Button("btn_addTeammate")({
          Style = "ButtonApplyFriend",
          Size = Vector2(29, 29),
          Location = Vector2(350, 0)
        }),
        ComFuc.ComLabel("match_num", GetUTF8Text("UI_pet_tianjiacanshuduiyuan"), Vector2(342, 20), Vector2(15, 5), 0, 17, colt),
        ComFuc.ComButton("change_team", GetUTF8Text("change"), Vector2(114, 40), Vector2(150, 310), 16, false, false),
        ComFuc.ComButton("apply_btn", GetUTF8Text("UI_pet_baoming"), Vector2(114, 40), Vector2(280, 310), 16, false, false),
        Gui.Control("friend_list")({
          Location = Vector2(60, 0),
          Size = Vector2(288, 331),
          BackgroundColor = ARGB(255, 255, 255, 255),
          Skin = SkinF.personalInfo_131,
          Gui.Control({
            Location = Vector2(5, 5),
            Size = Vector2(278, 273),
            BackgroundColor = ARGB(255, 255, 255, 255),
            Skin = SkinF.personalInfo_068,
            Padding = Vector4(5, 6, 5, 6),
            Gui.ListTreeView("list")({
              Dock = "kDockFill",
              Style = "Sociality.FriendsList"
            })
          }),
          Gui.Button("btn_confirm")({
            Location = Vector2(100, 278),
            Size = Vector2(84, 43),
            Text = GetUTF8Text("UI_pet_tianjia"),
            FontSize = 16,
            CanMove = true,
            TextColor = crTextColor,
            DisabledTextColor = crDisabledTextColor,
            TextShadowWhenNormal = true,
            TextShadowColor = ARGB(150, 0, 0, 0)
          })
        })
      })
    })
  })
}
local RequestTeamList, HideFriendList = function(clear)
  rpc.safecall("racing_team_list", {
    headerId = SelectCharacter.roleServerId
  }, function(data)
    TeamList = data.teamList[1]
    ui.match_num.Text = GetMatchedUTF8Text("UI_pet_tianjiacanshuduiyuan" .. "," .. #TeamList)
    BattleTeamMemList.DealBattleTeamMem(data, clear, 1, ui.addTeammate_main, TeamMemId)
  end)
end, Gui.FlowLayout("apply_fl")({
  Dock = "kDockFill",
  Align = "kAlignCenterMiddle",
  BackgroundColor = ARGB(128, 0, 0, 0),
  Gui.Control("area_main")({
    Size = Vector2(900, 600),
    BackgroundColor = ARGB(255, 255, 255, 255),
    Skin = SkinF.personalInfo_207,
    ComFuc.ComLabel("apply_rule", GetUTF8Text("UI_pet_baomingxuzhi"), Vector2(100, 20), Vector2(30, 40), 0, 17, ARGB(255, 62, 26, 1), "kAlignLeftMiddle"),
    ComFuc.ComTextArea("apply_ruleContent", Vector2(450, 510), Vector2(20, 62), 16, colw, 3000),
    ComFuc.ComControl(nil, Vector2(110, 115), Vector2(475, 43), 255, SkinF.guild_019),
    ComFuc.ComControl("guild_photo", Vector2(98, 98), Vector2(478, 43), 0),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_pet_gonghuiming"), Vector2(100, 20), Vector2(595, 70), 0, 17, colt),
    ComFuc.ComLabel(nil, GetUTF8Text("UI_pet_zhanduiming"), Vector2(100, 20), Vector2(595, 100), 0, 17, colt),
    ComFuc.ComLabel("guild_name", nil, Vector2(342, 20), Vector2(695, 70), 0, 17, colt),
    ComFuc.ComLabel("team_name", nil, Vector2(342, 20), Vector2(695, 100), 0, 17, colt),
    Gui.Control("addTeammate_main")({
      Size = Vector2(400, 400),
      Location = Vector2(480, 200),
      Gui.Button("btn_addTeammate")({
        Style = "ButtonApplyFriend",
        Size = Vector2(29, 29),
        Location = Vector2(350, 0)
      }),
      ComFuc.ComLabel("match_num", GetUTF8Text("UI_pet_tianjiacanshuduiyuan"), Vector2(342, 20), Vector2(15, 5), 0, 17, colt),
      ComFuc.ComButton("change_team", GetUTF8Text("change"), Vector2(114, 40), Vector2(150, 310), 16, false, false),
      ComFuc.ComButton("apply_btn", GetUTF8Text("UI_pet_baoming"), Vector2(114, 40), Vector2(280, 310), 16, false, false),
      Gui.Control("friend_list")({
        Location = Vector2(60, 0),
        Size = Vector2(288, 331),
        BackgroundColor = ARGB(255, 255, 255, 255),
        Skin = SkinF.personalInfo_131,
        Gui.Control({
          Location = Vector2(5, 5),
          Size = Vector2(278, 273),
          BackgroundColor = ARGB(255, 255, 255, 255),
          Skin = SkinF.personalInfo_068,
          Padding = Vector4(5, 6, 5, 6),
          Gui.ListTreeView("list")({
            Dock = "kDockFill",
            Style = "Sociality.FriendsList"
          })
        }),
        Gui.Button("btn_confirm")({
          Location = Vector2(100, 278),
          Size = Vector2(84, 43),
          Text = GetUTF8Text("UI_pet_tianjia"),
          FontSize = 16,
          CanMove = true,
          TextColor = crTextColor,
          DisabledTextColor = crDisabledTextColor,
          TextShadowWhenNormal = true,
          TextShadowColor = ARGB(150, 0, 0, 0)
        })
      })
    })
  })
})

function HideFriendList()
  friend_list.Parent = nil
end

function DealApplyLogic(data)
  CommonUtility.InitLtvHeader(ui.list, {
    {
      "",
      32,
      "kAlignLeftMiddle"
    },
    {
      "",
      150,
      "kAlignLeftMiddle"
    },
    {
      "",
      60,
      "kAlignLeftMiddle"
    },
    {
      "",
      1,
      "kAlignLeftMiddle"
    },
    {
      "",
      1,
      "kAlignLeftMiddle"
    }
  })
  HideFriendList()
  BattleTeamMemList.SelItem(0)
  ui.apply_fl.Parent = gui
  ui.apply_ruleContent.Text = GetUTF8Text("ni chou sha !")
  ui.apply_ruleContent.Readonly = true
  ui.guild_name.Text = data.teamList[1].guildName
  ui.team_name.Text = data.teamList[1].teamName
  ui.guild_photo.BackgroundColor = colw
  ui.guild_photo.Skin = Gui.ControlSkin({
    BackgroundImage = Gui.Image(resDir .. data.guildIcon .. ".tga", Vector4(0, 0, 0, 0))
  })
  GuildId = data.teamList[1].guildId
  RequestTeamList(true)
end

Tip.CreateTitle(ui.area_main, title_ui, GetUTF8Text("UI_pet_baomingcansai"))
local title_ui.btn.EventClick, AddFriendsGroupItem = function(sender, e)
  ui.apply_fl.Parent = nil
end, title_ui.btn
local AddFriendsGroupItem, DealGuildMember = function(group_list, online_state, player_level, player_name, player_id, apply_state)
  local list = group_list
  local root = list.RootItem
  local item
  item = list:AddItem(root, "")
  if tonumber(online_state) == ONLINE then
    item:SetIcon(0, IconsF.SocialityStatusIcons.OnlineA)
  elseif tonumber(online_state) == INGAMING then
    item:SetIcon(0, IconsF.SocialityStatusIcons.PlayingA)
  else
    item:SetIcon(0, IconsF.SocialityStatusIcons.OnlineN)
  end
  list:AddSubItem(item, player_name)
  list:AddSubItem(item, apply_state)
  item:SetTextColor(1, ARGB(255, 255, 255, 255))
  item:SetTextColor(2, ARGB(255, 255, 255, 255))
  item:SetHighLightTextColor(1, ARGB(255, 62, 26, 1))
  item:SetHighLightTextColor(2, ARGB(255, 62, 26, 1))
  list:AddSubItem(item, player_id)
  list:AddSubItem(item, online_state)
  return item
end, function(sender, e)
  ui.apply_fl.Parent = nil
end
local DealGuildMember, DealAddLogic = function(data)
  AddedMemList = data.memberList
  local apply_state
  if 0 < #AddedMemList then
    for i, v in ipairs(AddedMemList) do
      if v.isHeader == "Y" then
        apply_state = GetUTF8Text("UI_lobby_consortia_03")
      elseif tonumber(v.applyState) == 3 then
        apply_state = GetUTF8Text("UI_lobby_yibaoming")
      else
        apply_state = nil
      end
      AddFriendsGroupItem(ui.list, 1, v.level, v.name, v.pId, apply_state)
    end
  end
end, title_ui
local DealAddLogic, RefreshFriendList = function(sel_item)
  local ApplyState
  CurrentAddPid = sel_item:GetText(3)
  ApplyState = sel_item:GetText(2)
  if ApplyState == GetUTF8Text("UI_lobby_consortia_03") or ApplyState == GetUTF8Text("UI_lobby_yibaoming") then
    MessageBox.Show(GetUTF8Text("this human is header, cannot add !!!"), GetUTF8Text("button_common_OK"))
  else
    rpc.safecall("Invite_racing_member", {
      headerId = SelectCharacter.roleServerId,
      invitedPlayerId = CurrentAddPid
    }, nil)
    RequestTeamList(true)
    HideFriendList()
  end
end, GetUTF8Text("UI_pet_baomingcansai")

function RefreshFriendList()
  local nIndex = 0
  local pItem
  local chat = ptr_cast(game.ChatConnect)
  if not chat then
    return
  end
  ui.list:DeleteAll()
  rpc.safecall("guild_member_list", {guildId = GuildId}, DealGuildMember)
end

function ui.btn_addTeammate.EventClick(sender, e)
  if friend_list.Parent ~= nil then
    HideFriendList()
  else
    RefreshFriendList()
    friend_list.Parent = ui.addTeammate_main
  end
end

function ui.list.EventDoubleClick(sender, e)
  local item = sender.SelectedItem
  if item then
    DealAddLogic(item)
  end
end

function ui.btn_confirm.EventClick(sender, e)
  local sel_item = ui.list.SelectedItem
  if sel_item then
    DealAddLogic(sel_item)
  end
end

function ui.apply_btn.EventClick(sender, e)
  rpc.safecall("racing_team_apply", {
    num = #TeamList,
    headerId = SelectCharacter.roleServerId,
    playerIds = table.concat(TeamMemId, ","),
    racingName = CompetitionChampion.SeasonName
  }, function()
    MessageBox.ShowError(GetUTF8Text("Apply Succeed !!!"))
  end)
end

function ui.change_team.EventClick(sender, e)
  MessageBox.ShowWithConfirmCancel(GetUTF8Text("continue ? "), function(sender, e)
    rpc.safecall("racing_replacement_member", {
      headerId = SelectCharacter.roleServerId
    }, nil)
    RequestTeamList(true)
  end)
end
