# 内容审核「待审核列表可进入帖子详情」增量文档（2026-03-24）

## 1. 变更目标

管理员/审核员在待审核列表中点击帖子标题，进入帖子详情页查看完整内容后再执行通过/驳回。

## 2. 前端已完成

页面：`/admin/reviews`

1. 待审核列表“标题”列已改为可点击链接。
2. 点击后跳转：`/admin/post-detail/{postId}`。
3. 现有审核动作（通过/驳回）保留不变。

## 3. 后端接口增量要求

核心接口：`GET /api/v1/posts/{postId}`

### 3.1 权限口径（关键）
- 对 `status = pending` 的帖子：
  - 管理员/审核员（具备 `review:read`）必须可查看详情。
- 对 `status = pending/rejected/draft`：
  - 作者本人可查看自己的帖子详情。
- `published`：登录用户可查看。

> 若当前后端对 pending 详情直接 403，会导致审核列表点进去看不到内容，需要调整。

### 3.2 返回字段（建议最小集）
- `id`
- `title`
- `summary`
- `content`
- `format`
- `attachments`
- `tags`
- `author`
- `authorId`
- `boardId`
- `boardName`
- `status`
- `riskLevel`
- `visibility`
- `createdAt`
- `updatedAt`

## 4. 响应示例

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "post": {
      "id": 2001,
      "title": "考试周自习室规则说明",
      "summary": "请同学们注意晚间秩序",
      "content": "<p>正文内容...</p>",
      "format": "rich_text",
      "attachments": [],
      "tags": ["考试周"],
      "author": "student_01",
      "authorId": 10001,
      "boardId": 2,
      "boardName": "校园生活",
      "status": "pending",
      "riskLevel": "low",
      "visibility": "public",
      "createdAt": "2026-03-24T08:00:00.000Z",
      "updatedAt": "2026-03-24T08:00:00.000Z"
    }
  }
}
```

## 5. 验收项

1. 在 `/admin/reviews` 点击待审核帖子标题可进入详情。
2. 审核员账户访问 pending 帖子详情不再 403。
3. 详情页能展示完整正文与附件，便于审核判断。
4. 审核动作执行后，列表刷新状态正确。
