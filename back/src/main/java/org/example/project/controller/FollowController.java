package org.example.project.controller;

import org.example.project.api.ApiResponse;
import org.example.project.service.ForumService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/follows")
public class FollowController {
    private final ForumService forumService;

    public FollowController(ForumService forumService) {
        this.forumService = forumService;
    }

    @GetMapping("/relation")
    public ApiResponse<Map<String, Object>> relation(
            @RequestHeader("Authorization") String authorization,
            @RequestParam Long targetUserId
    ) {
        var user = forumService.getUserByToken(authorization);
        boolean followed = forumService.getFollowRelation(user, targetUserId);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("followed", followed);
        return ApiResponse.ok(data);
    }

    @PostMapping("/{targetUserId}/toggle")
    public ApiResponse<Map<String, Object>> toggle(
            @RequestHeader("Authorization") String authorization,
            @PathVariable Long targetUserId
    ) {
        var user = forumService.getUserByToken(authorization);
        boolean followed = forumService.toggleFollow(user, targetUserId);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("followed", followed);
        return ApiResponse.ok(data);
    }
}
