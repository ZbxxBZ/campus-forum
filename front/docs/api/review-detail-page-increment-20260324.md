# 审核专页增量文档（2026-03-24）

## 1. 变更目标

审核阶段不再复用普通帖子详情页（避免出现点赞、收藏、评论等互动入口），改为专用审核详情页，仅展示内容与审核动作。

## 2. 前端已完成

### 2.1 路由
- `GET /admin/reviews`：待审核列表
- `GET /admin/reviews/{postId}`：审核专页（新）

### 2.2 交互
1. 待审核列表点击标题跳转到审核专页。
2. 审核专页按帖子格式展示完整内容（富文本/Markdown/图文相册/外链）。
3. 页面底部提供“通过 / 驳回”按钮。
4. 不展示点赞、收藏、评论输入区（与普通详情页隔离）。

## 3. 后端接口要求

### 3.1 获取帖子详情
- `GET /api/v1/posts/{postId}`
- 对 `pending` 状态帖子：审核员（`review:read`）必须可访问详情。
- 返回字段建议：
  - `id,title,summary,content,format,attachments,tags,author,authorId,boardId,boardName,status,riskLevel,visibility,createdAt,updatedAt,linkUrl,linkSummary`

### 3.2 审核动作
- `PATCH /api/v1/posts/{postId}/review`
- 请求：`{ "action": "approve" | "reject" }`
- 规则：
  - `approve -> published`
  - `reject -> rejected`

## 4. 验收项

1. 在待审核列表点击标题进入审核专页。
2. 审核专页可看到完整正文和附件。
3. 页面无点赞/收藏/评论等互动入口。
4. 点击“通过/驳回”后，返回待审核列表且状态更新正确。
5. 审核员访问 pending 帖子详情不返回 403。
