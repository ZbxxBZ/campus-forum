package org.example.project.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.project.model.TopicOptionEntity;

import java.util.List;

@Mapper
public interface TopicOptionMapper {
    int insertBatch(@Param("topicId") Long topicId, @Param("options") List<String> options);

    TopicOptionEntity findById(@Param("id") Long id);

    List<TopicOptionEntity> listByTopicId(@Param("topicId") Long topicId);

    List<TopicOptionEntity> listByTopicIds(@Param("topicIds") List<Long> topicIds);

    int increaseVoteCount(@Param("optionId") Long optionId, @Param("delta") int delta);
}

