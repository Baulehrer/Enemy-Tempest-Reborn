part of 'main.dart';

class LauncherView extends StatefulWidget {
  const LauncherView({
    super.key,
    required this.selectedKind,
    required this.selected,
    required this.language,
    required this.status,
    required this.busy,
    required this.display,
    required this.aspect,
    required this.pixels,
    required this.control,
    required this.showLaunchSplash,
    required this.launchSplashAsset,
    required this.onTargetChanged,
    required this.onLanguageChanged,
    required this.onDisplayChanged,
    required this.onAspectChanged,
    required this.onPixelsChanged,
    required this.onControlChanged,
    required this.onLaunch,
    required this.onMaps,
    required this.onAbout,
  });

  final TargetKind selectedKind;
  final LauncherTarget selected;
  final LanguageChoice language;
  final String status;
  final bool busy;
  final String display;
  final String aspect;
  final String pixels;
  final String control;
  final bool showLaunchSplash;
  final String launchSplashAsset;
  final ValueChanged<TargetKind> onTargetChanged;
  final ValueChanged<LanguageChoice> onLanguageChanged;
  final ValueChanged<String> onDisplayChanged;
  final ValueChanged<String> onAspectChanged;
  final ValueChanged<String> onPixelsChanged;
  final ValueChanged<String> onControlChanged;
  final VoidCallback onLaunch;
  final VoidCallback onMaps;
  final VoidCallback onAbout;

  @override
  State<LauncherView> createState() => _LauncherViewState();
}

class _LauncherViewState extends State<LauncherView> {
  bool _settingsOpen = false;

  bool get _english => widget.language == LanguageChoice.en;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _Atmosphere()),
          SafeArea(
            child: Column(
              children: [
                _Masthead(
                  language: widget.language,
                  onLanguageChanged: widget.onLanguageChanged,
                  onMaps: widget.onMaps,
                  onAbout: widget.onAbout,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 1100;
                      final compact = constraints.maxWidth < 720;
                      final horizontalPadding = compact ? 16.0 : 28.0;
                      final selector = _GameSelector(
                        selected: widget.selectedKind,
                        compact: !wide,
                        onChanged: widget.onTargetChanged,
                      );
                      final content = _LaunchDeck(
                        selected: widget.selected,
                        selectedKind: widget.selectedKind,
                        english: _english,
                        status: widget.status,
                        busy: widget.busy,
                        display: widget.display,
                        aspect: widget.aspect,
                        pixels: widget.pixels,
                        control: widget.control,
                        settingsOpen: _settingsOpen,
                        onSettingsToggle: () =>
                            setState(() => _settingsOpen = !_settingsOpen),
                        onDisplayChanged: widget.onDisplayChanged,
                        onAspectChanged: widget.onAspectChanged,
                        onPixelsChanged: widget.onPixelsChanged,
                        onControlChanged: widget.onControlChanged,
                        onLaunch: widget.onLaunch,
                      );

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          compact ? 18 : 26,
                          horizontalPadding,
                          34,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1380),
                            child: wide
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 280, child: selector),
                                      const SizedBox(width: 34),
                                      Expanded(child: content),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      selector,
                                      SizedBox(height: compact ? 18 : 26),
                                      content,
                                    ],
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (widget.showLaunchSplash)
            Positioned.fill(
              child: _NewLaunchSplash(
                asset: widget.launchSplashAsset,
                english: _english,
              ),
            ),
        ],
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead({
    required this.language,
    required this.onLanguageChanged,
    required this.onMaps,
    required this.onAbout,
  });

  final LanguageChoice language;
  final ValueChanged<LanguageChoice> onLanguageChanged;
  final VoidCallback onMaps;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    final english = language == LanguageChoice.en;
    final text = AppText(english);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return Container(
          height: compact ? 104 : 132,
          decoration: const BoxDecoration(
            color: SiteColors.panelDark,
            border: Border(
              bottom: BorderSide(color: SiteColors.enemyRed, width: 2),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.46,
                  child: Image.asset(
                    'assets/images/streifen.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (!compact)
                Positioned(
                  left: 0,
                  bottom: 0,
                  top: 0,
                  child: Image.asset(
                    'assets/images/alien.png',
                    width: 230,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomLeft,
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        SiteColors.panelDark.withValues(alpha: 0.15),
                        SiteColors.panelDark.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 16 : 28,
                  vertical: compact ? 12 : 18,
                ),
                child: Row(
                  children: [
                    if (!compact) const SizedBox(width: 190),
                    Image.asset(
                      'assets/images/anachronia.png',
                      width: compact ? 150 : 224,
                      fit: BoxFit.contain,
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 22),
                      Container(width: 1, height: 45, color: SiteColors.line),
                      const SizedBox(width: 22),
                      const Expanded(
                        child: Text(
                          'ENEMY: TEMPEST REBORN',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SiteColors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.4,
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    _HeaderAction(
                      icon: Icons.map_outlined,
                      tooltip: text.levelMaps,
                      onPressed: onMaps,
                    ),
                    const SizedBox(width: 6),
                    _HeaderAction(
                      icon: Icons.info_outline,
                      tooltip: text.about,
                      onPressed: onAbout,
                    ),
                    const SizedBox(width: 10),
                    _LanguageSwitch(
                      language: language,
                      onChanged: onLanguageChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      color: SiteColors.text,
      focusColor: SiteColors.signalYellow,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(44),
        side: const BorderSide(color: SiteColors.lineSoft),
        shape: const RoundedRectangleBorder(),
      ),
    );
  }
}

class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch({required this.language, required this.onChanged});

  final LanguageChoice language;
  final ValueChanged<LanguageChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: language == LanguageChoice.de ? 'Sprache' : 'Language',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageButton(
            label: 'DE',
            selected: language == LanguageChoice.de,
            onPressed: () => onChanged(LanguageChoice.de),
          ),
          _LanguageButton(
            label: 'EN',
            selected: language == LanguageChoice.en,
            onPressed: () => onChanged(LanguageChoice.en),
          ),
        ],
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: selected ? SiteColors.voidBlack : SiteColors.text,
          backgroundColor: selected
              ? SiteColors.signalYellow
              : SiteColors.panel,
          shape: const RoundedRectangleBorder(),
          side: BorderSide(
            color: selected ? SiteColors.signalYellow : SiteColors.lineSoft,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
      ),
    );
  }
}

class _GameSelector extends StatelessWidget {
  const _GameSelector({
    required this.selected,
    required this.compact,
    required this.onChanged,
  });

  final TargetKind selected;
  final bool compact;
  final ValueChanged<TargetKind> onChanged;

  @override
  Widget build(BuildContext context) {
    const entries = [
      (TargetKind.intro, 'INTRO', 'ENEMY 1'),
      (TargetKind.enemy1, 'ENEMY 1', 'TEMPEST OF VIOLENCE'),
      (TargetKind.enemy2, 'ENEMY 2', 'MISSING IN ACTION'),
    ];
    if (compact) {
      return Row(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            Expanded(
              child: _GameButton(
                title: entries[i].$2,
                subtitle: entries[i].$3,
                selected: selected == entries[i].$1,
                onPressed: () => onChanged(entries[i].$1),
                compact: true,
              ),
            ),
            if (i != entries.length - 1) const SizedBox(width: 8),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('SELECT / AUSWAHL'),
        const SizedBox(height: 12),
        for (final entry in entries) ...[
          _GameButton(
            title: entry.$2,
            subtitle: entry.$3,
            selected: selected == entry.$1,
            onPressed: () => onChanged(entry.$1),
            compact: false,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _GameButton extends StatelessWidget {
  const _GameButton({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onPressed,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: SizedBox(
        height: compact ? 62 : 76,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 16,
              vertical: 9,
            ),
            foregroundColor: selected ? SiteColors.white : SiteColors.text,
            backgroundColor: selected
                ? SiteColors.panelRaised
                : SiteColors.panelDark,
            side: BorderSide(
              color: selected ? SiteColors.signalYellow : SiteColors.lineSoft,
              width: selected ? 2 : 1,
            ),
            shape: const RoundedRectangleBorder(),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 6,
                height: compact ? 34 : 46,
                color: selected ? SiteColors.enemyRed : SiteColors.lineSoft,
              ),
              SizedBox(width: compact ? 8 : 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 12 : 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: compact ? 0.5 : 1.2,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SiteColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LaunchDeck extends StatelessWidget {
  const _LaunchDeck({
    required this.selected,
    required this.selectedKind,
    required this.english,
    required this.status,
    required this.busy,
    required this.display,
    required this.aspect,
    required this.pixels,
    required this.control,
    required this.settingsOpen,
    required this.onSettingsToggle,
    required this.onDisplayChanged,
    required this.onAspectChanged,
    required this.onPixelsChanged,
    required this.onControlChanged,
    required this.onLaunch,
  });

  final LauncherTarget selected;
  final TargetKind selectedKind;
  final bool english;
  final String status;
  final bool busy;
  final String display;
  final String aspect;
  final String pixels;
  final String control;
  final bool settingsOpen;
  final VoidCallback onSettingsToggle;
  final ValueChanged<String> onDisplayChanged;
  final ValueChanged<String> onAspectChanged;
  final ValueChanged<String> onPixelsChanged;
  final ValueChanged<String> onControlChanged;
  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    final text = AppText(english);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SelectedGameHero(
          selected: selected,
          selectedKind: selectedKind,
          english: english,
          status: status,
          busy: busy,
          onLaunch: onLaunch,
        ),
        const SizedBox(height: 16),
        _SettingsDrawer(
          text: text,
          open: settingsOpen,
          display: display,
          aspect: aspect,
          pixels: pixels,
          control: control,
          onToggle: onSettingsToggle,
          onDisplayChanged: onDisplayChanged,
          onAspectChanged: onAspectChanged,
          onPixelsChanged: onPixelsChanged,
          onControlChanged: onControlChanged,
        ),
        const SizedBox(height: 22),
        _ScreenshotRail(shots: selected.shots),
      ],
    );
  }
}

class _SelectedGameHero extends StatelessWidget {
  const _SelectedGameHero({
    required this.selected,
    required this.selectedKind,
    required this.english,
    required this.status,
    required this.busy,
    required this.onLaunch,
  });

  final LauncherTarget selected;
  final TargetKind selectedKind;
  final bool english;
  final String status;
  final bool busy;
  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    final text = AppText(english);
    final intro = selectedKind == TargetKind.intro;
    final launchLabel = intro ? text.playIntro : text.startGame;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;
        final cover = AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: AspectRatio(
            key: ValueKey(selected.cover),
            aspectRatio: 292 / 208,
            child: Image.asset(selected.cover, fit: BoxFit.cover),
          ),
        );
        final action = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              selected.title.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: SiteColors.white,
                fontSize: stacked ? 23 : 31,
                height: 1.04,
                fontWeight: FontWeight.w900,
                letterSpacing: stacked ? 1.2 : 2.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.circle, size: 9, color: SiteColors.readyGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    intro && !busy
                        ? text.introNote
                        : (status == 'Bereit.' || status == 'Ready.'
                              ? text.ready
                              : status),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SiteColors.text,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _LaunchButton(label: launchLabel, busy: busy, onPressed: onLaunch),
          ],
        );

        return Container(
          decoration: BoxDecoration(
            color: SiteColors.panel,
            border: Border.all(color: SiteColors.lineSoft),
            boxShadow: const [
              BoxShadow(
                color: Color(0x77000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 7,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SiteColors.enemyRed,
                      SiteColors.enemyRedDark,
                      SiteColors.lineSoft,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(stacked ? 18 : 26),
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [cover, const SizedBox(height: 20), action],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(width: 310, child: cover),
                          const SizedBox(width: 28),
                          Expanded(child: action),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LaunchButton extends StatelessWidget {
  const _LaunchButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: 58,
        child: FilledButton(
          onPressed: busy ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: SiteColors.enemyRed,
            disabledBackgroundColor: SiteColors.enemyRedDark,
            foregroundColor: SiteColors.white,
            shape: const RoundedRectangleBorder(),
            side: const BorderSide(color: Color(0xffff6873)),
          ),
          child: busy
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SiteColors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded, size: 26),
                    const SizedBox(width: 9),
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SettingsDrawer extends StatelessWidget {
  const _SettingsDrawer({
    required this.text,
    required this.open,
    required this.display,
    required this.aspect,
    required this.pixels,
    required this.control,
    required this.onToggle,
    required this.onDisplayChanged,
    required this.onAspectChanged,
    required this.onPixelsChanged,
    required this.onControlChanged,
  });

  final AppText text;
  final bool open;
  final String display;
  final String aspect;
  final String pixels;
  final String control;
  final VoidCallback onToggle;
  final ValueChanged<String> onDisplayChanged;
  final ValueChanged<String> onAspectChanged;
  final ValueChanged<String> onPixelsChanged;
  final ValueChanged<String> onControlChanged;

  @override
  Widget build(BuildContext context) {
    final summary = [
      display == 'Fullscreen' ? text.fullscreen : text.window,
      pixels == 'Enhanced'
          ? text.enhanced
          : pixels == 'Enhanced Plus'
          ? text.enhancedPlus
          : pixels,
      control == 'Keyboard' ? text.keyboard : control,
    ].join('  ·  ');
    return Container(
      decoration: BoxDecoration(
        color: SiteColors.panelDark,
        border: Border.all(color: SiteColors.lineSoft),
      ),
      child: Column(
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: InkWell(
              onTap: onToggle,
              focusColor: SiteColors.pinkMuted,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 58),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tune, color: SiteColors.pink, size: 20),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text.settings.toUpperCase(),
                              style: const TextStyle(
                                color: SiteColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              summary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: SiteColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        open ? Icons.expand_less : Icons.expand_more,
                        color: SiteColors.text,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: open
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 2 : 1;
                  final items = [
                    _SettingGroup(
                      label: text.display,
                      value: display,
                      options: [
                        ('Fullscreen', text.fullscreen),
                        ('Window', text.window),
                      ],
                      onChanged: onDisplayChanged,
                    ),
                    _SettingGroup(
                      label: text.aspect,
                      value: aspect,
                      options: [
                        ('4:3', 'Original 4:3'),
                        ('Pixel', text.pixelPerfect),
                        ('Stretch', text.stretch),
                      ],
                      onChanged: onAspectChanged,
                    ),
                    _SettingGroup(
                      label: text.graphics,
                      value: pixels,
                      options: [
                        ('Original', 'Original'),
                        ('Retro', 'Retro'),
                        ('Retro Plus', 'Retro Plus'),
                        ('Enhanced', text.enhanced),
                        ('Enhanced Plus', text.enhancedPlus),
                      ],
                      onChanged: onPixelsChanged,
                    ),
                    _SettingGroup(
                      label: text.controls,
                      value: control,
                      options: [
                        ('Keyboard', text.keyboard),
                        ('Gamepad', 'Gamepad'),
                        ('Joystick', 'Joystick'),
                      ],
                      onChanged: onControlChanged,
                    ),
                  ];
                  if (columns == 1) {
                    return Column(
                      children: [
                        for (final item in items) ...[
                          item,
                          const SizedBox(height: 17),
                        ],
                      ],
                    );
                  }
                  return Wrap(
                    spacing: 22,
                    runSpacing: 20,
                    children: [
                      for (final item in items)
                        SizedBox(
                          width: (constraints.maxWidth - 22) / 2,
                          child: item,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingGroup extends StatelessWidget {
  const _SettingGroup({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(label.toUpperCase()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(option.$2),
                selected: value == option.$1,
                onSelected: (_) => onChanged(option.$1),
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: value == option.$1
                      ? SiteColors.voidBlack
                      : SiteColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
                selectedColor: SiteColors.signalYellow,
                backgroundColor: SiteColors.panel,
                side: BorderSide(
                  color: value == option.$1
                      ? SiteColors.signalYellow
                      : SiteColors.lineSoft,
                ),
                shape: const RoundedRectangleBorder(),
              ),
          ],
        ),
      ],
    );
  }
}

class _ScreenshotRail extends StatelessWidget {
  const _ScreenshotRail({required this.shots});

  final List<String> shots;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 620;
        final children = [
          for (final shot in shots)
            AspectRatio(
              aspectRatio: 16 / 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: SiteColors.lineSoft),
                ),
                child: Image.asset(shot, fit: BoxFit.cover),
              ),
            ),
        ];
        if (stacked) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) const SizedBox(width: 14),
            ],
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: SiteColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _Atmosphere extends StatelessWidget {
  const _Atmosphere();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/galax-01.jpg', fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xdd05070d), Color(0xf2142753)],
              stops: [0, 0.75],
            ),
          ),
        ),
      ],
    );
  }
}

class _NewLaunchSplash extends StatelessWidget {
  const _NewLaunchSplash({required this.asset, required this.english});

  final String asset;
  final bool english;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(
        color: SiteColors.voidBlack,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.58,
              child: Image.asset(asset, fit: BoxFit.cover),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000000), Color(0xf205070d)],
                ),
              ),
            ),
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 620),
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: SiteColors.panel.withValues(alpha: 0.94),
                  border: Border.all(color: SiteColors.enemyRed, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ENEMY: TEMPEST REBORN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SiteColors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      english ? 'STARTING GAME' : 'SPIEL WIRD GESTARTET',
                      style: const TextStyle(
                        color: SiteColors.pink,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const LinearProgressIndicator(
                      minHeight: 3,
                      color: SiteColors.enemyRed,
                      backgroundColor: SiteColors.lineSoft,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
