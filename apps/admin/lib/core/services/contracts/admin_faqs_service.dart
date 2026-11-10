/// Một câu FAQ chatbot dùng để trả lời chính sách cửa hàng.
class AdminFaq {
  const AdminFaq({
    required this.id,
    required this.topic,
    required this.answer,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String topic;
  final String answer;
  final int sortOrder;
  final bool isActive;

  factory AdminFaq.fromJson(Map<String, dynamic> json) => AdminFaq(
        id: json['id'] as String,
        topic: json['topic'] as String,
        answer: json['answer'] as String,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toBody() => {
        'topic': topic,
        'answer': answer,
        'sortOrder': sortOrder,
        'isActive': isActive,
      };
}

abstract class AdminFaqsService {
  Future<List<AdminFaq>> getFaqs();

  /// [faq.id] bị bỏ qua khi tạo mới.
  Future<AdminFaq> createFaq(AdminFaq faq);

  Future<AdminFaq> updateFaq(AdminFaq faq);

  Future<void> deleteFaq(String id);
}
