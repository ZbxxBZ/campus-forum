$ErrorActionPreference = "Stop"

$Base = "http://localhost:8080/api/v1"

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

function BuildText([string]$scene, [string]$angle) {
  return "这篇内容围绕$scene整理，重点放在可执行和可复盘。最近一段时间我发现，很多问题不是不会做，而是没有稳定节奏：任务边界不清、协作时间不固定、复盘习惯缺失。我的做法是先写结果定义，再拆执行动作，然后固定同步点，最后做一周复盘。$angle 从实操看，这样做能明显减少返工和临时沟通成本，情绪也会更稳定。建议大家把今天最关键的一件事提前完成，再把协作事项安排在固定时段，避免整天被打断。长期坚持下来，学习、活动和生活的掌控感都会提升。"
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

$specialByRole = @{
  "super_admin" = @(
    @{ boardId=3; format="rich_text"; title="考试周通知冲突治理：一次真实排期复盘"; scene="考试周通知冲突治理"; angle="从全局管理视角看" },
    @{ boardId=7; format="markdown"; title="大型活动当天的应急分工表怎么设计"; scene="校园大型活动应急协同"; angle="从治理协同视角看" },
    @{ boardId=4; format="external_link"; title="权限边界梳理后，跨角色协作为什么更顺"; scene="权限与流程边界梳理"; angle="从系统治理视角看" },
    @{ boardId=3; format="image_gallery"; title="校内活动公告发布全流程图解"; scene="通知发布流程图解"; angle="从运营规范视角看" },
    @{ boardId=7; format="rich_text"; title="校园热点话题降噪：讨论规则落地周记"; scene="热点讨论秩序优化"; angle="从社区治理视角看" },
    @{ boardId=1; format="markdown"; title="管理侧复盘模板：如何把问题变成标准动作"; scene="管理复盘模板沉淀"; angle="从流程优化视角看" }
  );
  "admin" = @(
    @{ boardId=3; format="rich_text"; title="通知发布后执行偏差大？我这样追踪闭环"; scene="通知执行追踪"; angle="从管理执行视角看" },
    @{ boardId=4; format="markdown"; title="接口联调总返工，先统一字段口径再开干"; scene="接口联调协作"; angle="从执行落地视角看" },
    @{ boardId=7; format="external_link"; title="活动现场分工总失效？关键在预案而非临场"; scene="活动预案制定"; angle="从组织落地视角看" },
    @{ boardId=3; format="image_gallery"; title="一场校园讲座从通知到复盘的全过程"; scene="讲座运营流程"; angle="从运营视角看" },
    @{ boardId=4; format="rich_text"; title="跨角色协作会议怎么开才不空转"; scene="跨角色例会机制"; angle="从协同效率视角看" },
    @{ boardId=7; format="markdown"; title="贴吧高频问题清单：本周治理动作复盘"; scene="校园讨论治理"; angle="从问题闭环视角看" }
  );
  "teacher" = @(
    @{ boardId=1; format="rich_text"; title="课程作业拖延严重？这套拆解法能救场"; scene="课程作业推进"; angle="从教学实践视角看" },
    @{ boardId=4; format="markdown"; title="项目答辩前一周：老师最看重的三件事"; scene="课程项目答辩准备"; angle="从课程指导视角看" },
    @{ boardId=5; format="external_link"; title="实习季简历常见误区：老师批改后的共性问题"; scene="简历辅导"; angle="从就业指导视角看" },
    @{ boardId=1; format="image_gallery"; title="课堂小组展示改进前后对比记录"; scene="课堂展示优化"; angle="从教学改进视角看" },
    @{ boardId=4; format="rich_text"; title="技术实践课如何减少无效加班"; scene="技术课协作安排"; angle="从项目节奏视角看" },
    @{ boardId=5; format="markdown"; title="面试模拟课后反馈：表达和结构怎么一起练"; scene="面试训练复盘"; angle="从就业训练视角看" }
  );
  "student" = @(
    @{ boardId=2; format="rich_text"; title="宿舍作息磨合一周后，我们达成了这三条共识"; scene="宿舍作息磨合"; angle="从学生日常视角看" },
    @{ boardId=1; format="markdown"; title="四六级冲刺期，我把复习拆成了四个时间块"; scene="四六级冲刺安排"; angle="从学习节奏视角看" },
    @{ boardId=7; format="external_link"; title="社团报名信息太杂？我用四步法快速筛选"; scene="社团信息筛选"; angle="从校园参与视角看" },
    @{ boardId=6; format="image_gallery"; title="表达心意之前，我先做了这份沟通准备清单"; scene="情感沟通准备"; angle="从沟通边界视角看" },
    @{ boardId=2; format="rich_text"; title="食堂错峰一周实测：排队时间真的降下来了"; scene="食堂错峰实践"; angle="从生活效率视角看" },
    @{ boardId=1; format="markdown"; title="图书馆学习搭子协作规则：少内耗更高效"; scene="学习搭子协作"; angle="从学习协作视角看" }
  )
}

# 活跃用户
$userRows = & mysql --default-character-set=utf8mb4 -N -B -uroot -p123456 -D campus_forum -e "SET NAMES utf8mb4; SELECT username,password,role,COALESCE(NULLIF(display_name,''),username) FROM users WHERE status='active' ORDER BY id;"
$users = @()
foreach($r in $userRows){
  $a = $r -split "`t"
  if($a.Count -ge 4){ $users += [pscustomobject]@{ username=$a[0]; password=$a[1]; role=$a[2]; display=$a[3] } }
}
if($users.Count -eq 0){ throw "无活跃用户" }

$tokens = @{}
foreach($u in $users){ $tokens[$u.username] = Login $u.username $u.password }

$ids = New-Object System.Collections.Generic.List[int]
$seq = 0

foreach($u in $users){
  $roleKey = if($specialByRole.ContainsKey($u.role)){ $u.role } else { "student" }
  $templates = $specialByRole[$roleKey]
  foreach($tpl in $templates){
    $title = $tpl.title + "（第" + ((([Math]::Abs($u.username.GetHashCode()) + $seq) % 9) + 1) + "期）"
    $payload = @{
      title = $title
      summary = "特色帖子：$($tpl.scene) 场景复盘。"
      content = BuildText $tpl.scene $tpl.angle
      format = $tpl.format
      tags = @("特色专题","生活化","经验复盘")
      boardId = $tpl.boardId
      visibility = "public"
    }
    if($tpl.format -eq "markdown"){
      $payload.content = "## 关键动作`n`n1. 明确目标`n2. 固定节奏`n3. 协作同步`n4. 复盘优化`n`n" + (BuildText $tpl.scene $tpl.angle)
    } elseif($tpl.format -eq "external_link"){
      $payload.linkUrl = $links[$seq % $links.Count]
      $payload.linkTitle = "延伸阅读"
      $payload.linkSummary = "结合公开资料理解帖子场景。"
    } elseif($tpl.format -eq "image_gallery"){
      $imgOffset = ($seq + [Math]::Abs($u.username.GetHashCode())) % $galleryUrls.Count
      $payload.content = "这组图文围绕$($tpl.scene)展开，展示准备、执行和复盘的关键过程。"
      $payload.attachments = @(
        $galleryUrls[$imgOffset % $galleryUrls.Count],
        $galleryUrls[($imgOffset+1) % $galleryUrls.Count],
        $galleryUrls[($imgOffset+2) % $galleryUrls.Count],
        $galleryUrls[($imgOffset+3) % $galleryUrls.Count],
        $galleryUrls[($imgOffset+4) % $galleryUrls.Count]
      )
      $payload.galleryCaptions = @("准备阶段","执行阶段","问题处理","结果展示","复盘优化")
    }
    $id = Create-Post $tokens[$u.username] $payload
    $ids.Add($id) | Out-Null
    $seq++
  }
}

if($ids.Count -gt 0){
  $minId = ($ids | Measure-Object -Minimum).Minimum
  $maxId = ($ids | Measure-Object -Maximum).Maximum
  & mysql --default-character-set=utf8mb4 -uroot -p123456 -D campus_forum -e "SET @base='2026-04-12 20:00:00'; UPDATE posts SET status='published', created_at = DATE_FORMAT(DATE_SUB(@base, INTERVAL ((id-$minId) % 30) DAY) + INTERVAL ((id-$minId) % 23) HOUR + INTERVAL ((id-$minId) % 59) MINUTE, '%Y-%m-%d %H:%i:%s') WHERE id BETWEEN $minId AND $maxId;"
}

Write-Output ("SPECIAL_CREATED={0}" -f $ids.Count)
& mysql --default-character-set=utf8mb4 -uroot -p123456 -D campus_forum -e "SET NAMES utf8mb4; SELECT COUNT(*) AS cnt_today_after FROM posts WHERE created_at LIKE '2026-04-12%';"
