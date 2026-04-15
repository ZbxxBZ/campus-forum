# 帖子详情功能增量文档（2026-03-16）

## 1. 目标

用户在工作台点击“已发布帖子列表”中的标题后，进入帖子详情页，看到完整帖子主体。

前端入口已实现：
- 路由：`/admin/post-detail/:postId`
- 入口：工作台列表标题可点击

---

## 2. 新增接口（后端）

### 2.1 获取帖子详情

- 方法：`GET`
- 路径：`/api/v1/posts/{postId}`
- 鉴权：登录即可（建议按可见性做权限控制）

响应结构：

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "post": {
      "id": 1001,
      "title": "期末复习资料共享帖",
      "summary": "汇总高数、英语、计组复习资料",
      "content": "<p>正文内容</p>",
      "format": "rich_text",
      "attachments": ["https://cdn.xxx/a.pdf"],
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
  }
}
```

兼容说明：
- 前端也可兼容 `data` 直接是帖子对象（不包 `post`），但建议统一为 `data.post`。

---

## 3. 权限与可见性建议（关键）

建议后端按以下规则校验：

1. `status = published`：登录用户可见。  
2. `status != published`：仅作者本人、审核/管理角色可见。  
3. `visibility = private`：仅作者本人可见（管理角色可按业务决定是否可见）。

若不满足权限，返回：
- `code = 10006`
- `message = 无权限访问`

---

## 4. 前端已完成的改动

- 工作台列表支持点击标题进入详情
- 详情页展示：标题、摘要、正文、附件、标签、作者、板块、状态、可见性、发布时间
- 富文本用 `v-html` 渲染，其他格式按文本展示

对应文件：
- `src/views/admin/HomeView.vue`
- `src/views/admin/PostDetailView.vue`
- `src/router/index.js`
- `src/services/modules/forumApi.js`

---

## 5. 待你和前端确认的 3 项（建议并行）

1. 详情页是否要补扩展字段：`viewCount`、`likeCount`、`commentCount`。
2. `attachments` 是否升级为对象数组（`url/type/size/duration/cover`）。
3. 非公开状态（pending/rejected/draft）的可见口径是否严格“仅作者+管理角色”。
