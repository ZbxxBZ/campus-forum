package org.example.project.controller;

import org.example.project.api.ApiResponse;
import org.example.project.exception.ApiException;
import org.example.project.service.ForumService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/uploads")
public class UploadController {
    private static final long DEFAULT_MAX_IMAGE_BYTES = 5L * 1024L * 1024L;

    private final ForumService forumService;
    private final Path imageUploadDir;
    private final long maxImageBytes;

    public UploadController(
            ForumService forumService,
            @Value("${app.upload.image-dir:uploads/images}") String imageUploadDir,
            @Value("${app.upload.max-image-size-bytes:5242880}") long maxImageBytes
    ) {
        this.forumService = forumService;
        this.imageUploadDir = Path.of(imageUploadDir).toAbsolutePath().normalize();
        this.maxImageBytes = maxImageBytes > 0 ? maxImageBytes : DEFAULT_MAX_IMAGE_BYTES;
    }

    @PostMapping("/images")
    public ApiResponse<Map<String, Object>> uploadImages(
            @RequestHeader("Authorization") String authorization,
            @RequestParam("files") MultipartFile[] files
    ) {
        forumService.getUserByToken(authorization);
        if (files == null || files.length == 0) {
            throw new ApiException("请选择要上传的图片");
        }
        List<Map<String, Object>> uploaded = new ArrayList<>();
        LocalDate now = LocalDate.now();
        String year = String.valueOf(now.getYear());
        String month = String.format("%02d", now.getMonthValue());
        Path relativeDir = Path.of(year, month);
        Path targetDir = imageUploadDir.resolve(relativeDir).normalize();
        if (!targetDir.startsWith(imageUploadDir)) {
            throw new ApiException("上传目录非法");
        }
        try {
            Files.createDirectories(targetDir);
            for (MultipartFile file : files) {
                if (file == null || file.isEmpty()) {
                    continue;
                }
                validateImageFile(file);
                String ext = detectExtension(file.getOriginalFilename(), file.getContentType());
                String savedName = UUID.randomUUID().toString().replace("-", "") + ext;
                Path savedPath = targetDir.resolve(savedName).normalize();
                if (!savedPath.startsWith(imageUploadDir)) {
                    throw new ApiException("上传文件名非法");
                }
                file.transferTo(savedPath);
                String relativeUrl = "/uploads/images/" + year + "/" + month + "/" + savedName;
                String url = ServletUriComponentsBuilder.fromCurrentContextPath()
                        .path(relativeUrl)
                        .toUriString();
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("url", url);
                item.put("name", StringUtils.hasText(file.getOriginalFilename()) ? file.getOriginalFilename() : savedName);
                item.put("size", file.getSize());
                item.put("contentType", file.getContentType());
                uploaded.add(item);
            }
        } catch (IOException ex) {
            throw new ApiException("图片上传失败");
        }
        if (uploaded.isEmpty()) {
            throw new ApiException("未检测到可上传图片");
        }
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("files", uploaded);
        return ApiResponse.ok(data);
    }

    private void validateImageFile(MultipartFile file) {
        if (file.getSize() > maxImageBytes) {
            throw new ApiException("单张图片大小不能超过 " + (maxImageBytes / 1024 / 1024) + "MB");
        }
        String contentType = file.getContentType();
        if (!StringUtils.hasText(contentType) || !contentType.toLowerCase(Locale.ROOT).startsWith("image/")) {
            throw new ApiException("仅支持图片文件上传");
        }
    }

    private String detectExtension(String originalName, String contentType) {
        if (StringUtils.hasText(originalName)) {
            String filename = StringUtils.getFilename(originalName);
            if (filename != null) {
                int dot = filename.lastIndexOf('.');
                if (dot >= 0 && dot < filename.length() - 1) {
                    String ext = filename.substring(dot).toLowerCase(Locale.ROOT);
                    if (ext.matches("\\.[a-z0-9]{1,10}")) {
                        return ext;
                    }
                }
            }   
        }
        if (StringUtils.hasText(contentType)) {
            return switch (contentType.toLowerCase(Locale.ROOT)) {
                case "image/jpeg", "image/jpg" -> ".jpg";
                case "image/png" -> ".png";
                case "image/gif" -> ".gif";
                case "image/webp" -> ".webp";
                case "image/bmp" -> ".bmp";
                default -> ".img";
            };
        }
        return ".img";
    }
}

