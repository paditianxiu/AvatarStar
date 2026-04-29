module("VipPad", package.seeall)
openVipCost = 5000
local vipPadList = {
  line1 = {
    res = "skin_common_xingbi.tga",
    name = GetUTF8Text("UI_store_VIP_pad_line01_row00"),
    row1 = {
      {
        res = "skin_common_xingbi.tga",
        content = "",
        hint = ""
      }
    },
    row2 = {
      {
        res = "skin_common_xingbi.tga",
        content = "",
        hint = ""
      }
    },
    row3 = {
      {
        res = "skin_common_xingbi.tga",
        content = "",
        hint = ""
      }
    },
    row4 = {
      {
        res = "skin_common_xingbi.tga",
        content = "",
        hint = ""
      }
    },
    row5 = {
      {
        res = "skin_common_xingbi.tga",
        content = "",
        hint = ""
      }
    },
    row6 = {
      {
        res = "skin_common_xingbi.tga",
        content = "",
        hint = ""
      }
    },
    row7 = {
      {
        res = "skin_common_xingbi.tga",
        content = "",
        hint = ""
      }
    }
  },
  line2 = {
    res = "skin_vip_icon12.tga",
    name = GetUTF8Text("UI_store_VIP_pad_line02_row00"),
    row1 = {
      {
        res = "skin_vip_icon12.tga",
        content = "",
        hint = ""
      }
    },
    row2 = {
      {
        res = "skin_vip_icon12.tga",
        content = "",
        hint = ""
      }
    },
    row3 = {
      {
        res = "skin_vip_icon12.tga",
        content = "",
        hint = ""
      }
    },
    row4 = {
      {
        res = "skin_vip_icon12.tga",
        content = "",
        hint = ""
      }
    },
    row5 = {
      {
        res = "skin_vip_icon12.tga",
        content = "",
        hint = ""
      }
    },
    row6 = {
      {
        res = "skin_vip_icon12.tga",
        content = "",
        hint = ""
      }
    },
    row7 = {
      {
        res = "skin_vip_icon12.tga",
        content = "",
        hint = ""
      }
    }
  },
  line3 = {
    res = "skin_common_jinbi.tga",
    name = GetUTF8Text("id_common_add_Card_01"),
    row1 = {
      {
        res = "skin_common_jinbi.tga",
        content = "",
        hint = ""
      }
    },
    row2 = {
      {
        res = "skin_common_jinbi.tga",
        content = "",
        hint = ""
      }
    },
    row3 = {
      {
        res = "skin_common_jinbi.tga",
        content = "",
        hint = ""
      }
    },
    row4 = {
      {
        res = "skin_common_jinbi.tga",
        content = "",
        hint = ""
      }
    },
    row5 = {
      {
        res = "skin_common_jinbi.tga",
        content = "",
        hint = ""
      }
    },
    row6 = {
      {
        res = "skin_common_jinbi.tga",
        content = "",
        hint = ""
      }
    },
    row7 = {
      {
        res = "skin_common_jinbi.tga",
        content = "",
        hint = ""
      }
    }
  },
  line4 = {
    res = "skin_vip_icon28.tga",
    name = GetUTF8Text("id_common_add_Card_02"),
    row1 = {
      {
        res = "skin_vip_icon28.tga",
        content = "",
        hint = ""
      }
    },
    row2 = {
      {
        res = "skin_vip_icon28.tga",
        content = "",
        hint = ""
      }
    },
    row3 = {
      {
        res = "skin_vip_icon28.tga",
        content = "",
        hint = ""
      }
    },
    row4 = {
      {
        res = "skin_vip_icon28.tga",
        content = "",
        hint = ""
      }
    },
    row5 = {
      {
        res = "skin_vip_icon28.tga",
        content = "",
        hint = ""
      }
    },
    row6 = {
      {
        res = "skin_vip_icon28.tga",
        content = "",
        hint = ""
      }
    },
    row7 = {
      {
        res = "skin_vip_icon28.tga",
        content = "",
        hint = ""
      }
    }
  },
  line5 = {
    res = "skin_vip_icon16.tga",
    name = GetUTF8Text("UI_store_VIP_pad_line04_row00"),
    row1 = {
      {
        res = "skin_vip_icon16.tga",
        content = "",
        hint = ""
      }
    },
    row2 = {
      {
        res = "skin_vip_icon16.tga",
        content = "",
        hint = ""
      }
    },
    row3 = {
      {
        res = "skin_vip_icon16.tga",
        content = "",
        hint = ""
      }
    },
    row4 = {
      {
        res = "skin_vip_icon16.tga",
        content = "",
        hint = ""
      },
      {
        res = "skin_vip_icon27.tga",
        content = "",
        hint = GetUTF8Text("tips_store_AH_open_VIP3")
      }
    },
    row5 = {
      {
        res = "skin_vip_icon16.tga",
        content = "",
        hint = ""
      }
    },
    row6 = {
      {
        res = "skin_vip_icon16.tga",
        content = "",
        hint = ""
      }
    },
    row7 = {
      {
        res = "skin_vip_icon16.tga",
        content = "",
        hint = ""
      }
    }
  },
  line6 = {
    res = "skin_vip_icon17.tga",
    name = GetUTF8Text("UI_store_VIP_pad_line05_row00"),
    row1 = {
      {
        res = "",
        content = "",
        hint = ""
      }
    },
    row2 = {
      {
        res = "skin_vip_icon18.tga",
        content = "+2",
        hint = GetUTF8Text("tips_store_VIP_pad_line05_common")
      }
    },
    row3 = {
      {
        res = "",
        content = "",
        hint = ""
      }
    },
    row4 = {
      {
        res = "",
        content = "",
        hint = ""
      }
    },
    row5 = {
      {
        res = "",
        content = "",
        hint = ""
      }
    },
    row6 = {
      {
        res = "",
        content = "",
        hint = ""
      }
    },
    row7 = {
      {
        res = "",
        content = "",
        hint = ""
      }
    }
  },
  line7 = {
    res = "skin_vip_icon15.tga",
    name = GetUTF8Text("UI_store_VIP_pad_line06_row00"),
    row1 = {
      {
        res = "skin_common_jinbi.tga",
        content = "",
        hint = ""
      }
    },
    row2 = {
      {
        res = "skin_common_jinbi.tga",
        content = "",
        hint = ""
      }
    },
    row3 = {
      {
        res = "skin_common_jinbi.tga",
        content = "",
        hint = ""
      }
    },
    row4 = {
      {
        res = "skin_common_jinbi.tga",
        content = "",
        hint = ""
      }
    },
    row5 = {
      {
        res = "skin_common_jinbi.tga",
        content = "",
        hint = ""
      }
    },
    row6 = {
      {
        res = "skin_common_jinbi.tga",
        content = "",
        hint = ""
      }
    },
    row7 = {
      {
        res = "skin_common_jinbi.tga",
        content = "",
        hint = ""
      }
    }
  },
  line8 = {
    res = "skin_vip_icon19.tga",
    name = GetUTF8Text("UI_store_VIP_pad_line07_row00"),
    row1 = {
      {
        res = "skin_vip_icon22.tga",
        content = "",
        hint = ""
      }
    },
    row2 = {
      {
        res = "skin_vip_icon22.tga",
        content = "",
        hint = ""
      }
    },
    row3 = {
      {
        res = "skin_vip_icon22.tga",
        content = "",
        hint = ""
      }
    },
    row4 = {
      {
        res = "skin_vip_icon22.tga",
        content = "",
        hint = ""
      }
    },
    row5 = {
      {
        res = "skin_vip_icon22.tga",
        content = "",
        hint = ""
      }
    },
    row6 = {
      {
        res = "skin_vip_icon22.tga",
        content = "",
        hint = ""
      }
    },
    row7 = {
      {
        res = "skin_vip_icon22.tga",
        content = "",
        hint = ""
      }
    }
  },
  line9 = {
    res = "skin_vip_icon20.tga",
    name = GetUTF8Text("UI_store_VIP_pad_line08_row00"),
    row1 = {
      {
        res = "skin_vip_icon21.tga",
        content = "",
        hint = ""
      }
    },
    row2 = {
      {
        res = "skin_vip_icon21.tga",
        content = "",
        hint = ""
      }
    },
    row3 = {
      {
        res = "skin_vip_icon21.tga",
        content = "",
        hint = ""
      }
    },
    row4 = {
      {
        res = "skin_vip_icon21.tga",
        content = "",
        hint = ""
      }
    },
    row5 = {
      {
        res = "skin_vip_icon21.tga",
        content = "",
        hint = ""
      }
    },
    row6 = {
      {
        res = "skin_vip_icon21.tga",
        content = "",
        hint = ""
      }
    },
    row7 = {
      {
        res = "skin_vip_icon21.tga",
        content = "",
        hint = ""
      }
    }
  }
}

function GetVipPadList()
  return vipPadList
end

local openVipLevel = 5

function GetOpenVipLevel()
  return openVipLevel
end

local openVipMesg = {
  [1] = string.format(GetUTF8Text("msgbox_store_VIP_msg_02"), openVipCost),
  [2] = GetUTF8Text("msgbox_store_VIP_msg_06"),
  [3] = GetUTF8Text("msgbox_store_VIP_msg_06"),
  [4] = GetUTF8Text("msgbox_store_VIP_msg_06"),
  [5] = GetUTF8Text("msgbox_store_VIP_msg_06"),
  [6] = GetUTF8Text("msgbox_store_VIP_msg_06")
}

function GetOpenMessage(level)
  if level == 1 then
    return string.format(GetUTF8Text("msgbox_store_VIP_msg_02"), openVipCost)
  end
  return openVipMesg[level]
end

local finishOpenVipMesg = {
  [1] = GetUTF8Text("msgbox_store_VIP_msg_03"),
  [2] = string.format(GetUTF8Text("msgbox_store_VIP_msg_05"), 2),
  [3] = GetUTF8Text("msgbox_store_VIP_3_AH"),
  [4] = string.format(GetUTF8Text("msgbox_store_VIP_msg_05"), 4),
  [5] = string.format(GetUTF8Text("msgbox_store_VIP_msg_05"), 5),
  [6] = GetUTF8Text("tips_store_VIP_msg_07")
}

function GetFinishOpenVipMesg(level)
  return finishOpenVipMesg[level]
end
