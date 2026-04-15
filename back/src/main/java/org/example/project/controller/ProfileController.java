package org.example.project.controller;

import org.example.project.api.ApiResponse;
import org.example.project.dto.CommentView;
import org.example.project.dto.FollowUserView;
import org.example.project.dto.PostView;
import org.example.project.dto.request.UpdateMyProfileRequest;
import org.example.project.service.ForumService;
import org.springframework.web.bind.annotation.GetMapping;
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
@RequestMapping("/api/v1/profile")
public class ProfileController {
    private final ForumService forumService;

    public ProfileController(ForumService forumService) {
        this.forumService = forumService;
    }

    @GetMapping("/me")
    public ApiResponse<Map<String, Object>> me(@RequestHeader("Authorization") String authorization) {
        var user = forumService.getUserByToken(authorization);
        return ApiResponse.ok(forumService.getMyProfile(user));
    }

    @PatchMapping("/me")
    public ApiResponse<Map<String, Object>> updateMe(
            @RequestHeader("Authorization") String authorization,
            @RequestBody UpdateMyProfileRequest request
    ) {
        var user = forumService.getUserByToken(authorization);
        return ApiResponse.ok(forumService.updateMyProfile(user, request));
    }

    @GetMapping("/me/posts")
    public ApiResponse<Map<String, Object>> myPosts(
            @RequestHeader("Authorization") String authorization,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "20") Integer pageSize
    ) {
        var user = forumService.getUserByToken(authorization);
        int safePage = Math.max(page, 1);
        int safePageSize = forumService.normalizePageSize(pageSize);
        List<PostView> list = forumService.listMyProfilePosts(user, keyword, status, safePage, safePageSize);
        long total = forumService.countMyProfilePosts(user, keyword, status);
        return listData(list, total, safePage, safePageSize);
    }

    @GetMapping("/me/comments")
    public ApiResponse<Map<String, Object>> myComments(
            @RequestHeader("Authorization") String authorization,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "20") Integer pageSize
    ) {
        var user = forumService.getUserByToken(authorization);
        int safePage = Math.max(page, 1);
        int safePageSize = forumService.normalizePageSize(pageSize);
        List<CommentView> list = forumService.listMyComments(user, keyword, safePage, safePageSize);
        long total = forumService.countMyComments(user, keyword);
        return listData(list, total, safePage, safePageSize);
    }

    @GetMapping("/me/likes")
    public ApiResponse<Map<String, Object>> myLikes(
            @RequestHeader("Authorization") String authorization,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "20") Integer pageSize
    ) {
        var user = forumService.getUserByToken(authorization);
        int safePage = Math.max(page, 1);
        int safePageSize = forumService.normalizePageSize(pageSize);
        List<PostView> list = forumService.listMyLikedPosts(user, safePage, safePageSize);
        long total = forumService.countMyLikes(user);
        return listData(list, total, safePage, safePageSize);
    }

    @GetMapping("/me/favorites")
    public ApiResponse<Map<String, Object>> myFavorites(
            @RequestHeader("Authorization") String authorization,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "20") Integer pageSize
    ) {
        var user = forumService.getUserByToken(authorization);
        int safePage = Math.max(page, 1);
        int safePageSize = forumService.normalizePageSize(pageSize);
        List<PostView> list = forumService.listMyFavoritePosts(user, safePage, safePageSize);
        long total = forumService.countMyFavorites(user);
        return listData(list, total, safePage, safePageSize);
    }

    @GetMapping("/me/following")
    public ApiResponse<Map<String, Object>> myFollowing(
            @RequestHeader("Authorization") String authorization,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "20") Integer pageSize
    ) {
        var user = forumService.getUserByToken(authorization);
        int safePage = Math.max(page, 1);
        int safePageSize = forumService.normalizePageSize(pageSize);
        List<FollowUserView> list = forumService.listMyFollowing(user, keyword, safePage, safePageSize);
        long total = forumService.countMyFollowing(user, keyword);
        return listData(list, total, safePage, safePageSize);
    }

    @GetMapping("/users/{userId}")
    public ApiResponse<Map<String, Object>> userProfile(
            @RequestHeader("Authorization") String authorization,
            @PathVariable Long userId
    ) {
        forumService.getUserByToken(authorization);
        return ApiResponse.ok(forumService.getPublicProfile(userId));
    }

    private <T> ApiResponse<Map<String, Object>> listData(List<T> list, long total, int page, int pageSize) {
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("list", list);
        data.put("total", total);
        data.put("page", page);
        data.put("pageSize", pageSize);
        return ApiResponse.ok(data);
    }
}
