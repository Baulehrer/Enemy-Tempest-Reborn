part of 'main.dart';

class IntroVideoScreen extends StatefulWidget {
  const IntroVideoScreen({super.key, required this.english});

  final bool english;

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  late final Player _player;
  late final VideoController _controller;
  late final FocusNode _focusNode;
  StreamSubscription<bool>? _completedSubscription;
  Object? _error;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'intro-skip');
    _player = Player();
    _controller = VideoController(_player);
    _completedSubscription = _player.stream.completed.listen((completed) {
      if (completed) _close();
    });
    _open();
  }

  Future<void> _open() async {
    try {
      final language = widget.english ? 'en' : 'de';
      await _player.open(
        Media('asset:///assets/video/enemy-intro-$language.mp4'),
        play: true,
      );
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) _close();
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _completedSubscription?.cancel();
    _focusNode.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skip = widget.english
        ? 'Press any key or click to skip'
        : 'Beliebige Taste oder Klick zum Überspringen';
    final failed = widget.english
        ? 'The intro video could not be played.'
        : 'Das Introvideo konnte nicht abgespielt werden.';

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: KeyboardListener(
          autofocus: true,
          focusNode: _focusNode,
          onKeyEvent: _handleKey,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_error == null)
                  Video(
                    controller: _controller,
                    fit: BoxFit.contain,
                    controls: NoVideoControls,
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: SiteColors.enemyRed,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            failed,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: SiteColors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: SiteColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  right: 22,
                  bottom: 18,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xaa000000),
                      border: Border.all(color: SiteColors.lineSoft),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      child: Text(
                        skip,
                        style: const TextStyle(
                          color: SiteColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
