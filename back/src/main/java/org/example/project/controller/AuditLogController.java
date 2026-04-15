package org.example.project.controller;

import org.example.project.api.ApiResponse;
import org.example.project.dto.AuditLogView;
import org.example.project.service.ForumService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/audit")
public class AuditLogController {
    private final ForumService forumService;

    public AuditLogController(ForumService forumService) {
        this.forumService = forumService;
    }

    @GetMapping("/logs")
    public ApiResponse<Map<String, Object>> listLogs(
            @RequestHeader("Authorization") String authorization,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String action,
            @RequestParam(required = false) String role,
            @RequestParam(required = false) String operator,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "20") Integer pageSize
    ) {
        forumService.requirePermission(authorization, "auditlog:read");
        int safePage = Math.max(page, 1);
        int safePageSize = forumService.normalizePageSize(pageSize);
        List<AuditLogView> list = forumService.listAuditLogs(keyword, action, role, operator, safePage, safePageSize);
        long total = forumService.countAuditLogs(keyword, action, role, operator);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("list", list);
        data.put("total", total);
        data.put("page", safePage);
        data.put("pageSize", safePageSize);
        return ApiResponse.ok(data);
    }
}
