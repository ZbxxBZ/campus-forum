package org.example.project.controller;

import org.example.project.api.ApiResponse;
import org.example.project.dto.BoardView;
import org.example.project.dto.request.CreateBoardRequest;
import org.example.project.dto.request.UpdateBoardRequest;
import org.example.project.model.BoardEntity;
import org.example.project.service.ForumService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/boards")
public class BoardController {
    private final ForumService forumService;

    public BoardController(ForumService forumService) {
        this.forumService = forumService;
    }

    @GetMapping
    public ApiResponse<Map<String, Object>> listBoards(
            @RequestHeader("Authorization") String authorization,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String status
    ) {
        forumService.requirePermission(authorization, "board:read");
        List<BoardView> list = forumService.listBoards(keyword, status).stream()
                .map(forumService::toBoardView)
                .toList();
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("list", list);
        data.put("total", forumService.countBoards(keyword, status));
        return ApiResponse.ok(data);
    }

    @GetMapping("/available")
    public ApiResponse<Map<String, Object>> availableBoards(@RequestHeader("Authorization") String authorization) {
        forumService.requirePermission(authorization, "post:create");
        List<Map<String, Object>> list = forumService.listAvailableBoards().stream()
                .map(board -> {
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("id", board.getId());
                    item.put("name", board.getName());
                    return item;
                })
                .toList();
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("list", list);
        data.put("total", list.size());
        return ApiResponse.ok(data);
    }

    @PostMapping
    public ApiResponse<Map<String, Object>> createBoard(
            @RequestHeader("Authorization") String authorization,
            @RequestBody CreateBoardRequest request
    ) {
        forumService.requirePermission(authorization, "board:update");
        BoardEntity board = forumService.createBoard(request);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("board", forumService.toBoardView(board));
        return ApiResponse.ok(data);
    }

    @PatchMapping("/{boardId}")
    public ApiResponse<Map<String, Object>> updateBoard(
            @RequestHeader("Authorization") String authorization,
            @PathVariable Long boardId,
            @RequestBody UpdateBoardRequest request
    ) {
        forumService.requirePermission(authorization, "board:update");
        BoardEntity board = forumService.updateBoard(boardId, request);
        Map<String, Object> boardData = new LinkedHashMap<>();
        boardData.put("id", board.getId());
        boardData.put("name", board.getName());
        boardData.put("code", board.getCode());
        boardData.put("sortOrder", board.getSortOrder());
        boardData.put("status", board.getStatus());
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("board", boardData);
        return ApiResponse.ok(data);
    }
}
