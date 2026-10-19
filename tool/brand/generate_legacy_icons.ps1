#Requires -Version 5.1
<#
.SYNOPSIS
  从图标矢量源导出 API 24–25 的 legacy 位图（5 档）。

.DESCRIPTION
  API 24–25 不支持自适应图标，会回落到 mipmap-*/ic_launcher.png。
  两个容易做错的地方，本脚本按规矩处理：

  1. 位图内容取自画布的**中央 72dp 区域**（viewBox="18 18 72 72"），不是整个 108dp 画布。
     自适应图标上屏时可见区只有画布的 2/3；legacy 若按整画布导出，图标会明显比别人的小一圈。
  2. 背景**满幅方形、四角不透明**：老启动器要么直接用方形，要么自己裁圆；
     给带透明圆角的设计反而在方形启动器里显得缺角。

  环境里没有 rsvg / Inkscape / cairosvg，所以用无头 Chrome 渲染（与仓库既有的
  预览渲染方式一致）。产物是提交进仓库的 PNG，本脚本只是记录它们的来源，不需要在 CI 跑。

.EXAMPLE
  pwsh -File tool/brand/generate_legacy_icons.ps1
#>
[CmdletBinding()]
param(
    [string]$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Chrome)) {
    throw "找不到 Chrome：$Chrome。用 -Chrome <路径> 指定。"
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$resRoot = Join-Path $repoRoot 'android\app\src\main\res'

# 与 drawable/ic_launcher_foreground.xml 逐值一致（改那边必须同步这里）。
$bookPath = 'M54,57.5 C48.5,52 42,51 34,52.5 L34,69.5 C42,68 48.5,69 54,75.5 C59.5,69 66,68 74,69.5 L74,52.5 C66,51 59.5,52 54,57.5 Z'
$barsPath = 'M41,44.5 L41,40.5 M47.5,44.5 L47.5,33.5 M54,44.5 L54,29.5 M60.5,44.5 L60.5,35.5 M67,44.5 L67,39.5'
$ink = '#0E2A3B'
$paper = '#F2F4E9'
$echo = '#58DCC1'

$targets = @(
    @{ Density = 'mdpi'; Size = 48 },
    @{ Density = 'hdpi'; Size = 72 },
    @{ Density = 'xhdpi'; Size = 96 },
    @{ Density = 'xxhdpi'; Size = 144 },
    @{ Density = 'xxxhdpi'; Size = 192 }
)

$temp = Join-Path ([IO.Path]::GetTempPath()) ('tometone-legacy-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $temp | Out-Null

try {
    foreach ($target in $targets) {
        $size = $target.Size
        $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="$size" height="$size" viewBox="18 18 72 72">
  <rect x="18" y="18" width="72" height="72" fill="$ink"/>
  <g fill="none" stroke-linecap="round" stroke-linejoin="round">
    <path d="$bookPath" stroke="$paper" stroke-width="3"/>
    <path d="$barsPath" stroke="$echo" stroke-width="3.4"/>
  </g>
</svg>
"@
        $svgPath = Join-Path $temp ('legacy-' + $size + '.svg')
        [IO.File]::WriteAllText($svgPath, $svg, (New-Object Text.UTF8Encoding($false)))

        $outDir = Join-Path $resRoot ('mipmap-' + $target.Density)
        if (-not (Test-Path -LiteralPath $outDir)) {
            New-Item -ItemType Directory -Force -Path $outDir | Out-Null
        }
        $outPng = Join-Path $outDir 'ic_launcher.png'
        if (Test-Path -LiteralPath $outPng) {
            Remove-Item -LiteralPath $outPng -Force
        }

        # 每次调用给独立的 --user-data-dir：循环里复用默认 profile 会互相抢锁，
        # 表现为后面几张图 net::ERR_FILE_NOT_FOUND。
        $profile = Join-Path $temp ('profile-' + $size)
        $uri = 'file:///' + ($svgPath -replace '\\', '/')
        & $Chrome --headless=new --disable-gpu --hide-scrollbars --no-first-run `
            --force-device-scale-factor=1 --user-data-dir="$profile" `
            --window-size="$size,$size" --screenshot="$outPng" "$uri" | Out-Null

        # Chrome 落盘是异步的：截图命令返回时文件可能还没写完，必须等待确认。
        $deadline = (Get-Date).AddSeconds(20)
        while ((Get-Date) -lt $deadline) {
            if ((Test-Path -LiteralPath $outPng) -and (Get-Item -LiteralPath $outPng).Length -gt 0) {
                break
            }
            Start-Sleep -Milliseconds 200
        }
        if (-not (Test-Path -LiteralPath $outPng) -or (Get-Item -LiteralPath $outPng).Length -le 0) {
            throw "截图未产出：$outPng"
        }
        Write-Host ('{0,-12} {1,4}px  {2,7} bytes' -f $target.Density, $size, (Get-Item -LiteralPath $outPng).Length)
    }
}
finally {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
