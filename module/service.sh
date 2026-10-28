#!/system/bin/sh
# HDR Badge for beekeeper (Redmi G Pro 27U / MiTV-MFFU1)
# 轮询系统画质引擎模式，检测到杜比视界/HDR 时通知 helper 弹标
# 兼容任意播放器（VidHub / Kodi / 系统播放器等）

MODDIR=${0%/*}
HELPER_PKG="com.hdrbadge"
LOG="$MODDIR/badge.log"

log() { echo "$(date '+%H:%M:%S') $*" >> "$LOG"; }

# ---------- 等待系统就绪 ----------
until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
sleep 8

# ---------- 首次安装 helper ----------
if [ -f "$MODDIR/helper.apk" ]; then
    if ! pm path $HELPER_PKG >/dev/null 2>&1; then
        pm install -r -t "$MODDIR/helper.apk" >> "$LOG" 2>&1
        sleep 2
    fi
    appops set $HELPER_PKG SYSTEM_ALERT_WINDOW allow >/dev/null 2>&1
fi

log "service started, helper=$([ "$(pm path $HELPER_PKG 2>/dev/null)" ] && echo ok || echo missing)"

# ---------- 状态机 ----------
# picture_mode / picture_mode_dolby 取值（实测映射表）：
#   59 = 杜比视界（播放DV片源时，picture_mode_dolby 同步=59）
#   15 = HDR10（蜘蛛侠实测，picture_list_hdr=1 picture_format=1）
#   7  = 空闲/SDR 桌面
#   其他 null/0 = SDR
# 空闲值依赖 picture_list_hdr=1 区分 HDR10 与桌面

LAST=""

while true; do
    MODE=$(settings get global picture_mode 2>/dev/null)
    MODE_DV=$(settings get global picture_mode_dolby 2>/dev/null)
    LIST_HDR=$(settings get global picture_list_hdr 2>/dev/null)

    # 判定当前状态
    # PC 模式（HDMI 外部输入，前台为 tvplayer/ExternalSourceActivity）一律不弹
    FG=$(dumpsys activity activities 2>/dev/null | grep -m1 'topResumedActivity')
    case "$FG" in
        *ExternalSourceActivity*)
            STATE="pc"
            ;;
        *)
            if [ "$MODE" = "59" ] || [ "$MODE_DV" = "59" ]; then
                STATE="dolby"
            elif [ "$MODE" = "15" ] && [ "$LIST_HDR" = "1" ]; then
                STATE="hdr"
            else
                STATE="sd"
            fi
            ;;
    esac

    if [ "$STATE" != "$LAST" ]; then
        if [ "$STATE" = "dolby" ]; then
            am broadcast -n $HELPER_PKG/.BadgeReceiver -a com.hdrbadge.SHOW --es type dolby >/dev/null 2>&1
            log "DOLBY badge (mode=$MODE dv=$MODE_DV)"
        elif [ "$STATE" = "hdr" ]; then
            am broadcast -n $HELPER_PKG/.BadgeReceiver -a com.hdrbadge.SHOW --es type hdr >/dev/null 2>&1
            log "HDR badge (mode=$MODE hdr=$LIST_HDR)"
        else
            log "SDR (mode=$MODE)"
        fi
        LAST="$STATE"
    fi

    sleep 1
done
