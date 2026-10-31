/// Ukazkove texty pre galeriu a goldeny. Len placeholdery, ziadny obsah
/// (PLAN_VYVOJA 5.5 bod 1).
abstract final class GallerySamples {
  /// Kratky text v hlavnom bloku karty.
  static const lead = '[PLACEHOLDER quote] The sample line in the lead block.';

  /// Dlhsi text na overenie zalamovania.
  static const translation =
      '[PLACEHOLDER text] This sentence only shows how a longer text wraps '
      'on a card. It carries no meaning and is not a quote.';

  static const attribution = '[PLACEHOLDER] Author, tr. Sample';

  /// Kratky citat (dlzka ako typicky citat na karte).
  static const quote =
      '[PLACEHOLDER quote] Nowhere does a person retire with more quiet '
      'than into the sample sentence of the gallery.';

  /// Dlhsi uryvok.
  static const passage =
      '[PLACEHOLDER passage] Begin the sample by saying to yourself: this '
      'paragraph only shows how a longer passage wraps on a card, in the '
      'reader and on a shared image. It carries no meaning and is not a '
      'quote from any work.';

  /// Otazka na zamyslenie.
  static const prompt =
      '[PLACEHOLDER prompt] What is in my control in the sample today?';
}
