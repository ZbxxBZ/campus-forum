package org.example.project.dto;

import org.example.project.model.TopicEntity;

import java.util.List;

public record TopicView(
        Long id,
        String title,
        String description,
        String createdBy,
        String createdAt,
        List<TopicOptionView> options
) {
    public static TopicView from(TopicEntity topic, List<TopicOptionView> options) {
        return new TopicView(
                topic.getId(),
                topic.getTitle(),
                topic.getDescription(),
                topic.getCreatedByName(),
                topic.getCreatedAt(),
                options
        );
    }
}

