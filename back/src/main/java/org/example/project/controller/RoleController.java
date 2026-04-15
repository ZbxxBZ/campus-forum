package org.example.project.controller;

import org.example.project.api.ApiResponse;
import org.example.project.dto.request.UpdateRolePermissionsRequest;
import org.example.project.service.ForumService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/roles")
public class RoleController {
    private final ForumService dataService;

    public RoleController(ForumService dataService) {
        this.dataService = dataService;
    }

    @GetMapping
    public ApiResponse<Map<String, Object>> listRoles(@RequestHeader("Authorization") String authorization) {
        dataService.requirePermission(authorization, "role:read");
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("list", dataService.listRoles());
        return ApiResponse.ok(data);
    }

    @PutMapping("/{role}/permissions")
    public ApiResponse<Map<String, Object>> updatePermissions(
            @RequestHeader("Authorization") String authorization,
            @PathVariable String role,
            @RequestBody UpdateRolePermissionsRequest request
    ) {
        dataService.requirePermission(authorization, "role:update");
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("role", role);
        data.put("permissions", dataService.updateRolePermissions(role, request.permissions()));
        return ApiResponse.ok(data);
    }
}
