import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';
import 'package:share_plus/share_plus.dart';

/// Co sa zdiela z karty (docs/02 B0.7): plny arabsky text, preklad,
/// referencia (B0.4) a atribucia zdroja. Ziadne osobne udaje.
@immutable
final class CardShareData {
  const CardShareData({
    required this.reference,
    this.arabic,
    this.arabicIsQuran = false,
    this.translation,
    this.translationLang,
    this.attribution,
    this.source,
  });

  /// Arabsky text (Uthmani pri verse); null = karta bez arabciny.
  final String? arabic;
  final bool arabicIsQuran;
  final String? translation;

  /// Jazyk prekladu (smer textu na obrazku).
  final String? translationLang;

  /// Napr. "Al-Baqarah 2:255" alebo "Sahih al-Bukhari 1 · Grade: Sahih".
  final String reference;

  /// Zdroj prekladu, napr. "Translation: Saheeh International".
  final String? attribution;

  /// Atribucia zdroja s verziou (hadis: "Source: HadeethEnc.com ...,
  /// version ..."), docs/09.
  final String? source;
}

/// "Share as text" (docs/02 B0.7):
/// `{arabsky}\n\n{preklad}\n\n- {referencia} ({atribucia})\n{zdroj}\nvia Prosoche`.
String buildShareText(CardShareData data, {required String via}) {
  final ref = data.attribution == null
      ? '- ${data.reference}'
      : '- ${data.reference} (${data.attribution})';
  final footer = [ref, ?data.source, via].join('\n');
  return [?data.arabic, ?data.translation, footer].join('\n\n');
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

/// Rozmery obrazka (docs/02 B0.7): sirka 1080 px, 4:5 (1350 px) az do
/// 1080 x 1920. Logicke body pri sirke 360.
abstract final class ShareImageSize {
  static const logicalWidth = 360.0;
  static const minLogicalHeight = 450.0;
  static const maxLogicalHeight = 640.0;
  static const pixelRatio = 3.0;
}

/// Obsah obrazka: cely arabsky text (nikdy neorezany), preklad,
/// referencia, atribucia a znacka v paticke mimo textu.
///
/// D-05: list papiera (`surface`) s ramcekom na pozadi s geometrickym
/// vzorom. Vzor je len v okraji okolo listu, nikdy pod textom; atribucia
/// zdroja ostava citatelna (`textSecondary`).
class CardShareImage extends StatelessWidget {
  const CardShareImage({required this.data, required this.appName, super.key});

  final CardShareData data;
  final String appName;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    final arabic = data.arabic;
    final translation = data.translation;
    final meta = sk.text.bodySmall!.copyWith(color: c.textSecondary);
    return ColoredBox(
      color: c.bg,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: ShareImageSize.logicalWidth,
          maxWidth: ShareImageSize.logicalWidth,
          minHeight: ShareImageSize.minLogicalHeight,
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: SkPatternField(
                tile: 44,
                opacity: 0.5,
                fadeFrom: AlignmentDirectional.topCenter,
                fadeTo: AlignmentDirectional.bottomCenter,
                fadeStop: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                SkSpace.space8,
                SkSpace.space8,
                SkSpace.space8,
                0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(SkRadius.lg),
                    ),
                    child: CustomPaint(
                      painter: SkCardFramePainter(
                        color: c.goldDeco.withValues(alpha: 0.5),
                        inset: 6,
                        radius: SkRadius.lg - 6,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight:
                              ShareImageSize.minLogicalHeight -
                              SkSpace.space8 -
                              _footerHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: SkSpace.space16 + SkSpace.space4,
                            vertical: SkSpace.space16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                data.reference,
                                textAlign: TextAlign.center,
                                style: sk.text.labelLarge!.copyWith(
                                  color: c.accentText,
                                ),
                              ),
                              if (arabic != null && data.arabicIsQuran)
                                SkArabicText.quran([
                                  SkArabicSegment(arabic),
                                ], textSimple: arabic)
                              else if (arabic != null)
                                SkArabicText.text(arabic),
                              if (translation != null) ...[
                                const Padding(
                                  padding: EdgeInsetsDirectional.symmetric(
                                    vertical: SkSpace.space4,
                                  ),
                                  child: SkOrnamentDivider(width: 80),
                                ),
                                Directionality(
                                  textDirection: data.translationLang == null
                                      ? Directionality.of(context)
                                      : textDirectionForLanguage(
                                          data.translationLang!,
                                        ),
                                  child: Text(
                                    translation,
                                    style: sk.type.translation,
                                  ),
                                ),
                              ],
                              if (data.attribution != null ||
                                  data.source != null)
                                const SizedBox(height: SkSpace.space12),
                              if (data.attribution != null)
                                Text(data.attribution!, style: meta),
                              if (data.source != null)
                                Text(data.source!, style: meta),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: _footerHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SkRosette(
                          size: 16,
                          ring: false,
                          strokeWidth: 1,
                          color: c.goldDeco,
                        ),
                        const SizedBox(width: SkSpace.space8),
                        Text(
                          appName,
                          style: sk.text.labelLarge!.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Paticka so znackou pod listom.
  static const _footerHeight = 36.0;
}

/// Vyska plochy na meranie (obsah sa nikdy neorezava, len sa zmeria).
const _measureHeight = 100000.0;

/// Vyrenderuje [widget] mimo obrazovky do PNG (sirka [width], vyska podla
/// obsahu). Vrati null, ak by obrazok bol vyssi ako [maxHeight] - text sa
/// nikdy neoreze, ponukne sa zdielanie textom (docs/02 B0.7).
Future<Uint8List?> renderWidgetToPng(
  BuildContext context,
  Widget widget, {
  double width = ShareImageSize.logicalWidth,
  double maxHeight = ShareImageSize.maxLogicalHeight,
  double pixelRatio = ShareImageSize.pixelRatio,
}) async {
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
    if (boundary.size.height > maxHeight + 0.5) return null;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    RenderObjectToWidgetAdapter<RenderBox>(container: boundary)
        .attachToRenderTree(buildOwner, root);
    buildOwner.finalizeTree();
    focus.dispose();
  }
}
