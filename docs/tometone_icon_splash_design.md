# 听卷 TomeTone · 应用图标与启动页设计提案

> **状态：提案，待批准。** 未改动任何应用代码或资源。
> 预览与自检工具：`docs/design-preview/icon-splash/`（说明见该目录 `README.md`）
> 依据：`docs/tometone_architecture_requirements.md` §1.1 / §2.8 / §3.4 / §9.1

---

## 0. 一页速览

| 项 | 结论 |
| :--- | :--- |
| Mark 名 | ⚠️ **「卷 · 声纹」已被用户否决**，新方向在 `docs/design-preview/icon-concepts/` 探索。本表及全文的 mark 相关数值**待重算**（清单见文末） |
| 品牌色对 | 墨 `#1E1710` + 金 `#C08A3E`。**不跟随 5 套色盘**，是与色盘正交的固定品牌层 |
| 图标三层 | 全用 VectorDrawable（`anydpi-v26`），**零位图**；mark 外接 ~~Ø52.50dp~~（待重算） |
| 单色层 | 独立简化（去外弧、内弧加粗到 6.5dp），**不带墨盘**、只用 alpha |
| legacy（API 24–25） | 5 档方形 PNG，从 108dp 画布的**中央 72dp 区域**导出（照做，不砍） |
| 启动页 31+ | `windowSplashScreenBackground` + `windowSplashScreenAnimatedIcon=@mipmap/ic_launcher`，零依赖、零动效 |
| 启动页 24–30 | `launch_background.xml`：纯色 + 居中 240dp vector |
| 防白闪 | `NormalTheme.windowBackground` 直接指向 **`@drawable/launch_background`**（同一张记印），**API 24–36 三分支统一** |
| 字标 | **不进启动页**；只在应用内，吃系统衬线回退链 |
| 依赖 / manifest | **0 个新依赖；manifest 零改动** |
| 启动时长 | 不加最小展示时长、不加 AVD → 对 800ms 门禁零影响 |

---

## 1. 意图

### 1.1 只有三件事值得被图标承担

架构文档 §1.1 的定义里，能被一枚 48dp 图标承担的有三件：**「卷」**（长篇、数卷、上千集，是藏馆不是播放列表）、**「听」**（媒介是耳朵）、**「稳」**（本地优先、离线完整、排斥下架，所以要有旧物的分量）。

其余关键词（高保真、沉浸、跨卷连播、阶梯微回退）都是**用起来**才知道的，图标说不动，也不该硬塞。

### 1.2 为什么图标不能跟着色盘变

应用内有五套可切换国风色盘（`app_color_palette.dart`）。图标**不跟着变**，理由不是"做不到"，是三条硬约束：

1. **图标是系统层的固定标识。** 它出现在启动器、最近任务、系统设置、通知、分享面板——这些界面我们一个都控制不了，也不受"用户选了哪套色盘"影响。跟着变，等于在系统界面里不断变换身份。
2. **`anydpi-v26` 是静态资源。** 要变色就得在每次切换时重写 mipmap 并通知启动器刷新图标缓存，代价极高，收益近乎零。
3. **色盘是"氛围"，不是"身份"。** 选其中一套做图标色，等于宣布那套是官方默认、其余四套是二等。

**主张：不与色盘同源，而是与色盘正交 —— 「墨 + 单一强调色」。** 五套色盘讲的都是材质（纸、墨、瓷、竹、木、砂、金），"墨 + 金"是它们的共同底层。代价是图标无法表达"当前是哪套色盘"——这是有意接受的损失（§2.3 第 1 条）。

### 1.3 启动页只负责一件事

**在引擎启动的几百毫秒里，让用户确认"我点对了，而且它已经在跑"。**

不负责品牌宣讲、不显示进度、不加载数据。所以：无文字、无字标、无进度条（§5.5）、无自绘动效（§5.4）。唯一要死磕的指标是**不白闪、不跳变**（§5.3）。

---

## 2. 目标 / 非目标 / 反目标

**目标**

| # | 目标 | 判定 |
| :--- | :--- | :--- |
| G1 | 与同屏播客/音乐/阅读类图标不混淆 | 与 4 个模拟邻居并排能第一眼分辨 |
| G2 | 一枚 mark 同时说清「卷」与「听」 | 遮住名字给 5 人看，≥3 人说得出"书/卷"或"声音" |
| G3 | 满足自适应图标全部尺寸规则，任何遮罩不被切 | 外接 Ø52.50dp < 安全圆 Ø66dp（解析法 + 像素法双验） |
| G4 | 覆盖 API 24 → 36 | 24–25 走 PNG、26+ 走自适应、33+ 走主题图标 |
| G5 | 启动页不白闪、不跳变、不拖慢 | §5.3 四项检查点 + §7 B3 |
| G6 | 零依赖、自适应部分零位图 | `pubspec.yaml` diff 为空；三层全是 vector |
**非目标**：图标内写汉字（CJK 在 48px 成团）；启动页 AVD 动画；多套图标主题；iOS/桌面图标；改 manifest。

**反目标（技术上做出来了，但算失败）**

1. **图标跟着色盘变了。** 一旦迈出去，图标就不再是"系统标识"，而是"应用内的一处皮肤"。
2. **48px 下退化成 `|)`。** 轴杆压到 4dp 以下、弧间隙压到 2dp 以下，就会和任何均衡器图标没区别。
3. **启动页出现文字 / 进度条 / 加载圈。** 任何一样都会把"引擎在跑"变成"应用在等"。
4. **用户看到白闪。** 闪屏是墨、首屏是纸，中间闪过一帧纯白，前 200ms 全部作废。
5. **`flutter analyze` 出新告警，或 `pubspec.yaml` 多依赖。** 这是资源层的事，Dart 层不该有痕迹。
6. **自适应图标变成 15 张 PNG。** 那样就失去了自适应能力，用户改图标形状时会露馅。

---

## 3. 品牌决策

### 3.1 色值与对比度

| 角色 | Hex | 用在哪 | 为什么 |
| :--- | :--- | :--- | :--- |
| 品牌墨 | `#1E1710` | 图标 background、深色启动页底、`launch_mark` 墨盘 | 不是纯黑。带暖褐的松烟墨，浅色桌面上不刺眼，与五套色盘的暖调不打架 |
| 品牌金 | `#C08A3E` | 前景层、单色层（仅 alpha）、深色启动页 mark | 琥珀金。**色相 ≈35°，与默认色盘 primary `#8A5A20`（H≈34°）同族**，但明度从 33% 提到 50%——原色做 4.5dp 细笔画会糊成一团褐 |
| 宣纸 | `#FBF6EC` | 浅色启动页窗口底 | **直接复用 `amberScroll.light.surface`**，不新造色，启动页纸色 = 首屏纸色 |
| 深色首屏底 | `#191510` | **仅作退回方案的备用色**（§5.3 / D15）；正常路径下 `NormalTheme.windowBackground` 用的是下面那张记印 | 复用 `amberScroll.dark.surface`，与首屏同色 |

对比度（WCAG 2.1，由 `tools/mark-geometry-check.js` 计算）：

| 组合 | 值 | 判定 |
| :--- | :--- | :--- |
| 金 `#C08A3E` on 墨 `#1E1710` | **5.86:1** | ✅ 图标唯一正式组合（非文本图形门槛 3:1） |
| 墨 `#1E1710` on 纸 `#FBF6EC` | **16.45:1** | ✅ 浅色启动页的墨盘 / 窗口底 |
| 金 `#C08A3E` on 深色底 `#191510` | **6.01:1** | ✅ 深色形态 |
| 金 `#C08A3E` on 纸 `#FBF6EC` | 2.81:1 | ❌ **禁止**：金纹裸落纸面 |
| 金 `#C08A3E` on 琥珀 primary `#8A5A20` | 1.95:1 | ❌ **禁止**：亮度过近会互相吃掉 |

**一句话规则：品牌金只允许出现在深底上。** 浅色场景一律用"墨盘 + 金纹"这个记印组合。这是对比度硬要求，不是审美偏好。

### 3.2 与「琥珀旧卷」的协调

不同源、但同族、不同档：品牌金与琥珀 primary 同色相、高一个明度档，放在一起像"同一个工匠做的两种材料"。品牌墨比 `onSurface`（`#221A11`）略冷一点点，用来承担"封皮"而不是"正文"的角色。

**应用内若要用品牌色**，优先用色盘的 `onPrimary`/`onSurface`；品牌金只用于"深底上的小面积点睛"（如关于页的一线金），不要拿它做大字或大面积填充。

### 3.3 图形母题

> ⚠️ **mark 已被用户否决，本节数值待新方向定稿后重算。**
> 本节保留的原因：三个「否决方向」的理由对新方向同样有效（它们约束的是**搜索空间**，
> 不是这一版 mark），推荐方向的推导路径也可复用。

**✅ 推荐：「卷 · 声纹」** —— 一轴竖立的卷子（上下圆头轴杆 + 中间卷身），右缘荡出两道同心声波弧。

- 轴杆端头是**圆头**（rx = h/2），这是"卷"的关键笔画：它把一根竖条变成"两头有轴的卷轴"。
- 两道弧的**圆心落在卷身右缘**，所以弧是从卷轴上"长出来"的，不是旁边贴了两个括号。
- 结果：竖着看是**一卷书**，横着读是**一声音**，共用同一个视觉重心。

**❌ 否决 1 · 播放三角**：媒体播放器的通用符号，无法承载"长篇/藏馆"，48px 下与任何播放器撞脸。**它说的是"能放"，不是"藏着多少"。**

**❌ 否决 2 · 耳机**：有声书/播客最饱和的符号，与"卷"无关，细线在圆遮罩里极易糊成一团。**所有人都用，用它就等于放弃被记住。**

**❌ 否决 3 · 等宽竖条均衡器**：语义偏"音乐"而非"长篇朗读"，竖条数量一变就从"声"变"信号"。**竖条在圆遮罩里会退化成条形码。**

（另试过"竖排『听』字"：CJK 在 48px 笔画糊成一团，且品牌名已由字标承担，重复。否决。）

### 3.4 Mark 几何（108dp 画布）

> ⚠️ **mark 已被用户否决，本节数值待新方向定稿后重算。**
> 仍然有效的只有**方法**：组内坐标 = 自然构建位置、重心修正靠整组 `translate`、
> 改任何参数后必须重跑 `tools/mark-geometry-check.js`。**新方向应沿用这套做法，然后重算全部数值。**

组内坐标 = **自然构建位置**，不做手工挪动；视觉重心修正统一由 `translate(1.44 0)` 承担。这样"构造网格"与"交付资源"是同一套数字，可审计。

| 元素 | 几何 |
| :--- | :--- |
| 卷身 | `rect(39, 38, 10, 32) rx 3` |
| 上 / 下轴杆 | `rect(35, 33, 18, 5.5)` / `rect(35, 69.5, 18, 5.5)`，均 `rx 2.75`（= h/2，圆头） |
| 内圈弧 | `r 14, sw 5.5`，圆心 `(49, 54)`，张角 **±58°** |
| 外圈弧 | `r 22, sw 4.5`，圆心 `(49, 54)`，张角 **±58°** |
| 外接盒 | 39.69 × 42dp，垂直居中 |

**五条硬约束（别动）**

1. 轴杆宽度 ≥ 卷身宽度的 **1.6 倍**。低于此，"轴头"读不出来，会变成竖条 + 两个括号。
2. 两弧半径差 ≥ 8dp，**净间隙 ≥ 3dp**。低于 3dp，画布 72px 以下会粘成一片。
3. 最小笔画（外弧 4.5dp）**不得低于 4dp**。
4. 张角**不得小于 ±50°**，否则弧退化成"逗号"，"声"的语义丢失。
5. 卷轴与内弧最短净间隙 **≥ 3dp**，不得相接或重叠。

**视觉重心修正**：mark 墨量水平不对称（左实体卷轴、右两道细弧）。面积加权算出墨量质心在 `x = 52.557`，偏左 **1.443dp**，不修正眼睛会觉得图标"往左倒"。修正 = **整组右移 1.44dp**（不是挪某条边，那会破坏内部比例）。修正后质心 `54.000`，残差 0.000dp；垂直方向上下对称，修正量 0。

这数字不是手感，是 `tools/mark-geometry-check.js` 复算的。**改任何几何参数后必须重跑该脚本，并把新的 CORRECTION 抄回资源。**

### 3.5 备选（若推翻推荐）

| 备选 | 得到 | 失去 |
| :--- | :--- | :--- |
| **B1 只留卷**（去弧） | 更静、更像藏馆，单色层更干净 | 丢了「听」，可能被误读成阅读器 |
| **B2 卷 + 弦**（横穿 5 条细弦） | 国风浓度最高 | 5 条细线 48px 必糊；单色层几乎无法简化 |
| **B3 宣纸底 + 墨金 mark** | 更轻、更"纸"，浅桌面上不像黑砖 | 深色桌面需第二套资源；前景被迫双色；对比度更难达标 |

推荐仍是「卷 · 声纹 + 墨盘」：B3 的"更轻"是唯一有说服力的动机，但代价（多一套明暗变体 + 前景被迫两色）远大于收益；而墨盘带来的重量感，对自称"藏馆"的产品是资产不是负担。

---

## 4. 自适应（分层）图标规范

### 4.1 尺寸模型

```
┌ 108 × 108dp 画布 ────────────────────────┐
│  18dp 外圈带：系统可能裁掉 / 用于视差      │
│  ┌ 72 × 72dp 可见区 ──────────────┐      │
│  │      ╭──── Ø66dp 安全圆 ────╮   │      │
│  │      │   ╭─ Ø62dp 关键核心 ─╮│   │      │
│  │      │   │      mark       ││   │      │
│  │      │   ╰─────────────────╯│   │      │
│  │      ╰──────────────────────╯   │      │
│  └─────────────────────────────────┘      │
└───────────────────────────────────────────┘
```

| 概念 | 数值 | 含义 |
| :--- | :--- | :--- |
| 画布 | 108 × 108dp | 三层资源统一的坐标系 |
| 可见区 | 72 × 72dp（居中） | 遮罩后**必定**保留。外侧 18dp 被切或用于视差 |
| 官方安全圆 | Ø66dp | Google 建议关键内容落在此 |
| 关键核心（自定） | Ø62dp | 我们加的**激进裁切保险线**：有些 ROM/第三方启动器裁得比 Ø66 更狠 |

前景内容的惯例缩放比例是 **66/108 ≈ 0.611**（让前景占满 Ø66）。我们等价地**直接把 mark 画成 Ø52.50dp**，落在同一位置。

### 4.2 mark 落在哪（已验证）

> ⚠️ **mark 已被用户否决，本节数值待新方向定稿后重算。**
> 仍然有效的是**口径与判定方法**：外接怎么算、余量留多少（≥4dp）、两条独立验证路径
> （解析法 + 像素法）与 0.8dp 抗锯齿容差。新方向按同一套重跑即可。

| 指标 | 数值 | 判定 |
| :--- | :--- | :--- |
| mark 外接直径（含描边外扩，交付坐标） | **Ø52.50dp** | — |
| 距 Ø66 安全圆余量 | **6.75dp** | PASS |
| 距 Ø62 关键核心余量 | **4.75dp** | PASS |
| 墨量质心偏移（修正后） | 0.000dp | PASS |
| 最小笔画 / 两弧净间隙 | 4.5dp / 3.00dp | — |
| 单色层外接直径 | **Ø52.50dp** | 与前景层一致 |

余量 6.75dp 是**有意的**：足以吸收「ROM 裁得更狠」「启动器加描边/阴影」「蒙版比圆形更激进」三类真实意外。

> **不要为了"填满"把 mark 放大。** 一旦外接超过 Ø58dp，激进裁切就不再安全，而 48dp 下的观感提升几乎为零。

两条互相独立的验证路径，都必须 PASS：

```powershell
node   tools/mark-geometry-check.js                            # 解析法：几何求极值
python tools/render-extent-check.py preview/master-render.png  # 像素法：量渲染结果
```

实测一致性：解析 `26.251dp`、像素 `26.686dp`，偏差 +0.435dp（抗锯齿，容差 0.8dp）。

### 4.3 遮罩自检

> ⚠️ **mark 已被用户否决，本节数值待新方向定稿后重算。**
> 仍然有效的是**四种遮罩的口径与三条硬性结论**（不得被切 / 不得贴边 / 不得靠负空间传信息）——
> 它们是所有候选 mark 都要过的门，与具体形状无关。

`preview/icon-preview.png` §1 是 4 遮罩 × 4 尺寸 = 16 格，逐格看：

| 遮罩 | 定义（108 坐标系） | 结论 |
| :--- | :--- | :--- |
| 圆形 | `circle r=54` | 无损。唯一约束是安全圆，已满足 |
| Squircle | 超椭圆 n=4 | 无损。四角内收最大约 12dp，远小于 18dp 外圈带 |
| 圆角方 | `rx = 24` | 无损。四角是直线代替弧，比圆形**更宽松** |
| **Ø66 极限裁切** | `circle r=33`（只留安全圆） | 无损，余量 6.75dp。这是"激进 ROM"的极端情形 |

**三条硬性结论：**

1. **不得被切。** 依据：外接 Ø52.50dp < Ø66dp，与遮罩形状无关——所有合法遮罩至少保留 72dp 可见区，最狠的也不会切进 Ø66。
2. **不得"贴边"。** 距安全圆 6.75dp、距关键核心 4.75dp，两块余量都 ≥4dp。贴边（元素边缘距安全圆 <2dp）会让遮罩的抗锯齿啃掉笔画。
3. **不得靠负空间传信息。** 语义全靠正向笔画（卷轴的实心形状 + 弧的实心笔画），不依赖镂空或留白——因为背景色在单色层里根本不存在。这是它能在 themed icon 下存活的原因。

### 4.4 三层的产出

**推荐：全用 VectorDrawable，不产出任何自适应图标位图。** 一套资源覆盖所有密度与形状变体，体积以字节计。

| 层 | 路径（**待新增**） | 要点 |
| :--- | :--- | :--- |
| 前景 | `android/app/src/main/res/drawable/ic_launcher_foreground.xml` | 108dp/108 viewport；`translate(1.44 0)` 组内 3 rect + 2 stroke path；全 `#FFC08A3E`；**无底色**、不加 `autoMirrored`（镜像会破坏声波方向） |
| 背景 | `android/app/src/main/res/values/ic_launcher_background.xml` | `<color name="ic_launcher_background">#FF1E1710</color>`。必须满幅出血，不能有透明边（透明边在遮罩下会露出系统底色） |
| 单色 | `android/app/src/main/res/drawable/ic_launcher_monochrome.xml` | 同构但**只有一道弧**、`strokeWidth 6.5`；纯 alpha、不带墨盘 |

```xml
<!-- 待新增 android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml -->
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>
```

`<monochrome>` 是 API 33 引入的，但**放在 `-v26` 文件里是安全的**——API 26–32 会忽略它（Google 官方模板就这么放），不必建 `-v33` 目录。

> **背景层用纯色，不用渐变。** 预览里那层 4% 径向提亮是为了"不死板"，但在 192px 以下肉眼不可见；纯色换来零渲染成本、零 ROM 行为差异、零色带风险。若坚持要渐变：VectorDrawable 的 `<gradient>` 自 API 24 可用，只改背景层一个文件。

**`ic_launcher_round.xml`：默认不做。** 现有 manifest 只有 `android:icon`，没有 `android:roundIcon`。API 26+ 形状由系统遮罩决定；只有 API 24–25 少数"要圆形图标"的启动器会读 `roundIcon`。**不新增 round 文件、不新增 5 张圆 PNG**，换来 manifest 零改动。若要补：内容同上的 `mipmap-anydpi-v26/ic_launcher_round.xml` + manifest 加一行 + 5 张圆 PNG。

### 4.5 单色层（themed icon，API 33+）

系统读 `<monochrome>` 的 **alpha**，用系统 tint 上色、垫系统底色、套系统遮罩。我们的颜色、明暗、渐变**全部失效，只有形状存活**。由此四条规则：

1. **只用 alpha。** 不允许第二种颜色，不允许渐变（alpha 变化在 tint 下会变成"半透的同色"，看起来像脏了）。
2. **绝对不能带墨盘。** 墨盘是"深底 + 亮纹"这个对比关系的一半；单色下描不出这个对比，只会多一块大色块把 mark 闷死。
3. **必须单独简化。** 保留两道弧时，3.00dp 的弧间净间隙在低对比底色上会完全消失，两弧粘成一条粗弧，看起来像"信号强度"。**因此去掉外圈弧、只留一道并加粗到 6.5dp。** 卷身与轴杆与前景层**逐值一致**，保证两层是同一个字形记忆点。
4. **可以不同几何，不可以不同结构。** 删弧、加粗 = 允许；把卷轴换成别的形状、把弧换成三角 = 不允许。

**判断"要不要单独简化"的通则**：mark 只有"实体块 + 大间隙"（间隙 ≥ 笔画宽）时，前景层可直接复用；一旦出现"细笔画 + 细间隙"（间隙 < 1.5 × 笔画宽），必须单独简化，否则必糊。

### 4.6 legacy 兼容（API 24–25）

API 24–25 不支持自适应图标，会回落到位图。

**关键：不要渲染整个 108dp 画布，要渲染它的中央 72dp 区域。** 自适应图标上屏时可见区只有画布的 2/3；legacy 若按整画布渲染，mark 会明显比别人的小一圈。

| 密度 | 文件（**待新增/替换**） | 尺寸 |
| :--- | :--- | :--- |
| mdpi | `mipmap-mdpi/ic_launcher.png` | 48×48 |
| hdpi | `mipmap-hdpi/ic_launcher.png` | 72×72 |
| xhdpi | `mipmap-xhdpi/ic_launcher.png` | 96×96 |
| xxhdpi | `mipmap-xxhdpi/ic_launcher.png` | 144×144 |
| xxxhdpi | `mipmap-xxxhdpi/ic_launcher.png` | 192×192 |

- **形状**：满幅方形、四角不透明。API 24–25 的启动器要么直接用方形，要么自己裁圆；给带透明圆角的设计反而在方形启动器里显得缺角。
- **内容**：墨盘满幅 + 金纹。从 72dp 区域裁切后，mark 在 48px 里约占 35px（73%），与同时代图标分量相当。
- **若提供 `roundIcon`**：再各导一份圆形版（直径 = 上表尺寸，四角透明）。

**什么时候用 `flutter_launcher_icons`，什么时候手写 XML**

| 做法 | 适用 | 态度 |
| :--- | :--- | :--- |
| **手写三层 XML** | 自适应图标 | ✅ **采用**。约 20 行，可加注释（本仓库要求注释到位），完全可控 |
| `flutter_launcher_icons` | 从 1024 母版批量导 5 档 legacy PNG | ⚠️ **可选、一次性**。它会**重写 `mipmap-*/`、可能改 manifest、覆盖 `anydpi-v26/`** |
| `flutter_native_splash` | 启动页 | ❌ **不用**。按模板重写 `launch_background.xml`，且它的"保留时长"正是我们禁止的东西 |

**结论**：legacy 的 5 张 PNG 用一次性方式产出（可用它生成后**只留 PNG、删掉它写的 XML 与 config**，也可从 `src/*.svg` 用任意工具导出），三层 XML **手写**。**并且不要把 `flutter_launcher_icons` 留在 `dev_dependencies`**——否则它就是一个"下次有人随手跑一下就把 `anydpi-v26/` 覆盖掉"的地雷。

### 4.7 深浅色 / 主题图标下的表现

| 系统状态 | 默认（自适应） | themed icon |
| :--- | :--- | :--- |
| 浅色桌面 | 墨盘 + 金纹。**深墨在浅桌面上是"重量级"的**——正是"藏馆/旧卷"要的分量 | 系统浅底 + 系统 tint，形状一致 |
| 深色桌面 | **完全相同的资源**，不做明暗变体；对比更足（6.01:1） | 系统深底 + 系统 tint |
| ROM 强制 tint / 加描边 | 墨盘已是 `#1E1710`，足够深，不会因此变脏；金纹明度留有裕量 | 由系统决定，我们只保证 alpha 轮廓 |

1. **自适应图标不做明暗变体。** 系统不会自动暗化自适应图标，`-night` 在这里也不生效（`drawable-night` 只对普通 drawable 有效）。**一份资源吃两种系统主题**——这是选墨盘而非宣纸底的最大收益。
2. **"强制主题图标时如何不变形"**：变形风险的唯一来源是"单色层照搬前景层"，所以 §4.5 第 3 条是强制项。判定：把 mono 层渲成纯黑剪影，若"卷轴"与"声纹"仍可分辨即合格。
3. **不允许"只在一种模式下好看"**：靠"卷身/轴杆逐值一致"保证两种形态一眼是同一枚 mark。

---

## 5. 启动页规范

### 5.1 Android 12+（API 31+）

系统闪屏由系统绘制，我们只能给四样：**窗口底单色**、**图标**、**图标底色（可选）**、**入场动画长度（可选）**。

**尺寸规则（注意两个分支）**

| 情形 | 画布 | 可见圆 |
| :--- | :--- | :--- |
| **带 icon background** | **240 × 240dp** | **Ø160dp** |
| 不带 icon background | 288 × 288dp | Ø192dp |
| 动画图标（AVD） | 432 × 432dp（=4×108） | 288 × 288dp（=4×72） |

> ⚠️ 修正一处常见误传：**288dp / Ø192dp 属于"不带 icon background"那一支**；带底色时是 240dp / Ø160dp。两者都是"可见圆 = 画布 × 2/3"。本方案走**带 icon background** 那一支。

```xml
<!-- 待新增 android/app/src/main/res/values-v31/styles.xml -->
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <!-- 兼容兜底：平台若忽略下面属性，退化成这套 layer-list -->
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowSplashScreenBackground">@color/splash_window_background</item>
        <!-- 直接指向自适应图标，系统自己决定要不要显示它的墨盘 -->
        <item name="android:windowSplashScreenAnimatedIcon">@mipmap/ic_launcher</item>
        <!-- Android 13+：避免"空白闪屏"。品牌全在 mark 上，不能没有图标 -->
        <item name="android:windowSplashScreenBehavior">icon_preferred</item>
    </style>
</resources>
```

`values-night-v31/styles.xml`（**待新增**）与上面**只差 `parent`**（换 `Theme.Black.NoTitleBar`），其余 item 完全一致——`@color/splash_window_background` 在 night 下自动取墨色。

**`windowSplashScreenIconBackgroundColor`：我们故意不设。** 官方文档对自适应图标有一句关键说明——"**如果使用自适应图标，当它与窗口底对比足够时，会显示它的背景层**"。这句话正好给了我们要的两种形态，且由系统自动切换：

| 形态 | 窗口底 | 与墨盘对比 | 系统行为 | 用户看到 |
| :--- | :--- | :--- | :--- | :--- |
| 浅色 | `#FBF6EC` | **16.45:1**（充足） | 显示墨盘 | 金纹嵌在墨盘徽记里，落在纸面上 |
| 深色 | `#1E1710` | **1.00:1**（无对比） | 隐去墨盘 | 金纹直接浮在墨色里 |

**同一份图标资源，两种形态由系统的对比度规则决定，我们不写一行条件代码。** 这也顺手解决了"金纹不能裸落宣纸"的对比度问题——浅色形态永远带着墨盘。

**`postSplashScreenTheme` 说明（诚实版）**：它是 **`androidx.core:core-splashscreen` compat 库**引入的属性（配合 `SplashScreen.installSplashScreen(activity)`），用来声明"闪屏后切哪个主题"。本方案**不引入该依赖**，因此：

- post-splash 的主题切换**由 Flutter 现有机制承担**——manifest 里已有的 `<meta-data android:name="io.flutter.embedding.android.NormalTheme" .../>`；
- 若实现者确认框架级也支持 `android:` 命名空间的同名属性，可以补上（无害），但**不要当必需项，也不要为它加依赖**。

**零依赖的代价**（都可接受）：API 23–30 得不到这套系统闪屏（本来就走 §5.2 分支）；不做自定义退场动画（我们本来就决定不动画，§5.4）；Day/Night 靠 `values-night-v31` 手动组织（成本为 0）。

### 5.2 API 24–30（传统 layer-list）

这段人群（Android 7–11）没有系统闪屏 API，只能给 Activity 窗口设一张背景图，它会一直显示到 Flutter 画出第一帧。

```xml
<!-- 修改 android/app/src/main/res/drawable/launch_background.xml -->
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- ① 窗口底：单色。浅=宣纸 / 夜=墨（靠 values-night 的 colors 切换） -->
    <item android:drawable="@color/splash_window_background"/>
    <!-- ② 居中记印：240dp 见方 = 与 12+ 的 Ø160dp 可见圆逐像素对齐
         注：<item> 的 width/height 需 API 23+，本项目 minSdk 24，安全 -->
    <item
        android:width="240dp"
        android:height="240dp"
        android:gravity="center"
        android:drawable="@drawable/launch_mark"/>
</layer-list>
```

`drawable-v21/launch_background.xml` 与它同步，**或直接删掉那份**——minSdk 已是 24，v21 变体没有存在意义，留着只会让将来调 minSdk 时行为不可预测。

**`launch_mark` 为什么是 240dp**：12+ 把自适应图标放进 240dp 画布 / Ø160dp 可见圆。所以 `launch_mark.xml` 的 viewport 仍是 108×108（与图标同构），但**声明尺寸写 240dp**，墨盘画成 `circle(r=36)`：

- `r=36` → 渲染成 240dp 时是 Ø160dp（36×2/108×240 = 160）✓
- mark 外接 52.50dp → 渲染成 **Ø116.7dp**，与 12+ 上"可见区里 mark 的占比"完全一致

**这样两条分支看起来是同一个画面，而不是两个相似的设计。**

**这个 240dp 对齐同时服务 31+ 的应用窗口**：因为 §5.3 决定让 `NormalTheme.windowBackground`
也指向这张 `launch_background`，系统闪屏（Ø160dp 可见圆）与随后露出的应用窗口底是**同几何、同位置**，
于是「闪屏结束」不再是一次画面切换，而是同一张画面继续存在，直到 Flutter 首帧盖上。

```xml
<!-- 待新增 android/app/src/main/res/drawable/launch_mark.xml（浅色：带墨盘） -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="240dp" android:height="240dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <!-- 墨盘：半径 36 = 自适应图标的 72dp 可见圆 -->
    <path android:fillColor="#FF1E1710"
          android:pathData="M18,54 A36,36 0 1,0 90,54 A36,36 0 1,0 18,54 Z"/>
    <group android:translateX="1.44">
        <!-- 卷身 / 上轴杆 / 下轴杆 / 内弧 / 外弧，与前景层逐值一致 -->
    </group>
</vector>
```

`drawable-night/launch_mark.xml`（**待新增**）内容完全相同，**只删掉墨盘那条 path**。用 `drawable-night` 而不给 path 引用一个会变透明的颜色，是因为前者在任何 API 上都直白可靠，后者要依赖 vector 对 ColorStateList 的支持细节。

### 5.3 不白闪 / 不跳变（唯一会真的做错的地方）

**机制（已按引擎源码修正）**

`FlutterActivity.onCreate()` 的**第一句**就是 `switchLaunchThemeForNormalTheme()`
（`shell/platform/android/io/flutter/embedding/android/FlutterActivity.java`；
`FlutterFragmentActivity.java` 同）。所以主题切换**发生在引擎首帧之前**，而不是之后。
真实时序是：

| 步 | 谁在画 | 画面内容 |
| :--- | :--- | :--- |
| ① | 系统绘制起始窗口（starting window） | `LaunchTheme.windowBackground` = `@drawable/launch_background`（记印） |
| ② | `onCreate()` 第一句切到 `NormalTheme` | 应用窗口底 = `NormalTheme.windowBackground`；**此背景会一直露出到 Flutter 首帧** |
| ③ | Flutter 首帧绘制完成 | Flutter 视图盖住窗口底，露出首屏 |

**关键推论**：① 与 ③ 之间夹着一段「应用窗口底」，而 ② 就在最前面。**如果 ② ≠ ①，这段就是一次可见的画面跳变。**

**结论：让 ② 等于 ①。**
把 `NormalTheme.windowBackground` **直接设为 `@drawable/launch_background`**（含 240dp 记印的那张 layer-list），
**API 24–36 三个分支统一**：

```xml
<!-- 修改 android/app/src/main/res/values/styles.xml（values-night 同步） -->
<style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
    <item name="android:windowBackground">@drawable/launch_background</item>
</style>
```

**为什么这个结论是稳的**：它在两种真实机制下都成立 —— 若系统起始窗口一直撑到 Flutter 首帧，
主题切换根本不可见；若 `NormalTheme` 的底色会露出来，露出的也是同一张记印。
**我们不需要先判定实机到底是哪一种，因为它对两者都成立。** 31+ 的收益顺带兑现：
因为 §5.2 已把 layer-list 的记印对齐成 240dp / Ø160dp，系统闪屏 → 应用窗口是**逐像素接续**的一条画面。

**代价（诚实写）**：首帧很慢时（老旧低端机），静态记印会多停一会儿，观感更接近"卡住"而不是"在跑"。

**为什么接受这个代价**：这正是 §5.4 已经把 AVD 否决掉的同一个理由——低端机上任何动效都会定格成静止画面，
只会把"卡住"演得更明显。既然动画帮不上忙，一张连续、稳定、不变的记印反而是最不坏的选择。

**退回方案（一行属性）**：真机实测若发现记印**明显早退**（屏幕上先出现一段无记印的纯色）或**滞留难看**，
把 `NormalTheme.windowBackground` 改回纯色 `@color/window_background` 即可 —— 两条 C 项各改一行。

**实测判定方法**：冷启录屏逐帧看**记印消失的时刻**与**首屏内容出现的时刻**（命令与逐帧判定见 §7.4）。
两者相差 ≤2 帧 = 接续成功；中间夹着一片明显异色的纯色 = 退回方案。

> 为什么备用色仍选默认色盘而不是读用户当前色盘：读设置要在 Kotlin 侧同步读 SharedPreferences，
> 在冷启动路径上要花几十毫秒，而窗口底的暴露窗口很短。用默认色盘足够。

**检查点（逐条做，别跳）**

| # | 查什么 | 怎么查 | 通过 |
| :--- | :--- | :--- | :--- |
| C1 | `LaunchTheme` 与 `NormalTheme` 的 `windowBackground` **都**指向 `@drawable/launch_background`；不再是 `?android:colorBackground` / `@android:color/white` | `grep -n windowBackground android/app/src/main/res/values*/styles.xml` | 四个文件（含 v31 / night-v31）都能对上，无一处残留 `?android:colorBackground` |
| C2 | 那张 layer-list 确实含 240dp 居中记印，且与 31+ 系统闪屏同几何 | 读 `drawable/launch_background.xml`；对照 §5.1 的 240dp / Ø160dp | `<item width/height="240dp" gravity="center">` 在，且 `launch_mark` 的墨盘是 `circle r=36` |
| C3 | 冷启不白闪、底色不跳、无大面积纯白 | §7.4 的录屏 + `tools/splash-frame-check.py` | 三条判据全 PASS（见 §7 B4） |
| C4 | 深色 / OLED 同样跑 C3 | 系统切深色 + OLED | 三条判据全 PASS |

### 5.4 时长预算

**闪屏不消耗预算。** 它不是新增页面，是引擎启动期间**本来就会显示**的窗口背景，不增加任何启动时间。唯一的破坏方式是**人为延长展示时长**（`setKeepOnScreenCondition` / 固定 delay / 等接口）。**本方案明确禁止任何形式的最小展示时长**：引擎 250ms 就绪，闪屏就只活 250ms。

| 平台 | 选择 | 时长 |
| :--- | :--- | :--- |
| API 31+ | 只用系统默认入场（淡入 + 轻微放大），**不自绘 AVD** | 系统默认约 200–300ms，随首帧提前截断 |
| API 24–30 | **完全静态** layer-list，零动效 | 0ms |

**为什么不做 AVD 品牌动画**

1. **抢不到时间。** 必须在前 250ms 内基本演完，否则被首帧截断成一帧"抽"。用户第 80ms 才抬眼，只看了个尾巴。
2. **抢资源。** AVD 的解码绘制与引擎冷启抢 CPU/GPU，**为了 150ms 的好看去赌 800ms 硬指标，不划算**。
3. **和"减弱动效"打架。** 系统闪屏的入场跟随系统动画缩放，但**我们自绘的 AVD 不会自动遵守**——要自己读 `ANIMATOR_DURATION_SCALE` 并降级。多一条容易漏的合规路径，收益为零。

**与「减弱动效」（§3.4）**：本方案**没有我们自己的动效**，唯一的运动是系统内置入场，而系统本身已尊重该设置。**天然合规，无需代码**——这也是不做 AVD 的第四个理由。
**与 ≤800ms（§9.1）**：不加最小时长、不加 AVD，静态资源对启动路径的增量接近 0。验证见 §7 B3。

**"什么都不加"的边界**（防止将来以"品牌感"为名偷偷加回动画）：参考机型冷启已 ≤500ms → **不加**（动画会被截断成"抽搐"）；低端机冷启 >1000ms → **不加**（300ms 后定格成静止画面，把"在跑"变成"卡住了"，这是最坏结果）；系统动画缩放为 0 / 开启减弱动效 → **不加**。三者都不成立且愿承担风险时，只允许一种：图标 opacity 0→1、**≤200ms**。

一句话：**这个产品的启动页应该是"一扇门"，不是"一段片头"。**

### 5.5 字标

**主张：字标不进启动页。**

| 平台 | 能否放 | 为什么 |
| :--- | :--- | :--- |
| API 31+ | **技术上不能** | 系统闪屏只接受"底色 + 图标（可动画）+ 图标底色 + branding image"。文字只能烧进图标里，那就变成"图标里写汉字"（违反非目标）。`windowSplashScreenBrandingImage`（200×80dp）存在，但**官方设计指南明确反对使用** |
| API 24–30 | 能（layer-list 塞位图） | 但**不该**：会造成"12+ 只有 mark、24–30 有 mark + 字标"的入场不一致，还要把「听卷」光栅化进 5 个密度目录 |

**不打包字体时字标怎么做**：字标**只在应用内**出现（书架空态、关于页、播放台、备份页），而那里是 Flutter 的世界，直接用已有的系统衬线回退链——`AppTypefaces.serifFamily` + `serifFallback`（`theme_tokens.dart` 已就绪，**无需改动**）。好处：零字体文件、零体积、随系统语言与字体缩放自动正确，且与全应用排版一致。预览见 `src/wordmark.svg`。

**要不要引入字体文件？——不建议。** 唯一正当理由是"跨设备字形必须逐像素一致"，但启动页用不到字标（已定），应用内字标只是气质表达，没人会拿两台设备比对字形。代价却很实在：中文字体要覆盖常用字至少 3–8MB；即使 `pyftsubset` 只截「听卷TomeTone」也要 **8–20KB**，还多了一份必须 OFL/免费商用的许可审查。**结论：不打包。** 将来真需要（如品牌分享卡片）再走"子集 + `assets/fonts/`"，回退方案是丢掉 `fontFamily` 声明、自动落回 `serifFallback`。

---

## 6. 落地清单

**左边是方案的交付物（已在仓库），右边是实现阶段才动的文件。现在都不动。**

**本提案已产出**：`docs/tometone_icon_splash_design.md`（本文件）+ `docs/design-preview/icon-splash/` 全部内容（**5 个 SVG 源**、**3 个预览页**、**10 张渲染 PNG**、**3 个自检脚本**、README）。
其中 mark 与含 mark 的渲染已被用户否决，状态标为「待替换」——清单见该目录 `README.md`。

### 6.1 待新增

| # | 路径 | 内容要点 |
| :--- | :--- | :--- |
| A1 | `android/app/src/main/res/drawable/ic_launcher_foreground.xml` | Vector 108/108；`translate(1.44 0)` 组内 3 rect + 2 stroke path；`#FFC08A3E`；无底色 |
| A2 | `android/app/src/main/res/drawable/ic_launcher_monochrome.xml` | 同构但只一道弧、`strokeWidth 6.5`；纯 alpha |
| A3 | `android/app/src/main/res/values/ic_launcher_background.xml` | `<color name="ic_launcher_background">#FF1E1710</color>` |
| A4 | `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | `<adaptive-icon>`：background / foreground / **monochrome** |
| A5 | `android/app/src/main/res/values/colors.xml` | `brand_ink` `#FF1E1710`、`brand_gold` `#FFC08A3E`、`splash_window_background` `#FFFBF6EC`、`window_background` `#FFFBF6EC`（**`window_background` 只作退回方案的备用色**，正常路径不用它，见 C3） |
| A6 | `android/app/src/main/res/values-night/colors.xml` | `splash_window_background` → `#FF1E1710`；`window_background` → `#FF191510`（同上，仅备用） |
| A7 | `android/app/src/main/res/drawable/launch_mark.xml` | Vector **声明 240dp**、viewport 108；`circle(r=36)` 墨盘 + `translate(1.44 0)` 的 mark |
| A8 | `android/app/src/main/res/drawable-night/launch_mark.xml` | 同 A7，**只删墨盘那条 path** |
| A9 | `android/app/src/main/res/values-v31/styles.xml` | `LaunchTheme`：`windowBackground` + `windowSplashScreenBackground` + `windowSplashScreenAnimatedIcon=@mipmap/ic_launcher` + `windowSplashScreenBehavior=icon_preferred` |
| A10 | `android/app/src/main/res/values-night-v31/styles.xml` | 同 A9，仅 `parent` 换 `Theme.Black.NoTitleBar` |
| A11 | `mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` | legacy 位图 48/72/96/144/192px，源自 108dp 画布的**中央 72dp 区域** |

### 6.2 待修改

| # | 路径 | 改什么 | 为什么 |
| :--- | :--- | :--- | :--- |
| C1 | `android/app/src/main/res/drawable/launch_background.xml` | 改成 §5.2 的 layer-list | 现状是纯白 / 系统色 |
| C2 | `android/app/src/main/res/drawable-v21/launch_background.xml` | 与 C1 同步**或直接删除** | 两份不一致时，将来调 minSdk 会莫名回退 |
| C3 | `android/app/src/main/res/values/styles.xml` | `NormalTheme.windowBackground` → **`@drawable/launch_background`**（与 `LaunchTheme` 指向同一张记印；`LaunchTheme` 其余不动） | **不跳变的关键改动**（§5.3）：`onCreate()` 第一句就切主题，若此处是别的颜色，露出的就是一次可见画面跳变 |
| C4 | `android/app/src/main/res/values-night/styles.xml` | 同 C3（三个分支 24–30 / 31+ / night-31+ 统一） | 同上 |

### 6.3 明确不改

| 路径 | 原因 |
| :--- | :--- |
| `android/app/src/main/AndroidManifest.xml` | `android:icon="@mipmap/ic_launcher"` 已能让 26+ 命中 `anydpi-v26`、24–25 命中 PNG；不需要 `roundIcon`（§4.4）；`NormalTheme` meta-data 已在，正是 post-splash 主题切换的挂点 |
| `android/app/build.gradle.kts` | minSdk 24 已满足 VectorDrawable 渐变与 `<item width/height>` |
| `pubspec.yaml` / `pubspec.lock` | 零新依赖、零新增 assets（字标走系统字体） |
| `android/app/src/main/res/values/strings.xml` | `app_name` 保持「听卷」 |
| `lib/**` | 资源层的事，Dart 侧零改动 |
| `test/**`、以及工作树里其他会话的改动 | 本任务不涉及。工作树可能同时存在其他会话的改动（它们不属于本任务范围，也不要一并提交） |

### 6.4 为什么不新增依赖

| 候选 | 不采用的理由 |
| :--- | :--- |
| `androidx.core:core-splashscreen` | 价值主要在 API 23–30 上**模拟** 12 闪屏并统一 Day/Night。但我们本来就要为 24–30 做手工方案（可控性更好），引入等于维护两套并存路径 |
| `flutter_native_splash` | 按模板重写 `launch_background.xml`，覆盖 C1/C2 的精细对齐；且它的"保留时长"正是明令禁止的东西 |
| `flutter_launcher_icons`（长期保留） | 一次性工具。留着就是"随手跑一下覆盖 `anydpi-v26/`"的地雷（§4.6） |
| 任何字体包 | §5.5 已论证 |

---

## 7. 验收标准

**验收分两层，写清哪些现在就能自证、哪些必须上真机：**

- **第一层「现在就能自证」**：纯静态/离线可完成——几何解析与像素双检、对比度、静态 grep、`flutter analyze`、API 36 模拟器上的 31+/33+ 路径截图。**不需要真机。**
- **第二层「需要真机或需要你执行」**：冷启动耗时、白闪/跳变逐帧判定、系统闪屏实际观感、API 24–30 实机画面。命令见 **§7.4**，设备清单一见 **§7.5**。

**API 24–30 分支照做，不砍。** 成本只是两个 xml + 5 张 legacy PNG；砍掉反而要长期维护一个"只有 31+"的不对称启动页，且会让 Android 7–11 用户看到裸白屏。

### A 组 · 图标几何

> ⚠️ **mark 已被用户否决，A 组全部数值待新方向定稿后重算。**
> 仍然有效的是**判定方法与门槛**（余量 ≥4dp、0.8dp 抗锯齿容差、四条遮罩口径）。

**层**：A1–A5、A8 属第一层；A6、A7 属两层（脚本与剪影可自证，最终观感以人眼确认为准）。

| # | 标准 | 判定方法 | 通过值 |
| :--- | :--- | :--- | :--- |
| A1 | 外接不超安全区（解析法） | `node tools/mark-geometry-check.js` | ① ② ④ 三段全 PASS；『Ø66 余量 ≥ 6.5dp』『Ø62 余量 ≥ 4.5dp』。<br>**注意：③ 段不是门禁**（见 A6），不要为消掉 ③ 段的 `[参考]` 去改阈值或改几何 |
| A2 | 渲染与几何一致（像素法） | `python tools/render-extent-check.py preview/master-render.png` | PASS，且 `｜像素 − 解析｜ ≤ 0.8dp` |
| A3 | 前景/背景对比度 | `mark-geometry-check.js` 第 ④ 段 | 金 on 墨 ≥ 3.0:1（实测 5.86:1），且三组「禁止组合」仍被标 FAIL |
| A4 | 视觉重心不偏 | 同上第 ② 段 | 偏差 ≤ 0.1dp（实测 0.000dp） |
| A5 | 4 遮罩下不被切、不贴边 | `preview/icon-preview.png` §1 的 16 格 | mark 完整，与遮罩边界最小距离 ≥ 4dp |
| A6 | 48px 可辨识 | 同上 §4 的 1:1 行 | 能分辨主体形状，与相邻图标不混淆。**不要求细节完全清晰**——画布 48px（legacy mdpi）下弧间净间隙只有 1.33px，这是物理必然，`mark-geometry-check.js` ③ 段已把它标为 `[参考]` 而非门禁 |
| A7 | 单色层可辨识 | 把 mono 源渲成纯黑剪影，或看 §2 右两格 | 剪影里主体与细节可分辨，没粘成一团 |
| A8 | 自适应图标不用位图 | 查 `mipmap-anydpi-v26/ic_launcher.xml` 与两个 drawable | 三层分别指向 `@color` / `@drawable` 的 vector，无 PNG 引用 |

### B 组 · 启动页

**层**：B5、B7 属第一层；B1、B2、B3、B4、B6、B8 属第二层（需真机；命令见 §7.4）。

| # | 标准 | 判定方法 | 通过值 |
| :--- | :--- | :--- | :--- |
| B1 | 31+ 浅色：墨盘由系统自动显示 | 真机（Android 12+）冷启截图 | "宣纸底 + 墨盘金纹徽记"，与 `splash-preview.html` §1 左帧构图一致 |
| B2 | 31+ 深色：墨盘自动隐去 | 同上，系统切深色 | "墨底 + 金纹"，无墨盘、无多余色块 |
| B3 | 冷启动不回归 800ms | §7.4 命令 1：force-stop → `am start -W` 取 `TotalTime`，**同机型连测 10 次取中位数** | 中位数 ≤ 800ms，且比"未改启动页"基线**退化 ≤ 20ms**（§9.1） |
| B4 | 无白闪、底色不跳、无大面积纯白 | §7.4 命令 2+3：录屏 → 拆帧 → `python tools/splash-frame-check.py frames/` | **三条判据全 PASS**（① 无白闪帧 ② 底色逐帧稳定 ③ 无大面积纯白）。判定范围**只到「Flutter 首帧、首屏内容可见之前」**，首屏出现之后的帧不参与 |
| B5 | 无最小展示时长 | `grep -rn "KeepOnScreen\|postDelayed\|Thread.sleep" android/app/src/main` | 无匹配 |
| B6 | 两条分支画面一致 | API 30 与 API 31 各截一张 | 记印的**大小与位置**一致（240dp / Ø160dp 对齐），只有系统栏差异 |
| B7 | 启动页无文字 / 无进度条 | 目视 + `grep -rn "TextView\|ProgressBar" android/app/src/main/res` | 零文字、零进度控件 |
| B8 | 尊重减弱动效 | 系统开"移除动画"后冷启 | 无异常。因本方案零自绘动效，此项**应自动通过** |

### C 组 · 仓库卫生

**层**：全部属第一层。

| # | 标准 | 判定方法 | 通过值 |
| :--- | :--- | :--- | :--- |
| C1 | `flutter analyze` 0 告警 | `flutter analyze` | 与改动前**完全一致**（本次没动 Dart） |
| C2 | 依赖零变化 | `git diff pubspec.yaml pubspec.lock` | 空 diff |
| C3 | manifest 零变化 | `git diff android/app/src/main/AndroidManifest.xml` | 空 diff |
| C4 | 改动落在白名单内 | `git status --short` | 只有 §6.1/§6.2 的路径 + `docs/`。工作树里**其他会话**的改动（`lib/**`、`test/**`、`MainActivity.kt` 等）不属于本任务，不要一并提交 |

### 7.4 第二层：可执行判据（任何人都能照着跑）

把 `com.tometone.app` 换成实际 applicationId；`MainActivity` 全名见 `AndroidManifest.xml`。

**命令 1 · 冷启动耗时（B3）**

```powershell
# 每次都要 force-stop，否则是热启，数字没意义。重复 10 次，取 TotalTime 的中位数。
1..10 | ForEach-Object {
  adb shell am force-stop com.tometone.app
  Start-Sleep -Milliseconds 800
  adb shell am start -W -n com.tometone.app/.MainActivity |
    Select-String "TotalTime"
}
```

判读：`TotalTime` 就是我们要的冷启总耗时。**取 10 次的中位数**，不用单次值；与"未改启动页"的基线比，退化 ≤ 20ms。

**命令 2 · 冷启录屏（B4）**

```powershell
# 录屏与启动要并发：先开录屏，再（在另一个终端）启动应用
adb shell screenrecord --time-limit 6 --bit-rate 8000000 /sdcard/cold.mp4
# ← 在另一个终端立刻执行：
adb shell am force-stop com.tometone.app
adb shell am start -n com.tometone.app/.MainActivity
# 录完拉回来
adb pull /sdcard/cold.mp4 .
```

**命令 3 · 拆帧 + 逐帧判定（B4 的三条判据）**

```powershell
ffmpeg -i cold.mp4 -vsync 0 frames/f_%04d.png        # 拆帧（需要 ffmpeg）
python docs/design-preview/icon-splash/tools/splash-frame-check.py frames/
# 脚本会自己猜「首屏内容出现」的帧并提示复核；也可显式指定：
python docs/design-preview/icon-splash/tools/splash-frame-check.py frames/ --cut 37
```

三条判据（浅色 / 深色同一口径）：

| 判据 | 定义 | 通过 |
| :--- | :--- | :--- |
| ① 白闪帧 | 整帧平均 **WCAG 相对亮度** ≥ 0.95 | 不允许出现 |
| ② 底色逐帧稳定 | 相邻帧「四角底色采样区」平均 RGB 的最大通道差 > 8/255 | 不允许出现 |
| ③ 大面积纯白 | 纯白像素（L ≥ 0.95）占比 > 1% | 不允许出现 |

- **判定范围**：只到「Flutter 首帧、首屏内容可见之前」。首屏出现之后的帧不参与——因为浅色首屏 `#FBF6EC` 本身的相对亮度就有 ≈0.92，**用原来的"平均亮度 > 0.8 即失败"会把正确的浅色首屏判成白闪**，等于逼实现者去加深首屏或加最小展示时长（后者明令禁止）。
- 0.95 这个阈值把"纸色首屏 0.92"和"纯白 1.00"干净分开，两边都不会误判。
- 脚本保护：**近白的帧不会被当成"首屏"候选**（否则白闪会被误判成"内容出现了"而漏判）；判定范围外的近白帧会单独列出来提示复核。
- **模拟器不作为通过依据。** 模拟器的窗口合成与真机不同，必须真机 force-stop 后冷启录屏。

**命令 4 · 接续实测（§5.3 的退回方案判定）**

在命令 2 的帧序列里找两个时刻：**记印消失的时刻** 与 **首屏内容出现的时刻**。

- 两者相差 ≤2 帧 → 接续成功，保持 `NormalTheme.windowBackground = @drawable/launch_background`。
- 中间夹着一片明显异色的纯色 → 记印明显早退，把 `NormalTheme.windowBackground` 改回 `@color/window_background`。
- 记印滞留很久才被首屏盖住（低端机）→ 属 §5.3 已接受的代价，**不要用加动画去掩盖**。

### 7.5 待你提供设备 / 待你自行执行

以下我做不了，需要你或拿到设备的人执行（第一层不需要设备，已可自证）：

| # | 事项 | 需要的设备 / 条件 | 对应验收 |
| :--- | :--- | :--- | :--- |
| 1 | 冷启耗时取样 10 次取中位数 | 参考机型真机（§9.1 的定标机型） | B3 |
| 2 | 冷启录屏 + 逐帧判定（浅色） | 同上；需 ffmpeg | B4、C3 |
| 3 | 冷启录屏 + 逐帧判定（深色 / OLED） | 同上 | B4、C4 |
| 4 | 系统闪屏实际观感截图 | Android 12 及以上真机 | B1、B2、B6 |
| 5 | API 24–30 实机/模拟器画面 | Android 7–11 设备（模拟器可用） | B6 |
| 6 | 减弱动效下冷启 | 任意真机 | B8 |
| 7 | 接续实测（记印消失 vs 首屏出现） | 同 2 | §5.3 退回方案判定 |

**不需要设备的那些**（A1–A5、A8、B5、B7、C1–C3）现在就能跑完，命令都在 §7.4 与 §6。

---

## 8. 我替用户做的决定（逐条可否决）

| # | 决定 | 若否决 |
| :--- | :--- | :--- |
| D1 | 品牌色对用墨 `#1E1710` + 金 `#C08A3E`，**不跟随 5 套色盘** | 需重新论证"跟色盘变"的技术代价（§1.2 三条约束），成本高 |
| D2 | 图标底色用**深墨盘**而非宣纸底 | 换 §3.5 的 B3：深色桌面需第二套资源 + 前景被迫双色 |
| D3 | mark 用**卷轴 + 两道声纹弧** | 换 B1（只留卷）或 B2（卷 + 弦） |
| D4 | 外接只做到 **Ø52.50dp**，留 6.75dp 余量 | 可放大到 Ø58dp 换小尺寸观感，但 Ø62 保险线余量降到 2dp |
| D5 | 三层**全用 Vector**，不产出自适应位图 | 若要渐变/纹理，改各密度 PNG = 108/162/216/324/432 |
| D6 | 单色层**去外弧、加粗到 6.5dp**（与前景层有意不同） | 保留两弧则弧间净间隙要拉到 ≥5dp，会显著改变比例 |
| D7 | legacy PNG 从**中央 72dp 区域**裁切 | 整画布导出会让 legacy 上的 mark 比自适应小一圈 |
| D8 | **不新增** `ic_launcher_round.xml` / `android:roundIcon` | 补 1 个 anydpi-v26 文件 + manifest 一行 + 5 张圆 PNG |
| D9 | 启动页**跟随系统明暗**（浅=纸底墨盘 / 深=墨底金纹） | 改成两模式都墨底（少一支），但浅色用户会经历一次墨→纸换色 |
| D10 | **不设** `windowSplashScreenIconBackgroundColor`，让系统按对比度决定 | 两边各显式指定一次；会失去"深色下金纹浮在墨里"的效果 |
| D11 | **不加任何品牌动效**（无 AVD、无自绘） | 最多允许"图标 opacity 0→1、≤200ms"一种（§5.4 边界） |
| D12 | 字标**不进启动页** | 只能在 24–30 加（12+ 技术上办不到），会导致两分支不一致 |
| D13 | **不打包字体** | 走 `pyftsubset` 子集（8–20KB）+ `assets/fonts/`，字体必须 OFL |
| D14 | 不引入 `core-splashscreen` / `flutter_native_splash` / `flutter_launcher_icons` | 见 §6.4 |
| D15 | **（已按修正后的机制更新）** `NormalTheme.windowBackground` → **`@drawable/launch_background`**（同一张记印），API 24–36 三分支统一 | 退回纯色 `@color/window_background`（一行属性）；退回后会重新出现"记印 → 纯色 → 首屏"的一次可见跳变 |
| D16 | **不改 manifest** | 若加 roundIcon 则必须改（见 D8） |
| D17 | 背景层用纯色，弃用 4% 渐变 | 恢复渐变只需替换背景层一个文件 |
| D18 | `drawable-v21/launch_background.xml` 同步或删除 | 两份不一致会让将来调 minSdk 时行为不可预测 |
| D19 | **（修正机制后的推论）** 因为 `onCreate()` **第一句**就切主题，"应用窗口底"会先于首帧露出，所以让 ② = ①：`NormalTheme` 用同一张 `launch_background`。理由不依赖"实机到底是哪种机制"——它对两种都成立 | 退回 D15 的纯色方案，接受一次可见的画面跳变 |
| D20 | 验收拆成两层（**第一层"现在就能自证"** / **第二层"需真机或需你执行"**，后者配可直接粘贴的 `adb` 命令），且 **API 24–30 分支照做不砍** | 砍 24–30 会留下"只有 31+"的不对称启动页，并让 Android 7–11 用户看到裸白屏 |
| D21 | 画布 48px（legacy mdpi）下弧间净间隙只有 1.33px，**仍接受**；门禁以 §7 A6 为准，`mark-geometry-check.js` ③ 段标为 `[参考]` 而非门禁 | 若要求 48px 细节清晰，必须放大 mark 或减弧，等于改设计 |

---

## 9. 留给实现者的自由度

| 自由度 | 范围 |
| :--- | :--- |
| 轴杆尺寸微调 | 高 5.5–6.5dp、宽 17–19dp。**改完必须重跑 `mark-geometry-check.js` 并更新 CORRECTION**，且满足 §3.4 五条约束 |
| 弧端点 | 保持圆头（`stroke-linecap="round"`）是设计意图的一部分；圆头半径由笔画宽决定，不用管 |
| VectorDrawable 写法 | 用 `<path>` 画 rect 还是 `<group>` 平移随实现者，只要渲染结果与 `src/*.svg` 一致 |
| 资源命名 | `ic_launcher_foreground` / `ic_launcher_monochrome` / `launch_mark` 是惯例名，可换；但 `mipmap-anydpi-v26/ic_launcher.xml` 与 `ic_launcher_background` **不能换**（系统/工具约定） |
| 颜色常量组织 | 一个 `colors.xml` 还是拆多个文件、是否加注释随实现者 |
| 单色层简化程度 | 在"能分辨卷轴与声纹"的前提下，可只留轴杆 + 弧（去掉卷身），也可保留卷身。**不允许**改成一团实心轮廓 |
| legacy PNG 导出工具 | 一次性 `flutter_launcher_icons` 或从 SVG 用 Chrome/Inkscape 批量导出，随实现者 |
| 字标字号字距 | `src/wordmark.svg` 的 58 / 16 / 11 只是起点，应用内按页面节奏调 |
| 启动页记印微调 | 240dp / `circle r=36` 是对齐 12+ 的硬约束；若实测偏小可在 `<item width/height>` 上 ±16dp（需接受两分支不再逐像素对齐） |

---

## 10. 依赖 mark 的结论清单（交接给新方向 lane）

**mark「卷 · 声纹」已被用户否决。** 以下结论**全部依赖具体 mark 几何**，新方向定稿后必须重算；
按"重算成本"分三档，便于新 lane 排期。

**A 档 · 必须重算的具体数值**（照同一套工具与口径跑一遍即可，工具已就绪）

| 结论 | 现在写在哪 | 重算方式 |
| :--- | :--- | :--- |
| mark 外接直径 Ø52.50dp（含描边外扩） | §0、§4.2、§7 A1 | 改 `mark-geometry-check.js` 的 `GEOM` → 读 ①′ 段 |
| 距 Ø66 安全圆余量 6.75dp / 距 Ø62 关键核心余量 4.75dp | §4.2、§4.3、§7 A1 | 同上 |
| 视觉重心修正量 `translate(1.44 0)`；修正前质心 52.557、修正后残差 0.000dp | §3.4、§4.4、§4.7 | 读 ② 段，把新的 CORRECTION 抄回三份 SVG 与 native vector |
| 最小笔画 4.5dp、两弧净间隙 3.00dp，及各级画布下的物理像素 | §4.2、§7 A6、§4.5 | 读 ③ 段（参考值） |
| 像素法与解析法的一致性（26.686 / 26.251，偏差 +0.435dp） | §4.2、§7 A2 | 重渲母版 → `render-extent-check.py` 的 `EXPECTED_DP` 要同步改 |
| §3.1 的对比度表 | §3.1、§7 A3 | `brand_gold`/`brand_ink` 若沿用，**这一项不用重算**；若换色，读 ④ 段 |

**B 档 · 几何约束（方法仍有效，对新 mark 重新成立即可）**

| 结论 | 现在写在哪 | 说明 |
| :--- | :--- | :--- |
| 五条硬约束（轴杆宽 ≥ 卷身 1.6 倍、弧净间隙 ≥ 3dp、最小笔画 ≥ 4dp、张角 ≥ ±50°、卷轴与内弧间隙 ≥ 3dp） | §3.4 | 这是**这一版 mark** 的经验约束。新方向形状不同时，前两条要换成对应的"可读性下限"表述 |
| 单色层简化策略（去外弧、加粗到 6.5dp）与"什么时候必须单独简化"的通则 | §4.5 | **通则（§4.5 末段）可复用**；具体删哪条弧、加粗到多少要按新 mark 重定 |
| 「组内坐标 = 自然构建位置 + 整组 translate 做重心修正」这套做法 | §3.4 | 方法可原样沿用，值得规定为项目惯例 |

**C 档 · 与 mark 无关，**不要**重算**（新 lane 可直接引用）

| 结论 | 现在写在哪 |
| :--- | :--- |
| 108 / 72 / Ø66 / Ø62 四层尺寸口径与三条遮罩硬性结论 | §4.1、§4.3 |
| 三种遮罩 + Ø66 极限裁切的自检**方法** | §4.3、`icon-preview.html` §1 |
| legacy 从"中央 72dp 区域"导出的做法与 5 档尺寸 | §4.6 |
| 明暗 / themed icon 的判定方法与"自适应图标不做明暗变体" | §4.7 |
| 单色层只用 alpha、不带墨盘 | §4.5 |
| 启动页 31+ / 24–30 的全部结构、240dp 对齐、时长预算、不做 AVD 的边界 | §5.1–§5.4 |
| **§5.3 的机制与 `NormalTheme.windowBackground = @drawable/launch_background`** | §5.3、D19 |
| 全部文件清单、依赖取舍、验收方法（含 §7.4 的 adb 命令） | §6、§7 |
| 字标不进启动页、不打包字体 | §5.5 |

**新 lane 的入口建议**：先读 §3.3 的三个否决方向（搜索空间的约束）与 §4.1/§4.3（所有候选都要过的门），
选定方向后再回 §3.4 定几何，最后按 A 档逐项重算。**不要**照搬 A 档的任何数字。

---

## 附录 A · 预览与复现

产物清单、状态（哪些待替换）、复现命令、已知限制见 `docs/design-preview/icon-splash/README.md`。
自检脚本共三个：

```powershell
node   tools/mark-geometry-check.js                             # 解析法几何自检（GEOM 待替换）
python tools/render-extent-check.py preview/master-render.png   # 像素法自检（需 Pillow）
python tools/splash-frame-check.py frames/                      # 冷启录屏三判据（需 Pillow）
```

关于 `mark-geometry-check.js` 的 ③ 段：它打印各级画布下的最小笔画与弧间净间隙，
**`<72px` 的几行标 `[参考]` 而不是 PASS/FAIL**——48px 画布下净间隙不足 2px 是物理必然，
门禁是 §7 A6（"认得出是同一枚 mark"），不是这一段的数值。不要为了消掉它去改阈值或改几何。

本环境无 rsvg / Inkscape / cairosvg / sharp，渲染统一用**无头 Chrome**（`--headless=new --screenshot`）。
这是已知限制：预览是浏览器画的 SVG，不是 Android 真实渲染管线。

## 附录 B · 事实核对

| 事实 | 出处 |
| :--- | :--- |
| applicationId `com.tometone.app`、minSdk 24、targetSdk/compileSdk 36 | `android/app/build.gradle.kts` |
| 应用名「听卷」 | `res/values/strings.xml`、`lib/app/app_info.dart` |
| 五套国风色盘 + OLED，默认 `amberScroll`（primary `#8A5A20`、light surface `#FBF6EC`、dark surface `#191510`） | `lib/ui/theme/app_color_palette.dart` |
| 不打包字体，只用系统衬线回退链 | `lib/ui/theme/theme_tokens.dart`（`AppTypefaces`） |
| 冷启动 ≤800ms；48dp 触摸目标；WCAG AA；跟随减弱动效 | `docs/tometone_architecture_requirements.md` §9.1 / §3.4 |
| 图标现状：只有 5 张默认 `mipmap-*/ic_launcher.png`；**不存在** `anydpi-v26/`、`values-v31/`、任何 `ic_launcher_*` 资源 | 目录列举 |
| 启动页现状：`drawable/launch_background.xml`（纯白）、`drawable-v21/…`（`?android:colorBackground`） | 两个文件内容 |
| `LaunchTheme` = `Theme.Light.NoTitleBar`（night 用 `Theme.Black`），`NormalTheme` 同样，`windowBackground` = `?android:colorBackground` | `values/styles.xml`、`values-night/styles.xml` |
| manifest 只有 `android:icon`、无 `roundIcon`；已有 Flutter `NormalTheme` meta-data | `AndroidManifest.xml` |
| 无 `flutter_launcher_icons` / `flutter_native_splash`；无 `assets/` 目录 | `pubspec.yaml` |



