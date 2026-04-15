# 精准全文检索增量文档（2026-03-27）

## 1. 目标

在工作台“已发布帖子”列表支持精准检索与高级筛选：
- 全文检索：标题、内容、作者、话题标签
- 高级筛选：板块、发布时间范围

## 2. 前端已完成

页面：`/admin/home`

### 2.1 新增交互
1. 检索输入框（全文检索）
2. 高级筛选展开/收起
3. 高级筛选项：
- 作者
- 话题标签
- 所属板块
- 发布时间起
- 发布时间止
4. 结果数统计显示
5. 重置筛选按钮

### 2.2 兼容策略
- 前端已做本地过滤兜底，后端未完全支持前也可用。
- 推荐后端实现服务端过滤，减少无效数据下发。

## 3. 后端接口建议

接口：`GET /api/v1/posts/published`

### 3.1 查询参数（建议）
- `keyword`：全文关键词（标题/内容/作者/标签）
- `author`：作者账号关键词
- `tag`：标签关键词
- `boardId`：板块ID
- `dateFrom`：发布时间起（YYYY-MM-DD）
- `dateTo`：发布时间止（YYYY-MM-DD）
- `page`：默认1
- `pageSize`：默认20，建议上限100

### 3.2 返回结构

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "list": [
      {
        "id": 1001,
        "title": "期末复习资料共享帖",
        "summary": "...",
        "content": "...",
        "author": "teacher_li",
        "authorId": 2,
        "tags": ["期末", "资料共享"],
        "boardId": 1,
        "boardName": "学习交流",
        "format": "rich_text",
        "formatLabel": "富文本",
        "status": "published",
        "createdAt": "2026-03-10T08:00:00.000Z"
      }
    ],
    "total": 1,
    "page": 1,
    "pageSize": 20
  }
}
```

## 4. 查询口径建议（后端实现）

1. `keyword` 同时匹配：`title/content/author/tags`
2. `author` 为独立筛选项，与 `keyword` 叠加
3. `tag` 为独立筛选项，与 `keyword` 叠加
4. `dateFrom/dateTo` 按 `createdAt` 范围过滤（包含边界）
5. 始终限定 `status = published`

## 5. 索引建议

- `posts(status, created_at)`
- `posts(board_id, status, created_at)`
- `posts(author, status, created_at)`
- `posts(title)`（可配全文索引）
- `posts(content)`（建议全文索引）

> 若使用 MySQL，可评估 `FULLTEXT(title, content)`，标签可单独映射表或 JSON 倒排。

## 6. 验收项

1. 输入 `keyword` 可命中标题/内容/作者/标签。
2. 设置板块后，仅返回对应板块已发布帖子。
3. 设置发布时间范围后，结果符合区间。
4. 返回分页字段 `list/total/page/pageSize` 完整。
5. 工作台页面检索结果与后端查询结果一致。

## 7. 相关度排序补充（v2）

### 7.1 前端当前行为（已上线）

- 当传入 `keyword` 时，前端会按“相关度优先”进行临时排序兜底：
1. 标题精确/完整命中优先
2. 标签命中次优先
3. 摘要/正文命中再次优先
4. 同分按发布时间倒序
- 对“四六级”增加了召回增强：可额外匹配“四级/六级/四六”。

> 该逻辑用于过渡，最终应以服务端相关度排序为准。

### 7.2 对后端的回应口径（本次联调）

1. 接口路径与返回结构不变：`GET /api/v1/posts/published` + `data.list/total/page/pageSize`。
2. 当传 `keyword` 时，后端默认排序改为“匹配度从高到低”。
3. 推荐排序权重：标题完整命中 > 标题分词命中 > 正文命中 > 标签/作者命中。
4. 同分按发布时间倒序。

### 7.3 新增验收口径

1. 搜索“四六级”应能命中“四六级/四级/六级/四六”等相关帖子。
2. 同一关键字下，标题精确命中的帖子应稳定排在仅正文命中的帖子前面。
