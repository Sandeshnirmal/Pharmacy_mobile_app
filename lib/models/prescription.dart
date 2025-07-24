class Prescription {
  final int id;
  final String status;
  final DateTime uploadDate;
  final String? imageUrl;
  final List<Medicine> medicines;
  final double? aiConfidence;
  final String? notes;
  final String? pharmacistRemarks;
  final DateTime? reviewedAt;
  final int userId;

  Prescription({
    required this.id,
    required this.status,
    required this.uploadDate,
    this.imageUrl,
    required this.medicines,
    this.aiConfidence,
    this.notes,
    this.pharmacistRemarks,
    this.reviewedAt,
    required this.userId,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'pending',
      uploadDate: json['upload_date'] != null 
          ? DateTime.parse(json['upload_date'])
          : DateTime.now(),
      imageUrl: json['image_url'],
      medicines: json['medicines'] != null
          ? (json['medicines'] as List)
              .map((medicineJson) => Medicine.fromJson(medicineJson))
              .toList()
          : [],
      aiConfidence: json['ai_confidence']?.toDouble(),
      notes: json['notes'],
      pharmacistRemarks: json['pharmacist_remarks'],
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.parse(json['reviewed_at'])
          : null,
      userId: json['user_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'upload_date': uploadDate.toIso8601String(),
      'image_url': imageUrl,
      'medicines': medicines.map((medicine) => medicine.toJson()).toList(),
      'ai_confidence': aiConfidence,
      'notes': notes,
      'pharmacist_remarks': pharmacistRemarks,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'user_id': userId,
    };
  }

  Prescription copyWith({
    int? id,
    String? status,
    DateTime? uploadDate,
    String? imageUrl,
    List<Medicine>? medicines,
    double? aiConfidence,
    String? notes,
    String? pharmacistRemarks,
    DateTime? reviewedAt,
    int? userId,
  }) {
    return Prescription(
      id: id ?? this.id,
      status: status ?? this.status,
      uploadDate: uploadDate ?? this.uploadDate,
      imageUrl: imageUrl ?? this.imageUrl,
      medicines: medicines ?? this.medicines,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      notes: notes ?? this.notes,
      pharmacistRemarks: pharmacistRemarks ?? this.pharmacistRemarks,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'Prescription(id: $id, status: $status, medicines: ${medicines.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Prescription && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Medicine {
  final int id;
  final String name;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? instructions;
  final bool isGeneric;
  final double? confidence;

  Medicine({
    required this.id,
    required this.name,
    this.dosage,
    this.frequency,
    this.duration,
    this.instructions,
    this.isGeneric = false,
    this.confidence,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      dosage: json['dosage'],
      frequency: json['frequency'],
      duration: json['duration'],
      instructions: json['instructions'],
      isGeneric: json['is_generic'] ?? false,
      confidence: json['confidence']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
      'is_generic': isGeneric,
      'confidence': confidence,
    };
  }

  Medicine copyWith({
    int? id,
    String? name,
    String? dosage,
    String? frequency,
    String? duration,
    String? instructions,
    bool? isGeneric,
    double? confidence,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      instructions: instructions ?? this.instructions,
      isGeneric: isGeneric ?? this.isGeneric,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  String toString() {
    return 'Medicine(id: $id, name: $name, dosage: $dosage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Medicine && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
