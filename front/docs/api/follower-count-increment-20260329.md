# 个人主页/公开主页粉丝数展示增量文档（2026-03-29）

## 1. 变更目标

在以下页面展示粉丝相关统计：

1. 个人主页 `/admin/profile`
2. 用户公开主页 `/admin/profile/:userId`

新增展示项：
- 粉丝数（`followerCount`）
- 关注数（`followingCount`）

## 2. 前端已完成

### 2.1 个人主页

- 在“内容资产”卡片中新增：
  - 粉丝
  - 关注

### 2.2 公开主页

- 在“公开数据”卡片中新增：
  - 粉丝
  - 关注

### 2.3 兼容策略

- 若后端未返回字段，前端默认展示 `0`，不阻塞页面渲染。

## 3. 后端接口增量要求

## 3.1 个人主页接口

- `GET /api/v1/profile/me`
- `data.stats` 建议补充：
  - `followerCount`
  - `followingCount`

## 3.2 公开主页接口

- `GET /api/v1/profile/users/{userId}`
- `data.stats` 建议补充：
  - `followerCount`
  - `followingCount`

## 4. 字段定义建议

- `followerCount`: number，当前用户被多少人关注
- `followingCount`: number，当前用户关注了多少人

## 5. 验收项

1. 个人主页可正确展示粉丝/关注数。
2. 公开主页可正确展示粉丝/关注数。
3. 关注/取消关注后，相关统计在刷新后可反映最新结果。
