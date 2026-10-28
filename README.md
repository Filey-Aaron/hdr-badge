# HDR Badge (beekeeper 杜比/HDR弹标)

让小米/红米电视形态设备（实测：红米 G Pro 27U 2025, beekeeper / MiTV-MFFU1）在**任意播放器**播放杜比视界 / HDR 片源时弹出格式标识。Apple TV 风格黑底药丸标。

## 痛点

小米电视形态固件只有自带播放器才弹杜比/HDR 标。VidHub、Kodi 等第三方播放器播放时画质引擎已正确进入对应模式，却没有任何提示。

## 原理

1. `service.sh`（由 Magisk 开机拉起）每秒轮询画质引擎状态 `settings get global picture_mode`（与系统图像设置页一致）
2. 状态变化时广播唤起隐形 helper（无图标无界面，21KB）
3. helper 在屏幕右上角绘制悬浮标，3 秒淡出

### 状态映射（beekeeper 实测）

| 场景 | picture_mode | 动作 |
|---|---|---|
| 杜比视界片源 | 59 | 弹杜比标 |
| HDR10 片源 | 15（picture_list_hdr=1） | 弹 HDR 标 |
| PC / HDMI 外部输入 | 前台为 `ExternalSourceActivity` | 不弹 |
| SDR / 桌面 | 7 / null | 不弹 |

> 注意：PC 输出杜比时 picture_mode 也是 59，所以必须结合前台应用判断。

## 安装

Magisk → 模块 → 从本地安装 `hdr-badge-v0.6.zip` → 重启。完成。

## 构建

无需 Android Studio，纯命令行（构建工具已内置于 `build-tools/`）：

```bash
bash build-helper.sh
```

产物为 `module/helper.apk`，再打模块包：

```bash
"build-tools/jdk-17.0.20.1+1/bin/jar.exe" cfM hdr-badge.zip -C module module.prop -C module service.sh -C module helper.apk
```

## 目录结构

```
module/        Magisk 模块（module.prop + service.sh + helper.apk）
helper/        helper 应用源码（Android 悬浮窗）
badge_img/     标图素材（SVG 源 + PNG，含 Apple TV 风格药丸合成脚本所用图）
build-helper.sh  一键构建脚本
```

## 自定义

- 标大小/位置/停留时长：`helper/src/com/hdrbadge/BadgeService.java`
- 状态映射：`module/service.sh`
- 其他机型：自行采样 `settings get global picture_mode` 后修改映射表
