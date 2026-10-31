import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';
import 'package:share_plus/share_plus.dart';

/// Co sa zdiela z karty (docs/02 B0.7): cely text, referencia (B0.4)
/// a atribucia zdroja. Ziadne osobne udaje.
@immutable
final class CardShareData {
  const CardShareData({
    required this.reference,
    this.text,
    this.textLang,
    this.attribution,
    this.source,
  });

  /// Text karty (citat, uryvok).
  final String? text;

  /// Jazyk textu (smer textu na obrazku).
  final String? textLang;

  /// Napr. "Meditations 2.1".
  final String reference;

  /// Autor alebo prekladatel, napr. "Marcus Aurelius".
  final String? attribution;

  /// Atribucia zdroja s verziou (docs/09).
  final String? source;
}

/// "Share as text" (docs/02 B0.7):
/// `{text}\n\n- {referencia} ({atribucia})\n{zdroj}\nvia Prosoche`.
String buildShareText(CardShareData data, {required String via}) {
  final ref = data.attribution == null
      ? '- ${data.reference}'
      : '- ${data.reference} (${data.attribution})';
  final footer = [ref, ?data.source, via].join('\n');
  return [?data.text, footer].join('\n\n');
}

/// Zdielanie cez systemovy share sheet. V testoch sa prepise fake
/// implementaciou ([cardSharerProvider]).
abstract interface class CardSharer {
  Future<void> shareText(String text);

  /// PNG obrazok karty s textom ako fallback pre appky bez obrazkov.
  Future<void> shareImage(Uint8List png, {required String text});
}

class SharePlusCardSharer implements CardSharer {
  const SharePlusCardSharer();

  @override
  Future<void> shareText(String text) =>
      SharePlus.instance.share(ShareParams(text: text));

  @override
  Future<void> shareImage(Uint8List png, {required String text}) =>
      // `XFile.fromData` zapise docasny subor do cache, share_plus ho po
      // zdielani uprace (docs/02 B0.7).
      SharePlus.instance.share(
        ShareParams(
          text: text,
          files: [
            XFile.fromData(
              png,
              mimeType: 'image/png',
              name: 'prosoche_card.png',
            ),
          ],
        ),
      );
}

final Provider<CardSharer> cardSharerProvider = Provider<CardSharer>(
  (ref) => const SharePlusCardSharer(),
  name: 'cardSharerProvider',
);

/// Render karty do PNG (override v testoch).
typedef CardImageRenderer = Future<Uint8List?> Function(
  BuildContext context,
  Widget widget,
);

final Provider<CardImageRenderer> cardImageRendererProvider =
    Provider<CardImageRenderer>(
      (ref) => renderWidgetToPng,
      name: 'cardImageRendererProvider',
    );

/// Rozmery obrazka (docs/DESIGN.md 7.9): sirka 1080 px a dva formaty,
/// 4:5 (1080 x 1350) a 9:16 (1080 x 1920). Logicke body pri sirke 360.
abstract final class ShareImageSize {
  static const logicalWidth = 360.0;

  /// 4:5, default.
  static const minLogicalHeight = 450.0;

  /// 9:16 pre dlhsie texty; nad nim sa ponukne len zdielanie textom.
  static const maxLogicalHeight = 640.0;

  /// Povolene vysky; obrazok sa "prichyti" k najmensej, do ktorej sa
  /// obsah zmesti.
  static const List<double> heights = [minLogicalHeight, maxLogicalHeight];
  static const pixelRatio = 3.0;
}

/// Obsah obrazka (docs/DESIGN.md 7.9): meander v hornom a dolnom okraji,
/// referencia, cely text (nikdy neorezany, zarovnany na zaciatok),
/// atribucia a v paticke znacka. Ziadne fotky, filtre ani text
/// pouzivatela. Motiv je len v okrajoch, nikdy pod textom.
///
/// Bez pevnej vysky (meranie) ma prirodzenu vysku; s `minHeight`
/// z rodica (renderer prichyti 4:5 alebo 9:16) vyplni celu plochu.
class CardShareImage extends StatelessWidget {
  const CardShareImage({required this.data, required this.appName, super.key});

  final CardShareData data;
  final String appName;

  /// Od tejto dlzky sa text vysadza mensim stupnom (`passage`).
  static const longTextChars = 240;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    final text = data.text;
    final meta = sk.text.bodySmall!.copyWith(color: c.textSecondary);
    final textStyle = text != null && text.length > longTextChars
        ? sk.type.passage
        : sk.type.quote;
    final locale = Localizations.maybeLocaleOf(context);
    // Verzalky a rozostup len v latinke.
    final ltr = locale == null || !ProsocheLocales.isRtl(locale);
    final content = <Widget>[
      Text(
        ltr ? data.reference.toUpperCase() : data.reference,
        style: sk.type.eyebrow.copyWith(letterSpacing: ltr ? null : 0),
      ),
      if (text != null) ...[
        const SizedBox(height: SkSpace.space16),
        Directionality(
          textDirection: data.textLang == null
              ? Directionality.of(context)
              : textDirectionForLanguage(data.textLang!),
          child: Text(text, style: textStyle),
        ),
      ],
      if (data.attribution != null || data.source != null)
        const SizedBox(height: SkSpace.space16),
      if (data.attribution != null)
        Text(data.attribution!, style: sk.type.attribution),
      if (data.source != null) Text(data.source!, style: meta),
    ];
    final footer = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SkPortalMark(size: 16),
        const SizedBox(width: SkSpace.space8),
        Text(
          appName,
          style: sk.text.labelLarge!.copyWith(color: c.textSecondary),
        ),
      ],
    );
    const band = SkMeanderBand(opacity: 0.55);
    return ColoredBox(
      color: c.bg,
      child: SizedBox(
        width: ShareImageSize.logicalWidth,
        child: LayoutBuilder(
          builder: (context, box) {
            final fixed = box.minHeight > 0 && box.minHeight.isFinite;
            final body = Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: SkSpace.space32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: content,
              ),
            );
            final children = <Widget>[
              const SizedBox(height: SkSpace.space24),
              const Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: SkSpace.space24,
                ),
                child: band,
              ),
              const SizedBox(height: SkSpace.space32),
              if (fixed) const Spacer(),
              body,
              if (fixed) const Spacer(),
              const SizedBox(height: SkSpace.space32),
              const Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: SkSpace.space24,
                ),
                child: band,
              ),
              const SizedBox(height: SkSpace.space12),
              footer,
              const SizedBox(height: SkSpace.space16),
            ];
            final column = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: children,
            );
            return fixed
                ? SizedBox(height: box.minHeight, child: column)
                : column;
          },
        ),
      ),
    );
  }
}

/// Vyska plochy na meranie (obsah sa nikdy neorezava, len sa zmeria).
const _measureHeight = 100000.0;

/// Vyrenderuje [widget] mimo obrazovky do PNG (sirka [width], vyska podla
/// obsahu). Vrati null, ak by obrazok bol vyssi ako [maxHeight] - text sa
/// nikdy neoreze, ponukne sa zdielanie textom (docs/02 B0.7).
///
/// Vyska sa prichyti k najmensej z [heights], do ktorej sa obsah zmesti
/// (4:5, inak 9:16); widget dostane `minHeight` a vyplni ju.
Future<Uint8List?> renderWidgetToPng(
  BuildContext context,
  Widget widget, {
  double width = ShareImageSize.logicalWidth,
  double maxHeight = ShareImageSize.maxLogicalHeight,
  double pixelRatio = ShareImageSize.pixelRatio,
  List<double> heights = ShareImageSize.heights,
}) async {
  final natural = _layoutAndMeasure(context, widget, width: width);
  if (natural > maxHeight + 0.5) return null;
  final target = heights.firstWhere(
    (h) => h + 0.5 >= natural,
    orElse: () => natural,
  );
  return await _renderPng(
    context,
    ConstrainedBox(
      constraints: BoxConstraints(minHeight: target),
      child: widget,
    ),
    width: width,
    pixelRatio: pixelRatio,
  );
}

double _layoutAndMeasure(
  BuildContext context,
  Widget widget, {
  required double width,
}) {
  var height = 0.0;
  _withOffscreen(context, widget, width, (boundary) {
    height = boundary.size.height;
  });
  return height;
}

Future<Uint8List?> _renderPng(
  BuildContext context,
  Widget widget, {
  required double width,
  required double pixelRatio,
}) async {
  ui.Image? image;
  _withOffscreen(context, widget, width, (boundary) {
    image = boundary.toImageSync(pixelRatio: pixelRatio);
  });
  final img = image!;
  try {
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  } finally {
    img.dispose();
  }
}

/// Postavi a vykresli [widget] mimo obrazovky a zavola [use] s hranicou.
void _withOffscreen(
  BuildContext context,
  Widget widget,
  double width,
  void Function(RenderRepaintBoundary boundary) use,
) {
  final view = View.of(context);
  final wrapped = InheritedTheme.captureAll(
    context,
    MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.noScaling, size: Size(width, 4000)),
      child: Directionality(
        textDirection: Directionality.of(context),
        child: widget,
      ),
    ),
  );

  final boundary = RenderRepaintBoundary();
  final renderView = RenderView(
    view: view,
    child: RenderPositionedBox(alignment: Alignment.topCenter, child: boundary),
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tightFor(
        width: width,
        height: _measureHeight,
      ),
      physicalConstraints: BoxConstraints.tightFor(
        width: width,
        height: _measureHeight,
      ),
    ),
  );
  final pipeline = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();
  final focus = FocusManager();
  final buildOwner = BuildOwner(focusManager: focus);
  final root = RenderObjectToWidgetAdapter<RenderBox>(
    container: boundary,
    child: wrapped,
  ).attachToRenderTree(buildOwner);
  try {
    buildOwner
      ..buildScope(root)
      ..finalizeTree();
    pipeline
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();
    use(boundary);
  } finally {
    RenderObjectToWidgetAdapter<RenderBox>(container: boundary)
        .attachToRenderTree(buildOwner, root);
    buildOwner.finalizeTree();
    focus.dispose();
  }
}
