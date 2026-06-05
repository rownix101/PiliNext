# PRD: PiliNext — 硬分叉重新发行版

**状态:** 草案
**日期:** 2026-06-05
**作者:** Rownix

---

## 问题陈述 (Problem Statement)

当前的 PiliNext 是一个功能极其强大的第三方 BiliBili 客户端——但它的强大是以用户体验为代价的。

**对于普通视频观看者来说，这款 App 太难用了：**

1. **决策疲劳** — 200+ 个设置项。用户需要理解 mpv 的 `video-sync` 参数、CDN 提供商选择、和弹簧物理参数（质量/刚度/阻尼）才能"正确"配置 App。大多数人在打开设置页面的瞬间就放弃了。

2. **动画不自然** — 大量动画使用线性曲线（`Curves.linear`），同一过渡的不同属性动画持续时间不一致（不透明度 300ms vs 高度 500ms 同时进行），部分模式直接操作像素偏移而没有任何过渡。动画缺乏「液态感」——没有果冻般的弹性、没有水流般的连贯性、没有真实物体的质量感。用户感知到的不是"流畅"，而是"机械"、"僵硬"、"不跟手"。**基准线：当前线上版本不存在任何 spring-based 动画，所有过渡为 ease-in-out 或 linear。**

3. **交互不符合直觉** — 中区上下滑进入全屏容易误触，三种导航栏实现并存让人困惑，平板布局切换逻辑需要手动配置。底部导航栏本身也有粗糙感——指示器动画生硬，缺少模糊背景，没有那种"高级 App"的质感。

4. **视觉语言平庸** — 虽然是 Material Design 3，但配色过于鲜艳，缺乏高级感。没有毛玻璃效果，没有精致的阴影层次，没有去饱和度的克制调色。看起来像一个"功能齐全的工具"，而不是一个"精致的消费品"。

5. **代码债阻碍迭代** — 2000+ 行单文件视图、三种导航栏共存、自定义 fork 依赖过多、零测试覆盖。平台抽象层充斥着 `if (Platform.isAndroid) ... else if (Platform.isIOS) ...` 的条件分支，导致新功能开发和维护成本居高不下。

**用户想要的是一个"开箱即用"的 BiliBili 客户端——干净、快速、直觉化、有质感。而不是一个需要先读 200 页手册的播放器框架。**

---

## 解决方案 (Solution)

**PiliNext** — 硬分叉自原项目。一个全平台优先（Android / iOS / Linux / macOS / Windows）、以玻璃质感 + 液态动画为核心体验的「意见明确」（opinionated）的 BiliBili 客户端。所有平台享有一致的视觉语言和交互体验。

### 核心设计原则

| 原则 | 含义 |
|------|------|
| **少即是多** | 每个功能/设置进入 App 前，默认答案是"不做"。只有被验证过的高频需求才加。 |
| **智能默认 > 手动配置** | 用户不需要知道 mpv 内部参数。选最好的默认值，不做成设置项。 |
| **液态动画** | 所有动画必须像液体一样流动——有质量、有弹性、有惯性。果冻般的 stretch/squish，水流般的连贯过渡。禁止线性动画，禁止生硬的即时跳变。 |
| **玻璃质感** | 毛玻璃（glassmorphism）为核心视觉语言——背景模糊、半透明层叠、精致的阴影深度。不是平面 Material Design，而是有空间纵深的玻璃层。 |
| **去饱和调色** | 配色走低饱和度、高明度的路线——"高级灰"色调。避免 Material You 的艳丽原色，用克制、优雅的色板。 |
| **全平台优先** | Android / iOS / Linux / macOS / Windows 五平台同等对待。**视觉语言统一，交互跟随平台直觉。** 所有平台共享玻璃质感、液态动画、去饱和调色的视觉 DNA——但交互模式尊重各平台用户习以为常的操作习惯。iOS 用户的感觉应该像 iOS App，Linux 用户的感觉像 Linux App，而非"一个 Flutter App 跑了五个平台"。 |
| **尊重平台直觉** | 每个平台的用户有自己已经学会的交互语言。iOS 用户期望弹性滚动（rubber band），macOS 用户按 ⌘Q 退出，Linux 用户期望跟 GNOME/KDE 一致的快捷键。**我们不和用户的肌肉记忆作对。** 视觉设计可以有自己的主张（玻璃+液态），但交互层尊重平台惯例。具体而言：iOS 的 ScrollPhysics 用 BouncingScrollPhysics、macOS 菜单栏走原生 NSMenu、Windows 标题栏按钮位置不动。 |
| **底部导航所有设备** | 无论手机还是平板，一律使用底部导航。平板不切侧边栏——而是调整底部导航栏的宽度和间距比例。 |
| **3 次点击原则** | 任何核心功能（看视频、发评论、搜内容）不超过 3 次点击可达。 |
| **一个东西只做一种方式** | 不保留多种导航栏实现。选最好的，删掉其余。 |

### 量化目标

- 设置项：200+ → **≤ 30**
- 动画持续时间种类：15+ → **5** (100ms / 150ms / 200ms / 300ms / 500ms)
- 动画曲线：**全部替换为 spring-based**。保留 0 个 ease-in-out 作为主要曲线。
- 导航栏实现：3 → **1**（全新设计，非简单保留现有 FloatingNavigationBar）
- 视频页布局分支：5 → **2**
- Fork 依赖：评估后尽可能减少 50%+

### 兼容性基准线 (Compatibility Baseline)

**覆盖范围：2023 年及以后发布的主流设备。不做历史遗留兼容。**

**目标平台及最低版本：**

| 平台 | 最低 OS 版本 | 理由 | 目标 SDK |
|------|-------------|------|---------|
| Android | 12 (API 31) | 2023 年出货设备最低预装 Android 12 | 35 |
| iOS | 16.0 | iPhone 14 (2022) 是 2023 年仍主力服役的最老设备 | 18.x |
| Linux | Ubuntu 22.04 / glibc 2.35+ | 22.04 LTS 覆盖 2023 后的主流发行版 | — |
| macOS | 13.0 (Ventura) | 2023 年 Mac 最低预装 Ventura | 15.x |
| Windows | 11 (build 22000+) | 2023 年后出货的 PC 预装 Windows 11 | — |

**明确不支持：**
- Android 11 及以下（API ≤ 30）
- iOS 15 及以下
- Windows 10 及以下
- macOS 12 Monterey 及以下
- 32 位架构（armv7, i686）
- 低端 SoC（Unisoc / 早期 MTK 非 G 系列）

**目标设备：**

| 设备类别 | 典型规格 | 注释 |
|---------|---------|------|
| 手机 | 1080p+, 6GB+ RAM, Adreno 6xx / Apple A14+ | 全部玻璃效果开启，标准体验 |
| 折叠屏 | 动态分辨率, 8GB+ RAM | 折叠/展开弹簧过渡 |
| 小平板 | 8"–10", 1200p+ | 平板导航布局 |
| 大平板 | 11"–13", 2K+ | 导航栏居中悬浮 + 内容区双侧留白 |
| 桌面 | 任意分辨率, 窗口化 | 底部导航 + 可选左侧 pill 模式 |

**玻璃效果分级（2023+ 设备均具备硬件加速能力）：**

```
Tier 1 — 全部效果 (旗舰: Adreno 7xx / Apple A16+ / Apple M 系列 / 桌面独显):
  → blur 30px max, 发光效果, 内阴影, 高光渐变
  → 覆盖 ~40% 目标设备

Tier 2 — 标准效果 (主流: Adreno 6xx / Apple A14–A15 / 桌面集显):
  → blur 20px max, 无发光, 无内阴影
  → 覆盖 ~60% 目标设备

不做 Tier 3（无 blur 回退）。
2023 年后的设备 GPU 都能跑 Tier 2。不为了兼容不存在的设备而降低设计标准。

检测方式:
  - Android: Vulkan GPU 型号 → 两级映射表
  - iOS: Metal GPU family → 两级映射表
  - Desktop: GL_RENDERER 字符串 → 关键词匹配
  - 用户可在设置中手动选择 Tier 1/2
```

**性能基准线（Tier 2 设备，即主流 2023 手机）：**

| 指标 | 基准值 | 测量方法 |
|------|-------|---------|
| 冷启动 (first frame) | ≤ 800ms | `flutter run --profile --trace-startup` |
| 热启动 | ≤ 300ms | `flutter run --profile` |
| 页面切换 90th percentile | 0 丢帧 (≤ 16ms/frame) | Skia raster thread trace |
| 毛玻璃导航栏渲染 | ≤ 4ms GPU | Flutter DevTools raster thread |
| 内存 (前台, 含视频播放) | ≤ 400MB | `adb shell dumpsys meminfo` |
| APK 体积 | ≤ 60MB (arm64-v8a) | `flutter build apk --split-per-abi` |
| 桌面内存 (空闲) | ≤ 200MB | 系统任务管理器 |

---

## 用户故事 (User Stories)

### 动画系统

1. 作为一个视频观众，我希望 App 里的所有运动和过渡都有"液态感"——像果冻一样有弹性、像水一样连贯流动，而不是机械地从 A 点移动到 B 点。这样我才会觉得这个 App "高级"。

2. 作为一个视频观众，我希望当我滑动返回时，页面像被弹簧拉着一样自然回弹，速度继承我手指离开时的动量。而不是以固定速度机械关闭。

3. 作为一个视频观众，我希望导航栏切换 Tab 时，指示器像水滴一样"弹"到新位置——有 stretch（拉伸）和 squish（挤压）的变形过程，而不是一个僵硬的平移。

4. 作为一个视频观众，我希望微交互（点赞、收藏、开关切换）有令人愉悦的弹性反馈——图标短暂放大再弹回，像一个被轻按的果冻。

5. 作为一个视频观众，我希望滚动列表时，内容有微妙的视差和惯性感——不是"像素跟着手指走"，而是"内容有质量地在移动"。

### 视觉设计

6. 作为一个注重审美的用户，我希望 App 有毛玻璃效果——导航栏、弹出面板、播放器控制栏都有半透明的背景模糊，能看到下方内容的色彩渗透上来。这让我觉得 App 是"现代"的。

7. 作为一个对色彩敏感的用户，我希望 App 的配色是克制、低饱和度、高级的——像高档香水瓶的配色，而不是儿童玩具的艳丽原色。

8. 作为一个夜间使用的用户，我希望深色模式下的背景不是纯黑（#000000），而是有层次、有微妙差别的深色调——配合玻璃效果，有"深邃"的空间感。

9. 作为一个多设备用户，我希望 App 能完美适配我的所有设备——从 6 寸手机到 13 寸平板到桌面端，导航栏自适应宽度和比例，但始终在底部（桌面端可切换为左侧 pill）。

### 设置系统

10. 作为一个新用户，我希望下载 App 后不需要调整任何设置就能获得良好的观看体验——默认画质自动选最合适的、弹幕大小适中、主题跟随系统。

11. 作为一个普通用户，我希望设置页面简洁到我能在一分钟内浏览完所有选项并理解每一项的作用。

12. 作为一个对弹幕密度敏感的用户，我希望有 3 档预设（少/中/多）来快速调整，而不是研究 11 个独立的滑块。

13. 作为一个经常在移动网络下看视频的用户，我希望 App 能记住我在 WiFi 和蜂窝网络下的不同画质偏好——但我不需要知道 CDN 是什么。

### 导航系统

14. 作为一个手机用户，我希望底部导航栏悬浮在内容上方，有 pill 形状的指示器和毛玻璃背景——并且切换时指示器有果冻般的弹性动画。

15. 作为一个平板用户，我希望导航栏依然在底部（不是侧边栏），但宽度比例和间距做了适配——让我单手也能操作，不需要伸手去够屏幕边缘。

16. 作为一个有社交需求的用户，我希望"消息"是一个一级导航 Tab，而不是藏在二级页面里。

17. 作为一个内容浏览者，我希望能自定义底部导航栏的 Tab 顺序，把最常用的放在第一个。

### 播放器

18. 作为一个视频观众，我希望双击左侧快退、双击右侧快进、左侧上下调亮度、右侧上下调音量——这些手势是直觉的，不需要引导就能发现。

19. 作为一个新用户，我希望能看到一个轻量的手势引导（首次使用时出现，之后不再打扰），告诉我可以在屏幕左右侧滑动调节亮度和音量。

20. 作为一个横屏观看者，我希望视频信息和评论区能自动在视频旁边显示，而不是需要我手动切换布局。

21. 作为一个关注内容本身的用户，我希望播放器控制栏在无操作 3 秒后自动隐藏，并且淡入淡出动画是流畅的——不要突然消失。

22. 作为一个追求质感的人，我希望播放器的控制按钮在按下时有一个微小的弹性缩放——让我感觉"真的按下了一个实体按钮"，而不是触发了软件逻辑。

### 技术基础

23. 作为一个未来的贡献者，我希望核心模块（动画系统、设置系统、导航系统）有测试覆盖，这样我在修改时不会意外破坏现有功能。

24. 作为一个关注性能的用户，我希望 App 启动快、页面切换不掉帧、毛玻璃效果不影响流畅度——玻璃效果不能以牺牲性能为代价。

---

## 实现决策 (Implementation Decisions)

### M1 — 液态动画系统 (Fluid Animation System)

**目标：** 建立一个集中的、以液态物理（果冻/弹簧/流体）为核心的动画 token 系统，全应用统一使用，彻底消除线性动画。

**决策 1.1 — 设计哲学转变**

```
传统 Material Design 动画:
  ease-in-out → 对称加速减速 → "优雅但无个性"
  duration-based → 固定时长，不管运动距离

液态动画 (Fluid Animation):
  spring-based → 质量-弹性-阻尼模型 → "有物理质感"
  velocity-aware → 初始速度影响整体运动 → "跟手"
  stretch-squish → 形变表达力和方向 → "像果冻"
```

**决策 1.2 — 动画 Token 层级**

```
层级 1: 持续时间 (Duration Token)
  - xs:  100ms  (微交互反馈: 涟漪、图标状态切换)
  - sm:  150ms  (小过渡: tooltip、标签切换)
  - md:  200ms  (中过渡: 控制栏显隐、FAB、chip)
  - lg:  300ms  (大过渡: 页面切换、底部弹出、模态)
  - xl:  500ms  (重量级: 导航栏切换、全屏进入/退出)

层级 2: 弹簧预设 (Spring Preset) — 全部使用 SpringDescription
  - spring-snappy:
      mass: 0.8, stiffness: 600, damping: 0.85
      用途: 按钮反馈、开关切换、微交互
      感觉: 轻快、敏捷、有轻微回弹

  - spring-fluid:
      mass: 1.0, stiffness: 350, damping: 0.75
      用途: 页面过渡、面板滑入、模态弹出
      感觉: 液态流动、明显的弹性过冲

  - spring-jelly:
      mass: 1.2, stiffness: 250, damping: 0.65
      用途: 导航栏指示器切换、点赞爆发、通知到达
      感觉: 果冻般 stretch-squish、高弹性、长回弹

  - spring-heavy:
      mass: 1.5, stiffness: 200, damping: 0.9
      用途: 全屏进入/退出、重量级页面切换
      感觉: 有重量感、缓慢但有力、几乎无回弹

  - spring-gentle:
      mass: 0.5, stiffness: 500, damping: 1.0
      用途: 淡入淡出、列表项出现、图片加载完成
      感觉: 轻柔、临界阻尼无回弹、不打扰用户

层级 3: 组合预设 (Animation Preset)
  - fade-in:       opacity 0→1, md, spring-gentle
  - fade-out:      opacity 1→0, sm, spring-gentle
  - slide-up:      translateY(20→0) + fade, lg, spring-fluid
  - slide-down:    translateY(0→20) + fade, md, spring-fluid
  - pop-in:        scale(0.85→1.05→1) + fade, md, spring-jelly
  - pop-out:       scale(1→0.9) + fade, sm, spring-fluid
  - jelly-move:    translate with stretch, xl, spring-jelly
  - icon-bounce:   scale(1→1.3→0.9→1), sm, spring-jelly
```

**决策 1.3 — 导航栏指示器的果冻动画**

这是整个动画系统的标志性实现——导航栏切换时，pill 指示器的运动不应该是僵硬的平移：

```
指示器动画分为三个阶段:
  1. Stretch (拉伸): 指示器从位置A向位置B拉伸 (0-40% duration)
     - 宽度先增长到 (距离*1.3 + 原始宽度)
     - 然后开始向目标位置移动
  2. Overshoot (过冲): 指示器到达位置B后继续滑过 5-8dp (40-70% duration)
     - 宽高比从拉伸态恢复
  3. Settle (回弹): 指示器弹回精确位置B (70-100% duration)
     - 微小的阻尼振荡，1-2 次回弹后稳定

弹簧参数: mass: 1.2, stiffness: 250, damping: 0.65
总时长: ~500ms (但取决于距离，远距离略长)
```

这与 iOS 的 UITabBar 动画类似，但做得更极致——更像果冻，更明显的 stretch-squish。

**决策 1.4 — 实现方式**

- 在 `lib/common/animation/` 下创建独立的动画系统模块
- 提供 `FluidTokens` 类，暴露所有 duration / spring / preset
- 提供 `FluidTransition` widget 封装 `AnimatedBuilder` + `SpringSimulation`
- 提供 `JellyIndicator` widget 实现导航栏的果冻指示器
- 所有 `AnimatedOpacity` 必须显式指定 spring（默认 linear 将被 lint 规则禁止）
- 替换所有裸 `const Duration(milliseconds: X)` 为 token 引用

**决策 1.5 — 需要修复的具体动画问题**

| 当前问题 | 修复方案 |
|---------|---------|
| 顶部栏不透明度 (300ms linear) 和高度 (500ms) 不同步 | 统一为 `lg` (300ms) + `spring-fluid` |
| 选择遮罩不透明度 (200ms linear) 和缩放 (250ms) 不同步 | 统一为 `md` (200ms) + `spring-snappy` |
| 同步模式零动画直接偏移 | 改为实时 spring-driven 跟随，滞后 ≤ 1 帧 |
| 图片淡入 120ms linear | 改为 `sm` (150ms) + `spring-gentle` |
| FAB 动画 100ms | 改为 `md` (200ms) + `spring-snappy` |
| 骨架屏用 setState 驱动 | 改为 `AnimatedBuilder` + `xs` timer |
| 手势返回直接设 controller.value | 改为 `animateTo()` + 继承手势速度 + `spring-fluid` |
| 英雄动画 RectTween 无曲线 | 改为 spring-based RectTween |
| 播放器按钮缺少按下反馈 | 添加 `icon-bounce` preset 到所有控制按钮 |
| 导航栏指示器平移无弹性 | 替换为 `jelly-move` 三阶段果冻动画 |

### M2 — 设置极致精简 (Settings Minimization)

**目标：** 从 200+ 设置精简到 ≤ 30 个。

**决策 2.1 — 删除类目清单**

以下类目的设置**全部移除**，改为硬编码最优默认值：

| 类目 | 删除项数 | 默认行为 |
|------|---------|---------|
| mpv 技术参数 | 6 | mpv 默认值 |
| CDN/网络配置 | 7 | 自动选择 |
| SSL/安全设置 | 4 | 标准 SSL，HTTP/2 开启 |
| 推荐过滤阈值 | 7 | 不做过滤 |
| SponsorBlock 高级 | 7 | 只保留开关 |
| 弹幕高级微调 | 10 | 固定最佳默认，通过预设档调节 |
| 字幕微调 | 6 | 固定最佳默认 |
| 弹簧动画参数 | 1 | 使用 PiliNext spring tokens |
| 视频显示微调 | 8 | 固定开启 |
| 全屏微调 | 8 | 全屏默认横向 |
| 动态微调 | 9 | 默认列表布局 |
| 导航微调 | 8 | 自动隐藏，平板适配 |
| 主题高级 | 6 | 系统跟随 + 自动取色 |
| 跨平台/桌面高级 | 7 | 保持现状，不做优化 |
| 其它微调 | 20 | 固定最佳默认 |
| 高级反诈 | 3 | 默认开启 |
| 评论相关 | 4 | 不做过滤 |
| 播放器进度条/滑动 | 9 | 全部保留手势，固定最佳默认 |

**决策 2.2 — 保留的 ≤ 30 个设置项**

```
[播放]
1. 默认视频画质 (WiFi)
2. 默认视频画质 (蜂窝)
3. 默认播放倍速
4. 倍速列表
5. 后台播放
6. 自动画中画
7. SponsorBlock 自动跳过

[弹幕]
8.  弹幕开关
9.  弹幕密度 (少/中/多 — 3 档预设)
10. 弹幕字号 (小/中/大 — 3 档预设)
11. 弹幕不透明度 (低/中/高 — 3 档预设)
12. 字幕语言偏好

[外观]
13. 主题模式 (浅色/深色/跟随系统)

[导航]
14. 导航栏项目顺序 (拖拽排序)
15. 首页默认 Tab

[内容]
16. 推荐来源 (App 端/WEB 端)
17. 视频页显示相关视频
18. 视频页显示评论
19. 评论排序方式
20. 默认收藏夹

[消息]
21. 消息通知类型
22. 消息角标样式 (数字/红点)

[隐私]
23. 搜索历史记录
24. 搜索建议

[其他]
25. 缓存大小限制
26. 自动清除缓存
27. 触觉反馈
28. 检查更新
29. 语言
30. 重新显示手势引导
```

**决策 2.3 — 预设档替代滑块**

弹幕调节不再使用独立滑块，改用协调的预设档：

```
弹幕密度:  少 (1/3 面积) / 中 (1/2 面积) / 多 (2/3 面积)
弹幕字号:  小 (0.85x) / 中 (1.0x) / 大 (1.15x)
弹幕透明度: 低 (0.4) / 中 (0.7) / 高 (1.0)
```

每个档位内部映射到一套完整的协调参数——字号、行高、描边宽度、持续时间同步变化，而不是用户手动逐个调节。

### M3 — 导航系统重构 (Navigation Redesign)

**目标：** 完全重新设计导航栏，玻璃质感 + 果冻动画 + 所有设备底部导航（桌面端可选转为侧边 pill 布局）。

**决策 3.1 — 删除旧实现**

- 删除 `BottomNavigationBar`（传统实现）
- 删除 M3 `NavigationBar`（Material 3 实现）
- 删除 `FloatingNavigationBar`（当前自定义实现）
- 删除 `NavigationRail` / `NavigationDrawer`（侧边栏实现）
- 删除 `useSideBar`、`optTabletNav`、`enableMYBar`、`floatingNavBar` 等设置

**决策 3.2 — 全新实现：GlassNavigationBar**

从零开始实现一个新的底部导航栏，具备以下特征：

```
视觉层:
  - 毛玻璃背景: BackdropFilter + ImageFilter.blur(sigmaX: 20, sigmaY: 20)
  - 半透明底色: surfaceContainer @ 65% opacity
  - 细边框: 1px outlineVariant @ 8% opacity (模拟玻璃边缘折射)
  - 内阴影: 顶部微弱的白色内阴影 (模拟玻璃厚度)

指示器层:
  - Pill 形状，RoundedSuperellipseBorder
  - 果冻动画 (见 M1 决策 1.3) — stretch → overshoot → settle
  - 颜色: primaryColor @ 20% opacity + 白色高光
  - 微妙的发光效果 (blur + spread)

布局层 — 按设备类型自适应:
  手机 (< 600dp 宽):
    - 位置: 底部悬浮居中
    - 宽度: tabs * 80dp
    - 高度: 64dp
    - 底部间距: 8dp + 系统导航栏高度

  平板 (600dp–1024dp 宽):
    - 位置: 底部悬浮居中
    - 宽度: min(tabs * 120dp, screenWidth * 0.6)
    - 高度: 72dp
    - 底部间距: 12dp + 系统导航栏高度

  桌面 / 大屏 (> 1024dp 宽):
    - 位置: 底部悬浮居中（默认），用户可在设置中切换为"左侧垂直 pill"
    - 底部模式宽度: min(tabs * 140dp, screenWidth * 0.4)
    - 左侧模式: 垂直 pill 列表，居屏幕左侧 16dp，宽度 72dp
    - 高度: 80dp
    - 底部间距: 16dp

  折叠屏:
    - 折叠态 → 手机布局
    - 展开态 → 平板布局
    - 折叠/展开过渡使用 spring-fluid 动画，无跳变

图标层:
  - 选中态: filled variant, weight 600
  - 未选中态: outlined variant, weight 400
  - 过渡: 使用动画的 weight 插值（如果 Flutter 支持）或 cross-fade
```

**决策 3.3 — Tab 结构**

```
当前:  首页 | 动态 | 我的
新:    首页 | 动态 | 消息 | 我的
```

"消息"从二级页面提升为一级 Tab。

**决策 3.4 — 隐藏行为**

- 统一行为：向下滚动隐藏，向上滚动显示
- 使用 spring-fluid 动画，持续时间跟随滚动速度
- 删除 `barHideType` (sync/instant) 设置——只有一个行为
- 删除 `hideTopBar` / `hideBottomBar` 设置——始终自动

### M4 — 视频播放器体验重构 (Player UX Overhaul)

**目标：** 降低实现复杂度，添加质感反馈，保持手势丰富度。

**决策 4.1 — 文件拆分**

```
lib/
  pages/video/
    view.dart              # ~200 行，组装各部件
    controller.dart        # 业务逻辑
    widgets/
      video_player.dart    # 播放器核心
      video_info.dart      # 视频简介
      video_comments.dart  # 评论区
      video_related.dart   # 相关视频
      video_season.dart    # 分P/番剧选集
  plugin/pl_player/
    view/
      player_core.dart     # 播放器渲染
      player_controls.dart # 控制栏（含毛玻璃背景）
      player_gestures.dart # 手势处理
      player_danmaku.dart  # 弹幕层
      player_subtitle.dart # 字幕层
```

拆分原则：每个文件 ≤ 500 行，单一职责，禁止 `part` 指令。

**决策 4.2 — 布局简化**

```
之前: 5 种布局分支
之后: 2 种布局分支
  - 竖屏 (< 560dp 宽 或 竖屏): 播放器在顶部，内容在下方滚动
  - 横屏 (≥ 560dp 宽 且 横屏): 播放器在左侧 (50-70% 宽)，内容在右侧
```

**决策 4.3 — 手势系统**

保留：
- 左侧上下滑 → 亮度
- 右侧上下滑 → 音量
- 水平滑动 → 快进/快退
- 双击左 → 快退 10s
- 双击右 → 快进 10s
- 双击中 → 播放/暂停
- 长按 → 临时 2x

移除：
- 中区上下滑进入/退出全屏（误触率高，改用按钮）
- 双指缩放视频（罕见用例）

实现改善：
- 使用 Flutter 原生 `GestureDetector` 替代自定义 `PlayerScaleGestureRecognizer`
- 手势冲突用 `GestureArena` 解决

**决策 4.4 — 播放器毛玻璃控制栏**

```
控制栏:
  - 背景: BackdropFilter + ImageFilter.blur
  - 按钮: 每个按钮按下时触发 icon-bounce (spring-jelly)
  - 进度条: 拖动时 thumb 放大 (scale 1→1.5, spring-snappy)
  - 显隐动画: 出现 150ms spring-fluid, 消失 200ms spring-gentle
  - 自动隐藏: 3 秒无操作
```

**决策 4.5 — 首次使用引导**

- 半透明毛玻璃 overlay，标注手势区域
- 3 秒后自动消失
- 仅显示一次（Hive 标记）

### M5 — 视觉设计系统 (Visual Design System)

**目标：** 建立以玻璃质感 + 去饱和调色为核心的统一视觉语言。

**决策 5.1 — Glassmorphism 设计规范**

毛玻璃效果是 PiliNext 的核心视觉识别，需要一套一致的规范：

```
玻璃层级 (Glass Depth Levels):

  Level 0 - 内容层 (Content):
    - 无玻璃效果
    - 标准 Material 卡片
    - 用途: 列表内容、视频缩略图

  Level 1 - 悬浮层 (Floating):
    - blur: 12px, opacity: 80%
    - 用途: 导航栏 (GlassNavigationBar)、搜索栏

  Level 2 - 面板层 (Panel):
    - blur: 20px, opacity: 85%
    - 用途: 底部弹出面板、播放器控制栏

  Level 3 - 覆盖层 (Overlay):
    - blur: 30px, opacity: 90%
    - 用途: 模态对话框、全屏图片浏览器背景

边框规范:
  - 所有玻璃层: 1px border, outlineVariant @ 8% opacity
  - 模拟玻璃边缘的折射和厚度感

高光规范:
  - 玻璃层顶部: 微弱的白色渐变 (0% → 2% opacity)
  - 模拟环境光在玻璃表面的反射
```

**决策 5.2 — 去饱和调色板**

告别 Material You 的高饱和度原色，采用克制的调色方案：

```
浅色主题 (Light):
  surface/background:    #F8F7F4 (暖灰白，非纯白)
  surfaceContainer:      #F0EEE9 (微暖灰)
  primary:               #5B6E7A (灰蓝 — 低饱和度，高明度)
  onPrimary:             #FFFFFF
  secondary:             #8B7E74 (暖灰棕)
  tertiary:              #6B8B7A (灰绿)
  error:                 #C4726F (灰玫瑰 — 不刺眼的红色)
  outline:               #D6D3CD (暖灰边框)
  outlineVariant:        #E8E5DF

深色主题 (Dark):
  surface/background:    #1A1B1E (深灰蓝，非纯黑 #000000)
  surfaceContainer:      #232528 (略亮于背景)
  surfaceContainerHigh:  #2D2F33
  primary:               #8DA3B2 (灰蓝 — 低饱和度)
  onPrimary:             #1A1B1E
  secondary:             #B5A89C (暖灰棕)
  tertiary:              #8BA89A (灰绿)
  error:                 #D4908D (灰玫瑰)
  outline:               #3A3C40
  outlineVariant:        #2A2C30

关键: 所有颜色的 chroma/saturation 控制在 15% 以内。
没有饱和度高过 30% 的颜色出现在 UI 中（品牌色除外）。
```

**决策 5.3 — 不再使用 Material You 动态取色**

Material You 的动态取色（Monet）生成的颜色对于 PiliNext 来说过于鲜艳。我们使用固定的、精心设计的手工调色板：

- 删除 `dynamic_color` 依赖
- 删除 `flex_seed_scheme` 依赖
- 删除 `customColor`、`schemeVariant`、`isPureBlackTheme`、`reduceLuxColor` 设置
- 简化 `ThemeUtils.getThemeData()` —— 只处理 light/dark 两个主题，使用固定色板

**决策 5.4 — 排版**

```
字体: 各平台系统默认 — Android: Roboto / Google Sans Text, iOS: SF Pro, Linux: Noto Sans CJK, macOS: SF Pro, Windows: Segoe UI / Microsoft YaHei。不做跨平台字体统一，尊重各平台的原生阅读体验。
标题层级:
  - displayLarge:  32px, weight 400, letterSpacing -0.5
  - headlineMedium: 24px, weight 500, letterSpacing 0
  - titleLarge:    20px, weight 500, letterSpacing 0
  - titleMedium:   16px, weight 500, letterSpacing 0.15
  - bodyLarge:     16px, weight 400, letterSpacing 0.5
  - bodyMedium:    14px, weight 400, letterSpacing 0.25
  - labelLarge:    14px, weight 500, letterSpacing 0.1

圆角系统 (基于 4dp 的倍数):
  - xs:  4dp  (chip, badge)
  - sm:  8dp  (button, input)
  - md:  12dp (card)
  - lg:  16dp (panel, sheet, dialog)
  - xl:  24dp (modal, glass panel)
  - full: 999dp (pill, navigation indicator)
```

**决策 5.5 — 阴影系统**

配合玻璃效果，阴影需要更细腻的表达：

```
Level 0: 无阴影 (内容元素)
Level 1: 0 1px 3px rgba(0,0,0,0.04), 0 1px 2px rgba(0,0,0,0.06)
Level 2: 0 4px 8px rgba(0,0,0,0.04), 0 2px 4px rgba(0,0,0,0.06)
Level 3: 0 8px 24px rgba(0,0,0,0.06), 0 4px 8px rgba(0,0,0,0.04)
Level 4: 0 16px 48px rgba(0,0,0,0.08), 0 8px 16px rgba(0,0,0,0.04)
```

深色模式下的阴影用黑色 + 更高的 opacity（因为没有环境光来"照亮"阴影边缘）。

### M6 — 技术基础 (Technical Foundation)

**目标：** 清理代码债，减少 fork 依赖，建立全平台一致的架构基线。

**决策 6.1 — 平台策略：全平台优先**

所有平台（Android / iOS / Linux / macOS / Windows）平等对待。**视觉语言统一，交互跟随平台直觉。** 核心视觉（玻璃质感、液态动画、去饱和调色）在 Flutter 层统一实现——但交互模式尊重各平台用户的肌肉记忆：

| 平台 | 用户期望的交互习惯 | PiliNext 的做法 |
|------|-------------------|----------------|
| Android | Material 返回箭头、系统返回手势、底部导航 | 跟随 Material Design 交互规范 |
| iOS | 弹性滚动（rubber band）、左滑返回、导航栏标题居中 | BouncingScrollPhysics、左滑手势、尊重 Safe Area |
| Linux | GNOME/KDE 快捷键、CSD 标题栏（可选）、托盘图标 | 桌面通知走 freedesktop、快捷键匹配 DE 约定 |
| macOS | ⌘ 快捷键、菜单栏、窗口关闭在左、弹性滚动 | NSMenu 原生菜单栏、⌘Q/W 等标准快捷键 |
| Windows | Ctrl 快捷键、任务栏托盘、窗口控制按钮在右 | Ctrl 系快捷键、SMTC 媒体控制、系统托盘 |

```
平台策略:
  Android:  全平台核心成员 — 全部新特性首发，深度系统集成，性能优化
  iOS:      全平台核心成员 — 全部新特性首发，深度系统集成，遵守 iOS HIG 底线但不做 Cupertino 模仿
  Linux:    全平台核心成员 — 全部新特性首发，窗口管理、系统托盘、MPRIS 等桌面集成
  macOS:    全平台核心成员 — 全部新特性首发，窗口管理、快捷键、菜单栏集成
  Windows:  全平台核心成员 — 全部新特性首发，窗口管理、系统托盘、任务栏集成
```

代码层面的处理：
- 保留 `ios/`、`linux/`、`macos/`、`windows/` 目录——不删除，持续维护
- **核心设计决策在 Flutter 层统一，不因平台而异。** 玻璃质感、液态动画、去饱和调色在所有平台上表现一致
- 平台专属代码使用能力检测（capability detection）而非平台检测（`Platform.isXXX`）
- 每个平台的系统集成按其自身能力实现，不互相等待——Android edge-to-edge 和 macOS 菜单栏可以独立推进
- 新代码避免新增 `Platform.isXXX` 分支，统一使用抽象接口 + 平台实现

**平台能力矩阵（基线定义）：**

| 能力 | Android | iOS | Linux | macOS | Windows |
|------|---------|-----|-------|-------|---------|
| 玻璃质感 (BackdropFilter) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 液态动画 (Spring) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Edge-to-Edge / 安全区域 | ✅ | ✅ | — | — | — |
| 画中画 (PiP) | ✅ | ✅ | — | — | — |
| 系统通知 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 媒体会话 (锁屏/控制中心) | ✅ | ✅ | ✅ (MPRIS) | ✅ | ✅ |
| 窗口管理 | — | — | ✅ | ✅ | ✅ |
| 系统托盘 | — | — | ✅ | ✅ | ✅ |
| 快捷键体系 | — | — | ✅ | ✅ | ✅ |
| 菜单栏 | — | — | — | ✅ | — |
| Per-app 语言切换 | ✅ | ✅ | — | — | — |
| 动态图标 (Themed Icon) | ✅ | — | — | — | — |
| 预测性返回手势 | ✅ | — | — | — | — |
| 分屏 / 多窗口 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 折叠屏适配 | ✅ | — | — | — | — |

**决策 6.2 — Fork 依赖评估**

| 依赖 | 当前状态 | 决策 |
|------|---------|------|
| `getx` (get) | Fork | **替换为 `riverpod`** — 逐步迁移，新模块用 riverpod |
| `media_kit` | Fork | **评估上游** — 检查上游是否已修复 fork 原因 |
| `cached_network_image` | Fork (ce) | **评估上游** |
| `audio_service` | Fork | **评估上游** — 核心功能，优先测试 |
| `window_manager` | Fork | **评估上游** — 桌面端保留基本窗口管理 |
| `flutter_inappwebview` | Fork | **评估上游** |
| `canvas_danmaku` | Fork | **保留** — 弹幕渲染是差异化功能 |
| `dynamic_color` | 正常 | **删除** — 不再使用 Material You 动态取色 |
| `flex_seed_scheme` | 正常 | **删除** — 使用固定手工调色板 |

**决策 6.3 — 状态管理迁移策略**

GetX → Riverpod 的理由：
- GetX 的 `Get.find<>()` 是隐式依赖，无法追踪、不可测试
- Riverpod 的 `ref.watch()` 是显式依赖，compile-time 可验证
- Riverpod 的 `AsyncValue` 支持 loading/error/data 三态

迁移策略：**渐进式**。
- 新模块（M1-M5 的所有新代码）使用 Riverpod
- 旧模块不改（除非被重构触及）
- 不使用 GetX 的导航——坚持 Flutter 原生 Navigator 2.0 / GoRouter

**决策 6.4 — 国际化规范化**

- 所有硬编码中文字符串迁移到 `.arb` 文件
- 初始支持：简体中文 + 英文
- 架构支持扩展更多语言

**决策 6.5 — 代码组织标准**

- 单文件 ≤ 500 行（硬限制）
- 单 widget ≤ 200 行（软限制）
- 禁止 `part` 指令——用 `export` + 独立文件
- Controller 和 View 必须分离

### M7 — 全平台系统集成 (Platform-specific Integration)

**新增模块。** 每个平台按其自身能力实现系统级集成，作为核心体验的增量叠加。各平台的集成独立推进，不互相阻塞。

**决策 7.1 — Android 专属系统集成**

| 特性 | 用途 | 最低版本 |
|------|------|---------|
| Edge-to-Edge | 全屏内容延伸至状态栏和导航栏下方 | Android 12+ (基线已覆盖) |
| 画中画 (PiP) | 已支持，保留并优化 | Android 12+ (基线已覆盖) |
| 预测性返回手势 | Predictive Back Gesture | Android 14+ |
| 动态图标 (Themed Icon) | Material You 主题图标 | Android 13+ |
| 快捷方式 (Shortcuts) | 长按图标显示常用入口 | Android 12+ (基线已覆盖) |
| 通知通道 | 通知分类管理 | Android 12+ (基线已覆盖) |
| 系统触觉反馈 | HapticConstants 精细振动 | Android 12+ |
| Per-app language | 应用内语言切换 | Android 13+ |
| 媒体会话 (MediaSession) | 锁屏和通知栏媒体控制 | Android 12+ (基线已覆盖) |
| 分屏 / 多窗口 | 自适应布局 | Android 12+ (基线已覆盖) |
| 折叠屏适配 | Foldable 状态检测 | Android 12+ (基线已覆盖) |

**决策 7.2 — iOS 专属系统集成**

| 特性 | 用途 | 最低版本 |
|------|------|---------|
| Safe Area / Home Indicator | 内容避让系统 UI | iOS 16+ (基线已覆盖) |
| 画中画 (PiP) | 视频浮窗播放 | iOS 16+ (基线已覆盖) |
| 系统媒体控制 (MPNowPlaying) | 锁屏和控制中心媒体信息 | iOS 16+ (基线已覆盖) |
| Haptic Touch | 系统级触觉反馈 | iOS 16+ (基线已覆盖) |
| Per-app language | 应用内语言切换 | iOS 16+ (基线已覆盖) |
| 分屏 / Slide Over | iPad 多任务 | iOS 16+ (基线已覆盖) |
| 动态岛 (Dynamic Island) | Live Activities 播放信息 | iOS 16+ |

**决策 7.3 — Linux 专属系统集成**

| 特性 | 用途 |
|------|------|
| MPRIS 媒体控制 | 桌面环境媒体信息和控制 |
| 系统托盘 | 后台播放托盘图标 |
| 通知 (freedesktop) | 系统通知 |
| X11/Wayland 窗口管理 | 窗口位置/大小记忆、全屏 |
| 全局快捷键 | 媒体键 (播放/暂停/下一曲) |

**决策 7.4 — macOS 专属系统集成**

| 特性 | 用途 |
|------|------|
| 菜单栏 (MenuBar) | 应用菜单，快捷键绑定 |
| Now Playing (MPNowPlaying) | 控制中心和 Touch Bar 媒体信息 |
| 系统托盘 | 菜单栏图标 |
| 窗口管理 | 窗口尺寸/位置持久化、全屏 |
| 全局快捷键 | 媒体键 |
| 原生通知 | UserNotifications |

**决策 7.5 — Windows 专属系统集成**

| 特性 | 用途 |
|------|------|
| 系统托盘 | 任务栏托盘图标 |
| 媒体控制 (SMTC) | 锁屏和音量弹窗媒体控制 |
| 窗口管理 | 窗口尺寸/位置/最大化记忆 |
| 全局快捷键 | 媒体键 |
| 原生通知 | Toast 通知 |

**决策 7.6 — 各平台集成的优先级**

平台集成按各自平台独立推进，不设跨平台依赖。但同一特性在不同平台上尽量保持行为一致（如 PiP 在 Android/iOS 上的进入/退出逻辑相同）。

**决策 7.7 — 减少平台条件分支**

使用能力检测（capability detection）而非平台检测：

```dart
// ❌ 避免
if (Platform.isAndroid) { ... }
else if (Platform.isIOS) { ... }

// ✅ 推荐
if (EdgeToEdge.isSupported) { ... }
// 或使用抽象接口，各平台有各自的实现
```

---

## 测试决策 (Testing Decisions)

### 什么值得测试

只测试**外部行为**，不测试实现细节：
- 动画 spring 参数的物理正确性（参数值验证）
- 设置键的读写完整性（设置 → 存储 → 读取 → UI）
- 导航状态正确性（Tab 切换、平板比例调整）
- 播放器手势 → 动作映射
- 玻璃效果的 Token 值正确性（颜色、透明度、模糊值）
- 平台代码正确性（各平台 API 调用验证、能力检测逻辑）

### 哪些模块需要测试

1. **FluidTokens (M1)** — 单元测试验证 spring 参数、duration 常量
2. **设置存储层 (M2)** — 集成测试验证读写、预设档映射
3. **导航状态管理 (M3)** — Widget 测试验证 Tab 切换和布局
4. **播放器手势映射 (M4)** — Widget 测试验证手势区域
5. **视觉 Token (M5)** — 单元测试验证颜色值、圆角、阴影标准
6. **平台工具 (M7)** — 单元测试验证平台能力检测、版本判断、GPU 分级逻辑

### 测试工具

- `flutter_test` (内置)
- `mockito` / `mocktail` 用于依赖隔离
- Arrange-Act-Assert 模式

### 不测试的内容

- 动画视觉效果（肉眼验证）
- Protobuf/gRPC 序列化（自动生成代码）
- 第三方库内部（由库维护者测试）
- 毛玻璃渲染效果（肉眼验证，目标设备范围窄，Tier 1/2 行为稳定）

---

## 超出范围 (Out of Scope)

以下内容明确不在本 PRD 范围内：

1. **新功能开发** — 不添加任何 BiliBili API 未覆盖的新功能。只做减法+重构。
2. **视频播放内核变更** — 不替换 media-kit。播放内核保持，只改外层封装。
3. **gRPC 迁移完成** — 半完成迁移不强制推进，但新模块使用 gRPC。
4. **100% 测试覆盖** — 目标为 7 个核心模块添加基础测试，非覆盖所有页面。
5. **Logo/图标重新设计** — 不重新设计品牌视觉（图标、Logo）。
6. **多语言完整翻译** — 只迁移 ARB + 英文翻译。
7. **CI/CD 变更** — GitHub Actions 工作流保持不变。所有平台构建 job 平等对待，不设优先级差异。
8. **完整的 GetX → Riverpod 迁移** — 只在新模块使用 Riverpod，旧代码不改。

---

## 进一步说明 (Further Notes)

### 关于液态动画的物理原理

传统 ease-in-out 的问题在于它是一条固定路径的数学曲线——不管运动距离多远、不管手势速度多快，动画都走同一条贝塞尔曲线。这在物理上是不可能的。

真实物体（包括液体）遵循：
```
Force → Acceleration → Velocity → Position
```

Spring 动画的优势：
1. **速度继承** — 手势结束时的速度 = 动画初始速度。不会出现"手指离开后画面停一下再动"。
2. **距离自适应** — 同样的 spring 参数，移动 10dp 和 100dp 的时长不同（因为回弹力随位移增大而增大）。而 ease-in-out 是固定 duration，远距离移动会显得"飞过去"。
3. **自然终止** — spring 动画的终点是自然稳定点，不需要手动指定 duration。它"刚好"在物理应该停的时候停下来。
4. **Stretch-Squish** — 果冻效应来自对 widget 施加 scaleX/scaleY 的相位移变形——指示器向某个方向移动时，它在该方向短暂拉伸，然后回弹到正常形状。这是对"液体在容器中移动"的视觉模拟。

### 关于玻璃质感的性能

毛玻璃效果（`BackdropFilter`）有 GPU 开销——需要离屏渲染。但 **2023 年后的所有主流设备 GPU 都具备硬件加速能力**：手机端 Adreno 6xx / Apple A14+ 处理 blur ≤ 4ms raster。桌面端即使是 Intel Iris Xe 集显也绰绰有余。

在这个前提下，因性能恐惧而弱化设计是本末倒置。

优化策略：

1. **只在玻璃元素可见时启用 blur。** 当导航栏被隐藏时，关闭 blur。
2. **限制玻璃层级。** 不超过 3 层玻璃叠加。
3. **使用 `ImageFilter.blur`** —— Flutter 引擎优化版本。
4. **两级 GPU 分级（详见"兼容性基准线"）。** Tier 1 全效果，Tier 2 标准效果。不设 Tier 3（无 blur 回退）——2023+ 设备不需要。用户可手动覆盖 Tier 1/2。
5. **设计先行。** Tier 2 效果（blur 20px）在 100% 的目标设备上流畅运行。不为了不存在的低端设备而降低设计标准。

### 关于多设备导航

"所有设备底部导航"的设计原则背后是对多平台一致性的追求：

**手机 (3.5"–7")** — 底部导航是标准移动模式。悬浮 pill + 毛玻璃 + 果冻动画，距底边 8dp。手指自然落点在下半屏，底部导航最小化拇指位移。

**平板 (7"–13")** — iPad 的 HIG 推崇侧边栏，但这个模式在 Android 平板上并不理想：
- Android 平板多数宽屏横持（16:10），侧边栏占用宝贵的水平阅读空间
- 底部导航保持手机与平板行为一致——用户无需学习两套交互
- 底部导航手指仍在屏幕下半部分，单手操作友好
- 平板模式下加大图标和间距即可，导航栏居中悬浮

**桌面 (≥ 13" 或窗口 > 1024dp)** — 底部导航在超宽屏幕上不再是最优解：
- 27 寸显示器上底部导航离鼠标光标可能很远
- 默认仍用底部导航（保证跨平台一致性），但提供"左侧垂直 pill"选项
- 左侧模式本质是底部导航旋转 90°——同一套逻辑，只是方向变了
- 垂直 pill 的果冻动画改为纵向拉伸（stretch 方向从水平变垂直）

**折叠屏** — 折叠态和展开态无缝切换：
- 折叠态 → 手机布局（< 600dp 分支）
- 展开态 → 平板布局（600dp–1024dp 分支）
- 过渡使用 spring-fluid，无跳变
- 窗口尺寸变化时实时响应，不做 debounce（保证"跟手"）

**平板 / 桌面端内容区适配：**
- 导航栏居中悬浮，宽度按比例调整
- 内容区最大宽度 ~840dp 居中（避免文本行过长影响可读性）
- 大屏留白不填充（不为了铺满而拉伸内容）

### 关于硬分叉维护

硬分叉策略:
1. 原项目的 bug 修复（尤其是 BiliBili API 适配）→ 手动 cherry-pick
2. 原项目的新功能 → 忽略，除非符合 PiliNext 设计原则
3. PiliNext 独有的改动 → 永远不合并回上游

配置:
- 原项目作为 `upstream` remote
- 定期 `git fetch upstream && git log upstream/main --oneline` 扫描
- API 层 (`lib/http/`, `lib/grpc/`) 尽可能保持与上游兼容，降低 cherry-pick 冲突

### 阶段划分

**Phase 1: 基础清理** — M6 (技术清理 + 全平台基线) + M2 (设置精简)
**Phase 2: 体验核心** — M1 (液态动画) + M3 (导航栏重构) + M5 (视觉设计系统)
**Phase 3: 差异化** — M4 (播放器重构) + M7 (各平台系统集成，按平台独立推进)

M1/M3/M5 建议并行推进，因为玻璃导航栏同时涉及动画 (M1)、导航 (M3)、和视觉 (M5) 三个维度。
M7 各平台的系统集成独立推进，不互相阻塞——Android edge-to-edge 和 macOS 菜单栏可以同时开工。

### AI 开发假设

本项目由 AI 全栈驱动开发。以下声明用于校准 PRD 的工程估算预期：

1. **代码生成速度** — 本项目中所有模块（动画系统、导航栏、设置页面、播放器重构等）的代码产出由 AI 完成。传统"人月"估算不适用于本项目。
2. **迭代节奏** — AI 生成 → 人工审查 → 真机验证 → 修正 prompt → 重新生成。瓶颈在"审查+验证"，不在"写代码"。
3. **设计决策仍由人做** — AI 负责实现，但不负责设计判断。本 PRD 中的设计决策（配色、动画参数、布局规则）由人做最终确认。
4. **测试由 AI 生成** — 单元测试、Widget 测试由 AI 以 TDD 方式生成，人工确认覆盖范围。
5. **最低交付定义 (MVP)** — 一周内走通 M1（动画 token）+ M3（导航栏）+ M5（主题色板），可在一个主流手机上运行。其余模块按优先级追加。
