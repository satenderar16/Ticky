/// THIS OPTION ARE USED FOR BOTH THE CONTEST AND RESULT SECTION :
class Option {
  final String id;
  final String text;
  final bool? correct;
  final String? explanation;

  Option({
    required this.id,
    required this.text,
    this.correct,
    this.explanation,
  });

  /// Factory for submission JSON (only id and option are needed)
  factory Option.fromSubmitJson(Map<String, dynamic> data) {
    switch (data) {
      case {'id': final id, 'option': final text}:
        return Option(id: id, text: text);
      default:
        throw FormatException('Invalid submit JSON: $data');
    }
  }

  /// Factory for result JSON (all fields may be present)
  factory Option.fromResultJson(Map<String, dynamic> data) {
    switch (data) {
      // ensure the data
      case {
        'id': final id,
        'option': final text,
        'is_correct': final correct?,
        'explanation': final explanation?,
      }:
        return Option(
          id: id,
          text: text,
          correct: correct,
          explanation: explanation,
        );
      case {'id': final id, 'option': final text}:
        // Fallback if only partial data is present
        return Option(id: id, text: text);
      default:
        throw FormatException('Invalid result JSON: $data');
    }
  }

  /// Convert to JSON for submission
  Map<String, dynamic> toSubmitJson() => {'id': id, 'option': text};

  /// Convert to JSON for results (optional fields included)
  Map<String, dynamic> toResultJson() => {
    'id': id,
    'option': text,
    if (correct != null) 'is_correct': correct,
    if (explanation != null) 'explanation': explanation,
  };
}
