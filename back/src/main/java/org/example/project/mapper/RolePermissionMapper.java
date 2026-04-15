package org.example.project.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.project.model.RolePermissionRow;

import java.util.List;

@Mapper
public interface RolePermissionMapper {
    List<String> findPermissionsByRole(@Param("role") String role);

    List<RolePermissionRow> listAll();

    int roleExists(@Param("role") String role);

    String findRoleLabel(@Param("role") String role);

    int deleteByRole(@Param("role") String role);

    int insertBatch(@Param("role") String role, @Param("roleLabel") String roleLabel, @Param("permissions") List<String> permissions);
}
