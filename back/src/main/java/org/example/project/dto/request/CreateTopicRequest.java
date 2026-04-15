package org.example.project.dto.request;

import java.util.List;

public record CreateTopicRequest(
        String title,
        String description,
        List<String> options,
        String createdBy
) {
}

