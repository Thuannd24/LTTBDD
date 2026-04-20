class Specialty {
  final String id;
  final String name;
  final String? description;
  final String? overview;
  final String? services;
  final String? technology;
  final String? image;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Specialty({
    required this.id,
    required this.name,
    this.description,
    this.overview,
    this.services,
    this.technology,
    this.image,
    this.createdAt,
    this.updatedAt,
  });

  factory Specialty.fromJson(Map<String, dynamic> json) {
    return Specialty(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      overview: json['overview'],
      services: json['services'],
      technology: json['technology'],
      image: json['image'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'overview': overview,
      'services': services,
      'technology': technology,
      'image': image,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
