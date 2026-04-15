-- campus_forum.sql (2026-03-12 增量迁移版)
SET NAMES utf8mb4;
CREATE DATABASE IF NOT EXISTS campus_forum
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE campus_forum;

CREATE TABLE IF NOT EXISTS roles (
  role VARCHAR(32) NOT NULL PRIMARY KEY,
  role_label VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(64) NOT NULL UNIQUE,
  display_name VARCHAR(100) NOT NULL,
  email VARCHAR(128) NOT NULL UNIQUE,
  password VARCHAR(128) NOT NULL,
  role VARCHAR(32) NOT NULL,
  status VARCHAR(32) NOT NULL,
  created_at VARCHAR(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS role_permissions (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  role VARCHAR(32) NOT NULL,
  role_label VARCHAR(50) NULL,
  permission VARCHAR(100) NOT NULL,
  UNIQUE KEY uq_role_permissions_role_perm (role, permission)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS boards (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(64) NOT NULL,
  code VARCHAR(64) NOT NULL UNIQUE,
  description VARCHAR(255) NULL,
  sort_order INT NOT NULL DEFAULT 0,
  status VARCHAR(16) NOT NULL,
  post_count INT NOT NULL DEFAULT 0,
  created_at VARCHAR(30) NOT NULL,
  updated_at VARCHAR(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS posts (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  author VARCHAR(64) NOT NULL,
  status VARCHAR(32) NOT NULL,
  risk_level VARCHAR(32) NOT NULL,
  created_at VARCHAR(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS auth_tokens (
  token VARCHAR(128) NOT NULL PRIMARY KEY,
  user_id BIGINT NOT NULL,
  last_seen VARCHAR(30) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE IF NOT EXISTS post_comment (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  post_id BIGINT NOT NULL,
  parent_id BIGINT NULL,
  user_id BIGINT NOT NULL,
  content TEXT NOT NULL,
  created_at VARCHAR(30) NOT NULL,
  updated_at VARCHAR(30) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS post_like (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  post_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at VARCHAR(30) NOT NULL,
  UNIQUE KEY uq_post_like (post_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS post_favorite (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  post_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at VARCHAR(30) NOT NULL,
  UNIQUE KEY uq_post_favorite (post_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS topic (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(128) NOT NULL,
  description VARCHAR(500) NULL,
  created_by BIGINT NOT NULL,
  created_at VARCHAR(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS topic_option (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  topic_id BIGINT NOT NULL,
  text VARCHAR(128) NOT NULL,
  vote_count INT NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS topic_vote (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  topic_id BIGINT NOT NULL,
  option_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at VARCHAR(30) NOT NULL,
  UNIQUE KEY uq_topic_vote (topic_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS user_profile (
  user_id BIGINT NOT NULL PRIMARY KEY,
  avatar VARCHAR(255) NULL,
  bio VARCHAR(500) NULL,
  updated_at VARCHAR(30) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS user_follow (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  target_user_id BIGINT NOT NULL,
  created_at VARCHAR(30) NOT NULL,
  UNIQUE KEY uq_user_follow (user_id, target_user_id),
  KEY idx_follow_user (user_id, created_at),
  KEY idx_follow_target (target_user_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS audit_log (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  action VARCHAR(64) NOT NULL,
  action_label VARCHAR(64) NOT NULL,
  post_id BIGINT NOT NULL,
  post_title VARCHAR(255) NULL,
  operator_id BIGINT NOT NULL,
  operator VARCHAR(64) NOT NULL,
  operator_role VARCHAR(32) NOT NULL,
  detail VARCHAR(500) NULL,
  created_at VARCHAR(30) NOT NULL,
  KEY idx_audit_created_at (created_at),
  KEY idx_audit_post_id (post_id),
  KEY idx_audit_operator_id (operator_id),
  KEY idx_audit_action (action)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- posts 增量字段
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'posts' AND column_name = 'summary'),'SELECT 1','ALTER TABLE posts ADD COLUMN summary VARCHAR(255) NULL'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'posts' AND column_name = 'content'),'SELECT 1','ALTER TABLE posts ADD COLUMN content TEXT NULL'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'posts' AND column_name = 'format'),'SELECT 1','ALTER TABLE posts ADD COLUMN format VARCHAR(32) NULL'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'posts' AND column_name = 'attachments_json'),'SELECT 1','ALTER TABLE posts ADD COLUMN attachments_json TEXT NULL'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'posts' AND column_name = 'tags_json'),'SELECT 1','ALTER TABLE posts ADD COLUMN tags_json TEXT NULL'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'posts' AND column_name = 'gallery_captions_json'),'SELECT 1','ALTER TABLE posts ADD COLUMN gallery_captions_json TEXT NULL'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'posts' AND column_name = 'link_url'),'SELECT 1','ALTER TABLE posts ADD COLUMN link_url VARCHAR(1024) NULL'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'posts' AND column_name = 'link_title'),'SELECT 1','ALTER TABLE posts ADD COLUMN link_title VARCHAR(255) NULL'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'posts' AND column_name = 'link_summary'),'SELECT 1','ALTER TABLE posts ADD COLUMN link_summary VARCHAR(500) NULL'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'posts' AND column_name = 'board_id'),'SELECT 1','ALTER TABLE posts ADD COLUMN board_id BIGINT NULL'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'posts' AND column_name = 'board_name'),'SELECT 1','ALTER TABLE posts ADD COLUMN board_name VARCHAR(64) NULL'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'posts' AND column_name = 'category'),'SELECT 1','ALTER TABLE posts ADD COLUMN category VARCHAR(64) NULL'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'posts' AND column_name = 'visibility'),'SELECT 1','ALTER TABLE posts ADD COLUMN visibility VARCHAR(16) NULL'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'posts' AND column_name = 'is_top'),'SELECT 1','ALTER TABLE posts ADD COLUMN is_top TINYINT(1) NOT NULL DEFAULT 0'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'posts' AND column_name = 'is_featured'),'SELECT 1','ALTER TABLE posts ADD COLUMN is_featured TINYINT(1) NOT NULL DEFAULT 0'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'posts' AND column_name = 'updated_at'),'SELECT 1','ALTER TABLE posts ADD COLUMN updated_at VARCHAR(30) NULL'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(
  EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'posts' AND column_name = 'category'),
  'ALTER TABLE posts MODIFY COLUMN category VARCHAR(64) NULL DEFAULT NULL',
  'SELECT 1'
));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 索引
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'posts' AND index_name = 'idx_posts_board'),'SELECT 1','CREATE INDEX idx_posts_board ON posts(board_id)'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'posts' AND index_name = 'idx_posts_filter'),'SELECT 1','CREATE INDEX idx_posts_filter ON posts(status, format, visibility)'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'boards' AND index_name = 'idx_boards_status_sort'),'SELECT 1','CREATE INDEX idx_boards_status_sort ON boards(status, sort_order)'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'posts' AND index_name = 'idx_posts_author_created'),'SELECT 1','CREATE INDEX idx_posts_author_created ON posts(author, created_at)'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'post_comment' AND index_name = 'idx_post_comment_user_created'),'SELECT 1','CREATE INDEX idx_post_comment_user_created ON post_comment(user_id, created_at)'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'post_like' AND index_name = 'idx_post_like_user_created'),'SELECT 1','CREATE INDEX idx_post_like_user_created ON post_like(user_id, created_at)'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(EXISTS(SELECT 1 FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'post_favorite' AND index_name = 'idx_post_favorite_user_created'),'SELECT 1','CREATE INDEX idx_post_favorite_user_created ON post_favorite(user_id, created_at)'));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 兼容历史约束：确保 posts.status 支持 hidden（下架）
SET @sql = (SELECT IF(
  EXISTS(
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE()
      AND table_name = 'posts'
      AND constraint_name = 'chk_posts_status'
      AND constraint_type = 'CHECK'
  ),
  'ALTER TABLE posts DROP CHECK chk_posts_status',
  'SELECT 1'
));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql = (SELECT IF(
  EXISTS(
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE()
      AND table_name = 'posts'
      AND constraint_name = 'chk_posts_status'
      AND constraint_type = 'CHECK'
  ),
  'SELECT 1',
  'ALTER TABLE posts ADD CONSTRAINT chk_posts_status CHECK (status IN (''draft'',''pending'',''published'',''rejected'',''hidden''))'
));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 初始化数据
INSERT INTO roles (role, role_label) VALUES
('super_admin', '超级管理员'),
('admin', '管理员'),
('teacher', '教师'),
('student', '学生')
ON DUPLICATE KEY UPDATE role_label = VALUES(role_label);

INSERT INTO users (id, username, display_name, email, password, role, status, created_at) VALUES
(1, 'admin', '系统管理员', 'admin@campus.edu', 'Admin123!', 'super_admin', 'active', '2026-03-11 00:00:00'),
(2, 'teacher_li', '李老师', 'teacher_li@campus.edu', 'Teacher123!', 'teacher', 'active', '2026-03-11 01:30:00')
ON DUPLICATE KEY UPDATE
display_name = VALUES(display_name),
email = VALUES(email),
password = VALUES(password),
role = VALUES(role),
status = VALUES(status);

INSERT INTO role_permissions (role, role_label, permission) VALUES
('super_admin', '超级管理员', 'dashboard:read'),
('super_admin', '超级管理员', 'user:read'),
('super_admin', '超级管理员', 'user:update'),
('super_admin', '超级管理员', 'post:read'),
('super_admin', '超级管理员', 'post:create'),
('super_admin', '超级管理员', 'post:update'),
('super_admin', '超级管理员', 'review:read'),
('super_admin', '超级管理员', 'role:read'),
('super_admin', '超级管理员', 'role:update'),
('super_admin', '超级管理员', 'board:read'),
('super_admin', '超级管理员', 'board:update'),
('super_admin', '超级管理员', 'topic:create'),
('super_admin', '超级管理员', 'topic:read'),
('super_admin', '超级管理员', 'topic:vote'),
('super_admin', '超级管理员', 'auditlog:read'),
('admin', '管理员', 'user:read'),
('admin', '管理员', 'user:update'),
('admin', '管理员', 'post:read'),
('admin', '管理员', 'post:create'),
('admin', '管理员', 'post:update'),
('admin', '管理员', 'review:read'),
('admin', '管理员', 'role:read'),
('admin', '管理员', 'role:update'),
('admin', '管理员', 'board:read'),
('admin', '管理员', 'board:update'),
('admin', '管理员', 'topic:create'),
('admin', '管理员', 'topic:read'),
('admin', '管理员', 'topic:vote'),
('teacher', '教师', 'post:create'),
('teacher', '教师', 'post:read'),
('teacher', '教师', 'post:update'),
('teacher', '教师', 'review:read'),
('teacher', '教师', 'board:read'),
('teacher', '教师', 'topic:create'),
('teacher', '教师', 'topic:read'),
('teacher', '教师', 'topic:vote'),
('student', '学生', 'post:create'),
('student', '学生', 'topic:read'),
('student', '学生', 'topic:vote')
ON DUPLICATE KEY UPDATE role_label = VALUES(role_label);

INSERT INTO boards (id, name, code, description, sort_order, status, post_count, created_at, updated_at) VALUES
(1, '学习交流', 'study', '课程学习、资料分享', 10, 'enabled', 128, '2026-03-10 08:00:00', '2026-03-10 08:00:00'),
(2, '校园生活', 'campus-life', '校园生活与活动讨论', 20, 'enabled', 64, '2026-03-10 08:00:00', '2026-03-10 08:00:00'),
(3, '通知公告', 'notice', '校内通知与公告', 30, 'enabled', 8, '2026-03-10 08:00:00', '2026-03-10 08:00:00')
ON DUPLICATE KEY UPDATE
name = VALUES(name),
description = VALUES(description),
sort_order = VALUES(sort_order),
status = VALUES(status),
post_count = VALUES(post_count),
updated_at = VALUES(updated_at);

INSERT INTO posts (
  id, title, summary, content, format, attachments_json, tags_json, board_id, board_name, category, author,
  visibility, status, risk_level, is_top, is_featured, created_at, updated_at
) VALUES
(1001, '期末复习资料共享帖', '汇总资料下载链接', '<p>...</p>', 'rich_text', '[]', '["期末","资料共享"]', 1, '学习交流', '学习交流', 'teacher_li', 'public', 'published', 'low', 1, 1, '2026-03-10 08:00:00', '2026-03-10 08:00:00'),
(1002, '二手教材交流', '考后教材流转帖', '# 欢迎留言交换教材', 'markdown', '[]', '["教材","交流"]', 2, '校园生活', '校园生活', 'zhangsan', 'campus', 'pending', 'medium', 0, 0, '2026-03-10 09:00:00', '2026-03-10 09:00:00')
ON DUPLICATE KEY UPDATE
summary = VALUES(summary),
content = VALUES(content),
format = VALUES(format),
attachments_json = VALUES(attachments_json),
tags_json = VALUES(tags_json),
board_id = VALUES(board_id),
board_name = VALUES(board_name),
category = VALUES(category),
visibility = VALUES(visibility),
status = VALUES(status),
risk_level = VALUES(risk_level),
is_top = VALUES(is_top),
is_featured = VALUES(is_featured),
updated_at = VALUES(updated_at);
