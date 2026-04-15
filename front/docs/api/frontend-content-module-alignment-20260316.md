# 前端对齐说明（内容发布模块）- 2026-03-16

本说明用于确认：当前前端已按《校园论坛内容发布模块接口与字段对齐清单》完成对接。

## 1. 对齐结论

已对齐模块：
- 内容发布
- 帖子列表（管理）
- 我的帖子
- 审核队列
- 板块下拉

统一响应读取：
- 前端统一读取 `response.data.data`

---

## 2. 接口对齐映射

### 2.1 发布帖子
- 前端调用：`POST /api/v1/posts`
- 文件：`src/services/modules/forumApi.js` -> `createPostApi`
- 发布页：`src/views/admin/PostCreateView.vue`
- 已对齐字段：
  - `title, summary, content, format, attachments, tags, boardId, visibility, status, isTop, isFeatured`
- 前端行为：非超管默认提交审核（status 传 pending）

### 2.2 更新帖子（管理）
- 前端调用：`PATCH /api/v1/posts/{postId}`
- 文件：`src/services/modules/forumApi.js` -> `updatePostApi`
- 页面：
  - 管理页：`src/views/admin/PostManagementView.vue`
  - 我的帖子：`src/views/admin/MyPostView.vue`

### 2.3 全量帖子列表（管理）
- 前端调用：`GET /api/v1/posts`
- 文件：`src/services/modules/forumApi.js` -> `listPostsApi`
- 查询参数已支持：
  - `keyword,status,reviewStatus,auditStatus,boardId,format,visibility,mine,page,pageSize`
- 前端默认分页：`page=1&pageSize=20`

### 2.4 已发布帖子列表（首页）
- 前端调用：优先 `GET /api/v1/posts/published`，失败回退 `/posts?status=published`
- 文件：`src/services/modules/forumApi.js` -> `listPublishedPostsApi`
- 页面：`src/views/admin/HomeView.vue`

### 2.5 我的帖子
- 前端调用：优先 `GET /api/v1/posts/mine`，失败回退 `/posts?mine=true`
- 文件：`src/services/modules/forumApi.js` -> `listMyPostsApi`
- 页面：`src/views/admin/MyPostView.vue`

### 2.6 审核待处理队列
- 前端调用：优先 `GET /api/v1/posts/review/pending`，失败回退 `/posts?status=pending`
- 文件：`src/services/modules/forumApi.js` -> `listPendingReviewPostsApi`
- 页面：`src/views/admin/ContentReviewView.vue`

### 2.7 审核动作
- 前端调用：`PATCH /api/v1/posts/{postId}/review`
- 文件：`src/services/modules/forumApi.js` -> `reviewPostApi`

### 2.8 板块列表（管理）
- 前端调用：`GET /api/v1/boards`
- 文件：`src/services/modules/forumApi.js` -> `listBoardsApi`
- 页面：`src/views/admin/BoardManagementView.vue`

### 2.9 可发布板块下拉
- 前端调用：优先 `GET /api/v1/boards/available`，失败回退 `/boards?status=enabled`
- 文件：`src/services/modules/forumApi.js` -> `listAvailableBoardsApi`
- 页面：`src/views/admin/PostCreateView.vue`

---

## 3. 字段口径对齐

前端按以下字段渲染帖子对象：
- `id,title,summary,content,format,attachments,tags,boardId,boardName,author,visibility,status,riskLevel,isTop,isFeatured,createdAt,updatedAt`

兼容处理：
- 审核列表板块列支持 `boardName || category`（兼容旧字段）

---

## 4. 已做兼容与容错

- 清理空查询参数，避免后端按空值误过滤。
- 所有列表请求默认带分页参数（`page=1&pageSize=20`）。
- 审核队列接口、已发布列表、我的帖子、可发布板块均有回退策略，便于平滑联调。

---

## 5. 建议后端最终固定（减少回退依赖）

建议后端稳定提供并长期保持：
1. `GET /posts/published`
2. `GET /posts/mine`
3. `GET /posts/review/pending`
4. `GET /boards/available`

稳定后可移除前端回退分支，代码更简洁。
