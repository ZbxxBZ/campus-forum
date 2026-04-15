# 前端进度完整清单（交接后端团队）

更新时间：2026-03-21
交接目标：让新后端团队快速了解“前端已实现到什么程度、正在调用哪些接口、还缺什么才能联调通过”。

## 1. 当前总体状态

- 前端主流程已完成：登录注册、工作台浏览、内容发布、帖子详情、审核、板块管理、用户与权限管理、互动交流、个人主页、公开主页。
- 前端已按真实后端接口接入（并保留 mock 兜底）。
- 当前联调主要依赖：帖子详情、互动接口、个人主页接口、话题接口、图片上传接口、权限下发一致性。

## 2. 路由与页面完成度

| 路由 | 页面 | 状态 | 说明 |
|---|---|---|---|
| `/login` | 登录 | 已完成 | 调用 `/v1/auth/login` |
| `/register` | 注册 | 已完成 | 调用 `/v1/auth/register` |
| `/admin/home` | 工作台 | 已完成 | 已发布帖子列表，支持进入详情 |
| `/admin/post-detail/:postId` | 帖子详情 | 已完成 | 正文渲染 + 点赞收藏 + 多级评论 |
| `/admin/post-create` | 内容发布 | 已完成 | rich_text / markdown / image_gallery / external_link 四格式 |
| `/admin/posts` | 帖子管理 | 已完成 | 筛选、编辑、置顶、加精、发布/下架（下架二次确认） |
| `/admin/my-posts` | 我的帖子 | 已完成 | 学生侧自管帖子 |
| `/admin/reviews` | 内容审核 | 已完成 | 待审核列表 + 通过/驳回 |
| `/admin/boards` | 板块配置 | 已完成 | 查询、新增、编辑、启用禁用 |
| `/admin/users` | 用户管理 | 已完成 | 用户查询、角色变更、状态变更 |
| `/admin/permissions` | 权限管理 | 已完成 | 角色权限勾选保存；无 `role:update` 仅可查看 |
| `/admin/topics` | 互动交流（话题投票） | 已完成 | 话题列表、发布话题、投票；按钮按权限控制 |
| `/admin/profile` | 我的主页 | 已完成 | 资料展示、编辑态切换、本地上传头像、四个资产Tab |
| `/admin/profile/:userId` | 公开主页 | 已完成 | 用户公开信息 + 公开统计 |

## 3. 前端实际调用接口清单（后端必须对应）

统一读取口径：前端固定读取 `response.data.data`。

### 3.1 鉴权与用户
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/profile`
- `GET /api/v1/users`
- `PATCH /api/v1/users/{userId}/role`
- `PATCH /api/v1/users/{userId}/status`
- `GET /api/v1/roles`
- `PUT /api/v1/roles/{role}/permissions`

### 3.2 内容发布与管理
- `GET /api/v1/posts`
- `GET /api/v1/posts/mine`（失败时前端回退 `GET /posts?mine=true`）
- `GET /api/v1/posts/published`（失败时回退 `GET /posts?status=published`）
- `POST /api/v1/posts`
- `PATCH /api/v1/posts/{postId}`
- `GET /api/v1/posts/{postId}`
- `PATCH /api/v1/posts/{postId}/review`
- `GET /api/v1/posts/review/pending`（失败时回退 `GET /posts?status=pending`）
- `POST /api/v1/uploads/images`
- `GET /api/v1/boards`
- `GET /api/v1/boards/available`（失败时回退 `GET /boards?status=enabled`）
- `POST /api/v1/boards`
- `PATCH /api/v1/boards/{boardId}`

### 3.3 互动交流
- `GET /api/v1/posts/{postId}/interaction`
- `POST /api/v1/posts/{postId}/like`
- `POST /api/v1/posts/{postId}/favorite`
- `GET /api/v1/posts/{postId}/comments`
- `POST /api/v1/posts/{postId}/comments`
- `GET /api/v1/topics`
- `POST /api/v1/topics`
- `POST /api/v1/topics/{topicId}/vote`

### 3.4 个人主页
- `GET /api/v1/profile/me`
- `PATCH /api/v1/profile/me`
- `GET /api/v1/profile/me/posts`
- `GET /api/v1/profile/me/comments`
- `GET /api/v1/profile/me/likes`
- `GET /api/v1/profile/me/favorites`
- `GET /api/v1/profile/users/{userId}`

## 4. 关键字段契约（后端返回必须满足）

### 4.1 帖子对象
最小字段：
- `id,title,summary,content,format,attachments,tags,author,authorId,boardId,boardName,status,visibility,createdAt,updatedAt`

用途说明：
- `authorId`：前端用于“作者 -> 公开主页”跳转，缺失会降级为纯文本。
- `format`：决定详情页渲染策略（富文本/Markdown/图文/外链）。

### 4.2 互动对象
- `likeCount,favoriteCount,liked,favorited`

### 4.3 评论对象
- `id,postId,parentId,author,authorId,content,createdAt`

### 4.4 个人主页对象
- `data.user`：`id,username,displayName,avatar,role,bio,joinedAt`
- `data.stats`：`postCount,commentCount,likeCount,favoriteCount`

### 4.5 列表统一格式
- `data.list`
- `data.total`
- `data.page`
- `data.pageSize`

## 5. 权限模型（前端当前行为）

前端基于登录返回的 `permissions` 控制菜单、路由与按钮。

### 5.1 关键权限
- `post:create`：显示“内容发布”
- `post:read`：显示“帖子管理/我的帖子”
- `review:read`：显示“内容审核”
- `board:read`：显示“板块配置”
- `user:read`：显示“用户管理”
- `role:read`：显示“权限管理”
- `role:update`：权限管理页可保存
- `topic:read`：话题列表可读取
- `topic:create`：可发布话题
- `topic:vote`：可参与投票

### 5.2 特别说明
- 话题页已做按钮级鉴权：无权限会禁用按钮并提示。
- 管理端帖子“下架”有二次确认弹窗，后端仍只需状态更新。

## 6. 已落地的前端交互细节（后端需知）

1. 内容发布支持四种格式动态表单。
2. 图文相册与头像都走 `POST /uploads/images` 上传后再提交 URL。
3. 个人主页资料编辑采用“点击编辑 -> 展开表单 -> 保存后收起”的交互。
4. 帖子作者在多个页面可点击跳转公开主页（依赖 `authorId`）。
5. 审核页兼容 `status/reviewStatus/auditStatus` 三种字段口径。

## 7. 联调优先级（建议新后端团队按此顺序）

1. P0：`/posts/{id}` + `/uploads/images` + `/posts/*互动接口`
2. P0：`/profile/me` + `/profile/me/*` 四个列表
3. P1：`/profile/users/{userId}`
4. P1：`/topics` 三个接口 + 话题权限鉴权
5. P1：角色权限保存与登录态权限下发一致性

## 8. 新后端首轮验收脚本（最小）

1. 学生登录 -> 工作台点击帖子标题 -> 能看到正文。
2. 在详情页点赞/收藏/评论 -> 页面计数与评论刷新成功。
3. 学生进入个人主页 -> 编辑昵称与简介（不上传头像）可保存。
4. 学生进入个人主页 -> 上传本地头像后保存成功。
5. 超管进入权限管理 -> 给学生增加 `topic:create` -> 学生重新登录后可发布话题。
6. 管理员在帖子管理点“下架” -> 弹确认，确认后状态改 `hidden`。

## 9. 风险与待确认项

1. `attachments` 当前按 `string[]` 使用，若后端升级对象结构需提前告知前端。
2. 评论是否必须返回 `authorId`（当前建议必须，便于评论作者跳转）。
3. 上传接口返回结构需固定：`data.files[].url`。
4. 鉴权失败时建议统一返回 401/403，便于前端统一提示。

## 10. 关联文档

- `docs/api/backend-todo-priority-20260318.md`
- `docs/api/fe-be-gap-progress-20260318.md`
- `docs/api/topic-permission-increment-20260318.md`
- `docs/api/content-module-fix-increment-20260312.md`
- `docs/api/interaction-module-increment-20260316.md`
- `docs/api/profile-module-increment-20260318.md`
