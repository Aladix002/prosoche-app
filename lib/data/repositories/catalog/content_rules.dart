import 'dart:convert';

/// JSON pole retazcov (`card.tags`); null alebo iny tvar = prazdne.
List<String> stringList(String? json) {
  if (json == null) return const [];
  try {
    return switch (jsonDecode(json)) {
      final List<Object?> l => [for (final v in l) ?(v is String ? v : null)],
      _ => const [],
    };
  } on FormatException {
    return const [];
  }
}
