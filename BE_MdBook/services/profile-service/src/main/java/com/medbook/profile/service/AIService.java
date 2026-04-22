package com.medbook.profile.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;
import java.util.*;

@Service
public class AIService {

    @Value("${app.openai.api-key:}")
    private String apiKey;

    private final RestTemplate restTemplate = new RestTemplate();

    public String generateSummary(String medicalHistory, String allergies) {
        if (apiKey == null || apiKey.isEmpty()) {
            return "AI Summary not available (Missing API Key)";
        }

        String url = "https://api.openai.com/v1/chat/completions";
        
        String prompt = String.format(
            "Tóm tắt hồ sơ y tế sau đây thành một bản tóm tắt ngắn gọn (dưới 100 từ) cho bác sĩ:\n" +
            "Tiền sử bệnh: %s\nDị ứng: %s", 
            medicalHistory, allergies
        );

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", "gpt-3.5-turbo");
        requestBody.put("messages", List.of(
            Map.of("role", "system", "content", "Bạn là một trợ lý y tế chuyên nghiệp."),
            Map.of("role", "user", "content", prompt)
        ));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        try {
            ResponseEntity<Map> response = restTemplate.postForEntity(url, entity, Map.class);
            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                List<Map> choices = (List<Map>) response.getBody().get("choices");
                Map message = (Map) choices.get(0).get("message");
                return (String) message.get("content");
            }
        } catch (Exception e) {
            return "Error generating summary: " + e.getMessage();
        }

        return "Failed to generate summary";
    }
}
