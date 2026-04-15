# 工作台信息流与分页联调接口契约（2026-03-28）

## 1. 背景

当前工作台 `/admin/home` 已有信息流导航与分页交互，但出现“上一页/下一页灰色不可用、每页条数切换不生效”等联调问题。  
本文件用于统一前后端口径，避免实现偏差。

## 2. 接口范围

- 接口：`GET /api/v1/posts/published`
- 鉴权：登录态
- 统一响应：`{ code, message, data }`

## 3. 请求参数（后端必须支持）

### 3.1 信息流参数

- `feed`：`all | recommend | hot | latest | followed`
  - `all`：全部（按发布时间倒序）
  - `recommend`：推荐（当前可先按默认排序）
  - `hot`：热门（按热度降序）
  - `latest`：最新（按发布时间倒序）
  - `followed`：我的关注（当前可先等价于 all，后续接关注流）

### 3.2 分页参数

- `page`：页码，从 `1` 开始
- `pageSize`：每页条数，建议上限 `100`

### 3.3 检索筛选参数

- `keyword`
- `author`
- `tag`
- `boardId`
- `dateFrom`（YYYY-MM-DD）
- `dateTo`（YYYY-MM-DD）

## 4. 返回结构（强约束）

后端必须返回：

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

字段要求：
- `list`：当前页数据数组
- `total`：当前筛选条件下总条数（不是当前页数量）
- `page`：当前页（应与请求一致，或为后端修正后的有效页）
- `pageSize`：当前页大小（应与请求一致，或为后端修正后的有效值）

## 5. 排序口径（后端实现）

1. `feed=all`：`createdAt DESC`
2. `feed=latest`：`createdAt DESC`
3. `feed=hot`：按热度降序（同分 `createdAt DESC`）
4. `feed=recommend`：可先用默认排序，后续升级推荐算法
5. `feed=followed`：短期可返回 all 口径；长期改为关注作者流
6. 当传 `keyword` 时：建议优先相关度排序（可覆盖 feed 默认排序）

## 6. 热门所需字段

每条帖子建议返回：
- `likeCount`
- `favoriteCount`
- `commentCount`

当前前端热度兜底：
`hotScore = likeCount * 3 + favoriteCount * 2 + commentCount`

> 若后端直接返回 `hotScore`，前端可直接使用。

## 7. 错误处理建议

1. `feed` 非法值：返回 `400` + 明确 message（不要静默降级）
2. 鉴权失败：`401/403`（保持统一）
3. 分页越界：返回空 `list` + 原 `total` + 当前 `page/pageSize`

## 8. 联调验收清单（必须通过）

1. 请求 `feed=all&page=2&pageSize=20` 时，响应 `data.page=2`，且 `list` 为第2页数据。
2. 请求 `pageSize=50` 时，响应 `data.pageSize=50`，列表条数按页大小变化。
3. `total` 在筛选条件不变时稳定，不随翻页波动。
4. `feed=followed` 不报错，至少返回可分页数据。
5. `feed` 切换后（all/recommend/hot/latest/followed）分页仍可继续使用。

## 9. 前端已对齐说明

前端当前已做到：
- 所有请求透传 `feed/page/pageSize`。
- 切换 feed 时重置到第1页并重新请求。
- 分页状态按 `data.page/data.pageSize/data.total` 回填。
- 详情返回可恢复原 feed + 原筛选 + 原页码 + 原 pageSize。
