class Option {
  final String id;
  final String text;

  Option({
    required this.id,
    required this.text,
  });

  // Factory method for JSON deserialization
  factory Option.fromJson(Map<String, dynamic> data) {
    return Option(
      id: data['id'] as String,
      text: data['option'] as String,
    );
  }

  // Method for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'option': text,
    };
  }
}
