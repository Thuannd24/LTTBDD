import 'package:flutter/material.dart';
import 'package:tbdd/core/models/ai_suggestion_model.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';
import 'package:tbdd/features/user/ai_chat/data/ai_chat_service.dart';
import 'package:tbdd/features/user/appointment/screens/doctor_detail_screen.dart';

// ─── Data models cho chat ─────────────────────────────────────────────────────

enum _MessageType { user, ai, suggestion }

class _ChatMessage {
  final _MessageType type;
  final String? text;
  final AiSuggestion? suggestion;

  _ChatMessage.user(this.text)
      : type = _MessageType.user,
        suggestion = null;

  _ChatMessage.ai(this.text)
      : type = _MessageType.ai,
        suggestion = null;

  _ChatMessage.suggestion(this.suggestion)
      : type = _MessageType.suggestion,
        text = null;
}

// ─── Main Screen ─────────────────────────────────────────────────────────────

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final AiChatService _aiService = AiChatService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  // Gợi ý triệu chứng nhanh
  static const List<String> _quickPrompts = [
    '🤒 Tôi bị sốt cao và đau họng',
    '😣 Tôi bị đau bụng dữ dội',
    '💔 Tôi hay bị đau ngực khi gắng sức',
    '🦷 Tôi bị đau răng và sưng hàm',
    '👁️ Mắt tôi bị đỏ và chảy nước',
    '🦴 Tôi bị đau khớp gối khi leo cầu thang',
  ];

  @override
  void initState() {
    super.initState();
    // Tin nhắn chào mừng từ AI
    _messages.add(_ChatMessage.ai(
      'Xin chào! Tôi là trợ lý AI của MedBook. 🏥\n\n'
      'Hãy mô tả triệu chứng bạn đang gặp phải, tôi sẽ giúp bạn tìm chuyên khoa và bác sĩ phù hợp nhất.\n\n'
      '_Lưu ý: Tôi chỉ hỗ trợ gợi ý ban đầu, không thay thế chẩn đoán của bác sĩ._',
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _inputCtrl.clear();

    setState(() {
      _messages.add(_ChatMessage.user(trimmed));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final suggestion = await _aiService.suggestSpecialty(trimmed);
      if (!mounted) return;

      setState(() {
        _messages.add(_ChatMessage.ai(suggestion.aiMessage));
        _messages.add(_ChatMessage.suggestion(suggestion));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage.ai(
          '⚠️ Xin lỗi, tôi gặp sự cố kết nối. Vui lòng thử lại sau.\n\n_Chi tiết: ${e.toString().replaceAll('Exception: ', '')}_',
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_isLoading) _buildTypingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D3142), size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF38A3A5), Color(0xFF22577A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Tư vấn y tế',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3142),
                ),
              ),
              Text(
                'Gợi ý chuyên khoa & bác sĩ',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF38A3A5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Color(0xFF4CAF50), size: 8),
              SizedBox(width: 4),
              Text('AI Online', style: TextStyle(fontSize: 11, color: Color(0xFF38A3A5), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        switch (msg.type) {
          case _MessageType.user:
            return _UserBubble(text: msg.text!);
          case _MessageType.ai:
            return _AiBubble(text: msg.text!);
          case _MessageType.suggestion:
            return _SuggestionCard(
              suggestion: msg.suggestion!,
              onDoctorTap: (doctor) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctor: doctor)),
                );
              },
            );
        }
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          _AiAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                const SizedBox(width: 4),
                _TypingDot(delay: 200),
                const SizedBox(width: 4),
                _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Quick prompts
          if (_messages.length <= 1)
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: _quickPrompts.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _sendMessage(_quickPrompts[i].substring(3)),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38A3A5).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF38A3A5).withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        _quickPrompts[i],
                        style: const TextStyle(fontSize: 12, color: Color(0xFF38A3A5)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Input row
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: _inputCtrl,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142)),
                      decoration: const InputDecoration(
                        hintText: 'Mô tả triệu chứng của bạn...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _sendMessage(_inputCtrl.text),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38A3A5), Color(0xFF22577A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38A3A5).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chat Bubble Widgets ──────────────────────────────────────────────────────

class _AiAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF38A3A5), Color(0xFF22577A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 18),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final String text;
  const _AiBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AiAvatar(),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: _buildRichText(text),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildRichText(String text) {
    // Đơn giản render text, xử lý italic với _..._
    final parts = text.split('_');
    if (parts.length == 1) {
      return Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142), height: 1.5));
    }
    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          fontSize: 14,
          color: i % 2 == 1 ? Colors.grey[600] : const Color(0xFF2D3142),
          fontStyle: i % 2 == 1 ? FontStyle.italic : FontStyle.normal,
          height: 1.5,
        ),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 60),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF38A3A5), Color(0xFF22577A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Suggestion Card ──────────────────────────────────────────────────────────

class _SuggestionCard extends StatelessWidget {
  final AiSuggestion suggestion;
  final void Function(DoctorProfile) onDoctorTap;

  const _SuggestionCard({required this.suggestion, required this.onDoctorTap});

  Color get _urgencyColor {
    switch (suggestion.urgency) {
      case 'high':
        return const Color(0xFFE53935);
      case 'medium':
        return const Color(0xFFFF8F00);
      default:
        return const Color(0xFF43A047);
    }
  }

  String get _urgencyLabel {
    switch (suggestion.urgency) {
      case 'high':
        return '⚠️ Khẩn cấp';
      case 'medium':
        return '⏰ Nên khám sớm';
      default:
        return '✅ Không khẩn cấp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF38A3A5), Color(0xFF22577A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chuyên khoa gợi ý',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          suggestion.specialty.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _urgencyColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _urgencyColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      _urgencyLabel,
                      style: TextStyle(fontSize: 10, color: _urgencyColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Lý do gợi ý
            if (suggestion.reasoning.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38A3A5).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF38A3A5), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion.reasoning,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568), height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Danh sách bác sĩ
            if (suggestion.doctors.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Bác sĩ thuộc chuyên khoa này',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2D3142)),
                ),
              ),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  itemCount: suggestion.doctors.length,
                  itemBuilder: (_, i) => _DoctorMiniCard(
                    doctor: suggestion.doctors[i],
                    onTap: () => onDoctorTap(suggestion.doctors[i]),
                  ),
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  'Hiện chưa có bác sĩ trong chuyên khoa này.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DoctorMiniCard extends StatelessWidget {
  final DoctorProfile doctor;
  final VoidCallback onTap;

  const _DoctorMiniCard({required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF38A3A5).withOpacity(0.1),
              backgroundImage: doctor.avatar != null && doctor.avatar!.isNotEmpty
                  ? NetworkImage(doctor.avatar!)
                  : null,
              child: doctor.avatar == null || doctor.avatar!.isEmpty
                  ? const Icon(Icons.person_rounded, color: Color(0xFF38A3A5), size: 28)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              doctor.fullName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
            ),
            const SizedBox(height: 4),
            Text(
              '${doctor.experienceYears} năm KN',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF38A3A5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Xem chi tiết',
                style: TextStyle(fontSize: 10, color: Color(0xFF38A3A5), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Typing Animation Dot ─────────────────────────────────────────────────────

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF38A3A5),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
