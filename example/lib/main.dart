import 'package:flutter/material.dart';
import 'package:tactile/tactile.dart';

void main() => runApp(const TactileGalleryApp());

class TactileGalleryApp extends StatelessWidget {
  const TactileGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tactile gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF7F5BFF),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0C0C10),
      ),
      home: const GalleryPage(),
    );
  }
}

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('tactile'),
            backgroundColor: Colors.transparent,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
            sliver: SliverList.list(
              children: const [
                _Intro(),
                SizedBox(height: 28),
                _WrapAnythingSection(),
                SizedBox(height: 36),
                _PresetsSection(),
                SizedBox(height: 36),
                _StyledSection(),
                SizedBox(height: 36),
                _TilesSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Press, hold, and drag your finger across anything below.',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.6),
        fontSize: 15,
      ),
    );
  }
}

/// Section 1 — the generic [Tactile] wrapper on many different widget types.
class _WrapAnythingSection extends StatelessWidget {
  const _WrapAnythingSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Wrap anything',
      subtitle: 'One Tactile() around any widget — no layout changes.',
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        alignment: WrapAlignment.center,
        children: [
          // Flutter logo.
          Tactile(onTap: () {}, tilt: 0.2, child: const FlutterLogo(size: 84)),
          // An icon in a colored circle.
          Tactile(
            onTap: () {},
            tilt: 0.25,
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFFB86B)],
                ),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 36),
            ),
          ),
          // An avatar.
          Tactile(
            onTap: () {},
            borderRadius: BorderRadius.circular(100),
            child: const CircleAvatar(
              radius: 42,
              backgroundColor: Color(0xFF49C6E5),
              child: Text(
                'MA',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // A faux photo (gradient + icon) with playful feel.
          Tactile.playful(
            borderRadius: BorderRadius.circular(20),
            onTap: () {},
            child: Container(
              width: 120,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7F5BFF), Color(0xFF49C6E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.photo_camera,
                color: Colors.white70,
                size: 34,
              ),
            ),
          ),
          // Plain emoji text.
          Tactile(
            tilt: 0.3,
            child: const Text('🍩', style: TextStyle(fontSize: 64)),
          ),
          // A Material chip.
          Tactile(
            onTap: () {},
            borderRadius: BorderRadius.circular(100),
            child: const Chip(
              avatar: Icon(Icons.bolt, size: 18, color: Color(0xFF7F5BFF)),
              label: Text('a chip'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section 2 — the same card with each preset, side by side.
class _PresetsSection extends StatelessWidget {
  const _PresetsSection();

  @override
  Widget build(BuildContext context) {
    Widget swatch(String label) => Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D2F45), Color(0xFF20222F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );

    return _Section(
      title: 'Presets',
      subtitle: 'subtle · default · playful — feel the difference.',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Tactile.subtle(
            borderRadius: BorderRadius.circular(22),
            onTap: () {},
            child: swatch('subtle'),
          ),
          Tactile(
            borderRadius: BorderRadius.circular(22),
            onTap: () {},
            child: swatch('default'),
          ),
          Tactile.playful(
            borderRadius: BorderRadius.circular(22),
            onTap: () {},
            child: swatch('playful'),
          ),
        ],
      ),
    );
  }
}

/// Section 3 — styled components that own their surface (shadow morph).
class _StyledSection extends StatelessWidget {
  const _StyledSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Styled components',
      subtitle:
          'They own their surface, so shadows morph from raised to flush.',
      child: Column(
        children: [
          // Light neumorphic panel — surface matches background.
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: const Color(0xFFE9ECF2),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TactileButton(
                      onTap: () {},
                      child: const Text(
                        'Press me',
                        style: TextStyle(
                          color: Color(0xFF2A2D34),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TactileButton(
                      onTap: () {},
                      style: const TactileStyle(
                        color: Color(0xFFE9ECF2),
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                        padding: EdgeInsets.all(18),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Color(0xFF7F5BFF),
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // A colored card where glare reads as a specular sheen.
          TactileCard(
            onTap: () {},
            style: TactileStyle(
              gradient: const LinearGradient(
                colors: [Color(0xFF7F5BFF), Color(0xFF5B7BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              color: const Color(0xFF5B6BFF),
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.all(22),
              tilt: 0.2,
              glareIntensity: 0.32,
            ),
            child: const Row(
              children: [
                Icon(Icons.style, color: Colors.white, size: 30),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'TactileCard with a glossy surface — drag to catch the light.',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section 4 — a list of tactile rows.
class _TilesSection extends StatelessWidget {
  const _TilesSection();

  static const _items = [
    (Icons.wifi, 'Wi-Fi', 'Home network'),
    (Icons.bluetooth, 'Bluetooth', 'On'),
    (Icons.notifications, 'Notifications', 'Badges, sounds'),
    (Icons.lock, 'Privacy & Security', 'Manage access'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'List rows',
      subtitle: 'TactileTile — a restrained press for dense lists.',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE9ECF2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            for (final (icon, title, subtitle) in _items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: TactileTile(
                  onTap: () {},
                  leading: Icon(icon, color: const Color(0xFF7F5BFF)),
                  title: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF2A2D34),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B6F78),
                      fontSize: 13,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF9AA0AA),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A labeled section wrapper.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}
