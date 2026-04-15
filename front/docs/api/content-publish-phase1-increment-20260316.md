# 内容发布模块第一阶段（动态格式发布）增量文档 - 2026-03-16

## 1. 本次前端改造范围

已完成：
1. 发帖页按 `format` 动态切换界面
- `rich_text`：富文本快捷排版按钮 + 编辑区
- `markdown`：编辑区 + 实时预览 + 语法提示
- `image_gallery`：本地选图、预览、排序、删除
- `external_link`：外链地址/标题/摘要专属输入

2. 工作台帖子可点击进入详情页，详情支持格式化展示
- 外链可点击跳转
- Markdown 渲染
- 图文相册渲染图片网格

---

## 2. 前端已使用/约定的接口

### 2.1 已在用接口（你后端已对齐）
- `POST /api/v1/posts`
- `GET /api/v1/posts`
- `GET /api/v1/posts/mine`
- `GET /api/v1/posts/published`
- `GET /api/v1/posts/review/pending`
- `PATCH /api/v1/posts/{postId}/review`
- `GET /api/v1/boards/available`
- `GET /api/v1/posts/{postId}`

### 2.2 建议新增（第二阶段上传能力）
> 当前第一阶段图文相册使用本地 dataURL 仅做演示，建议尽快切换上传接口。

- `POST /api/v1/uploads/images`
- 鉴权：登录即可
- `Content-Type: multipart/form-data`
- 请求字段：`files[]`
- 响应建议：

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "files": [
      {
        "url": "https://cdn.xxx.com/forum/2026/03/a.png",
        "name": "a.png",
        "size": 123456,
        "contentType": "image/png"
      }
    ]
  }
}
```

前端切换后会将 `image_gallery` 的 `attachments` 改为该接口返回的 URL 数组。

---

## 3. 帖子字段增量建议（与当前前端一致）

在现有帖子对象基础上，新增/确认字段：
- `linkUrl: string`（external_link 推荐主字段）
- `linkSummary: string`（可选）
- `galleryCaptions: string[]`（与图片顺序一一对应，可选）

当前前端提交示例：

### 3.1 rich_text
```json
{
  "title": "...",
  "format": "rich_text",
  "content": "<h2>标题</h2><p>正文</p>",
  "attachments": []
}
```

### 3.2 markdown
```json
{
  "title": "...",
  "format": "markdown",
  "content": "# 标题\n\n正文",
  "attachments": []
}
```

### 3.3 image_gallery（第一阶段临时）
```json
{
  "title": "...",
  "format": "image_gallery",
  "content": "相册说明",
  "attachments": ["data:image/png;base64,..."],
  "galleryCaptions": ["图1说明", "图2说明"]
}
```

> 建议后端在过渡期兼容 dataURL；接入上传接口后改为 URL。

### 3.4 external_link
```json
{
  "title": "...",
  "format": "external_link",
  "content": "补充说明",
  "linkUrl": "https://example.com/article/123",
  "linkTitle": "可选，默认帖子标题",
  "linkSummary": "可选摘要",
  "attachments": []
}
```

---

## 4. 后端校验建议

1. `format=external_link` 必须校验 `linkUrl`（http/https）。
2. 非 `image_gallery` 时，`attachments` 可为空。
3. 非超管发布强制 `status=pending`（保持你现有逻辑）。
4. 详情接口 `GET /posts/{postId}` 建议返回完整字段，避免前端二次拼装。

---

## 5. 权限与可见性建议

1. 详情访问建议口径：
- `published`：登录用户可见
- `pending/rejected/draft`：仅作者本人 + 管理审核角色可见

2. 上传接口权限：
- 建议 `post:create` 或登录即可（由你们安全策略决定）

---

## 6. 前端已改动文件（供联调排查）

- `src/views/admin/PostCreateView.vue`
- `src/views/admin/PostDetailView.vue`
- `src/views/admin/HomeView.vue`
- `src/services/modules/forumApi.js`
- `src/services/mockServer.js`
- `src/utils/contentFormat.js`
- `src/assets/main.css`

---

## 7. 联调验收

1. 选择不同 `format`，发布界面明显变化。
2. external_link 发布后，详情页链接可点击并新窗口打开。
3. markdown 发布后，详情页能按样式展示。
4. image_gallery 至少可展示图片网格。
5. 超管审核流不受影响（学生/教师仍走 pending）。
