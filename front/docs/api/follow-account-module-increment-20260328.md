# 关注账号功能增量文档（2026-03-28）

## 1. 变更目标

新增“关注账号”能力，覆盖三处入口：

1. 个人主页新增「我的关注」模块，展示已关注账号列表。  
2. 公开主页新增「关注/已关注」按钮。  
3. 帖子详情页新增「关注作者/已关注作者」按钮。  

并满足：
- 不能关注自己。
- 访问自己的公开主页时，自动跳转到个人主页。

## 2. 前端已完成

### 2.1 个人主页

页面：`/admin/profile`

- 底部 Tab 新增：`我的关注`
- 列表字段：`id/displayName/username/role`
- 点击昵称可跳转公开主页：`/admin/profile/{userId}`

### 2.2 公开主页

页面：`/admin/profile/:userId`

- 新增关注按钮（可切换“关注/已关注”）
- 已关注状态使用高亮色（沿用现有 `action-btn-active` 风格）
- 若 `:userId` 为当前登录用户，自动跳转到 `/admin/profile`

### 2.3 帖子详情页

页面：`/admin/post-detail/:postId`

- 在作者信息区域新增按钮：`关注作者/已关注作者`
- 若帖子作者就是当前用户，不显示关注按钮

## 3. 后端接口需求

## 3.1 关注关系查询

- `GET /api/v1/follows/relation?targetUserId={userId}`
- 权限：登录即可
- 响应：

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "followed": true
  }
}
```

## 3.2 关注/取消关注（toggle）

- `POST /api/v1/follows/{targetUserId}/toggle`
- 权限：登录即可
- 规则：若已关注则取消，否则关注
- 约束：`targetUserId != currentUserId`
- 响应：

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "followed": true
  }
}
```

## 3.3 我的关注列表

- `GET /api/v1/profile/me/following`
- 权限：登录即可
- 参数：`page,pageSize,keyword(可选)`
- 响应：

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "list": [
      {
        "id": 2,
        "username": "teacher_li",
        "displayName": "李老师",
        "avatar": "",
        "role": "teacher",
        "bio": "课程答疑",
        "joinedAt": "2026-03-11T00:10:00.000Z"
      }
    ],
    "total": 1,
    "page": 1,
    "pageSize": 20
  }
}
```

## 4. 建议补充字段（可选但推荐）

在公开主页接口 `GET /api/v1/profile/users/{userId}` 的 `data.stats` 增加：
- `followerCount`
- `followingCount`

用于后续展示账号影响力与社交关系。

## 5. 数据库建议

新增表：

- `user_follow(id, user_id, target_user_id, created_at, UNIQUE(user_id, target_user_id))`

索引建议：

- `idx_follow_user (user_id, created_at)`
- `idx_follow_target (target_user_id, created_at)`

## 6. 验收项

1. 个人主页可看到“我的关注”列表。
2. 在公开主页点关注后按钮变为“已关注”，再次点击可取消。
3. 在帖子详情可关注作者，状态切换正常。
4. 用户无法关注自己（后端返回业务错误）。
5. 打开自己的公开主页地址时，自动跳回个人主页。
