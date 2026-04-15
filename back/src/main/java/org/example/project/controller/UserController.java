package org.example.project.controller;

import org.example.project.api.ApiResponse;
import org.example.project.dto.UserView;
import org.example.project.dto.request.UpdateRoleRequest;
import org.example.project.dto.request.UpdateStatusRequest;
import org.example.project.model.UserEntity;
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
@RequestMapping("/api/v1/users")
public class UserController {
    private final ForumService dataService;

    public UserController(ForumService dataService) {
        this.dataService = dataService;
    }

    @GetMapping
    public ApiResponse<Map<String, Object>> listUsers(
            @RequestHeader("Authorization") String authorization,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String role,
            @RequestParam(required = false) String status
    ) {
        dataService.getUserByToken(authorization);
        List<UserView> list = dataService.listUsers(keyword, role, status).stream().map(UserView::from).toList();
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("list", list);
        data.put("total", dataService.countUsers(keyword, role, status));
        return ApiResponse.ok(data);
    }

    @PatchMapping("/{userId}/role")
    public ApiResponse<Map<String, Object>> updateRole(
            @RequestHeader("Authorization") String authorization,
            @PathVariable Long userId,
            @RequestBody UpdateRoleRequest request
    ) {
        dataService.getUserByToken(authorization);
        UserEntity user = dataService.updateUserRole(userId, request.role());
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("user", UserView.from(user));
        return ApiResponse.ok(data);
    }

    @PatchMapping("/{userId}/status")
    public ApiResponse<Map<String, Object>> updateStatus(
            @RequestHeader("Authorization") String authorization,
            @PathVariable Long userId,
            @RequestBody UpdateStatusRequest request
    ) {
        dataService.getUserByToken(authorization);
        UserEntity user = dataService.updateUserStatus(userId, request.status());
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("user", UserView.from(user));
        return ApiResponse.ok(data);
    }
}
