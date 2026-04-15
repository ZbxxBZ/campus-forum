# 审核日志追溯增量文档（2026-03-24）

## 1. 目标

新增“审核日志”模块，仅超级管理员可见，用于追溯：
- 审核通过
- 审核驳回
- 帖子下架
- 帖子上架
- 其他状态变更

## 2. 前端已完成

### 2.1 菜单与权限
- 左侧新增菜单：`审核日志`
- 仅超级管理员角色可见

### 2.2 路由
- `GET /admin/audit-logs`

### 2.3 页面能力
- 日志列表展示：时间、操作、帖子、操作人、角色、详情
- 支持筛选：
  - `keyword`（帖子标题/详情）
  - `action`
  - `role`
  - `operator`
- 帖子列支持点击跳转详情（便于回看上下文）

## 3. 后端接口新增要求

接口：`GET /api/v1/audit/logs`

### 3.1 权限
- 仅 `super_admin` 或具备 `auditlog:read` 的用户可访问

### 3.2 查询参数
- `keyword`（可选）
- `action`（可选）
- `role`（可选）
- `operator`（可选）
- `page`（默认 1）
- `pageSize`（默认 20，建议上限 100）

### 3.3 响应结构

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "list": [
      {
        "id": 10001,
        "action": "review_approve",
        "actionLabel": "审核通过",
        "postId": 2001,
        "postTitle": "考试周自习室规则说明",
        "operatorId": 301,
        "operator": "teacher_li",
        "operatorRole": "teacher",
        "detail": "status: pending -> published",
        "createdAt": "2026-03-24T10:30:00.000Z"
      }
    ],
    "total": 1,
    "page": 1,
    "pageSize": 20
  }
}
```

## 4. 后端日志记录点（必须）

### 4.1 审核动作
- 接口：`PATCH /api/v1/posts/{postId}/review`
- 记录：
  - `action=review_approve` / `review_reject`
  - 操作人、角色、帖子、时间、状态变更前后

### 4.2 帖子上下架
- 接口：`PATCH /api/v1/posts/{postId}`（当 status 变化）
- 记录：
  - `action=post_hide`（published->hidden）
  - `action=post_publish`（hidden->published）
  - 其他状态变化可记 `post_status_change`

## 5. 数据库建议

表：`audit_log`
- `id` bigint PK
- `action` varchar(64)
- `action_label` varchar(64)
- `post_id` bigint
- `post_title` varchar(255)
- `operator_id` bigint
- `operator` varchar(64)
- `operator_role` varchar(32)
- `detail` varchar(500)
- `created_at` datetime

索引建议：
- `idx_audit_created_at(created_at desc)`
- `idx_audit_post_id(post_id)`
- `idx_audit_operator_id(operator_id)`
- `idx_audit_action(action)`

## 6. 验收项

1. 仅超级管理员可看到“审核日志”菜单并访问页面。
2. 审核通过/驳回后，日志页出现对应记录。
3. 下架/上架后，日志页出现对应记录。
4. 可按操作类型、角色、操作人筛选。
5. 日志中的帖子可跳转到帖子详情回溯。
