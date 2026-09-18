import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../ast/options.dart';
import '../ast/style.dart';
import '../ast/syntax_tree.dart';
import '../parser/tex/parse_error.dart';
import '../parser/tex/parser.dart';
import '../parser/tex/settings.dart';
import 'controller.dart';
import 'exception.dart';
import 'math.dart';
import 'mode.dart';

const defaultSelection = TextSelection.collapsed(offset: -1);

/// Selectable math widget.
///
/// On top of non-selectable [Math], it adds selection functionality. Users can
/// select by long press gesture, drag gesture, moving selection handles or
/// pointer selection. The selected region can be encoded into TeX and copied
/// to clipboard.
///
/// See [SelectableText] as this widget aims to fully imitate its behavior.
class SelectableMath extends StatelessWidget {
  /// SelectableMath default constructor.
  ///
  /// Requires either a parsed [ast] or a [parseException].
  ///
  /// See [SelectableMath] for its member documentation.
  const SelectableMath({
    Key? key,
    this.ast,
    this.autofocus = false,
    this.cursorColor,
    this.cursorRadius,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection = true,
    this.focusNode,
    this.mathStyle = MathStyle.display,
    this.logicalPpi,
    this.onErrorFallback = defaultOnErrorFallback,
    this.options,
    this.parseException,
    this.showCursor = false,
    this.textScaleFactor,
    this.textSelectionControls,
    this.textStyle,
    ToolbarOptions? toolbarOptions,
    this.selectionText,
  })  : assert(ast != null || parseException != null),
        toolbarOptions = toolbarOptions ??
            const ToolbarOptions(
              selectAll: true,
              copy: true,
            ),
        super(key: key);

  /// The equation to display.
  ///
  /// It can be null only when [parseException] is not null.
  final SyntaxTree? ast;

  /// {@macro flutter.widgets.editableText.autofocus}
  final bool autofocus;

  /// The color to use when painting the cursor.
  ///
  /// Defaults to the theme's `cursorColor` when null.
  final Color? cursorColor;

  /// {@macro flutter.widgets.editableText.cursorRadius}
  final Radius? cursorRadius;

  /// {@macro flutter.widgets.editableText.cursorWidth}
  final double cursorWidth;

  /// {@macro flutter.widgets.editableText.cursorHeight}
  final double? cursorHeight;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.widgets.editableText.enableInteractiveSelection}
  final bool enableInteractiveSelection;

  /// Defines the focus for this widget.
  ///
  /// Math is only selectable when widget is focused.
  ///
  /// The [focusNode] is a long-lived object that's typically managed by a
  /// [StatefulWidget] parent. See [FocusNode] for more information.
  ///
  /// To give the focus to this widget, provide a [focusNode] and then
  /// use the current [FocusScope] to request the focus:
  ///
  /// ```dart
  /// FocusScope.of(context).requestFocus(myFocusNode);
  /// ```
  ///
  /// This happens automatically when the widget is tapped.
  ///
  /// To be notified when the widget gains or loses the focus, add a listener
  /// to the [focusNode]:
  ///
  /// ```dart
  /// focusNode.addListener(() { print(myFocusNode.hasFocus); });
  /// ```
  ///
  /// If null, this widget will create its own [FocusNode].
  final FocusNode? focusNode;

  /// {@macro flutter_math_fork.widgets.math.mathStyle}
  final MathStyle mathStyle;

  /// {@macro flutter_math_fork.widgets.math.logicalPpi}
  final double? logicalPpi;

  /// {@macro flutter_math_fork.widgets.math.onErrorFallback}
  final OnErrorFallback onErrorFallback;

  /// {@macro flutter_math_fork.widgets.math.options}
  final MathOptions? options;

  /// {@macro flutter_math_fork.widgets.math.parseError}
  final ParseException? parseException;

  /// {@macro flutter.widgets.editableText.showCursor}
  final bool showCursor;

  /// {@macro flutter.widgets.editableText.textScaleFactor}
  final double? textScaleFactor;

  /// Optional delegate for building the text selection handles and toolbar.
  ///
  /// Just works like [EditableText.selectionControls]
  final TextSelectionControls? textSelectionControls;

  /// {@macro fluttermath.widgets.math.textStyle}
  final TextStyle? textStyle;

  /// Configuration of toolbar options.
  ///
  /// Paste and cut will be disabled regardless.
  ///
  /// If not set, select all and copy will be enabled by default.
  final ToolbarOptions toolbarOptions;

  /// Raw text returned when the whole math expression is selected/copied.
  ///
  /// This is intentionally treated as one selectable unit. It can contain
  /// the original TeX delimiters if the caller wants them copied.
  final String? selectionText;

  /// SelectableMath builder using a TeX string
  ///
  /// {@macro flutter_math_fork.widgets.math.tex_builder}
  ///
  /// See alse:
  ///
  /// * [SelectableMath.mathStyle]
  /// * [SelectableMath.textStyle]
  factory SelectableMath.tex(
    String expression, {
    Key? key,
    TexParserSettings settings = const TexParserSettings(),
    MathOptions? options,
    OnErrorFallback onErrorFallback = defaultOnErrorFallback,
    bool autofocus = false,
    Color? cursorColor,
    Radius? cursorRadius,
    double cursorWidth = 2.0,
    double? cursorHeight,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    bool enableInteractiveSelection = true,
    FocusNode? focusNode,
    MathStyle mathStyle = MathStyle.display,
    double? logicalPpi,
    bool showCursor = false,
    double? textScaleFactor,
    TextSelectionControls? textSelectionControls,
    TextStyle? textStyle,
    ToolbarOptions? toolbarOptions,
    String? selectionText,
  }) {
    SyntaxTree? ast;
    ParseException? parseError;
    try {
      ast = SyntaxTree(greenRoot: TexParser(expression, settings).parse());
    } on ParseException catch (e) {
      parseError = e;
    } on Object catch (e) {
      parseError = ParseException('Unsanitized parse exception detected: $e.'
          'Please report this error with correponding input.');
    }
    return SelectableMath(
      key: key,
      ast: ast,
      autofocus: autofocus,
      cursorColor: cursorColor,
      cursorRadius: cursorRadius,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      dragStartBehavior: dragStartBehavior,
      enableInteractiveSelection: enableInteractiveSelection,
      focusNode: focusNode,
      mathStyle: mathStyle,
      logicalPpi: logicalPpi,
      onErrorFallback: onErrorFallback,
      options: options,
      parseException: parseError,
      showCursor: showCursor,
      textScaleFactor: textScaleFactor,
      textSelectionControls: textSelectionControls,
      textStyle: textStyle,
      toolbarOptions: toolbarOptions,
      selectionText: selectionText ?? expression,
    );
  }

  Widget build(BuildContext context) {
    if (parseException != null) {
      return onErrorFallback(parseException!);
    }

    var effectiveTextStyle = textStyle;
    if (effectiveTextStyle == null || effectiveTextStyle.inherit) {
      effectiveTextStyle = DefaultTextStyle.of(context).style.merge(textStyle);
    }
    if (MediaQuery.boldTextOf(context)) {
      effectiveTextStyle = effectiveTextStyle.merge(const TextStyle(fontWeight: FontWeight.bold));
    }

    final textScaleFactor = this.textScaleFactor ?? MediaQuery.textScaleFactorOf(context);

    final options = this.options ??
        MathOptions(
          style: mathStyle,
          fontSize: effectiveTextStyle.fontSize! * textScaleFactor,
          mathFontOptions: effectiveTextStyle.fontWeight != FontWeight.normal && effectiveTextStyle.fontWeight != null
              ? FontOptions(fontWeight: effectiveTextStyle.fontWeight!)
              : null,
          logicalPpi: logicalPpi,
          color: effectiveTextStyle.color!,
        );

    // A trial build to catch any potential build errors
    try {
      ast!.buildWidget(options);
    } on BuildException catch (e) {
      return onErrorFallback(e);
    } on Object catch (e) {
      return onErrorFallback(BuildException('Unsanitized build exception detected: $e.'
          'Please report this error with correponding input.'));
    }

    final theme = Theme.of(context);
    // The following code adapts for Flutter's new theme system (https://github.com/flutter/flutter/pull/62014/)
    final selectionTheme = TextSelectionTheme.of(context);

    var textSelectionControls = this.textSelectionControls;
    bool paintCursorAboveText;
    bool cursorOpacityAnimates;
    Offset? cursorOffset;
    var cursorColor = this.cursorColor;
    Color selectionColor;
    var cursorRadius = this.cursorRadius;
    bool forcePressEnabled;

    switch (theme.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        forcePressEnabled = true;
        textSelectionControls ??= cupertinoTextSelectionControls;
        paintCursorAboveText = true;
        cursorOpacityAnimates = true;
        cursorColor ??= selectionTheme.cursorColor ?? CupertinoTheme.of(context).primaryColor;
        selectionColor = selectionTheme.selectionColor ?? CupertinoTheme.of(context).primaryColor;

        cursorRadius ??= const Radius.circular(2.0);
        cursorOffset = Offset(iOSHorizontalOffset / MediaQuery.of(context).devicePixelRatio, 0);
        break;

      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        forcePressEnabled = false;
        textSelectionControls ??= materialTextSelectionControls;
        paintCursorAboveText = false;
        cursorOpacityAnimates = false;
        cursorColor ??= selectionTheme.cursorColor ?? theme.colorScheme.primary;
        selectionColor = selectionTheme.selectionColor ?? theme.colorScheme.primary;

        break;
    }

    return RepaintBoundary(
      child: InternalSelectableMath(
        ast: ast!,
        options: options,
        cursorColor: cursorColor,
        selectionColor: selectionColor,
        selectionText: selectionText,
      ),
    );
  }

  /// Default fallback function for [Math], [SelectableMath]
  static Widget defaultOnErrorFallback(FlutterMathException error) => Math.defaultOnErrorFallback(error);
}

/// The internal widget for [SelectableMath].
///
/// This implementation participates in Flutter's modern Selection API.
/// The complete math expression is treated as one selectable unit.
///
/// That means:
///   Text -> Math -> Text
///
/// can be selected as one SelectionArea, while copying the math returns
/// [selectionText] verbatim.
class InternalSelectableMath extends StatefulWidget {
  const InternalSelectableMath({
    Key? key,
    required this.ast,
    required this.options,
    required this.cursorColor,
    required this.selectionColor,
    this.selectionText,
  }) : super(key: key);

  final SyntaxTree ast;
  final MathOptions options;
  final Color cursorColor;
  final Color? selectionColor;
  final String? selectionText;

  @override
  State<InternalSelectableMath> createState() => _InternalSelectableMathState();
}

class _InternalSelectableMathState extends State<InternalSelectableMath> {
  late MathController controller;

  @override
  void initState() {
    super.initState();

    controller = MathController(
      ast: widget.ast,
    );
  }

  @override
  void didUpdateWidget(
    covariant InternalSelectableMath oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.ast != widget.ast) {
      controller.dispose();

      controller = MathController(
        ast: widget.ast,
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SelectionRegistrar? registrar = SelectionContainer.maybeOf(context);

    final Widget math = Provider<FlutterMathMode>.value(
      value: FlutterMathMode.view,
      child: controller.ast.buildWidget(
        widget.options,
      ),
    );

    // Outside SelectionArea/SelectableRegion there is no registrar.
    // In that case SelectableMath simply behaves like normal Math.
    if (registrar == null) {
      return math;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: _SelectableMathAdapter(
        registrar: registrar,
        selectionColor: widget.selectionColor ?? DefaultSelectionStyle.of(context).selectionColor!,
        selectionText: widget.selectionText ?? '',
        child: math,
      ),
    );
  }
}

/// Adapter that makes the rendered math participate in Flutter's
/// SelectionArea/SelectableRegion selection tree.
class _SelectableMathAdapter extends SingleChildRenderObjectWidget {
  const _SelectableMathAdapter({
    required this.registrar,
    required this.selectionColor,
    required this.selectionText,
    required Widget child,
  }) : super(child: child);

  final SelectionRegistrar registrar;
  final Color selectionColor;
  final String selectionText;

  @override
  _RenderSelectableMathAdapter createRenderObject(
    BuildContext context,
  ) {
    return _RenderSelectableMathAdapter(
      selectionColor,
      selectionText,
      registrar,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSelectableMathAdapter renderObject,
  ) {
    renderObject
      ..selectionColor = selectionColor
      ..selectionText = selectionText
      ..registrar = registrar;
  }
}

/// A selectable render object representing one complete math expression.
///
/// The important design decision here is:
///
///     contentLength == 1
///
/// The math is therefore one logical selectable unit. We do not try to map
/// screen coordinates to individual AST nodes or TeX characters.
///
/// This makes it possible for Flutter's SelectionContainer to move selection
/// from:
///
///     Text -> Math -> Text
///
/// while [getSelectedContent] returns the original raw TeX for the math.
class _RenderSelectableMathAdapter extends RenderProxyBox with Selectable, SelectionRegistrant {
  _RenderSelectableMathAdapter(
    Color selectionColor,
    String selectionText,
    SelectionRegistrar registrar,
  )   : _selectionColor = selectionColor,
        _selectionText = selectionText,
        _geometry = ValueNotifier<SelectionGeometry>(
          _noSelection,
        ) {
    this.registrar = registrar;
    _geometry.addListener(markNeedsPaint);
  }

  static const SelectionGeometry _noSelection = SelectionGeometry(
    status: SelectionStatus.none,
    hasContent: true,
  );

  final ValueNotifier<SelectionGeometry> _geometry;

  Color _selectionColor;

  Color get selectionColor => _selectionColor;

  set selectionColor(Color value) {
    if (_selectionColor == value) {
      return;
    }

    _selectionColor = value;
    markNeedsPaint();
  }

  String _selectionText;

  String get selectionText => _selectionText;

  set selectionText(String value) {
    if (_selectionText == value) {
      return;
    }

    _selectionText = value;
  }

  // ---------------------------------------------------------------------------
  // ValueListenable<SelectionGeometry>
  // ---------------------------------------------------------------------------

  @override
  void addListener(VoidCallback listener) {
    _geometry.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _geometry.removeListener(listener);
  }

  @override
  SelectionGeometry get value => _geometry.value;

  // ---------------------------------------------------------------------------
  // Selectable
  // ---------------------------------------------------------------------------

  @override
  List<Rect> get boundingBoxes => <Rect>[paintBounds];

  @override
  int get contentLength => 1;

  Offset? _start;
  Offset? _end;

  LayerLink? _startHandle;
  LayerLink? _endHandle;

  void _updateGeometry() {
    if (_start == null || _end == null) {
      _geometry.value = _noSelection;
      return;
    }

    final Rect renderObjectRect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );

    final Rect selectionRect = Rect.fromPoints(
      _start!,
      _end!,
    );

    if (renderObjectRect.intersect(selectionRect).isEmpty) {
      _geometry.value = _noSelection;
      return;
    }

    final Rect highlightRect = renderObjectRect;

    final SelectionPoint firstSelectionPoint = SelectionPoint(
      localPosition: highlightRect.bottomLeft,
      lineHeight: highlightRect.height,
      handleType: TextSelectionHandleType.left,
    );

    final SelectionPoint secondSelectionPoint = SelectionPoint(
      localPosition: highlightRect.bottomRight,
      lineHeight: highlightRect.height,
      handleType: TextSelectionHandleType.right,
    );

    final bool isReversed;

    if (_start!.dy > _end!.dy) {
      isReversed = true;
    } else if (_start!.dy < _end!.dy) {
      isReversed = false;
    } else {
      isReversed = _start!.dx > _end!.dx;
    }

    _geometry.value = SelectionGeometry(
      status: SelectionStatus.uncollapsed,
      hasContent: true,
      startSelectionPoint: isReversed ? secondSelectionPoint : firstSelectionPoint,
      endSelectionPoint: isReversed ? firstSelectionPoint : secondSelectionPoint,
      selectionRects: <Rect>[
        highlightRect,
      ],
    );
  }

  @override
  SelectionResult dispatchSelectionEvent(
    SelectionEvent event,
  ) {
    SelectionResult result = SelectionResult.none;

    switch (event.type) {
      case SelectionEventType.startEdgeUpdate:
      case SelectionEventType.endEdgeUpdate:
        final Rect renderObjectRect = Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        );

        final Offset point = globalToLocal(
          (event as SelectionEdgeUpdateEvent).globalPosition,
        );

        final Offset adjustedPoint = SelectionUtils.adjustDragOffset(
          renderObjectRect,
          point,
        );

        if (event.type == SelectionEventType.startEdgeUpdate) {
          _start = adjustedPoint;
        } else {
          _end = adjustedPoint;
        }

        result = SelectionUtils.getResultBasedOnRect(
          renderObjectRect,
          point,
        );
        break;

      case SelectionEventType.clear:
        _start = null;
        _end = null;
        break;

      case SelectionEventType.selectAll:
      case SelectionEventType.selectWord:
      case SelectionEventType.selectParagraph:
        // The complete formula is one logical selectable unit.
        _start = Offset.zero;
        _end = Offset.infinite;
        break;

      case SelectionEventType.granularlyExtendSelection:
        result = SelectionResult.end;

        final GranularlyExtendSelectionEvent extendSelectionEvent = event as GranularlyExtendSelectionEvent;

        if (_start == null || _end == null) {
          if (extendSelectionEvent.forward) {
            _start = _end = Offset.zero;
          } else {
            _start = _end = Offset.infinite;
          }
        }

        final Offset newOffset = extendSelectionEvent.forward ? Offset.infinite : Offset.zero;

        if (extendSelectionEvent.isEnd) {
          if (newOffset == _end) {
            result = extendSelectionEvent.forward ? SelectionResult.next : SelectionResult.previous;
          }

          _end = newOffset;
        } else {
          if (newOffset == _start) {
            result = extendSelectionEvent.forward ? SelectionResult.next : SelectionResult.previous;
          }

          _start = newOffset;
        }
        break;

      case SelectionEventType.directionallyExtendSelection:
        result = SelectionResult.end;

        final DirectionallyExtendSelectionEvent extendSelectionEvent = event as DirectionallyExtendSelectionEvent;

        final double horizontalBaseLine = globalToLocal(
          Offset(event.dx, 0),
        ).dx;

        final Offset newOffset;
        final bool forward;

        switch (extendSelectionEvent.direction) {
          case SelectionExtendDirection.backward:
          case SelectionExtendDirection.previousLine:
            forward = false;

            if (_start == null || _end == null) {
              _start = _end = Offset.infinite;
            }

            if (extendSelectionEvent.direction == SelectionExtendDirection.previousLine || horizontalBaseLine < 0) {
              newOffset = Offset.zero;
            } else {
              newOffset = Offset.infinite;
            }
            break;

          case SelectionExtendDirection.nextLine:
          case SelectionExtendDirection.forward:
            forward = true;

            if (_start == null || _end == null) {
              _start = _end = Offset.zero;
            }

            if (extendSelectionEvent.direction == SelectionExtendDirection.nextLine || horizontalBaseLine > size.width) {
              newOffset = Offset.infinite;
            } else {
              newOffset = Offset.zero;
            }
            break;
        }

        if (extendSelectionEvent.isEnd) {
          if (newOffset == _end) {
            result = forward ? SelectionResult.next : SelectionResult.previous;
          }

          _end = newOffset;
        } else {
          if (newOffset == _start) {
            result = forward ? SelectionResult.next : SelectionResult.previous;
          }

          _start = newOffset;
        }
        break;
    }

    _updateGeometry();

    return result;
  }

  // ---------------------------------------------------------------------------
  // Copy
  // ---------------------------------------------------------------------------

  @override
  SelectedContent? getSelectedContent() {
    if (!value.hasSelection) {
      return null;
    }

    return SelectedContent(
      plainText: _selectionText,
    );
  }

  @override
  SelectedContentRange? getSelection() {
    if (!value.hasSelection) {
      return null;
    }

    // The complete formula is one logical character/unit.
    return const SelectedContentRange(
      startOffset: 0,
      endOffset: 1,
    );
  }

  // ---------------------------------------------------------------------------
  // Selection handles
  // ---------------------------------------------------------------------------

  @override
  void pushHandleLayers(
    LayerLink? startHandle,
    LayerLink? endHandle,
  ) {
    if (_startHandle == startHandle && _endHandle == endHandle) {
      return;
    }

    _startHandle = startHandle;
    _endHandle = endHandle;

    markNeedsPaint();
  }

  // ---------------------------------------------------------------------------
  // Painting
  // ---------------------------------------------------------------------------

  @override
  void paint(
    PaintingContext context,
    Offset offset,
  ) {
    // 1. Vẽ background selection TRƯỚC
    // để công thức vẫn được vẽ lên phía trên.
    if (value.hasSelection) {
      final Paint selectionPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = _selectionColor;

      final Rect highlightRect = Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height,
      );

      context.canvas.drawRect(
        highlightRect.shift(offset),
        selectionPaint,
      );
    }

    // 2. Vẽ công thức lên trên selection background.
    super.paint(context, offset);

    // 3. Vẽ selection handles.
    if (!value.hasSelection) {
      return;
    }

    if (_startHandle != null && value.startSelectionPoint != null) {
      context.pushLayer(
        LeaderLayer(
          link: _startHandle!,
          offset: offset + value.startSelectionPoint!.localPosition,
        ),
        (PaintingContext context, Offset offset) {},
        Offset.zero,
      );
    }

    if (_endHandle != null && value.endSelectionPoint != null) {
      context.pushLayer(
        LeaderLayer(
          link: _endHandle!,
          offset: offset + value.endSelectionPoint!.localPosition,
        ),
        (PaintingContext context, Offset offset) {},
        Offset.zero,
      );
    }
  }

  @override
  void dispose() {
    _geometry.dispose();
    _startHandle = null;
    _endHandle = null;
    super.dispose();
  }
}

class SelectionStyle {
  final Color cursorColor;
  final Offset? cursorOffset;
  final Radius? cursorRadius;
  final double cursorWidth;
  final double? cursorHeight;
  final Color? hintingColor;
  final bool paintCursorAboveText;
  final Color? selectionColor;
  final bool showCursor;

  const SelectionStyle({
    required this.cursorColor,
    this.cursorOffset,
    this.cursorRadius,
    this.cursorWidth = 1.0,
    this.cursorHeight,
    this.hintingColor,
    this.paintCursorAboveText = false,
    this.selectionColor,
    this.showCursor = false,
  });

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is SelectionStyle &&
        o.cursorColor == cursorColor &&
        o.cursorOffset == cursorOffset &&
        o.cursorRadius == cursorRadius &&
        o.cursorWidth == cursorWidth &&
        o.cursorHeight == cursorHeight &&
        o.hintingColor == hintingColor &&
        o.paintCursorAboveText == paintCursorAboveText &&
        o.selectionColor == selectionColor &&
        o.showCursor == showCursor;
  }

  @override
  int get hashCode => Object.hash(
        cursorColor,
        cursorOffset,
        cursorRadius,
        cursorWidth,
        cursorHeight,
        hintingColor,
        paintCursorAboveText,
        selectionColor,
        showCursor,
      );
}
