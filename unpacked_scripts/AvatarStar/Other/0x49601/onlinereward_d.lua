module("OnlineReward", package.seeall)
local resDir = "/ui/skinF/lobby/"
colw = ComFuc.colw
un_time_award_ui = Gui.Create()({
  Gui.Control("ctl_root")({
    Dock = "kDockFill",
    BackgroundColor = ARGB(128, 0, 0, 0),
    Gui.Control("main")({
      Size = Vector2(448, 432),
      Dock = "kDockCenter",
      Skin = SkinF.skin_time_award_no,
      BackgroundColor = colw,
      ComFuc.ComLabel("label1", GetUTF8Text("UI_common_online_hortation_01"), Vector2(298, 20), Vector2(70, 8), 0, 16, colw, "kAlignCenterMiddle"),
      Gui.Button("close_button")({
        Size = Vector2(24, 24),
        Location = Vector2(378, 10),
        Skin = SkinF.lookInfo_002
      }),
      Gui.Control({
        Size = Vector2(448, 50),
        Location = Vector2(0, 52),
        ComFuc.ComLabel(nil, GetUTF8Text("UI_common_online_hortation_06"), Vector2(448, 25), Vector2(0, 0), 0, 16, colw, "kAlignCenterMiddle")
      }),
      ComFuc.ComItemCB("prize_1_1", Vector2(47, 87), ""),
      ComFuc.ComItemCB("prize_1_2", Vector2(127, 87), ""),
      ComFuc.ComItemCB("prize_1_3", Vector2(207, 87), ""),
      ComFuc.ComItemCB("prize_2_1", Vector2(47, 199), ""),
      ComFuc.ComItemCB("prize_2_2", Vector2(127, 199), ""),
      ComFuc.ComItemCB("prize_2_3", Vector2(207, 199), ""),
      ComFuc.ComItemCB("prize_3_1", Vector2(47, 311), ""),
      ComFuc.ComItemCB("prize_3_2", Vector2(127, 311), ""),
      ComFuc.ComItemCB("prize_3_3", Vector2(207, 311), ""),
      ComFuc.ComButton("getbutton_1", GetUTF8Text("button_store_sign_newbutton"), Vector2(94, 53), Vector2(302, 113), 16, false, false, SkinF.select_character_038),
      ComFuc.ComButton("getbutton_2", GetUTF8Text("button_store_sign_newbutton"), Vector2(94, 53), Vector2(302, 225), 16, false, false, SkinF.select_character_038),
      ComFuc.ComButton("getbutton_3", GetUTF8Text("button_store_sign_newbutton"), Vector2(94, 53), Vector2(302, 337), 16, false, false, SkinF.select_character_038),
      ComFuc.ComLabel("label2", GetUTF8Text("00:00:00"), Vector2(100, 25), Vector2(302, 88), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComLabel("label3", GetUTF8Text("00:00:00"), Vector2(100, 25), Vector2(302, 200), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComLabel("label4", GetUTF8Text("00:00:00"), Vector2(100, 25), Vector2(302, 312), 0, 16, colw, "kAlignCenterMiddle")
    })
  })
})

function initializelabelMember(membername)
  for i = 2, 4 do
    un_time_award_ui[membername .. i].Text = "00" .. ":" .. "00" .. ":" .. "00"
    un_time_award_ui[membername .. i].Enable = false
  end
end

initializelabelMember("label")
finish_time_award_ui = Gui.Create()({
  Gui.Control("ctl_root")({
    Dock = "kDockFill",
    BackgroundColor = ARGB(128, 0, 0, 0),
    Gui.Control("main")({
      Size = Vector2(448, 297),
      Dock = "kDockCenter",
      Skin = SkinF.skin_time_award,
      BackgroundColor = colw,
      ComFuc.ComLabel("label1", GetUTF8Text("UI_common_online_hortation_01"), Vector2(298, 20), Vector2(70, 8), 0, 16, colw, "kAlignCenterMiddle"),
      Gui.Button("close_button")({
        Size = Vector2(24, 24),
        Location = Vector2(378, 10),
        Skin = SkinF.lookInfo_002
      }),
      ComFuc.ComLabel("label2", GetUTF8Text("UI_common_online_hortation_05"), Vector2(350, 120), Vector2(49, 64), 0, 16, colw, "kAlignCenterMiddle"),
      ComFuc.ComButton("okButton", GetUTF8Text("button_common_OK"), Vector2(260, 66), Vector2(94, 210), 16, false, false, SkinF.select_character_029)
    })
  })
})
local finish_time_award_ui.label2.AutoWrap, Showgifttips = true, finish_time_award_ui.label2

function Showgifttips(sender, e)
  if e.type == 7 then
    local hintStr
    if e.itemId == "1" then
      hintStr = GetUTF8Text("msgbox_common_conditionkey_128")
    elseif e.itemId == "2" then
      hintStr = GetUTF8Text("msgbox_common_conditionkey_129")
    elseif e.itemId == "3" then
      hintStr = GetUTF8Text("msgbox_common_conditionkey_130")
    elseif e.itemId == "4" then
      hintStr = GetUTF8Text("msgbox_common_conditionkey_195")
    end
    sender.Hint = hintStr
  else
    sender.Hint = ""
    Tip.SetRpc(PersonalInfo.tip_sys_interface[e.type], {
      t = e.type,
      sid = e.itemId
    })
    Tip.SetUseDescription(false)
    Tip.SetOwner(sender)
  end
end

function ShowUnTimeAwardDialog(prizeList)
  for k, v in ipairs(prizeList) do
    for i = 1, 3 do
      if i <= #v then
        if v[i].type then
          un_time_award_ui["prize_" .. v.prizeLevel .. "_" .. i].Visible = true
          un_time_award_ui["prize_" .. v.prizeLevel .. "_" .. i .. "_res"].EventMouseEnter = function(sender, e)
            Showgifttips(sender, v[i])
          end
          if v[i].type == 7 then
            local resName
            if v[i].itemId == "1" then
              resName = "skin_common_icon_gold01"
            elseif v[i].itemId == "2" then
              resName = "xingbi"
            elseif v[i].itemId == "3" then
              resName = "xunzhang"
            elseif v[i].itemId == "4" then
              resName = "duihuanquan"
            end
            ComFuc.ShowOneButton(un_time_award_ui["prize_" .. v.prizeLevel .. "_" .. i .. "_lev"], un_time_award_ui["prize_" .. v.prizeLevel .. "_" .. i .. "_res"], "/ui/skinF/", resName, v[i].grade)
          else
            local res
            if v[i].type == 1 then
              print(GetUTF8Text("msgbox_common_num_1376"))
            elseif v[i].type == 2 then
              res = v[i].resource
              if v[i].subType == 102 then
                local start, endlen = string.find(v[i].resource, ",")
                if start then
                  res = string.sub(v[i].resource, 2, start - 2)
                else
                  res = v[i].resource
                end
              end
            elseif v[i].type == 3 then
              res = v[i].resource
            elseif v[i].type == 4 then
              res = v[i].resource
            elseif v[i].type == 5 then
              if v[i].subType == 1 then
                res = "humancard"
              elseif v[i].subType == 2 then
                res = "herocard"
              end
            elseif v[i].type == 6 then
              if v[i].subType == 1 then
                res = "humancard"
              elseif v[i].subType == 2 then
                res = "herocard"
              end
            else
              print("unknown attachment type: " .. v[i].type)
            end
            ComFuc.ShowOneButton(un_time_award_ui["prize_" .. v.prizeLevel .. "_" .. i .. "_lev"], un_time_award_ui["prize_" .. v.prizeLevel .. "_" .. i .. "_res"], resDir, res, v[i].grade)
          end
          local quantity = v[i].quantity
          if v[i].unitType and v[i].unitType ~= 3 then
            quantity = 1
          end
          un_time_award_ui["prize_" .. v.prizeLevel .. "_" .. i .. "_count"].Text = quantity
        else
          un_time_award_ui["prize_" .. v.prizeLevel .. "_" .. i].Visible = false
          print("Error!The online prize info has an empty table!")
        end
      else
        un_time_award_ui["prize_" .. v.prizeLevel .. "_" .. i].Visible = false
      end
    end
  end
  un_time_award_ui.ctl_root.Parent = gui
end

function un_time_award_ui.close_button.EventClick(sender, e)
  HideUnTimeAwardDialog()
end

function HideUnTimeAwardDialog()
  un_time_award_ui.ctl_root.Parent = nil
end

function ShowPrizeButState(i)
  for k = 1, 3 do
    un_time_award_ui["getbutton_" .. k].Enable = k == i
    local txt = GetUTF8Text("button_store_sign_newbutton")
    if k < i then
      txt = GetUTF8Text("button_store_received")
    end
    un_time_award_ui["getbutton_" .. k].Text = txt
  end
end

function SetTimeText(onlineIndex, hourtext, mintext, sectext)
  initializelabelMember("label")
  if onlineIndex == 1 then
    un_time_award_ui.label2.Text = hourtext .. ":" .. mintext .. ":" .. sectext
  elseif onlineIndex == 2 then
    un_time_award_ui.label3.Text = hourtext .. ":" .. mintext .. ":" .. sectext
  elseif onlineIndex == 3 then
    un_time_award_ui.label4.Text = hourtext .. ":" .. mintext .. ":" .. sectext
  end
end

for i = 1, 3 do
  un_time_award_ui["getbutton_" .. i].EventClick = function(sender, e)
    if Lobby.canGetPrize then
      rpc.safecall("player_ol_get_prize", nil, Lobby.DealGetGiftSuccess)
      Lobby.rpc_player_ol_prize()
    else
      MessageBox.ShowError(GetUTF8Text("msgbox_common_online_hortation_07"))
    end
  end
end

function finish_time_award_ui.close_button.EventClick(sender, e)
  HideFinishTimeAwardDialog()
end

function finish_time_award_ui.okButton.EventClick(sender, e)
  HideFinishTimeAwardDialog()
end

function ShowFinishTimeAwardDialog()
  finish_time_award_ui.ctl_root.Parent = gui
end

function HideFinishTimeAwardDialog()
  finish_time_award_ui.ctl_root.Parent = nil
end
