export const ROLE_PERMISSIONS = {
  super_admin: [
    'dashboard:read',
    'user:create',
    'user:read',
    'user:update',
    'user:delete',
    'post:read',
    'post:create',
    'post:update',
    'post:delete',
    'board:read',
    'board:update',
    'review:read',
    'review:approve',
    'review:reject',
    'topic:read',
    'topic:create',
    'topic:vote',
    'auditlog:read',
    'role:read',
    'role:update'
  ],
  teacher: [
    'dashboard:read',
    'post:read',
    'post:create',
    'review:read',
    'review:approve',
    'review:reject',
    'topic:read',
    'topic:create',
    'topic:vote'
  ],
  student: ['dashboard:read', 'topic:read', 'topic:vote']
}

export const ROLE_LABELS = {
  super_admin: '超级管理员',
  teacher: '教师',
  student: '学生'
}

export const PERMISSION_LABELS = {
  'dashboard:read': '查看系统总览',
  'user:create': '创建用户',
  'user:read': '查看用户列表',
  'user:update': '编辑用户信息',
  'user:delete': '删除用户',
  'post:read': '查看帖子',
  'post:create': '发布帖子',
  'post:update': '编辑帖子',
  'post:delete': '删除帖子',
  'board:read': '查看板块配置',
  'board:update': '管理板块配置',
  'review:read': '查看待审核内容',
  'review:approve': '审核通过',
  'review:reject': '审核驳回',
  'topic:read': '查看话题投票',
  'topic:create': '发布话题',
  'topic:vote': '参与投票',
  'auditlog:read': '查看审核日志',
  'role:read': '查看角色权限',
  'role:update': '修改角色权限'
}

export const ALL_PERMISSIONS = Object.keys(PERMISSION_LABELS).sort()

export function getPermissionLabel(permission) {
  return PERMISSION_LABELS[permission] || permission
}
