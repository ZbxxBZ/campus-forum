# 话题权限增量对齐（2026-03-18）

## 1. 背景

当前学生无法发布话题，核心原因是权限模型中缺少话题维度能力或未下发到登录态。

## 2. 新增权限项（建议）

- `topic:read`：查看话题列表
- `topic:create`：发布话题
- `topic:vote`：参与投票

> 说明：`role:update` 已用于“权限管理页保存配置”按钮控制。

## 3. 后端必须落地

1. 角色权限配置接口可保存上述 3 个权限。
2. 登录接口 / 获取用户信息接口返回的 `permissions` 中包含上述权限。
3. 话题接口按权限鉴权：
- `GET /api/v1/topics` -> `topic:read`
- `POST /api/v1/topics` -> `topic:create`
- `POST /api/v1/topics/{topicId}/vote` -> `topic:vote`

## 4. 前端已完成内容

1. 权限管理页已增加并显示话题权限中文选项。
2. 互动交流菜单改为按话题权限显示。
3. 话题页发布按钮、投票按钮按权限启用/禁用并提示缺失权限。
4. 若无话题查看权限，页面会提示需分配 `topic:read`。

## 5. 建议默认角色策略（可调整）

- super_admin：`topic:read/topic:create/topic:vote`
- admin：`topic:read/topic:create/topic:vote`
- teacher：`topic:read/topic:create/topic:vote`
- student：`topic:read/topic:vote`（是否允许 `topic:create` 由你们业务决定）

## 6. 验收清单

1. 超级管理员在权限管理页可勾选并保存 `topic:create` 给学生。
2. 学生重新登录后，能在“话题与投票”页看到“发布话题”按钮已可点击。
3. 去掉 `topic:create` 后，按钮变灰且点击提示无权限。
4. `topic:vote` 去掉后，投票按钮变灰且不可投票。
