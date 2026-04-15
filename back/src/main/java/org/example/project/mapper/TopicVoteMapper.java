package org.example.project.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.project.model.TopicVoteEntity;

@Mapper
public interface TopicVoteMapper {
    TopicVoteEntity findByTopicAndUser(@Param("topicId") Long topicId, @Param("userId") Long userId);

    int insert(TopicVoteEntity vote);

    int updateOption(@Param("id") Long id, @Param("optionId") Long optionId);
}

