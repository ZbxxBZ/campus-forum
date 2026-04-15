# 审核队列未出现帖子 - 后端增量修复说明（2026-03-12）

问题现象：
- 学生发布帖子后，超级管理员“内容审核”未看到新增待审核数据。

结论：
- 该问题大概率是后端口径不一致（状态字段、查询条件、分页或权限过滤），不是单一前端问题。
- 前端已做兼容：会按 `status/reviewStatus/auditStatus` 多种口径拉取待审核列表，并支持分页默认参数。

---

## 一、后端必须保证的核心行为

### 1) 学生/教师发帖必须进入待审核

接口：`POST /api/v1/posts`

要求：
- 当发布者角色不是 `super_admin` 时，无论前端传什么，后端都要强制：
  - `status = pending`
  - 或 `review_status = pending`（若你们系统用该字段）

建议伪代码：

```java
if (!currentUser.isSuperAdmin()) {
    post.setStatus("pending");
}
```

### 2) 审核列表必须能查出待审核帖子

建议新增专用接口：
- `GET /api/v1/posts/review/pending`
- 权限：`review:read`

如果不新增，则至少保证 `GET /api/v1/posts` 支持以下任一种筛选并返回待审核数据：
- `status=pending`
- `reviewStatus=pending`
- `auditStatus=pending`

### 3) 分页参数

前端已默认传：`page=1&pageSize=20`

后端请保证：
- 不传分页时也有默认值
- 传了分页时正常返回第一页数据

### 4) 响应结构

前端可兼容：
- `data.list`
- `data.records`

后端建议统一为：

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "list": [],
    "total": 0,
    "page": 1,
    "pageSize": 20
  }
}
```

---

## 二、审核操作接口要求

接口：`PATCH /api/v1/posts/{postId}/review`

请求：

```json
{ "action": "approve" }
```

或

```json
{ "action": "reject" }
```

要求：
- `approve` -> `status = published`
- `reject` -> `status = rejected`
- 写入 `reviewerId`、`reviewedAt`、`reviewRemark`（建议）

---

## 三、定位排查步骤（建议你在 IDEA 快速验证）

1. 学生发帖后，直接查库该记录状态字段：
- `status` 是否为 `pending`。
- 若是 `draft/published`，说明发帖入库逻辑不对。

2. 用管理员 token 调审核列表接口：
- `GET /api/v1/posts?status=pending&page=1&pageSize=20`
- 看响应里是否有刚发的帖子。

3. 若接口返回空但数据库有 pending：
- 检查查询 SQL 是否加了错误条件（如只能查本人、板块过滤、软删除过滤、租户过滤）。

4. 若接口有数据但前端还显示空：
- 检查返回路径是不是 `data.list` 或 `data.records`。

---

## 四、前端本次已做兼容修改

1. 审核页查询兼容三种状态参数回退：
- `status=pending`
- `reviewStatus=pending`
- `auditStatus=pending`

2. 审核页字段兼容：
- 板块显示 `boardName || category`

3. 帖子查询增加默认分页参数，避免后端分页必填导致空结果。

以上修改已完成并通过前端构建。
