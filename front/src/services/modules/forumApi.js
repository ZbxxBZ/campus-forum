import http from '../http'
import {
  mockCreateComment,
  mockCreateBoard,
  mockCreatePost,
  mockCreateTopic,
  mockDashboardStats,
  mockGetMyProfile,
  mockGetPostDetail,
  mockGetPostInteraction,
  mockGetFollowRelation,
  mockGetUserPublicProfile,
  mockListAuditLogs,
  mockListBoards,
  mockListComments,
  mockListMyComments,
  mockListMyFavorites,
  mockListMyFollowing,
  mockListMyLikes,
  mockListPosts,
  mockListTopics,
  mockReviewPost,
  mockToggleFollowUser,
  mockTogglePostFavorite,
  mockTogglePostLike,
  mockUpdateMyProfile,
  mockUpdateBoard,
  mockUpdatePost,
  mockVoteTopic
} from '../mockServer'

const useMock = import.meta.env.VITE_USE_MOCK !== 'false'

function cleanParams(params = {}) {
  return Object.fromEntries(
    Object.entries(params).filter(([, value]) => value !== '' && value !== null && value !== undefined)
  )
}

export async function getDashboardStatsApi() {
  if (useMock) return mockDashboardStats()
  const { data } = await http.get('/v1/dashboard/stats')
  return data.data
}

export async function listAuditLogsApi(params) {
  if (useMock) return mockListAuditLogs(params)
  const { data } = await http.get('/v1/audit/logs', {
    params: cleanParams({ page: 1, pageSize: 20, ...params })
  })
  return data.data
}

export async function listPostsApi(params) {
  if (useMock) return mockListPosts(params)
  const { data } = await http.get('/v1/posts', {
    params: cleanParams({ page: 1, pageSize: 20, ...params })
  })
  return data.data
}

export async function listMyPostsApi(params) {
  if (useMock) return mockListPosts({ ...params, mine: true })
  try {
    const { data } = await http.get('/v1/posts/mine', {
      params: cleanParams({ page: 1, pageSize: 20, ...params })
    })
    return data.data
  } catch {
    const { data } = await http.get('/v1/posts', {
      params: cleanParams({ page: 1, pageSize: 20, ...params, mine: true })
    })
    return data.data
  }
}

export async function listPublishedPostsApi(params) {
  if (useMock) return mockListPosts({ ...params, status: 'published' })
  try {
    const { data } = await http.get('/v1/posts/published', {
      params: cleanParams({ page: 1, pageSize: 20, ...params })
    })
    return data.data
  } catch {
    const { data } = await http.get('/v1/posts', {
      params: cleanParams({ page: 1, pageSize: 20, ...params, status: 'published' })
    })
    return data.data
  }
}

export async function createPostApi(payload) {
  if (useMock) return mockCreatePost(payload)
  const { data } = await http.post('/v1/posts', payload)
  return data.data
}

export async function uploadImagesApi(files) {
  if (useMock) {
    return {
      files: files.map((file, index) => ({
        url: `mock://uploads/${Date.now()}-${index}-${file.name}`,
        name: file.name,
        size: file.size,
        contentType: file.type
      }))
    }
  }

  const formData = new FormData()
  files.forEach((file) => formData.append('files', file))
  const { data } = await http.post('/v1/uploads/images', formData, {
    timeout: 60000
  })
  return data.data
}

export async function getPostDetailApi(postId) {
  if (useMock) return mockGetPostDetail(postId)
  const { data } = await http.get(`/v1/posts/${postId}`)
  return data.data
}

export async function getPostInteractionApi(postId) {
  if (useMock) return mockGetPostInteraction(postId)
  const { data } = await http.get(`/v1/posts/${postId}/interaction`)
  return data.data
}

export async function togglePostLikeApi(postId) {
  if (useMock) return mockTogglePostLike(postId)
  const { data } = await http.post(`/v1/posts/${postId}/like`)
  return data.data
}

export async function togglePostFavoriteApi(postId) {
  if (useMock) return mockTogglePostFavorite(postId)
  const { data } = await http.post(`/v1/posts/${postId}/favorite`)
  return data.data
}

export async function listCommentsApi(postId) {
  if (useMock) return mockListComments(postId)
  const { data } = await http.get(`/v1/posts/${postId}/comments`)
  return data.data
}

export async function createCommentApi(postId, payload) {
  if (useMock) return mockCreateComment(postId, payload)
  const { data } = await http.post(`/v1/posts/${postId}/comments`, payload)
  return data.data
}

export async function listTopicsApi(params) {
  if (useMock) return mockListTopics(params)
  const { data } = await http.get('/v1/topics', { params: cleanParams(params) })
  return data.data
}

export async function createTopicApi(payload) {
  if (useMock) return mockCreateTopic(payload)
  const { data } = await http.post('/v1/topics', payload)
  return data.data
}

export async function voteTopicApi(topicId, optionId) {
  if (useMock) return mockVoteTopic(topicId, optionId)
  const { data } = await http.post(`/v1/topics/${topicId}/vote`, { optionId })
  return data.data
}

export async function updatePostApi(postId, payload) {
  if (useMock) return mockUpdatePost(postId, payload)
  const { data } = await http.patch(`/v1/posts/${postId}`, payload)
  return data.data
}

export async function reviewPostApi(postId, action) {
  if (useMock) return mockReviewPost(postId, action)
  const { data } = await http.patch(`/v1/posts/${postId}/review`, { action })
  return data.data
}

export async function listPendingReviewPostsApi(params) {
  if (useMock) return mockListPosts({ ...params, status: 'pending' })
  try {
    const { data } = await http.get('/v1/posts/review/pending', {
      params: cleanParams({ page: 1, pageSize: 20, ...params })
    })
    return data.data
  } catch {
    const { data } = await http.get('/v1/posts', {
      params: cleanParams({ page: 1, pageSize: 20, ...params, status: 'pending' })
    })
    return data.data
  }
}

export async function listBoardsApi(params) {
  if (useMock) return mockListBoards(params)
  const { data } = await http.get('/v1/boards', { params: cleanParams(params) })
  return data.data
}

export async function listAvailableBoardsApi(params) {
  if (useMock) return mockListBoards({ ...params, status: 'enabled' })
  try {
    const { data } = await http.get('/v1/boards/available', { params: cleanParams(params) })
    return data.data
  } catch {
    const { data } = await http.get('/v1/boards', { params: cleanParams({ ...params, status: 'enabled' }) })
    return data.data
  }
}

export async function createBoardApi(payload) {
  if (useMock) return mockCreateBoard(payload)
  const { data } = await http.post('/v1/boards', payload)
  return data.data
}

export async function updateBoardApi(boardId, payload) {
  if (useMock) return mockUpdateBoard(boardId, payload)
  const { data } = await http.patch(`/v1/boards/${boardId}`, payload)
  return data.data
}

export async function getMyProfileApi() {
  if (useMock) return mockGetMyProfile()
  const { data } = await http.get('/v1/profile/me')
  return data.data
}

export async function updateMyProfileApi(payload) {
  if (useMock) return mockUpdateMyProfile(payload)
  const { data } = await http.patch('/v1/profile/me', payload)
  return data.data
}

export async function listMyProfilePostsApi(params) {
  if (useMock) return mockListPosts({ ...params, mine: true })
  const { data } = await http.get('/v1/profile/me/posts', {
    params: cleanParams({ page: 1, pageSize: 20, ...params })
  })
  return data.data
}

export async function listMyProfileCommentsApi(params) {
  if (useMock) return mockListMyComments(params)
  const { data } = await http.get('/v1/profile/me/comments', {
    params: cleanParams({ page: 1, pageSize: 20, ...params })
  })
  return data.data
}

export async function listMyProfileLikesApi(params) {
  if (useMock) return mockListMyLikes(params)
  const { data } = await http.get('/v1/profile/me/likes', {
    params: cleanParams({ page: 1, pageSize: 20, ...params })
  })
  return data.data
}

export async function listMyProfileFavoritesApi(params) {
  if (useMock) return mockListMyFavorites(params)
  const { data } = await http.get('/v1/profile/me/favorites', {
    params: cleanParams({ page: 1, pageSize: 20, ...params })
  })
  return data.data
}

export async function listMyFollowingApi(params) {
  if (useMock) return mockListMyFollowing(params)
  const { data } = await http.get('/v1/profile/me/following', {
    params: cleanParams({ page: 1, pageSize: 20, ...params })
  })
  return data.data
}

export async function getUserPublicProfileApi(userId) {
  if (useMock) return mockGetUserPublicProfile(userId)
  const { data } = await http.get(`/v1/profile/users/${userId}`)
  return data.data
}

export async function getFollowRelationApi(targetUserId) {
  if (useMock) return mockGetFollowRelation(targetUserId)
  const { data } = await http.get('/v1/follows/relation', {
    params: cleanParams({ targetUserId })
  })
  return data.data
}

export async function toggleFollowUserApi(targetUserId) {
  if (useMock) return mockToggleFollowUser(targetUserId)
  const { data } = await http.post(`/v1/follows/${targetUserId}/toggle`)
  return data.data
}
