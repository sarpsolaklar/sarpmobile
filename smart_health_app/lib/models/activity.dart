class Activity {
  final int? id;
  final String date; // YYYY-MM-DD
  final int steps;
  final int caloriesBurned;
  final int exerciseMinutes;
  final String notes;

  const Activity({
    this.id,
    required this.date,
    required this.steps,
    required this.caloriesBurned,
    required this.exerciseMinutes,
    this.notes = '',
  });

  Activity copyWith({
    int? id,
    String? date,
    int? steps,
    int? caloriesBurned,
    int? exerciseMinutes,
    String? notes,
  }) =>
      Activity(
        id: id ?? this.id,
        date: date ?? this.date,
        steps: steps ?? this.steps,
        caloriesBurned: caloriesBurned ?? this.caloriesBurned,
        exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date,
        'steps': steps,
        'caloriesBurned': caloriesBurned,
        'exerciseMinutes': exerciseMinutes,
        'notes': notes,
      };

  factory Activity.fromMap(Map<String, dynamic> map) => Activity(
        id: map['id'] as int?,
        date: map['date'] as String,
        steps: map['steps'] as int,
        caloriesBurned: map['caloriesBurned'] as int,
        exerciseMinutes: map['exerciseMinutes'] as int,
        notes: map['notes'] as String? ?? '',
      );
}
