part of 'view.dart';

class PlaybackSpeedMenuEntry extends PopupMenuEntry<void> {
  const PlaybackSpeedMenuEntry({
    required this.initialSpeed,
    required this.presetSpeeds,
    required this.onSpeedChanged,
    super.key,
  });

  final double initialSpeed;
  final List<double> presetSpeeds;
  final ValueChanged<double> onSpeedChanged;

  @override
  double get height => 214;

  @override
  bool represents(void value) => false;

  @override
  State<PlaybackSpeedMenuEntry> createState() => _PlaybackSpeedMenuEntryState();
}

class _PlaybackSpeedMenuEntryState extends State<PlaybackSpeedMenuEntry> {
  static const _minSpeed = 0.25;
  static const _step = 0.05;
  static const _presetSpeeds = [0.5, 1.0, 1.5, 2.0];

  late double _speed;
  late double _maxSpeed;

  @override
  void initState() {
    super.initState();
    _maxSpeed = math.max(
      3,
      widget.presetSpeeds.isEmpty ? 3 : widget.presetSpeeds.max,
    );
    _speed = widget.initialSpeed.clamp(_minSpeed, _maxSpeed);
  }

  double _normalizedSpeed(double speed) {
    return ((speed / _step).round() * _step)
        .clamp(_minSpeed, _maxSpeed)
        .toDouble();
  }

  void _setSpeed(double speed) {
    final nextSpeed = _normalizedSpeed(speed);
    setState(() => _speed = nextSpeed);
    widget.onSpeedChanged(nextSpeed);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '播放速度调节',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 30,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '播放速度',
                  style: TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: Center(
                child: Text(
                  '${_speed.toStringAsFixed(2)}x',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  _SpeedStepButton(
                    icon: Icons.remove_rounded,
                    tooltip: '降低播放速度',
                    onPressed: _speed <= _minSpeed
                        ? null
                        : () => _setSpeed(_speed - _step),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withValues(
                          alpha: 0.28,
                        ),
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withValues(alpha: 0.10),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                      ),
                      child: Slider(
                        value: _speed,
                        min: _minSpeed,
                        max: _maxSpeed,
                        divisions: ((_maxSpeed - _minSpeed) / _step).round(),
                        semanticFormatterCallback: (value) =>
                            '${value.toStringAsFixed(2)}倍速',
                        onChanged: (value) {
                          setState(() => _speed = _normalizedSpeed(value));
                        },
                        onChangeEnd: (value) {
                          widget.onSpeedChanged(_normalizedSpeed(value));
                        },
                      ),
                    ),
                  ),
                  _SpeedStepButton(
                    icon: Icons.add_rounded,
                    tooltip: '提高播放速度',
                    onPressed: _speed >= _maxSpeed
                        ? null
                        : () => _setSpeed(_speed + _step),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  for (final (index, speed) in _presetSpeeds.indexed) ...[
                    if (index > 0) const SizedBox(width: 6),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final isSelected = (_speed - speed).abs() < 0.001;
                          return Semantics(
                            selected: isSelected,
                            button: true,
                            label:
                                '${_PLVideoPlayerState._formatPlaybackSpeed(speed)}倍速',
                            child: Material(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.18)
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: AppRadii.fullAll,
                              child: InkWell(
                                borderRadius: AppRadii.fullAll,
                                onTap: () => _setSpeed(speed),
                                child: Center(
                                  child: Text(
                                    speed == 1
                                        ? '正常'
                                        : '${_PLVideoPlayerState._formatPlaybackSpeed(speed)}x',
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: isSelected ? 1 : 0.78,
                                      ),
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedStepButton extends StatelessWidget {
  const _SpeedStepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.10),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.04),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.25),
        ),
        icon: Icon(icon, size: 19),
      ),
    );
  }
}

Widget buildDmChart(
  Color color,
  List<double> dmTrend,
  VideoDetailController videoDetailController, [
  double offset = 0,
]) {
  return IgnorePointer(
    child: Container(
      height: 12,
      margin: EdgeInsets.only(
        bottom:
            videoDetailController.viewPointList.isNotEmpty &&
                videoDetailController.showVP.value
            ? 19.25 + offset
            : 4.25 + offset,
      ),
      child: LineChart(
        LineChartData(
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (dmTrend.length - 1).toDouble(),
          minY: 0,
          maxY: dmTrend.max,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                dmTrend.length,
                (index) => FlSpot(
                  index.toDouble(),
                  dmTrend[index],
                ),
              ),
              isCurved: true,
              barWidth: 1,
              color: color,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// 进度条高度 + 少量间距（适配膨胀态 expandedThumbRadius=10）
const _kProgressBarOffset = 16.0;

Widget buildSeekPreviewWidget(
  PlPlayerController plPlayerController,
  double maxWidth,
  double maxHeight,
  ValueGetter<bool> isMounted,
) {
  return Obx(() {
    if (!plPlayerController.showPreview.value) {
      return const SizedBox.shrink();
    }

    try {
      final data = plPlayerController.videoShot!.data;

      final double scale =
          plPlayerController.isFullScreen.value &&
              (PlatformUtils.isDesktop || !plPlayerController.isVertical)
          ? 4
          : 3;
      double thumbHeight = 27 * scale;
      final compatHeight = maxHeight - 140;
      if (compatHeight > 50) {
        thumbHeight = math.min(thumbHeight, compatHeight);
      }

      final int imgXLen = data.imgXLen;
      final int imgYLen = data.imgYLen;
      final int totalPerImage = data.totalPerImage;
      double imgXSize = data.imgXSize;
      double imgYSize = data.imgYSize;

      return Obx(() {
        final index = plPlayerController.previewIndex.value;
        if (index == null) return const SizedBox.shrink();

        final ratio = plPlayerController.previewRatio.value;
        final int pageIndex = (index ~/ totalPerImage).clamp(
          0,
          data.image.length - 1,
        );
        final int align = index % totalPerImage;
        final int x = align % imgXLen;
        final int y = align ~/ imgYLen;
        final url = data.image[pageIndex];

        // 预览图宽度（先用高度比估算，VideoShotImage 加载后会更新 imgXSize）
        final thumbWidth = imgXSize > 0
            ? thumbHeight * imgXSize / imgYSize
            : thumbHeight * 16 / 9;

        // 水平位置：跟随拖动比例，夹紧边缘
        final halfW = thumbWidth / 2;
        final rawLeft = ratio * maxWidth - halfW;
        final left = rawLeft.clamp(8.0, maxWidth - thumbWidth - 8);

        // 时间戳
        final totalMs = plPlayerController.duration.value.inMilliseconds;
        final posMs = (ratio * totalMs).round();
        final timeStr = DurationUtils.formatDuration(posMs ~/ 1000);

        return Positioned(
          left: left,
          bottom: _kProgressBarOffset,
          child: AnimatedSwitcher(
            duration: FluidTokens.durationSm,
            switchInCurve: FluidTokens.curveEnter,
            switchOutCurve: FluidTokens.curveExit,
            child: Column(
              key: ValueKey(index),
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: Style.mdRadius,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: VideoShotImage(
                      url: url,
                      x: x,
                      y: y,
                      imgXSize: imgXSize,
                      imgYSize: imgYSize,
                      height: thumbHeight,
                      imageCache: plPlayerController.previewCache,
                      onSetSize: (xSize, ySize) => data
                        ..imgXSize = imgXSize = xSize
                        ..imgYSize = imgYSize = ySize,
                      isMounted: isMounted,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
        );
      });
    } catch (e) {
      if (kDebugMode) rethrow;
      return const SizedBox.shrink();
    }
  });
}

class VideoShotImage extends StatefulWidget {
  const VideoShotImage({
    super.key,
    required this.imageCache,
    required this.url,
    required this.x,
    required this.y,
    required this.imgXSize,
    required this.imgYSize,
    required this.height,
    required this.onSetSize,
    required this.isMounted,
  });

  final Map<String, ui.Image?> imageCache;
  final String url;
  final int x;
  final int y;
  final double imgXSize;
  final double imgYSize;
  final double height;
  final Function(double imgXSize, double imgYSize) onSetSize;
  final ValueGetter<bool> isMounted;

  @override
  State<VideoShotImage> createState() => _VideoShotImageState();
}

Future<ui.Image?> _getImg(String url) async {
  final cacheKey = Utils.getFileName(url, fileExt: false);
  try {
    final fileInfo = await CacheManager.manager.getSingleFile(
      ImageUtils.safeThumbnailUrl(url),
      key: cacheKey,
      headers: Constants.baseHeaders,
    );
    return await _loadImg(fileInfo.path);
  } catch (_) {
    return null;
  }
}

Future<ui.Image?> _loadImg(String path) async {
  final codec = await ui.instantiateImageCodecFromBuffer(
    await ImmutableBuffer.fromFilePath(path),
  );
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

class _VideoShotImageState extends State<VideoShotImage> {
  late Size _size;
  late Rect _srcRect;
  late Rect _dstRect;
  late RRect _rrect;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _initSize();
    _loadImg();
  }

  void _initSizeIfNeeded() {
    if (_size.width.isNaN) {
      _initSize();
    }
  }

  void _initSize() {
    if (widget.imgXSize == 0) {
      if (_image != null) {
        final imgXSize = _image!.width / 10;
        final imgYSize = _image!.height / 10;
        final height = widget.height;
        final width = height * imgXSize / imgYSize;
        _setRect(width, height);
        _setSrcRect(imgXSize, imgYSize);
        widget.onSetSize(imgXSize, imgYSize);
      } else {
        _setRect(double.nan, double.nan);
        _setSrcRect(widget.imgXSize, widget.imgYSize);
      }
    } else {
      final height = widget.height;
      final width = height * widget.imgXSize / widget.imgYSize;
      _setRect(width, height);
      _setSrcRect(widget.imgXSize, widget.imgYSize);
    }
  }

  void _setRect(double width, double height) {
    _size = Size(width, height);
    _dstRect = Rect.fromLTRB(0, 0, width, height);
    _rrect = RRect.fromRectAndRadius(_dstRect, const Radius.circular(10));
  }

  void _setSrcRect(double imgXSize, double imgYSize) {
    _srcRect = Rect.fromLTWH(
      widget.x * imgXSize,
      widget.y * imgYSize,
      imgXSize,
      imgYSize,
    );
  }

  void _loadImg() {
    final url = widget.url;
    _image = widget.imageCache[url];
    if (_image != null) {
      _initSizeIfNeeded();
    } else if (!widget.imageCache.containsKey(url)) {
      widget.imageCache[url] = null;
      _getImg(url).then((image) {
        if (image != null) {
          if (widget.isMounted()) {
            widget.imageCache[url] = image;
          }
          if (mounted) {
            _image = image;
            _initSizeIfNeeded();
            setState(() {});
          }
        } else {
          widget.imageCache.remove(url);
        }
      });
    }
  }

  @override
  void didUpdateWidget(VideoShotImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadImg();
    }
    if (oldWidget.x != widget.x || oldWidget.y != widget.y) {
      _setSrcRect(widget.imgXSize, widget.imgYSize);
    }
  }

  late final _imgPaint = Paint()..filterQuality = FilterQuality.medium;
  late final _borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    if (_image != null) {
      return CroppedImage(
        size: _size,
        image: _image!,
        srcRect: _srcRect,
        dstRect: _dstRect,
        rrect: _rrect,
        imgPaint: _imgPaint,
        borderPaint: _borderPaint,
      );
    }
    return const SizedBox.shrink();
  }
}

const double _triangleHeight = 5.6;

class _DanmakuTip extends SingleChildRenderObjectWidget {
  const _DanmakuTip({
    this.offset = 0,
    super.child,
  });

  final double offset;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderDanmakuTip(offset: offset);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderDanmakuTip renderObject,
  ) {
    renderObject.offset = offset;
  }
}

class _RenderDanmakuTip extends RenderProxyBox {
  _RenderDanmakuTip({
    required this._offset,
  });

  double _offset;
  double get offset => _offset;
  set offset(double value) {
    if (_offset == value) return;
    _offset = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final paint = Paint()
      ..color = const Color(0xB3000000)
      ..style = .fill;

    final radius = size.height / 2;
    const triangleBase = _triangleHeight * 2 / 3;

    final triangleCenterX = (size.width / 2 + _offset).clamp(
      radius + triangleBase,
      size.width - radius - triangleBase,
    );
    final path = Path()
      // triangle (exceed)
      ..moveTo(triangleCenterX - triangleBase, 0)
      ..lineTo(triangleCenterX, -_triangleHeight)
      ..lineTo(triangleCenterX + triangleBase, 0)
      // top
      ..lineTo(size.width - radius, 0)
      // right
      ..arcToPoint(
        Offset(size.width - radius, size.height),
        radius: Radius.circular(radius),
      )
      // bottom
      ..lineTo(radius, size.height)
      // left
      ..arcToPoint(
        Offset(radius, 0),
        radius: Radius.circular(radius),
      )
      ..close();

    context.canvas
      ..save()
      ..translate(offset.dx, offset.dy)
      ..drawPath(path, paint)
      ..drawPath(
        path,
        paint
          ..color = const Color(0x7EFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.25,
      )
      ..restore();

    super.paint(context, offset);
  }
}

class _VideoTime extends LeafRenderObjectWidget {
  const _VideoTime({
    required this.position,
    required this.duration,
  });

  final String position;
  final String duration;

  @override
  _RenderVideoTime createRenderObject(BuildContext context) => _RenderVideoTime(
    position: position,
    duration: duration,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderVideoTime renderObject,
  ) {
    renderObject
      ..position = position
      ..duration = duration;
  }
}

class _RenderVideoTime extends RenderBox {
  _RenderVideoTime({
    required this._position,
    required this._duration,
  });

  String _duration;
  set duration(String value) {
    _duration = value;
    final paragraph = _buildParagraph(const Color(0xFFD0D0D0), _duration);
    if (paragraph.maxIntrinsicWidth != _cache?.maxIntrinsicWidth) {
      markNeedsLayout();
    }
    _cache?.dispose();
    _cache = paragraph;
    markNeedsSemanticsUpdate();
  }

  String _position;
  set position(String value) {
    _position = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  ui.Paragraph? _cache;

  ui.Paragraph _buildParagraph(Color color, String time) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              fontSize: 10,
              height: 1.4,
              fontFamily: 'Monospace',
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: color,
              fontSize: 10,
              height: 1.4,
              fontFamily: 'Monospace',
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          )
          ..addText(time);
    return builder.build()
      ..layout(const ui.ParagraphConstraints(width: .infinity));
  }

  @override
  ui.Size computeDryLayout(covariant BoxConstraints constraints) {
    final paragraph = _cache ??= _buildParagraph(
      const Color(0xFFD0D0D0),
      _duration,
    );
    return Size(paragraph.maxIntrinsicWidth, paragraph.height * 2);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..textDirection = TextDirection.ltr
      ..label = 'position:$_position\nduration:$_duration';
  }

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  @override
  void paint(PaintingContext context, ui.Offset offset) {
    final para = _buildParagraph(Colors.white, _position);
    context.canvas
      ..drawParagraph(
        para,
        Offset(
          offset.dx + _cache!.maxIntrinsicWidth - para.maxIntrinsicWidth,
          offset.dy,
        ),
      )
      ..drawParagraph(_cache!, Offset(offset.dx, offset.dy + para.height));
    para.dispose();
  }

  @override
  void dispose() {
    _cache?.dispose();
    _cache = null;
    super.dispose();
  }

  @override
  bool get isRepaintBoundary => true;
}
