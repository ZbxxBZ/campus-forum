# 后端待办总清单（按优先级）

更新时间：2026-03-18
适用范围：互动交流模块 + 个人主页模块（含与现有内容发布联动）
统一响应：`{ code, message, data }`

## P0（必须先完成，阻塞联调）

1. 帖子详情接口（补齐主体内容）
- `GET /api/v1/posts/{postId}`
- 目的：工作台帖子列表点击后可查看完整正文。
- 最少返回：`id,title,summary,content,format,attachments,tags,author,authorId,boardId,boardName,status,visibility,createdAt,updatedAt`
- 权限建议：
  - `published`：登录可见
  - `pending/rejected`：作者本人 + 管理角色可见

2. 互动基础接口（点赞/收藏/评论）
- `GET /api/v1/posts/{postId}/interaction`
- `POST /api/v1/posts/{postId}/like`（toggle）
- `POST /api/v1/posts/{postId}/favorite`（toggle）
- `GET /api/v1/posts/{postId}/comments`
- `POST /api/v1/posts/{postId}/comments`
- 说明：评论至少支持 `parentId`（多级回复）

3. 个人主页基础接口（我的资料 + 四类资产）
- `GET /api/v1/profile/me`
- `PATCH /api/v1/profile/me`
- `GET /api/v1/profile/me/posts`
- `GET /api/v1/profile/me/comments`
- `GET /api/v1/profile/me/likes`
- `GET /api/v1/profile/me/favorites`
- 隐私要求：点赞/收藏明细默认仅本人可见

4. 列表返回格式统一
- 所有列表接口统一返回：`list,total,page,pageSize`
- 分页默认：`page=1,pageSize=20`，上限建议 `100`

5. 前端已依赖字段（必须提供）
- 帖子相关列表与详情都要返回：`authorId`（用于跳转公开主页）
- 评论列表建议返回：`authorId`（后续评论作者主页跳转）
- 我的点赞/我的收藏列表中的帖子对象建议与帖子列表同构（至少含 `id,title,author,authorId,status,updatedAt`）

## P1（本周建议完成，提升可用性）

1. 公开主页接口
- `GET /api/v1/profile/users/{userId}`
- 返回公开信息：`user + stats(postCount/commentCount)`
- 不返回点赞/收藏明细

2. 话题与投票接口
- `GET /api/v1/topics`
- `POST /api/v1/topics`
- `POST /api/v1/topics/{topicId}/vote`
- 约束：同一用户同一话题仅一票（唯一键）
- 权限建议：
  - `topic:read`：查看话题列表
  - `topic:create`：发布话题
  - `topic:vote`：参与投票

3. 评论查询能力增强
- 支持 `page,pageSize`（如当前全量返回，可兼容过渡）
- 可选支持 `keyword` 过滤

4. 交互与主页数据一致性
- 点赞/收藏后，`/interaction` 与 `/profile/me/likes|favorites` 数据应同步可见

## P2（优化项，可并行排期）

1. 计数器优化
- 帖子表维护 `comment_count/like_count/favorite_count` 或使用缓存聚合

2. 审计与风控
- 点赞/收藏/评论操作日志
- 频率限制（防刷）

3. 公开主页隐私开关
- 用户可配置是否公开“点赞/收藏数量（非明细）”

## 数据库增量（DDL建议）

1. 互动表
- `post_comment(id, post_id, parent_id, user_id, content, created_at, updated_at)`
- `post_like(id, post_id, user_id, created_at, UNIQUE(post_id,user_id))`
- `post_favorite(id, post_id, user_id, created_at, UNIQUE(post_id,user_id))`

2. 话题投票表
- `topic(id, title, description, created_by, created_at)`
- `topic_option(id, topic_id, text, vote_count)`
- `topic_vote(id, topic_id, option_id, user_id, created_at, UNIQUE(topic_id,user_id))`

3. 资料扩展表（按需）
- `user_profile(user_id PK, avatar, bio, updated_at)`

4. 关键索引
- `posts(author_id, created_at)`
- `post_comment(post_id, created_at)`
- `post_comment(user_id, created_at)`
- `post_like(user_id, created_at)`
- `post_favorite(user_id, created_at)`

## 联调验收（前后端共同）

1. 用户点击工作台帖子标题，能进入详情页看到正文。
2. 点赞/收藏可切换，计数实时变化。
3. 评论支持回复评论，详情页正确展示层级。
4. 我的主页四个 Tab 均可分页加载。
5. 学生/教师可访问个人主页，管理员也可访问但入口优先级可更低。
6. 公开主页仅展示公开字段，不泄露点赞/收藏明细。

## 备注

- 历史增量文档仍保留，作为字段细节参考：
  - `docs/api/interaction-module-increment-20260316.md`
  - `docs/api/profile-module-increment-20260318.md`
- 本文档是“排期与实施顺序”总清单，后端按 P0 -> P1 -> P2 执行即可。
