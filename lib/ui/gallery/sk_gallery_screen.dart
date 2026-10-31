import 'package:flutter/material.dart';
import 'package:prosoche/ui/components/sk_dialogs.dart';
import 'package:prosoche/ui/foundation/sk_text_scaling.dart';
import 'package:prosoche/ui/gallery/gallery_catalog.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';
import 'package:prosoche/ui/theme/sk_context.dart';
import 'package:prosoche/ui/tokens/sk_space.dart';

/// Dev obrazovka so vsetkymi komponentmi a stavmi (PLAN U-01 Vystupy).
///
/// Ma vlastnu temu (svetla/tmava, high contrast) a textScale. Nie je
/// urcena pre release (texty su EN placeholdery);
/// integracia ju pripoji len v dev flavore alebo debug route.
class SkGalleryScreen extends StatefulWidget {
  const SkGalleryScreen({super.key});

  @override
  State<SkGalleryScreen> createState() => _SkGalleryScreenState();
}

class _SkGalleryScreenState extends State<SkGalleryScreen> {
  bool _dark = false;
  bool _highContrast = false;
  double _textScale = 1;

  @override
  Widget build(BuildContext context) {
    final theme = _dark
        ? ProsocheTheme.dark(highContrast: _highContrast)
        : ProsocheTheme.light(highContrast: _highContrast);
    return Theme(
      data: theme,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(_textScale)),
        child: SkTextScaling(
          child: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Prosoche UI gallery'),
                actions: [
                  IconButton(
                    tooltip: 'Settings',
                    icon: const Icon(Icons.tune),
                    onPressed: () => _openSettings(context),
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: SkSpace.space16,
                ),
                children: [
                  for (final component in GalleryCatalog.components)
                    _Section(component: component),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) => showSkInfoSheet<void>(
    context,
    title: 'Gallery settings',
    closeLabel: 'Close',
    child: StatefulBuilder(
      builder: (context, setSheet) {
        void update(VoidCallback fn) {
          setState(fn);
          setSheet(() {});
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Dark theme'),
              value: _dark,
              onChanged: (v) => update(() => _dark = v),
            ),
            SwitchListTile(
              title: const Text('High contrast'),
              value: _highContrast,
              onChanged: (v) => update(() => _highContrast = v),
            ),
            const SizedBox(height: SkSpace.space8),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1.0')),
                ButtonSegment(value: 1.5, label: Text('1.5')),
                ButtonSegment(value: 2, label: Text('2.0')),
              ],
              selected: {_textScale},
              onSelectionChanged: (s) => update(() => _textScale = s.first),
            ),
          ],
        );
      },
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.component});

  final GalleryComponent component;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SkSpace.space16,
        vertical: SkSpace.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(component.name, style: sk.text.titleLarge),
          ),
          for (final entry in component.entries) ...[
            const SizedBox(height: SkSpace.space12),
            Text(entry.name, style: sk.text.bodySmall),
            const SizedBox(height: SkSpace.space4),
            Builder(builder: entry.builder),
          ],
          const SizedBox(height: SkSpace.space12),
          const Divider(),
        ],
      ),
    );
  }
}
