# 互动交流模块增量文档（2026-03-16）

## 1. 模块范围

本次前端已实现界面：
1. 帖子详情互动区
- 点赞
- 收藏
- 多级评论（回复评论）

2. 话题与投票页
- 创建话题
- 添加多个投票选项
- 投票并查看票数

---

## 2. 接口契约（后端增量）

统一响应：

```json
{
  "code": 0,
  "message": "OK",
  "data": {}
}
```

### 2.1 帖子互动统计
- `GET /api/v1/posts/{postId}/interaction`
- 响应 `data`：

```json
{
  "likeCount": 12,
  "favoriteCount": 8,
  "liked": false,
  "favorited": true
}
```

### 2.2 点赞/取消点赞
- `POST /api/v1/posts/{postId}/like`
- 行为：二次点击应可取消（建议 toggle）
- 响应 `data` 同互动统计结构

### 2.3 收藏/取消收藏
- `POST /api/v1/posts/{postId}/favorite`
- 行为：二次点击应可取消（建议 toggle）
- 响应 `data` 同互动统计结构

### 2.4 评论列表（支持多级）
- `GET /api/v1/posts/{postId}/comments`
- 响应：

```json
{
  "list": [
    {
      "id": 1,
      "postId": 1001,
      "parentId": null,
      "author": "张三",
      "content": "写得很好",
      "createdAt": "2026-03-16T10:00:00.000Z"
    },
    {
      "id": 2,
      "postId": 1001,
      "parentId": 1,
      "author": "李四",
      "content": "同感",
      "createdAt": "2026-03-16T10:05:00.000Z"
    }
  ],
  "total": 2
}
```

### 2.5 发表评论 / 回复评论
- `POST /api/v1/posts/{postId}/comments`
- 请求：

```json
{
  "parentId": 1,
  "content": "这是回复",
  "author": "王五"
}
```

说明：
- 一级评论时 `parentId = null`
- 回复评论时 `parentId = 被回复评论ID`

### 2.6 话题列表
- `GET /api/v1/topics`
- 查询：`page,pageSize,keyword`（可选）
- 响应：

```json
{
  "list": [
    {
      "id": 1,
      "title": "是否支持周末自习室延长开放？",
      "description": "校园服务优化投票",
      "createdBy": "admin",
      "createdAt": "2026-03-16T09:00:00.000Z",
      "options": [
        { "id": 101, "text": "支持", "voteCount": 20 },
        { "id": 102, "text": "不支持", "voteCount": 5 }
      ]
    }
  ],
  "total": 1,
  "page": 1,
  "pageSize": 20
}
```

### 2.7 创建话题
- `POST /api/v1/topics`
- 请求：

```json
{
  "title": "是否支持周末自习室延长开放？",
  "description": "校园服务优化投票",
  "options": ["支持", "不支持", "无所谓"],
  "createdBy": "admin"
}
```

### 2.8 投票
- `POST /api/v1/topics/{topicId}/vote`
- 请求：

```json
{
  "optionId": 101
}
```

响应：返回更新后的话题或票数统计。

---

## 3. 数据库增量建议

### 3.1 评论表 `post_comment`
- `id` bigint PK
- `post_id` bigint not null
- `parent_id` bigint null
- `user_id` bigint not null
- `content` text not null
- `created_at` datetime not null
- `updated_at` datetime null

### 3.2 点赞表 `post_like`
- `id` bigint PK
- `post_id` bigint not null
- `user_id` bigint not null
- `created_at` datetime not null
- 唯一键：`(post_id, user_id)`

### 3.3 收藏表 `post_favorite`
- `id` bigint PK
- `post_id` bigint not null
- `user_id` bigint not null
- `created_at` datetime not null
- 唯一键：`(post_id, user_id)`

### 3.4 话题表 `topic`
- `id` bigint PK
- `title` varchar(128) not null
- `description` varchar(500) null
- `created_by` bigint not null
- `created_at` datetime not null

### 3.5 话题选项表 `topic_option`
- `id` bigint PK
- `topic_id` bigint not null
- `text` varchar(128) not null
- `vote_count` int default 0

### 3.6 投票记录表 `topic_vote`
- `id` bigint PK
- `topic_id` bigint not null
- `option_id` bigint not null
- `user_id` bigint not null
- `created_at` datetime not null
- 唯一键：`(topic_id, user_id)`（每人每话题一票）

---

## 4. 权限建议

- 评论/点赞/收藏/投票：登录即可
- 创建话题：建议 `admin/super_admin`，或按业务放给 `teacher`

---

## 5. 前端已接入文件

- `src/views/admin/PostDetailView.vue`
- `src/views/admin/TopicVoteView.vue`
- `src/services/modules/forumApi.js`
- `src/router/index.js`
- `src/components/layout/AdminLayout.vue`

---

## 6. 验收清单

1. 点赞/收藏可成功计数，并支持取消。
2. 评论支持回复评论（至少两级）。
3. 话题可创建并投票，票数实时变化。
4. 接口返回结构满足 `data.list + total` 约定。
