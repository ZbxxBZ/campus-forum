import { ROLE_LABELS, ROLE_PERMISSIONS } from '../constants/permissions'

const DB_KEY = 'campus_forum_mock_db_v3'

const initialDb = {
  users: [
    {
      id: 1,
      username: 'admin',
      password: 'Admin123!',
      email: 'admin@campus.edu',
      displayName: '系统管理员',
      role: 'super_admin',
      status: 'active',
      createdAt: '2026-03-11T00:00:00.000Z'
    },
    {
      id: 2,
      username: 'teacher_li',
      password: 'Teacher123!',
      email: 'li@campus.edu',
      displayName: '李老师',
      role: 'teacher',
      status: 'active',
      createdAt: '2026-03-11T00:10:00.000Z'
    }
  ],
  boards: [
    {
      id: 1,
      name: '学习交流',
      code: 'study',
      description: '课程学习、资料分享、考试经验交流',
      sortOrder: 10,
      status: 'enabled',
      postCount: 128,
      createdAt: '2026-03-10T08:00:00.000Z'
    },
    {
      id: 2,
      name: '校园生活',
      code: 'campus-life',
      description: '社团活动、校园资讯、生活服务',
      sortOrder: 20,
      status: 'enabled',
      postCount: 93,
      createdAt: '2026-03-10T08:00:00.000Z'
    },
    {
      id: 3,
      name: '失物招领',
      code: 'lost-found',
      description: '失物招领与寻物启事',
      sortOrder: 30,
      status: 'disabled',
      postCount: 21,
      createdAt: '2026-03-10T08:00:00.000Z'
    }
  ],
  posts: [
    {
      id: 1001,
      title: '期末复习资料共享帖',
      summary: '汇总高数、英语、计组复习资料下载链接。',
      content: '<p>欢迎补充你们班的重点整理。</p>',
      format: 'rich_text',
      attachments: [],
      galleryCaptions: [],
      linkUrl: '',
      linkSummary: '',
      tags: ['期末', '资料共享'],
      boardId: 1,
      boardName: '学习交流',
      authorId: 2,
      author: 'teacher_li',
      status: 'published',
      riskLevel: 'low',
      isTop: true,
      isFeatured: true,
      createdAt: '2026-03-10T08:00:00.000Z',
      updatedAt: '2026-03-10T08:00:00.000Z'
    },
    {
      id: 1002,
      title: '二手教材交易注意事项',
      summary: '提醒大家线下交易安全和价格参考。',
      content: '# 交易建议\n\n请在校内公共区域交易。',
      format: 'markdown',
      attachments: [],
      galleryCaptions: [],
      linkUrl: '',
      linkSummary: '',
      tags: ['教材', '交易'],
      boardId: 2,
      boardName: '校园生活',
      authorId: null,
      author: 'student_zhang',
      status: 'pending',
      riskLevel: 'medium',
      isTop: false,
      isFeatured: false,
      createdAt: '2026-03-10T09:30:00.000Z',
      updatedAt: '2026-03-10T09:30:00.000Z'
    },
    {
      id: 1003,
      title: '疑似广告灌水帖',
      summary: '可疑外链刷屏，已拦截',
      content: 'http://unknown-site.test',
      format: 'external_link',
      attachments: [],
      galleryCaptions: [],
      linkUrl: 'http://unknown-site.test',
      linkSummary: '疑似广告链接',
      tags: ['灌水'],
      boardId: 2,
      boardName: '校园生活',
      authorId: null,
      author: 'unknown',
      status: 'rejected',
      riskLevel: 'high',
      isTop: false,
      isFeatured: false,
      createdAt: '2026-03-10T10:15:00.000Z',
      updatedAt: '2026-03-10T10:20:00.000Z'
    }
  ],
  rolePermissions: {
    ...ROLE_PERMISSIONS
  },
  auditLogs: [],
  follows: [],
  nextAuditLogId: 1,
  nextUserId: 3,
  nextBoardId: 4,
  nextPostId: 1004
}

function readDb() {
  const raw = localStorage.getItem(DB_KEY)
  if (!raw) {
    localStorage.setItem(DB_KEY, JSON.stringify(initialDb))
    return structuredClone(initialDb)
  }
  return JSON.parse(raw)
}

function writeDb(db) {
  localStorage.setItem(DB_KEY, JSON.stringify(db))
}

function delay(data) {
  return new Promise((resolve) => setTimeout(() => resolve(data), 120))
}

function issueToken(userId) {
  return btoa(`uid:${userId}:${Date.now()}`)
}

function decodeToken(token) {
  try {
    const value = atob(token)
    const userId = Number(value.split(':')[1])
    return Number.isNaN(userId) ? null : userId
  } catch {
    return null
  }
}

function sanitizeUser(user) {
  const { password, ...rest } = user
  return rest
}

function normalizeTags(tags) {
  if (Array.isArray(tags)) return tags.filter(Boolean).map((item) => String(item).trim())
  if (typeof tags === 'string') {
    return tags
      .split(/[，,]/)
      .map((item) => item.trim())
      .filter(Boolean)
  }
  return []
}

function findBoard(db, boardId) {
  return db.boards.find((item) => item.id === Number(boardId))
}

function ensureInteractionDb(db) {
  if (!db.postInteractions) db.postInteractions = {}
  if (!db.postComments) db.postComments = []
  if (!db.topics) db.topics = []
  if (!db.nextCommentId) db.nextCommentId = 1
  if (!db.nextTopicId) db.nextTopicId = 1
  if (!db.nextTopicOptionId) db.nextTopicOptionId = 1
}

function ensureAuditLogDb(db) {
  if (!db.auditLogs) db.auditLogs = []
  if (!db.nextAuditLogId) db.nextAuditLogId = 1
}

function ensureFollowDb(db) {
  if (!db.follows) db.follows = []
}

function appendAuditLog(db, payload) {
  ensureAuditLogDb(db)
  const log = {
    id: db.nextAuditLogId++,
    action: payload.action || 'unknown',
    actionLabel: payload.actionLabel || payload.action || '未知操作',
    postId: Number(payload.postId) || null,
    postTitle: payload.postTitle || '',
    operatorId: payload.operatorId || null,
    operator: payload.operator || 'system',
    operatorRole: payload.operatorRole || 'system',
    detail: payload.detail || '',
    createdAt: new Date().toISOString()
  }
  db.auditLogs.unshift(log)
}

function getCurrentUser(db) {
  const token = localStorage.getItem('campus_forum_token')
  const userId = decodeToken(token || '')
  if (!userId) return null
  return db.users.find((item) => item.id === userId) || null
}

export async function mockRegister(payload) {
  const db = readDb()
  const exists = db.users.some((u) => u.username === payload.username || u.email === payload.email)
  if (exists) {
    throw new Error('用户名或邮箱已存在')
  }

  const user = {
    id: db.nextUserId++,
    username: payload.username,
    password: payload.password,
    email: payload.email,
    displayName: payload.displayName,
    role: 'student',
    status: 'active',
    createdAt: new Date().toISOString()
  }

  db.users.push(user)
  writeDb(db)
  return delay({ user: sanitizeUser(user) })
}

export async function mockLogin(payload) {
  const db = readDb()
  const user = db.users.find((u) => u.username === payload.username)
  if (!user || user.password !== payload.password) {
    throw new Error('用户名或密码错误')
  }
  if (user.status !== 'active') {
    throw new Error('账号已被禁用')
  }

  return delay({
    token: issueToken(user.id),
    user: sanitizeUser(user),
    permissions: db.rolePermissions[user.role] || []
  })
}

export async function mockGetProfile(token) {
  const db = readDb()
  const userId = decodeToken(token)
  const user = db.users.find((item) => item.id === userId)
  if (!user) {
    throw new Error('登录态无效，请重新登录')
  }

  return delay({
    user: sanitizeUser(user),
    permissions: db.rolePermissions[user.role] || []
  })
}

export async function mockListUsers(query = {}) {
  const db = readDb()
  const keyword = (query.keyword || '').toLowerCase()
  const role = query.role || ''
  const status = query.status || ''

  const filtered = db.users.filter((user) => {
    const matchedKeyword =
      !keyword ||
      user.username.toLowerCase().includes(keyword) ||
      user.email.toLowerCase().includes(keyword) ||
      user.displayName.toLowerCase().includes(keyword)
    const matchedRole = !role || user.role === role
    const matchedStatus = !status || user.status === status
    return matchedKeyword && matchedRole && matchedStatus
  })

  return delay({ list: filtered.map(sanitizeUser), total: filtered.length })
}

export async function mockUpdateUserRole(userId, role) {
  const db = readDb()
  const user = db.users.find((item) => item.id === Number(userId))
  if (!user) {
    throw new Error('用户不存在')
  }
  if (!ROLE_LABELS[role]) {
    throw new Error('角色非法')
  }

  user.role = role
  writeDb(db)
  return delay({ user: sanitizeUser(user) })
}

export async function mockUpdateUserStatus(userId, status) {
  const db = readDb()
  const user = db.users.find((item) => item.id === Number(userId))
  if (!user) {
    throw new Error('用户不存在')
  }
  if (!['active', 'disabled'].includes(status)) {
    throw new Error('状态非法')
  }

  user.status = status
  writeDb(db)
  return delay({ user: sanitizeUser(user) })
}

export async function mockListRoles() {
  const db = readDb()
  const list = Object.entries(db.rolePermissions).map(([role, permissions]) => ({
    role,
    roleLabel: ROLE_LABELS[role] || role,
    permissions
  }))

  return delay({ list })
}

export async function mockUpdateRolePermissions(role, permissions) {
  const db = readDb()
  if (!db.rolePermissions[role]) {
    throw new Error('角色不存在')
  }

  db.rolePermissions[role] = [...new Set(permissions)]
  writeDb(db)
  return delay({ role, permissions: db.rolePermissions[role] })
}

export async function mockDashboardStats() {
  const db = readDb()
  const pendingReviews = db.posts.filter((item) => item.status === 'pending').length
  const rejectedToday = db.posts.filter((item) => item.status === 'rejected').length

  return delay({
    totalUsers: db.users.length,
    totalPosts: db.posts.length,
    pendingReviews,
    rejectedToday,
    peakQps: 1260,
    onlineUsers: 438
  })
}

export async function mockListBoards(query = {}) {
  const db = readDb()
  const keyword = (query.keyword || '').toLowerCase()
  const status = query.status || ''

  const list = db.boards
    .filter((item) => {
      const matchedKeyword =
        !keyword ||
        item.name.toLowerCase().includes(keyword) ||
        item.code.toLowerCase().includes(keyword)
      const matchedStatus = !status || item.status === status
      return matchedKeyword && matchedStatus
    })
    .sort((a, b) => a.sortOrder - b.sortOrder)

  return delay({ list, total: list.length })
}

export async function mockCreateBoard(payload) {
  const db = readDb()
  const codeExists = db.boards.some((item) => item.code === payload.code)
  if (codeExists) {
    throw new Error('板块编码已存在')
  }

  const board = {
    id: db.nextBoardId++,
    name: payload.name,
    code: payload.code,
    description: payload.description || '',
    sortOrder: Number(payload.sortOrder || 0),
    status: payload.status || 'enabled',
    postCount: 0,
    createdAt: new Date().toISOString()
  }

  db.boards.push(board)
  writeDb(db)
  return delay({ board })
}

export async function mockUpdateBoard(boardId, payload) {
  const db = readDb()
  const board = db.boards.find((item) => item.id === Number(boardId))
  if (!board) {
    throw new Error('板块不存在')
  }

  if (payload.code && payload.code !== board.code) {
    const codeExists = db.boards.some((item) => item.code === payload.code)
    if (codeExists) {
      throw new Error('板块编码已存在')
    }
  }

  Object.assign(board, {
    name: payload.name ?? board.name,
    code: payload.code ?? board.code,
    description: payload.description ?? board.description,
    sortOrder: payload.sortOrder !== undefined ? Number(payload.sortOrder) : board.sortOrder,
    status: payload.status ?? board.status
  })

  db.posts.forEach((post) => {
    if (post.boardId === board.id) {
      post.boardName = board.name
    }
  })

  writeDb(db)
  return delay({ board })
}

export async function mockListPosts(query = {}) {
  const db = readDb()
  const status = query.status || ''
  const keyword = (query.keyword || '').toLowerCase()
  const boardId = query.boardId ? Number(query.boardId) : null
  const format = query.format || ''
  const visibility = query.visibility || ''

  const list = db.posts.filter((post) => {
    const matchedStatus = !status || post.status === status
    const matchedKeyword =
      !keyword ||
      post.title.toLowerCase().includes(keyword) ||
      (post.summary || '').toLowerCase().includes(keyword)
    const matchedBoard = !boardId || post.boardId === boardId
    const matchedFormat = !format || post.format === format
    const matchedVisibility = !visibility || post.visibility === visibility
    return matchedStatus && matchedKeyword && matchedBoard && matchedFormat && matchedVisibility
  }).map((post) => {
    const matchedUser = db.users.find((item) => item.username === post.author)
    return {
      ...post,
      authorId: post.authorId ?? matchedUser?.id ?? null
    }
  })

  return delay({ list, total: list.length })
}

export async function mockCreatePost(payload) {
  const db = readDb()
  const board = findBoard(db, payload.boardId)
  if (!board) {
    throw new Error('板块不存在')
  }
  const currentUser = getCurrentUser(db)

  const now = new Date().toISOString()
  const post = {
    id: db.nextPostId++,
    title: payload.title,
    summary: payload.summary || '',
    content: payload.content || '',
    format: payload.format || 'rich_text',
    attachments: Array.isArray(payload.attachments) ? payload.attachments : [],
    galleryCaptions: Array.isArray(payload.galleryCaptions) ? payload.galleryCaptions : [],
    linkUrl: payload.linkUrl || '',
    linkSummary: payload.linkSummary || '',
    pollQuestion: payload.pollQuestion || '',
    pollOptions: Array.isArray(payload.pollOptions) ? payload.pollOptions : [],
    pollMultiple: Boolean(payload.pollMultiple),
    pollEndDate: payload.pollEndDate || '',
    tags: normalizeTags(payload.tags),
    boardId: board.id,
    boardName: board.name,
    authorId: currentUser?.id || null,
    author: currentUser?.username || payload.author || 'unknown',
    status: payload.status || 'pending',
    riskLevel: 'low',
    isTop: Boolean(payload.isTop),
    isFeatured: Boolean(payload.isFeatured),
    createdAt: now,
    updatedAt: now
  }

  db.posts.unshift(post)
  board.postCount += 1
  writeDb(db)
  return delay({ post })
}

export async function mockUpdatePost(postId, payload) {
  const db = readDb()
  ensureAuditLogDb(db)
  const post = db.posts.find((item) => item.id === Number(postId))
  if (!post) {
    throw new Error('帖子不存在')
  }
  const currentUser = getCurrentUser(db)
  const oldStatus = post.status

  let board = null
  if (payload.boardId !== undefined) {
    board = findBoard(db, payload.boardId)
    if (!board) {
      throw new Error('板块不存在')
    }
  }

  post.title = payload.title ?? post.title
  post.summary = payload.summary ?? post.summary
  post.content = payload.content ?? post.content
  post.format = payload.format ?? post.format
  post.status = payload.status ?? post.status
  post.isTop = payload.isTop !== undefined ? Boolean(payload.isTop) : post.isTop
  post.isFeatured = payload.isFeatured !== undefined ? Boolean(payload.isFeatured) : post.isFeatured
  post.tags = payload.tags !== undefined ? normalizeTags(payload.tags) : post.tags
  post.attachments = payload.attachments !== undefined ? payload.attachments : post.attachments
  post.galleryCaptions = payload.galleryCaptions !== undefined ? payload.galleryCaptions : post.galleryCaptions
  post.linkUrl = payload.linkUrl !== undefined ? payload.linkUrl : post.linkUrl
  post.linkSummary = payload.linkSummary !== undefined ? payload.linkSummary : post.linkSummary
  post.pollQuestion = payload.pollQuestion !== undefined ? payload.pollQuestion : post.pollQuestion
  post.pollOptions = payload.pollOptions !== undefined ? payload.pollOptions : post.pollOptions
  post.pollMultiple = payload.pollMultiple !== undefined ? Boolean(payload.pollMultiple) : post.pollMultiple
  post.pollEndDate = payload.pollEndDate !== undefined ? payload.pollEndDate : post.pollEndDate

  if (board) {
    post.boardId = board.id
    post.boardName = board.name
  }

  post.updatedAt = new Date().toISOString()

  if (payload.status !== undefined && payload.status !== oldStatus) {
    let action = 'post_status_change'
    let actionLabel = '帖子状态变更'
    if (oldStatus === 'published' && payload.status === 'hidden') {
      action = 'post_hide'
      actionLabel = '帖子下架'
    } else if (oldStatus === 'hidden' && payload.status === 'published') {
      action = 'post_publish'
      actionLabel = '帖子上架'
    }

    appendAuditLog(db, {
      action,
      actionLabel,
      postId: post.id,
      postTitle: post.title,
      operatorId: currentUser?.id || null,
      operator: currentUser?.username || 'system',
      operatorRole: currentUser?.role || 'system',
      detail: `status: ${oldStatus} -> ${payload.status}`
    })
  }

  writeDb(db)
  return delay({ post })
}

export async function mockGetPostDetail(postId) {
  const db = readDb()
  const post = db.posts.find((item) => item.id === Number(postId))
  if (!post) {
    throw new Error('帖子不存在')
  }
  const matchedUser = db.users.find((item) => item.username === post.author)
  const normalizedPost = {
    ...post,
    authorId: post.authorId ?? matchedUser?.id ?? null
  }
  return delay({ post: normalizedPost })
}

export async function mockGetPostInteraction(postId) {
  const db = readDb()
  ensureInteractionDb(db)
  const currentUser = getCurrentUser(db)
  const key = String(postId)
  const interaction = db.postInteractions[key] || {
    likeCount: 0,
    favoriteCount: 0,
    likedUsers: [],
    favoriteUsers: []
  }
  return delay({
    likeCount: interaction.likeCount,
    favoriteCount: interaction.favoriteCount,
    liked: currentUser ? interaction.likedUsers.includes(currentUser.username) : false,
    favorited: currentUser ? interaction.favoriteUsers.includes(currentUser.username) : false
  })
}

export async function mockTogglePostLike(postId) {
  const db = readDb()
  ensureInteractionDb(db)
  const currentUser = getCurrentUser(db)
  if (!currentUser) throw new Error('请先登录')
  const key = String(postId)
  if (!db.postInteractions[key]) {
    db.postInteractions[key] = { likeCount: 0, favoriteCount: 0, likedUsers: [], favoriteUsers: [] }
  }
  const interaction = db.postInteractions[key]
  const idx = interaction.likedUsers.indexOf(currentUser.username)
  if (idx >= 0) {
    interaction.likedUsers.splice(idx, 1)
  } else {
    interaction.likedUsers.push(currentUser.username)
  }
  interaction.likeCount = interaction.likedUsers.length
  writeDb(db)
  return delay({
    likeCount: interaction.likeCount,
    favoriteCount: interaction.favoriteCount,
    liked: interaction.likedUsers.includes(currentUser.username)
  })
}

export async function mockTogglePostFavorite(postId) {
  const db = readDb()
  ensureInteractionDb(db)
  const currentUser = getCurrentUser(db)
  if (!currentUser) throw new Error('请先登录')
  const key = String(postId)
  if (!db.postInteractions[key]) {
    db.postInteractions[key] = { likeCount: 0, favoriteCount: 0, likedUsers: [], favoriteUsers: [] }
  }
  const interaction = db.postInteractions[key]
  const idx = interaction.favoriteUsers.indexOf(currentUser.username)
  if (idx >= 0) {
    interaction.favoriteUsers.splice(idx, 1)
  } else {
    interaction.favoriteUsers.push(currentUser.username)
  }
  interaction.favoriteCount = interaction.favoriteUsers.length
  writeDb(db)
  return delay({
    likeCount: interaction.likeCount,
    favoriteCount: interaction.favoriteCount,
    favorited: interaction.favoriteUsers.includes(currentUser.username)
  })
}

export async function mockListComments(postId) {
  const db = readDb()
  ensureInteractionDb(db)
  const list = db.postComments.filter((item) => item.postId === Number(postId))
  return delay({ list, total: list.length })
}

export async function mockCreateComment(postId, payload) {
  const db = readDb()
  ensureInteractionDb(db)
  const comment = {
    id: db.nextCommentId++,
    postId: Number(postId),
    parentId: payload.parentId ? Number(payload.parentId) : null,
    author: payload.author || 'unknown',
    content: payload.content || '',
    createdAt: new Date().toISOString()
  }
  db.postComments.push(comment)
  writeDb(db)
  return delay({ comment })
}

export async function mockListTopics() {
  const db = readDb()
  ensureInteractionDb(db)
  return delay({ list: db.topics, total: db.topics.length })
}

export async function mockCreateTopic(payload) {
  const db = readDb()
  ensureInteractionDb(db)
  const topic = {
    id: db.nextTopicId++,
    title: payload.title,
    description: payload.description || '',
    options: (payload.options || []).map((text) => ({
      id: db.nextTopicOptionId++,
      text,
      voteCount: 0
    })),
    createdBy: payload.createdBy || 'unknown',
    createdAt: new Date().toISOString()
  }
  db.topics.unshift(topic)
  writeDb(db)
  return delay({ topic })
}

export async function mockVoteTopic(topicId, optionId) {
  const db = readDb()
  ensureInteractionDb(db)
  const topic = db.topics.find((item) => item.id === Number(topicId))
  if (!topic) throw new Error('话题不存在')
  const option = topic.options.find((item) => item.id === Number(optionId))
  if (!option) throw new Error('投票选项不存在')
  option.voteCount += 1
  writeDb(db)
  return delay({ topic })
}

export async function mockGetMyProfile() {
  const db = readDb()
  ensureInteractionDb(db)
  ensureFollowDb(db)
  const currentUser = getCurrentUser(db)
  if (!currentUser) throw new Error('请先登录')

  const postCount = db.posts.filter((item) => item.author === currentUser.username).length
  const commentCount = db.postComments.filter((item) => item.author === (currentUser.displayName || currentUser.username)).length
  let likeCount = 0
  let favoriteCount = 0
  for (const interaction of Object.values(db.postInteractions)) {
    likeCount += interaction.likedUsers.includes(currentUser.username) ? 1 : 0
    favoriteCount += interaction.favoriteUsers.includes(currentUser.username) ? 1 : 0
  }
  const followerCount = db.follows.filter((item) => item.targetUserId === currentUser.id).length
  const followingCount = db.follows.filter((item) => item.userId === currentUser.id).length

  return delay({
    user: {
      id: currentUser.id,
      username: currentUser.username,
      displayName: currentUser.displayName,
      avatar: currentUser.avatar || '',
      role: currentUser.role,
      bio: currentUser.bio || '',
      joinedAt: currentUser.createdAt
    },
    stats: { postCount, commentCount, likeCount, favoriteCount, followerCount, followingCount }
  })
}

export async function mockUpdateMyProfile(payload) {
  const db = readDb()
  const currentUser = getCurrentUser(db)
  if (!currentUser) throw new Error('请先登录')
  currentUser.displayName = payload.displayName ?? currentUser.displayName
  currentUser.avatar = payload.avatar ?? currentUser.avatar
  currentUser.bio = payload.bio ?? currentUser.bio
  writeDb(db)
  return delay({
    user: {
      id: currentUser.id,
      username: currentUser.username,
      displayName: currentUser.displayName,
      avatar: currentUser.avatar || '',
      role: currentUser.role,
      bio: currentUser.bio || '',
      joinedAt: currentUser.createdAt
    }
  })
}

export async function mockListMyComments(query = {}) {
  const db = readDb()
  ensureInteractionDb(db)
  const currentUser = getCurrentUser(db)
  if (!currentUser) throw new Error('请先登录')
  const keyword = String(query.keyword || '').toLowerCase()
  const username = currentUser.displayName || currentUser.username
  const postMap = new Map(db.posts.map((item) => [item.id, item]))
  const list = db.postComments
    .filter((item) => {
      const isMine = item.author === username
      const match = !keyword || item.content.toLowerCase().includes(keyword)
      return isMine && match
    })
    .map((item) => ({
      ...item,
      postTitle: postMap.get(item.postId)?.title || ''
    }))
  return delay({ list, total: list.length, page: 1, pageSize: 20 })
}

export async function mockListMyLikes() {
  const db = readDb()
  ensureInteractionDb(db)
  const currentUser = getCurrentUser(db)
  if (!currentUser) throw new Error('请先登录')
  const list = []
  for (const post of db.posts) {
    const interaction = db.postInteractions[String(post.id)]
    if (interaction?.likedUsers.includes(currentUser.username)) {
      list.push(post)
    }
  }
  return delay({ list, total: list.length, page: 1, pageSize: 20 })
}

export async function mockListMyFavorites() {
  const db = readDb()
  ensureInteractionDb(db)
  const currentUser = getCurrentUser(db)
  if (!currentUser) throw new Error('请先登录')
  const list = []
  for (const post of db.posts) {
    const interaction = db.postInteractions[String(post.id)]
    if (interaction?.favoriteUsers.includes(currentUser.username)) {
      list.push(post)
    }
  }
  return delay({ list, total: list.length, page: 1, pageSize: 20 })
}

export async function mockGetUserPublicProfile(userId) {
  const db = readDb()
  ensureFollowDb(db)
  const target = db.users.find((item) => item.id === Number(userId))
  if (!target) throw new Error('用户不存在')
  const postCount = db.posts.filter((item) => item.author === target.username && item.status === 'published').length
  const commentCount = (db.postComments || []).filter((item) => item.author === (target.displayName || target.username)).length
  const followerCount = db.follows.filter((item) => item.targetUserId === target.id).length
  const followingCount = db.follows.filter((item) => item.userId === target.id).length
  return delay({
    user: {
      id: target.id,
      username: target.username,
      displayName: target.displayName,
      avatar: target.avatar || '',
      role: target.role,
      bio: target.bio || '',
      joinedAt: target.createdAt
    },
    stats: {
      postCount,
      commentCount,
      followerCount,
      followingCount
    }
  })
}

export async function mockGetFollowRelation(targetUserId) {
  const db = readDb()
  ensureFollowDb(db)
  const currentUser = getCurrentUser(db)
  if (!currentUser) throw new Error('请先登录')
  const targetId = Number(targetUserId)
  if (!targetId) throw new Error('目标用户非法')
  const followed = db.follows.some((item) => item.userId === currentUser.id && item.targetUserId === targetId)
  return delay({ followed })
}

export async function mockToggleFollowUser(targetUserId) {
  const db = readDb()
  ensureFollowDb(db)
  const currentUser = getCurrentUser(db)
  if (!currentUser) throw new Error('请先登录')
  const targetId = Number(targetUserId)
  if (!targetId) throw new Error('目标用户非法')
  if (targetId === currentUser.id) throw new Error('不能关注自己')
  const targetUser = db.users.find((item) => item.id === targetId)
  if (!targetUser) throw new Error('目标用户不存在')

  const index = db.follows.findIndex((item) => item.userId === currentUser.id && item.targetUserId === targetId)
  let followed = false
  if (index >= 0) {
    db.follows.splice(index, 1)
    followed = false
  } else {
    db.follows.push({
      userId: currentUser.id,
      targetUserId: targetId,
      createdAt: new Date().toISOString()
    })
    followed = true
  }

  writeDb(db)
  return delay({ followed })
}

export async function mockListMyFollowing(query = {}) {
  const db = readDb()
  ensureFollowDb(db)
  const currentUser = getCurrentUser(db)
  if (!currentUser) throw new Error('请先登录')

  const page = Math.max(1, Number(query.page || 1))
  const pageSize = Math.min(100, Math.max(1, Number(query.pageSize || 20)))
  const keyword = String(query.keyword || '').toLowerCase()

  const followedIds = db.follows
    .filter((item) => item.userId === currentUser.id)
    .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
    .map((item) => item.targetUserId)

  const all = followedIds
    .map((id) => db.users.find((user) => user.id === id))
    .filter(Boolean)
    .filter((user) => {
      if (!keyword) return true
      return (
        String(user.username || '').toLowerCase().includes(keyword) ||
        String(user.displayName || '').toLowerCase().includes(keyword)
      )
    })
    .map((user) => ({
      id: user.id,
      username: user.username,
      displayName: user.displayName,
      avatar: user.avatar || '',
      role: user.role,
      bio: user.bio || '',
      joinedAt: user.createdAt
    }))

  const start = (page - 1) * pageSize
  const list = all.slice(start, start + pageSize)
  return delay({ list, total: all.length, page, pageSize })
}

export async function mockReviewPost(postId, action) {
  const db = readDb()
  ensureAuditLogDb(db)
  const post = db.posts.find((item) => item.id === Number(postId))
  if (!post) {
    throw new Error('帖子不存在')
  }
  const currentUser = getCurrentUser(db)
  const oldStatus = post.status

  if (action === 'approve') {
    post.status = 'published'
    post.riskLevel = 'low'
  }

  if (action === 'reject') {
    post.status = 'rejected'
    post.riskLevel = 'high'
  }

  post.updatedAt = new Date().toISOString()

  if (action === 'approve' || action === 'reject') {
    appendAuditLog(db, {
      action: action === 'approve' ? 'review_approve' : 'review_reject',
      actionLabel: action === 'approve' ? '审核通过' : '审核驳回',
      postId: post.id,
      postTitle: post.title,
      operatorId: currentUser?.id || null,
      operator: currentUser?.username || 'system',
      operatorRole: currentUser?.role || 'system',
      detail: `status: ${oldStatus} -> ${post.status}`
    })
  }

  writeDb(db)
  return delay({ post })
}

export async function mockListAuditLogs(query = {}) {
  const db = readDb()
  ensureAuditLogDb(db)
  const keyword = String(query.keyword || '').toLowerCase()
  const action = String(query.action || '')
  const operator = String(query.operator || '').toLowerCase()
  const role = String(query.role || '')
  const page = Math.max(1, Number(query.page || 1))
  const pageSize = Math.min(100, Math.max(1, Number(query.pageSize || 20)))

  const filtered = db.auditLogs.filter((item) => {
    const matchedKeyword =
      !keyword ||
      String(item.postTitle || '').toLowerCase().includes(keyword) ||
      String(item.detail || '').toLowerCase().includes(keyword)
    const matchedAction = !action || item.action === action
    const matchedOperator = !operator || String(item.operator || '').toLowerCase().includes(operator)
    const matchedRole = !role || item.operatorRole === role
    return matchedKeyword && matchedAction && matchedOperator && matchedRole
  })

  const start = (page - 1) * pageSize
  const list = filtered.slice(start, start + pageSize)
  return delay({ list, total: filtered.length, page, pageSize })
}
