$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http
$Base = "http://localhost:8080/api/v1"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ImgDir = Join-Path $ScriptDir "generated_images"

function Invoke-ApiJson {
  param([string]$Method, [string]$Url, [string]$Token, [object]$Body)
  $headers = @{ "Content-Type" = "application/json; charset=utf-8"; "Accept" = "application/json" }
  if ($Token) { $headers["Authorization"] = "Bearer $Token" }
  $json = $null
  if ($null -ne $Body) { $json = $Body | ConvertTo-Json -Depth 10 -Compress }
  try {
    if ($null -eq $json) {
      return Invoke-RestMethod -Uri $Url -Method $Method -Headers $headers
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    return Invoke-RestMethod -Uri $Url -Method $Method -Headers $headers -Body $bytes
  } catch {
    $msg = $_.Exception.Message
    if ($_.Exception.Response -and $_.Exception.Response.GetResponseStream) {
      $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
      $msg = $reader.ReadToEnd()
    }
    throw "请求失败: $Method $Url => $msg"
  }
}

function Login([string]$username, [string]$password) {
  $resp = Invoke-ApiJson -Method "Post" -Url "$Base/auth/login" -Body @{ username = $username; password = $password }
  if ($resp.code -ne 0 -or -not $resp.data.token) { throw "登录失败: $username" }
  return $resp.data.token
}

function Upload-Images([string]$token, [string[]]$paths) {
  $client = New-Object System.Net.Http.HttpClient
  $client.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $token)
  $content = New-Object System.Net.Http.MultipartFormDataContent
  $streams = @()
  try {
    foreach ($p in $paths) {
      $fs = [System.IO.File]::OpenRead($p)
      $streams += $fs
      $sc = New-Object System.Net.Http.StreamContent($fs)
      $sc.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("image/svg+xml")
      $content.Add($sc, "files", [System.IO.Path]::GetFileName($p))
    }
    $resp = $client.PostAsync("$Base/uploads/images", $content).Result
    $raw = $resp.Content.ReadAsStringAsync().Result
    if (-not $resp.IsSuccessStatusCode) { throw "上传失败: $raw" }
    $obj = $raw | ConvertFrom-Json
    if ($obj.code -ne 0) { throw "上传业务失败: $raw" }
    return @($obj.data.files | ForEach-Object { $_.url })
  } finally {
    foreach ($s in $streams) { $s.Dispose() }
    $content.Dispose()
    $client.Dispose()
  }
}

function Create-Post([string]$token, [hashtable]$payload) {
  $resp = Invoke-ApiJson -Method "Post" -Url "$Base/posts" -Token $token -Body $payload
  if ($resp.code -ne 0 -or -not $resp.data.post.id) { throw "发帖失败: $($payload.title)" }
  return $resp.data.post
}

function Approve-Post([string]$adminToken, [int]$postId) {
  $resp = Invoke-ApiJson -Method "Patch" -Url "$Base/posts/$postId/review" -Token $adminToken -Body @{ action = "approve" }
  if ($resp.code -ne 0) { throw "审核失败 postId=$postId" }
}

function New-SvgSet([string]$prefix, [string]$theme) {
  if (-not (Test-Path $ImgDir)) { New-Item -ItemType Directory -Path $ImgDir | Out-Null }
  $colors = @("#2B6CB0", "#2F855A", "#B7791F", "#9B2C2C", "#6B46C1")
  $files = @()
  for ($i = 1; $i -le 5; $i++) {
    $name = "{0}_{1}.svg" -f $prefix, $i
    $path = Join-Path $ImgDir $name
    $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720">
  <rect width="1280" height="720" fill="$($colors[$i-1])"/>
  <text x="80" y="180" font-size="56" fill="#FFFFFF">校园论坛图文相册</text>
  <text x="80" y="290" font-size="42" fill="#F7FAFC">主题：$theme</text>
  <text x="80" y="380" font-size="36" fill="#EDF2F7">阶段：第 $i 张 · 真实流程演示</text>
  <text x="80" y="470" font-size="28" fill="#E2E8F0">说明：准备-执行-反馈-复盘，沉淀可复用经验</text>
</svg>
"@
    Set-Content -Path $path -Value $svg -Encoding utf8
    $files += $path
  }
  return $files
}

# 回滚上一批外链图帖子
Invoke-ApiJson -Method "Get" -Url "$Base/auth/profile" -Token (Login "admin" "Admin123!") | Out-Null
& mysql --default-character-set=utf8mb4 -uroot -p123456 -D campus_forum -e "DELETE FROM posts WHERE id BETWEEN 1376 AND 1391;"

$LongA = '最近一周我发现，很多同学不是不努力，而是安排过于分散：学习、活动、社团、兼职全压在一起，容易出现忙但没有结果的情况。后来我把任务拆成固定节奏：先做当天最重要的一件事，再处理协作项，最后留出机动时间。这样做以后，焦虑明显下降，完成质量也稳定了。建议大家每周至少做一次复盘，记录哪些做法有帮助，哪些习惯在消耗精力。长期坚持下来，会慢慢建立自己的节奏感和方法论。'
$LongB = '这篇帖子想分享一些贴近校园生活的实践细节。比如组织活动时，不要只盯着现场当天，前置准备才是成败关键：时间节点、分工表、应急预案、对外通知都要提前确认。再比如学习备考，不要只看总时长，更要看单位时间产出是否有效。把事情做成“可执行、可检查、可复盘”的闭环，才会越来越轻松。欢迎大家在评论区补充自己的做法，我们一起把经验沉淀下来。'

$accounts = @(
  @{ u = "admin"; p = "Admin123!" },
  @{ u = "teacher_li"; p = "Teacher123!" },
  @{ u = "duanzhijie"; p = "AAAjt123@" },
  @{ u = "张三"; p = "zhangsan" }
)

$tokens = @{}
foreach ($acc in $accounts) { $tokens[$acc.u] = Login -username $acc.u -password $acc.p }
$adminToken = $tokens["admin"]

$galleryMap = @{
  "admin"      = @{ title = "校园志愿活动一日纪实"; boardId = 7; tags = @("志愿服务","校园文化") }
  "teacher_li" = @{ title = "社团开放日现场全记录"; boardId = 2; tags = @("社团活动","校园生活") }
  "duanzhijie" = @{ title = "一周学习节奏图文复盘"; boardId = 1; tags = @("学习方法","备考") }
  "张三"        = @{ title = "傍晚运动与作息平衡记录"; boardId = 2; tags = @("健康生活","运动") }
}

$postsByUser = @{}
$postsByUser["admin"] = @(
  @{ title = "考试周自习室高效学习小技巧"; summary = "把考试周过成可控节奏，而不是临时抱佛脚。"; content = $LongA + $LongB; format = "rich_text"; tags = @("期末","学习方法","时间管理"); boardId = 1; visibility = "public" },
  @{ title = "校园活动组织复盘：为什么这次大家都愿意来"; summary = "从报名到现场执行，分享可复用的组织方式。"; content = "## 组织复盘`n`n$LongA`n`n$LongB"; format = "markdown"; tags = @("校园活动","组织经验"); boardId = 2; visibility = "public" },
  @{ title = "教育部通知阅读笔记（同学可直接执行版）"; summary = "把信息拆成行动清单，减少理解成本。"; content = $LongA + $LongB; format = "external_link"; linkUrl = "https://www.moe.gov.cn/"; linkTitle = "教育部官网"; linkSummary = "建议先看原文，再对照执行清单。"; tags = @("通知解读","政策阅读"); boardId = 3; visibility = "public" }
)
$postsByUser["teacher_li"] = @(
  @{ title = "技术问答：小组项目总延期，真正卡点在哪"; summary = "问题往往不是能力，而是协作链路。"; content = $LongB + $LongA; format = "rich_text"; tags = @("项目协作","技术问答"); boardId = 4; visibility = "public" },
  @{ title = "就业分享：简历怎么写才不空"; summary = "把做过什么写成解决了什么问题。"; content = "## 简历建议`n`n$LongB`n`n$LongA"; format = "markdown"; tags = @("求职","简历","面试"); boardId = 5; visibility = "public" },
  @{ title = "给同学的一封提醒：真诚表达也要有边界"; summary = "沟通舒适感来自尊重和分寸。"; content = $LongA + $LongB; format = "external_link"; linkUrl = "https://www.people.com.cn/"; linkTitle = "人民网"; linkSummary = "借助公开文章讨论理性沟通。"; tags = @("沟通","边界感"); boardId = 6; visibility = "public" }
)
$postsByUser["duanzhijie"] = @(
  @{ title = "四六级备考：从低效刷题到有节奏复习"; summary = "重点不是题量，而是方法和复盘。"; content = $LongA + $LongB; format = "rich_text"; tags = @("四六级","英语学习"); boardId = 1; visibility = "public" },
  @{ title = "校园贴吧热帖整理：本周同学最关心的三件事"; summary = "把高频问题整理成一页清单。"; content = "## 热点整理`n`n$LongA`n`n$LongB"; format = "markdown"; tags = @("校园贴吧","热点"); boardId = 7; visibility = "public" },
  @{ title = "求职信息辨别：哪些招聘信息要多看一眼"; summary = "信息越多，越要重视来源和细节。"; content = $LongB + $LongA; format = "external_link"; linkUrl = "https://www.gov.cn/"; linkTitle = "中国政府网"; linkSummary = "建议结合官方渠道核验就业信息。"; tags = @("求职安全","就业信息"); boardId = 5; visibility = "public" }
)
$postsByUser["张三"] = @(
  @{ title = "宿舍关系小经验：把话说清楚比忍着更有效"; summary = "很多矛盾可以通过提前沟通避免。"; content = $LongB + $LongA; format = "rich_text"; tags = @("宿舍生活","沟通"); boardId = 2; visibility = "public" },
  @{ title = "技术入门路线：从会写代码到会解决问题"; summary = "少一点照抄，多一点场景理解。"; content = "## 入门路线`n`n$LongA`n`n$LongB"; format = "markdown"; tags = @("技术成长","学习路线"); boardId = 4; visibility = "public" },
  @{ title = "校园公告看不懂？这份先看什么清单给你"; summary = "通知很多，但可以按优先级处理。"; content = $LongA + $LongB; format = "external_link"; linkUrl = "https://www.xinhuanet.com/"; linkTitle = "新华网"; linkSummary = "配合公开信息，建立通知阅读优先级。"; tags = @("通知公告","信息筛选"); boardId = 3; visibility = "public" }
)

$created = New-Object System.Collections.Generic.List[object]

foreach ($acc in $accounts) {
  $u = $acc.u
  foreach ($payload in $postsByUser[$u]) {
    $post = Create-Post -token $tokens[$u] -payload $payload
    $created.Add([pscustomobject]@{ id = $post.id; title = $post.title; author = $u; format = $post.format })
  }

  $g = $galleryMap[$u]
  $svgFiles = New-SvgSet -prefix ($u + "_" + (Get-Random -Minimum 1000 -Maximum 9999)) -theme $g.title
  $uploadedUrls = Upload-Images -token $tokens[$u] -paths $svgFiles
  $galleryPayload = @{
    title = $g.title
    summary = "图文记录一次真实校园流程，包含准备、执行、反馈与复盘。"
    content = "这组图文不是简单晒图，而是围绕完整过程进行记录：先明确目标和分工，再展示现场执行细节，再记录中途问题和处理方案，最后沉淀可复用经验。每一张图都有中文说明，方便同学快速理解并直接借鉴。相比只看结果，这种过程化记录更能帮助后来者少走弯路。"
    format = "image_gallery"
    attachments = $uploadedUrls
    galleryCaptions = @("准备阶段：目标与分工","执行现场：节奏与协作","问题处理：定位与响应","结果展示：重点与反馈","复盘改进：经验沉淀")
    tags = $g.tags
    boardId = $g.boardId
    visibility = "public"
  }
  $gp = Create-Post -token $tokens[$u] -payload $galleryPayload
  $created.Add([pscustomobject]@{ id = $gp.id; title = $gp.title; author = $u; format = $gp.format })
}

foreach ($item in $created) { Approve-Post -adminToken $adminToken -postId ([int]$item.id) }

Write-Output ("CREATED_COUNT={0}" -f $created.Count)
$created | Sort-Object id | ForEach-Object {
  Write-Output ("{0}`t{1}`t{2}`t{3}" -f $_.id, $_.title, $_.author, $_.format)
}
