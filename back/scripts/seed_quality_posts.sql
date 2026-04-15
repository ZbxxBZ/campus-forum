SET NAMES utf8mb4;

UPDATE users
SET display_name = CASE username
  WHEN 'wangchen' THEN '王晨'
  WHEN 'liyue' THEN '李玥'
  WHEN 'zhaoming' THEN '赵明'
  WHEN 'chenxi' THEN '陈曦'
  WHEN 'sunhao' THEN '孙浩'
  WHEN 'zhouyan' THEN '周妍'
  WHEN 'hejing' THEN '何静'
  WHEN 'gaofei' THEN '高飞'
  WHEN 'tanlin' THEN '谭琳'
  WHEN 'yutong' THEN '于桐'
  WHEN 'luonan' THEN '罗楠'
  WHEN 'xieyu' THEN '谢雨'
  WHEN 'pengbo' THEN '彭博'
  WHEN 'maorui' THEN '毛睿'
  WHEN 'jiangnan' THEN '江楠'
  WHEN 'guoxia' THEN '郭夏'
  WHEN 'hanyu' THEN '韩宇'
  WHEN 'weiran' THEN '魏然'
  WHEN 'qinyi' THEN '秦怡'
  WHEN 'fangzhou' THEN '方舟'
  ELSE display_name
END
WHERE username IN (
  'wangchen','liyue','zhaoming','chenxi','sunhao','zhouyan','hejing','gaofei',
  'tanlin','yutong','luonan','xieyu','pengbo','maorui','jiangnan','guoxia',
  'hanyu','weiran','qinyi','fangzhou'
);

DELETE FROM posts
WHERE title LIKE '%毒品%'
   OR title LIKE '%dupin%'
   OR title LIKE '%block_test%'
   OR title REGEXP '^\\?{5,}$';

SET @seed_time := '2026-04-12 09:00:00';
SET @rownum := 0;

INSERT INTO posts (
  title, author, category, status, risk_level, created_at, summary, content, format,
  attachments_json, tags_json, board_id, board_name, visibility, is_top, is_featured,
  gallery_captions_json, link_url, link_title, link_summary
)
SELECT
  CONCAT(
    CASE t.board_id
      WHEN 1 THEN '学习方法复盘与互助计划'
      WHEN 2 THEN '校园活动组织与时间管理实践'
      WHEN 3 THEN '校园通知解读与执行清单'
      WHEN 4 THEN '技术问题排查与协作规范'
      WHEN 5 THEN '就业准备节奏与能力提升路线'
      WHEN 6 THEN '真诚表达与边界感沟通建议'
      WHEN 7 THEN '校园文化活动记录与参与攻略'
    END,
    '（', t.display_name, '）'
  ) AS title,
  t.username AS author,
  CASE t.board_id
    WHEN 1 THEN '学习'
    WHEN 2 THEN '生活'
    WHEN 3 THEN '通知'
    WHEN 4 THEN '技术'
    WHEN 5 THEN '就业'
    WHEN 6 THEN '情感'
    WHEN 7 THEN '社团'
  END AS category,
  'published' AS status,
  'low' AS risk_level,
  DATE_FORMAT(DATE_ADD(@seed_time, INTERVAL (@rownum := @rownum + 1) * 9 MINUTE), '%Y-%m-%d %H:%i:%s') AS created_at,
  CONCAT('围绕【', b.name, '】主题整理可执行方案，覆盖准备、执行、复盘三阶段，强调可落地与可复用。') AS summary,
  CASE t.fmt_idx
    WHEN 0 THEN CONCAT(
      '这篇内容以“', b.name, '”场景为主线，围绕目标拆解、执行节奏、过程协同和复盘迭代四个环节进行展开。首先建议同学先明确阶段目标，并把目标拆分为每周可验证的小任务，避免只停留在口号层面；其次将任务按优先级排入日程，保持稳定投入，减少临时突击带来的质量波动；再次通过小组协作公开进度和问题，及时获取反馈，降低重复试错成本；最后在每周固定时间复盘，记录高效做法与常见失误，形成可复用模板。本文结合',
      t.display_name,
      '的实际参与经验补充了案例和细节，希望能帮助更多同学在学习与活动中提升效率、增强协作、持续改进。'
    )
    WHEN 1 THEN CONCAT(
      '## 核心方法', '\n',
      '1. 先定义结果：把目标写成可检查指标。', '\n',
      '2. 再排执行节奏：按周拆分任务并设置截止时间。', '\n',
      '3. 建立协作机制：同步进度、共享资料、集中答疑。', '\n',
      '4. 做复盘迭代：记录问题、分析原因、优化方案。', '\n\n',
      '在“', b.name, '”相关实践中，以上四步能够明显提升执行质量。许多同学常见的问题是目标过大、缺少节奏和反馈回路，导致中途放弃或结果不稳定。建议把每个阶段产出写成清单，例如资料收集清单、任务拆解清单、风险预案清单、复盘改进清单。通过清单化管理，可以把复杂任务变成可推进、可检查、可复盘的闭环流程。本文同时提供了由',
      t.display_name,
      '整理的示例流程，便于直接参考并在班级或社团中落地。'
    )
    WHEN 2 THEN CONCAT(
      '本文围绕“', b.name, '”主题，先给出结构化结论，再附上权威公开链接作为延伸阅读。建议阅读顺序是：先看本文提炼的关键要点，再对照链接中的原始信息进行核验，最后结合自身场景制定执行方案。内容重点包括：如何识别高优先级任务、如何安排阶段性里程碑、如何建立可持续协作机制、如何用复盘提升下一轮质量。实践中，很多问题并非能力不足，而是缺乏稳定流程和明确分工。通过“目标-执行-反馈-优化”的闭环，能够显著提高完成度与可靠性。本文由',
      t.display_name,
      '结合近期校园实践整理，适合用于课程学习、活动组织和团队协作。'
    )
    WHEN 3 THEN CONCAT(
      '本图文相册围绕“', b.name, '”主题，采用“准备阶段—执行现场—结果呈现—复盘优化”的叙事结构进行展示。第一部分重点说明前期准备，包括目标设定、人员分工和资源清单；第二部分展示执行现场的关键环节，强调节奏把控、沟通协同和突发问题处理；第三部分呈现结果数据与反馈信息，帮助读者快速理解成果质量；第四部分沉淀复盘建议，便于后续团队复用。每张图片都配有简明中文说明，突出真实场景与可迁移经验。希望通过图文结合，让大家既能看到过程细节，也能学到可直接应用的方法。'
    )
  END AS content,
  CASE t.fmt_idx
    WHEN 0 THEN 'rich_text'
    WHEN 1 THEN 'markdown'
    WHEN 2 THEN 'external_link'
    WHEN 3 THEN 'image_gallery'
  END AS format,
  CASE t.fmt_idx
    WHEN 3 THEN JSON_ARRAY(
      CONCAT('https://source.unsplash.com/1600x900/?campus,', t.board_id, ',1'),
      CONCAT('https://source.unsplash.com/1600x900/?campus,', t.board_id, ',2'),
      CONCAT('https://source.unsplash.com/1600x900/?campus,', t.board_id, ',3'),
      CONCAT('https://source.unsplash.com/1600x900/?campus,', t.board_id, ',4'),
      CONCAT('https://source.unsplash.com/1600x900/?campus,', t.board_id, ',5')
    )
    ELSE JSON_ARRAY()
  END AS attachments_json,
  JSON_ARRAY(
    CASE t.board_id
      WHEN 1 THEN '学习互助'
      WHEN 2 THEN '校园生活'
      WHEN 3 THEN '通知执行'
      WHEN 4 THEN '技术实践'
      WHEN 5 THEN '求职成长'
      WHEN 6 THEN '真诚沟通'
      WHEN 7 THEN '社团活动'
    END,
    '校园论坛',
    '经验分享'
  ) AS tags_json,
  t.board_id,
  b.name AS board_name,
  'public' AS visibility,
  CASE WHEN MOD(t.seed, 17) = 0 THEN 1 ELSE 0 END AS is_top,
  CASE WHEN MOD(t.seed, 11) = 0 THEN 1 ELSE 0 END AS is_featured,
  CASE t.fmt_idx
    WHEN 3 THEN JSON_ARRAY(
      '准备阶段：明确目标与分工',
      '执行现场：控制节奏与质量',
      '关键节点：资源协调与问题处理',
      '结果呈现：数据与案例展示',
      '复盘优化：沉淀模板与改进建议'
    )
    ELSE JSON_ARRAY()
  END AS gallery_captions_json,
  CASE t.fmt_idx
    WHEN 2 THEN CASE MOD(t.seed, 4)
      WHEN 0 THEN 'https://www.moe.gov.cn/'
      WHEN 1 THEN 'https://www.gov.cn/'
      WHEN 2 THEN 'https://www.xinhuanet.com/'
      ELSE 'https://www.people.com.cn/'
    END
    ELSE NULL
  END AS link_url,
  CASE t.fmt_idx
    WHEN 2 THEN CONCAT('延伸阅读：', b.name, '主题权威信息')
    ELSE NULL
  END AS link_title,
  CASE t.fmt_idx
    WHEN 2 THEN '提供与主题直接相关的公开来源，便于核验与深入阅读。'
    ELSE NULL
  END AS link_summary
FROM (
  SELECT
    u.id,
    u.username,
    COALESCE(NULLIF(u.display_name, ''), u.username) AS display_name,
    s.n,
    (u.id * 10 + s.n) AS seed,
    (MOD(u.id * 10 + s.n, 7) + 1) AS board_id,
    MOD(u.id * 10 + s.n, 4) AS fmt_idx
  FROM users u
  JOIN (SELECT 0 AS n UNION ALL SELECT 1 AS n) s
  WHERE u.status = 'active'
    AND u.username IN (
      'admin','teacher_li','duanzhijie','张三',
      'wangchen','liyue','zhaoming','chenxi','sunhao','zhouyan','hejing','gaofei',
      'tanlin','yutong','luonan','xieyu','pengbo','maorui','jiangnan','guoxia',
      'hanyu','weiran','qinyi','fangzhou'
    )
) t
JOIN boards b ON b.id = t.board_id
ORDER BY t.id, t.n;
