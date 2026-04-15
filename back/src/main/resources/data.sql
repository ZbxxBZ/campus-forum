INSERT INTO users (id, username, display_name, email, password, role, status, created_at)
SELECT 1, 'admin', '系统管理员', 'admin@campus.edu', 'Admin123!', 'super_admin', 'active', '2026-03-11 00:00:00'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE id = 1);

INSERT INTO users (id, username, display_name, email, password, role, status, created_at)
SELECT 2, 'teacher_li', '李老师', 'teacher_li@campus.edu', 'Teacher123!', 'teacher', 'active', '2026-03-11 01:30:00'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE id = 2);

INSERT INTO roles (role, role_label)
SELECT 'super_admin', '超级管理员'
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE role = 'super_admin');
INSERT INTO roles (role, role_label)
SELECT 'teacher', '教师'
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE role = 'teacher');
INSERT INTO roles (role, role_label)
SELECT 'student', '学生'
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE role = 'student');

INSERT INTO role_permissions (role, role_label, permission)
SELECT 'super_admin', '超级管理员', 'dashboard:read'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'super_admin' AND permission = 'dashboard:read');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'super_admin', '超级管理员', 'user:read'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'super_admin' AND permission = 'user:read');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'super_admin', '超级管理员', 'user:update'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'super_admin' AND permission = 'user:update');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'super_admin', '超级管理员', 'post:read'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'super_admin' AND permission = 'post:read');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'super_admin', '超级管理员', 'post:create'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'super_admin' AND permission = 'post:create');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'super_admin', '超级管理员', 'post:update'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'super_admin' AND permission = 'post:update');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'super_admin', '超级管理员', 'review:read'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'super_admin' AND permission = 'review:read');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'super_admin', '超级管理员', 'role:read'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'super_admin' AND permission = 'role:read');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'super_admin', '超级管理员', 'role:update'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'super_admin' AND permission = 'role:update');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'super_admin', '超级管理员', 'board:read'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'super_admin' AND permission = 'board:read');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'super_admin', '超级管理员', 'board:update'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'super_admin' AND permission = 'board:update');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'super_admin', '超级管理员', 'topic:create'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'super_admin' AND permission = 'topic:create');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'super_admin', '超级管理员', 'topic:read'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'super_admin' AND permission = 'topic:read');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'super_admin', '超级管理员', 'topic:vote'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'super_admin' AND permission = 'topic:vote');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'super_admin', '超级管理员', 'auditlog:read'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'super_admin' AND permission = 'auditlog:read');

INSERT INTO role_permissions (role, role_label, permission)
SELECT 'teacher', '教师', 'post:create'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'teacher' AND permission = 'post:create');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'teacher', '教师', 'post:read'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'teacher' AND permission = 'post:read');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'teacher', '教师', 'post:update'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'teacher' AND permission = 'post:update');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'teacher', '教师', 'review:read'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'teacher' AND permission = 'review:read');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'teacher', '教师', 'board:read'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'teacher' AND permission = 'board:read');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'teacher', '教师', 'topic:create'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'teacher' AND permission = 'topic:create');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'teacher', '教师', 'topic:read'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'teacher' AND permission = 'topic:read');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'teacher', '教师', 'topic:vote'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'teacher' AND permission = 'topic:vote');

INSERT INTO role_permissions (role, role_label, permission)
SELECT 'student', '学生', 'post:create'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'student' AND permission = 'post:create');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'student', '学生', 'topic:read'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'student' AND permission = 'topic:read');
INSERT INTO role_permissions (role, role_label, permission)
SELECT 'student', '学生', 'topic:vote'
WHERE NOT EXISTS (SELECT 1 FROM role_permissions WHERE role = 'student' AND permission = 'topic:vote');

INSERT INTO boards (id, name, code, description, sort_order, status, post_count, created_at, updated_at)
SELECT 1, '学习交流', 'study', '课程学习、资料分享', 10, 'enabled', 128, '2026-03-10 08:00:00', '2026-03-10 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM boards WHERE id = 1);
INSERT INTO boards (id, name, code, description, sort_order, status, post_count, created_at, updated_at)
SELECT 2, '校园生活', 'campus-life', '校园生活与活动讨论', 20, 'enabled', 64, '2026-03-10 08:00:00', '2026-03-10 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM boards WHERE id = 2);
INSERT INTO boards (id, name, code, description, sort_order, status, post_count, created_at, updated_at)
SELECT 3, '通知公告', 'notice', '校内通知与公告', 30, 'enabled', 8, '2026-03-10 08:00:00', '2026-03-10 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM boards WHERE id = 3);

INSERT INTO posts (
    id, title, summary, content, format, attachments_json, tags_json, board_id, board_name, category, author,
    visibility, status, risk_level, is_top, is_featured, created_at, updated_at
)
SELECT
    1001, '期末复习资料共享帖', '汇总资料下载链接', '<p>...</p>', 'rich_text', '[]', '["期末","资料共享"]', 1, '学习交流', '学习交流', 'teacher_li',
    'public', 'published', 'low', 1, 1, '2026-03-10 08:00:00', '2026-03-10 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM posts WHERE id = 1001);

INSERT INTO posts (
    id, title, summary, content, format, attachments_json, tags_json, board_id, board_name, category, author,
    visibility, status, risk_level, is_top, is_featured, created_at, updated_at
)
SELECT
    1002, '二手教材交流', '考后教材流转帖', '# 欢迎留言交换教材', 'markdown', '[]', '["教材","交流"]', 2, '校园生活', '校园生活', 'zhangsan',
    'campus', 'pending', 'medium', 0, 0, '2026-03-10 09:00:00', '2026-03-10 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM posts WHERE id = 1002);
