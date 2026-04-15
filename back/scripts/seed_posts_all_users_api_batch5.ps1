$ErrorActionPreference = "Stop"

$Base = "http://localhost:8080/api/v1"

function Invoke-ApiJson {
  param([string]$Method, [string]$Url, [string]$Token, [object]$Body)
  $headers = @{ "Content-Type" = "application/json; charset=utf-8"; "Accept" = "application/json" }
  if ($Token) { $headers["Authorization"] = "Bearer $Token" }
  $json = $null
  if ($null -ne $Body) { $json = $Body | ConvertTo-Json -Depth 12 -Compress }
  try {
    if ($null -eq $json) {
      return Invoke-RestMethod -Uri $Url -Method $Method -Headers $headers
    } else {
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
      return Invoke-RestMethod -Uri $Url -Method $Method -Headers $headers -Body $bytes
    }
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
  if ($resp.code -ne 0 -or -not $resp.data.post.id) {
    throw "发帖失败: $($payload.title)"
  }
  return [int]$resp.data.post.id
}

function Build-Rich([string]$board, [string]$title, [string]$hint) {
  return "这篇《$title》记录的是我在$board场景下的一次真实实践。过去我常常把任务集中到最后，结果是越忙越乱。后来我把事情拆成准备、执行、反馈、复盘四个阶段，并为每个阶段设置可检查节点，执行质量明显稳定下来。$hint，我会先锁定当天最关键的一件事，再安排协作同步时间，尽量减少临时沟通和重复确认。很多问题并不是能力不足，而是流程没有稳定。每周做一次短复盘：这周最有效的方法是什么、最耗时低效动作是什么、下周先改哪一步。坚持一段时间后，学习、活动和生活都会更有掌控感。"
}

function Build-Md([string]$board, [string]$title, [string]$hint) {
  $main = Build-Rich $board $title $hint
  return "## 操作步骤`n`n1. 先定结果，避免无效投入。`n2. 再拆动作，给每步设截止点。`n3. 固定同步，减少信息差。`n4. 及时复盘，保留有效做法。`n`n$main"
}

function Build-Gallery([string]$board, [string]$title) {
  return "《$title》这组图文围绕$board展开，按准备、执行、问题处理、结果展示、复盘优化五个阶段整理。每一张图都对应一个真实动作，不是单纯展示画面。目的是让后来者看完就能借鉴执行路径，把经验沉淀成可复用模板。建议结合图片说明逐条阅读，再按自己的实际场景做调整。"
}

$boards = @(
  @{ id = 1; name = "学习交流"; tags = @("学习方法","效率提升","复盘") },
  @{ id = 2; name = "校园生活"; tags = @("校园生活","作息","日常") },
  @{ id = 3; name = "通知公告"; tags = @("通知解读","执行清单","时间管理") },
  @{ id = 4; name = "技术问答"; tags = @("技术实践","问题排查","协作") },
  @{ id = 5; name = "求职就业"; tags = @("求职","简历","面试") },
  @{ id = 6; name = "心动告白"; tags = @("沟通","边界感","表达") },
  @{ id = 7; name = "校园贴吧"; tags = @("校园热点","社团","讨论") }
)

$titlePool = @{
  1 = @("早八不崩盘：我的晨间学习流程","错题本不再积灰：复盘法真的有用","图书馆两小时高效学习法","临近考试周，如何稳住节奏","学习搭子如何分工才高效","我把拖延改成了分段执行","课程多任务并行的一点心得","周计划不是装饰：这样写才有效");
  2 = @("宿舍作息冲突怎么解","食堂高峰排队的错峰实践","一周生活成本记录","晚间运动后如何快速恢复","室友沟通中的边界感","周末校园散步路线推荐","校园生活里的小确幸清单","手机时间管理实测记录");
  3 = @("通知太多看不过来怎么办","班级群消息提炼方法","活动通知落地前的核对清单","请假流程常见坑位提醒","考试周通知优先级划分","报名截止前必须确认的三件事","会议纪要如何写得可执行","临时通知下的应急安排");
  4 = @("接口联调返工的根因分析","小组项目延期的真实原因","从能跑到可维护的重构记录","一次线上故障排查复盘","新人接手项目如何快速入门","代码评审中最常见的问题","技术文档为什么总没人看","我用清单减少了调试时间");
  5 = @("简历项目经历怎么写不空","春招信息筛选四问法","面试紧张时的应对流程","实习周报怎么写更有价值","求职季时间分配实践","投递后跟进邮件模板经验","岗位JD阅读的三个重点","面试复盘如何真正改进");
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

$galleryUrls = @(
  "http://localhost:8080/uploads/images/2026/04/6541f8d3ecda4cb6ab152a58b5bd4a58.jpg",
  "http://localhost:8080/uploads/images/2026/04/d4cacf68ad2b44cd9f955ce773b1db17.jpg",
  "http://localhost:8080/uploads/images/2026/04/ed209a0a51c74c47ad7aa6b47829bc48.jpg",
  "http://localhost:8080/uploads/images/2026/04/f4850d78f6fa4dee92d9848e4f8339ff.jpg",
  "http://localhost:8080/uploads/images/2026/04/af472932ccf544dc9599082727c8646c.jpg",
  "http://localhost:8080/uploads/images/2026/04/94825850bffb45e78e752bc18605a87c.jpg",
  "http://localhost:8080/uploads/images/2026/04/1fae1353300d49e3ba125a00793ee874.jpg",
  "http://localhost:8080/uploads/images/2026/04/39f1073d662e49b584f97f52766e06ec.jpg"
)

$links = @("https://www.moe.gov.cn/","https://www.gov.cn/","https://www.xinhuanet.com/","https://www.people.com.cn/")

# 读取全部活跃用户
$userRows = & mysql --default-character-set=utf8mb4 -N -B -uroot -p123456 -D campus_forum -e "SET NAMES utf8mb4; SELECT username,password,role,COALESCE(NULLIF(display_name,''),username) FROM users WHERE status='active' ORDER BY id;"
$users = @()
foreach($r in $userRows){
  $a = $r -split "`t"
  if($a.Count -ge 4){
    $users += [pscustomobject]@{ username=$a[0]; password=$a[1]; role=$a[2]; display=$a[3] }
  }
}
if($users.Count -eq 0){ throw "无活跃用户" }

# 删除今天帖子，彻底重建
& mysql --default-character-set=utf8mb4 -uroot -p123456 -D campus_forum -e "DELETE FROM posts WHERE created_at LIKE '2026-04-12%';"

$tokens = @{}
foreach($u in $users){
  $tokens[$u.username] = Login $u.username $u.password
}

$createdIds = New-Object System.Collections.Generic.List[int]
$seq = 0

foreach($u in $users){
  $hint = if($roleHint.ContainsKey($u.role)){ $roleHint[$u.role] } else { "从校园实践视角看" }
  $pref = if($rolePref.ContainsKey($u.role)){ $rolePref[$u.role] } else { $rolePref["student"] }
  $token = $tokens[$u.username]

  # 28帖：每板块x每格式
  foreach($b in $boards){
    $fmts = @("rich_text","markdown","external_link","image_gallery")
    foreach($fmt in $fmts){
      $ti = ($seq + $b.id) % $titlePool[$b.id].Count
      $title = $titlePool[$b.id][$ti]
      $summary = "围绕$($b.name)的生活化经验总结，强调可执行与可复盘。"

      $payload = @{
        title = $title
        summary = $summary
        content = (Build-Rich $b.name $title $hint)
        format = $fmt
        tags = $b.tags
        boardId = $b.id
        visibility = "public"
      }

      if($fmt -eq "markdown"){
        $payload.content = Build-Md $b.name $title $hint
      } elseif($fmt -eq "external_link"){
        $payload.content = Build-Rich $b.name $title $hint
        $payload.linkUrl = $links[$seq % $links.Count]
        $payload.linkTitle = "$($b.name)延伸阅读"
        $payload.linkSummary = "建议先看帖子要点，再结合公开来源核验。"
      } elseif($fmt -eq "image_gallery"){
        $payload.content = Build-Gallery $b.name $title
        $payload.attachments = @(
          $galleryUrls[($seq+0)%$galleryUrls.Count],
          $galleryUrls[($seq+1)%$galleryUrls.Count],
          $galleryUrls[($seq+2)%$galleryUrls.Count],
          $galleryUrls[($seq+3)%$galleryUrls.Count],
          $galleryUrls[($seq+4)%$galleryUrls.Count]
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
    $ti = ($seq + $k + $bid) % $titlePool[$bid].Count
    $title = $titlePool[$bid][$ti]
    $summary = "围绕$($b.name)偏好主题的生活化记录。"

    $payload = @{
      title = $title
      summary = $summary
      content = (Build-Rich $b.name $title $hint)
      format = $fmt
      tags = $b.tags
      boardId = $b.id
      visibility = "public"
    }

    if($fmt -eq "markdown"){
      $payload.content = Build-Md $b.name $title $hint
    } elseif($fmt -eq "external_link"){
      $payload.content = Build-Rich $b.name $title $hint
      $payload.linkUrl = $links[($seq+$k) % $links.Count]
      $payload.linkTitle = "$($b.name)参考资料"
      $payload.linkSummary = "结合公开资料给出可执行建议。"
    } elseif($fmt -eq "image_gallery"){
      $payload.content = Build-Gallery $b.name $title
      $payload.attachments = @(
        $galleryUrls[($seq+1)%$galleryUrls.Count],
        $galleryUrls[($seq+2)%$galleryUrls.Count],
        $galleryUrls[($seq+3)%$galleryUrls.Count],
        $galleryUrls[($seq+4)%$galleryUrls.Count],
        $galleryUrls[($seq+5)%$galleryUrls.Count]
      )
      $payload.galleryCaptions = @("准备阶段：目标和分工","执行阶段：节奏和协作","问题处理：定位和响应","结果展示：关键反馈","复盘优化：经验沉淀")
    }

    $id = Create-Post $token $payload
    $createdIds.Add($id) | Out-Null
    $seq++
  }
}

# 批量置为 published（避免逐条审核调用过慢）
if($createdIds.Count -gt 0){
  $minId = ($createdIds | Measure-Object -Minimum).Minimum
  $maxId = ($createdIds | Measure-Object -Maximum).Maximum
  & mysql --default-character-set=utf8mb4 -uroot -p123456 -D campus_forum -e "UPDATE posts SET status='published', risk_level='low' WHERE id BETWEEN $minId AND $maxId AND created_at LIKE '2026-04-12%';"
}

Write-Output ("ACTIVE_USERS={0}" -f $users.Count)
Write-Output ("CREATED_COUNT={0}" -f $createdIds.Count)

& mysql --default-character-set=utf8mb4 -uroot -p123456 -D campus_forum -e "SET NAMES utf8mb4; SELECT COUNT(*) AS cnt_today FROM posts WHERE created_at LIKE '2026-04-12%'; SELECT author,COUNT(*) AS cnt,COUNT(DISTINCT board_id) AS boards,COUNT(DISTINCT format) AS formats FROM posts WHERE created_at LIKE '2026-04-12%' GROUP BY author ORDER BY author; SELECT author,COUNT(*) AS conf_gallery_cnt FROM posts WHERE created_at LIKE '2026-04-12%' AND board_id=6 AND format='image_gallery' GROUP BY author ORDER BY author; SELECT MIN(CHAR_LENGTH(content)) AS min_text_len FROM posts WHERE created_at LIKE '2026-04-12%' AND format IN ('rich_text','markdown','external_link'); SELECT MIN(JSON_LENGTH(attachments_json)) AS min_gallery,MAX(JSON_LENGTH(attachments_json)) AS max_gallery FROM posts WHERE created_at LIKE '2026-04-12%' AND format='image_gallery'; SELECT id,title,author,board_id,format,CHAR_LENGTH(content) AS len FROM posts WHERE created_at LIKE '2026-04-12%' ORDER BY id DESC LIMIT 15;"
