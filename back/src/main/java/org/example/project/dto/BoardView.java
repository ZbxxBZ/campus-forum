package org.example.project.dto;

import org.example.project.model.BoardEntity;

public record BoardView(
        Long id,
        String name,
        String code,
        String description,
        Integer sortOrder,
        String status,
        Integer postCount,
        String createdAt
) {
    public static BoardView from(BoardEntity board) {
        return new BoardView(
                board.getId(),
                board.getName(),
                board.getCode(),
                board.getDescription(),
                board.getSortOrder(),
                board.getStatus(),
                board.getPostCount(),
                board.getCreatedAt()
        );
    }
}
