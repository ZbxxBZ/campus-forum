CREATE TABLE IF NOT EXISTS users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(64) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    email VARCHAR(128) NOT NULL UNIQUE,
    password VARCHAR(128) NOT NULL,
    role VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL,
    created_at VARCHAR(30) NOT NULL
);

CREATE TABLE IF NOT EXISTS auth_tokens (
    token VARCHAR(128) PRIMARY KEY,
    user_id BIGINT NOT NULL,
    last_seen VARCHAR(30) NOT NULL
);

CREATE TABLE IF NOT EXISTS role_permissions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    role VARCHAR(32) NOT NULL,
    role_label VARCHAR(50),
    permission VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS roles (
    role VARCHAR(32) PRIMARY KEY,
    role_label VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS posts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    summary VARCHAR(255),
    content TEXT NOT NULL,
    format VARCHAR(32) NOT NULL,
    attachments_json TEXT,
    tags_json TEXT,
    gallery_captions_json TEXT,
    link_url VARCHAR(1024),
    link_title VARCHAR(255),
    link_summary VARCHAR(500),
    board_id BIGINT NOT NULL,
    board_name VARCHAR(64) NOT NULL,
    category VARCHAR(64),
    author VARCHAR(64) NOT NULL,
    visibility VARCHAR(16) NOT NULL,
    status VARCHAR(32) NOT NULL,
    risk_level VARCHAR(32) NOT NULL,
    is_top TINYINT(1) NOT NULL DEFAULT 0,
    is_featured TINYINT(1) NOT NULL DEFAULT 0,
    created_at VARCHAR(30) NOT NULL,
    updated_at VARCHAR(30) NOT NULL
);

CREATE TABLE IF NOT EXISTS boards (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(64) NOT NULL,
    code VARCHAR(64) NOT NULL UNIQUE,
    description VARCHAR(255),
    sort_order INT NOT NULL DEFAULT 0,
    status VARCHAR(16) NOT NULL,
    post_count INT NOT NULL DEFAULT 0,
    created_at VARCHAR(30) NOT NULL,
    updated_at VARCHAR(30) NOT NULL
);

CREATE TABLE IF NOT EXISTS post_comment (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    post_id BIGINT NOT NULL,
    parent_id BIGINT,
    user_id BIGINT NOT NULL,
    content TEXT NOT NULL,
    created_at VARCHAR(30) NOT NULL,
    updated_at VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS post_like (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    post_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    created_at VARCHAR(30) NOT NULL,
    CONSTRAINT uq_post_like UNIQUE (post_id, user_id)
);

CREATE TABLE IF NOT EXISTS post_favorite (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    post_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    created_at VARCHAR(30) NOT NULL,
    CONSTRAINT uq_post_favorite UNIQUE (post_id, user_id)
);

CREATE TABLE IF NOT EXISTS topic (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(128) NOT NULL,
    description VARCHAR(500),
    created_by BIGINT NOT NULL,
    created_at VARCHAR(30) NOT NULL
);

CREATE TABLE IF NOT EXISTS topic_option (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    topic_id BIGINT NOT NULL,
    text VARCHAR(128) NOT NULL,
    vote_count INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS topic_vote (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    topic_id BIGINT NOT NULL,
    option_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    created_at VARCHAR(30) NOT NULL,
    CONSTRAINT uq_topic_vote UNIQUE (topic_id, user_id)
);

CREATE TABLE IF NOT EXISTS user_profile (
    user_id BIGINT PRIMARY KEY,
    avatar VARCHAR(255),
    bio VARCHAR(500),
    updated_at VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS user_follow (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    target_user_id BIGINT NOT NULL,
    created_at VARCHAR(30) NOT NULL,
    CONSTRAINT uq_user_follow UNIQUE (user_id, target_user_id)
);

CREATE TABLE IF NOT EXISTS audit_log (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    action VARCHAR(64) NOT NULL,
    action_label VARCHAR(64) NOT NULL,
    post_id BIGINT NOT NULL,
    post_title VARCHAR(255),
    operator_id BIGINT NOT NULL,
    operator VARCHAR(64) NOT NULL,
    operator_role VARCHAR(32) NOT NULL,
    detail VARCHAR(500),
    created_at VARCHAR(30) NOT NULL
);
