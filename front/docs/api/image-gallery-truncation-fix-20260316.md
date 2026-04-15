# 图文相册 Data truncation 修复增量（2026-03-16）

## 问题

学生发布图文相册时出现：
`Data truncation: Data too long for column 'attachments_json'`

根因：
- 之前前端把本地图片转成 base64 直接写入 `attachments_json`。
- base64 字符串很长，超出数据库列长度。

---

## 前端已修复

- 图文相册发布改为：
  1) 先调用上传接口拿图片 URL
  2) 再调用 `POST /api/v1/posts` 提交 `attachments: string[]`（URL 数组）

涉及文件：
- `src/services/modules/forumApi.js`（新增 `uploadImagesApi`）
- `src/views/admin/PostCreateView.vue`（图文发布流程改造）

---

## 后端需要补齐

### 1) 新增上传接口

- `POST /api/v1/uploads/images`
- `Content-Type: multipart/form-data`
- 字段：`files`（可多文件）

响应示例：

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

### 2) 帖子发布接口保持

- `POST /api/v1/posts`
- `attachments` 继续使用 `string[]`（URL 数组），不要接收 base64。

### 3) 数据库建议

- `attachments_json` 至少使用 `TEXT`（更稳妥）
- 即便未来升级独立附件表，也建议保留该列做过渡兼容

---

## 验收

1. 选 1~3 张本地图片发布图文相册，不再报 Data truncation。
2. 数据库 `attachments_json` 存储 URL 数组（非 base64）。
3. 详情页可正常展示图文相册图片。
