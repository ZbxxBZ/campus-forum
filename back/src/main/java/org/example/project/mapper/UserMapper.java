package org.example.project.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.project.model.UserEntity;

import java.util.List;
import java.util.Map;

@Mapper
public interface UserMapper {
    int insert(UserEntity user);

    UserEntity findById(@Param("id") Long id);

    UserEntity findByUsername(@Param("username") String username);

    UserEntity findByEmail(@Param("email") String email);

    List<UserEntity> list(@Param("keyword") String keyword, @Param("role") String role, @Param("status") String status);

    long count(@Param("keyword") String keyword, @Param("role") String role, @Param("status") String status);

    int updateRole(@Param("userId") Long userId, @Param("role") String role);

    int updateStatus(@Param("userId") Long userId, @Param("status") String status);

    int updateDisplayName(@Param("userId") Long userId, @Param("displayName") String displayName);

    long countAll();

    List<Map<String, Object>> countRoleDistribution();
}
