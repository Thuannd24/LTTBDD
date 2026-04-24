const OpenAI = require('openai');
const config = require('../utils/appConfig');
const { httpRequest } = require('../utils/httpClient');
const logger = require('../utils/logger');

// Khởi tạo OpenAI client (lazy)
let _openaiClient = null;
function getOpenAI() {
  if (!_openaiClient) {
    _openaiClient = new OpenAI({ apiKey: config.ai.openAiApiKey });
  }
  return _openaiClient;
}

// ─── Fetch data từ doctor-service ────────────────────────────────────────────

async function fetchAllSpecialties(correlationId) {
  const url = `${config.ai.doctorServiceUrl}/specialties`;
  const response = await httpRequest(url, {
    headers: {
      accept: 'application/json',
      'x-correlation-id': correlationId || '',
    },
  });

  if (!response.ok) {
    logger.warn('ai_fetch_specialties_failed', { url, status: response.status, correlationId });
    return [];
  }

  // doctor-service trả về { result: [...] } hoặc { data: [...] }
  const body = response.body;
  return body?.result || body?.data || (Array.isArray(body) ? body : []);
}

async function fetchDoctorsBySpecialty(specialtyId, correlationId) {
  const url = `${config.ai.doctorServiceUrl}/doctors?specialtyId=${encodeURIComponent(specialtyId)}`;
  const response = await httpRequest(url, {
    headers: {
      accept: 'application/json',
      'x-correlation-id': correlationId || '',
    },
  });

  if (!response.ok) {
    logger.warn('ai_fetch_doctors_failed', { url, status: response.status, correlationId });
    return [];
  }

  const body = response.body;
  return body?.result || body?.data || (Array.isArray(body) ? body : []);
}

// ─── Build system prompt ──────────────────────────────────────────────────────

function buildSystemPrompt(specialties) {
  const specialtyList = specialties
    .map((s, i) => `${i + 1}. ID: "${s.id}" | Tên: "${s.name}" | Mô tả: "${s.description || ''}"`)
    .join('\n');

  return `Bạn là trợ lý y tế AI của hệ thống MedBook. Nhiệm vụ của bạn là phân tích triệu chứng bệnh nhân mô tả và gợi ý chuyên khoa y tế phù hợp nhất.

DANH SÁCH CHUYÊN KHOA HIỆN CÓ:
${specialtyList}

YÊU CẦU TRẢ LỜI (BẮT BUỘC theo format JSON sau, KHÔNG thêm bất kỳ text nào ngoài JSON):
{
  "specialtyId": "<ID của chuyên khoa phù hợp nhất từ danh sách trên>",
  "specialtyName": "<Tên chuyên khoa>",
  "reasoning": "<Giải thích ngắn gọn bằng tiếng Việt tại sao gợi ý chuyên khoa này (2-3 câu)>",
  "aiMessage": "<Lời nhắn thân thiện gửi đến bệnh nhân bằng tiếng Việt, bao gồm: xác nhận triệu chứng, gợi ý chuyên khoa và lời khuyên sơ bộ (3-4 câu)>",
  "urgency": "<'low' | 'medium' | 'high' — mức độ khẩn cấp>"
}

LƯU Ý QUAN TRỌNG:
- Chỉ chọn specialtyId từ danh sách đã cung cấp
- Nếu không có chuyên khoa phù hợp, chọn chuyên khoa gần nhất
- KHÔNG đưa ra chẩn đoán bệnh cụ thể, chỉ gợi ý chuyên khoa
- Luôn khuyến khích bệnh nhân gặp bác sĩ để được khám trực tiếp
- Trả lời hoàn toàn bằng tiếng Việt`;
}

// ─── Main AI suggestion function ─────────────────────────────────────────────

async function getAiSuggestion({ userMessage, correlationId }) {
  if (!userMessage || !String(userMessage).trim()) {
    throw Object.assign(new Error('userMessage is required'), { status: 400 });
  }

  if (!config.ai.openAiApiKey) {
    throw Object.assign(new Error('AI service is not configured'), { status: 503 });
  }

  // 1. Fetch tất cả chuyên khoa
  const specialties = await fetchAllSpecialties(correlationId);
  if (!specialties.length) {
    throw Object.assign(new Error('No specialties available'), { status: 503 });
  }

  logger.info('ai_suggestion_requested', {
    correlationId,
    specialtyCount: specialties.length,
    messageLength: userMessage.length,
  });

  // 2. Gọi OpenAI
  const openai = getOpenAI();
  const completion = await openai.chat.completions.create({
    model: config.ai.openAiModel,
    messages: [
      { role: 'system', content: buildSystemPrompt(specialties) },
      { role: 'user', content: String(userMessage).trim() },
    ],
    temperature: 0.3,
    max_tokens: 600,
    response_format: { type: 'json_object' },
  });

  const rawContent = completion.choices[0]?.message?.content || '{}';

  let parsed;
  try {
    parsed = JSON.parse(rawContent);
  } catch (_) {
    logger.error('ai_response_parse_failed', { correlationId, rawContent });
    throw Object.assign(new Error('AI response could not be parsed'), { status: 502 });
  }

  const { specialtyId, specialtyName, reasoning, aiMessage, urgency } = parsed;

  if (!specialtyId) {
    throw Object.assign(new Error('AI did not return a valid specialtyId'), { status: 502 });
  }

  logger.info('ai_suggestion_completed', {
    correlationId,
    specialtyId,
    urgency,
  });

  // 3. Fetch bác sĩ của chuyên khoa được gợi ý
  const doctors = await fetchDoctorsBySpecialty(specialtyId, correlationId);

  // 4. Tìm thông tin đầy đủ của chuyên khoa
  const specialty = specialties.find((s) => s.id === specialtyId) || {
    id: specialtyId,
    name: specialtyName || '',
  };

  return {
    specialty,
    doctors: doctors.slice(0, 5), // Tối đa 5 bác sĩ
    reasoning: reasoning || '',
    aiMessage: aiMessage || `Dựa trên triệu chứng bạn mô tả, tôi gợi ý bạn nên thăm khám tại khoa ${specialtyName}.`,
    urgency: urgency || 'medium',
  };
}

module.exports = { getAiSuggestion };
