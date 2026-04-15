package org.example.project.dto.request;

public record UpdateBoardRequest(
        String name,
        String code,
        String description,
        Integer sortOrder,
        String status
) {
}
