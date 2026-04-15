# 前后端差异与进度对齐（2026-03-18）

用途：用于每天站会同步“前端已完成、后端已完成、联调阻塞点、下一步负责人”。

## 1. 总体结论（截至 2026-03-18）

- 前端页面层：内容发布、帖子详情、互动交流、个人主页、公开主页入口已具备。
- 当前主要风险不在页面，而在接口齐套度与字段一致性（尤其 `authorId`、详情接口、上传接口）。
- 建议联调顺序：`帖子详情 -> 互动接口 -> 个人主页 -> 公开主页 -> 话题投票`。

## 2. 模块进度差异（按优先级）

| 优先级 | 模块 | 前端状态 | 后端目标状态 | 当前差异/阻塞 | 负责人建议 |
|---|---|---|---|---|---|
| P0 | 帖子详情 | 已完成详情页与入口（工作台/管理/个人页） | 提供 `GET /api/v1/posts/{postId}` | 若缺 `content/attachments/authorId` 会导致详情不完整、作者无法跳转主页 | 后端先补 |
| P0 | 内容发布-图片上传 | 已完成图文相册本地上传交互 | 提供 `POST /api/v1/uploads/images` | 未接入时图文相册无法真实发布 | 后端先补 |
| P0 | 互动交流（点赞收藏评论） | 已完成按钮/评论UI/回复交互 | 提供 interaction/like/favorite/comments 5个接口 | 无接口或字段不齐时，计数与评论区不可用 | 后端先补 |
| P0 | 个人主页（我的） | 已完成资料+4个Tab | 提供 `/profile/me` 与4个列表接口 | 点赞/收藏列表字段若不统一会影响渲染 | 后端补齐字段 |
| P1 | 公开主页 | 路由与页面已完成 | 提供 `GET /api/v1/profile/users/{userId}` | 无接口时作者跳转会失败 | 后端补 |
| P1 | 话题与投票 | 页面已完成（创建/投票） | 提供 topics 三个接口 | 无接口时仅能展示空页面或 mock 数据 | 后端补 |
| P1 | 评论分页 | 前端当前可兼容全量 | 评论接口支持 `page/pageSize` | 数据量大时性能和首屏变差 | 后端补，前端再接 |

## 3. 前端已落地能力（可直接联调）

- 发布：`/admin/post-create` 支持 `rich_text/markdown/image_gallery/external_link` 四种格式。
- 详情：`/admin/post-detail/:postId` 支持正文展示、点赞、收藏、评论、回复。
- 首页列表：`/admin/home` 点击标题进详情，作者可跳公开主页（需 `authorId`）。
- 管理列表：`/admin/posts` 标题进详情，作者可跳公开主页。
- 个人主页：`/admin/profile`（帖子/评论/点赞/收藏）。
- 公开主页：`/admin/profile/:userId`。
- 话题投票：`/admin/topics`。

## 4. 后端必须补齐接口（联调硬依赖）

1. `GET /api/v1/posts/{postId}`
2. `POST /api/v1/uploads/images`
3. `GET /api/v1/posts/{postId}/interaction`
4. `POST /api/v1/posts/{postId}/like`
5. `POST /api/v1/posts/{postId}/favorite`
6. `GET /api/v1/posts/{postId}/comments`
7. `POST /api/v1/posts/{postId}/comments`
8. `GET /api/v1/profile/me`
9. `PATCH /api/v1/profile/me`
10. `GET /api/v1/profile/me/posts`
11. `GET /api/v1/profile/me/comments`
12. `GET /api/v1/profile/me/likes`
13. `GET /api/v1/profile/me/favorites`
14. `GET /api/v1/profile/users/{userId}`
15. `GET /api/v1/topics`
16. `POST /api/v1/topics`
17. `POST /api/v1/topics/{topicId}/vote`

## 5. 后端必须保证字段（否则前端会异常）

- 帖子对象：`id,title,summary,content,format,attachments,tags,author,authorId,boardId,boardName,status,visibility,createdAt,updatedAt`
- 互动对象：`likeCount,favoriteCount,liked,favorited`
- 评论对象：`id,postId,parentId,author,authorId,content,createdAt`
- 主页统计：`postCount,commentCount,likeCount,favoriteCount`
- 统一列表：`list,total,page,pageSize`

## 6. 联调日程建议（可直接执行）

1. Day 1：打通帖子详情 + 发布图片上传。
2. Day 2：打通点赞/收藏/评论。
3. Day 3：打通我的主页 5 个接口。
4. Day 4：打通公开主页 + 作者跳转。
5. Day 5：打通话题投票 + 回归测试。

## 7. 每日进度更新模板（复制使用）

```md
日期：YYYY-MM-DD
前端完成：
后端完成：
联调完成：
阻塞问题：
明日计划：
是否需要产品/架构决策：
```

## 8. 关联文档

- `docs/api/backend-todo-priority-20260318.md`
- `docs/api/content-module-fix-increment-20260312.md`
- `docs/api/interaction-module-increment-20260316.md`
- `docs/api/profile-module-increment-20260318.md`
