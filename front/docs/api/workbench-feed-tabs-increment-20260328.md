# 工作台信息流导航增量文档（2026-03-28）

## 1. 变更目标

在工作台 `/admin/home` 的“刷新按钮”和“帖子列表”之间新增信息流导航：
- 全部
- 推荐（默认）
- 热门
- 最新
- 我的关注（占位）

并保持原有检索与高级筛选在三个板块下都可使用。

## 2. 前端已完成

页面：`/admin/home`

1. 新增导航栏按钮：`全部 / 推荐 / 热门 / 最新 / 我的关注`，默认选中“推荐”。
2. 检索与高级筛选仍然生效：
- `keyword`
- `author`
- `tag`
- `boardId`
- `dateFrom`
- `dateTo`
3. 当前前端排序兜底逻辑：
- 有 `keyword`：按相关度优先（同分按发布时间倒序）
- 无 `keyword` 且选“热门”：按热度降序
- 无 `keyword` 且选“最新”：按发布时间降序
- 无 `keyword` 且选“全部”：按发布时间降序
- “推荐”：暂按后端返回顺序展示（后续可切换为推荐算法）
4. “我的关注”目前为前端占位模块，暂按“全部”口径展示，并给出占位提示。
5. 板块下拉选项已与帖子结果集解耦，避免筛选后下拉选项丢失。

## 3. 后端接口增量建议

接口仍用：`GET /api/v1/posts/published`

### 3.1 查询参数建议新增

- `feed`：`all | recommend | hot | latest | followed`（默认 `recommend`）
- 现有筛选参数继续保留：`keyword,author,tag,boardId,dateFrom,dateTo,page,pageSize`

### 3.2 排序口径建议

1. `feed=latest`：`createdAt DESC`
2. `feed=hot`：按热度分降序（同分按 `createdAt DESC`）
3. `feed=all`：按 `createdAt DESC`
4. `feed=recommend`：当前可先走已有排序，后续再接推荐策略
5. `feed=followed`：后续接入“关注关系”后按关注作者内容流排序
6. 若传 `keyword`：建议优先按相关度排序（覆盖 feed 排序），与前端当前行为一致

## 4. 热门计算所需字段（后端返回）

建议每条帖子至少返回：
- `likeCount`
- `favoriteCount`
- `commentCount`

前端当前热度公式（可后续与后端统一）：

`hotScore = likeCount * 3 + favoriteCount * 2 + commentCount`

> 若后端直接返回 `hotScore`，前端可直接使用，不必重复计算。

## 5. 返回结构（保持不变）

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

## 6. 验收项

1. 默认进入工作台展示“推荐”信息流。
2. 切换“热门”后，帖子按热度从高到低。
3. 切换“最新”后，帖子按发布时间从新到旧。
4. 切换“全部”后，帖子按发布时间从新到旧。
5. 切换“我的关注”可见占位提示，且不影响检索功能。
6. 在任一信息流下，检索/高级筛选都可正常生效。
7. 板块下拉始终显示完整可选板块，不随结果集缩窄。
