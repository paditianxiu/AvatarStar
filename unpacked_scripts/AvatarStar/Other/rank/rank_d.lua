module("Rank", package.seeall)
local _T = Tip._T
local _M = Tip._M
local white = Tip.white
local brown = Tip.brown
local yellow = Tip.yellow
local rank_color = ARGB(255, 255, 252, 8)
local GetIcon = Tip.GetIcon
local GetGradeImage = Tip.GetGradeImage
local GetRankName = Tip.GetRankName
local GetRankKey = Tip.GetRankKey
local GetCurrencyText = Tip.GetCurrencyText
local format = string.format
local my_rank, my_type, weapons
local fl_rank = Gui.FlowLayout({
  Dock = "kDockFill",
  Align = "kAlignCenterMiddle",
  BackgroundColor = ARGB(128, 0, 0, 0)
})()
local ctrl_rank = Gui.Control({
  Size = Vector2(1105, 830),
  BackgroundColor = white,
  Skin = SkinF.rank_stage_background
})(fl_rank, nil)
local title_ui = {}

function CreateTitle(p, ui, t)
  ui.lb = Gui.Label({
    Size = Vector2(100, 20),
    Location = Vector2(16, 13),
    TextAlign = "kAlignLeftMiddle",
    FontSize = 16,
    Text = t
  })(p, nil)
  ui.hint = Gui.Label({
    Size = Vector2(500, 20),
    Location = Vector2(569, 13),
    TextAlign = "kAlignRightMiddle",
    FontSize = 16,
    Text = ""
  })(p, nil)
  ui.btn = Gui.Button({
    Size = Vector2(24, 24),
    Location = Vector2(1069, 12),
    Skin = SkinF.lookInfo_002
  })(p, nil)
end

CreateTitle(ctrl_rank, title_ui, _T("UI_social_military_rank"))

function title_ui.btn.EventClick(sender, e)
  Hide()
end

Gui.Control({
  Location = Vector2(28, 117),
  Size = Vector2(221, 53),
  Skin = SkinF.rank_score_background,
  BackgroundColor = white
})(ctrl_rank, nil)
Gui.Label({
  Location = Vector2(28, 90),
  Size = Vector2(132, 24),
  TextColor = rank_color,
  FontSize = 16,
  Text = _T("UI_social_rank_score_now")
})(ctrl_rank, nil)
local lb_my_rank_score = Gui.Label({
  Style = "junxianfen.num",
  BackgroundColor = ARGB(0, 0, 0, 0),
  Location = Vector2(28, 130),
  TextAlign = "kAlignCenterMiddle",
  Size = Vector2(221, 33)
})(ctrl_rank, nil)
local lb_my_rank_icon = Gui.Label({
  Location = Vector2(73, 178),
  Size = Vector2(116, 116)
})(ctrl_rank, nil)
local lb_my_rank = Gui.Label({
  Location = Vector2(32, 298),
  Size = Vector2(200, 24),
  TextAlign = "kAlignCenterMiddle",
  TextColor = rank_color,
  FontSize = 16
})(ctrl_rank, nil)
for i = 0, 1 do
  Gui.Control({
    Location = Vector2(76, 326 + 3 * i),
    Size = Vector2(110, 1),
    Skin = SkinF.rank_underline,
    BackgroundColor = white
  })(ctrl_rank, nil)
end
local lb_my_rank_stage = Gui.Control({
  Location = Vector2(54, 383),
  Size = Vector2(170, 120),
  Skin = SkinF.rank_stage[1],
  BackgroundColor = white
})(ctrl_rank, nil)
local fl_list = Gui.FlowLayout({
  Location = Vector2(262, 185),
  Size = Vector2(818, 620),
  LineSpace = 3,
  BackgroundColor = white,
  Skin = SkinF.rank_02
})(ctrl_rank, nil)
local fl_header = Gui.FlowLayout({
  Size = Vector2(818, 38)
})(fl_list, nil)
local header_text = {
  {68, ""},
  {
    152,
    _T("UI_social_rank_name")
  },
  {
    108,
    _T("UI_social_rank_lv")
  },
  {
    114,
    _T("UI_social_score_add")
  },
  {
    114,
    _T("UI_social_score_reduce")
  },
  {
    114,
    _T("UI_social_score_line")
  },
  {
    144,
    _T("UI_social_rank_buff")
  }
}
for i, v in ipairs(header_text) do
  Gui.Label({
    Size = Vector2(v[1], 38),
    Text = v[2]
  })(fl_header, nil)
end
local item_ui = {}
local sub_item_ui = {}
local buff_ui, CreateSubItem = {}, {
  114,
  _T("UI_social_score_add")
}
local CreateSubItem, CreateBuff = function(p, ui)
  local m = (header_text[1][1] - 32) / 2
  Gui.Label({
    Size = Vector2(32, 32),
    Margin = Vector4(m, 0, m, 0)
  })(p, ui)
  for i = 2, 6 do
    Gui.Label({
      Size = Vector2(header_text[i][1], 32),
      FontSize = 16
    })(p, ui)
  end
  Gui.FlowLayout({
    Size = Vector2(header_text[6][1], 32),
    ControlSpace = 4
  })(p, ui)
end, {
  114,
  _T("UI_social_score_reduce")
}

function CreateBuff(p, ui)
  for i = 1, 2 do
    Gui.Control({
      Size = Vector2(32, 32),
      BackgroundColor = white
    })(p, ui)
  end
end

for i = 1, 14 do
  Gui.FlowLayout({
    Size = Vector2(818, 38),
    Align = "kAlignMiddle"
  })(fl_list, item_ui)
  sub_item_ui[i] = {}
  CreateSubItem(item_ui[i], sub_item_ui[i])
  sub_item_ui[i][1].Icon = IconsF.GetSmallRankIcon(1, i)
  sub_item_ui[i][2].Text = GetRankName(i)
  sub_item_ui[i][3].Text = i
  sub_item_ui[i][6].TextColor = yellow
  buff_ui[i] = {}
  CreateBuff(sub_item_ui[i][7], buff_ui[i])
end
local stage_button = {}
for i = 1, 4 do
  stage_button[i] = Gui.Button({
    Size = Vector2(170, 120),
    Location = Vector2(280 + 204 * (i - 1), 62),
    BackgroundColor = white,
    Skin = SkinF.rank_stage_button[i]
  })(ctrl_rank, nil)
  stage_button[i].EventClick = function(sender, e)
    SetRankList(i)
  end
end
local rank_list, SetSubItem = nil, 4
local SetSubItem, ShowRankList = function(sui, v)
  sui[4].Text = v[3]
  sui[5].Text = v[4]
  sui[6].Text = v[5]
  sui[7].Text = v[6]
end, 1
local ShowRankList, RequestRankList = function(rank_type)
  local temp = #rank_list
  for i = 1, 14 do
    sub_item_ui[i][1].Icon = IconsF.GetSmallRankIcon(rank_type, i)
  end
  for i = 1, rank_list[temp][1] do
    for j, v in ipairs(rank_list) do
      if i == v[1] and rank_type == v[2] then
        SetSubItem(sub_item_ui[i], v)
        buff_ui[i][1].Skin = SkinF.rank_03
        buff_ui[i][2].Skin = SkinF.rank_04
        table.sort(v[6], function(t1, t2)
          return t1[1] < t2[1]
        end)
        buff_ui[i][1].Hint = _T(v[6][1][2])
        buff_ui[i][2].Hint = _T(v[6][2][2])
        break
      end
    end
  end
  for i = 1, 4 do
    stage_button[i].PushDown = false
  end
  stage_button[rank_type].PushDown = true
end, CreateBuff
local RequestRankList, RequestMyRank = function()
  rpc.safecall("rank_list", {}, function(data)
    rank_list = data.list
    table.sort(rank_list, function(t1, t2)
      return t1[1] < t2[1] or t1[1] == t2[1] and t1[2] < t2[2]
    end)
    ShowRankList(1)
  end)
end, stage_button[i]

function RequestMyRank()
  rpc.safecall("rank_mine", {}, function(data)
    my_type = data.type
    if my_rank ~= data.rank then
      if my_rank then
        item_ui[my_rank].BackgroundColor = ARGB(0, 0, 0, 0)
        item_ui[my_rank].Skin = nil
      end
      my_rank = data.rank
      item_ui[my_rank].BackgroundColor = white
      item_ui[my_rank].Skin = SkinF.rank_05
    end
    lb_my_rank.Text = GetRankName(data.rank)
    lb_my_rank_score.Text = data.point
    lb_my_rank_icon.Icon = IconsF.GetBigRankIcon(data.type, data.rank)
    lb_my_rank_stage.Skin = SkinF.rank_stage[my_type], SetRankList(my_type)
    fl_rank.Parent = gui
  end, function(data)
    fl_rank.Parent = gui
  end)
end

function SetRankList(i)
  ShowRankList(i)
  item_ui[my_rank].BackgroundColor = ARGB(0, 0, 0, 0)
  item_ui[my_rank].Skin = nil
  if i == my_type then
    item_ui[my_rank].BackgroundColor = white
    item_ui[my_rank].Skin = SkinF.rank_05
  end
end

function Show()
  if not rank_list then
    RequestRankList()
  end
  RequestMyRank()
end

function Hide()
  fl_rank.Parent = nil
end

function Reset()
  rank_list = nil
end
