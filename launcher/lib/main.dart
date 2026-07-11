import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

part 'launcher_ui.dart';

void main() {
  runApp(const TempestRebornLauncher());
}

class TempestRebornLauncher extends StatelessWidget {
  const TempestRebornLauncher({super.key, this.userDataPath});

  final String? userDataPath;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Enemy: Tempest Reborn',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Open Sans',
        scaffoldBackgroundColor: SiteColors.voidBlack,
        colorScheme: const ColorScheme.dark(
          primary: SiteColors.enemyRed,
          secondary: SiteColors.pink,
          surface: SiteColors.panel,
        ),
        focusColor: SiteColors.signalYellow,
        splashColor: SiteColors.pinkMuted,
        useMaterial3: true,
      ),
      home: LauncherScreen(userDataPath: userDataPath),
    );
  }
}

enum TargetKind { enemy1, enemy2, intro, cartographer }

enum LanguageChoice { de, en }

class SiteColors {
  const SiteColors._();

  static const voidBlack = Color(0xff05070d);
  static const panel = Color(0xff101729);
  static const panelRaised = Color(0xff172442);
  static const panelDark = Color(0xff090d18);
  static const bodyBlue = Color(0xff142753);
  static const linkBlue = Color(0xff8b91f4);
  static const blueText = Color(0xffa7abff);
  static const pink = Color(0xffe1afd7);
  static const pinkMuted = Color(0x33e1afd7);
  static const enemyRed = Color(0xffcf2635);
  static const enemyRedDark = Color(0xff701622);
  static const signalYellow = Color(0xffffd34e);
  static const readyGreen = Color(0xff6de18b);
  static const line = Color(0xff626bb5);
  static const lineSoft = Color(0xff35416b);
  static const text = Color(0xffc5c9dc);
  static const textMuted = Color(0xff8e96ad);
  static const title = Color(0xfff4f2f7);
  static const white = Color(0xfff7f5f8);
}

class AppText {
  const AppText(this.english);

  final bool english;

  String get settings => english ? 'Settings' : 'Einstellungen';
  String get levelMaps => english ? 'Level maps' : 'Levelkarten';
  String get about => english ? 'About' : 'Info';
  String get display => english ? 'Display' : 'Bildschirm';
  String get aspect => english ? 'Image format' : 'Bildformat';
  String get graphics => english ? 'Graphics' : 'Grafik';
  String get controls => english ? 'Controls' : 'Steuerung';
  String get fullscreen => english ? 'Fullscreen' : 'Vollbild';
  String get window => english ? 'Window' : 'Fenster';
  String get pixelPerfect => english ? 'Pixel perfect' : 'Pixelgenau';
  String get stretch => english ? 'Wide' : 'Breit';
  String get enhanced => english ? 'Enhanced' : 'Verbessert';
  String get enhancedPlus => english ? 'Enhanced Plus' : 'Verbessert Plus';
  String get keyboard => english ? 'Keyboard' : 'Tastatur';
  String get ready => english ? 'Ready to play' : 'Bereit zum Spielen';
  String get introNote => english
      ? 'Some intro scenes are currently missing.'
      : 'Einige Intro-Szenen fehlen derzeit.';
  String get openMaps => english ? 'Open level maps' : 'Levelkarten öffnen';
  String get startGame => english ? 'Start game' : 'Spiel starten';
  String get playIntro => english ? 'Play intro' : 'Intro starten';
  String get close => english ? 'Close' : 'Schließen';
}

class LauncherTarget {
  const LauncherTarget({
    required this.title,
    required this.subtitle,
    required this.game,
    required this.mode,
    required this.cover,
    required this.shots,
  });

  final String title;
  final String subtitle;
  final String game;
  final String mode;
  final String cover;
  final List<String> shots;
}

class PreflightResult {
  const PreflightResult.ok() : message = null;
  const PreflightResult.blocked(this.message);

  final String? message;
  bool get passed => message == null;
}

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({super.key, this.userDataPath});

  final String? userDataPath;

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  static const appVersion = '0.8';
  static const cartographerUrl = 'https://auralis.ch/plu/enemy/cartographer/';
  static const launchSplashAsset = 'assets/images/launch-splash-boxart.jpeg';
  static const graphicsPresets = [
    'Original',
    'Retro',
    'Retro Plus',
    'Enhanced',
    'Enhanced Plus',
  ];
  static const graphicsShaderLabels = {
    'Original': 'nearest',
    'Retro': 'crt-hyllian',
    'Retro Plus': 'crt-lottes',
    'Enhanced': 'scalefx',
    'Enhanced Plus': 'scale4xhq',
  };

  TargetKind _target = TargetKind.enemy1;
  LanguageChoice _language = LanguageChoice.de;
  String _display = 'Fullscreen';
  String _aspect = '4:3';
  String _pixels = 'Original';
  String _control = 'Keyboard';
  String _status = '';
  bool _busy = false;
  bool _showLaunchSplash = false;
  int _launchSplashToken = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  LauncherTarget get _selected {
    final english = _language == LanguageChoice.en;
    switch (_target) {
      case TargetKind.enemy1:
        return LauncherTarget(
          title: 'Enemy: Tempest of Violence',
          subtitle: 'Enemy 1',
          game: 'enemy1',
          mode: 'game',
          cover: 'assets/images/enemy1-cover.jpg',
          shots: const [
            'assets/images/e1-shot-1.png',
            'assets/images/e1-shot-2.png',
          ],
        );
      case TargetKind.enemy2:
        return LauncherTarget(
          title: 'Enemy 2: Missing in Action',
          subtitle: 'Enemy 2',
          game: 'enemy2',
          mode: 'game',
          cover: 'assets/images/enemy2-cover.jpg',
          shots: const [
            'assets/images/e2-shot-1.png',
            'assets/images/e2-shot-2.png',
          ],
        );
      case TargetKind.intro:
        return LauncherTarget(
          title: 'Enemy Intro',
          subtitle: 'Intro',
          game: 'enemy1',
          mode: 'intro',
          cover: 'assets/images/enemy1-cover.jpg',
          shots: const [
            'assets/images/e1-shot-1.png',
            'assets/images/e1-shot-2.png',
          ],
        );
      case TargetKind.cartographer:
        return LauncherTarget(
          title: 'Enemy Cartographer',
          subtitle: english ? 'Level maps' : 'Levelkarten',
          game: '',
          mode: 'external',
          cover: 'assets/images/enemy1-cover.jpg',
          shots: const [
            'assets/images/e1-shot-1.png',
            'assets/images/e2-shot-1.png',
          ],
        );
    }
  }

  String get _languageCode => _language == LanguageChoice.de ? 'de' : 'en';
  bool get _english => _language == LanguageChoice.en;
  String get _readyText => _english ? 'Ready.' : 'Bereit.';
  String get _statusText => _status.isEmpty ? _readyText : _status;

  Future<void> _launchSelected() async {
    if (_target == TargetKind.cartographer) {
      await _openCartographer();
      return;
    }

    final selected = _selected;
    final root = _projectRoot();
    final baseConfig = _baseConfigFile(root, selected);
    final fsUae = _fsUaeExecutable(root);

    final preflight = await _runPreflight(root, baseConfig, fsUae);
    if (!preflight.passed) {
      setState(() => _status = preflight.message!);
      return;
    }

    setState(() {
      _busy = true;
      _showLaunchSplash = true;
      _status = _english
          ? 'Starting ${selected.subtitle} ${_languageCode.toUpperCase()}...'
          : 'Starte ${selected.subtitle} ${_languageCode.toUpperCase()}...';
    });
    final splashToken = ++_launchSplashToken;

    try {
      final runtimeConfig = await _writeRuntimeConfig(
        root,
        baseConfig,
        selected,
      );
      final process = await Process.start(
        fsUae,
        [runtimeConfig.path],
        workingDirectory: _fsUaeWorkingDirectory(root, fsUae),
        mode: selected.mode == 'game'
            ? ProcessStartMode.detached
            : ProcessStartMode.normal,
      );
      if (selected.mode != 'game') {
        process.stdout.drain<void>();
        process.stderr.drain<void>();
      }
      _hideLaunchSplashLater(splashToken, _launchSplashDuration(selected));
      if (selected.mode == 'intro') {
        await process.exitCode;
        if (mounted) {
          setState(
            () => _status = _english ? 'Intro closed.' : 'Intro beendet.',
          );
        }
      } else if (mounted) {
        setState(
          () => _status = _english
              ? 'FS-UAE started with runtime config.'
              : 'FS-UAE mit Runtime-Config gestartet.',
        );
      }
    } on Object catch (error) {
      setState(() {
        _showLaunchSplash = false;
        _launchSplashToken++;
        _status = _english
            ? 'Launch failed: $error'
            : 'Start fehlgeschlagen: $error';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Duration _launchSplashDuration(LauncherTarget selected) {
    if (selected.mode == 'intro') return const Duration(seconds: 15);
    return switch (selected.game) {
      'enemy1' => const Duration(seconds: 19),
      'enemy2' => const Duration(seconds: 14),
      _ => const Duration(seconds: 5),
    };
  }

  void _hideLaunchSplashLater(int token, Duration duration) {
    Future<void>.delayed(duration, () {
      if (!mounted || token != _launchSplashToken) return;
      setState(() => _showLaunchSplash = false);
    });
  }

  Future<PreflightResult> _runPreflight(
    Directory root,
    File baseConfig,
    String fsUae,
  ) async {
    if (!await _commandExists(fsUae)) {
      return PreflightResult.blocked(
        _english
            ? 'FS-UAE was not found. Use the bundled FS-UAE build or add fs-uae to PATH.'
            : 'FS-UAE wurde nicht gefunden. Nutze das mitgelieferte FS-UAE oder nimm fs-uae in den PATH auf.',
      );
    }

    if (!baseConfig.existsSync()) {
      return PreflightResult.blocked(
        _english
            ? 'Missing base profile: ${_relativePath(root, baseConfig)}'
            : 'Basisprofil fehlt: ${_relativePath(root, baseConfig)}',
      );
    }

    late final Map<String, String> config;
    try {
      config = _readConfigValues(await baseConfig.readAsString());
    } on Object catch (error) {
      return PreflightResult.blocked(
        _english
            ? 'Could not read base profile: $error'
            : 'Basisprofil konnte nicht gelesen werden: $error',
      );
    }

    final requiredFiles = <String, String>{
      'kickstart_file': _english ? 'AROS ROM' : 'AROS-ROM',
      'kickstart_ext_file': _english ? 'AROS extension ROM' : 'AROS-Ext-ROM',
      'floppy_drive_0': _english ? 'Disk image A' : 'Diskettenimage A',
      'floppy_drive_1': _english ? 'Disk image B' : 'Diskettenimage B',
    };

    final missing = <String>[];
    for (final entry in requiredFiles.entries) {
      final value = config[entry.key]?.trim();
      if (value == null || value.isEmpty) {
        missing.add(
          '${entry.value}: ${_english ? 'not configured' : 'nicht konfiguriert'}',
        );
        continue;
      }
      final file = _configPath(root, value);
      if (!file.existsSync()) {
        missing.add('${entry.value}: ${_relativePath(root, file)}');
      }
    }

    if (missing.isNotEmpty) {
      final shown = missing.take(3).join(' | ');
      final more = missing.length > 3 ? ' +${missing.length - 3}' : '';
      return PreflightResult.blocked(
        _english
            ? 'Missing runtime file: $shown$more'
            : 'Laufzeitdatei fehlt: $shown$more',
      );
    }

    return const PreflightResult.ok();
  }

  Future<bool> _commandExists(String command) async {
    try {
      if (command.contains(Platform.pathSeparator)) {
        final file = File(command);
        return file.existsSync();
      }
      final finder = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(finder, [command]);
      return result.exitCode == 0;
    } on Object {
      return false;
    }
  }

  String _fsUaeExecutable(Directory root) {
    final executableName = Platform.isWindows ? 'fs-uae.exe' : 'fs-uae';
    final bundled = File(
      '${root.path}${Platform.pathSeparator}bin${Platform.pathSeparator}fs-uae${Platform.pathSeparator}$executableName',
    );
    if (bundled.existsSync()) return bundled.path;
    return executableName;
  }

  String _fsUaeWorkingDirectory(Directory root, String fsUae) {
    if (fsUae.contains(Platform.pathSeparator)) {
      return File(fsUae).parent.path;
    }
    return root.path;
  }

  Future<void> _openCartographer() async {
    try {
      final command = Platform.isWindows
          ? 'cmd'
          : Platform.isMacOS
          ? 'open'
          : 'xdg-open';
      final args = Platform.isWindows
          ? ['/c', 'start', '', cartographerUrl]
          : [cartographerUrl];
      await Process.start(command, args);
      setState(() {
        _status = _english
            ? 'Cartographer opened in browser.'
            : 'Cartographer im Browser geoeffnet.';
      });
    } on Object catch (error) {
      setState(() {
        _status = _english
            ? 'Could not open browser: $error'
            : 'Browserstart fehlgeschlagen: $error';
      });
    }
  }

  Directory _projectRoot() {
    final current = Directory.current;
    if (current.path.endsWith('${Platform.pathSeparator}launcher')) {
      return current.parent;
    }
    final launcherChild = Directory(
      '${current.path}${Platform.pathSeparator}launcher',
    );
    if (launcherChild.existsSync()) return current;
    final executableDir = File(Platform.resolvedExecutable).parent;
    if (executableDir.path.endsWith('${Platform.pathSeparator}launcher')) {
      return executableDir.parent;
    }
    final executableLauncherChild = Directory(
      '${executableDir.path}${Platform.pathSeparator}launcher',
    );
    if (executableLauncherChild.existsSync()) return executableDir;
    return File(Platform.resolvedExecutable).parent.parent.parent.parent;
  }

  Directory _userDataRoot() {
    if (widget.userDataPath case final path?) return Directory(path);
    final env = Platform.environment;
    if (Platform.isWindows) {
      final appData = env['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return Directory(
          '$appData${Platform.pathSeparator}Enemy Tempest Reborn',
        );
      }
    } else if (Platform.isMacOS) {
      final home = env['HOME'];
      if (home != null && home.isNotEmpty) {
        return Directory(
          '$home${Platform.pathSeparator}Library${Platform.pathSeparator}Application Support${Platform.pathSeparator}Enemy Tempest Reborn',
        );
      }
    } else {
      final xdgDataHome = env['XDG_DATA_HOME'];
      if (xdgDataHome != null && xdgDataHome.isNotEmpty) {
        return Directory(
          '$xdgDataHome${Platform.pathSeparator}enemy-tempest-reborn',
        );
      }
      final home = env['HOME'];
      if (home != null && home.isNotEmpty) {
        return Directory(
          '$home${Platform.pathSeparator}.local${Platform.pathSeparator}share${Platform.pathSeparator}enemy-tempest-reborn',
        );
      }
    }
    return Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}enemy-tempest-reborn',
    );
  }

  File _settingsFile() {
    return File(
      '${_userDataRoot().path}${Platform.pathSeparator}settings.json',
    );
  }

  Future<void> _loadSettings() async {
    final file = _settingsFile();
    if (!file.existsSync()) {
      return;
    }

    try {
      final data = jsonDecode(await file.readAsString());
      if (data is! Map<String, dynamic>) return;
      if (!mounted) return;
      setState(() {
        final savedTarget = _targetFromName(data['target']);
        _target = savedTarget == TargetKind.cartographer
            ? TargetKind.enemy1
            : savedTarget ?? _target;
        _language = _languageFromName(data['language']) ?? _language;
        _display =
            _allowed(data['display'], const ['Fullscreen', 'Window']) ??
            _display;
        _aspect =
            _allowed(data['aspect'], const ['4:3', 'Pixel', 'Stretch']) ??
            _aspect;
        _pixels = _normalisePixels(data['pixels']) ?? _pixels;
        _control =
            _allowed(data['control'], const [
              'Keyboard',
              'Gamepad',
              'Joystick',
            ]) ??
            _control;
      });
    } on Object {
      return;
    }
  }

  Future<void> _saveSettings() async {
    final file = _settingsFile();
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(
      '${encoder.convert({'target': _target.name, 'language': _language.name, 'display': _display, 'aspect': _aspect, 'pixels': _pixels, 'control': _control})}\n',
    );
  }

  String? _allowed(Object? value, List<String> allowed) {
    return value is String && allowed.contains(value) ? value : null;
  }

  String? _normalisePixels(Object? value) {
    if (value is! String) return null;
    if (graphicsPresets.contains(value)) return value;
    return switch (value) {
      'Sharp' => 'Original',
      'Smooth' => 'Enhanced',
      'CRT' => 'Retro',
      _ => null,
    };
  }

  TargetKind? _targetFromName(Object? value) {
    if (value is! String) return null;
    for (final item in TargetKind.values) {
      if (item.name == value) return item;
    }
    return null;
  }

  LanguageChoice? _languageFromName(Object? value) {
    if (value is! String) return null;
    for (final item in LanguageChoice.values) {
      if (item.name == value) return item;
    }
    return null;
  }

  File _baseConfigFile(Directory root, LauncherTarget selected) {
    final name = selected.mode == 'intro'
        ? 'tempestreborn_intro_${_languageCode}_a1200.fs-uae'
        : 'tempestreborn_${selected.game}_${_languageCode}_a1200.fs-uae';
    return File(
      '${root.path}${Platform.pathSeparator}configs${Platform.pathSeparator}fs-uae${Platform.pathSeparator}$name',
    );
  }

  Map<String, String> _readConfigValues(String config) {
    final values = <String, String>{};
    for (final line in config.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty ||
          trimmed.startsWith('#') ||
          trimmed.startsWith(';') ||
          trimmed.startsWith('[')) {
        continue;
      }
      final equals = trimmed.indexOf('=');
      if (equals <= 0) continue;
      final key = trimmed.substring(0, equals).trim();
      final value = trimmed.substring(equals + 1).trim();
      values[key] = value;
    }
    return values;
  }

  File _configPath(Directory root, String value) {
    final expanded = value.replaceAll('/', Platform.pathSeparator);
    if (File(expanded).isAbsolute) return File(expanded);
    return File('${root.path}${Platform.pathSeparator}$expanded');
  }

  String _relativePath(Directory root, File file) {
    final prefix = '${root.path}${Platform.pathSeparator}';
    if (file.path.startsWith(prefix)) return file.path.substring(prefix.length);
    return file.path;
  }

  Future<File> _writeRuntimeConfig(
    Directory root,
    File baseConfig,
    LauncherTarget selected,
  ) async {
    final userDataRoot = _userDataRoot();
    final runtimeDir = Directory(
      '${userDataRoot.path}${Platform.pathSeparator}work${Platform.pathSeparator}launcher-runtime',
    );
    await runtimeDir.create(recursive: true);

    final targetId = selected.mode == 'intro'
        ? 'intro_$_languageCode'
        : '${selected.game}_$_languageCode';
    final runtimeConfig = File(
      '${runtimeDir.path}${Platform.pathSeparator}tempestreborn_runtime_$targetId.fs-uae',
    );
    final logDir = Directory(
      '${userDataRoot.path}${Platform.pathSeparator}output${Platform.pathSeparator}logs',
    );
    final screenshotDir = Directory(
      '${userDataRoot.path}${Platform.pathSeparator}output${Platform.pathSeparator}screenshots',
    );
    final stateDir = Directory(
      '${userDataRoot.path}${Platform.pathSeparator}output${Platform.pathSeparator}states',
    );
    await logDir.create(recursive: true);
    await screenshotDir.create(recursive: true);
    await stateDir.create(recursive: true);

    final baseText = await baseConfig.readAsString();
    final baseValues = _readConfigValues(baseText);
    final absolutePaths = _absoluteRuntimePaths(root, baseValues);

    final values = <String, String>{
      ...absolutePaths,
      'video_sync': '0',
      'zoom': 'auto',
      'uaelogfile': _fsUaePath(
        File(
          '${logDir.path}${Platform.pathSeparator}tempestreborn_runtime_$targetId.log',
        ),
      ),
      'screenshots_output_dir': _fsUaePath(screenshotDir),
      'screenshots_output_prefix': 'tempestreborn_runtime_${targetId}_',
      'state_dir': _fsUaePath(stateDir),
      'logs_dir': _fsUaePath(logDir),
      'enemy_launcher_runtime': '1',
      'enemy_target': selected.game.isEmpty ? 'cartographer' : selected.game,
      'enemy_language': _languageCode,
      'enemy_mode': selected.mode,
      'enemy_display': _display.toLowerCase(),
      'enemy_aspect': _aspect.toLowerCase(),
      'enemy_pixels': _pixels.toLowerCase().replaceAll(' ', '_'),
      'enemy_control': _control.toLowerCase(),
      ..._displayOverrides(_display),
      ..._aspectOverrides(_aspect),
      ..._pixelOverrides(_pixels),
      ..._controlOverrides(_control),
    };

    final generated = _upsertConfig(baseText, values);
    await runtimeConfig.writeAsString(generated);
    return runtimeConfig;
  }

  Map<String, String> _absoluteRuntimePaths(
    Directory root,
    Map<String, String> baseValues,
  ) {
    final values = <String, String>{};
    for (final key in const [
      'data_dir',
      'kickstart_file',
      'kickstart_ext_file',
      'floppy_drive_0',
      'floppy_drive_1',
      'floppy_drive_2',
      'floppy_drive_3',
    ]) {
      final value = baseValues[key]?.trim();
      if (value == null || value.isEmpty) continue;
      values[key] = _fsUaePath(_configPath(root, value));
    }
    return values;
  }

  String _fsUaePath(FileSystemEntity entity) {
    return entity.absolute.path.replaceAll(r'\', '/');
  }

  Map<String, String> _displayOverrides(String display) {
    if (display == 'Window') {
      return {'fullscreen': '0', 'window_width': '960', 'window_height': '720'};
    }
    return {'fullscreen': '1'};
  }

  Map<String, String> _aspectOverrides(String aspect) {
    return switch (aspect) {
      'Stretch' => {
        'keep_aspect': '0',
        'stretch': '1',
        'enemy_viewport': 'stretch',
      },
      'Pixel' => {
        'keep_aspect': '1',
        'stretch': '0',
        'enemy_viewport': 'integer',
      },
      _ => {'keep_aspect': '1', 'stretch': '0', 'enemy_viewport': '4_3'},
    };
  }

  Map<String, String> _pixelOverrides(String pixels) {
    return switch (pixels) {
      'Retro' => {
        'texture_filter': 'nearest',
        'smoothing': '0',
        'scanlines': '0',
        'shader': 'crt-hyllian',
        'enemy_filter': 'crt_hyllian',
      },
      'Retro Plus' => {
        'texture_filter': 'nearest',
        'smoothing': '0',
        'scanlines': '0',
        'shader': 'crt-lottes',
        'enemy_filter': 'crt_lottes',
      },
      'Enhanced' => {
        'texture_filter': 'nearest',
        'smoothing': '0',
        'scanlines': '0',
        'shader': 'scalefx',
        'enemy_filter': 'scalefx',
      },
      'Enhanced Plus' => {
        'texture_filter': 'nearest',
        'smoothing': '0',
        'scanlines': '0',
        'shader': 'scale4xhq',
        'enemy_filter': 'scale4xhq',
      },
      _ => {
        'texture_filter': 'nearest',
        'smoothing': '0',
        'scanlines': '0',
        'enemy_filter': 'original',
      },
    };
  }

  Map<String, String> _controlOverrides(String control) {
    return switch (control) {
      'Gamepad' => {
        'joystick_port_0': 'mouse',
        'joystick_port_0_mode': 'mouse',
        'joystick_port_1': 'auto',
        'joystick_port_1_mode': 'joystick',
        'joystick_port_1_primary': '1',
        'joystick_port_1_secondary': '1',
        'joystick_port_1_tertiary': '1',
        'joystick_port_1_left_shoulder': 'action_key_p',
        'joystick_port_1_right_shoulder': 'action_key_help',
        'joystick_port_1_left_trigger': 'action_key_r',
        'joystick_port_1_right_trigger': 'action_key_r',
        'joystick_port_1_select_button': 'action_key_r',
        'keyboard_key_h': 'action_key_help',
      },
      'Joystick' => {
        'joystick_port_0': 'mouse',
        'joystick_port_0_mode': 'mouse',
        'joystick_port_1': 'auto',
        'joystick_port_1_mode': 'joystick',
        'keyboard_key_h': 'action_key_help',
      },
      _ => {
        'joystick_port_0': 'mouse',
        'joystick_port_0_mode': 'mouse',
        'joystick_port_1': 'keyboard',
        'joystick_port_1_mode': 'joystick',
        'keyboard_key_h': 'action_key_help',
      },
    };
  }

  String _upsertConfig(String config, Map<String, String> values) {
    final pending = Map<String, String>.of(values);
    final lines = config.split('\n');
    final out = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      final equals = trimmed.indexOf('=');
      if (equals > 0 && !trimmed.startsWith('#') && !trimmed.startsWith(';')) {
        final key = trimmed.substring(0, equals).trim();
        final value = pending.remove(key);
        if (value != null) {
          out.add('$key = $value');
          continue;
        }
      }
      out.add(line);
    }

    if (pending.isNotEmpty) {
      out.add('');
      out.add('; Generated by Enemy: Tempest Reborn launcher');
      for (final entry in pending.entries) {
        out.add('${entry.key} = ${entry.value}');
      }
    }

    return out.join('\n');
  }

  void _select(TargetKind target) {
    setState(() {
      _target = target;
      _status = target == TargetKind.cartographer ? cartographerUrl : '';
    });
    _saveSettings();
  }

  void _setLanguage(LanguageChoice language) {
    setState(() => _language = language);
    _saveSettings();
  }

  void _setDisplay(String display) {
    setState(() => _display = display);
    _saveSettings();
  }

  void _setAspect(String aspect) {
    setState(() => _aspect = aspect);
    _saveSettings();
  }

  void _setPixels(String pixels) {
    setState(() => _pixels = pixels);
    _saveSettings();
  }

  void _setControl(String control) {
    setState(() => _control = control);
    _saveSettings();
  }

  void _showAbout() {
    final english = _english;
    showDialog<void>(
      context: context,
      builder: (context) => _AboutDialog(
        english: english,
        version: appVersion,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return LauncherView(
      selectedKind: _target,
      selected: selected,
      language: _language,
      status: _statusText,
      busy: _busy,
      display: _display,
      aspect: _aspect,
      pixels: _pixels,
      control: _control,
      showLaunchSplash: _showLaunchSplash,
      launchSplashAsset: launchSplashAsset,
      onTargetChanged: _select,
      onLanguageChanged: _setLanguage,
      onDisplayChanged: _setDisplay,
      onAspectChanged: _setAspect,
      onPixelsChanged: _setPixels,
      onControlChanged: _setControl,
      onLaunch: _launchSelected,
      onMaps: _openCartographer,
      onAbout: _showAbout,
    );
  }
}

// Legacy widgets are retained temporarily to keep this release change focused
// on presentation without touching the proven runtime implementation.
// ignore: unused_element
class _LaunchSplash extends StatelessWidget {
  const _LaunchSplash({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xf5050509)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(asset, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99000000),
                    Color(0x22000000),
                    Color(0xcc000000),
                  ],
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xdd111326),
                    border: Border.all(color: SiteColors.line, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xaa000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'ENEMY: TEMPEST REBORN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: SiteColors.blueText,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.8,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 8,
                              offset: Offset(3, 3),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'STARTING FS-UAE',
                        style: TextStyle(
                          color: SiteColors.pink,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 26,
              right: 26,
              bottom: 24,
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: Color(0x66000000),
                color: SiteColors.linkBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _Header extends StatelessWidget {
  const _Header({
    required this.language,
    required this.onLanguageChanged,
    required this.onAbout,
  });

  final LanguageChoice language;
  final ValueChanged<LanguageChoice> onLanguageChanged;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 196,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/streifen.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/alien.png',
              alignment: Alignment.centerLeft,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 28,
            top: 36,
            child: Row(
              children: [
                _AboutButton(onTap: onAbout),
                const SizedBox(width: 14),
                _LanguageFlags(
                  language: language,
                  onChanged: onLanguageChanged,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1030),
              child: Container(
                height: 78,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xdd2c2b2f),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xaa000000),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/anachronia.png',
                      width: 262,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 18),
                    const Expanded(child: _ProjectBrand()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutButton extends StatelessWidget {
  const _AboutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.62),
          border: Border.all(color: SiteColors.line),
        ),
        child: const Text(
          'ABOUT',
          style: TextStyle(
            color: SiteColors.pink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog({
    required this.english,
    required this.version,
    required this.onClose,
  });

  final bool english;
  final String version;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final thanks = english ? 'With thanks' : 'Mit Dank an';
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 820),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: SiteColors.panel,
            border: Border.all(color: SiteColors.enemyRed, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0xaa000000),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 10, 14),
                  decoration: const BoxDecoration(
                    color: SiteColors.panelDark,
                    border: Border(
                      bottom: BorderSide(color: SiteColors.lineSoft),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'ENEMY: TEMPEST REBORN',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SiteColors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ),
                      Text(
                        'V$version',
                        style: const TextStyle(
                          color: SiteColors.signalYellow,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onClose,
                        tooltip: english ? 'Close' : 'Schließen',
                        icon: const Icon(Icons.close),
                        color: SiteColors.text,
                        style: IconButton.styleFrom(
                          minimumSize: const Size.square(44),
                          shape: const RoundedRectangleBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: SiteColors.voidBlack,
                  padding: const EdgeInsets.all(14),
                  child: AspectRatio(
                    aspectRatio: 1214 / 880,
                    child: Image.asset(
                      _LauncherScreenState.launchSplashAsset,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        thanks.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: SiteColors.pink,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _AboutCredit(
                        name: 'André Wüthrich',
                        role: english
                            ? 'Creator of Enemy & Anachronia'
                            : 'Schöpfer von Enemy & Anachronia',
                      ),
                      const SizedBox(height: 10),
                      _AboutCredit(
                        name: 'Stephan Kaufmann',
                        role: english
                            ? 'Author of Enemy: Tempest Reborn'
                            : 'Autor von Enemy: Tempest Reborn',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutCredit extends StatelessWidget {
  const _AboutCredit({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: SiteColors.panelDark,
        border: Border.all(color: SiteColors.lineSoft),
      ),
      child: Column(
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SiteColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            role,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SiteColors.textMuted,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _AboutLine extends StatelessWidget {
  const _AboutLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: SiteColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: SiteColors.text, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: SiteColors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '- $line',
              style: const TextStyle(color: SiteColors.text, height: 1.28),
            ),
          ),
      ],
    );
  }
}

class _ProjectBrand extends StatelessWidget {
  const _ProjectBrand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'ENEMY: TEMPEST REBORN',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: SiteColors.blueText,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            shadows: [Shadow(color: Colors.black, blurRadius: 5)],
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Stephan Kaufmann',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: SiteColors.pink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
      ],
    );
  }
}

class _LanguageFlags extends StatelessWidget {
  const _LanguageFlags({required this.language, required this.onChanged});

  final LanguageChoice language;
  final ValueChanged<LanguageChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FlagButton(
          label: 'DE',
          selected: language == LanguageChoice.de,
          onTap: () => onChanged(LanguageChoice.de),
        ),
        const SizedBox(width: 8),
        _FlagButton(
          label: 'EN',
          selected: language == LanguageChoice.en,
          onTap: () => onChanged(LanguageChoice.en),
        ),
      ],
    );
  }
}

class _FlagButton extends StatelessWidget {
  const _FlagButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label == 'DE' ? '🇩🇪' : '🇬🇧',
        style: TextStyle(
          fontSize: selected ? 22 : 18,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selected,
    required this.language,
    required this.onSelected,
  });

  final TargetKind selected;
  final LanguageChoice language;
  final ValueChanged<TargetKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final english = language == LanguageChoice.en;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SubNavButton(
          label: 'Enemy 1',
          active: selected == TargetKind.enemy1,
          onTap: () => onSelected(TargetKind.enemy1),
        ),
        _SubNavButton(
          label: 'Enemy 2',
          active: selected == TargetKind.enemy2,
          onTap: () => onSelected(TargetKind.enemy2),
        ),
        _SubNavButton(
          label: 'Intro',
          active: selected == TargetKind.intro,
          onTap: () => onSelected(TargetKind.intro),
        ),
        _SubNavButton(
          label: english ? 'Maps' : 'Cartographer',
          active: selected == TargetKind.cartographer,
          onTap: () => onSelected(TargetKind.cartographer),
        ),
        const SizedBox(height: 28),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 246),
            child: ClipRRect(
              child: Image.asset(
                selected == TargetKind.enemy2
                    ? 'assets/images/enemy2-cover.jpg'
                    : 'assets/images/enemy1-cover.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubNavButton extends StatelessWidget {
  const _SubNavButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: SiteColors.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 30,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: active ? const Color(0xff111144) : Colors.black,
            border: Border(
              left: BorderSide(color: SiteColors.line, width: active ? 48 : 0),
            ),
          ),
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? SiteColors.white : SiteColors.blueText,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              shadows: const [Shadow(color: Color(0xff7680ff), blurRadius: 5)],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ContentPane extends StatelessWidget {
  const _ContentPane({
    required this.selected,
    required this.languageCode,
    required this.english,
    required this.status,
    required this.busy,
    required this.display,
    required this.aspect,
    required this.pixels,
    required this.control,
    required this.onDisplayChanged,
    required this.onAspectChanged,
    required this.onPixelsChanged,
    required this.onControlChanged,
    required this.onLaunch,
  });

  final LauncherTarget selected;
  final String languageCode;
  final bool english;
  final String status;
  final bool busy;
  final String display;
  final String aspect;
  final String pixels;
  final String control;
  final ValueChanged<String> onDisplayChanged;
  final ValueChanged<String> onAspectChanged;
  final ValueChanged<String> onPixelsChanged;
  final ValueChanged<String> onControlChanged;
  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    final external = selected.mode == 'external';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          selected.title.toUpperCase(),
          style: const TextStyle(
            color: SiteColors.title,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            shadows: [
              Shadow(color: Color(0x886f75df), blurRadius: 8),
              Shadow(color: Colors.black, offset: Offset(2, 2)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _DoubleRule(),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ActionBox(
                selected: selected,
                languageCode: languageCode,
                english: english,
                busy: busy,
                status: status,
                onLaunch: onLaunch,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 270,
              child: _SettingsBox(
                display: display,
                aspect: aspect,
                pixels: pixels,
                control: control,
                english: english,
                onDisplayChanged: onDisplayChanged,
                onAspectChanged: onAspectChanged,
                onPixelsChanged: onPixelsChanged,
                onControlChanged: onControlChanged,
                disabled: external,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _ScreenshotStrip(shots: selected.shots),
      ],
    );
  }
}

class _ActionBox extends StatelessWidget {
  const _ActionBox({
    required this.selected,
    required this.languageCode,
    required this.english,
    required this.busy,
    required this.status,
    required this.onLaunch,
  });

  final LauncherTarget selected;
  final String languageCode;
  final bool english;
  final bool busy;
  final String status;
  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    final label = selected.mode == 'intro'
        ? (english ? 'PLAY INTRO' : 'INTRO STARTEN')
        : selected.mode == 'external'
        ? (english ? 'OPEN CARTOGRAPHER' : 'CARTOGRAPHER OEFFNEN')
        : (english ? 'START GAME' : 'SPIEL STARTEN');
    final shownStatus = selected.mode == 'intro' && !busy
        ? (english
              ? 'Ready - some parts missing.'
              : 'Bereit - einige Teile fehlen.')
        : status;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        border: Border.all(color: SiteColors.line.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${selected.subtitle} / ${languageCode.toUpperCase()}',
            style: const TextStyle(
              color: SiteColors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            shownStatus,
            style: const TextStyle(color: SiteColors.text, fontSize: 16),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: busy ? null : onLaunch,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: SiteColors.pink,
                shape: const RoundedRectangleBorder(),
                side: const BorderSide(color: SiteColors.line),
              ),
              child: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsBox extends StatelessWidget {
  const _SettingsBox({
    required this.display,
    required this.aspect,
    required this.pixels,
    required this.control,
    required this.english,
    required this.onDisplayChanged,
    required this.onAspectChanged,
    required this.onPixelsChanged,
    required this.onControlChanged,
    required this.disabled,
  });

  final String display;
  final String aspect;
  final String pixels;
  final String control;
  final bool english;
  final ValueChanged<String> onDisplayChanged;
  final ValueChanged<String> onAspectChanged;
  final ValueChanged<String> onPixelsChanged;
  final ValueChanged<String> onControlChanged;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: IgnorePointer(
        ignoring: disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OptionLine(
              label: english ? 'Display' : 'Anzeige',
              value: display,
              values: const ['Fullscreen', 'Window'],
              onChanged: onDisplayChanged,
            ),
            _OptionLine(
              label: 'Aspect',
              value: aspect,
              values: const ['4:3', 'Pixel', 'Stretch'],
              onChanged: onAspectChanged,
            ),
            _OptionLine(
              label: english ? 'Preset' : 'Preset',
              value: pixels,
              values: _LauncherScreenState.graphicsPresets,
              captions: _LauncherScreenState.graphicsShaderLabels,
              onChanged: onPixelsChanged,
            ),
            _OptionLine(
              label: english ? 'Control' : 'Steuerung',
              value: control,
              values: const ['Keyboard', 'Gamepad', 'Joystick'],
              onChanged: onControlChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionLine extends StatelessWidget {
  const _OptionLine({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.captions = const {},
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  final Map<String, String> captions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: SiteColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final item in values)
                InkWell(
                  onTap: () => onChanged(item),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 82),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: item == value
                          ? const Color(0xff111144)
                          : Colors.black,
                      border: Border.all(color: SiteColors.line),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item,
                          style: TextStyle(
                            color: item == value
                                ? SiteColors.white
                                : SiteColors.blueText,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        if (captions[item] case final caption?)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              caption,
                              style: TextStyle(
                                color:
                                    (item == value
                                            ? SiteColors.white
                                            : SiteColors.blueText)
                                        .withValues(alpha: 0.72),
                                fontWeight: FontWeight.w700,
                                fontSize: 8,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScreenshotStrip extends StatelessWidget {
  const _ScreenshotStrip({required this.shots});

  final List<String> shots;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final shot in shots)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: SiteColors.line.withValues(alpha: 0.65),
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66000000), blurRadius: 8),
                  ],
                ),
                child: Image.asset(shot, fit: BoxFit.cover),
              ),
            ),
          ),
      ],
    );
  }
}

class _DoubleRule extends StatelessWidget {
  const _DoubleRule();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 1, color: SiteColors.line),
        const SizedBox(height: 8),
        Container(height: 1, color: SiteColors.line),
      ],
    );
  }
}

// ignore: unused_element
class _BlueBackground extends StatelessWidget {
  const _BlueBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/blue.jpg',
      repeat: ImageRepeat.repeat,
      fit: BoxFit.none,
      alignment: Alignment.topLeft,
    );
  }
}
