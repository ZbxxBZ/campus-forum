$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

$Base = "http://localhost:8080/api/v1"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ImgDir = Join-Path $ScriptDir "downloaded_images_batch2"
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

$Long1 = '今天想分享一个非常日常但很有用的小经验：把一天中最容易分心的时间段先留给机械任务，把最清醒的时间留给需要思考的事情。比如上午第一节课前后我会处理需要专注的学习任务，午后容易困的时候做整理和沟通，晚上再做轻复盘。这样安排以后，整天会更有掌控感。我们在校园生活里经常被临时通知和社交打断，如果没有固定节奏，很容易出现忙了一天但没有关键产出的情况。建议每晚花十分钟写下三件事：今天最有效的一件、最耗时但低效的一件、明天必须完成的一件。坚持两周就会看到变化。'
$Long2 = '另外一个贴近生活的点是“提前沟通”。很多宿舍、社团和小组矛盾，并不是价值观冲突，而是信息没有说清楚。比如活动安排、值日顺序、任务截止时间，如果只在群里说一句，很容易理解不一致。我的做法是：先把规则写成简单清单，再明确谁负责、什么时候验收，最后留一个反馈窗口。这个方法不复杂，但能减少大量重复解释和情绪消耗。希望这篇帖子能给大家一个可直接套用的模板，让学习和生活都更顺一点。'
$GalleryText = '这组图文围绕校园真实场景整理：从前期准备、现场执行、问题处理、结果展示到复盘改进。每张图片对应一个具体动作，不是单纯展示画面。你可以把它当作一个可复用的小模板：做活动、做学习计划、做社团协作都可以套用。尤其是“问题处理”和“复盘改进”两步，很多同学会跳过，导致下一次还会踩同样的坑。建议配合图片说明逐条阅读，再结合自己的实际情况调整执行。'

$accounts = @(
  @{ u = "admin"; p = "Admin123!" },
  @{ u = "teacher_li"; p = "Teacher123!" },
  @{ u = "duanzhijie"; p = "AAAjt123@" },
  @{ u = "张三"; p = "zhangsan" }
)
$tokens = @{}
foreach ($acc in $accounts) { $tokens[$acc.u] = Login $acc.u $acc.p }
$adminToken = $tokens["admin"]

$galleryCfg = @{
  "admin"      = @{ title = "清晨图书馆到晚自习的一天"; boardId = 1; tags = @("学习日常","时间管理"); kw = @("library","study","notebook","campus","students") }
  "teacher_li" = @{ title = "社团招新周现场实录"; boardId = 7; tags = @("社团","校园活动"); kw = @("club","event","team","campus","community") }
  "duanzhijie" = @{ title = "食堂高峰时段与错峰就餐记录"; boardId = 2; tags = @("校园生活","食堂"); kw = @("cafeteria","food","campus","queue","student") }
  "张三"        = @{ title = "运动场夜跑与作息调整周记"; boardId = 2; tags = @("运动","健康生活"); kw = @("running","track","night","campus","sports") }
}

$postsByUser = @{
  "admin" = @(
    @{ title = "期末周前两周，如何把复习计划真正落地"; summary = "不是计划写得漂亮，而是节奏要可执行。"; content = $Long1 + $Long2; format = "rich_text"; tags = @("期末复习","学习节奏"); boardId = 1; visibility = "public" },
    @{ title = "班级活动报名总是临时抱佛脚？这套流程能救急"; summary = "把报名、提醒、分工做成模板后，执行轻松很多。"; content = "## 活动组织模板`n`n$Long1`n`n$Long2"; format = "markdown"; tags = @("班级活动","执行模板"); boardId = 2; visibility = "public" },
    @{ title = "校园通知太多看不过来，我是这样做优先级的"; summary = "先分级，再处理，减少信息焦虑。"; content = $Long2 + $Long1; format = "external_link"; linkUrl = "https://www.moe.gov.cn/"; linkTitle = "教育部官网"; linkSummary = "建议结合官方信息源建立通知阅读顺序。"; tags = @("通知公告","信息筛选"); boardId = 3; visibility = "public" }
  )
  "teacher_li" = @(
    @{ title = "课程项目协作常见翻车点：不是技术问题"; summary = "更多是任务边界和沟通机制没定清。"; content = $Long2 + $Long1; format = "rich_text"; tags = @("项目协作","课程实践"); boardId = 4; visibility = "public" },
    @{ title = "春招准备别只刷题：简历和表达要同步练"; summary = "技术能力和表达能力要一起准备。"; content = "## 春招准备建议`n`n$Long1`n`n$Long2"; format = "markdown"; tags = @("春招","简历","面试"); boardId = 5; visibility = "public" },
    @{ title = "和喜欢的人聊天总紧张？先练习尊重边界"; summary = "舒服的关系从倾听和分寸感开始。"; content = $Long1 + $Long2; format = "external_link"; linkUrl = "https://www.people.com.cn/"; linkTitle = "人民网"; linkSummary = "参考公共讨论中的理性沟通案例。"; tags = @("情感沟通","边界感"); boardId = 6; visibility = "public" }
  )
  "duanzhijie" = @(
    @{ title = "四六级冲刺最后30天：我只做三件事"; summary = "稳住节奏、强化错题、控制心态。"; content = $Long1 + $Long2; format = "rich_text"; tags = @("四六级","备考"); boardId = 1; visibility = "public" },
    @{ title = "校园热帖复盘：大家最近为什么都在聊实习"; summary = "信息焦虑背后是准备路径不清晰。"; content = "## 热帖观察`n`n$Long2`n`n$Long1"; format = "markdown"; tags = @("校园贴吧","实习"); boardId = 7; visibility = "public" },
    @{ title = "招聘信息太杂怎么筛？我用这四个问题判断"; summary = "先判断来源，再判断岗位真实性。"; content = $Long2 + $Long1; format = "external_link"; linkUrl = "https://www.gov.cn/"; linkTitle = "中国政府网"; linkSummary = "建议结合官方渠道核验岗位信息。"; tags = @("求职安全","信息筛选"); boardId = 5; visibility = "public" }
  )
  "张三" = @(
    @{ title = "宿舍作息冲突怎么解：先约定再提醒"; summary = "规则明确后，摩擦会少很多。"; content = $Long2 + $Long1; format = "rich_text"; tags = @("宿舍","沟通"); boardId = 2; visibility = "public" },
    @{ title = "技术学习别只看教程：要做可复盘的小项目"; summary = "小步快跑比一次做大项目更稳。"; content = "## 学习路线建议`n`n$Long1`n`n$Long2"; format = "markdown"; tags = @("技术成长","学习方法"); boardId = 4; visibility = "public" },
    @{ title = "校园公告看不过来？试试三层分类法"; summary = "必须立刻处理、这周处理、了解即可。"; content = $Long1 + $Long2; format = "external_link"; linkUrl = "https://www.xinhuanet.com/"; linkTitle = "新华网"; linkSummary = "结合公开信息建立优先级模型。"; tags = @("公告解读","时间管理"); boardId = 3; visibility = "public" }
  )
}

$created = New-Object System.Collections.Generic.List[object]

foreach ($acc in $accounts) {
  $u = $acc.u
  foreach ($p in $postsByUser[$u]) {
    $post = Create-Post -token $tokens[$u] -payload $p
    $created.Add([pscustomobject]@{ id = $post.id; title = $post.title; author = $u; format = $post.format })
  }

  $g = $galleryCfg[$u]
  $downloaded = Download-WebImages -prefix ($u + "_" + (Get-Random -Minimum 1000 -Maximum 9999)) -keywords $g.kw
  $urls = Upload-Images -token $tokens[$u] -paths $downloaded
  $gp = @{
    title = $g.title
    summary = "真实网络图片整理成校园图文相册，含完整过程说明。"
    content = $GalleryText
    format = "image_gallery"
    attachments = $urls
    galleryCaptions = @("准备阶段：目标与分工","执行现场：节奏与协作","问题处理：定位与响应","结果展示：关键反馈","复盘改进：经验沉淀")
    tags = $g.tags
    boardId = $g.boardId
    visibility = "public"
  }
  $post = Create-Post -token $tokens[$u] -payload $gp
  $created.Add([pscustomobject]@{ id = $post.id; title = $post.title; author = $u; format = $post.format })
}

foreach ($c in $created) { Approve-Post -adminToken $adminToken -postId ([int]$c.id) }

Write-Output ("CREATED_COUNT={0}" -f $created.Count)
$created | Sort-Object id | ForEach-Object {
  Write-Output ("{0}`t{1}`t{2}`t{3}" -f $_.id, $_.title, $_.author, $_.format)
}
