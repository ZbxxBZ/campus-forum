package org.example.project.dto;

import java.util.List;

public record RolePermissionsView(
        String role,
        String roleLabel,
        List<String> permissions
) {
}
