package org.example.project.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.project.dto.TencentModerationResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.*;

@Service
@ConditionalOnProperty(name = "app.moderation.tencent.enabled", havingValue = "true")
public class TencentCloudModerationService {

    private static final Logger log = LoggerFactory.getLogger(TencentCloudModerationService.class);

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${app.moderation.tencent.secret-id}")
    private String secretId;

    @Value("${app.moderation.tencent.secret-key}")
    private String secretKey;

    @Value("${app.moderation.tencent.region}")
    private String region;

    @Value("${app.moderation.tencent.bucket}")
    private String bucket;

    @Value("${app.moderation.tencent.biz-type:}")
    private String bizType;

    private static final String SERVICE = "tms";
    private static final String HOST = "tms.tencentcloudapi.com";
    private static final String ENDPOINT = "https://" + HOST;
    private static final String ACTION = "TextModeration";
    private static final String VERSION = "2020-12-29";

    public TencentCloudModerationService(RestTemplate tencentRestTemplate) {
        this.restTemplate = tencentRestTemplate;
    }

    /**
     * 审核文本内容
     * @param text 待审核的文本
     * @return 审核结果
     */
    public TencentModerationResult moderateText(String text) {
        if (text == null || text.trim().isEmpty()) {
            return TencentModerationResult.success(0, "Normal", 0);
        }

        try {
            long startTime = System.currentTimeMillis();

            // Base64编码文本内容
            String content = Base64.getEncoder().encodeToString(text.getBytes(StandardCharsets.UTF_8));

            // 构建请求体
            Map<String, Object> requestBody = buildRequestBody(content);
            String requestBodyJson = objectMapper.writeValueAsString(requestBody);

            // 生成签名和请求头
            long timestamp = Instant.now().getEpochSecond();
            String authorization = generateAuthorization(requestBodyJson, timestamp);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", authorization);
            headers.set("X-TC-Action", ACTION);
            headers.set("X-TC-Version", VERSION);
            headers.set("X-TC-Timestamp", String.valueOf(timestamp));
            headers.set("X-TC-Region", region);

            HttpEntity<String> entity = new HttpEntity<>(requestBodyJson, headers);

            // 发送请求
            ResponseEntity<String> response = restTemplate.exchange(
                ENDPOINT,
                HttpMethod.POST,
                entity,
                String.class
            );

            long duration = System.currentTimeMillis() - startTime;
            log.debug("腾讯云审核API调用耗时: {}ms", duration);

            // 打印完整响应用于调试
            log.info("腾讯云API完整响应: {}", response.getBody());

            // 解析响应
            TencentModerationResult result = parseResponse(response.getBody());
            log.info("腾讯云审核结果: Result={}, Label={}, Score={}, Keywords={}",
                result.getResult(), result.getLabel(), result.getScore(), result.getKeywords());

            return result;

        } catch (Exception e) {
            log.error("腾讯云审核API调用失败，降级到本地审核", e);
            return TencentModerationResult.fallback();
        }
    }

    /**
     * 构建请求体
     */
    private Map<String, Object> buildRequestBody(String content) {
        Map<String, Object> body = new HashMap<>();
        body.put("Content", content);

        if (bizType != null && !bizType.trim().isEmpty()) {
            body.put("BizType", bizType.trim());
        }

        return body;
    }

    /**
     * 生成TC3-HMAC-SHA256签名
     */
    private String generateAuthorization(String requestBody, long timestamp) throws Exception {
        String date = Instant.ofEpochSecond(timestamp).toString().substring(0, 10);

        // 1. 拼接规范请求串
        String canonicalRequest = buildCanonicalRequest(requestBody);
        String hashedCanonicalRequest = sha256Hex(canonicalRequest);

        // 2. 拼接待签名字符串
        String credentialScope = date + "/" + SERVICE + "/tc3_request";
        String stringToSign = "TC3-HMAC-SHA256\n" + timestamp + "\n" + credentialScope + "\n" + hashedCanonicalRequest;

        // 3. 计算签名
        byte[] secretDate = hmacSHA256(("TC3" + secretKey).getBytes(StandardCharsets.UTF_8), date);
        byte[] secretService = hmacSHA256(secretDate, SERVICE);
        byte[] secretSigning = hmacSHA256(secretService, "tc3_request");
        String signature = bytesToHex(hmacSHA256(secretSigning, stringToSign));

        // 4. 拼接Authorization
        return "TC3-HMAC-SHA256 Credential=" + secretId + "/" + credentialScope +
               ", SignedHeaders=content-type;host, Signature=" + signature;
    }

    /**
     * 构建规范请求串
     */
    private String buildCanonicalRequest(String requestBody) throws Exception {
        String httpRequestMethod = "POST";
        String canonicalUri = "/";
        String canonicalQueryString = "";
        String canonicalHeaders = "content-type:application/json\nhost:" + HOST + "\n";
        String signedHeaders = "content-type;host";
        String hashedRequestPayload = sha256Hex(requestBody);

        return httpRequestMethod + "\n" +
               canonicalUri + "\n" +
               canonicalQueryString + "\n" +
               canonicalHeaders + "\n" +
               signedHeaders + "\n" +
               hashedRequestPayload;
    }

    /**
     * 解析响应
     */
    private TencentModerationResult parseResponse(String responseBody) throws Exception {
        JsonNode root = objectMapper.readTree(responseBody);
        JsonNode response = root.get("Response");

        // 检查是否有错误
        if (response.has("Error")) {
            String errorCode = response.get("Error").get("Code").asText();
            String errorMessage = response.get("Error").get("Message").asText();
            log.error("腾讯云审核API返回错误: Code={}, Message={}", errorCode, errorMessage);
            return TencentModerationResult.fallback();
        }

        // 解析审核结果
        String suggestionStr = response.has("Suggestion") ? response.get("Suggestion").asText() : "Pass";
        String label = response.has("Label") ? response.get("Label").asText() : "Normal";

        // 将字符串Suggestion转换为数字
        // Block=1(违规), Review=2(疑似), Pass=0(正常)
        Integer suggestion;
        switch (suggestionStr) {
            case "Block":
                suggestion = 1;
                break;
            case "Review":
                suggestion = 2;
                break;
            case "Pass":
            default:
                suggestion = 0;
                break;
        }

        // 获取详细分数
        Integer score = 0;
        if (response.has("DetailResults") && response.get("DetailResults").isArray()
            && response.get("DetailResults").size() > 0) {
            JsonNode firstDetail = response.get("DetailResults").get(0);
            if (firstDetail.has("Score")) {
                score = firstDetail.get("Score").asInt();
            }
        }

        // 提取关键词
        List<String> keywords = new ArrayList<>();
        if (response.has("Keywords") && response.get("Keywords").isArray()) {
            for (JsonNode keyword : response.get("Keywords")) {
                keywords.add(keyword.asText());
            }
        }

        TencentModerationResult result = TencentModerationResult.success(suggestion, label, score);
        result.setKeywords(keywords);

        return result;
    }

    /**
     * SHA256哈希
     */
    private String sha256Hex(String s) throws Exception {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] d = md.digest(s.getBytes(StandardCharsets.UTF_8));
        return bytesToHex(d);
    }

    /**
     * HMAC-SHA256
     */
    private byte[] hmacSHA256(byte[] key, String msg) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        SecretKeySpec secretKeySpec = new SecretKeySpec(key, "HmacSHA256");
        mac.init(secretKeySpec);
        return mac.doFinal(msg.getBytes(StandardCharsets.UTF_8));
    }

    /**
     * 字节数组转十六进制字符串
     */
    private String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }
}



