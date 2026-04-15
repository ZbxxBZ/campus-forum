# 个人主页「我的评论跳转帖子」增量文档（2026-03-24）

## 1. 变更目标

在个人主页的“我的评论”列表中新增“所属帖子”列，支持点击帖子标题跳转到帖子详情页。

## 2. 前端已完成

页面：`/admin/profile`

1. 评论表格新增列：`所属帖子`
2. 若评论包含 `postId`，前端渲染为可点击链接：`/admin/post-detail/{postId}`
3. 链接文案优先展示 `postTitle`，缺失时兜底为 `帖子 #{postId}`
4. 无 `postId` 时降级为纯文本展示

## 3. 后端接口增量要求

接口：`GET /api/v1/profile/me/comments`

### 3.1 每条评论对象建议至少包含
- `id`
- `postId`（必须）
- `postTitle`（建议，提升列表可读性）
- `content`
- `createdAt`

### 3.2 响应示例

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "list": [
      {
        "id": 901,
        "postId": 1001,
        "postTitle": "期末复习资料共享帖",
        "content": "这篇很有帮助",
        "createdAt": "2026-03-24T09:30:00.000Z"
      }
    ],
    "total": 1,
    "page": 1,
    "pageSize": 20
  }
}
```

## 4. 兼容策略

- 若后端短期只能提供 `postId`，前端仍可跳转（文案用 `帖子 #{postId}`）。
- 推荐后端同时返回 `postTitle`，避免前端二次请求补标题。

## 5. 验收项

1. 个人主页“我的评论”可看到“所属帖子”列。
2. 点击标题可进入对应帖子详情页。
3. 评论列表分页结构保持 `list/total/page/pageSize`。
