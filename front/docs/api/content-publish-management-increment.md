# 内容发布与管理模块 - 增量接口文档（给 IDEA 后端实现）

- 文档日期：2026-03-12
- 增量范围：多格式内容发布、帖子精细化管理、板块配置管理
- 前端已完成并依赖以下接口
- 基础路径：`/api/v1`
- 统一响应：

```json
{
  "code": 0,
  "message": "OK",
  "data": {}
}
```

---

## 1. 新增权限点（RBAC）

请在后端权限表或枚举中新增：

- `post:create` 发布帖子
- `board:read` 查看板块配置
- `board:update` 管理板块配置

建议角色默认权限：
- `super_admin`：全部
- `admin`：`post:create` + `board:read` + `board:update`
- `teacher`：`post:create`
- `student`：无（可后续按业务开放）

---

## 2. 帖子接口（增量）

### 2.1 创建帖子

- 方法：`POST`
- 路径：`/posts`
- 权限：`post:create`

请求体：

```json
{
  "title": "期末复习经验汇总",
  "summary": "分享期末复习路线",
  "content": "# 复习建议\n\n先过知识框架",
  "format": "markdown",
  "attachments": ["https://cdn.xxx/a.png"],
  "tags": ["期末", "学习"],
  "boardId": 1,
  "visibility": "public",
  "status": "pending",
  "isTop": false,
  "isFeatured": false,
  "author": "teacher_li"
}
```

响应 `data`：

```json
{
  "post": {
    "id": 1004,
    "title": "期末复习经验汇总",
    "summary": "分享期末复习路线",
    "content": "# 复习建议\n\n先过知识框架",
    "format": "markdown",
    "attachments": ["https://cdn.xxx/a.png"],
    "tags": ["期末", "学习"],
    "boardId": 1,
    "boardName": "学习交流",
    "author": "teacher_li",
    "visibility": "public",
    "status": "pending",
    "riskLevel": "low",
    "isTop": false,
    "isFeatured": false,
    "createdAt": "2026-03-12T01:00:00.000Z",
    "updatedAt": "2026-03-12T01:00:00.000Z"
  }
}
```

### 2.2 更新帖子（精细化管理）

- 方法：`PATCH`
- 路径：`/posts/{postId}`
- 权限：`post:update`

请求体（可部分字段）：

```json
{
  "title": "新标题",
  "summary": "新摘要",
  "content": "新内容",
  "format": "rich_text",
  "boardId": 2,
  "visibility": "campus",
  "status": "published",
  "tags": ["置顶推荐"],
  "attachments": [],
  "isTop": true,
  "isFeatured": true
}
```

响应 `data`：

```json
{
  "post": {
    "id": 1004,
    "title": "新标题",
    "status": "published",
    "isTop": true,
    "isFeatured": true,
    "updatedAt": "2026-03-12T01:20:00.000Z"
  }
}
```

### 2.3 帖子列表（新增筛选维度）

- 方法：`GET`
- 路径：`/posts`
- 权限：`post:read`

查询参数增量：
- `boardId`：按板块筛选
- `format`：按内容格式筛选
- `visibility`：按可见范围筛选

已有参数继续保留：
- `keyword`
- `status`

响应 `data`：

```json
{
  "list": [
    {
      "id": 1001,
      "title": "期末复习资料共享帖",
      "summary": "汇总资料下载链接",
      "content": "<p>...</p>",
      "format": "rich_text",
      "attachments": [],
      "tags": ["期末", "资料共享"],
      "boardId": 1,
      "boardName": "学习交流",
      "author": "teacher_li",
      "visibility": "public",
      "status": "published",
      "riskLevel": "low",
      "isTop": true,
      "isFeatured": true,
      "createdAt": "2026-03-10T08:00:00.000Z",
      "updatedAt": "2026-03-10T08:00:00.000Z"
    }
  ],
  "total": 1
}
```

---

## 3. 板块配置接口（新增）

### 3.1 板块列表

- 方法：`GET`
- 路径：`/boards`
- 权限：`board:read`

查询参数：
- `keyword`
- `status`（`enabled` / `disabled`）

响应 `data`：

```json
{
  "list": [
    {
      "id": 1,
      "name": "学习交流",
      "code": "study",
      "description": "课程学习、资料分享",
      "sortOrder": 10,
      "status": "enabled",
      "postCount": 128,
      "createdAt": "2026-03-10T08:00:00.000Z"
    }
  ],
  "total": 1
}
```

### 3.2 新增板块

- 方法：`POST`
- 路径：`/boards`
- 权限：`board:update`

请求体：

```json
{
  "name": "技术问答",
  "code": "tech-qna",
  "description": "编程与技术问题讨论",
  "sortOrder": 40,
  "status": "enabled"
}
```

响应 `data`：

```json
{
  "board": {
    "id": 4,
    "name": "技术问答",
    "code": "tech-qna",
    "description": "编程与技术问题讨论",
    "sortOrder": 40,
    "status": "enabled",
    "postCount": 0,
    "createdAt": "2026-03-12T01:30:00.000Z"
  }
}
```

### 3.3 修改板块

- 方法：`PATCH`
- 路径：`/boards/{boardId}`
- 权限：`board:update`

请求体（可部分字段）：

```json
{
  "name": "学习交流(新)",
  "code": "study-new",
  "description": "新版块说明",
  "sortOrder": 5,
  "status": "disabled"
}
```

响应 `data`：

```json
{
  "board": {
    "id": 1,
    "name": "学习交流(新)",
    "code": "study-new",
    "sortOrder": 5,
    "status": "disabled"
  }
}
```

---

## 4. 字段枚举（后端请与前端一致）

### `post.format`
- `rich_text`
- `markdown`
- `image_gallery`
- `external_link`

### `post.visibility`
- `public`
- `campus`
- `private`

### `post.status`
- `draft`
- `pending`
- `published`
- `rejected`
- `hidden`

### `board.status`
- `enabled`
- `disabled`

---

## 5. 数据表增量建议（供 IDEA 落库）

### `forum_board`
- `id` bigint PK
- `name` varchar(64) not null
- `code` varchar(64) unique not null
- `description` varchar(255)
- `sort_order` int default 0
- `status` varchar(16) not null
- `post_count` int default 0
- `created_at` datetime
- `updated_at` datetime

### `forum_post`（新增字段）
- `summary` varchar(255)
- `format` varchar(32) not null
- `visibility` varchar(16) not null
- `is_top` tinyint(1) default 0
- `is_featured` tinyint(1) default 0
- `board_id` bigint not null
- `attachments_json` text
- `tags_json` text

---

## 6. 与前端对齐注意事项

1. 前端读取格式固定为 `response.data.data`。
2. `boardId`、`postId` 请返回数值类型。
3. 新增/修改板块后，建议同步更新该板块下帖子 `boardName`（或由查询 join 保证一致）。
4. 错误时返回统一结构，`message` 给中文可读提示，前端会直接弹出。

---

## 7. 最小联调清单

1. `POST /posts` 成功返回 `data.post.id`
2. `PATCH /posts/{id}` 可改 `isTop/isFeatured/status`
3. `GET /posts` 支持 `boardId/format/visibility` 过滤
4. `GET /boards` 返回 `list + total`
5. `POST /boards` 能校验 `code` 唯一
6. `PATCH /boards/{id}` 可改 `status/sortOrder`

完成以上 6 条，前端“内容发布与管理模块”即可完整跑通。
