package org.example.project.dto.request;

public record CreateBoardRequest(
        String name,
        String code,
        String description,
        Integer sortOrder,
        String status
) {
}
