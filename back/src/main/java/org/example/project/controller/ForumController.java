package org.example.project.controller;

import org.example.project.api.ApiResponse;
import org.example.project.dto.CommentView;
import org.example.project.dto.PostView;
import org.example.project.dto.request.CreateCommentRequest;
import org.example.project.dto.request.CreatePostRequest;
import org.example.project.dto.request.ReviewPostRequest;
import org.example.project.dto.request.UpdatePostRequest;
import org.example.project.model.PostEntity;
import org.example.project.service.ForumService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class ForumController {
    private final ForumService dataService;

    public ForumController(ForumService dataService) {
        this.dataService = dataService;
    }

    @GetMapping("/dashboard/stats")
    public ApiResponse<Map<String, Object>> dashboardStats(@RequestHeader("Authorization") String authorization) {
        dataService.getUserByToken(authorization);
        return ApiResponse.ok(dataService.getDashboardStats());
    }

    @PostMapping("/posts")
    public ApiResponse<Map<String, Object>> createPost(
            @RequestHeader("Authorization") String authorization,
            @RequestBody CreatePostRequest request
    ) {
        var user = dataService.requirePermission(authorization, "post:create");
        PostEntity post = dataService.createPost(request, user);
        Map<String, Object> data = new LinkedHashMap<>();

        PostView postView = dataService.toPostView(post);
        data.put("post", postView);

        // 如果帖子状态为pending且风险等级为medium，添加详细提示信息
        if ("pending".equals(post.getStatus()) && "medium".equals(post.getRiskLevel())) {
            Map<String, Object> moderationInfo = new LinkedHashMap<>();
            moderationInfo.put("message", "内容疑似违规，已提交审核，请等待管理员审核");
            moderationInfo.put("riskLevel", post.getRiskLevel());
            data.put("moderation", moderationInfo);
        }

        return ApiResponse.ok(data);
    }

    @PatchMapping("/posts/{postId}")
    public ApiResponse<Map<String, Object>> updatePost(
            @RequestHeader("Authorization") String authorization,
            @PathVariable Long postId,
            @RequestBody UpdatePostRequest request
    ) {
        var user = dataService.getUserByToken(authorization);
        PostEntity post = dataService.updatePost(postId, request, user);
        Map<String, Object> postData = new LinkedHashMap<>();
        postData.put("id", post.getId());
        postData.put("title", post.getTitle());
        postData.put("status", post.getStatus());
        postData.put("isTop", post.getIsTop());
        postData.put("isFeatured", post.getIsFeatured());
        postData.put("updatedAt", post.getUpdatedAt());
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("post", postData);
        return ApiResponse.ok(data);
    }

    @GetMapping("/posts")
    public ApiResponse<Map<String, Object>> posts(
            @RequestHeader("Authorization") String authorization,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String reviewStatus,
            @RequestParam(required = false) String auditStatus,
            @RequestParam(required = false) Long boardId,
            @RequestParam(required = false) String format,
            @RequestParam(required = false) String visibility,
            @RequestParam(required = false) Boolean mine,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "20") Integer pageSize
    ) {
        var user = dataService.getUserByToken(authorization);
        String normalizedStatus = firstNonBlank(status, reviewStatus, auditStatus);
        String author = null;
        if (Boolean.TRUE.equals(mine)) {
            author = user.getUsername();
        } else {
            dataService.requirePermission(authorization, "post:read");
        }
        int safePage = Math.max(page, 1);
        int safePageSize = dataService.normalizePageSize(pageSize);
        List<PostView> list = dataService.listPosts(keyword, normalizedStatus, boardId, format, visibility, author, safePage, safePageSize).stream()
                .map(dataService::toPostView)
                .toList();
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("list", list);
        data.put("total", dataService.countPosts(keyword, normalizedStatus, boardId, format, visibility, author));
        data.put("page", safePage);
        data.put("pageSize", safePageSize);
        return ApiResponse.ok(data);
    }

    @GetMapping("/posts/published")
    public ApiResponse<Map<String, Object>> publishedPosts(
            @RequestHeader("Authorization") String authorization,
            @RequestParam(required = false, defaultValue = "recommend") String feed,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String author,
            @RequestParam(required = false) String tag,
            @RequestParam(required = false) Long boardId,
            @RequestParam(required = false) String format,
            @RequestParam(required = false) String dateFrom,
            @RequestParam(required = false) String dateTo,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "20") Integer pageSize
    ) {
        var user = dataService.getUserByToken(authorization);
        int safePage = Math.max(page, 1);
        int safePageSize = dataService.normalizePageSize(pageSize);
        List<PostView> list = dataService.listPublishedPosts(
                        user.getId(), feed, keyword, author, tag, boardId, format, dateFrom, dateTo, safePage, safePageSize
                ).stream()
                .map(dataService::toPostView)
                .toList();
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("list", list);
        data.put("total", dataService.countPublishedPosts(user.getId(), feed, keyword, author, tag, boardId, format, dateFrom, dateTo));
        data.put("page", safePage);
        data.put("pageSize", safePageSize);
        return ApiResponse.ok(data);
    }

    @GetMapping("/posts/{postId:\\d+}")
    public ApiResponse<Map<String, Object>> postDetail(
            @RequestHeader("Authorization") String authorization,
            @PathVariable Long postId
    ) {
        var user = dataService.getUserByToken(authorization);
        PostEntity post = dataService.getPostDetail(postId, user);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("post", dataService.toPostView(post));
        return ApiResponse.ok(data);
    }

    @GetMapping("/posts/mine")
    public ApiResponse<Map<String, Object>> myPosts(
            @RequestHeader("Authorization") String authorization,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String reviewStatus,
            @RequestParam(required = false) String auditStatus,
            @RequestParam(required = false) Long boardId,
            @RequestParam(required = false) String format,
            @RequestParam(required = false) String visibility,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "20") Integer pageSize
    ) {
        var user = dataService.getUserByToken(authorization);
        int safePage = Math.max(page, 1);
        int safePageSize = dataService.normalizePageSize(pageSize);
        String normalizedStatus = firstNonBlank(status, reviewStatus, auditStatus);
        List<PostView> list = dataService.listPosts(
                        keyword, normalizedStatus, boardId, format, visibility, user.getUsername(), safePage, safePageSize
                ).stream()
                .map(dataService::toPostView)
                .toList();
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("list", list);
        data.put("total", dataService.countPosts(keyword, normalizedStatus, boardId, format, visibility, user.getUsername()));
        data.put("page", safePage);
        data.put("pageSize", safePageSize);
        return ApiResponse.ok(data);
    }

    @GetMapping("/posts/review/pending")
    public ApiResponse<Map<String, Object>> pendingReviewPosts(
            @RequestHeader("Authorization") String authorization,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Long boardId,
            @RequestParam(required = false) String format,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "20") Integer pageSize
    ) {
        dataService.requirePermission(authorization, "review:read");
        int safePage = Math.max(page, 1);
        int safePageSize = dataService.normalizePageSize(pageSize);
        List<PostView> list = dataService.listPendingReviewPosts(keyword, boardId, format, safePage, safePageSize).stream()
                .map(dataService::toPostView)
                .toList();
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("list", list);
        data.put("total", dataService.countPendingReviewPosts(keyword, boardId, format));
        data.put("page", safePage);
        data.put("pageSize", safePageSize);
        return ApiResponse.ok(data);
    }

    @PatchMapping("/posts/{postId}/review")
    public ApiResponse<Map<String, Object>> review(
            @RequestHeader("Authorization") String authorization,
            @PathVariable Long postId,
            @RequestBody ReviewPostRequest request
    ) {
        var user = dataService.requirePermission(authorization, "review:read");
        PostEntity post = dataService.reviewPost(postId, request.action(), user);
        Map<String, Object> postData = new LinkedHashMap<>();
        postData.put("id", post.getId());
        postData.put("status", post.getStatus());
        postData.put("riskLevel", post.getRiskLevel());
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("post", postData);
        return ApiResponse.ok(data);
    }

    @GetMapping("/posts/{postId}/interaction")
    public ApiResponse<Map<String, Object>> postInteraction(
            @RequestHeader("Authorization") String authorization,
            @PathVariable Long postId
    ) {
        var user = dataService.getUserByToken(authorization);
        return ApiResponse.ok(dataService.getPostInteraction(postId, user));
    }

    @PostMapping("/posts/{postId}/like")
    public ApiResponse<Map<String, Object>> togglePostLike(
            @RequestHeader("Authorization") String authorization,
            @PathVariable Long postId
    ) {
        var user = dataService.getUserByToken(authorization);
        return ApiResponse.ok(dataService.togglePostLike(postId, user));
    }

    @PostMapping("/posts/{postId}/favorite")
    public ApiResponse<Map<String, Object>> togglePostFavorite(
            @RequestHeader("Authorization") String authorization,
            @PathVariable Long postId
    ) {
        var user = dataService.getUserByToken(authorization);
        return ApiResponse.ok(dataService.togglePostFavorite(postId, user));
    }

    @GetMapping("/posts/{postId}/comments")
    public ApiResponse<Map<String, Object>> postComments(
            @RequestHeader("Authorization") String authorization,
            @PathVariable Long postId,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "20") Integer pageSize
    ) {
        var user = dataService.getUserByToken(authorization);
        int safePage = Math.max(page, 1);
        int safePageSize = dataService.normalizePageSize(pageSize);
        List<CommentView> list = dataService.listPostComments(postId, user, safePage, safePageSize);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("list", list);
        data.put("total", dataService.countPostComments(postId));
        data.put("page", safePage);
        data.put("pageSize", safePageSize);
        return ApiResponse.ok(data);
    }

    @PostMapping("/posts/{postId}/comments")
    public ApiResponse<Map<String, Object>> createPostComment(
            @RequestHeader("Authorization") String authorization,
            @PathVariable Long postId,
            @RequestBody CreateCommentRequest request
    ) {
        var user = dataService.getUserByToken(authorization);
        CommentView comment = dataService.createPostComment(postId, request, user);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("comment", comment);
        return ApiResponse.ok(data);
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value;
            }
        }
        return null;
    }
}
