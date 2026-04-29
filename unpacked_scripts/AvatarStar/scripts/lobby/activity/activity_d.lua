module("L_Activity", package.seeall)
require("activityDraw.lua")
local ui = L_ActivityDraw.GetUI()
local actData

function DealActiveList(data)
  actData = data.list
  if #actData == 0 then
    MessageBox.ShowError(GetUTF8Text("tips_common_bill_05"))
  else
    Show(gui)
    local list = ui.ltv_activity_list
    list:DeleteAll()
    local root = list.RootItem
    local item
    for i, v in ipairs(actData) do
      item = list:AddItem(root, "")
      list:AddSubItem(item, GetUTF8Text(v.name))
      list:AddSubItem(item, v.isAchieve and GetUTF8Text("button_common_Complete") or GetUTF8Text("msgbox_common_num_1334"))
      item:SetTextColor(1, ComFuc.colw)
      item:SetTextColor(2, v.isAchieve and ComFuc.coly or ComFuc.colg)
    end
    if actData and #actData ~= 0 then
      SelectItemByIndex(1)
    end
  end
end

function SelectItemByIndex(index)
  ui.ltv_activity_list.SelectedItem = ui.ltv_activity_list:DisplayIndexToItem(index - 1)
end

function ShowDetails(index)
  if actData then
    if actData[index] then
      ui.lbl_name.Text = GetUTF8Text(actData[index].name)
      ui.lbl_details.Text = GetUTF8Text(actData[index].activeContent)
      local s = GetUTF8Text(actData[index].startTime)
      ui.lbl_date_begin.Text = s
      s = GetUTF8Text(actData[index].endTime)
      ui.lbl_date_end.Text = s
      ui.btn_web_details.Enable = true
    else
      ui.lbl_name.Text = ""
      ui.lbl_details.Text = ""
      ui.lbl_date_begin.Text = ""
      ui.lbl_date_end.Text = ""
      ui.btn_web_details.Enable = false
    end
  else
    print("===========Error:no data============")
  end
end

local RpcActiveList, RegisterEvent = function()
  rpc.safecall("list_player_active", nil, DealActiveList)
end, function()
  rpc.safecall("list_player_active", nil, DealActiveList)
end

function RegisterEvent()
  function ui.btn_close.EventClick(sender, e)
    Hide()
  end
  
  function ui.ltv_activity_list.EventSelectItemChange(sender, e)
    if sender.SelectedItem then
      local curIndex = sender:ItemToDisplayIndex(sender.SelectedItem) + 1
      ShowDetails(curIndex)
    else
      ShowDetails(-1)
    end
  end
  
  function ui.btn_web_details.EventClick(sender, e)
    local curIndex = ui.ltv_activity_list:ItemToDisplayIndex(ui.ltv_activity_list.SelectedItem) + 1
    if actData and actData[curIndex] then
      game:OpenUrl(actData[curIndex].activeUrl)
    end
  end
end

RegisterEvent()

function Show(par)
  ui.ctl_root.Parent = par
  Initialize()
end

function Hide()
  Finalize()
  ui.ctl_root.Parent = nil
end

function Initialize()
  print("======================Activity Initialize")
end

function Finalize()
  print("======================Activity Finalize")
  SelectItemByIndex(-1)
  actData = nil
end
