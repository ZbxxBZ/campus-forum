# 帖子精细化管理分页增量文档（2026-04-12）

## 1. 变更目标

页面：`/admin/posts`

为“帖子精细化管理”补齐完整分页能力：

1. 顶部分页控件：上一页 / 当前页 / 下一页 / 每页条数
2. 底部分页控件：上一页 / 当前页 / 下一页 / 每页条数
3. 分页与筛选联动：切换关键字、板块、格式、可见性、状态后从第 1 页重新查询

## 2. 前端已完成

1. 请求参数透传：`page`、`pageSize`、`keyword`、`status`、`boardId`、`format`、`visibility`
2. 页码显示：`第 page / totalPages 页`
3. 每页条数可选：`10/20/50/100`
4. 上下双分页条逻辑一致
5. 列表数据不再做前端截断分页，完全按后端返回分页渲染

## 3. 后端接口契约要求

接口：`GET /api/v1/posts`

### 3.1 查询参数（本页面实际使用）

- `page`（默认 1）
- `pageSize`（默认 20，建议上限 100）
- `keyword`
- `status`（可能是多值，如 `published,hidden`）
- `boardId`
- `format`
- `visibility`

### 3.2 返回结构（必须）

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

### 3.3 状态多选建议

- 支持 `status=published,hidden` 按 IN 查询
- 若只传单值，按等值查询

> 该能力可避免前端再做状态二次过滤，保证分页总数准确。

## 4. 验收项

1. 在 `/admin/posts` 切换到第 2 页，请求参数应为 `page=2`。
2. 切换“每页 50 条”后，请求参数应为 `page=1&pageSize=50`。
3. 返回 `total/page/pageSize` 能驱动上下分页条同步变化。
4. `status=published,hidden` 时，结果仅包含已发布和已下架。
5. 筛选条件变化后页码重置到第 1 页。
