$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

$Base = "http://localhost:8080/api/v1"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ImgDir = Join-Path $ScriptDir "downloaded_images_batch3"
if (-not (Test-Path $ImgDir)) { New-Item -ItemType Directory -Path $ImgDir | Out-Null }

function Invoke-ApiJson {
  param([string]$Method, [string]$Url, [string]$Token, [object]$Body)
  $headers = @{ "Content-Type" = "application/json; charset=utf-8"; "Accept" = "application/json" }
  if ($Token) { $headers["Authorization"] = "Bearer $Token" }
  $json = $null
  if ($null -ne $Body) { $json = $Body | ConvertTo-Json -Depth 10 -Compress }
  try {
    if ($null -eq $json) { return Invoke-RestMethod -Uri $Url -Method $Method -Headers $headers }
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

function Download-WebImages([string]$prefix, [string[]]$keywords) {
  $files = @()
  for ($i = 0; $i -lt 5; $i++) {
    $seed = [uri]::EscapeDataString("$prefix-$($keywords[$i % $keywords.Count])-$i")
    $url = "https://picsum.photos/seed/$seed/1280/720"
    $path = Join-Path $ImgDir ("{0}_{1}.jpg" -f $prefix, ($i + 1))
    & curl.exe -L --ssl-no-revoke --silent --show-error --fail $url -o $path | Out-Null
    $files += $path
  }
  return $files
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
      $sc.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("image/jpeg")
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

function Build-LongContent([string]$boardName, [string]$roleHint) {
  $a = "这篇帖子围绕【$boardName】这个校园场景，记录了我最近一段时间真实遇到的问题和可执行的解决方式。很多时候我们感觉忙，是因为任务边界不清、节奏不稳定、反馈不及时。我的做法是先把目标写成可检查的结果，再拆成每周可完成的小任务，最后给每个任务配一个验收标准。这样做以后，执行效率和心态都稳定了不少。尤其在课程、社团、活动并行的阶段，节奏比冲刺更重要。"
  $b = "从$roleHint的角度看，最有效的不是临时加班，而是把协作流程提前跑通：谁负责、什么时候完成、出现问题找谁兜底。看起来是小事，但对团队体验影响很大。建议大家固定一个小复盘习惯：每周记录一次做对了什么、踩坑在哪里、下周怎么改。长期坚持，个人成长会非常明显。也欢迎在评论区分享你的方法，我们可以一起把这些经验沉淀成可复用模板。"
  return $a + $b
}

function Build-MarkdownContent([string]$boardName, [string]$roleHint) {
  $main = Build-LongContent $boardName $roleHint
  return "## 这周实践复盘`n`n1. 明确目标：先定义结果，再安排步骤。`n2. 控制节奏：按周推进，避免临时堆任务。`n3. 协同执行：提前确认分工和反馈节点。`n4. 复盘迭代：把经验写下来，下次直接复用。`n`n$main"
}

function Build-GalleryContent([string]$boardName) {
  return "这组图文主要记录【$boardName】相关的一个完整过程：准备、执行、问题处理、结果展示、复盘优化。每张图都配了中文说明，重点不是展示画面，而是沉淀可复用的方法。你可以把它理解为一个可直接套用的执行模板：先做准备清单，再做现场节奏控制，遇到问题及时复盘，最后把经验整理成文。这样下次再做同类事情时，效率会明显提高。"
}

$boards = @(
  @{ id = 1; name = "学习交流"; tags = @("学习方法","复盘","校园成长"); kw = @("library","study","notebook","students","campus") },
  @{ id = 2; name = "校园生活"; tags = @("校园生活","日常","效率"); kw = @("campus","cafeteria","dorm","sunset","students") },
  @{ id = 3; name = "通知公告"; tags = @("通知解读","执行清单","时间管理"); kw = @("notice","calendar","meeting","schedule","bulletin") },
  @{ id = 4; name = "技术问答"; tags = @("技术成长","问题排查","协作"); kw = @("code","laptop","developer","software","programming") },
  @{ id = 5; name = "求职就业"; tags = @("求职","简历","面试"); kw = @("resume","interview","career","office","job") },
  @{ id = 6; name = "心动告白"; tags = @("沟通","边界感","情感表达"); kw = @("flowers","park","letters","evening","city") },
  @{ id = 7; name = "校园贴吧"; tags = @("校园热点","社团","讨论"); kw = @("community","festival","club","event","campus") }
)

$accounts = @(
  @{ u = "admin"; p = "Admin123!"; roleHint = "系统管理和组织协同" },
  @{ u = "teacher_li"; p = "Teacher123!"; roleHint = "课程指导和项目实践" },
  @{ u = "duanzhijie"; p = "AAAjt123@"; roleHint = "学生学习和校园活动参与" },
  @{ u = "张三"; p = "zhangsan"; roleHint = "学生日常和社交沟通" }
)

$tokens = @{}
foreach ($acc in $accounts) { $tokens[$acc.u] = Login $acc.u $acc.p }
$adminToken = $tokens["admin"]

$externalLinks = @(
  "https://www.moe.gov.cn/",
  "https://www.gov.cn/",
  "https://www.xinhuanet.com/",
  "https://www.people.com.cn/"
)

# 角色偏好板块（在全覆盖基础上再加偏好帖）
$preferences = @{
  "admin" = @(1,3,7)
  "teacher_li" = @(4,5,3)
  "duanzhijie" = @(1,2,7)
  "张三" = @(2,6,7)
}

$created = New-Object System.Collections.Generic.List[object]

foreach ($acc in $accounts) {
  $u = $acc.u
  $token = $tokens[$u]
  $hint = $acc.roleHint

  # 第一层：全板块覆盖（每个板块 1 帖，格式循环，保证每个账号覆盖全部板块+全部格式）
  for ($i = 0; $i -lt $boards.Count; $i++) {
    $b = $boards[$i]
    $fmtIndex = $i % 4
    $fmt = @("rich_text","markdown","external_link","image_gallery")[$fmtIndex]
    $title = "[$u] $($b.name)实用经验分享（第$($i+1)期）"

    if ($fmt -eq "image_gallery") {
      $files = Download-WebImages -prefix ($u + "_b3_base_" + $b.id + "_" + (Get-Random -Minimum 1000 -Maximum 9999)) -keywords $b.kw
      $urls = Upload-Images -token $token -paths $files
      $payload = @{
        title = $title
        summary = "围绕$($b.name)的生活化图文记录，强调过程和方法。"
        content = Build-GalleryContent $b.name
        format = "image_gallery"
        attachments = $urls
        galleryCaptions = @("准备阶段：目标和分工","执行阶段：节奏和协作","问题处理：响应和调整","结果展示：数据和反馈","复盘优化：方法沉淀")
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }
    } elseif ($fmt -eq "external_link") {
      $link = $externalLinks[$i % $externalLinks.Count]
      $payload = @{
        title = $title
        summary = "结合公开信息源，给出可执行的校园实践建议。"
        content = Build-LongContent $b.name $hint
        format = "external_link"
        linkUrl = $link
        linkTitle = "$($b.name)相关延伸阅读"
        linkSummary = "建议先看本帖要点，再结合公开来源核验。"
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }
    } elseif ($fmt -eq "markdown") {
      $payload = @{
        title = $title
        summary = "把经验拆成步骤，便于直接落地执行。"
        content = Build-MarkdownContent $b.name $hint
        format = "markdown"
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }
    } else {
      $payload = @{
        title = $title
        summary = "贴近校园场景的经验分享，强调节奏与复盘。"
        content = Build-LongContent $b.name $hint
        format = "rich_text"
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }
    }

    $post = Create-Post -token $token -payload $payload
    $created.Add([pscustomobject]@{ id = $post.id; title = $post.title; author = $u; format = $post.format; board = $b.name })
  }

  # 第二层：角色偏好增量（每人再加 5 帖）
  for ($k = 0; $k -lt 5; $k++) {
    $prefBoardId = $preferences[$u][$k % $preferences[$u].Count]
    $b = $boards | Where-Object { $_.id -eq $prefBoardId } | Select-Object -First 1
    $fmt = @("rich_text","markdown","external_link","image_gallery","rich_text")[$k]
    $title = "[$u] $($b.name)偏好主题实践记录（加更$($k+1)）"

    if ($fmt -eq "image_gallery") {
      $files = Download-WebImages -prefix ($u + "_b3_pref_" + $b.id + "_" + (Get-Random -Minimum 1000 -Maximum 9999)) -keywords $b.kw
      $urls = Upload-Images -token $token -paths $files
      $payload = @{
        title = $title
        summary = "偏好主题图文记录，内容更贴近日常场景。"
        content = Build-GalleryContent $b.name
        format = "image_gallery"
        attachments = $urls
        galleryCaptions = @("准备","执行","处理","展示","复盘")
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }
    } elseif ($fmt -eq "external_link") {
      $link = $externalLinks[($k + $prefBoardId) % $externalLinks.Count]
      $payload = @{
        title = $title
        summary = "结合公开来源的偏好主题经验复盘。"
        content = Build-LongContent $b.name $hint
        format = "external_link"
        linkUrl = $link
        linkTitle = "$($b.name)延伸阅读"
        linkSummary = "从真实案例出发，给出可执行建议。"
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }
    } elseif ($fmt -eq "markdown") {
      $payload = @{
        title = $title
        summary = "偏好主题步骤化整理，便于参考。"
        content = Build-MarkdownContent $b.name $hint
        format = "markdown"
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }
    } else {
      $payload = @{
        title = $title
        summary = "偏好主题的生活化经验总结。"
        content = Build-LongContent $b.name $hint
        format = "rich_text"
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }
    }

    $post = Create-Post -token $token -payload $payload
    $created.Add([pscustomobject]@{ id = $post.id; title = $post.title; author = $u; format = $post.format; board = $b.name })
  }
}

foreach ($c in $created) {
  Approve-Post -adminToken $adminToken -postId ([int]$c.id)
}

Write-Output ("CREATED_COUNT={0}" -f $created.Count)
$created | Sort-Object id | ForEach-Object {
  Write-Output ("{0}`t{1}`t{2}`t{3}`t{4}" -f $_.id, $_.author, $_.board, $_.format, $_.title)
}
