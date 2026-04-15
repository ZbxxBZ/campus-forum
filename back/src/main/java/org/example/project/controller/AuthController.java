package org.example.project.controller;

import org.example.project.api.ApiResponse;
import org.example.project.dto.UserView;
import org.example.project.dto.request.LoginRequest;
import org.example.project.dto.request.RegisterRequest;
import org.example.project.model.UserEntity;
import org.example.project.service.ForumService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    private final ForumService dataService;

    public AuthController(ForumService dataService) {
        this.dataService = dataService;
    }

    @PostMapping("/register")
    public ApiResponse<Map<String, Object>> register(@RequestBody RegisterRequest request) {
        UserEntity user = dataService.register(request.username(), request.displayName(), request.email(), request.password());
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("user", UserView.from(user));
        return ApiResponse.ok(data);
    }

    @PostMapping("/login")
    public ApiResponse<Map<String, Object>> login(@RequestBody LoginRequest request) {
        String token = dataService.login(request.username(), request.password());
        UserEntity user = dataService.getUserByToken("Bearer " + token);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("token", token);
        data.put("user", UserView.from(user));
        data.put("permissions", dataService.getPermissionsByRole(user.getRole()));
        return ApiResponse.ok(data);
    }

    @GetMapping("/profile")
    public ApiResponse<Map<String, Object>> profile(@RequestHeader("Authorization") String authorization) {
        UserEntity user = dataService.getUserByToken(authorization);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("user", UserView.from(user));
        data.put("permissions", dataService.getPermissionsByRole(user.getRole()));
        return ApiResponse.ok(data);
    }
}
