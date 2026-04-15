package org.example.project.dto;

import org.example.project.model.TopicOptionEntity;

public record TopicOptionView(
        Long id,
        String text,
        Integer voteCount
) {
    public static TopicOptionView from(TopicOptionEntity option) {
        return new TopicOptionView(
                option.getId(),
                option.getText(),
                option.getVoteCount() == null ? 0 : option.getVoteCount()
        );
    }
}

