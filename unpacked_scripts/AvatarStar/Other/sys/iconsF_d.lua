module("IconsF", package.seeall)
GameTypeIcons = {
  kTeam = Gui.Icon("/ui/skinF/skin_humaninfo_closebutton_normal.tga"),
  kExplode = Gui.Icon("/ui/skinF/skin_humaninfo_closebutton_normal.tga"),
  kBanner = Gui.Icon("/ui/skinF/skin_humaninfo_closebutton_normal.tga"),
  kZombie = Gui.Icon("/ui/skinF/skin_humaninfo_closebutton_normal.tga"),
  kTeamDead = Gui.Icon("/ui/skinF/skin_icon_tuanzhan.tga"),
  kTreasure = Gui.Icon("/ui/skinF/skin_humaninfo_closebutton_normal.tga"),
  kContention = Gui.Icon("/ui/skinF/skin_icon_zhandian.tga"),
  kHero = Gui.Icon("/ui/skinF/skin_humaninfo_closebutton_normal.tga"),
  kOccupy = Gui.Icon("/ui/skinF/skin_icon_duoqi.tga"),
  kSnatch = Gui.Icon("/ui/skinF/skin_icon_duobao.tga"),
  kNovice = Gui.Icon("/ui/skinF/skin_guild_icon03.tga"),
  kGameTypeKillAll = Gui.Icon("/ui/skinF/skin_icon_jianmie.tga"),
  kGameTypeBlast = Gui.Icon("/ui/skinF/lobby/skin_icon_baopo.tga")
}
RoomStatusIcons = {
  PlayingN = Gui.Icon("/ui/skinF/skin_roomlist_icon01.tga"),
  PlayingA = Gui.Icon("/ui/skinF/skin_roomlist_icon01.tga"),
  WaitingN = Gui.Icon("/ui/skinF/skin_roomlist_icon04.tga"),
  WaitingA = Gui.Icon("/ui/skinF/skin_roomlist_icon04.tga"),
  FullN = Gui.Icon("/ui/skinF/skin_roomlist_icon02.tga"),
  FullA = Gui.Icon("/ui/skinF/skin_roomlist_icon02.tga"),
  PasswordN = Gui.Icon("/ui/skinF/skin_roomlist_icon03.tga"),
  PasswordA = Gui.Icon("/ui/skinF/skin_roomlist_icon03.tga"),
  vip_level1 = Gui.Icon("/ui/skinF/skin_vip_lv1.tga"),
  vip_level2 = Gui.Icon("/ui/skinF/skin_vip_lv2.tga"),
  vip_level3 = Gui.Icon("/ui/skinF/skin_vip_lv3.tga"),
  vip_level4 = Gui.Icon("/ui/skinF/skin_vip_lv4.tga"),
  vip_level5 = Gui.Icon("/ui/skinF/skin_vip_lv5.tga"),
  vip_level_temp = Gui.Icon("/ui/skinF/skin_vip_temp.tga"),
  watched = Gui.Icon("/ui/skinF/skin_lianxisai_icon01.tga")
}
PlayerStatusIcons = {
  HostN = Gui.Icon("/ui/skinF/skin_room_icon_host.tga"),
  HostA = Gui.Icon("/ui/skinF/skin_room_icon_host.tga"),
  ReadyN = Gui.Icon("/ui/skinF/skin_room_icon_ready.tga"),
  ReadyA = Gui.Icon("/ui/skinF/skin_room_icon_ready.tga"),
  PlayingN = Gui.Icon("/ui/skinF/skin_room_icon_play.tga"),
  PlayingA = Gui.Icon("/ui/skinF/skin_room_icon_play.tga")
}
PlayerCareerIcons = {
  Gui.Icon("/ui/skinF/skin_common_icon01.tga"),
  Gui.Icon("/ui/skinF/skin_common_icon02.tga"),
  Gui.Icon("/ui/skinF/skin_common_icon03.tga"),
  Gui.Icon("/ui/skinF/skin_common_icon04.tga")
}
SocialityStatusIcons = {
  HeadBg = Gui.Icon("/ui/skinF/skin_common_background06.tga"),
  OnlineN = Gui.Icon("/ui/skinF/skin_gam_humanicon_disabled.tga"),
  OnlineA = Gui.Icon("/ui/skinF/skin_gam_humanicon_normal.tga"),
  PlayingN = nil,
  PlayingA = Gui.Icon("/ui/skinF/skin_gam_playicon.tga")
}
MailStatusIcons = {
  Gift = Gui.Icon("/ui/skinF/skin_mail_icon04.tga"),
  Warning = Gui.Icon("/ui/skinF/skin_mail_icon03.tga"),
  Box = Gui.Icon("/ui/skinF/skin_mail_icon01.tga"),
  MailOn = Gui.Icon("/ui/skinF/skin_mail_icon05.tga"),
  MailOff = Gui.Icon("/ui/skinF/skin_mail_icon06.tga")
}
local LobbySlotIcons = {}

function GetLobbySlotIcon(resource_name)
  if not LobbySlotIcons[resource_name] then
    local icon = Gui.Icon("/ui/SkinF/lobby/" .. resource_name .. ".tga")
    if not icon then
      print("cannot find icon: " .. resource_name)
    else
      LobbySlotIcons[resource_name] = icon
    end
  end
  return LobbySlotIcons[resource_name]
end

local LobbySlotDisableIcons = {}

function GetLobbySlotDisableIcon(resource_name)
  if not LobbySlotDisableIcons[resource_name] then
    LobbySlotDisableIcons[resource_name] = Gui.Icon("/ui/SkinF/lobby/" .. resource_name .. "_disabled.tga")
  end
  return LobbySlotDisableIcons[resource_name]
end

GpIcon = Gui.Icon("/ui/skinF/skin_common_jinbi.tga")
MbIcon = Gui.Icon("/ui/skinF/skin_common_xingbi.tga")
TbIcon = Gui.Icon("/ui/skinF/skin_common_xunzhang.tga")
TkIcon = Gui.Icon("/ui/skinF/skin_common_duihuanquan.tga")
BigGpIcon = Gui.Icon("/ui/skinF/skin_common_icon_gold01.tga")
BigMbIcon = Gui.Icon("/ui/skinF/xingbi.tga")
BigTbIcon = Gui.Icon("/ui/skinF/xunzhang.tga")
BigTkIcon = Gui.Icon("/ui/skinF/duihuanquan.tga")
local big_rank_icon = {}
local small_rank_icon = {}
local rank_type = {
  "tong",
  "yin",
  "jin",
  "zuan"
}
for i = 1, 4 do
  if not big_rank_icon[i] then
    big_rank_icon[i] = {}
  end
  if not small_rank_icon[i] then
    small_rank_icon[i] = {}
  end
  for j = 1, 14 do
    big_rank_icon[i][j] = Gui.Icon(string.format("/ui/skinF/skin_junxian_icon_%02d_%s.tga", j, rank_type[i]))
    small_rank_icon[i][j] = Gui.Icon(string.format("/ui/skinF/skin_junxian_icon_s_%02d_%s.tga", j, rank_type[i]))
  end
end

function GetBigRankIcon(i, j)
  return big_rank_icon[i][j]
end

function GetSmallRankIcon(i, j)
  return small_rank_icon[i][j]
end

RankIcons = {
  {
    Gui.Icon("ui/skinF/skin_junxian_icon_s_01_tong.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_02_tong.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_03_tong.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_04_tong.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_05_tong.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_06_tong.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_07_tong.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_08_tong.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_09_tong.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_10_tong.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_11_tong.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_12_tong.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_13_tong.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_14_tong.tga")
  },
  {
    Gui.Icon("ui/skinF/skin_junxian_icon_s_01_yin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_02_yin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_03_yin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_04_yin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_05_yin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_06_yin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_07_yin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_08_yin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_09_yin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_10_yin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_11_yin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_12_yin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_13_yin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_14_yin.tga")
  },
  {
    Gui.Icon("ui/skinF/skin_junxian_icon_s_01_jin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_02_jin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_03_jin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_04_jin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_05_jin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_06_jin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_07_jin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_08_jin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_09_jin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_10_jin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_11_jin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_12_jin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_13_jin.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_14_jin.tga")
  },
  {
    Gui.Icon("ui/skinF/skin_junxian_icon_s_01_zuan.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_02_zuan.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_03_zuan.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_04_zuan.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_05_zuan.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_06_zuan.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_07_zuan.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_08_zuan.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_09_zuan.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_10_zuan.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_11_zuan.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_12_zuan.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_13_zuan.tga"),
    Gui.Icon("ui/skinF/skin_junxian_icon_s_14_zuan.tga")
  }
}
jobIcons = {
  Gui.Icon("ui/skinF/skin_common_icon01.tga"),
  Gui.Icon("ui/skinF/skin_common_icon02.tga"),
  Gui.Icon("ui/skinF/skin_common_icon03.tga"),
  Gui.Icon("ui/skinF/skin_common_icon04.tga")
}
vipIcons = {
  Gui.Icon("/ui/skinF/skin_vip_lv1.tga"),
  Gui.Icon("/ui/skinF/skin_vip_lv2.tga"),
  Gui.Icon("/ui/skinF/skin_vip_lv3.tga"),
  Gui.Icon("/ui/skinF/skin_vip_lv4.tga"),
  Gui.Icon("/ui/skinF/skin_vip_lv5.tga")
}
