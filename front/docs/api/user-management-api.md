# 校园论坛管理系统 API 文档（用户管理模块）

- 版本：v1
- 基础路径：`/api/v1`
- 鉴权方式：`Authorization: Bearer <access_token>`
- 返回格式：统一 JSON 包装

## 1. 通用返回结构

### 成功

```json
{
  "code": 0,
  "message": "OK",
  "data": {}
}
```

### 失败

```json
{
  "code": 10001,
  "message": "Validation failed",
  "data": null,
  "requestId": "f7c1f6f44b1a4bba"
}
```

## 2. 鉴权与注册登录

### 2.1 用户注册

- 方法：`POST`
- 路径：`/auth/register`
- 权限：公开

请求体：

```json
{
  "username": "zhangsan",
  "displayName": "张三",
  "email": "zhangsan@campus.edu",
  "password": "Admin123!"
}
```

字段约束：
- `username`: 4-32 位，字母/数字/下划线
- `displayName`: 2-32 位
- `email`: 校园邮箱优先（可按学校规则校验）
- `password`: 至少 8 位，建议含大小写字母+数字+特殊字符

成功响应：

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "user": {
      "id": 101,
      "username": "zhangsan",
      "displayName": "张三",
      "email": "zhangsan@campus.edu",
      "role": "student",
      "status": "active",
      "createdAt": "2026-03-11T03:00:00.000Z"
    }
  }
}
```

### 2.2 用户登录

- 方法：`POST`
- 路径：`/auth/login`
- 权限：公开

请求体：

```json
{
  "username": "admin",
  "password": "Admin123!"
}
```

成功响应：

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 7200,
    "user": {
      "id": 1,
      "username": "admin",
      "displayName": "系统管理员",
      "email": "admin@campus.edu",
      "role": "super_admin",
      "status": "active"
    },
    "permissions": [
      "user:create",
      "user:read",
      "user:update",
      "user:delete",
      "role:read",
      "role:update"
    ]
  }
}
```

### 2.3 获取当前登录用户信息

- 方法：`GET`
- 路径：`/auth/profile`
- 权限：已登录

成功响应：

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "user": {
      "id": 1,
      "username": "admin",
      "displayName": "系统管理员",
      "email": "admin@campus.edu",
      "role": "super_admin",
      "status": "active"
    },
    "permissions": ["user:read", "role:read"]
  }
}
```

## 3. 用户管理

### 3.1 用户列表查询

- 方法：`GET`
- 路径：`/users`
- 权限：`user:read`

查询参数：
- `keyword`：按用户名/邮箱模糊搜索
- `role`：角色过滤（`super_admin`/`admin`/`teacher`/`student`）
- `status`：状态过滤（`active`/`disabled`）
- `page`：页码（默认 1）
- `pageSize`：每页条数（默认 20，最大 100）

成功响应：

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "list": [
      {
        "id": 1,
        "username": "admin",
        "displayName": "系统管理员",
        "email": "admin@campus.edu",
        "role": "super_admin",
        "status": "active",
        "createdAt": "2026-03-11T00:00:00.000Z"
      }
    ],
    "total": 1,
    "page": 1,
    "pageSize": 20
  }
}
```

### 3.2 修改用户角色

- 方法：`PATCH`
- 路径：`/users/{userId}/role`
- 权限：`user:update`

请求体：

```json
{
  "role": "teacher"
}
```

成功响应：

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "id": 101,
    "role": "teacher"
  }
}
```

### 3.3 启用/禁用用户

- 方法：`PATCH`
- 路径：`/users/{userId}/status`
- 权限：`user:update`

请求体：

```json
{
  "status": "disabled"
}
```

成功响应：

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "id": 101,
    "status": "disabled"
  }
}
```

## 4. 权限管理（RBAC）

### 4.1 角色列表与权限

- 方法：`GET`
- 路径：`/roles`
- 权限：`role:read`

成功响应：

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "list": [
      {
        "role": "admin",
        "roleLabel": "管理员",
        "permissions": ["user:create", "user:read", "user:update", "role:read"]
      }
    ]
  }
}
```

### 4.2 更新角色权限

- 方法：`PUT`
- 路径：`/roles/{role}/permissions`
- 权限：`role:update`

请求体：

```json
{
  "permissions": [
    "user:read",
    "user:update",
    "role:read"
  ]
}
```

成功响应：

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "role": "admin",
    "permissions": ["user:read", "user:update", "role:read"]
  }
}
```

## 5. 建议错误码

- `0`: 成功
- `10001`: 参数校验失败
- `10002`: 用户名或邮箱已存在
- `10003`: 用户名或密码错误
- `10004`: 账号已被禁用
- `10005`: Token 无效或已过期
- `10006`: 无权限访问
- `10007`: 资源不存在
- `10008`: 请求频率过高
- `20000`: 系统内部错误

## 6. 安全与高并发建议

- 登录接口增加图形验证码/滑块验证码，限制暴力破解。
- 全接口启用 HTTPS，Token 建议短期 AccessToken + RefreshToken。
- 用户密码后端使用 `bcrypt` 或 `argon2` 哈希存储，不可明文。
- 关键接口（登录、改权限、禁用用户）写审计日志。
- 对 `/auth/login`、`/users` 等高频接口做限流与缓存。
- 对角色变更操作做事务和幂等处理，避免高并发下权限错乱。
