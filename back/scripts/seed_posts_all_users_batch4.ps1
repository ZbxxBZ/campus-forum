$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

$Base = "http://localhost:8080/api/v1"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ImgDir = Join-Path $ScriptDir "downloaded_images_batch4"
if (-not (Test-Path $ImgDir)) { New-Item -ItemType Directory -Path $ImgDir | Out-Null }

function Invoke-ApiJson {
  param([string]$Method, [string]$Url, [string]$Token, [object]$Body)
  $headers = @{ "Content-Type" = "application/json; charset=utf-8"; "Accept" = "application/json" }
  if ($Token) { $headers["Authorization"] = "Bearer $Token" }
  $json = $null
  if ($null -ne $Body) { $json = $Body | ConvertTo-Json -Depth 12 -Compress }
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
    $ok = $false
    for ($try = 1; $try -le 4; $try++) {
      try {
        & curl.exe -L --ssl-no-revoke --silent --show-error --fail $url -o $path | Out-Null
        if (Test-Path $path) {
          $ok = $true
          break
        }
      } catch {}
      Start-Sleep -Milliseconds 500
    }
    if ($ok) { $files += $path }
  }
  return $files
}

function Get-ExistingGalleryUrls([int]$boardId) {
  $json = & mysql --default-character-set=utf8mb4 -N -B -uroot -p123456 -D campus_forum -e "SET NAMES utf8mb4; SELECT attachments_json FROM posts WHERE status='published' AND format='image_gallery' AND board_id=$boardId AND JSON_LENGTH(attachments_json)>=5 ORDER BY id DESC LIMIT 1;"
  if (-not $json) { return @() }
  try {
    $arr = $json | ConvertFrom-Json
    return @($arr | Select-Object -First 5)
  } catch {
    return @()
  }
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

function Build-RichContent([string]$boardName, [string]$title, [string]$displayName, [string]$roleHint) {
  $p1 = "这篇《$title》记录的是我在【$boardName】中的真实经历。过去我常常把任务堆到最后，结果是越忙越乱。后来我把事情拆成准备-执行-反馈-复盘四段，每段都写清楚目标和截止时间，执行效果明显提升。"
  $p2 = "以$displayName的实际场景为例，先把当天必须完成的一件事提前锁定，再把协作任务安排到固定时间点同步，能明显减少临时沟通成本。很多同学的问题不是能力不足，而是流程没有稳定下来。"
  $p3 = "从$roleHint角度看，长期有效的方法是持续复盘：本周最有效的方法是什么、最容易卡住的环节是什么、下周先改哪一步。只要坚持两三周，节奏感会逐步建立，学习、活动和生活都更可控。"
  return $p1 + $p2 + $p3
}

function Build-MarkdownContent([string]$boardName, [string]$title, [string]$displayName, [string]$roleHint) {
  $main = Build-RichContent $boardName $title $displayName $roleHint
  return "## 核心做法`n`n1. 先明确目标，避免无效投入。`n2. 再拆执行步骤，给每步设截止时间。`n3. 固定协作同步点，减少重复沟通。`n4. 每周做一次小复盘，持续迭代。`n`n$main"
}

function Build-GalleryContent([string]$boardName, [string]$title) {
  return "《$title》这组图文围绕【$boardName】展开，按准备、执行、问题处理、结果展示、复盘优化五个阶段整理。每一张图都对应一个现实动作，目的是让后来者看完就能照着做，而不是只看结果图。通过这种过程化记录，能把经验沉淀成可复用模板。"
}

$boards = @(
  @{ id = 1; name = "学习交流"; tags = @("学习方法","复盘","效率"); kw = @("library","study","students","note","campus") },
  @{ id = 2; name = "校园生活"; tags = @("校园生活","作息","日常"); kw = @("campus","dorm","cafeteria","sunset","student") },
  @{ id = 3; name = "通知公告"; tags = @("通知解读","执行清单","优先级"); kw = @("notice","calendar","schedule","board","meeting") },
  @{ id = 4; name = "技术问答"; tags = @("技术实践","问题排查","协作"); kw = @("code","programming","laptop","developer","software") },
  @{ id = 5; name = "求职就业"; tags = @("求职","简历","面试"); kw = @("resume","career","interview","office","job") },
  @{ id = 6; name = "心动告白"; tags = @("沟通","边界感","表达"); kw = @("park","flowers","street","letter","evening") },
  @{ id = 7; name = "校园贴吧"; tags = @("校园热点","社团","讨论"); kw = @("community","club","event","festival","campus") }
)

$titlePool = @{
  1 = @("早八不崩盘：我的晨间学习节奏是这样建立的","错题本不再积灰：我把复盘变成每天10分钟","图书馆学习搭子怎么配合才高效")
  2 = @("宿舍作息冲突怎么解：先约定再提醒","食堂高峰排队太久？我试了两周错峰方案","一周生活成本记录：怎样花得值又不焦虑")
  3 = @("通知太多看不过来？这套三层分类法很好用","班级群消息刷太快，我的关键信息提取方法","活动通知落地总出错？先做执行清单")
  4 = @("小组项目总延期，真正卡点常在沟通而非代码","接口联调总返工？先统一字段和错误码","从能跑到可维护：我最近的代码整理习惯")
  5 = @("简历写不出亮点？试试问题-行动-结果结构","春招信息太杂，我用四个问题快速筛选","面试紧张怎么破：我用三次模拟找到节奏")
  6 = @("喜欢可以表达，但边界感必须在线","关系里最有用的一件事：把感受说清楚","聊天不再尬住：我学会了先倾听再回应")
  7 = @("本周校园热帖复盘：大家最关心的三件事","社团活动参与感低？问题可能在前期分工","校园讨论容易跑偏？我这样拉回主题")
}

$externalLinks = @(
  "https://www.moe.gov.cn/",
  "https://www.gov.cn/",
  "https://www.xinhuanet.com/",
  "https://www.people.com.cn/"
)

$rolePrefBoards = @{
  "super_admin" = @(3,7,1,3,7)
  "admin" = @(3,4,7,3,4)
  "teacher" = @(4,5,3,4,5)
  "student" = @(2,1,7,2,1)
}

$roleHints = @{
  "super_admin" = "全局管理和流程协同"
  "admin" = "管理执行和问题闭环"
  "teacher" = "教学指导和项目实践"
  "student" = "学习成长和校园参与"
}

# 全部活跃用户
$userLines = & mysql --default-character-set=utf8mb4 -N -B -uroot -p123456 -D campus_forum -e "SET NAMES utf8mb4; SELECT username,password,role,COALESCE(NULLIF(display_name,''),username) FROM users WHERE status='active' ORDER BY id;"
$users = @()
foreach ($line in $userLines) {
  $parts = $line -split "`t"
  if ($parts.Count -ge 4) {
    $users += [pscustomobject]@{
      username = $parts[0]
      password = $parts[1]
      role = $parts[2]
      displayName = $parts[3]
    }
  }
}
if ($users.Count -eq 0) { throw "无活跃用户" }

$tokens = @{}
$failedUsers = New-Object System.Collections.Generic.List[string]
foreach ($u in $users) {
  try { $tokens[$u.username] = Login $u.username $u.password } catch { $failedUsers.Add($u.username) | Out-Null }
}
if (-not $tokens.ContainsKey("admin")) { throw "admin 登录失败" }
$adminToken = $tokens["admin"]

# 每个板块准备一套图（优先下载并上传，失败则回退到库中已有上传图）
$boardGalleryUrls = @{}
foreach ($b in $boards) {
  $files = Download-WebImages -prefix ("b4_" + $b.id + "_" + (Get-Random -Minimum 1000 -Maximum 9999)) -keywords $b.kw
  if ($files.Count -ge 5) {
    $urls = Upload-Images -token $adminToken -paths $files
    $boardGalleryUrls[$b.id] = $urls
  } else {
    $fallback = Get-ExistingGalleryUrls -boardId $b.id
    if ($fallback.Count -ge 5) {
      $boardGalleryUrls[$b.id] = $fallback
    } else {
      throw "板块[$($b.name)]图片准备失败：下载失败且无可用历史图"
    }
  }
}

$created = New-Object System.Collections.Generic.List[object]

foreach ($u in $users) {
  if (-not $tokens.ContainsKey($u.username)) { continue }
  $token = $tokens[$u.username]
  $hint = if ($roleHints.ContainsKey($u.role)) { $roleHints[$u.role] } else { "校园学习与协作实践" }
  $prefBoards = if ($rolePrefBoards.ContainsKey($u.role)) { $rolePrefBoards[$u.role] } else { @(2,1,7,2,1) }

  # A. 每用户7帖：每个板块1帖，格式循环，保证覆盖所有板块+所有格式
  for ($i = 0; $i -lt $boards.Count; $i++) {
    $b = $boards[$i]
    $fmt = @("rich_text","markdown","external_link","image_gallery","rich_text","markdown","external_link")[$i]
    $title = $titlePool[$b.id][($i + [Math]::Abs($u.username.GetHashCode())) % $titlePool[$b.id].Count] + "（" + $u.displayName + "）"

    if ($fmt -eq "image_gallery") {
      $payload = @{
        title = $title
        summary = "图文方式复盘$($b.name)真实过程。"
        content = Build-GalleryContent $b.name $title
        format = "image_gallery"
        attachments = $boardGalleryUrls[$b.id]
        galleryCaptions = @("准备","执行","处理","展示","复盘")
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }
    } elseif ($fmt -eq "external_link") {
      $payload = @{
        title = $title
        summary = "结合公开来源沉淀实践建议。"
        content = Build-RichContent $b.name $title $u.displayName $hint
        format = "external_link"
        linkUrl = $externalLinks[$i % $externalLinks.Count]
        linkTitle = "$($b.name)参考资料"
        linkSummary = "建议先看要点，再对照公开信息。"
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }
    } elseif ($fmt -eq "markdown") {
      $payload = @{
        title = $title
        summary = "步骤化整理，便于直接落地。"
        content = Build-MarkdownContent $b.name $title $u.displayName $hint
        format = "markdown"
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }
    } else {
      $payload = @{
        title = $title
        summary = "贴近生活的经验复盘。"
        content = Build-RichContent $b.name $title $u.displayName $hint
        format = "rich_text"
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }
    }

    $post = Create-Post -token $token -payload $payload
    $created.Add([pscustomobject]@{ id = $post.id; author = $u.username; role = $u.role; board = $b.name; format = $post.format; title = $title }) | Out-Null
  }

  # B. 每用户再加5帖：角色偏好板块，强化真实分布
  for ($k = 0; $k -lt 5; $k++) {
    $boardId = $prefBoards[$k]
    $b = $boards | Where-Object { $_.id -eq $boardId } | Select-Object -First 1
    $fmt = @("rich_text","markdown","external_link","image_gallery","rich_text")[$k]
    $title = $titlePool[$boardId][($k + [Math]::Abs($u.displayName.GetHashCode())) % $titlePool[$boardId].Count] + "（偏好加更" + ($k+1) + "·" + $u.displayName + "）"

    if ($fmt -eq "image_gallery") {
      $payload = @{
        title = $title
        summary = "偏好板块图文记录，突出真实场景。"
        content = Build-GalleryContent $b.name $title
        format = "image_gallery"
        attachments = $boardGalleryUrls[$b.id]
        galleryCaptions = @("准备","执行","处理","展示","复盘")
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }
    } elseif ($fmt -eq "external_link") {
      $payload = @{
        title = $title
        summary = "偏好板块的公开信息复盘。"
        content = Build-RichContent $b.name $title $u.displayName $hint
        format = "external_link"
        linkUrl = $externalLinks[($k + $boardId) % $externalLinks.Count]
        linkTitle = "$($b.name)延伸阅读"
        linkSummary = "从现实问题出发的参考资料。"
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }
    } elseif ($fmt -eq "markdown") {
      $payload = @{
        title = $title
        summary = "偏好板块步骤化总结。"
        content = Build-MarkdownContent $b.name $title $u.displayName $hint
        format = "markdown"
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }
    } else {
      $payload = @{
        title = $title
        summary = "偏好板块的生活化复盘。"
        content = Build-RichContent $b.name $title $u.displayName $hint
        format = "rich_text"
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }
    }

    $post = Create-Post -token $token -payload $payload
    $created.Add([pscustomobject]@{ id = $post.id; author = $u.username; role = $u.role; board = $b.name; format = $post.format; title = $title }) | Out-Null
  }
}

foreach ($item in $created) {
  Approve-Post -adminToken $adminToken -postId ([int]$item.id)
}

Write-Output ("TOTAL_ACTIVE_USERS={0}" -f $users.Count)
Write-Output ("LOGIN_FAILED={0}" -f $failedUsers.Count)
if ($failedUsers.Count -gt 0) { Write-Output ("FAILED_USERS=" + ($failedUsers -join ",")) }
Write-Output ("CREATED_COUNT={0}" -f $created.Count)
$created | Group-Object author | Sort-Object Name | ForEach-Object {
  Write-Output ("USER_POSTS`t{0}`t{1}" -f $_.Name, $_.Count)
}
