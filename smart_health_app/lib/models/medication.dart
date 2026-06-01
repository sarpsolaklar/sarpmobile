class Medication {
  final int? id;
  final String name;
  final String dosage;
  final String time; // e.g., '08:00 AM'
  final bool isDone;
  final bool notifyEnabled;

  Medication({
    this.id,
    required this.name,
    required this.dosage,
    required this.time,
    this.isDone = false,
    this.notifyEnabled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'dosage': dosage,
      'time': time,
      'isDone': isDone ? 1 : 0,
      'notifyEnabled': notifyEnabled ? 1 : 0,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      name: map['name'],
      dosage: map['dosage'],
      time: map['time'],
      isDone: map['isDone'] == 1,
      notifyEnabled: (map['notifyEnabled'] ?? 0) == 1,
    );
  }

  Medication copyWith({
    int? id,
    String? name,
    String? dosage,
    String? time,
    bool? isDone,
    bool? notifyEnabled,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
      isDone: isDone ?? this.isDone,
      notifyEnabled: notifyEnabled ?? this.notifyEnabled,
    );
  }
}
