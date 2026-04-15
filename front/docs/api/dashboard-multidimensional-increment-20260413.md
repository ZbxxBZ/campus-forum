# 系统总览多维统计增量文档（2026-04-13）

## 1. 变更目标

页面：`/admin/dashboard`

在保留原有 KPI 卡片基础上，完成总览统计升级：

1. 不再展示“峰值QPS”卡片
2. 趋势统计改为近一个月（30天）
3. 角色占比、板块发帖 Top 使用彩色饼图（含图例与占比）
4. 保留帖子状态分布条形图，便于管理侧快速对比

## 2. 前端已完成

1. 核心 KPI 展示：注册用户 / 帖子总量 / 待审核 / 今日驳回 / 在线用户
2. 扩展 KPI 展示：评论总量 / 点赞总量 / 收藏总量 / 今日审核通过率
3. 趋势图已升级为 30 天：
- 近一个月发帖趋势
- 近一个月活跃趋势
4. 饼图模块：
- 角色占比（彩色饼图 + 图例 + 百分比）
- 板块发帖 Top（彩色饼图 + 图例 + 百分比）
5. 兼容降级：后端暂未返回新字段时，前端使用兜底值渲染，不阻塞页面。

## 3. 后端接口增量要求

接口沿用：`GET /api/v1/dashboard/stats`

统一响应：`{ code, message, data }`

### 3.1 现有字段（继续可返回）

- `totalUsers`
- `totalPosts`
- `pendingReviews`
- `rejectedToday`
- `onlineUsers`
- `peakQps`（可继续返回，但前端已不展示）

### 3.2 建议新增字段（P0）

- `totalComments`: number
- `totalLikes`: number
- `totalFavorites`: number
- `reviewPassedToday`: number
- `reviewSubmittedToday`: number
- `publishedPosts`: number
- `hiddenPosts`: number
- `rejectedPosts`: number

### 3.3 建议新增数组（P1）

- `postTrend`: `[{ label/date, value/count }]`（建议30天）
- `activeTrend`: `[{ label/date, value/count }]`（建议30天）
- `roleDistribution`: `[{ label, value }]`
- `statusDistribution`: `[{ label, value }]`
- `boardDistribution`: `[{ label, value }]`（建议按发帖量降序 TopN）

## 4. 响应示例

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "totalUsers": 1280,
    "totalPosts": 6450,
    "pendingReviews": 46,
    "rejectedToday": 7,
    "onlineUsers": 438,
    "peakQps": 1260,
    "totalComments": 21342,
    "totalLikes": 98211,
    "totalFavorites": 15430,
    "reviewPassedToday": 38,
    "reviewSubmittedToday": 52,
    "publishedPosts": 6010,
    "hiddenPosts": 204,
    "rejectedPosts": 190,
    "postTrend": [
      { "label": "D1", "value": 102 },
      { "label": "D2", "value": 117 }
    ],
    "activeTrend": [
      { "label": "D1", "value": 480 },
      { "label": "D2", "value": 512 }
    ],
    "roleDistribution": [
      { "label": "学生", "value": 930 },
      { "label": "教师", "value": 290 },
      { "label": "管理员", "value": 60 }
    ],
    "statusDistribution": [
      { "label": "已发布", "value": 6010 },
      { "label": "待审核", "value": 46 },
      { "label": "已下架", "value": 204 },
      { "label": "已驳回", "value": 190 }
    ],
    "boardDistribution": [
      { "label": "学习交流", "value": 2580 },
      { "label": "校园生活", "value": 2230 },
      { "label": "通知公告", "value": 1640 }
    ]
  }
}
```

## 5. 验收项

1. 总览页面不再展示峰值QPS卡片。
2. 趋势图按近一个月（30天）展示。
3. 角色占比和板块发帖 Top 使用彩色饼图，图例与百分比正确。
4. 状态分布条形图比例与返回值一致。
5. 后端仅返回旧字段时，页面仍可正常渲染（降级可用）。
