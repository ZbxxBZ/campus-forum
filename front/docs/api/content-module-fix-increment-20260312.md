# 内容发布与管理模块 - 问题修复增量文档（2026-03-12）

本增量用于修复以下联调问题：
1. 登录后可看到已发布帖子。
2. 学生/教师在“内容发布”页可获取板块下拉选项。
3. 学生/教师发帖默认进入审核流，需超级管理员审核后发布。
4. 教师/管理员帖子管理列表和筛选可正常查询。

---

## 一、后端新增/调整接口

### 1) 已发布帖子列表（登录可见）
- `GET /api/v1/posts/published`
- 权限：登录即可（不强依赖 `post:read`）
- 查询参数：`keyword`、`boardId`、`format`
- 返回：`data.list` + `data.total`

说明：前端首页会调用该接口展示“论坛已发布帖子”。

### 2) 可发布板块列表（发布页下拉）
- `GET /api/v1/boards/available`
- 权限：拥有 `post:create` 的角色可访问（学生/教师/管理员/超管按业务决定）
- 返回：仅启用板块，字段至少包含：
  - `id`
  - `name`

说明：该接口用于“内容发布”页板块下拉，避免依赖管理接口 `/boards`。

### 3) 我的帖子列表（建议实现）
- `GET /api/v1/posts/mine`
- 权限：登录即可
- 行为：仅返回当前登录用户自己的帖子

说明：前端学生“我的帖子”页优先调用该接口；未实现时会退化到 `/posts?mine=true`。

### 4) 帖子列表查询（现有接口增强）
- `GET /api/v1/posts`
- 现有筛选参数建议支持：
  - `keyword`
  - `status`
  - `boardId`
  - `format`
  - `visibility`
  - `mine`

关键要求：**后端需忽略空字符串参数**（例如 `status=''`），否则会导致查不到数据。

---

## 二、发帖审核流要求

### `POST /api/v1/posts`
- 学生/教师提交时：后端应强制写入 `status = pending`（即使前端传了 `published` 也不要直接发布）
- 超级管理员可按业务允许：
  - `status = published`（直接发布）
  - 或 `status = pending`（走审核）

建议后端做最终兜底规则：
- `role != super_admin` -> `status` 强制 `pending`

---

## 三、权限建议

### 学生角色最少权限（可发帖+看自己）
- `post:create`
- `post:read`（用于“我的帖子”展示；或不配此权限但开放 `/posts/mine`）

### 教师角色
- `post:create`
- `post:read`

### 管理员/超管
- `post:read`
- `post:update`
- `post:delete`
- `board:read` / `board:update`（按职责）

---

## 四、响应结构保持不变

前端固定读取：`response.data.data`

统一返回结构：

```json
{
  "code": 0,
  "message": "OK",
  "data": {}
}
```

错误示例：

```json
{
  "code": 10006,
  "message": "无权限访问",
  "data": null
}
```

---

## 五、联调验收清单

1. 学生登录后首页可看到已发布帖子（`/posts/published` 正常）。
2. 学生/教师进入“内容发布”页，板块下拉有数据（`/boards/available` 正常）。
3. 学生/教师发帖后状态为 `pending`，不会直接 `published`。
4. 超级管理员在审核页可将 `pending -> published/rejected`。
5. 教师/管理员在“帖子管理”页可查询到数据，并可按条件筛选。
6. 学生不能进入全量“帖子管理”，只能进入“我的帖子”。

---

## 六、前端本次对应改动（便于后端核对）

- 首页显示已发布帖子：调用 `GET /posts/published`
- 发布页板块来源：优先 `GET /boards/available`
- 发帖状态策略：非超管默认提交审核
- 帖子列表查询参数：前端已清洗空参数再请求
- 学生路由限制：阻止访问 `/admin/posts`，改走 `/admin/my-posts`
