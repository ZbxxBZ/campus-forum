# 个人主页模块增量文档（2026-03-18）

## 1. 目标与原则

### 1.1 目标
为所有登录用户提供统一的个人主页能力，支持身份展示、内容沉淀、互动资产查看。

### 1.2 角色策略
- 学生/教师：主页入口前置（高频使用）
- 管理员/超级管理员：主页保留，默认入口优先级可低于管理菜单

### 1.3 统一原则
- 所有角色都有主页
- 差异在“模块可见性”和“默认导航优先级”，不是“有没有主页”

---

## 2. 前端页面信息架构（建议）

## 2.1 路由
- `GET /admin/profile`：我的主页（仅本人）
- `GET /admin/profile/:userId`：用户公开主页（可选二期）

## 2.2 Tab 结构（MVP）
1. 资料卡（基础信息）
2. 我的帖子
3. 我的评论
4. 我的点赞
5. 我的收藏

## 2.3 管理角色扩展 Tab（可选）
- 我的审核记录（admin/super_admin）
- 我的管理操作（admin/super_admin）

---

## 3. 隐私与访问规则

## 3.1 默认隐私建议
- 点赞列表：仅本人可见
- 收藏列表：仅本人可见
- 帖子列表：按帖子自身可见性规则
- 评论列表：默认公开（可按业务做脱敏）

## 3.2 公开主页（若启用）
- 仅展示：基础信息、可公开帖子、可公开评论数量
- 不展示：点赞/收藏明细（除非用户显式开放）

---

## 4. 接口契约（后端）

统一响应：

```json
{
  "code": 0,
  "message": "OK",
  "data": {}
}
```

## 4.1 获取我的主页基础信息
- `GET /api/v1/profile/me`
- 权限：登录即可

响应示例：

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "user": {
      "id": 101,
      "username": "zhangsan",
      "displayName": "张三",
      "avatar": "https://cdn.xxx/avatar/a.png",
      "role": "student",
      "bio": "计算机学院2023级",
      "joinedAt": "2026-01-10T08:00:00.000Z"
    },
    "stats": {
      "postCount": 12,
      "commentCount": 35,
      "likeCount": 18,
      "favoriteCount": 9
    }
  }
}
```

## 4.2 更新我的资料
- `PATCH /api/v1/profile/me`
- 权限：登录即可
- 请求字段：`displayName, avatar, bio`

## 4.3 我的帖子
- `GET /api/v1/profile/me/posts`
- 权限：登录即可
- 查询：`page,pageSize,status,keyword`

## 4.4 我的评论
- `GET /api/v1/profile/me/comments`
- 权限：登录即可
- 查询：`page,pageSize,keyword`

## 4.5 我的点赞（仅本人）
- `GET /api/v1/profile/me/likes`
- 权限：登录即可
- 查询：`page,pageSize`

## 4.6 我的收藏（仅本人）
- `GET /api/v1/profile/me/favorites`
- 权限：登录即可
- 查询：`page,pageSize`

## 4.7 （可选）公开主页
- `GET /api/v1/profile/users/{userId}`
- 权限：登录即可
- 返回公开字段，不返回点赞/收藏明细

---

## 5. 列表响应统一格式

所有列表接口建议统一：

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

---

## 6. 数据库增量建议

## 6.1 user_profile（若用户主表字段不足）
- `user_id` bigint PK
- `avatar` varchar(255)
- `bio` varchar(500)
- `updated_at` datetime

## 6.2 使用现有表聚合（无需新表）
- 我的帖子：`posts`（author_id / author）
- 我的评论：`post_comment.user_id`
- 我的点赞：`post_like.user_id`
- 我的收藏：`post_favorite.user_id`

## 6.3 索引建议
- `posts(author_id, created_at)`
- `post_comment(user_id, created_at)`
- `post_like(user_id, created_at)`
- `post_favorite(user_id, created_at)`

---

## 7. 权限建议

- `profile:read:self`（可并入登录默认能力）
- `profile:update:self`
- 管理角色不应自动绕过“点赞/收藏仅本人可见”，除非有审计场景并记录操作日志

---

## 8. 前后端联调清单（MVP）

1. 登录后可进入 `/admin/profile`
2. 资料卡显示成功（头像/昵称/角色/简介/加入时间）
3. 我的帖子/评论/点赞/收藏四个 Tab 均能分页
4. 点赞/收藏默认仅本人可见
5. 修改个人简介后刷新可见

---

## 9. 分阶段落地建议

### Phase 1（本周）
- 完成 `/profile/me` + 四个“我的列表”接口
- 前端完成 `/admin/profile` 单页多 Tab

### Phase 2（下周）
- 增加公开主页 `users/{userId}`
- 增加“公开点赞/收藏”隐私开关

### Phase 3
- 增加管理角色行为摘要（审核数、处理效率、最近操作）
