package org.example.project.dto;

import java.util.List;

public class TencentModerationResult {
    private boolean success;        // API调用是否成功
    private boolean pass;           // 是否通过审核
    private String riskLevel;       // 风险等级: low/medium/high
    private String label;           // 违规标签: Normal/Porn/Ads/Illegal等
    private Integer score;          // 风险分数
    private Integer result;         // 审核结果: 0正常/1违规/2疑似
    private List<String> keywords;  // 命中的关键词
    private String suggestion;      // 建议操作
    private boolean fallback;       // 是否降级到本地审核

    public TencentModerationResult() {
    }

    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public boolean isPass() {
        return pass;
    }

    public void setPass(boolean pass) {
        this.pass = pass;
    }

    public String getRiskLevel() {
        return riskLevel;
    }

    public void setRiskLevel(String riskLevel) {
        this.riskLevel = riskLevel;
    }

    public String getLabel() {
        return label;
    }

    public void setLabel(String label) {
        this.label = label;
    }

    public Integer getScore() {
        return score;
    }

    public void setScore(Integer score) {
        this.score = score;
    }

    public Integer getResult() {
        return result;
    }

    public void setResult(Integer result) {
        this.result = result;
    }

    public List<String> getKeywords() {
        return keywords;
    }

    public void setKeywords(List<String> keywords) {
        this.keywords = keywords;
    }

    public String getSuggestion() {
        return suggestion;
    }

    public void setSuggestion(String suggestion) {
        this.suggestion = suggestion;
    }

    public boolean isFallback() {
        return fallback;
    }

    public void setFallback(boolean fallback) {
        this.fallback = fallback;
    }

    // 静态工厂方法：创建成功的审核结果
    public static TencentModerationResult success(Integer result, String label, Integer score) {
        TencentModerationResult dto = new TencentModerationResult();
        dto.setSuccess(true);
        dto.setFallback(false);
        dto.setResult(result);
        dto.setLabel(label);
        dto.setScore(score);

        // 根据result判断是否通过
        dto.setPass(result == 0);

        // 设置风险等级
        if (result == 0) {
            dto.setRiskLevel("low");
        } else if (result == 1) {
            dto.setRiskLevel("high");
        } else if (result == 2) {
            dto.setRiskLevel("medium");
        }

        return dto;
    }

    // 静态工厂方法：创建失败的审核结果（降级）
    public static TencentModerationResult fallback() {
        TencentModerationResult dto = new TencentModerationResult();
        dto.setSuccess(false);
        dto.setFallback(true);
        dto.setPass(false);
        return dto;
    }
}
