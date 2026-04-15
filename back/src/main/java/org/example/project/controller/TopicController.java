package org.example.project.controller;

import org.example.project.api.ApiResponse;
import org.example.project.dto.TopicView;
import org.example.project.dto.request.CreateTopicRequest;
import org.example.project.dto.request.VoteTopicRequest;
import org.example.project.service.ForumService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/topics")
public class TopicController {
    private final ForumService forumService;

    public TopicController(ForumService forumService) {
        this.forumService = forumService;
    }

    @GetMapping
    public ApiResponse<Map<String, Object>> topics(
            @RequestHeader("Authorization") String authorization,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "20") Integer pageSize
    ) {
        forumService.getUserByToken(authorization);
        int safePage = Math.max(page, 1);
        int safePageSize = forumService.normalizePageSize(pageSize);
        List<TopicView> list = forumService.listTopics(keyword, safePage, safePageSize);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("list", list);
        data.put("total", forumService.countTopics(keyword));
        data.put("page", safePage);
        data.put("pageSize", safePageSize);
        return ApiResponse.ok(data);
    }

    @PostMapping
    public ApiResponse<Map<String, Object>> createTopic(
            @RequestHeader("Authorization") String authorization,
            @RequestBody CreateTopicRequest request
    ) {
        var user = forumService.requirePermission(authorization, "topic:create");
        TopicView topic = forumService.createTopic(request, user);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("topic", topic);
        return ApiResponse.ok(data);
    }

    @PostMapping("/{topicId}/vote")
    public ApiResponse<Map<String, Object>> voteTopic(
            @RequestHeader("Authorization") String authorization,
            @PathVariable Long topicId,
            @RequestBody VoteTopicRequest request
    ) {
        var user = forumService.getUserByToken(authorization);
        TopicView topic = forumService.voteTopic(topicId, request, user);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("topic", topic);
        return ApiResponse.ok(data);
    }
}
