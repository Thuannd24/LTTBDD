package com.medbook.slotservice.service;

import com.medbook.slotservice.dto.request.EquipmentAvailabilityQuery;
import com.medbook.slotservice.dto.request.RoomAvailabilityQuery;
import com.medbook.slotservice.dto.response.AvailableSlotsResponse;
import com.medbook.slotservice.entity.enums.RoomCategory;
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

    private static final String ROOM_CACHE_PREFIX = "slot:rooms:";
    private static final String EQUIPMENT_CACHE_PREFIX = "slot:equipments:";
    private static final Duration CACHE_TTL = Duration.ofMinutes(5);
    private static final int DEFAULT_LIMIT = 5;

    private final RedisTemplate<String, Object> redisTemplate;

    public String buildRoomCacheKey(RoomAvailabilityQuery query) {
        // Different limits return different metadata, so limit must be part of the key.
        return ROOM_CACHE_PREFIX + query.getFacilityId() + ":" + query.getRoomCategory() + ":" + query.getDate() + ":"
                + normalizeLimit(query.getLimit());
    }

    public String buildEquipmentCacheKey(EquipmentAvailabilityQuery query) {
        StringBuilder builder = new StringBuilder(EQUIPMENT_CACHE_PREFIX)
                .append(query.getFacilityId())
                .append(":")
                .append(query.getRoomId())
                .append(":");
        builder.append(query.getEquipmentType() != null ? query.getEquipmentType() : "ALL");
        return builder.append(":")
                .append(query.getDate())
                .append(":")
                .append(normalizeLimit(query.getLimit()))
                .toString();
    }

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

    public void invalidateRoomAvailability(Long facilityId, RoomCategory roomCategory) {
        invalidateByPattern(ROOM_CACHE_PREFIX + facilityId + ":" + roomCategory + ":*");
    }

    public void invalidateEquipmentAvailability(Long facilityId, String roomId) {
        invalidateByPattern(EQUIPMENT_CACHE_PREFIX + facilityId + ":" + roomId + ":*");
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
