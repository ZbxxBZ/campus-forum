package org.example.project.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.project.model.TopicEntity;

import java.util.List;

@Mapper
public interface TopicMapper {
    int insert(TopicEntity topic);

    TopicEntity findById(@Param("id") Long id);

    List<TopicEntity> list(
            @Param("keyword") String keyword,
            @Param("offset") int offset,
            @Param("pageSize") int pageSize
    );

    long count(@Param("keyword") String keyword);
}

