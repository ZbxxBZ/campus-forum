package org.example.project.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.project.model.UserProfileEntity;

@Mapper
public interface UserProfileMapper {
    UserProfileEntity findByUserId(@Param("userId") Long userId);

    int insert(UserProfileEntity profile);

    int update(UserProfileEntity profile);
}

