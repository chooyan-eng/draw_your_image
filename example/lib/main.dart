import 'package:draw_your_image/draw_your_image.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

enum DrawMode {
  writing, // 書き込みモード
  reviewing, // 書き順確認モード
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _strokes = <Stroke>[];
  var _currentColor = Colors.black;
  var _currentWidth = 4.0;
  var _smoothingMode = SmoothingMode.catmullRom;
  var _mode = DrawMode.writing;
  var _reviewingStrokeIndex = 0;

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes = _strokes.sublist(0, _strokes.length - 1);
    });
  }

  void _clear() {
    setState(() {
      _strokes = [];
      _mode = DrawMode.writing;
      _reviewingStrokeIndex = 0;
    });
  }

  void _switchToReviewMode() {
    if (_strokes.isEmpty) return;
    setState(() {
      _mode = DrawMode.reviewing;
      _reviewingStrokeIndex = 0;
    });
  }

  void _switchToWritingMode() {
    setState(() {
      _mode = DrawMode.writing;
      _reviewingStrokeIndex = 0;
    });
  }

  /// モードに応じて表示するストロークを生成
  List<Stroke> _convert(List<Stroke> strokes) {
    if (_mode == DrawMode.writing) {
      return strokes;
    }

    // 書き順確認モード
    return strokes.asMap().entries.map((entry) {
      final index = entry.key;
      final stroke = entry.value;

      if (index < _reviewingStrokeIndex) {
        // 過去のストローク: 黒
        return stroke.copyWith(color: Colors.black);
      } else if (index == _reviewingStrokeIndex) {
        // 現在のストローク: 強調色（赤）
        return stroke.copyWith(color: Colors.red, width: stroke.width * 1.2);
      } else {
        // 未来のストローク: 薄いグレー
        return stroke.copyWith(color: Colors.grey.withValues(alpha: 0.3));
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_mode == DrawMode.writing) ...[
            IconButton(
              icon: Icon(Icons.undo),
              onPressed: _strokes.isEmpty ? null : _undo,
            ),
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _strokes.isEmpty ? null : _clear,
            ),
            IconButton(
              icon: Icon(Icons.play_arrow),
              onPressed: _strokes.isEmpty ? null : _switchToReviewMode,
              tooltip: '書き順確認',
            ),
          ],
          if (_mode == DrawMode.reviewing) ...[
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: _switchToWritingMode,
              tooltip: '書き込みに戻る',
            ),
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clear,
            ),
          ],
        ],
      ),
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 書き込みモード時のみ表示

            // Smoothing mode selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Smoothing: '),
                  SegmentedButton<SmoothingMode>(
                    segments: const [
                      ButtonSegment(
                        value: SmoothingMode.none,
                        label: Text('None'),
                      ),
                      ButtonSegment(
                        value: SmoothingMode.catmullRom,
                        label: Text('Smooth'),
                      ),
                    ],
                    selected: {_smoothingMode},
                    onSelectionChanged: (Set<SmoothingMode> newSelection) {
                      setState(() {
                        _smoothingMode = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: IgnorePointer(
                ignoring: _mode == DrawMode.reviewing,
                child: Draw(
                  strokes: _convert(_strokes),
                  strokeColor: _currentColor,
                  strokeWidth: _currentWidth,
                  smoothingFunc: _smoothingMode.converter,
                  onStrokeDrawn: (stroke) {
                    setState(() => _strokes = [..._strokes, stroke]);
                  },
                  onStrokeStarted: styrusPriorHandler,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 書き順確認モード時のスライダー
            if (_mode == DrawMode.reviewing && _strokes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      '書き順: ${_reviewingStrokeIndex + 1} / ${_strokes.length}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios),
                          onPressed: _reviewingStrokeIndex > 0
                              ? () {
                                  setState(() {
                                    _reviewingStrokeIndex--;
                                  });
                                }
                              : null,
                        ),
                        Expanded(
                          child: Slider(
                            value: _reviewingStrokeIndex.toDouble(),
                            min: 0,
                            max: (_strokes.length - 1).toDouble(),
                            divisions: _strokes.length - 1,
                            label: '${_reviewingStrokeIndex + 1}',
                            onChanged: (value) {
                              setState(() {
                                _reviewingStrokeIndex = value.toInt();
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_forward_ios),
                          onPressed: _reviewingStrokeIndex < _strokes.length - 1
                              ? () {
                                  setState(() {
                                    _reviewingStrokeIndex++;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // 書き込みモード時のコントロール
            if (_mode == DrawMode.writing) const SizedBox(height: 60),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
