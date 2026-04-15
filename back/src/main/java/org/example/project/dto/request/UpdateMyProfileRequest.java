package org.example.project.dto.request;

public record UpdateMyProfileRequest(
        String displayName,
        String avatar,
        String bio
) {
}

