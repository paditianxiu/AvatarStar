module("Mail", package.seeall)
local local_mail_list = {}
local ui_mail_write_attach = {}
local ui_mail_read_attach = {}
local local_storage_infos = {}
local local_storage_types = {}
local SwitchTab, ShowMailRead, HideMailRead, ShowFriendList, ClearAllMailWrite, RefreshMailRead, DeleteMailList, HideFriendList, ShowAttachConfig, ClearAllMailWriteAttachment, RefreshMailReadAttachment, ClearMailReadAttachment, SetDelBtnSEnableState, SetAttachBtnEnableState
local MAX_MAIL_COUNT = 100
local WARNING_COUNT = 100
local timer
local crTextColor = ARGB(255, 255, 255, 255)
local crDisabledTextColor = ARGB(255, 192, 192, 192)
local nMailSendCost = 20
local nMailAttachSendCost = 1
local nCanSendMailCount = 0
local tip_player_interface, Trim = {
  "tip_player_skill",
  "tip_player_item",
  "tip_player_item",
  "tip_player_item",
  "tip_player_avatar",
  "tip_player_avatar"
}, "tip_player_skill"

function Trim(s)
  assert(type(s) == "string")
  if string.len(s) < 1 then
    return ""
  else
    return string.gsub(s, "^%s*(.-)%s*$", "%1")
  end
end

ui = Gui.Create()({
  Gui.Control("main")({
    Size = Vector2(1600, 1200),
    BackgroundColor = ARGB(155, 0, 0, 0),
    Gui.Control("main_mid")({
      Size = Vector2(592, 508),
      Location = Vector2(398, 300)
    })
  }),
  Gui.Control("root")({
    Location = Vector2(100, 100),
    Size = Vector2(394, 599),
    BackgroundColor = ARGB(255, 255, 255, 255),
    Skin = SkinF.personalInfo_207,
    ComFuc.ComLabel("name_t", GetUTF8Text("tips_lobby_Button_Decs5"), Vector2(218, 18), Vector2(16, 6), 0, 16, ARGB(255, 255, 255, 255)),
    Gui.Button("btn_close")({
      Location = Vector2(358, 4),
      Size = Vector2(24, 24),
      Skin = SkinF.lookInfo_002,
      EventClick = function(sender, e)
        Hide()
      end
    }),
    Gui.Control("container")({
      Location = Vector2(7, 84),
      Size = Vector2(378, 506),
      BackgroundColor = ARGB(0, 255, 0, 0)
    }),
    Gui.Button("btn_readList")({
      Size = Vector2(125, 38),
      Location = Vector2(27, 48),
      Text = GetUTF8Text("button_social_additional_string_001"),
      TextColor = ARGB(255, 62, 26, 1),
      HighlightTextColor = ARGB(255, 62, 26, 1),
      TextShadowColor = ARGB(0, 0, 0, 0),
      FontSize = 16,
      Skin = SkinF.personalInfo_121,
      TextShadowWhenNormal = false,
      EventClick = function(sender, e)
        SwitchTab(1)
      end
    }),
    Gui.Button("btn_write")({
      Size = Vector2(125, 38),
      Location = Vector2(155, 48),
      Text = GetUTF8Text("button_common_Compose"),
      TextColor = ARGB(255, 62, 26, 1),
      HighlightTextColor = ARGB(255, 62, 26, 1),
      TextShadowColor = ARGB(0, 0, 0, 0),
      FontSize = 16,
      Skin = SkinF.personalInfo_121,
      TextShadowWhenNormal = false,
      EventClick = function(sender, e)
        SwitchTab(2)
      end
    }),
    Gui.Button("btn_warning")({
      Size = Vector2(34, 36),
      Location = Vector2(346, 48),
      Skin = SkinF.mail_button_004,
      CanMove = true,
      Visible = false,
      Hint = "",
      EventClick = function(sender, e)
        if ui_mail_list.list.ItemCount < tonumber(MAX_MAIL_COUNT) then
          MessageBox.ShowError(GetUTF8Text("msgbox_social_additional_string_002"))
        else
          MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1358"))
        end
      end
    })
  })
})
ui_mail_list = Gui.Create()({
  Gui.Control("root")({
    Dock = "kDockFill",
    BackgroundColor = ARGB(255, 255, 255, 255),
    Skin = SkinF.personalInfo_131,
    Gui.Control({
      Location = Vector2(6, 6),
      Size = Vector2(366, 384),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.personalInfo_068,
      Gui.SocialityChannelList("list")({
        Dock = "kDockFill",
        Margin = Vector4(7, 7, 7, 7),
        BackgroundColor = ARGB(255, 255, 0, 255),
        Style = "Mail.List"
      })
    }),
    Gui.CheckBox("check_SelectAll")({
      Location = Vector2(25, 404),
      Size = Vector2(150, 24),
      Text = GetUTF8Text("UI_social_Select_All_Mails"),
      TextColor = ARGB(255, 62, 26, 1),
      FontSize = 16,
      ClickAudio = "textbar",
      EventCheckChanged = function(sender, e)
        ui_mail_list.list:SetAllItemsCheck(sender.Check)
        SetDelBtnSEnableState()
        SetAttachBtnEnableState()
      end
    }),
    Gui.Label("lbl_mail_count")({
      TextAlign = "kAlignRightMiddle",
      Location = Vector2(225, 406),
      Size = Vector2(145, 21),
      Text = string.format(GetUTF8Text("UI_social_additional_string_003"), 0, MAX_MAIL_COUNT),
      TextColor = ARGB(255, 62, 26, 1),
      FontSize = 16
    }),
    Gui.Button("btn_del")({
      Location = Vector2(12, 449),
      Size = Vector2(84, 43),
      Text = GetUTF8Text("button_common_Delete"),
      FontSize = 16,
      Enable = false,
      CanMove = true,
      TextColor = crTextColor,
      DisabledTextColor = crDisabledTextColor,
      TextShadowWhenNormal = true,
      TextShadowColor = ARGB(150, 0, 0, 0)
    }),
    Gui.Button("btn_attach_cfg")({
      Location = Vector2(245, 450),
      Size = Vector2(34, 36),
      Skin = SkinF.mail_button_007,
      Hint = GetUTF8Text("msgbox_common_num_1314"),
      CanMove = true,
      EventClick = function(sender, e)
        ShowAttachConfig()
      end
    }),
    Gui.Button("btn_attach")({
      Location = Vector2(282, 449),
      Size = Vector2(84, 43),
      Text = GetUTF8Text("button_common_Retrieve"),
      FontSize = 16,
      CanMove = true,
      TextColor = crTextColor,
      DisabledTextColor = crDisabledTextColor,
      TextShadowWhenNormal = true,
      TextShadowColor = ARGB(150, 0, 0, 0)
    })
  })
})
ui_mail_read = Gui.Create()({
  Gui.Control("root")({
    Location = Vector2(7, 84),
    Size = Vector2(378, 506),
    BackgroundColor = ARGB(255, 255, 255, 255),
    Skin = SkinF.personalInfo_131,
    Gui.Control({
      Location = Vector2(5, 5),
      Size = Vector2(368, 443),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.battle_005,
      Gui.Label("lbl_sender")({
        Location = Vector2(12, 16),
        Size = Vector2(68, 21),
        BackgroundColor = ARGB(0, 0, 0, 0),
        Text = GetUTF8Text("UI_social_additional_string_004"),
        TextColor = ARGB(255, 62, 26, 1),
        TextAlign = "kAlignLeftMiddle",
        FontSize = 16
      }),
      Gui.Textbox("txt_sender")({
        Location = Vector2(84, 12),
        Size = Vector2(244, 29),
        Text = "",
        TextColor = ARGB(255, 255, 255, 255),
        FontSize = 16,
        Readonly = true
      }),
      Gui.Button("btn_close")({
        Location = Vector2(335, 12),
        Size = Vector2(24, 24),
        Skin = SkinF.lookInfo_002,
        CanMove = true,
        EventClick = function(sender, e)
          HideMailRead()
        end
      }),
      Gui.Label("lbl_time")({
        Location = Vector2(12, 47),
        Size = Vector2(68, 21),
        BackgroundColor = ARGB(0, 0, 0, 0),
        Text = GetUTF8Text("UI_common_Sent_Time"),
        TextColor = ARGB(255, 62, 26, 1),
        TextAlign = "kAlignLeftMiddle",
        FontSize = 16
      }),
      Gui.Textbox("txt_time")({
        Location = Vector2(84, 43),
        Size = Vector2(276, 29),
        Text = "2012/9/1",
        TextColor = ARGB(255, 255, 255, 255),
        FontSize = 16,
        Readonly = true
      }),
      Gui.Label("lbl_subject")({
        Location = Vector2(12, 78),
        Size = Vector2(68, 21),
        BackgroundColor = ARGB(0, 0, 0, 0),
        Text = GetUTF8Text("UI_social_Subject"),
        TextColor = ARGB(255, 62, 26, 1),
        TextAlign = "kAlignLeftMiddle",
        FontSize = 16
      }),
      Gui.Textbox("txt_subject")({
        Location = Vector2(84, 74),
        Size = Vector2(276, 29),
        Text = "",
        TextColor = ARGB(255, 255, 255, 255),
        FontSize = 16,
        Readonly = true
      }),
      Gui.TextArea("txt_content")({
        Location = Vector2(8, 105),
        Size = Vector2(352, 262),
        Text = "",
        TextColor = ARGB(255, 255, 255, 255),
        TextPadding = Vector4(6, 6, 6, 6),
        Style = "Mail.TextArea",
        MaxLength = 600,
        Readonly = true,
        VScrollBarDisplay = "kHide"
      }),
      Gui.FlowLayout("ctrl_attach")({
        Location = Vector2(8, 370),
        Size = Vector2(352, 64),
        BackgroundColor = ARGB(0, 255, 0, 0),
        Align = "kAlignLeftTop",
        ControlSpace = 8
      })
    }),
    Gui.Button("btn_del")({
      Location = Vector2(12, 449),
      Size = Vector2(84, 43),
      Text = GetUTF8Text("button_common_Delete"),
      FontSize = 16,
      CanMove = true,
      TextColor = crTextColor,
      DisabledTextColor = crDisabledTextColor,
      TextShadowWhenNormal = true,
      TextShadowColor = ARGB(150, 0, 0, 0),
      EventClick = function(sender, e)
        local isAttach = false
        for i = 1, 5 do
          if ui_mail_read_attach[i].lbl_icon.Icon then
            isAttach = true
            break
          end
        end
        if isAttach then
          MessageBox.ShowWithConfirmCancel(GetUTF8Text("msgbox_common_num_1245"), function()
            local item = ui_mail_list.list.SelectedItem
            if item then
              HideMailRead()
              DeleteMailList(tostring(item:GetText(6)), 1)
            end
          end)
        else
          MessageBox.ShowWithConfirmCancel(GetUTF8Text("msgbox_common_num_1323"), function()
            local item = ui_mail_list.list.SelectedItem
            if item then
              HideMailRead()
              DeleteMailList(tostring(item:GetText(6)), 1)
            end
          end)
        end
      end
    }),
    Gui.Button("btn_replay")({
      Location = Vector2(192, 449),
      Size = Vector2(84, 43),
      Text = GetUTF8Text("button_social_additional_string_005"),
      FontSize = 16,
      CanMove = true,
      TextColor = ARGB(255, 255, 255, 255),
      DisabledTextColor = ARGB(255, 192, 192, 192),
      TextShadowWhenNormal = true,
      TextShadowColor = ARGB(150, 0, 0, 0),
      EventClick = function(sender, e)
        item = ui_mail_list.list.SelectedItem
        if item then
          local mail_info = local_mail_list[item:GetText(6)].data
          ui_mail_write.txt_sender.Text = mail_info.senderName
          ui_mail_write.txt_subject.Text = GetUTF8Text("button_social_additional_string_005") .. ":" .. mail_info.subject
          ui_mail_write.txt_content.Text = ""
          SwitchTab(2)
          ClearAllMailWriteAttachment()
        end
      end
    }),
    Gui.Button("btn_recieve_all")({
      Location = Vector2(282, 449),
      Size = Vector2(84, 43),
      Text = GetUTF8Text("UI_common_Retrieve_All"),
      FontSize = 16,
      CanMove = true,
      TextColor = crTextColor,
      DisabledTextColor = crDisabledTextColor,
      TextShadowWhenNormal = true,
      TextShadowColor = ARGB(150, 0, 0, 0)
    })
  })
})
ui_mail_write = Gui.Create()({
  Gui.Control("root")({
    Dock = "kDockFill",
    BackgroundColor = ARGB(255, 255, 255, 255),
    Skin = SkinF.personalInfo_131,
    Gui.Control({
      Location = Vector2(5, 5),
      Size = Vector2(368, 433),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.battle_005,
      Gui.Label("lbl_sender")({
        Location = Vector2(12, 16),
        Size = Vector2(68, 21),
        BackgroundColor = ARGB(0, 0, 0, 0),
        Text = GetUTF8Text("UI_social_Recipient"),
        TextColor = ARGB(255, 62, 26, 1),
        TextAlign = "kAlignLeftMiddle",
        FontSize = 16
      }),
      Gui.Textbox("txt_sender")({
        Location = Vector2(84, 12),
        Size = Vector2(238, 29),
        Text = "",
        TextColor = ARGB(255, 255, 255, 255),
        FontSize = 16,
        MaxLength = 20
      }),
      Gui.Button("btn_friends")({
        Location = Vector2(323, 10),
        Size = Vector2(33, 34),
        Skin = SkinF.mail_button_006,
        CanMove = true,
        Hint = GetUTF8Text("button_social_additional_string_006"),
        EventClick = function(sender, e)
          ShowFriendList()
        end
      }),
      Gui.Label("lbl_subject")({
        Location = Vector2(12, 47),
        Size = Vector2(68, 21),
        BackgroundColor = ARGB(0, 0, 0, 0),
        Text = GetUTF8Text("UI_social_Subject"),
        TextColor = ARGB(255, 62, 26, 1),
        TextAlign = "kAlignLeftMiddle",
        FontSize = 16
      }),
      Gui.Textbox("txt_subject")({
        Location = Vector2(84, 43),
        Size = Vector2(277, 29),
        Text = "",
        TextColor = ARGB(255, 255, 255, 255),
        MaxLength = 20,
        FontSize = 16
      }),
      Gui.TextArea("txt_content")({
        Location = Vector2(8, 74),
        Size = Vector2(352, 226),
        Text = "",
        TextColor = ARGB(255, 255, 255, 255),
        TextPadding = Vector4(6, 6, 6, 6),
        Style = "Mail.TextArea",
        MaxLength = 400,
        VScrollBarDisplay = "kAuto"
      }),
      Gui.FlowLayout("ctrl_attach")({
        Location = Vector2(8, 303),
        Size = Vector2(352, 64),
        BackgroundColor = ARGB(0, 255, 0, 0),
        Align = "kAlignLeftTop",
        ControlSpace = 8
      }),
      Gui.Textbox("txt_box")({
        Location = Vector2(84, 397),
        Size = Vector2(130, 29),
        Number = true,
        MaxLength = 9,
        Visible = false
      }),
      Gui.Label("lbl_attachSetting")({
        Location = Vector2(0, 373),
        Size = Vector2(360, 21),
        Text = "",
        TextColor = ARGB(255, 176, 53, 2),
        TextAlign = "kAlignRightMiddle",
        FontSize = 16
      }),
      Gui.Label("lbl_memory")({
        Location = Vector2(210, 401),
        Size = Vector2(120, 21),
        Text = GetUTF8Text("UI_social_Postage") .. ": 20",
        TextColor = ARGB(255, 62, 26, 1),
        TextAlign = "kAlignRightMiddle",
        FontSize = 16
      }),
      Gui.Control({
        Location = Vector2(332, 397),
        Size = Vector2(30, 30),
        BackgroundColor = ARGB(255, 255, 255, 255),
        Skin = SkinF.shop_02
      })
    }),
    Gui.Button("btn_attach_over")({
      Location = Vector2(12, 449),
      Size = Vector2(84, 43),
      Text = GetUTF8Text("button_common_Clear"),
      FontSize = 16,
      CanMove = true,
      TextColor = crTextColor,
      DisabledTextColor = crDisabledTextColor,
      TextShadowWhenNormal = true,
      TextShadowColor = ARGB(150, 0, 0, 0),
      EventClick = function(sender, e)
        ClearAllMailWriteAttachment()
      end
    }),
    Gui.Button("btn_add_attach")({
      Location = Vector2(110, 449),
      Size = Vector2(84, 43),
      Text = GetUTF8Text("button_common_Add"),
      FontSize = 16,
      CanMove = true,
      TextColor = crTextColor,
      DisabledTextColor = crDisabledTextColor,
      TextShadowWhenNormal = true,
      TextShadowColor = ARGB(150, 0, 0, 0),
      EventClick = function(sender, e)
        if not MailDepot then
          require("mailDepot.lua")
        end
        if MailDepot then
          if MailDepot.Visible() then
            MailDepot.Hide()
            SetAttachCtrlFlash(false)
          else
            MailDepot.Show(ui.main_mid, OnMailDepotClose)
            SetAttachCtrlFlash(true)
          end
        end
      end
    }),
    Gui.Button("btn_send")({
      Location = Vector2(282, 449),
      Size = Vector2(84, 43),
      Text = GetUTF8Text("button_common_Send"),
      FontSize = 16,
      CanMove = true,
      TextColor = crTextColor,
      DisabledTextColor = crDisabledTextColor,
      TextShadowWhenNormal = true,
      TextShadowColor = ARGB(150, 0, 0, 0),
      EventClick = function(sender, e)
        local txtSender = Trim(ui_mail_write.txt_sender.Text)
        local txtSubject = Trim(ui_mail_write.txt_subject.Text)
        local txtContent = Trim(ui_mail_write.txt_content.Text)
        print(txtSender)
        if string.len(txtSender) < 1 then
          MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1380"))
          return
        end
        if string.len(txtSubject) < 1 then
          MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1070"))
          return
        end
        if string.len(txtContent) < 1 then
          MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1071"))
          return
        end
        local count = 0
        local attachs = ""
        local bAttached = false
        for id = 1, #ui_mail_write_attach do
          local sinfo = local_storage_infos[id]
          if sinfo then
            local attach_item = local_storage_types[id] .. "," .. sinfo.pid .. "," .. (sinfo.quantity or 0)
            attachs = attachs .. attach_item .. ";"
            bAttached = true
            count = count + 1
          end
        end
        if count > nCanSendMailCount then
          MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1088"))
          return
        end
        rpc.safecall("mail_send", {
          receiver = txtSender,
          subject = txtSubject,
          content = txtContent,
          attachment = attachs
        }, function(data)
          if not data.error then
            ClearAllMailWrite()
            if bAttached then
              PersonalInfo.ReflashMail()
              if MailDepot and MailDepot.Visible() then
                MailDepot.SendToMailOK()
              end
            end
            UpdateSysSettingDetail()
            if MailDepot and MailDepot.Visible() then
              MailDepot.Hide()
              SetAttachCtrlFlash(false)
            end
            MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1375"))
          end
        end)
      end
    })
  }),
  ComFuc.ComMoveControl()
})
ui_friend_list = Gui.Create()({
  Gui.Control("root")({
    Location = Vector2(168, 45),
    Size = Vector2(248, 376),
    BackgroundColor = ARGB(255, 255, 255, 255),
    Skin = SkinF.personalInfo_131,
    Gui.Control({
      Location = Vector2(5, 5),
      Size = Vector2(238, 316),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.personalInfo_068,
      Padding = Vector4(5, 6, 5, 6),
      Gui.ListTreeView("list")({
        Dock = "kDockFill",
        Style = "Sociality.FriendsList"
      })
    }),
    Gui.Button("btn_confirm")({
      Location = Vector2(82, 325),
      Size = Vector2(84, 43),
      Text = GetUTF8Text("button_common_OK"),
      FontSize = 16,
      CanMove = true,
      TextColor = crTextColor,
      DisabledTextColor = crDisabledTextColor,
      TextShadowWhenNormal = true,
      TextShadowColor = ARGB(150, 0, 0, 0),
      EventClick = function(sender, e)
        local sel_item = ui_friend_list.list.SelectedItem
        if sel_item then
          ui_mail_write.txt_sender.Text = sel_item:GetText(1)
        end
        HideFriendList()
      end
    })
  })
})
ui_attach_config = Gui.Create()({
  Gui.Control("root")({
    Location = Vector2(100, 100),
    Size = Vector2(300, 120),
    BackgroundColor = ARGB(255, 255, 255, 255),
    Skin = SkinF.personalInfo_131,
    Gui.Control({
      Location = Vector2(5, 5),
      Size = Vector2(290, 104),
      BackgroundColor = ARGB(255, 255, 255, 255),
      Skin = SkinF.battle_005,
      Gui.Label({
        Location = Vector2(18, 8),
        Size = Vector2(260, 20),
        Text = GetUTF8Text("msgbox_common_num_1314"),
        TextColor = ARGB(255, 62, 26, 1),
        TextAlign = "kAlignLeftMiddle",
        FontSize = 16
      }),
      Gui.CheckBox("rd_all_attach")({
        Location = Vector2(18, 40),
        Size = Vector2(260, 20),
        Style = "Gui.CheckBox_01",
        Text = GetUTF8Text("msgbox_common_num_1303"),
        TextColor = ARGB(255, 62, 26, 1),
        FontSize = 16,
        CheckPosition = "kCheckLeft",
        EventCheckChanged = function(sender, e)
          if "kTriggerMouse" == e.Trigger then
            sender.Check = true
            ui_attach_config.rd_chk_attach.Check = false
            SetAttachBtnEnableState()
            ui_attach_config.root.Parent = nil
          end
        end
      }),
      Gui.CheckBox("rd_chk_attach")({
        Location = Vector2(18, 72),
        Size = Vector2(260, 20),
        Style = "Gui.CheckBox_01",
        Text = GetUTF8Text("UI_common_Retrieve_selected_attachment"),
        TextColor = ARGB(255, 62, 26, 1),
        FontSize = 16,
        CheckPosition = "kCheckLeft",
        EventCheckChanged = function(sender, e)
          if "kTriggerMouse" == e.Trigger then
            sender.Check = true
            ui_attach_config.rd_all_attach.Check = false
            SetAttachBtnEnableState()
            ui_attach_config.root.Parent = nil
          end
        end,
        Check = true
      })
    })
  })
})
local OnMailDepotClose, ShowDepotTips = function()
  SetAttachCtrlFlash(false)
end, function()
  SetAttachCtrlFlash(false)
end

function ShowDepotTips(tc, data, type, id)
  if data and data ~= 0 then
    Tip.SetRpc(tip_player_interface[type], {t = type, pid = id})
    Tip.SetUseDescription(false)
    Tip.SetOwner(tc)
  end
end

mail_bg_Skin = Gui.ControlSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_common_background06_01.tga", Vector4(0, 0, 0, 0))
})
mail_bg_Skin_2 = Gui.ControlSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_common_background05.tga", Vector4(0, 0, 0, 0))
})
mail_bg_Skin_lock = Gui.ControlSkin({
  BackgroundImage = Gui.Image("ui/skinF/skin_common_background06_lock04.tga", Vector4(0, 0, 0, 0))
})
local resDir = "/ui/skinF/lobby/"
local locDown

function CalLation(up)
  local l = up.CurrentCursorPosition - Vector2(u2.Size.x / 2 - 10, u2.Size.y / 2 - 10) + Vector2(3, 253)
  return l
end

local OnMouseMove, IsOutsect = function(up, isCard, u1, u2, p)
  u2.Location = up.CurrentCursorPosition - Vector2(u2.Size.x / 2 - 10, u2.Size.y / 2 - 10) + Vector2(3, 253)
end, function(up, isCard, u1, u2, p)
  u2.Location = up.CurrentCursorPosition - Vector2(u2.Size.x / 2 - 10, u2.Size.y / 2 - 10) + Vector2(3, 253)
end
local IsOutsect, CreateAttachItemCtrl = function(vt1, vt2, size)
  local vtTemp = vt1 - vt2
  if vtTemp.x > 63 or vtTemp.x < -63 or 63 < vtTemp.y or -63 > vtTemp.y then
    return true
  else
    return false
  end
end, Gui.Image("ui/skinF/skin_common_background06_lock04.tga", Vector4(0, 0, 0, 0))

function CreateAttachItemCtrl(type, index, ctrl_attach)
  local c
  if tonumber(type) == 1 then
    c = Gui.Create()({
      Gui.Control("root")({
        Size = Vector2(64, 64),
        BackgroundColor = ARGB(255, 255, 255, 255),
        Skin = mail_bg_Skin,
        Gui.Control({
          Dock = "kDockFill",
          BackgroundColor = ARGB(255, 255, 255, 255),
          Skin = SkinF.personalInfo_092
        }),
        Gui.Button("drag_btn")({
          Dock = "kDockFill",
          BackgroundColor = ARGB(255, 255, 255, 255),
          Visible = false,
          EventClick = function(sender, e)
            ReceiveMailReadAttachments({index})
          end,
          Gui.Label("lbl_icon")({
            Dock = "kDockFill",
            TextAlign = "kAlignCenterMiddle",
            BackgroundColor = ARGB(0, 255, 255, 255),
            Gui.Label("lbl_number")({
              Dock = "kDockBottom",
              Margin = Vector4(0, 0, 2, 2),
              BackgroundColor = ARGB(0, 0, 0, 0),
              Text = "0",
              TextAlign = "kAlignRightMiddle",
              TextureFont = SkinF.hecheng_number_1
            }),
            Gui.Control("level")({
              Size = Vector2(22, 23),
              Location = Vector2(42, 0),
              BackgroundColor = ComFuc.colw,
              Skin = SkinF.personalInfo_245[1],
              Visible = true,
              ComFuc.ComLabel("level_text", nil, Vector2(22, 12), Vector2(0, 3), 0, 10, ComFuc.colw, "kAlignCenterMiddle")
            }),
            Gui.Control("skin_ctrl")({
              Size = Vector2(64, 64),
              BackgroundColor = ARGB(255, 255, 255, 255),
              Skin = SkinF.skin_touming,
              EventMouseEnter = function(sender, e)
                sender.Skin = mail_bg_Skin_2
              end,
              EventMouseLeave = function(sender, e)
                sender.Skin = SkinF.skin_touming
              end
            })
          })
        })
      })
    })
  else
    c = Gui.Create()({
      Gui.Control("root")({
        Size = Vector2(64, 64),
        BackgroundColor = ARGB(255, 255, 255, 255),
        Skin = mail_bg_Skin,
        Gui.Control("stamp_btn")({
          Dock = "kDockFill",
          BackgroundColor = ARGB(255, 255, 255, 255),
          Skin = SkinF.personalInfo_092,
          Gui.Control({
            Dock = "kDockFill",
            BackgroundColor = ARGB(255, 255, 255, 255),
            Skin = SkinF.skin_touming,
            EventMouseEnter = function(sender, e)
              sender.Skin = mail_bg_Skin_2
            end,
            EventMouseLeave = function(sender, e)
              sender.Skin = SkinF.skin_touming
            end,
            Gui.FlashNew("flashCtrl")({
              Dock = "kDockFill",
              Skin = mail_bg_Skin_2,
              BackgroundColor = ARGB(255, 255, 255, 255),
              Visible = false
            })
          })
        }),
        Gui.DragBtn("drag_btn")({
          Dock = "kDockFill",
          BackgroundColor = ARGB(255, 255, 255, 255),
          Visible = false,
          EventMouseDown = function(sender, e)
            local s, l, c = ComFuc.GetMoveMesg(sender)
            if sender.IsCapture then
              l = l + Vector2(3, 253)
              local temp = Vector2(8 + 72 * (index - 1), 327) + Vector2(32, 32) + Vector2(7, 84)
              if local_storage_infos and local_storage_infos[index] and local_storage_infos[index].resource then
                ComFuc.ShowMoveControl(s, l, resDir, local_storage_infos[index].resource, local_storage_infos[index].grade, ui_mail_write.moveControl, ui_mail_write.moveControl_son, true)
              end
              locDown = temp + Vector2(3, 253) + Vector2(2, 2)
            else
              EquipButonUp(sender, index)
            end
          end,
          EventMouseMove = function(sender, e)
            if sender.IsCapture then
              OnMouseMove(sender, false, ui_mail_write.moveCard, ui_mail_write.moveControl, true)
            end
          end,
          EventMouseUp = function(sender, e)
            if sender.IsCapture then
              OnMouseMove(sender, false, ui_mail_write.moveCard, ui_mail_write.moveControl, true)
            end
            EquipButonUp(sender, index)
          end,
          Gui.FlashNew("AttachFlash")({
            Dock = "kDockFill",
            Skin = mail_bg_Skin_2,
            BackgroundColor = ARGB(255, 255, 255, 255)
          }),
          Gui.Label("lbl_icon")({
            Dock = "kDockFill",
            TextAlign = "kAlignCenterMiddle",
            BackgroundColor = ARGB(0, 255, 255, 255),
            Gui.Label("lbl_number")({
              Dock = "kDockBottom",
              Margin = Vector4(0, 0, 2, 2),
              BackgroundColor = ARGB(0, 0, 0, 0),
              Text = "0",
              TextAlign = "kAlignRightMiddle",
              TextureFont = SkinF.hecheng_number_1
            }),
            Gui.Control("skin_ctrl")({
              Size = Vector2(64, 64),
              BackgroundColor = ARGB(255, 255, 255, 255),
              Skin = SkinF.skin_touming,
              EventMouseEnter = function(sender, e)
                sender.Skin = mail_bg_Skin_2
              end,
              EventMouseLeave = function(sender, e)
                sender.Skin = SkinF.skin_touming
              end
            })
          })
        })
      })
    })
  end
  c.root.Parent = ctrl_attach
  if config.IsNeedVip and tonumber(type) ~= 1 and (not ComFuc.VIPLevel or 2 > ComFuc.VIPLevel) then
    c.stamp_btn.Hint = GetUTF8Text("tips_social_additional_string_007")
  end
  return c
end

for i = 1, 5 do
  ui_mail_read_attach[i] = CreateAttachItemCtrl(1, i, ui_mail_read.ctrl_attach)
  ui_mail_write_attach[i] = CreateAttachItemCtrl(2, i, ui_mail_write.ctrl_attach)
  if not ComFuc.VIPLevel or 2 > ComFuc.VIPLevel then
    ui_mail_write_attach[i].stamp_btn.Skin = mail_bg_Skin_lock
    if config.IsNeedVip then
      ui_mail_write_attach[i].stamp_btn.Hint = GetUTF8Text("tips_social_additional_string_007")
    end
  else
    ui_mail_write_attach[i].stamp_btn.Hint = ""
  end
end

function IsInAABB(index, location)
  local bRet = false
  for id = 1, #ui_mail_write_attach do
    if index ~= id then
      local vt1 = Vector2(3, 253) + Vector2(8 + 72 * (id - 1), 327) + Vector2(32, 32) + Vector2(7, 84)
      local vtTemp = vt1 - location
      if 32 > vtTemp.x and vtTemp.x > -32 and 32 > vtTemp.y and -32 < vtTemp.y then
        OnAddAttachment(id, local_storage_infos[index], local_storage_types[index])
        return true
      end
    end
  end
  return bRet
end

function EquipButonUp(sender, index)
  gui:PlayAudio("putdown")
  if IsOutsect(locDown, ui_mail_write.moveControl.Location + Vector2(32, 32), ui_mail_write.moveControl.Size) and not IsInAABB(index, ui_mail_write.moveControl.Location + Vector2(32, 32)) then
    ClearMailWriteAttachment(index)
  end
  sender.IsCapture = false
  ui_mail_write.moveControl.Parent = nil
end

function SetDelBtnSEnableState()
  local bEnable = false
  for i, v in pairs(local_mail_list) do
    if v.item.Parent and v.item.Check then
      bEnable = true
    end
  end
  ui_mail_list.btn_del.Enable = bEnable
end

function SetAttachBtnEnableState()
  local bEnable = false
  local bCheck = true
  for i, v in pairs(local_mail_list) do
    if ui_attach_config.rd_chk_attach.Check then
      bCheck = v.item.Check
    end
    if v.item.Parent and v.item:GetIcon(5) and bCheck then
      bEnable = true
    end
  end
  ui_mail_list.btn_attach.Enable = bEnable
end

function CheckMailIsAllOpen()
  local mail_info
  for i, v in pairs(local_mail_list) do
    mail_info = local_mail_list[i].data
    if mail_info.isOpen ~= "Y" then
      return
    end
  end
  Lobby.SetNewMail(true)
end

local total_time, OnTimer = 0, 5
local OnTimer, CheckIsRunTimer = function()
  total_time = total_time + 0.05
  if ui_mail_list.list.ItemCount < MAX_MAIL_COUNT then
    ui.btn_warning.Skin = SkinF.mail_button_004
  else
    ui.btn_warning.Skin = SkinF.mail_button_008
  end
  alfa = math.abs(math.cos(total_time) * 255)
  if alfa < 55 then
    alfa = 55
  end
  ui.btn_warning.BackgroundColor = ARGB(alfa, 255, 255, 255)
end, 1
local CheckIsRunTimer, RefreshMailCount = function()
  if ui_mail_list.list.ItemCount < WARNING_COUNT then
    if timer then
      game.TimerMgr:RemoveTimer(timer)
      timer = nil
      total_time = 0
    end
  elseif not timer then
    timer = game.TimerMgr:AddTimer(0.03)
    timer.EventOnTimer = OnTimer
    total_time = 0
  end
end, Vector4(0, 0, 0, 0)
local RefreshMailCount, DeleteMailNode = function()
  if ui_mail_list.list.ItemCount < WARNING_COUNT then
    ui.btn_warning.Visible = false
  else
    ui.btn_warning.Visible = true
  end
  ui_mail_list.lbl_mail_count.Text = string.format(GetUTF8Text("UI_social_additional_string_003"), ui_mail_list.list.ItemCount, MAX_MAIL_COUNT)
  CheckIsRunTimer()
end, ui_mail_write_attach[i].stamp_btn
local DeleteMailNode, RefreshMailListItem = function(mail_id)
  local item = ui_mail_list.list.SelectedItem
  if item then
    ui_mail_list.list:DeleteNode(item)
    if local_mail_list[mail_id] then
      local_mail_list[mail_id].data = nil
      local_mail_list[mail_id].item.Parent = nil
      local_mail_list[mail_id].item = nil
      local_mail_list[mail_id] = nil
    end
    RefreshMailCount()
  end
end, "stamp_btn"
local RefreshMailListItem, RefreshMailList = function(key, mail_info)
  local list = ui_mail_list.list
  local root = list.RootItem
  if not local_mail_list[key] then
    local_mail_list[key] = {}
    local_mail_list[key].item = list:CreateItem()
  end
  local item = ptr_cast(local_mail_list[key].item)
  local_mail_list[key].data = mail_info
  list:AddExistingItem(root, item)
  item:SetText(0, "")
  item:SetLocation(0, Vector2(12, 18))
  item:SetSize(0, Vector2(24, 24))
  item:SetText(1, "")
  item:SetLocation(1, Vector2(45, 5))
  item:SetSize(1, Vector2(47, 50))
  if mail_info.isSysMail and mail_info.isSysMail == "Y" then
    mail_info.senderName = GetMatchedUTF8Text(mail_info.senderName)
    local subject = GetMatchedUTF8Text(mail_info.subject)
    if subject and 0 < string.len(subject) then
      mail_info.subject = GetMatchedUTF8Text(mail_info.subject)
    end
  end
  if mail_info.isOpen == "Y" then
    item:SetIcon(1, IconsF.MailStatusIcons.MailOn)
  else
    item:SetIcon(1, IconsF.MailStatusIcons.MailOff)
  end
  item:SetText(2, mail_info.senderName)
  if mail_info.isSysMail and mail_info.isSysMail == "Y" then
    item:SetTextColor(2, ARGB(255, 33, 255, 226))
    item:SetHoverTextColor(2, ARGB(255, 104, 255, 235))
    item:SetHighLightTextColor(2, ARGB(255, 104, 255, 235))
  else
    item:SetTextColor(2, ARGB(255, 255, 255, 255))
    item:SetHoverTextColor(2, ARGB(255, 255, 255, 255))
    item:SetHighLightTextColor(2, ARGB(255, 255, 255, 0))
  end
  item:SetLocation(2, Vector2(101, 6))
  item:SetSize(2, Vector2(214, 23))
  item:SetText(3, mail_info.lastDay .. GetUTF8Text("UI_common_Day"))
  if tonumber(mail_info.lastDay) < 4 then
    item:SetTextColor(3, ARGB(255, 255, 90, 63))
    item:SetHoverTextColor(3, ARGB(255, 255, 90, 63))
    item:SetHighLightTextColor(3, ARGB(255, 255, 90, 63))
  else
    item:SetTextColor(3, ARGB(255, 255, 255, 255))
    item:SetHoverTextColor(3, ARGB(255, 255, 255, 255))
    item:SetHighLightTextColor(3, ARGB(255, 255, 255, 0))
  end
  item:SetLocation(3, Vector2(101, 6))
  item:SetSize(3, Vector2(214, 23))
  item:SetText(4, mail_info.subject)
  item:SetTextColor(4, ARGB(255, 255, 255, 255))
  item:SetHoverTextColor(4, ARGB(255, 255, 255, 255))
  item:SetHighLightTextColor(4, ARGB(255, 255, 255, 0))
  item:SetLocation(4, Vector2(101, 28))
  item:SetSize(4, Vector2(220, 23))
  item:SetText(5, "")
  item:SetLocation(5, Vector2(290, 29))
  item:SetSize(5, Vector2(25, 23))
  if mail_info.haveAttachment == "Y" then
    item:SetIcon(5, IconsF.MailStatusIcons.Gift)
  end
  item:SetText(6, key)
  item.Check = ui_mail_list.check_SelectAll.Check
end, "tips_social_additional_string_007"

function RefreshMailList(remove_check)
  local mail_curr_page = 1
  rpc.safecall("mail_list", {
    currentPage = mail_curr_page,
    pageSize = MAX_MAIL_COUNT,
    totalNum = ""
  }, function(data)
    if not data.error then
      for k, v in pairs(local_mail_list) do
        local_mail_list[k].data = nil
        local_mail_list[k].item.Parent = nil
        local_mail_list[k].item = nil
        local_mail_list[k] = nil
      end
      for i, item in ipairs(data.list.emails) do
        RefreshMailListItem(item.id, item)
      end
      RefreshMailCount()
      SetDelBtnSEnableState()
      SetAttachBtnEnableState()
      CheckMailIsAllOpen()
    end
  end)
end

function DeleteMailList(id_list, nCount)
  rpc.safecall("mail_delete", {mids = id_list, all = ""}, function(data)
    if not data.error then
      RefreshMailList(true)
    end
    MessageBox.CloseWaiter()
  end, function(data)
    MessageBox.CloseWaiter()
  end)
end

function ui_mail_list.list.EventSelectItemChange(sender, e)
  if sender.SelectedItem then
    local item = sender.SelectedItem
    ShowMailRead()
    RefreshMailRead(local_mail_list[item:GetText(6)].data)
    item:SetIcon(1, IconsF.MailStatusIcons.MailOn)
    local_mail_list[item:GetText(6)].data.isOpen = "Y"
    CheckMailIsAllOpen()
  end
end

function ui_mail_list.list.EventDoubleClick(sender, e)
  if sender.SelectedItem then
    local item = sender.SelectedItem
    ShowMailRead()
    RefreshMailRead(local_mail_list[item:GetText(6)].data)
    item:SetIcon(1, IconsF.MailStatusIcons.MailOn)
    local_mail_list[item:GetText(6)].data.isOpen = "Y"
    CheckMailIsAllOpen()
  end
end

function ui_mail_list.list.EventCheckChanged(sender, e)
  SetDelBtnSEnableState()
  SetAttachBtnEnableState()
end

function ui_mail_list.btn_del.EventClick(sender, e)
  local id_list = ""
  local mail_count = 0
  local hide_read_mail = false
  local isAttach = false
  for i, v in pairs(local_mail_list) do
    if v.item.Parent and v.item.Check then
      if 0 < mail_count then
        id_list = id_list .. ","
      end
      id_list = id_list .. v.data.id
      if v.item:GetIcon(5) then
        isAttach = true
      end
      if v.item == ui_mail_list.list.SelectedItem then
        hide_read_mail = true
      end
      mail_count = mail_count + 1
    end
  end
  if 0 < mail_count then
    local Msg
    if isAttach then
      Msg = string.format(GetUTF8Text("msgbox_social_additional_string_008"), mail_count)
      MessageBox.ShowWithConfirmCancel(Msg, function(sender, e)
        RpcDeleteMail(hide_read_mail, id_list, mail_count)
      end)
    else
      Msg = string.format(GetUTF8Text("msgbox_social_additional_string_009"), mail_count)
      MessageBox.ShowWithConfirmCancel(Msg, function(sender, e)
        RpcDeleteMail(hide_read_mail, id_list, mail_count)
      end)
    end
  else
    MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1378"))
  end
end

local RpcDeleteMail, AlignAttachConfig = function(hide_read_mail, id_list, mail_count)
  MessageBox.ShowWaiter(GetUTF8Text("msgbox_social_additional_string_010"))
  if hide_read_mail then
    HideMailRead()
  end
  ui_mail_list.btn_del.Enable = false
  DeleteMailList(id_list, mail_count)
end, function(hide_read_mail, id_list, mail_count)
  MessageBox.ShowWaiter(GetUTF8Text("msgbox_social_additional_string_010"))
  if hide_read_mail then
    HideMailRead()
  end
  ui_mail_list.btn_del.Enable = false
  DeleteMailList(id_list, mail_count)
end

function AlignAttachConfig()
  local attach_btn_loc = ui_mail_list.btn_attach_cfg:ClientToScreen(Vector2(0, 0))
  ui_attach_config.root.Location = Vector2(attach_btn_loc.x - 130, attach_btn_loc.y - 121)
end

function ShowAttachConfig()
  ui_attach_config.root.Parent = gui
  ui_attach_config.root.Focused = true
  AlignAttachConfig()
  
  function ui_attach_config.root.EventLeave(sender, e)
    ui_attach_config.root.Parent = nil
  end
end

function ui_mail_list.btn_attach.EventClick(sender, e)
  HideMailRead()
  local id_list = ""
  local mail_count = 0
  local bChecked
  for i, v in pairs(local_mail_list) do
    if ui_attach_config.rd_chk_attach.Check then
      bChecked = v.item.Check
    else
      bChecked = true
    end
    if v.item.Parent and bChecked then
      if 0 < mail_count then
        id_list = id_list .. ","
      end
      id_list = id_list .. v.data.id
      mail_count = mail_count + 1
    end
  end
  if 0 < string.len(id_list) then
    rpc.safecall("mail_detach", {mailIds = id_list}, function(data)
      if not data.error then
        if Lobby.mainBtnPushDown == 1 then
          PersonalInfo.ReflashMail()
        end
        for i, v in pairs(local_mail_list) do
          if ui_attach_config.rd_chk_attach.Check then
            bChecked = v.item.Check
          else
            bChecked = true
          end
          if v.item.Parent and bChecked then
            v.item:SetIcon(5, nil)
            RefreshMailRead(local_mail_list[v.item:GetText(6)].data)
            v.item:SetIcon(1, IconsF.MailStatusIcons.MailOn)
            local_mail_list[v.item:GetText(6)].data.isOpen = "Y"
            CheckMailIsAllOpen()
          end
        end
        SetAttachBtnEnableState()
        MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1301"))
      end
    end, function()
      ReLoadMailList()
      if Lobby.mainBtnPushDown == 1 then
        PersonalInfo.ReflashMail()
      end
    end)
  end
end

local FRIEND_TYPE = 2
local MYFRIEND_GROUP = 1
local OFFLINE = 1
local ONLINE = 2
local INGAMING, AddFriendsGroupItem = 3, Vector4(0, 0, 0, 0)
local AddFriendsGroupItem, RefreshFriendList = function(group_list, online_state, player_level, player_name, player_id)
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
  item:SetTextColor(1, ARGB(255, 255, 255, 255))
  item:SetHighLightTextColor(1, ARGB(255, 62, 26, 1))
  list:AddSubItem(item, player_id)
  list:AddSubItem(item, online_state)
  return item
end, Vector4(0, 0, 0, 0)

function RefreshFriendList()
  local nIndex = 0
  local pItem
  local chat = ptr_cast(game.ChatConnect)
  if not chat then
    return
  end
  ui_friend_list.list:DeleteAll()
  while true do
    pItem = chat:GetFriendGroupItem(FRIEND_TYPE, MYFRIEND_GROUP, 0, nIndex)
    if not pItem then
      break
    end
    AddFriendsGroupItem(ui_friend_list.list, pItem.Online_state, pItem.Player_level, pItem.Player_name, pItem.PlayerID)
    nIndex = nIndex + 1
  end
end

local HideFriendList, AlignFriendList = function()
  ui_friend_list.root.Parent = nil
end, Vector4(0, 0, 0, 0)

function AlignFriendList()
  local friend_btn_loc = ui_mail_write.btn_friends:ClientToScreen(Vector2(0, 0))
  ui_friend_list.root.Location = Vector2(friend_btn_loc.x, friend_btn_loc.y + 33)
end

function ShowFriendList()
  if ui_friend_list.root.Parent == nil then
    ui_friend_list.root.Parent = gui
    ui_friend_list.root.Focused = true
    AlignFriendList()
    
    function ui_friend_list.root.EventLeave(sender, e)
      HideFriendList()
    end
    
    RefreshFriendList()
  else
    HideFriendList()
  end
end

function ui_friend_list.list.EventDoubleClick(sender, e)
  local item = sender.SelectedItem
  if item then
    ui_mail_write.txt_sender.Text = item:GetText(1)
    HideFriendList()
  end
end

local SetAttachCtrlFlash, CalAttachmentNumber = function(bEnable)
  for id = 1, #ui_mail_write_attach do
    ui_mail_write_attach[id].flashCtrl.Visible = bEnable
    ui_mail_write_attach[id].AttachFlash.Visible = bEnable
  end
end, function(bEnable)
  for id = 1, #ui_mail_write_attach do
    ui_mail_write_attach[id].flashCtrl.Visible = bEnable
    ui_mail_write_attach[id].AttachFlash.Visible = bEnable
  end
end

function CalAttachmentNumber()
  local number = tonumber(nMailSendCost)
  for id = 1, #ui_mail_write_attach do
    if ui_mail_write_attach[id].lbl_icon.Icon then
      number = number + nMailAttachSendCost
    end
  end
  number = number or 20
  ui_mail_write.lbl_memory.Text = GetUTF8Text("UI_social_Postage") .. " : " .. number
  ui_mail_write.txt_box.Text = number - tonumber(nMailSendCost)
  if number == tonumber(nMailSendCost) then
    ui_mail_write.btn_attach_over.Enable = false
  else
    ui_mail_write.btn_attach_over.Enable = true
  end
end

function ClearMailWriteAttachment(id)
  if ui_mail_write_attach and ui_mail_write_attach[id] then
    ui_mail_write_attach[id].lbl_icon.Icon = nil
    ui_mail_write_attach[id].lbl_number.Text = ""
    ui_mail_write_attach[id].drag_btn.Visible = false
    if local_storage_infos[id] and local_storage_infos[id].pid then
      MailDepot.SetItemInMail(local_storage_infos[id].pid, false)
    end
    local_storage_infos[id] = nil
    local_storage_types[id] = nil
    CalAttachmentNumber()
  end
end

function ClearAllMailWriteAttachment()
  for i = 1, 5 do
    ClearMailWriteAttachment(i)
  end
  ui_mail_write.txt_box.Text = ""
  ui_mail_write.btn_attach_over.Enable = false
end

local ClearAllMailWrite, RefreshMailWriteAttachment = function()
  ui_mail_write.txt_sender.Text = ""
  ui_mail_write.txt_subject.Text = ""
  ui_mail_write.txt_content.Text = ""
  ClearAllMailWriteAttachment()
  CalAttachmentNumber()
end, function(id)
  if ui_mail_write_attach and ui_mail_write_attach[id] then
    ui_mail_write_attach[id].lbl_icon.Icon = nil
    ui_mail_write_attach[id].lbl_number.Text = ""
    ui_mail_write_attach[id].drag_btn.Visible = false
    if local_storage_infos[id] and local_storage_infos[id].pid then
      MailDepot.SetItemInMail(local_storage_infos[id].pid, false)
    end
    local_storage_infos[id] = nil
    local_storage_types[id] = nil
    CalAttachmentNumber()
  end
end
local RefreshMailWriteAttachment, RemoveExistedMailWriteAttachment = function(id, storage_info, storage_type)
  local nCount = 0
  local strCount = ""
  if storage_info.quantity then
    nCount = tonumber(storage_info.quantity)
  end
  if 0 < nCount then
    strCount = tostring(nCount)
  end
  ui_mail_write_attach[id].lbl_icon.Icon = IconsF.GetLobbySlotIcon(storage_info.resource)
  ui_mail_write_attach[id].lbl_icon.Icon.DisplayType = "kIconTextFullFill"
  ui_mail_write_attach[id].lbl_number.Text = strCount
  local_storage_infos[id] = storage_info
  local_storage_types[id] = storage_type
  ui_mail_write.btn_attach_over.Enable = true
  local img_id = 1
  if storage_type <= 3 then
    img_id = storage_info.grade
  elseif storage_type == 4 then
    img_id = 1
  elseif storage_type == 5 then
    img_id = storage_info.grade
  end
  if 0 < img_id then
    ui_mail_write_attach[id].drag_btn.Visible = true
    ui_mail_write_attach[id].drag_btn.Skin = Gui.ButtonSkin({
      BackgroundImage = Gui.Image("ui/skinF/skin_common_weapon_bg0" .. img_id .. ".tga", Vector4(0, 0, 0, 0))
    })
  end
  ui_mail_write_attach[id].drag_btn.EventRightClick = function(sender, e)
    ClearMailWriteAttachment(id)
  end
  ui_mail_write_attach[id].lbl_icon.EventMouseEnter = function(sender, e)
    ShowDepotTips(ui_mail_write_attach[id].skin_ctrl, storage_info.pid, storage_type, storage_info.pid)
  end, MailDepot.SetItemInMail(storage_info.pid, true)
  CalAttachmentNumber()
end, function(sender, e)
  local item = sender.SelectedItem
  if item then
    ui_mail_write.txt_sender.Text = item:GetText(1)
    HideFriendList()
  end
end

function RemoveExistedMailWriteAttachment(storage_info)
  for id = 1, #ui_mail_write_attach do
    if local_storage_infos[id] and local_storage_infos[id].pid == storage_info.pid then
      ClearMailWriteAttachment(id)
      MailDepot.SetItemInMail(storage_info.pid, false)
      break
    end
  end
  CalAttachmentNumber()
end

function UpdateSysSettingDetail()
  rpc.safecall("mail_sys_detail", {}, function(data)
    if not data.error then
      nMailSendCost = tonumber(data.mailSendCost)
      nMailAttachSendCost = tonumber(data.mailAttachSendCost)
      ui_mail_write.lbl_memory.Text = GetUTF8Text("UI_social_Postage") .. " : " .. nMailSendCost
      nCanSendMailCount = tonumber(data.attachSendMaxNum) - tonumber(data.attachSendNum)
      ui_mail_write.lbl_attachSetting.Text = string.format(GetUTF8Text("UI_social_additional_string_011"), nCanSendMailCount)
      if ComFuc.VIPLevel and ComFuc.VIPLevel > 1 and 0 < nCanSendMailCount then
        ui_mail_write.btn_add_attach.Enable = true
      else
        ui_mail_write.btn_add_attach.Enable = false
      end
    end
  end)
end

function SwitchTab(nIndex)
  if nIndex == 1 then
    ui.btn_readList.PushDown = true
    ui.btn_write.PushDown = false
    ui_mail_list.root.Parent = ui.container
    ui_mail_write.root.Parent = nil
    HideFriendList()
    if MailDepot and MailDepot.Visible() then
      MailDepot.Hide()
      SetAttachCtrlFlash(false)
    end
    RefreshMailList(false)
  else
    ui.btn_readList.PushDown = false
    ui.btn_write.PushDown = true
    HideMailRead()
    ui_mail_list.root.Parent = nil
    ui_mail_write.root.Parent = ui.container
    local bFind = false
    for i = 1, 5 do
      if ui_mail_write_attach[i].lbl_icon.Icon then
        bFind = true
      end
    end
    ui_mail_write.btn_attach_over.Enable = bFind
    UpdateSysSettingDetail()
  end
end

local ui_mail_read.btn_recieve_all.EventClick, AlignMailRead = function(sender, e)
  ReceiveMailReadAttachments({
    1,
    2,
    3,
    4,
    5
  })
end, ui_mail_read.btn_recieve_all

function AlignMailRead()
  local mail_list_loc = ui_mail_list.root:ClientToScreen(Vector2(0, 0))
  ui_mail_read.root.Location = Vector2(mail_list_loc.x + 379, mail_list_loc.y)
end

function ShowMailRead()
  ui_mail_read.root.Parent = gui
  AlignMailRead()
end

function HideMailRead()
  ui_mail_read.root.Parent = nil
end

function RefreshMailRead(mail_info)
  gui:PlayAudio("selecttask")
  rpc.safecall("mail_open", {
    mid = mail_info.id
  }, function(data)
    if not data.error then
      local sendName, subject, content
      if data.mail.isSysMail and data.mail.isSysMail == "Y" then
        sendName = GetMatchedUTF8Text(data.mail.senderName)
        subject = GetMatchedUTF8Text(data.mail.subject)
        if not subject or string.len(subject) < 1 then
          subject = data.mail.subject
        end
        content = GetMatchedUTF8Text(data.mail.content)
        if not content or string.len(content) < 1 then
          content = data.mail.content
        end
      else
        sendName = data.mail.senderName
        subject = data.mail.subject
        content = data.mail.content
      end
      ui_mail_read.lbl_sender.Text = GetUTF8Text("UI_social_additional_string_004")
      ui_mail_read.txt_sender.Text = sendName
      if data.mail.createTime then
        ui_mail_read.txt_time.Text = data.mail.createTime
      else
        ui_mail_read.txt_time.Text = mail_info.createTime
      end
      ui_mail_read.txt_subject.Text = subject
      if data.mail.isSysMail and data.mail.isSysMail == "Y" then
        ui_mail_read.txt_sender.TextColor = ARGB(255, 104, 255, 235)
      else
        ui_mail_read.txt_sender.TextColor = ARGB(255, 255, 255, 255)
      end
      if mail_info.haveAttachement == "Y" then
        ui_mail_read.lbl_icon.Icon = IconsF.MailStatusIcons.Gift
      end
      ui_mail_read.txt_content.Text = content
      local_attachment_list = data.mail.attachment
      local bRet = false
      for i = 1, #ui_mail_read_attach do
        local attach_info = data.mail.attachment[i]
        if attach_info then
          if RefreshMailReadAttachment(i, attach_info) then
            bRet = true
          end
        else
          ClearMailReadAttachment(i)
        end
      end
      ui_mail_read.btn_recieve_all.Enable = bRet
    end
  end)
end

function RefreshMailReadAttachment(id, attach_info)
  local icon
  local quantity = attach_info.quantity
  if attach_info.unitType and attach_info.unitType ~= 3 then
    quantity = 1
  end
  if attach_info.type == 1 then
    print(GetUTF8Text("msgbox_common_num_1376"))
  elseif attach_info.type == 2 then
    local res = attach_info.resource
    if attach_info.subType == 102 then
      local start, endlen = string.find(attach_info.resource, ",")
      if start then
        res = string.sub(attach_info.resource, 2, start - 2)
      else
        res = attach_info.resource
      end
    end
    icon = IconsF.GetLobbySlotIcon(res)
  elseif attach_info.type == 3 then
    icon = IconsF.GetLobbySlotIcon(attach_info.resource)
  elseif attach_info.type == 4 then
    icon = IconsF.GetLobbySlotIcon(attach_info.resource)
  elseif attach_info.type == 5 then
    if attach_info.subType == 1 then
      icon = IconsF.GetLobbySlotIcon("humancard")
    elseif attach_info.subType == 2 then
      icon = IconsF.GetLobbySlotIcon("herocard")
    end
  elseif attach_info.type == 6 then
    if attach_info.subType == 1 then
      icon = IconsF.GetLobbySlotIcon("humancard")
    elseif attach_info.subType == 2 then
      icon = IconsF.GetLobbySlotIcon("herocard")
    end
  elseif attach_info.type == 7 then
    if attach_info.itemId == 1 then
      icon = Gui.Icon("/ui/SkinF/skin_common_icon_gold01.tga")
    elseif attach_info.itemId == 2 then
      icon = Gui.Icon("/ui/SkinF/xingbi.tga")
    elseif attach_info.itemId == 3 then
      icon = Gui.Icon("/ui/SkinF/xunzhang.tga")
    elseif attach_info.itemId == 4 then
      icon = Gui.Icon("/ui/SkinF/duihuanquan.tga")
    end
    quantity = attach_info.quantity
  else
    print("unknown attachment type: " .. attach_info.type)
  end
  if icon then
    icon.DisplayType = "kIconTextFullFill"
    ui_mail_read_attach[id].drag_btn.Visible = true
    local img_id = 1
    if attach_info.grade then
      if attach_info.type <= 4 then
        img_id = attach_info.grade
      elseif attach_info.type == 5 then
        img_id = attach_info.grade
      end
    end
    if img_id < 1 then
      img_id = 1
    end
    ui_mail_read_attach[id].drag_btn.Skin = Gui.ButtonSkin({
      BackgroundImage = Gui.Image("ui/skinF/skin_common_weapon_bg0" .. img_id .. ".tga", Vector4(0, 0, 0, 0))
    })
    ui_mail_read_attach[id].lbl_icon.Icon = icon
    ui_mail_read_attach[id].lbl_number.Text = quantity
    ui_mail_read_attach[id].lbl_icon.Hint = ""
    ui_mail_read_attach[id].level.Visible = false
    if attach_info.refitedNum and attach_info.refitedNum <= 20 and 0 < attach_info.refitedNum then
      ui_mail_read_attach[id].level.Visible = true
      if not Tip then
        require("tip.lua")
      end
      ui_mail_read_attach[id].level.Skin = Tip.GetPlusLevelSkin(attach_info.refitedNum)
      ui_mail_read_attach[id].level_text.Text = attach_info.refitedNum
    end
    ui_mail_read_attach[id].lbl_icon.EventMouseEnter = function(sender, e)
      if attach_info.type ~= 7 then
        ShowDepotTips(ui_mail_read_attach[id].skin_ctrl, attach_info.itemId, attach_info.type, attach_info.itemId)
      elseif attach_info.itemId == 1 then
        ui_mail_read_attach[id].lbl_icon.Hint = GetUTF8Text("msgbox_common_conditionkey_128")
      elseif attach_info.itemId == 2 then
        ui_mail_read_attach[id].lbl_icon.Hint = GetUTF8Text("msgbox_common_conditionkey_129")
      elseif attach_info.itemId == 3 then
        ui_mail_read_attach[id].lbl_icon.Hint = GetUTF8Text("msgbox_common_conditionkey_130")
      elseif attach_info.itemId == 4 then
        ui_mail_read_attach[id].lbl_icon.Hint = GetUTF8Text("msgbox_common_conditionkey_195")
      end
    end
  end
  local_attachment_list[id] = attach_info
  if icon then
    return true
  else
    return false
  end
end

function ClearMailReadAttachment(id)
  ui_mail_read_attach[id].lbl_icon.Icon = nil
  ui_mail_read_attach[id].lbl_number.Text = nil
  ui_mail_read_attach[id].lbl_icon.EventMouseEnter = nil
  ui_mail_read_attach[id].drag_btn.Visible = false
  local_attachment_list[id] = nil
end

function ReceiveMailReadAttachments(id_table)
  local ids = ""
  local gps = 0
  local mbs = 0
  local tbs = 0
  for _, id in ipairs(id_table) do
    local attach_info = local_attachment_list[id]
    if attach_info then
      if attach_info.type == 11 then
        gps = gps + attach_info.quantity
      elseif attach_info.type == 12 then
        mbs = mbs + attach_info.quantity
      elseif attach_info.type == 13 then
        tbs = tbs + attach_info.quantity
      end
      ids = ids .. attach_info.id .. ","
    end
    ui_mail_read_attach[id].drag_btn.Enable = false
  end
  if 0 < string.len(ids) then
    rpc.safecall("mail_detach", {
      attachmentIds = ids,
      GPcount = gps,
      MBcount = mbs,
      TBcount = tbs
    }, function(data)
      if Lobby.mainBtnPushDown == 1 then
        PersonalInfo.ReflashMail()
      end
      for _, id in ipairs(id_table) do
        ClearMailReadAttachment(id)
        ui_mail_read_attach[id].drag_btn.Enable = true
      end
      local bExist = false
      for i = 1, 5 do
        local attach_info = local_attachment_list[i]
        if attach_info then
          bExist = true
        end
      end
      if not bExist then
        local item = ui_mail_list.list.SelectedItem
        if item then
          item:SetIcon(5, nil)
        end
        ui_mail_read.btn_recieve_all.Enable = false
        SetAttachBtnEnableState()
      end
      MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1301"))
    end, function(data)
      for _, id in ipairs(id_table) do
        ui_mail_read_attach[id].drag_btn.Enable = true
      end
      local item = ui_mail_list.list.SelectedItem
      ShowMailRead()
      RefreshMailRead(local_mail_list[item:GetText(6)].data)
    end)
  end
end

function Visible()
  return ui.root.Parent ~= nil
end

function IsMailWriteVisible()
  return Visible() and ui_mail_write.root.Parent ~= nil
end

function OnAddAttachment(id, storage_info, storage_type)
  if not storage_info then
    return
  end
  local res_name
  if storage_type == 2 and storage_info.subtype == 102 then
    local start, endlen = string.find(storage_info.resource, ",")
    if start then
      res_name = string.sub(storage_info.resource, 2, start - 2)
    else
      res_name = storage_info.resource
    end
  elseif storage_type == 5 or storage_type == 6 then
    if storage_info.subType == 1 then
      res_name = "humancard"
    elseif storage_info.subType == 2 then
      res_name = "herocard"
    end
  else
    res_name = storage_info.resource
  end
  local info = Tip.TableCopy(storage_info)
  info.resource = res_name
  if id <= #ui_mail_write_attach then
    if info.isBind == "Y" then
      MessageBox.ShowError(GetUTF8Text("msgbox_common_num_1369"))
      return
    end
    ClearMailWriteAttachment(id)
    RemoveExistedMailWriteAttachment(info)
    RefreshMailWriteAttachment(id, info, storage_type)
  end
end

function Show(MailWin)
  ui.main.Parent = gui
  ui.root.Parent = gui
  CommonUtility.InitLtvHeader(ui_mail_list.list, {
    {
      "",
      45,
      "kAlignCenterMiddle"
    },
    {
      "",
      1,
      "kAlignCenterMiddle"
    },
    {
      "",
      1,
      "kAlignLeftMiddle"
    },
    {
      "",
      1,
      "kAlignRightMiddle"
    },
    {
      "",
      1,
      "kAlignLeftMiddle"
    },
    {
      "",
      281,
      "kAlignCenterMiddle"
    },
    {
      "",
      1,
      "kAlignCenterMiddle"
    }
  })
  CommonUtility.InitLtvHeader(ui_friend_list.list, {
    {
      "",
      32,
      "kAlignLeftMiddle"
    },
    {
      "",
      160,
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
  SwitchTab(1)
  AlignUI()
  ClearAllMailWriteAttachment()
  CheckIsRunTimer()
  for i = 1, 5 do
    if ui_mail_write_attach and ui_mail_write_attach[i] then
      if not ComFuc.VIPLevel or ComFuc.VIPLevel < 2 then
        ui_mail_write_attach[i].stamp_btn.Skin = mail_bg_Skin_lock
        if config.IsNeedVip then
          ui_mail_write_attach[i].stamp_btn.Hint = GetUTF8Text("tips_social_additional_string_007")
        end
      else
        ui_mail_write_attach[i].stamp_btn.Skin = SkinF.personalInfo_092
        ui_mail_write_attach[i].stamp_btn.Hint = ""
      end
    end
  end
  if ComFuc.VIPLevel and 1 < ComFuc.VIPLevel and 0 < nCanSendMailCount then
    ui_mail_write.btn_add_attach.Enable = true
  else
    ui_mail_write.btn_add_attach.Enable = false
  end
end

function Hide()
  ui.root.Parent = nil
  ui.main.Parent = nil
  HideMailRead()
  ClearAllMailWrite()
  if timer then
    game.TimerMgr:RemoveTimer(timer)
    timer = nil
    total_time = 0
  end
end

function AlignUI()
  Gui.Align(ui.root, 3, 253)
end

function ReLoadMailList()
  if Visible() and ui_mail_list.root.Parent ~= nil then
    RefreshMailList(false)
    CheckIsRunTimer()
  end
end
