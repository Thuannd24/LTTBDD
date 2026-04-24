package com.medbook.slotservice.service;

import com.medbook.slotservice.dto.response.AvailableSlotsResponse;
import java.time.Duration;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class SlotCacheService {

    private static final Duration CACHE_TTL = Duration.ofMinutes(5);
    private static final int DEFAULT_LIMIT = 5;

    private final RedisTemplate<String, Object> redisTemplate;

    public AvailableSlotsResponse getAvailableSlots(String cacheKey) {
        try {
            Object cached = redisTemplate.opsForValue().get(cacheKey);
            if (cached instanceof AvailableSlotsResponse response) {
                return response;
            }
        } catch (Exception ex) {
            log.warn("Redis read error for key={}: {}", cacheKey, ex.getMessage());
        }
        return null;
    }

    public void setAvailableSlots(String cacheKey, AvailableSlotsResponse response) {
        try {
            // Cache the full response so totalAvailable/hasMore stay correct on cache hit.
            redisTemplate.opsForValue().set(cacheKey, response, CACHE_TTL);
        } catch (Exception ex) {
            log.warn("Redis write error for key={}: {}", cacheKey, ex.getMessage());
        }
    }

    private void invalidateByPattern(String pattern) {
        try {
            Set<String> keys = redisTemplate.keys(pattern);
            if (keys != null && !keys.isEmpty()) {
                redisTemplate.delete(keys);
            }
        } catch (Exception ex) {
            log.warn("Redis invalidation error for pattern={}: {}", pattern, ex.getMessage());
        }
    }

    private int normalizeLimit(Integer limit) {
        return limit != null ? limit : DEFAULT_LIMIT;
    }
}
