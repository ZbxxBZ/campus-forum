package org.example.project.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.project.dto.BoardView;
import org.example.project.dto.CommentView;
import org.example.project.dto.FollowUserView;
import org.example.project.dto.PostView;
import org.example.project.dto.RolePermissionsView;
import org.example.project.dto.AuditLogView;
import org.example.project.dto.TopicOptionView;
import org.example.project.dto.TopicView;
import org.example.project.dto.request.CreateBoardRequest;
import org.example.project.dto.request.CreateCommentRequest;
import org.example.project.dto.request.CreatePostRequest;
import org.example.project.dto.request.CreateTopicRequest;
import org.example.project.dto.request.UpdateBoardRequest;
import org.example.project.dto.request.UpdateMyProfileRequest;
import org.example.project.dto.request.UpdatePostRequest;
import org.example.project.dto.request.VoteTopicRequest;
import org.example.project.exception.ApiException;
import org.example.project.mapper.AuthTokenMapper;
import org.example.project.mapper.AuditLogMapper;
import org.example.project.mapper.BoardMapper;
import org.example.project.mapper.PostCommentMapper;
import org.example.project.mapper.PostFavoriteMapper;
import org.example.project.mapper.PostLikeMapper;
import org.example.project.mapper.PostMapper;
import org.example.project.mapper.RolePermissionMapper;
import org.example.project.mapper.TopicMapper;
import org.example.project.mapper.TopicOptionMapper;
import org.example.project.mapper.TopicVoteMapper;
import org.example.project.mapper.UserMapper;
import org.example.project.mapper.UserFollowMapper;
import org.example.project.mapper.UserProfileMapper;
import org.example.project.model.BoardEntity;
import org.example.project.model.AuditLogEntity;
import org.example.project.model.PostCommentEntity;
import org.example.project.model.PostEntity;
import org.example.project.model.RolePermissionRow;
import org.example.project.model.TopicEntity;
import org.example.project.model.TopicOptionEntity;
import org.example.project.model.TopicVoteEntity;
import org.example.project.model.UserEntity;
import org.example.project.model.UserProfileEntity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URI;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ForumService {
    private static final DateTimeFormatter DB_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final int ONLINE_ACTIVE_WINDOW_MINUTES = 15;
    private static final int DASHBOARD_TREND_DAYS = 30;
    private static final int DASHBOARD_BOARD_TOP_LIMIT = 8;

    private static final List<String> ALLOWED_ROLES = List.of("super_admin", "teacher", "student");
    private static final List<String> ALLOWED_USER_STATUS = List.of("active", "disabled");
    private static final List<String> ALLOWED_REVIEW_ACTIONS = List.of("approve", "reject");
    private static final List<String> ALLOWED_POST_FORMATS = List.of("rich_text", "markdown", "image_gallery", "external_link");
    private static final List<String> ALLOWED_POST_VISIBILITY = List.of("public", "campus", "private");
    private static final List<String> ALLOWED_POST_STATUS = List.of("draft", "pending", "published", "rejected", "hidden");
    private static final List<String> ALLOWED_PUBLISHED_FEEDS = List.of("all", "recommend", "hot", "latest", "followed");
    private static final List<String> ALLOWED_BOARD_STATUS = List.of("enabled", "disabled");
    private static final List<String> DEFAULT_BLOCKED_WORDS = List.of("毒品", "代考", "买卖枪支", "爆炸物", "电信诈骗");
    private static final List<String> DEFAULT_WARNING_WORDS = List.of("兼职刷单", "私下转账", "外挂", "翻墙", "校园贷");

    private final UserMapper userMapper;
    private final AuthTokenMapper authTokenMapper;
    private final AuditLogMapper auditLogMapper;
    private final RolePermissionMapper rolePermissionMapper;
    private final PostMapper postMapper;
    private final BoardMapper boardMapper;
    private final PostLikeMapper postLikeMapper;
    private final PostFavoriteMapper postFavoriteMapper;
    private final PostCommentMapper postCommentMapper;
    private final TopicMapper topicMapper;
    private final TopicOptionMapper topicOptionMapper;
    private final TopicVoteMapper topicVoteMapper;
    private final UserProfileMapper userProfileMapper;
    private final UserFollowMapper userFollowMapper;
    private final TencentCloudModerationService tencentModerationService;
    private final List<String> blockedWords;
    private final List<String> warningWords;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public ForumService(
            UserMapper userMapper,
            AuthTokenMapper authTokenMapper,
            AuditLogMapper auditLogMapper,
            RolePermissionMapper rolePermissionMapper,
            PostMapper postMapper,
            BoardMapper boardMapper,
            PostLikeMapper postLikeMapper,
            PostFavoriteMapper postFavoriteMapper,
            PostCommentMapper postCommentMapper,
            TopicMapper topicMapper,
            TopicOptionMapper topicOptionMapper,
            TopicVoteMapper topicVoteMapper,
            UserProfileMapper userProfileMapper,
            UserFollowMapper userFollowMapper,
            @Value("${app.moderation.blocked-words:}") String blockedWordsConfig,
            @Value("${app.moderation.warning-words:}") String warningWordsConfig,
            @Autowired(required = false) TencentCloudModerationService tencentModerationService
    ) {
        this.userMapper = userMapper;
        this.authTokenMapper = authTokenMapper;
        this.auditLogMapper = auditLogMapper;
        this.rolePermissionMapper = rolePermissionMapper;
        this.postMapper = postMapper;
        this.boardMapper = boardMapper;
        this.postLikeMapper = postLikeMapper;
        this.postFavoriteMapper = postFavoriteMapper;
        this.postCommentMapper = postCommentMapper;
        this.topicMapper = topicMapper;
        this.topicOptionMapper = topicOptionMapper;
        this.topicVoteMapper = topicVoteMapper;
        this.userProfileMapper = userProfileMapper;
        this.userFollowMapper = userFollowMapper;
        this.tencentModerationService = tencentModerationService;
        this.blockedWords = parseWordList(blockedWordsConfig, DEFAULT_BLOCKED_WORDS);
        this.warningWords = parseWordList(warningWordsConfig, DEFAULT_WARNING_WORDS);
    }

    @Transactional
    public UserEntity register(String username, String displayName, String email, String password) {
        if (isBlank(username) || isBlank(displayName) || isBlank(email) || isBlank(password)) {
            throw new ApiException("Missing required fields");
        }
        if (userMapper.findByUsername(username) != null) {
            throw new ApiException("Username already exists");
        }
        if (userMapper.findByEmail(email) != null) {
            throw new ApiException("Email already exists");
        }
        UserEntity user = new UserEntity();
        user.setUsername(username);
        user.setDisplayName(displayName);
        user.setEmail(email);
        user.setPassword(password);
        user.setRole("student");
        user.setStatus("active");
        user.setCreatedAt(nowDbTime());
        userMapper.insert(user);
        return user;
    }

    @Transactional
    public String login(String username, String password) {
        UserEntity user = userMapper.findByUsername(username);
        if (user == null || !Objects.equals(user.getPassword(), password)) {
            throw new ApiException("Invalid username or password");
        }
        if (!"active".equals(user.getStatus())) {
            throw new ApiException("User is disabled");
        }
        String token = UUID.randomUUID().toString();
        authTokenMapper.insert(token, user.getId(), nowDbTime());
        return token;
    }

    public UserEntity getUserByToken(String authorizationHeader) {
        if (isBlank(authorizationHeader) || !authorizationHeader.startsWith("Bearer ")) {
            throw new ApiException("Unauthorized");
        }
        String token = authorizationHeader.substring("Bearer ".length()).trim();
        if (isBlank(token)) {
            throw new ApiException("Unauthorized");
        }
        Long userId = authTokenMapper.findUserIdByToken(token);
        if (userId == null) {
            throw new ApiException("Unauthorized");
        }
        authTokenMapper.touch(token, nowDbTime());
        UserEntity user = userMapper.findById(userId);
        if (user == null) {
            throw new ApiException("Unauthorized");
        }
        return user;
    }

    public UserEntity requirePermission(String authorizationHeader, String permission) {
        UserEntity user = getUserByToken(authorizationHeader);
        if ("super_admin".equals(user.getRole())) {
            return user;
        }
        List<String> permissions = getPermissionsByRole(user.getRole());
        if (!permissions.contains(permission)) {
            throw new ApiException("无权限访问");
        }
        return user;
    }

    public List<String> getPermissionsByRole(String role) {
        return rolePermissionMapper.findPermissionsByRole(role);
    }

    public List<UserEntity> listUsers(String keyword, String role, String status) {
        return userMapper.list(keyword, role, status);
    }

    public long countUsers(String keyword, String role, String status) {
        return userMapper.count(keyword, role, status);
    }

    @Transactional
    public UserEntity updateUserRole(Long userId, String role) {
        if (isBlank(role)) {
            throw new ApiException("Role is required");
        }
        if (!ALLOWED_ROLES.contains(role)) {
            throw new ApiException("Invalid role");
        }
        if (userMapper.updateRole(userId, role) == 0) {
            throw new ApiException("User not found");
        }
        return userMapper.findById(userId);
    }

    @Transactional
    public UserEntity updateUserStatus(Long userId, String status) {
        if (isBlank(status)) {
            throw new ApiException("Status is required");
        }
        if (!ALLOWED_USER_STATUS.contains(status)) {
            throw new ApiException("Invalid status");
        }
        if (userMapper.updateStatus(userId, status) == 0) {
            throw new ApiException("User not found");
        }
        return userMapper.findById(userId);
    }

    public List<RolePermissionsView> listRoles() {
        List<RolePermissionRow> rows = rolePermissionMapper.listAll();
        Map<String, List<RolePermissionRow>> grouped = rows.stream()
                .collect(Collectors.groupingBy(RolePermissionRow::getRole, LinkedHashMap::new, Collectors.toList()));

        List<RolePermissionsView> result = new ArrayList<>();
        for (Map.Entry<String, List<RolePermissionRow>> entry : grouped.entrySet()) {
            String role = entry.getKey();
            List<RolePermissionRow> roleRows = entry.getValue();
            String roleLabel = roleRows.get(0).getRoleLabel();
            List<String> permissions = roleRows.stream()
                    .map(RolePermissionRow::getPermission)
                    .filter(Objects::nonNull)
                    .toList();
            result.add(new RolePermissionsView(role, roleLabel, permissions));
        }
        return result;
    }

    @Transactional
    public List<String> updateRolePermissions(String role, List<String> permissions) {
        if (isBlank(role)) {
            throw new ApiException("Role is required");
        }
        if (rolePermissionMapper.roleExists(role) == 0) {
            throw new ApiException("Role not found");
        }
        if (permissions == null) {
            throw new ApiException("Permissions cannot be null");
        }
        String roleLabel = rolePermissionMapper.findRoleLabel(role);
        rolePermissionMapper.deleteByRole(role);
        if (!permissions.isEmpty()) {
            rolePermissionMapper.insertBatch(role, roleLabel, permissions);
        }
        return permissions;
    }

    public Map<String, Object> getDashboardStats() {
        LocalDate today = LocalDate.now();
        LocalDate trendStartDate = today.minusDays(DASHBOARD_TREND_DAYS - 1L);
        String todayPrefix = today.toString();
        String trendDateFrom = trendStartDate.toString();
        String trendDateTo = today.toString();
        Map<String, Object> stats = new LinkedHashMap<>();

        stats.put("totalUsers", userMapper.countAll());
        stats.put("totalPosts", postMapper.countAll());
        stats.put("pendingReviews", postMapper.countPendingReview(null, null, null));
        stats.put("rejectedToday", postMapper.countByStatusAndUpdatedDatePrefix("rejected", todayPrefix));
        stats.put("peakQps", 1260);

        String onlineSince = LocalDateTime.now().minusMinutes(ONLINE_ACTIVE_WINDOW_MINUTES).format(DB_TIME_FORMATTER);
        stats.put("onlineUsers", authTokenMapper.countOnlineUsersSince(onlineSince));

        stats.put("totalComments", postCommentMapper.countAll());
        stats.put("totalLikes", postLikeMapper.countAll());
        stats.put("totalFavorites", postFavoriteMapper.countAll());
        stats.put("reviewPassedToday", postMapper.countByStatusAndUpdatedDatePrefix("published", todayPrefix));
        stats.put("reviewSubmittedToday", postMapper.countByStatusAndUpdatedDatePrefix("pending", todayPrefix));
        stats.put("publishedPosts", postMapper.countByStatus("published"));
        stats.put("hiddenPosts", postMapper.countByStatus("hidden"));
        stats.put("rejectedPosts", postMapper.countByStatus("rejected"));

        stats.put("postTrend", buildTrendSeries(trendStartDate, today, postMapper.countCreatedTrendByDate(trendDateFrom, trendDateTo)));
        stats.put("activeTrend", buildTrendSeries(trendStartDate, today, authTokenMapper.countActiveTrendByDate(trendDateFrom, trendDateTo)));
        stats.put("roleDistribution", buildRoleDistribution(userMapper.countRoleDistribution()));
        stats.put("statusDistribution", buildStatusDistribution());
        stats.put("boardDistribution", buildValueDistribution(postMapper.countBoardDistributionTop(DASHBOARD_BOARD_TOP_LIMIT)));

        return stats;
    }

    @Transactional
    public PostEntity createPost(CreatePostRequest request, UserEntity currentUser) {
        if (isBlank(request.title()) || request.boardId() == null) {
            throw new ApiException("帖子标题、板块不能为空");
        }
        String format = normalizePostFormat(request.format());
        String visibility = normalizeText(request.visibility());
        if (visibility == null) {
            visibility = "public";  // 默认为公开
        }
        String requestedStatus = normalizePostStatus(request.status());
        validatePostFormat(format);
        validatePostVisibility(visibility);
        List<String> attachments = normalizeStringList(request.attachments());
        List<String> galleryCaptions = normalizeStringList(request.galleryCaptions());
        String linkUrl = normalizeText(request.linkUrl());
        String linkTitle = normalizeText(request.linkTitle());
        String linkSummary = normalizeText(request.linkSummary());
        String createStatus = resolveCreateStatus(currentUser, requestedStatus);
        boolean isDraftCreate = "draft".equals(createStatus);
        if (!isDraftCreate) {
            validatePostPayload(format, request.content(), attachments, linkUrl);
        }

        // 审核逻辑：仅在非草稿状态时进行审核
        String riskLevel = "low";
        String moderationReason = null;  // 记录审核未通过的原因
        List<String> moderationKeywords = null;  // 记录命中的关键词
        if (!isDraftCreate) {
            // 第一层：本地敏感词审核
            ModerationCheckResult localResult = preModerationCheck(
                    request.title(),
                    request.summary(),
                    request.content(),
                    normalizeStringList(request.tags()),
                    linkTitle,
                    linkSummary
            );

            // 本地审核命中blocked-words，直接拒绝
            if ("high".equals(localResult.riskLevel())) {
                Map<String, Object> data = new LinkedHashMap<>();
                data.put("message", "请修改后再提交");
                data.put("riskLevel", localResult.riskLevel());
                data.put("hitWords", localResult.hitWords());
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, 42201, "内容命中违禁规则", data);
            }

            // 第二层：腾讯云审核（如果启用）
            if (tencentModerationService != null) {
                String fullText = buildFullText(
                    request.title(),
                    request.summary(),
                    request.content(),
                    normalizeStringList(request.tags()),
                    linkTitle,
                    linkSummary
                );

                org.example.project.dto.TencentModerationResult cloudResult =
                    tencentModerationService.moderateText(fullText);

                // 处理云审核结果
                if (cloudResult.isSuccess() && !cloudResult.isFallback()) {
                    if (!cloudResult.isPass()) {
                        // Result=1 违规，直接拒绝
                        if (cloudResult.getResult() == 1) {
                            // 构建友好的错误提示
                            String reason = getLabelDescription(cloudResult.getLabel());
                            Map<String, Object> data = new LinkedHashMap<>();
                            data.put("reason", reason);
                            data.put("label", cloudResult.getLabel());
                            data.put("score", cloudResult.getScore());
                            if (cloudResult.getKeywords() != null && !cloudResult.getKeywords().isEmpty()) {
                                data.put("keywords", cloudResult.getKeywords());
                            }
                            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, 42202,
                                "内容审核未通过：" + reason, data);
                        }
                        // Result=2 疑似，强制转为pending状态
                        if (cloudResult.getResult() == 2) {
                            createStatus = "pending";
                            riskLevel = "medium";
                            moderationReason = getLabelDescription(cloudResult.getLabel());
                            moderationKeywords = cloudResult.getKeywords();
                        }
                    } else {
                        riskLevel = "low";
                    }
                } else {
                    // 云审核失败，降级使用本地审核结果
                    riskLevel = localResult.riskLevel();
                    if ("medium".equals(riskLevel)) {
                        createStatus = "pending";
                    }
                }
            } else {
                // 未启用云审核，使用本地审核结果
                riskLevel = localResult.riskLevel();
                if ("medium".equals(riskLevel)) {
                    createStatus = "pending";
                }
            }
        }

        BoardEntity board = getBoardOrThrow(request.boardId());
        PostEntity post = new PostEntity();
        post.setTitle(request.title());
        post.setSummary(request.summary());
        post.setContent(request.content());
        post.setFormat(format);
        post.setAttachmentsJson(writeJsonArray(attachments));
        post.setTagsJson(writeJsonArray(normalizeStringList(request.tags())));
        post.setGalleryCaptionsJson(writeJsonArray(galleryCaptions));
        post.setLinkUrl(linkUrl);
        post.setLinkTitle(linkTitle == null ? request.title() : linkTitle);
        post.setLinkSummary(linkSummary);
        post.setBoardId(request.boardId());
        post.setBoardName(board.getName());
        post.setCategory(board.getName());
        post.setAuthor(currentUser.getUsername());
        post.setVisibility(visibility);
        post.setStatus(createStatus);
        post.setRiskLevel(riskLevel);
        post.setIsTop(Boolean.TRUE.equals(request.isTop()));
        post.setIsFeatured(Boolean.TRUE.equals(request.isFeatured()));
        post.setCreatedAt(nowDbTime());
        post.setUpdatedAt(post.getCreatedAt());
        int affected = postMapper.insert(post);
        if (affected <= 0 || post.getId() == null) {
            throw new ApiException("帖子写入失败");
        }
        PostEntity created = postMapper.findById(post.getId());
        if (created == null) {
            throw new ApiException("帖子写入后查询失败");
        }

        return created;
    }

    @Transactional
    public PostEntity updatePost(Long postId, UpdatePostRequest request, UserEntity operator) {
        PostEntity old = postMapper.findById(postId);
        if (old == null) {
            throw new ApiException("帖子不存在");
        }
        boolean isAuthor = Objects.equals(old.getAuthor(), operator.getUsername());
        boolean isManager = isManagementUser(operator);
        if (!isAuthor && !isManager) {
            throw new ApiException("无权限访问");
        }
        PostEntity update = new PostEntity();
        update.setId(postId);
        update.setTitle(request.title());
        update.setSummary(request.summary());
        update.setContent(request.content());
        String format = normalizePostFormat(request.format());
        String visibility = normalizeText(request.visibility());
        String status = normalizePostStatus(request.status());
        if (isAuthor && !isManager) {
            validateAuthorPostUpdateRule(old, request, status);
        }
        String effectiveFormat = format == null ? old.getFormat() : format;
        String effectiveContent = request.content() == null ? old.getContent() : request.content();
        List<String> effectiveAttachments = request.attachments() == null
                ? readJsonArray(old.getAttachmentsJson())
                : normalizeStringList(request.attachments());
        String effectiveLinkUrl = request.linkUrl() == null ? normalizeText(old.getLinkUrl()) : normalizeText(request.linkUrl());
        boolean contentChanged = request.format() != null
                || request.content() != null
                || request.attachments() != null
                || request.linkUrl() != null;
        if (contentChanged) {
            validatePostPayload(effectiveFormat, effectiveContent, effectiveAttachments, effectiveLinkUrl);
        }
        if (format != null) {
            validatePostFormat(format);
            update.setFormat(format);
        }
        if (visibility != null) {
            validatePostVisibility(visibility);
            update.setVisibility(visibility);
        }
        if (status != null) {
            validatePostStatus(status);
            update.setStatus(status);
        }
        if (request.boardId() != null) {
            BoardEntity board = getBoardOrThrow(request.boardId());
            update.setBoardId(request.boardId());
            update.setBoardName(board.getName());
            update.setCategory(board.getName());
        }
        if (request.tags() != null) {
            update.setTagsJson(writeJsonArray(normalizeStringList(request.tags())));
        }
        if (request.attachments() != null) {
            update.setAttachmentsJson(writeJsonArray(effectiveAttachments));
        }
        if (request.galleryCaptions() != null) {
            update.setGalleryCaptionsJson(writeJsonArray(normalizeStringList(request.galleryCaptions())));
        }
        if (request.linkUrl() != null) {
            update.setLinkUrl(normalizeText(request.linkUrl()));
        }
        if (request.linkTitle() != null) {
            update.setLinkTitle(normalizeText(request.linkTitle()));
        }
        if (request.linkSummary() != null) {
            update.setLinkSummary(normalizeText(request.linkSummary()));
        }
        update.setIsTop(request.isTop());
        update.setIsFeatured(request.isFeatured());
        update.setUpdatedAt(nowDbTime());
        postMapper.updateSelective(update);
        PostEntity updated = postMapper.findById(postId);
        if (updated != null && !Objects.equals(old.getStatus(), updated.getStatus())) {
            String action;
            String actionLabel;
            if ("published".equals(old.getStatus()) && "hidden".equals(updated.getStatus())) {
                action = "post_hide";
                actionLabel = "帖子下架";
            } else if ("hidden".equals(old.getStatus()) && "published".equals(updated.getStatus())) {
                action = "post_publish";
                actionLabel = "帖子上架";
            } else {
                action = "post_status_change";
                actionLabel = "状态变更";
            }
            createAuditLog(action, actionLabel, updated, operator, "status: " + old.getStatus() + " -> " + updated.getStatus());
        }
        return updated;
    }

    public List<PostEntity> listPosts(
            String keyword,
            String status,
            Long boardId,
            String format,
            String visibility,
            String author,
            int page,
            int pageSize
    ) {
        String normalizedKeyword = normalizeText(keyword);
        List<String> normalizedStatuses = normalizePostStatuses(status);
        String normalizedFormat = normalizePostFormat(format);
        String normalizedVisibility = normalizeText(visibility);
        String normalizedAuthor = normalizeText(author);
        if (normalizedFormat != null) {
            validatePostFormat(normalizedFormat);
        }
        if (normalizedVisibility != null) {
            validatePostVisibility(normalizedVisibility);
        }
        int safePage = Math.max(page, 1);
        int safePageSize = normalizePageSize(pageSize);
        int offset = (safePage - 1) * safePageSize;
        return postMapper.list(
                normalizedKeyword, null, normalizedStatuses, boardId, normalizedFormat, normalizedVisibility, normalizedAuthor, offset, safePageSize
        );
    }

    public long countPosts(String keyword, String status, Long boardId, String format, String visibility, String author) {
        return postMapper.count(
                normalizeText(keyword),
                null,
                normalizePostStatuses(status),
                boardId,
                normalizePostFormat(format),
                normalizeText(visibility),
                normalizeText(author)
        );
    }

    public List<PostEntity> listPublishedPosts(
            Long currentUserId,
            String feed,
            String keyword,
            String author,
            String tag,
            Long boardId,
            String format,
            String dateFrom,
            String dateTo,
            int page,
            int pageSize
    ) {
        String normalizedFormat = normalizePostFormat(format);
        if (normalizedFormat != null) {
            validatePostFormat(normalizedFormat);
        }
        String normalizedFeed = normalizePublishedFeed(feed);
        int safePage = Math.max(page, 1);
        int safePageSize = normalizePageSize(pageSize);
        int offset = (safePage - 1) * safePageSize;
        String from = normalizeDateBound(dateFrom, true);
        String to = normalizeDateBound(dateTo, false);
        List<String> keywordTerms = buildPublishedSearchTerms(keyword);
        List<String> preferredTags = "recommend".equals(normalizedFeed)
                ? buildUserPreferredTags(currentUserId)
                : List.of();
        return postMapper.listPublished(
                normalizedFeed,
                currentUserId,
                keywordTerms,
                preferredTags,
                normalizeText(author),
                normalizeText(tag),
                boardId,
                normalizedFormat,
                from,
                to,
                offset,
                safePageSize
        );
    }

    public long countPublishedPosts(
            Long currentUserId,
            String feed,
            String keyword,
            String author,
            String tag,
            Long boardId,
            String format,
            String dateFrom,
            String dateTo
    ) {
        String normalizedFeed = normalizePublishedFeed(feed);
        String from = normalizeDateBound(dateFrom, true);
        String to = normalizeDateBound(dateTo, false);
        List<String> keywordTerms = buildPublishedSearchTerms(keyword);
        return postMapper.countPublished(
                normalizedFeed,
                currentUserId,
                keywordTerms,
                normalizeText(author),
                normalizeText(tag),
                boardId,
                normalizePostFormat(format),
                from,
                to
        );
    }

    public List<PostEntity> listPendingReviewPosts(String keyword, Long boardId, String format, int page, int pageSize) {
        String normalizedFormat = normalizePostFormat(format);
        if (normalizedFormat != null) {
            validatePostFormat(normalizedFormat);
        }
        int safePage = Math.max(page, 1);
        int safePageSize = normalizePageSize(pageSize);
        int offset = (safePage - 1) * safePageSize;
        return postMapper.listPendingReview(normalizeText(keyword), boardId, normalizedFormat, offset, safePageSize);
    }

    public long countPendingReviewPosts(String keyword, Long boardId, String format) {
        return postMapper.countPendingReview(normalizeText(keyword), boardId, normalizePostFormat(format));
    }

    public List<AuditLogView> listAuditLogs(String keyword, String action, String role, String operator, int page, int pageSize) {
        int safePage = Math.max(page, 1);
        int safePageSize = normalizePageSize(pageSize);
        int offset = (safePage - 1) * safePageSize;
        return auditLogMapper.list(
                        normalizeText(keyword),
                        normalizeText(action),
                        normalizeText(role),
                        normalizeText(operator),
                        offset,
                        safePageSize
                ).stream()
                .map(this::toAuditLogViewLocalized)
                .toList();
    }

    public long countAuditLogs(String keyword, String action, String role, String operator) {
        return auditLogMapper.count(
                normalizeText(keyword),
                normalizeText(action),
                normalizeText(role),
                normalizeText(operator)
        );
    }

    public Map<String, Object> getPostInteraction(Long postId, UserEntity user) {
        ensurePostExists(postId);
        long likeCount = postLikeMapper.countByPostId(postId);
        long favoriteCount = postFavoriteMapper.countByPostId(postId);
        boolean liked = postLikeMapper.exists(postId, user.getId()) > 0;
        boolean favorited = postFavoriteMapper.exists(postId, user.getId()) > 0;
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("likeCount", likeCount);
        data.put("favoriteCount", favoriteCount);
        data.put("liked", liked);
        data.put("favorited", favorited);
        return data;
    }

    @Transactional
    public Map<String, Object> togglePostLike(Long postId, UserEntity user) {
        ensurePostExists(postId);
        if (postLikeMapper.exists(postId, user.getId()) > 0) {
            postLikeMapper.delete(postId, user.getId());
        } else {
            postLikeMapper.insert(postId, user.getId(), nowDbTime());
        }
        return getPostInteraction(postId, user);
    }

    @Transactional
    public Map<String, Object> togglePostFavorite(Long postId, UserEntity user) {
        ensurePostExists(postId);
        if (postFavoriteMapper.exists(postId, user.getId()) > 0) {
            postFavoriteMapper.delete(postId, user.getId());
        } else {
            postFavoriteMapper.insert(postId, user.getId(), nowDbTime());
        }
        return getPostInteraction(postId, user);
    }

    public List<CommentView> listPostComments(Long postId, UserEntity user) {
        ensurePostExists(postId);
        getPostDetail(postId, user);
        return postCommentMapper.listByPostId(postId).stream()
                .map(CommentView::from)
                .toList();
    }

    public List<CommentView> listPostComments(Long postId, UserEntity user, int page, int pageSize) {
        ensurePostExists(postId);
        getPostDetail(postId, user);
        int safePage = Math.max(page, 1);
        int safePageSize = normalizePageSize(pageSize);
        int offset = (safePage - 1) * safePageSize;
        return postCommentMapper.listByPostIdPaged(postId, offset, safePageSize).stream()
                .map(CommentView::from)
                .toList();
    }

    public long countPostComments(Long postId) {
        return postCommentMapper.countByPostId(postId);
    }

    @Transactional
    public CommentView createPostComment(Long postId, CreateCommentRequest request, UserEntity user) {
        ensurePostExists(postId);
        if (isBlank(request.content())) {
            throw new ApiException("评论内容不能为空");
        }
        Long parentId = request.parentId();
        if (parentId != null) {
            PostCommentEntity parent = postCommentMapper.findById(parentId);
            if (parent == null || !postId.equals(parent.getPostId())) {
                throw new ApiException("回复的评论不存在");
            }
        }
        PostCommentEntity comment = new PostCommentEntity();
        comment.setPostId(postId);
        comment.setParentId(parentId);
        comment.setUserId(user.getId());
        comment.setContent(request.content().trim());
        comment.setCreatedAt(nowDbTime());
        comment.setUpdatedAt(nowDbTime());
        postCommentMapper.insert(comment);
        PostCommentEntity saved = postCommentMapper.findById(comment.getId());
        if (saved == null) {
            throw new ApiException("评论发布失败");
        }
        return CommentView.from(saved);
    }

    public List<TopicView> listTopics(String keyword, int page, int pageSize) {
        int safePage = Math.max(page, 1);
        int safePageSize = normalizePageSize(pageSize);
        int offset = (safePage - 1) * safePageSize;
        List<TopicEntity> topics = topicMapper.list(normalizeText(keyword), offset, safePageSize);
        if (topics.isEmpty()) {
            return List.of();
        }
        List<Long> topicIds = topics.stream().map(TopicEntity::getId).toList();
        List<TopicOptionEntity> options = topicOptionMapper.listByTopicIds(topicIds);
        Map<Long, List<TopicOptionView>> optionsMap = new HashMap<>();
        for (TopicOptionEntity option : options) {
            optionsMap.computeIfAbsent(option.getTopicId(), ignored -> new ArrayList<>())
                    .add(TopicOptionView.from(option));
        }
        return topics.stream()
                .map(topic -> TopicView.from(topic, optionsMap.getOrDefault(topic.getId(), List.of())))
                .toList();
    }

    public long countTopics(String keyword) {
        return topicMapper.count(normalizeText(keyword));
    }

    @Transactional
    public TopicView createTopic(CreateTopicRequest request, UserEntity user) {
        if (!"super_admin".equals(user.getRole()) && !getPermissionsByRole(user.getRole()).contains("topic:create")) {
            throw new ApiException("无权限访问");
        }
        if (isBlank(request.title())) {
            throw new ApiException("话题标题不能为空");
        }
        List<String> options = sanitizeTopicOptions(request.options());
        if (options.size() < 2) {
            throw new ApiException("投票选项至少需要2个");
        }
        TopicEntity topic = new TopicEntity();
        topic.setTitle(request.title().trim());
        topic.setDescription(normalizeText(request.description()));
        topic.setCreatedBy(user.getId());
        topic.setCreatedAt(nowDbTime());
        topicMapper.insert(topic);
        topicOptionMapper.insertBatch(topic.getId(), options);
        TopicEntity saved = topicMapper.findById(topic.getId());
        List<TopicOptionView> optionViews = topicOptionMapper.listByTopicId(topic.getId()).stream()
                .map(TopicOptionView::from)
                .toList();
        return TopicView.from(saved, optionViews);
    }

    @Transactional
    public TopicView voteTopic(Long topicId, VoteTopicRequest request, UserEntity user) {
        TopicEntity topic = topicMapper.findById(topicId);
        if (topic == null) {
            throw new ApiException("话题不存在");
        }
        if (request.optionId() == null) {
            throw new ApiException("投票选项不能为空");
        }
        TopicOptionEntity option = topicOptionMapper.findById(request.optionId());
        if (option == null || !topicId.equals(option.getTopicId())) {
            throw new ApiException("投票选项不存在");
        }
        TopicVoteEntity existing = topicVoteMapper.findByTopicAndUser(topicId, user.getId());
        if (existing == null) {
            TopicVoteEntity vote = new TopicVoteEntity();
            vote.setTopicId(topicId);
            vote.setOptionId(request.optionId());
            vote.setUserId(user.getId());
            vote.setCreatedAt(nowDbTime());
            topicVoteMapper.insert(vote);
            topicOptionMapper.increaseVoteCount(request.optionId(), 1);
        } else if (!request.optionId().equals(existing.getOptionId())) {
            topicVoteMapper.updateOption(existing.getId(), request.optionId());
            topicOptionMapper.increaseVoteCount(existing.getOptionId(), -1);
            topicOptionMapper.increaseVoteCount(request.optionId(), 1);
        }
        TopicEntity refreshed = topicMapper.findById(topicId);
        List<TopicOptionView> optionViews = topicOptionMapper.listByTopicId(topicId).stream()
                .map(TopicOptionView::from)
                .toList();
        return TopicView.from(refreshed, optionViews);
    }

    public Map<String, Object> getMyProfile(UserEntity user) {
        UserProfileEntity profile = userProfileMapper.findByUserId(user.getId());
        Map<String, Object> userData = new LinkedHashMap<>();
        userData.put("id", user.getId());
        userData.put("username", user.getUsername());
        userData.put("displayName", user.getDisplayName());
        userData.put("avatar", profile == null ? null : profile.getAvatar());
        userData.put("role", user.getRole());
        userData.put("bio", profile == null ? null : profile.getBio());
        userData.put("joinedAt", user.getCreatedAt());

        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("postCount", countPosts(null, null, null, null, null, user.getUsername()));
        stats.put("commentCount", postCommentMapper.countByUserId(user.getId(), null));
        stats.put("likeCount", postLikeMapper.countByUserId(user.getId()));
        stats.put("favoriteCount", postFavoriteMapper.countByUserId(user.getId()));
        stats.put("followerCount", userFollowMapper.countFollowerByTargetUserId(user.getId()));
        stats.put("followingCount", userFollowMapper.countFollowing(user.getId(), null));

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("user", userData);
        data.put("stats", stats);
        return data;
    }

    public Map<String, Object> getPublicProfile(Long userId) {
        UserEntity user = userMapper.findById(userId);
        if (user == null) {
            throw new ApiException("用户不存在");
        }
        UserProfileEntity profile = userProfileMapper.findByUserId(user.getId());
        Map<String, Object> userData = new LinkedHashMap<>();
        userData.put("id", user.getId());
        userData.put("username", user.getUsername());
        userData.put("displayName", user.getDisplayName());
        userData.put("avatar", profile == null ? null : profile.getAvatar());
        userData.put("role", user.getRole());
        userData.put("bio", profile == null ? null : profile.getBio());
        userData.put("joinedAt", user.getCreatedAt());

        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("postCount", countPosts(null, null, null, null, null, user.getUsername()));
        stats.put("commentCount", postCommentMapper.countByUserId(user.getId(), null));
        stats.put("followerCount", userFollowMapper.countFollowerByTargetUserId(user.getId()));
        stats.put("followingCount", userFollowMapper.countFollowing(user.getId(), null));

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("user", userData);
        data.put("stats", stats);
        return data;
    }

    @Transactional
    public Map<String, Object> updateMyProfile(UserEntity user, UpdateMyProfileRequest request) {
        String displayName = normalizeText(request.displayName());
        if (displayName != null) {
            userMapper.updateDisplayName(user.getId(), displayName);
        }
        UserProfileEntity existing = userProfileMapper.findByUserId(user.getId());
        UserProfileEntity profile = existing == null ? new UserProfileEntity() : existing;
        profile.setUserId(user.getId());
        profile.setAvatar(normalizeText(request.avatar()));
        profile.setBio(normalizeText(request.bio()));
        profile.setUpdatedAt(nowDbTime());
        if (existing == null) {
            userProfileMapper.insert(profile);
        } else {
            userProfileMapper.update(profile);
        }
        UserEntity refreshedUser = userMapper.findById(user.getId());
        return getMyProfile(refreshedUser);
    }

    public List<PostView> listMyProfilePosts(UserEntity user, String keyword, String status, int page, int pageSize) {
        return listPosts(keyword, "published", null, null, null, user.getUsername(), page, pageSize).stream()
                .map(this::toPostView)
                .map(this::localizePostStatusForProfile)
                .toList();
    }

    public long countMyProfilePosts(UserEntity user, String keyword, String status) {
        return countPosts(keyword, "published", null, null, null, user.getUsername());
    }

    public List<CommentView> listMyComments(UserEntity user, String keyword, int page, int pageSize) {
        int safePage = Math.max(page, 1);
        int safePageSize = normalizePageSize(pageSize);
        int offset = (safePage - 1) * safePageSize;
        return postCommentMapper.listByUserId(user.getId(), normalizeText(keyword), offset, safePageSize).stream()
                .map(CommentView::from)
                .toList();
    }

    public long countMyComments(UserEntity user, String keyword) {
        return postCommentMapper.countByUserId(user.getId(), normalizeText(keyword));
    }

    public List<PostView> listMyLikedPosts(UserEntity user, int page, int pageSize) {
        int safePage = Math.max(page, 1);
        int safePageSize = normalizePageSize(pageSize);
        int offset = (safePage - 1) * safePageSize;
        List<Long> postIds = postLikeMapper.listPostIdsByUserId(user.getId(), offset, safePageSize);
        return listPostsByIds(postIds);
    }

    public long countMyLikes(UserEntity user) {
        return postLikeMapper.countByUserId(user.getId());
    }

    public List<PostView> listMyFavoritePosts(UserEntity user, int page, int pageSize) {
        int safePage = Math.max(page, 1);
        int safePageSize = normalizePageSize(pageSize);
        int offset = (safePage - 1) * safePageSize;
        List<Long> postIds = postFavoriteMapper.listPostIdsByUserId(user.getId(), offset, safePageSize);
        return listPostsByIds(postIds);
    }

    public long countMyFavorites(UserEntity user) {
        return postFavoriteMapper.countByUserId(user.getId());
    }

    public boolean getFollowRelation(UserEntity currentUser, Long targetUserId) {
        UserEntity target = userMapper.findById(targetUserId);
        if (target == null) {
            throw new ApiException("用户不存在");
        }
        if (Objects.equals(currentUser.getId(), targetUserId)) {
            return false;
        }
        return userFollowMapper.exists(currentUser.getId(), targetUserId) > 0;
    }

    @Transactional
    public boolean toggleFollow(UserEntity currentUser, Long targetUserId) {
        if (targetUserId == null) {
            throw new ApiException("目标用户不能为空");
        }
        if (Objects.equals(currentUser.getId(), targetUserId)) {
            throw new ApiException("不能关注自己");
        }
        UserEntity target = userMapper.findById(targetUserId);
        if (target == null) {
            throw new ApiException("用户不存在");
        }
        boolean followed = userFollowMapper.exists(currentUser.getId(), targetUserId) > 0;
        if (followed) {
            userFollowMapper.delete(currentUser.getId(), targetUserId);
            return false;
        }
        userFollowMapper.insert(currentUser.getId(), targetUserId, nowDbTime());
        return true;
    }

    public List<FollowUserView> listMyFollowing(UserEntity user, String keyword, int page, int pageSize) {
        int safePage = Math.max(page, 1);
        int safePageSize = normalizePageSize(pageSize);
        int offset = (safePage - 1) * safePageSize;
        return userFollowMapper.listFollowing(user.getId(), normalizeText(keyword), offset, safePageSize);
    }

    public long countMyFollowing(UserEntity user, String keyword) {
        return userFollowMapper.countFollowing(user.getId(), normalizeText(keyword));
    }

    public PostView toPostView(PostEntity post) {
        Long authorId = null;
        String authorName = post.getAuthor();
        String authorAvatar = null;
        UserEntity authorUser = userMapper.findByUsername(post.getAuthor());
        if (authorUser != null) {
            authorId = authorUser.getId();
            authorName = firstNonBlank(authorUser.getDisplayName(), authorUser.getUsername());
            UserProfileEntity authorProfile = userProfileMapper.findByUserId(authorId);
            authorAvatar = authorProfile == null ? null : authorProfile.getAvatar();
        }
        long likeCount = postLikeMapper.countByPostId(post.getId());
        long favoriteCount = postFavoriteMapper.countByPostId(post.getId());
        long commentCount = postCommentMapper.countByPostId(post.getId());
        long hotScore = likeCount * 3 + favoriteCount * 2 + commentCount;
        return PostView.from(
                post,
                readJsonArray(post.getAttachmentsJson()),
                readJsonArray(post.getTagsJson()),
                readJsonArray(post.getGalleryCaptionsJson()),
                authorName,
                authorId,
                authorAvatar,
                likeCount,
                favoriteCount,
                commentCount,
                hotScore
        );
    }

    public PostEntity getPostDetail(Long postId, UserEntity currentUser) {
        PostEntity post = postMapper.findById(postId);
        if (post == null) {
            throw new ApiException("帖子不存在");
        }
        boolean isAuthor = currentUser.getUsername().equals(post.getAuthor());
        if ("private".equals(post.getVisibility()) && !isAuthor) {
            throw new ApiException("无权限访问");
        }
        if (!"published".equals(post.getStatus()) && !isAuthor && !isManagementUser(currentUser)) {
            throw new ApiException("无权限访问");
        }
        return post;
    }

    @Transactional
    public PostEntity reviewPost(Long postId, String action, UserEntity operator) {
        if (isBlank(action)) {
            throw new ApiException("Action is required");
        }
        if (!ALLOWED_REVIEW_ACTIONS.contains(action)) {
            throw new ApiException("Invalid action");
        }
        PostEntity current = postMapper.findById(postId);
        if (current == null) {
            throw new ApiException("Post not found");
        }
        String nextStatus = "approve".equals(action) ? "published" : "rejected";
        String nextRiskLevel = "approve".equals(action) ? "low" : "high";
        postMapper.updateReview(postId, nextStatus, nextRiskLevel);
        PostEntity updated = postMapper.findById(postId);
        String logAction = "approve".equals(action) ? "review_approve" : "review_reject";
        String logActionLabel = "approve".equals(action) ? "审核通过" : "审核驳回";
        if (updated != null) {
            createAuditLog(logAction, logActionLabel, updated, operator, "status: " + current.getStatus() + " -> " + updated.getStatus());
        }
        return updated;
    }

    public List<BoardEntity> listBoards(String keyword, String status) {
        String normalizedStatus = normalizeText(status);
        if (normalizedStatus != null && !ALLOWED_BOARD_STATUS.contains(normalizedStatus)) {
            throw new ApiException("Invalid board status");
        }
        return boardMapper.list(normalizeText(keyword), normalizedStatus);
    }

    public long countBoards(String keyword, String status) {
        return boardMapper.count(normalizeText(keyword), normalizeText(status));
    }

    public List<BoardEntity> listAvailableBoards() {
        return boardMapper.listAvailable();
    }

    @Transactional
    public BoardEntity createBoard(CreateBoardRequest request) {
        if (isBlank(request.name()) || isBlank(request.code())) {
            throw new ApiException("板块名称和编码不能为空");
        }
        String status = isBlank(request.status()) ? "enabled" : request.status();
        if (!ALLOWED_BOARD_STATUS.contains(status)) {
            throw new ApiException("板块状态不合法");
        }
        if (boardMapper.findByCode(request.code()) != null) {
            throw new ApiException("板块编码已存在");
        }
        BoardEntity board = new BoardEntity();
        board.setName(request.name());
        board.setCode(request.code());
        board.setDescription(request.description());
        board.setSortOrder(request.sortOrder() == null ? 0 : request.sortOrder());
        board.setStatus(status);
        board.setPostCount(0);
        board.setCreatedAt(nowDbTime());
        board.setUpdatedAt(board.getCreatedAt());
        boardMapper.insert(board);
        return boardMapper.findById(board.getId());
    }

    @Transactional
    public BoardEntity updateBoard(Long boardId, UpdateBoardRequest request) {
        BoardEntity current = boardMapper.findById(boardId);
        if (current == null) {
            throw new ApiException("板块不存在");
        }
        if (request.code() != null) {
            BoardEntity dup = boardMapper.findByCode(request.code());
            if (dup != null && !dup.getId().equals(boardId)) {
                throw new ApiException("板块编码已存在");
            }
        }
        if (request.status() != null && !ALLOWED_BOARD_STATUS.contains(request.status())) {
            throw new ApiException("板块状态不合法");
        }
        BoardEntity board = new BoardEntity();
        board.setId(boardId);
        board.setName(request.name());
        board.setCode(request.code());
        board.setDescription(request.description());
        board.setSortOrder(request.sortOrder());
        board.setStatus(request.status());
        board.setUpdatedAt(nowDbTime());
        boardMapper.updateSelective(board);
        BoardEntity updated = boardMapper.findById(boardId);
        postMapper.updateBoardNameByBoardId(boardId, updated.getName());
        return updated;
    }

    public BoardView toBoardView(BoardEntity board) {
        return BoardView.from(board);
    }

    private BoardEntity getBoardOrThrow(Long boardId) {
        BoardEntity board = boardMapper.findById(boardId);
        if (board == null) {
            throw new ApiException("板块不存在");
        }
        if (!"enabled".equals(board.getStatus())) {
            throw new ApiException("板块已禁用");
        }
        return board;
    }

    private void validatePostFormat(String format) {
        if (isBlank(format) || !ALLOWED_POST_FORMATS.contains(format)) {
            throw new ApiException("帖子格式不合法");
        }
    }

    private void validatePostVisibility(String visibility) {
        if (isBlank(visibility) || !ALLOWED_POST_VISIBILITY.contains(visibility)) {
            throw new ApiException("帖子可见范围不合法");
        }
    }

    private void validatePostStatus(String status) {
        if (isBlank(status) || !ALLOWED_POST_STATUS.contains(status)) {
            throw new ApiException("帖子状态不合法");
        }
    }

    private void validateAuthorPostUpdateRule(PostEntity old, UpdatePostRequest request, String targetStatus) {
        if (hasRestrictedAuthorFields(request)) {
            throw new ApiException("用户仅可编辑标题、摘要、正文或执行状态流转");
        }
        if ("published".equals(targetStatus)) {
            throw new ApiException("普通用户不允许直接发布帖子");
        }
        String currentStatus = old.getStatus();
        if ("published".equals(currentStatus)) {
            boolean hasContentChange = request.title() != null || request.summary() != null || request.content() != null;
            if (!"hidden".equals(targetStatus) || hasContentChange) {
                throw new ApiException("已发布帖子仅支持删除");
            }
            return;
        }
        if ("pending".equals(currentStatus)) {
            if (targetStatus != null && !"pending".equals(targetStatus) && !"draft".equals(targetStatus)) {
                throw new ApiException("待审核帖子仅支持撤回或编辑");
            }
            return;
        }
        if ("draft".equals(currentStatus) || "rejected".equals(currentStatus)) {
            if (targetStatus != null
                    && !Objects.equals(targetStatus, currentStatus)
                    && !"pending".equals(targetStatus)) {
                throw new ApiException("草稿/驳回帖子仅支持编辑或重新发布");
            }
            return;
        }
        throw new ApiException("当前状态不支持该操作");
    }

    private boolean hasRestrictedAuthorFields(UpdatePostRequest request) {
        return request.format() != null
                || request.boardId() != null
                || request.visibility() != null
                || request.linkUrl() != null
                || request.linkTitle() != null
                || request.linkSummary() != null
                || request.galleryCaptions() != null
                || request.tags() != null
                || request.attachments() != null
                || request.isTop() != null
                || request.isFeatured() != null;
    }

    private void validatePostPayload(String format, String content, List<String> attachments, String linkUrl) {
        if ("rich_text".equals(format) || "markdown".equals(format)) {
            if (isBlank(content)) {
                throw new ApiException("正文不能为空");
            }
            return;
        }
        if ("image_gallery".equals(format)) {
            if (attachments == null || attachments.isEmpty()) {
                throw new ApiException("图文相册至少上传一张图片");
            }
            for (String attachment : attachments) {
                String value = normalizeText(attachment);
                if (isBlank(value)) {
                    throw new ApiException("图片地址不能为空");
                }
                String lower = value.toLowerCase();
                if (lower.startsWith("data:")) {
                    throw new ApiException("图文相册仅支持图片 URL，不支持 base64");
                }
                if (!(lower.startsWith("http://") || lower.startsWith("https://") || lower.startsWith("/uploads/"))) {
                    throw new ApiException("图片地址格式不合法");
                }
            }
            return;
        }
        if ("external_link".equals(format)) {
            validateExternalLink(linkUrl);
        }
    }

    private void validateExternalLink(String linkUrl) {
        if (isBlank(linkUrl)) {
            throw new ApiException("外链地址不能为空");
        }
        try {
            URI uri = URI.create(linkUrl);
            String scheme = uri.getScheme();
            if (scheme == null || (!"http".equalsIgnoreCase(scheme) && !"https".equalsIgnoreCase(scheme))) {
                throw new ApiException("外链地址不合法，仅支持 http/https");
            }
            if (isBlank(uri.getHost())) {
                throw new ApiException("外链地址不合法，仅支持 http/https");
            }
        } catch (IllegalArgumentException ex) {
            throw new ApiException("外链地址不合法，仅支持 http/https");
        }
    }

    private String resolveCreateStatus(UserEntity currentUser, String requestedStatus) {
        if (requestedStatus != null) {
            validatePostStatus(requestedStatus);
        }
        if (!"super_admin".equals(currentUser.getRole())) {
            if ("draft".equals(requestedStatus)) {
                return "draft";
            }
            return "pending";
        }
        if (requestedStatus == null) {
            return "pending";
        }
        return requestedStatus;
    }

    private ModerationCheckResult preModerationCheck(
            String title,
            String summary,
            String content,
            List<String> tags,
            String linkTitle,
            String linkSummary
    ) {
        String text = String.join("\n", List.of(
                normalizeText(title) == null ? "" : normalizeText(title),
                normalizeText(summary) == null ? "" : normalizeText(summary),
                normalizeText(content) == null ? "" : normalizeText(content),
                normalizeText(linkTitle) == null ? "" : normalizeText(linkTitle),
                normalizeText(linkSummary) == null ? "" : normalizeText(linkSummary),
                tags == null ? "" : String.join(" ", tags)
        ));

        List<String> blockedHits = findHitWords(text, blockedWords);
        if (!blockedHits.isEmpty()) {
            return new ModerationCheckResult("high", blockedHits);
        }
        List<String> warningHits = findHitWords(text, warningWords);
        if (!warningHits.isEmpty()) {
            return new ModerationCheckResult("medium", warningHits);
        }
        return new ModerationCheckResult("low", List.of());
    }

    private String buildFullText(String title, String summary, String content,
                                 List<String> tags, String linkTitle, String linkSummary) {
        return String.join("\n", List.of(
            normalizeText(title) == null ? "" : normalizeText(title),
            normalizeText(summary) == null ? "" : normalizeText(summary),
            normalizeText(content) == null ? "" : normalizeText(content),
            normalizeText(linkTitle) == null ? "" : normalizeText(linkTitle),
            normalizeText(linkSummary) == null ? "" : normalizeText(linkSummary),
            tags == null ? "" : String.join(" ", tags)
        ));
    }

    private String getLabelDescription(String label) {
        if (label == null) {
            return "内容不符合社区规范";
        }
        switch (label) {
            case "Porn":
                return "内容包含色情信息";
            case "Illegal":
                return "内容包含违法信息（如赌博、诈骗等）";
            case "Ad":
                return "内容包含广告推广信息";
            case "Abuse":
                return "内容包含谩骂或人身攻击";
            case "Polity":
                return "内容包含政治敏感信息";
            case "Terror":
                return "内容包含暴力恐怖信息";
            default:
                return "内容不符合社区规范";
        }
    }

    private List<String> findHitWords(String text, List<String> words) {
        if (isBlank(text) || words == null || words.isEmpty()) {
            return List.of();
        }
        Set<String> hit = new LinkedHashSet<>();
        String lowerText = text.toLowerCase();
        for (String word : words) {
            if (isBlank(word)) {
                continue;
            }
            String normalized = word.trim();
            if (lowerText.contains(normalized.toLowerCase())) {
                hit.add(normalized);
            }
        }
        return new ArrayList<>(hit);
    }

    private List<String> parseWordList(String rawConfig, List<String> defaults) {
        if (isBlank(rawConfig)) {
            return defaults;
        }
        List<String> words = new ArrayList<>();
        for (String part : rawConfig.split(",")) {
            String value = normalizeText(part);
            if (value != null) {
                words.add(value);
            }
        }
        return words.isEmpty() ? defaults : words;
    }

    private List<String> readJsonArray(String value) {
        if (isBlank(value)) {
            return List.of();
        }
        try {
            return objectMapper.readValue(value, new TypeReference<>() {
            });
        } catch (Exception ex) {
            return List.of();
        }
    }

    private String writeJsonArray(List<String> value) {
        try {
            return objectMapper.writeValueAsString(value == null ? List.of() : value);
        } catch (Exception ex) {
            throw new ApiException("JSON 序列化失败");
        }
    }

    private List<String> normalizeStringList(Object raw) {
        if (raw == null) {
            return List.of();
        }
        if (raw instanceof String str) {
            if (str.isBlank()) {
                return List.of();
            }
            return List.of(str);
        }
        if (raw instanceof List<?> list) {
            List<String> result = new ArrayList<>();
            for (Object item : list) {
                if (item == null) {
                    continue;
                }
                String value = String.valueOf(item).trim();
                if (!value.isEmpty()) {
                    result.add(value);
                }
            }
            return result;
        }
        throw new ApiException("列表字段格式不正确");
    }

    private String nowDbTime() {
        return LocalDateTime.now().format(DB_TIME_FORMATTER);
    }

    private void ensurePostExists(Long postId) {
        if (postId == null || postMapper.findById(postId) == null) {
            throw new ApiException("帖子不存在");
        }
    }

    private List<String> sanitizeTopicOptions(List<String> rawOptions) {
        if (rawOptions == null) {
            return List.of();
        }
        List<String> options = new ArrayList<>();
        for (String option : rawOptions) {
            String value = normalizeText(option);
            if (value != null) {
                options.add(value);
            }
        }
        return options;
    }

    private List<PostView> listPostsByIds(List<Long> postIds) {
        if (postIds == null || postIds.isEmpty()) {
            return List.of();
        }
        List<PostView> list = new ArrayList<>();
        for (Long postId : postIds) {
            PostEntity post = postMapper.findById(postId);
            if (post != null) {
                list.add(toPostView(post));
            }
        }
        return list;
    }

    private Long resolveAuthorId(String username) {
        if (isBlank(username)) {
            return null;
        }
        UserEntity user = userMapper.findByUsername(username);
        return user == null ? null : user.getId();
    }

    private String normalizePostFormat(String rawFormat) {
        String normalized = normalizeText(rawFormat);
        if (normalized == null) {
            return null;
        }
        return switch (normalized.toLowerCase()) {
            case "rich_text", "richtext", "rich-text", "rich", "富文本" -> "rich_text";
            case "markdown", "md", "markdown_text", "markdown-text" -> "markdown";
            case "image_gallery", "imagegallery", "image-gallery", "image_album", "image-album", "album", "gallery", "图文相册", "相册" ->
                    "image_gallery";
            case "external_link", "external", "link", "url", "外链", "外部链接" -> "external_link";
            default -> normalized;
        };
    }

    private String normalizePostStatus(String rawStatus) {
        String normalized = normalizeText(rawStatus);
        if (normalized == null) {
            return null;
        }
        return switch (normalized.toLowerCase()) {
            case "draft", "pending", "published", "rejected", "hidden" -> normalized.toLowerCase();
            case "off_shelf", "off-shelf", "offshelf", "offline", "down", "unpublished", "下架" -> "hidden";
            case "on_shelf", "on-shelf", "onshelf", "上架" -> "published";
            default -> normalized;
        };
    }

    private List<String> normalizePostStatuses(String rawStatus) {
        String normalized = normalizeText(rawStatus);
        if (normalized == null) {
            return List.of();
        }
        LinkedHashSet<String> result = new LinkedHashSet<>();
        String[] parts = normalized.split("[,，]");
        for (String part : parts) {
            String status = normalizePostStatus(part);
            if (status == null) {
                continue;
            }
            validatePostStatus(status);
            result.add(status);
        }
        return new ArrayList<>(result);
    }

    private List<String> buildPublishedSearchTerms(String keyword) {
        String normalized = normalizeText(keyword);
        if (normalized == null) {
            return List.of();
        }
        LinkedHashSet<String> terms = new LinkedHashSet<>();
        terms.add(normalized);
        addLiteralVariantExpansions(terms, normalized);
        for (String fragment : splitSearchFragments(normalized)) {
            if (fragment.length() < 2) {
                continue;
            }
            terms.add(fragment);
            addLiteralVariantExpansions(terms, fragment);
            String stripped = stripChineseModalSuffix(fragment);
            if (stripped.length() >= 2) {
                terms.add(stripped);
                addLiteralVariantExpansions(terms, stripped);
            }
            if (containsCjk(fragment)) {
                addCjkNgrams(terms, fragment, 2);
                addCjkNgrams(terms, fragment, 3);
            }
        }
        return new ArrayList<>(terms).subList(0, Math.min(terms.size(), 30));
    }

    private void addLiteralVariantExpansions(Set<String> terms, String value) {
        String normalized = normalizeText(value);
        if (normalized == null) {
            return;
        }
        String compact = normalized.replaceAll("[\\s,，.。!！?？;；:：/\\\\|\\-—_()（）\\[\\]【】\"“”'‘’、]+", "");
        if (compact.length() >= 2) {
            terms.add(compact);
        }
        if ("四六级".equals(compact)) {
            terms.add("四级");
            terms.add("六级");
            terms.add("四六");
            terms.add("四%六%级");
        }
        if (compact.length() >= 3 && containsCjk(compact)) {
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < compact.length(); i++) {
                if (i > 0) {
                    sb.append('%');
                }
                sb.append(compact.charAt(i));
            }
            terms.add(sb.toString());
        }
        // 中文短关键词增加单字兜底召回，保证“相同字眼”也能命中（例如 期中 -> 期末）
        if (containsCjk(compact) && compact.length() <= 3) {
            for (int i = 0; i < compact.length(); i++) {
                terms.add(String.valueOf(compact.charAt(i)));
            }
        }
    }

    private List<String> buildUserPreferredTags(Long userId) {
        if (userId == null) {
            return List.of();
        }
        Set<Long> interactedPostIds = new LinkedHashSet<>();
        interactedPostIds.addAll(postLikeMapper.listAllPostIdsByUserId(userId));
        interactedPostIds.addAll(postFavoriteMapper.listAllPostIdsByUserId(userId));
        interactedPostIds.addAll(postCommentMapper.listDistinctPostIdsByUserId(userId));
        if (interactedPostIds.isEmpty()) {
            return List.of();
        }
        Map<String, Integer> tagFrequency = new HashMap<>();
        for (Long postId : interactedPostIds) {
            PostEntity post = postMapper.findById(postId);
            if (post == null) {
                continue;
            }
            for (String tag : readJsonArray(post.getTagsJson())) {
                String normalizedTag = normalizeText(tag);
                if (normalizedTag == null) {
                    continue;
                }
                tagFrequency.merge(normalizedTag, 1, Integer::sum);
            }
        }
        return tagFrequency.entrySet().stream()
                .sorted((a, b) -> {
                    int byCount = Integer.compare(b.getValue(), a.getValue());
                    if (byCount != 0) {
                        return byCount;
                    }
                    return a.getKey().compareTo(b.getKey());
                })
                .limit(5)
                .map(Map.Entry::getKey)
                .toList();
    }

    private String normalizePublishedFeed(String feed) {
        String normalized = normalizeText(feed);
        if (normalized == null) {
            return "recommend";
        }
        String lower = normalized.toLowerCase();
        if (!ALLOWED_PUBLISHED_FEEDS.contains(lower)) {
            throw new ApiException("信息流类型不合法");
        }
        return lower;
    }

    private List<String> splitSearchFragments(String keyword) {
        if (isBlank(keyword)) {
            return List.of();
        }
        String[] parts = keyword.split("[\\s,，.。!！?？;；:：/\\\\|\\-—_()（）\\[\\]【】\"“”'‘’]+");
        List<String> result = new ArrayList<>();
        for (String part : parts) {
            String value = normalizeText(part);
            if (value != null) {
                result.add(value);
            }
        }
        return result;
    }

    private String stripChineseModalSuffix(String value) {
        if (value == null || value.length() < 2) {
            return value == null ? "" : value;
        }
        String result = value;
        while (result.length() >= 2) {
            char last = result.charAt(result.length() - 1);
            if (last == '了' || last == '呢' || last == '吗' || last == '啊' || last == '呀' || last == '吧') {
                result = result.substring(0, result.length() - 1);
            } else {
                break;
            }
        }
        return result;
    }

    private void addCjkNgrams(Set<String> terms, String value, int n) {
        if (value == null || value.length() < n || n <= 1) {
            return;
        }
        for (int i = 0; i <= value.length() - n; i++) {
            String gram = value.substring(i, i + n);
            if (gram.length() >= 2) {
                terms.add(gram);
            }
        }
    }

    private boolean containsCjk(String value) {
        if (value == null) {
            return false;
        }
        for (int i = 0; i < value.length(); i++) {
            Character.UnicodeScript script = Character.UnicodeScript.of(value.charAt(i));
            if (script == Character.UnicodeScript.HAN) {
                return true;
            }
        }
        return false;
    }

    private String normalizeDateBound(String rawDate, boolean startOfDay) {
        String value = normalizeText(rawDate);
        if (value == null) {
            return null;
        }
        try {
            LocalDate date = LocalDate.parse(value);
            return date + (startOfDay ? " 00:00:00" : " 23:59:59");
        } catch (Exception ex) {
            throw new ApiException("日期格式不合法，应为 YYYY-MM-DD");
        }
    }

    private void createAuditLog(String action, String actionLabel, PostEntity post, UserEntity operator, String detail) {
        if (post == null || operator == null) {
            return;
        }
        AuditLogEntity log = new AuditLogEntity();
        log.setAction(action);
        log.setActionLabel(actionLabel == null ? action : actionLabel);
        log.setPostId(post.getId());
        log.setPostTitle(post.getTitle());
        log.setOperatorId(operator.getId());
        log.setOperator(firstNonBlank(operator.getDisplayName(), operator.getUsername()));
        log.setOperatorRole(operator.getRole());
        log.setDetail(detail);
        log.setCreatedAt(nowDbTime());
        auditLogMapper.insert(log);
    }

    private AuditLogView toAuditLogViewLocalized(AuditLogEntity entity) {
        String operatorName = firstNonBlank(resolveUserDisplayName(entity.getOperatorId()), entity.getOperator());
        String operatorRoleLabel = toChineseRole(entity.getOperatorRole());
        String localizedDetail = toChineseAuditDetail(entity.getDetail());
        return new AuditLogView(
                entity.getId(),
                entity.getAction(),
                entity.getActionLabel(),
                entity.getPostId(),
                entity.getPostTitle(),
                entity.getOperatorId(),
                operatorName,
                operatorRoleLabel,
                localizedDetail,
                entity.getCreatedAt()
        );
    }

    private String resolveUserDisplayName(Long userId) {
        if (userId == null) {
            return null;
        }
        UserEntity user = userMapper.findById(userId);
        if (user == null) {
            return null;
        }
        return firstNonBlank(user.getDisplayName(), user.getUsername());
    }

    private String toChineseRole(String role) {
        if (role == null) {
            return null;
        }
        return switch (role) {
            case "super_admin" -> "超级管理员";
            case "admin" -> "管理员";
            case "teacher" -> "教师";
            case "student" -> "学生";
            default -> role;
        };
    }

    private String toChineseAuditDetail(String detail) {
        String value = normalizeText(detail);
        if (value == null) {
            return null;
        }
        String prefix = "status:";
        if (value.startsWith(prefix)) {
            String body = value.substring(prefix.length()).trim();
            String[] parts = body.split("->");
            if (parts.length == 2) {
                String from = toChinesePostStatus(normalizeText(parts[0]));
                String to = toChinesePostStatus(normalizeText(parts[1]));
                return "状态：" + (from == null ? "-" : from) + " -> " + (to == null ? "-" : to);
            }
        }
        return value;
    }

    private String firstNonBlank(String... values) {
        if (values == null) {
            return null;
        }
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value;
            }
        }
        return null;
    }

    private PostView localizePostStatusForProfile(PostView post) {
        String localizedStatus = toChinesePostStatus(post.status());
        if (Objects.equals(localizedStatus, post.status())) {
            return post;
        }
        return new PostView(
                post.id(),
                post.title(),
                post.summary(),
                post.content(),
                post.format(),
                post.formatLabel(),
                post.attachments(),
                post.tags(),
                post.galleryCaptions(),
                post.linkUrl(),
                post.linkTitle(),
                post.linkSummary(),
                post.boardId(),
                post.boardName(),
                post.author(),
                post.authorId(),
                post.authorAvatar(),
                post.visibility(),
                localizedStatus,
                post.riskLevel(),
                post.isTop(),
                post.isFeatured(),
                post.createdAt(),
                post.updatedAt(),
                post.likeCount(),
                post.favoriteCount(),
                post.commentCount(),
                post.hotScore()
        );
    }

    private String toChinesePostStatus(String status) {
        if (status == null) {
            return null;
        }
        return switch (status) {
            case "draft" -> "草稿";
            case "pending" -> "待审核";
            case "published" -> "已发布";
            case "rejected" -> "已驳回";
            case "hidden" -> "已下架";
            default -> status;
        };
    }

    private List<Map<String, Object>> buildTrendSeries(LocalDate startDate, LocalDate endDate, List<Map<String, Object>> rawRows) {
        Map<String, Long> valueByDate = new HashMap<>();
        if (rawRows != null) {
            for (Map<String, Object> row : rawRows) {
                String date = asText(row.get("date"));
                if (date == null) {
                    continue;
                }
                valueByDate.put(date, asLong(row.get("count")));
            }
        }
        List<Map<String, Object>> result = new ArrayList<>();
        LocalDate cursor = startDate;
        while (!cursor.isAfter(endDate)) {
            String date = cursor.toString();
            long value = valueByDate.getOrDefault(date, 0L);
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("label", date);
            item.put("date", date);
            item.put("value", value);
            item.put("count", value);
            result.add(item);
            cursor = cursor.plusDays(1);
        }
        return result;
    }

    private List<Map<String, Object>> buildRoleDistribution(List<Map<String, Object>> rawRows) {
        List<Map<String, Object>> result = new ArrayList<>();
        if (rawRows == null) {
            return result;
        }
        for (Map<String, Object> row : rawRows) {
            String rawRole = asText(row.get("label"));
            if (rawRole == null) {
                continue;
            }
            long value = asLong(row.get("value"));
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("label", toChineseRole(rawRole));
            item.put("value", value);
            result.add(item);
        }
        return result;
    }

    private List<Map<String, Object>> buildStatusDistribution() {
        List<Map<String, Object>> result = new ArrayList<>();
        List<String> statuses = List.of("published", "pending", "hidden", "rejected", "draft");
        for (String status : statuses) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("label", toChinesePostStatus(status));
            item.put("value", postMapper.countByStatus(status));
            result.add(item);
        }
        return result;
    }

    private List<Map<String, Object>> buildValueDistribution(List<Map<String, Object>> rawRows) {
        List<Map<String, Object>> result = new ArrayList<>();
        if (rawRows == null) {
            return result;
        }
        for (Map<String, Object> row : rawRows) {
            String label = asText(row.get("label"));
            if (label == null) {
                continue;
            }
            long value = asLong(row.get("value"));
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("label", label);
            item.put("value", value);
            result.add(item);
        }
        return result;
    }

    private String asText(Object value) {
        if (value == null) {
            return null;
        }
        String text = String.valueOf(value).trim();
        return text.isEmpty() ? null : text;
    }

    private long asLong(Object value) {
        if (value == null) {
            return 0L;
        }
        if (value instanceof Number number) {
            return number.longValue();
        }
        try {
            return Long.parseLong(String.valueOf(value).trim());
        } catch (NumberFormatException ex) {
            return 0L;
        }
    }

    private String normalizeText(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    public int normalizePageSize(Integer pageSize) {
        if (pageSize == null || pageSize <= 0) {
            return 20;
        }
        return Math.min(pageSize, 100);
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private boolean isManagementUser(UserEntity user) {
        if ("super_admin".equals(user.getRole())) {
            return true;
        }
        List<String> permissions = getPermissionsByRole(user.getRole());
        return permissions.contains("review:read") || permissions.contains("post:update");
    }

    private record ModerationCheckResult(String riskLevel, List<String> hitWords) {
    }
}
