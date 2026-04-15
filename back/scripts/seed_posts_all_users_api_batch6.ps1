$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

$Base = "http://localhost:8080/api/v1"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ImgDir = Join-Path $ScriptDir "downloaded_images_batch6"
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

function Create-Post([string]$token, [hashtable]$payload) {
  $resp = Invoke-ApiJson -Method "Post" -Url "$Base/posts" -Token $token -Body $payload
  if ($resp.code -ne 0 -or -not $resp.data.post.id) { throw "发帖失败: $($payload.title)" }
  return [int]$resp.data.post.id
}

function Download-WebImage([string]$seed, [string]$outPath) {
  $url = "https://picsum.photos/seed/$([uri]::EscapeDataString($seed))/1280/720"
  for ($t = 1; $t -le 4; $t++) {
    try {
      & curl.exe -L --ssl-no-revoke --silent --show-error --fail $url -o $outPath | Out-Null
      if (Test-Path $outPath) { return $true }
    } catch {}
    Start-Sleep -Milliseconds 300
  }
  return $false
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

function Build-Rich([string]$boardName, [string]$title, [string]$hint) {
  return "《$title》来自$boardName场景的真实复盘。以前我做事经常先忙起来再想路径，结果返工很多。后来把任务拆成准备、执行、反馈、复盘四段，每段都配检查点，效率稳定了很多。$hint，关键是把当天最重要的一件事提前锁定，再安排协作同步时间，减少临时沟通成本。真正有效的提升往往不是更拼命，而是更有节奏。每周固定复盘一次：本周有效做法、低效动作、下周改进点。坚持下来，学习和生活都会更可控。"
}

function Build-Md([string]$boardName, [string]$title, [string]$hint) {
  $main = Build-Rich $boardName $title $hint
  return "## 可执行拆解`n`n1. 先定义结果，避免无效投入。`n2. 再拆动作，给每步设置截止点。`n3. 固定协作同步，减少信息差。`n4. 周复盘持续优化。`n`n$main"
}

function Build-Gallery([string]$boardName, [string]$title) {
  return "这组《$title》图文记录围绕$boardName展开，按准备、执行、问题处理、结果展示、复盘优化五个阶段组织。每张图都对应一个具体动作，强调过程可复用，而不是只展示结果。你可以直接把这套流程迁移到自己的学习、活动或协作任务里。"
}

$boards = @(
  @{ id = 1; name = "学习交流"; tags = @("学习方法","效率提升","复盘"); kw = @("library","study","students","notebook","campus") },
  @{ id = 2; name = "校园生活"; tags = @("校园生活","作息","日常"); kw = @("dorm","cafeteria","campus","sunset","student") },
  @{ id = 3; name = "通知公告"; tags = @("通知解读","执行清单","时间管理"); kw = @("notice","calendar","schedule","meeting","board") },
  @{ id = 4; name = "技术问答"; tags = @("技术实践","问题排查","协作"); kw = @("code","programming","developer","laptop","software") },
  @{ id = 5; name = "求职就业"; tags = @("求职","简历","面试"); kw = @("resume","career","interview","office","job") },
  @{ id = 6; name = "心动告白"; tags = @("沟通","边界感","表达"); kw = @("flowers","park","street","letters","evening") },
  @{ id = 7; name = "校园贴吧"; tags = @("校园热点","社团","讨论"); kw = @("community","club","event","festival","campus") }
)

$titlePool = @{
  1 = @("早八不崩盘：我的晨间学习流程","错题本不再积灰：复盘法实测","图书馆两小时高效学习法","临近考试周，如何稳住节奏","学习搭子如何分工更高效","我把拖延改成分段执行","课程并行期的时间分配法","周计划这样写才会执行");
  2 = @("宿舍作息冲突怎么解","食堂高峰错峰实践记录","一周生活成本复盘","晚间运动后的恢复安排","室友沟通中的边界感","周末校园散步路线分享","校园生活小确幸清单","手机时间管理实测");
  3 = @("通知太多看不过来怎么办","班级群消息提炼方法","活动通知落地核对清单","请假流程常见坑位提醒","考试周通知优先级划分","报名截止前确认三件事","会议纪要如何写可执行","临时通知下的应急安排");
  4 = @("接口联调返工的根因","小组项目延期真实原因","从能跑到可维护的重构记录","一次线上故障排查复盘","新人接手项目快速入门","代码评审高频问题清单","技术文档没人看的原因","我用清单减少调试时间");
  5 = @("简历项目经历怎么写不空","春招信息筛选四问法","面试紧张时的应对流程","实习周报怎么写更有价值","求职季时间分配实践","投递后跟进邮件模板","岗位JD阅读三个重点","面试复盘如何真正改进");
  6 = @("喜欢可以表达但要有边界","如何把感受说清楚","关系中的尊重与分寸","聊天总尴尬时我这样做","被误解后如何有效沟通","告白前先问自己三件事","真诚表达不等于情绪宣泄","关于陪伴与安全感的思考");
  7 = @("本周校园热帖观察","社团活动参与度提升记录","校园讨论如何避免跑偏","一次活动组织复盘","校园二手交易防坑提醒","同学们最近在聊什么","社团招新流程改进建议","校园话题讨论礼仪建议")
}

$roleHint = @{
  "super_admin" = "从全局管理视角看";
  "admin" = "从管理执行视角看";
  "teacher" = "从教学和项目实践视角看";
  "student" = "从学生日常体验视角看"
}

$rolePref = @{
  "super_admin" = @(3,7,1,3,7,1,3,7,1,3,7,1);
  "admin" = @(3,4,7,3,4,7,3,4,7,3,4,7);
  "teacher" = @(4,5,3,4,5,3,4,5,3,4,5,3);
  "student" = @(2,1,7,2,1,7,2,1,7,2,1,7)
}

$links = @("https://www.moe.gov.cn/","https://www.gov.cn/","https://www.xinhuanet.com/","https://www.people.com.cn/")

# 拉取活跃用户
$userRows = & mysql --default-character-set=utf8mb4 -N -B -uroot -p123456 -D campus_forum -e "SET NAMES utf8mb4; SELECT username,password,role,COALESCE(NULLIF(display_name,''),username) FROM users WHERE status='active' ORDER BY id;"
$users = @()
foreach($r in $userRows){
  $a = $r -split "`t"
  if($a.Count -ge 4){ $users += [pscustomobject]@{ username=$a[0]; password=$a[1]; role=$a[2]; display=$a[3] } }
}
if($users.Count -eq 0){ throw "无活跃用户" }

# 删除当天旧数据
& mysql --default-character-set=utf8mb4 -uroot -p123456 -D campus_forum -e "DELETE FROM posts WHERE created_at LIKE '2026-04-12%';"

# 登录
$tokens = @{}
foreach($u in $users){ $tokens[$u.username] = Login $u.username $u.password }

# 准备每板块图池（每板块20张，降低重复）
$boardImagePool = @{}
foreach($b in $boards){
  $pool = New-Object System.Collections.Generic.List[string]
  $batch = 1
  while($pool.Count -lt 20){
    $tempFiles = @()
    for($i=0; $i -lt 5; $i++){
      $seed = "b6-$($b.id)-$batch-$i-" + (Get-Random -Minimum 1000 -Maximum 9999)
      $path = Join-Path $ImgDir ("{0}_{1}_{2}.jpg" -f $b.id,$batch,$i)
      if(Download-WebImage $seed $path){ $tempFiles += $path }
    }
    if($tempFiles.Count -ge 5){
      $urls = Upload-Images $tokens["admin"] $tempFiles
      foreach($u in $urls){ $pool.Add($u) }
    } else {
      # 回退到已有本地图，避免流程中断
      $fallback = & mysql --default-character-set=utf8mb4 -N -B -uroot -p123456 -D campus_forum -e "SET NAMES utf8mb4; SELECT JSON_UNQUOTE(JSON_EXTRACT(attachments_json,'$[0]')) FROM posts WHERE format='image_gallery' AND board_id=$($b.id) AND JSON_LENGTH(attachments_json)>=5 LIMIT 20;"
      foreach($f in $fallback){ if($f){ $pool.Add($f) } }
      if($pool.Count -lt 5){ throw "板块$($b.name)图池不足" }
    }
    $batch++
    if($batch -gt 8 -and $pool.Count -lt 20){ break }
  }
  $boardImagePool[$b.id] = @($pool | Select-Object -First 20)
}

$createdIds = New-Object System.Collections.Generic.List[int]
$seq = 0

foreach($u in $users){
  $hint = if($roleHint.ContainsKey($u.role)){ $roleHint[$u.role] } else { "从校园实践视角看" }
  $pref = if($rolePref.ContainsKey($u.role)){ $rolePref[$u.role] } else { $rolePref["student"] }
  $token = $tokens[$u.username]

  # 28帖：每板块每格式
  foreach($b in $boards){
    $fmts = @("rich_text","markdown","external_link","image_gallery")
    foreach($fmt in $fmts){
      $ti = ($seq + [Math]::Abs($u.display.GetHashCode()) + $b.id) % $titlePool[$b.id].Count
      $suffix = @("实测版","复盘版","清单版","进阶版","执行版","周更版","优化版","实践版")[($seq+$b.id) % 8]
      $title = $titlePool[$b.id][$ti] + "（" + $suffix + "）"

      $payload = @{
        title = $title
        summary = "围绕$($b.name)的生活化经验总结，强调可执行与可复盘。"
        content = (Build-Rich $b.name $title $hint)
        format = $fmt
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }
      if($fmt -eq "markdown"){
        $payload.content = Build-Md $b.name $title $hint
      } elseif($fmt -eq "external_link"){
        $payload.linkUrl = $links[$seq % $links.Count]
        $payload.linkTitle = "$($b.name)延伸阅读"
        $payload.linkSummary = "建议先看帖子要点，再结合公开来源核验。"
      } elseif($fmt -eq "image_gallery"){
        $pool = $boardImagePool[$b.id]
        $imgOffset = ($seq + [Math]::Abs($u.username.GetHashCode())) % $pool.Count
        $payload.content = Build-Gallery $b.name $title
        $payload.attachments = @(
          $pool[$imgOffset % $pool.Count],
          $pool[($imgOffset+1) % $pool.Count],
          $pool[($imgOffset+2) % $pool.Count],
          $pool[($imgOffset+3) % $pool.Count],
          $pool[($imgOffset+4) % $pool.Count]
        )
        $payload.galleryCaptions = @("准备阶段：目标和分工","执行阶段：节奏和协作","问题处理：定位和响应","结果展示：关键反馈","复盘优化：经验沉淀")
      }
      $id = Create-Post $token $payload
      $createdIds.Add($id) | Out-Null
      $seq++
    }
  }

  # 12帖：角色偏好加更
  $extraFmt = @("rich_text","markdown","external_link","image_gallery","rich_text","markdown","external_link","image_gallery","rich_text","markdown","external_link","rich_text")
  for($k=0; $k -lt 12; $k++){
    $bid = $pref[$k]
    $b = $boards | Where-Object { $_.id -eq $bid } | Select-Object -First 1
    $fmt = $extraFmt[$k]
    $ti = ($seq + $k + [Math]::Abs($u.display.GetHashCode()) + $bid) % $titlePool[$bid].Count
    $suffix = @("加更","补充","周记","复盘","更新","实录","追踪","实践")[($k+$seq) % 8]
    $title = $titlePool[$bid][$ti] + "（" + $suffix + "）"

    $payload = @{
      title = $title
      summary = "围绕$($b.name)偏好主题的生活化记录。"
      content = (Build-Rich $b.name $title $hint)
      format = $fmt
      tags = $b.tags
      boardId = $b.id
      visibility = "public"
    }
    if($fmt -eq "markdown"){
      $payload.content = Build-Md $b.name $title $hint
    } elseif($fmt -eq "external_link"){
      $payload.linkUrl = $links[($seq+$k) % $links.Count]
      $payload.linkTitle = "$($b.name)参考资料"
      $payload.linkSummary = "结合公开资料给出可执行建议。"
    } elseif($fmt -eq "image_gallery"){
      $pool = $boardImagePool[$b.id]
      $imgOffset = ($seq + $k + [Math]::Abs($u.username.GetHashCode())) % $pool.Count
      $payload.content = Build-Gallery $b.name $title
      $payload.attachments = @(
        $pool[$imgOffset % $pool.Count],
        $pool[($imgOffset+2) % $pool.Count],
        $pool[($imgOffset+4) % $pool.Count],
        $pool[($imgOffset+6) % $pool.Count],
        $pool[($imgOffset+8) % $pool.Count]
      )
      $payload.galleryCaptions = @("准备阶段：目标和分工","执行阶段：节奏和协作","问题处理：定位和响应","结果展示：关键反馈","复盘优化：经验沉淀")
    }
    $id = Create-Post $token $payload
    $createdIds.Add($id) | Out-Null
    $seq++
  }
}

# 改状态 + 打散发布时间（近30天）
if($createdIds.Count -gt 0){
  $minId = ($createdIds | Measure-Object -Minimum).Minimum
  $maxId = ($createdIds | Measure-Object -Maximum).Maximum
  & mysql --default-character-set=utf8mb4 -uroot -p123456 -D campus_forum -e "SET @base='2026-04-12 20:00:00'; UPDATE posts SET status='published', risk_level='low', created_at = DATE_FORMAT(DATE_SUB(@base, INTERVAL ((id-$minId) % 30) DAY) + INTERVAL ((id-$minId) % 24) HOUR + INTERVAL ((id-$minId) % 60) MINUTE, '%Y-%m-%d %H:%i:%s') WHERE id BETWEEN $minId AND $maxId;"
}

Write-Output ("ACTIVE_USERS={0}" -f $users.Count)
Write-Output ("CREATED_COUNT={0}" -f $createdIds.Count)

& mysql --default-character-set=utf8mb4 -uroot -p123456 -D campus_forum -e "SET NAMES utf8mb4; SELECT COUNT(*) AS cnt_today FROM posts WHERE created_at LIKE '2026-04-12%'; SELECT MIN(created_at) AS min_created, MAX(created_at) AS max_created FROM posts WHERE id BETWEEN (SELECT MIN(id) FROM posts) AND (SELECT MAX(id) FROM posts); SELECT author,COUNT(*) AS cnt,COUNT(DISTINCT board_id) AS boards,COUNT(DISTINCT format) AS formats FROM posts WHERE id BETWEEN (SELECT MAX(id)-$($createdIds.Count-1) FROM posts) AND (SELECT MAX(id) FROM posts) GROUP BY author ORDER BY author; SELECT author,COUNT(*) AS conf_gallery_cnt FROM posts WHERE id BETWEEN (SELECT MAX(id)-$($createdIds.Count-1) FROM posts) AND (SELECT MAX(id) FROM posts) AND board_id=6 AND format='image_gallery' GROUP BY author ORDER BY author; SELECT MIN(CHAR_LENGTH(content)) AS min_text_len FROM posts WHERE id BETWEEN (SELECT MAX(id)-$($createdIds.Count-1) FROM posts) AND (SELECT MAX(id) FROM posts) AND format IN ('rich_text','markdown','external_link'); SELECT MIN(JSON_LENGTH(attachments_json)) AS min_gallery,MAX(JSON_LENGTH(attachments_json)) AS max_gallery FROM posts WHERE id BETWEEN (SELECT MAX(id)-$($createdIds.Count-1) FROM posts) AND (SELECT MAX(id) FROM posts) AND format='image_gallery';"
