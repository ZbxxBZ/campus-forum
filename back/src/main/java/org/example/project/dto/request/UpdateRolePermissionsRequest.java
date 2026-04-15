package org.example.project.dto.request;

import java.util.List;

public record UpdateRolePermissionsRequest(List<String> permissions) {
}
