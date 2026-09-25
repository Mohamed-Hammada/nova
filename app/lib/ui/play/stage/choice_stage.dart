import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nova_app/core/play/trials.dart';

import '../../design/components/storybook.dart';
import '../../design/tokens.dart';
import '../../widgets/props.dart';
import '../trial_context.dart';
import '../visual_view.dart';
import 'choice_look.dart';
import 'holders.dart';
import 'pointing_hand.dart';

/// Where one answer is in the round.
enum HolderState {
  /// Waiting to be chosen.
  idle,

  /// Chosen, and it was it.
  right,

  /// Chosen on an earlier try and not it: it rests, faded, and can't be
  /// chosen again, so the next try is a real new choice.
  tried,

  /// Floated away as a first-step hint: one fewer to think about.
  away,
}

/// A choice round played in the world: every answer is an object that
/// belongs to the place (see [ChoiceLook]). Answers arrive with movement
/// and bob gently. A right answer celebrates. A first miss is never the end:
/// that answer wobbles and rests, the companion encourages, and the child
/// tries again; after a second miss the companion's hand shows where the
/// answer is and the child taps it. Only the first try counts toward
/// accuracy (the session logs later tries as retries).
///
/// Help follows the scaffold: a demonstration shows the answer with the
/// hand, a first step floats one wrong answer away, and a hint on request
/// does the first step, then shows.
class ChoiceTrialView extends StatefulWidget {
  const ChoiceTrialView({super.key, required this.trial, required this.ctx});
  final ChoiceTrial trial;
  final TrialContext ctx;

  @override
  State<ChoiceTrialView> createState() => _ChoiceTrialViewState();
}

class _ChoiceTrialViewState extends State<ChoiceTrialView> {
  final _tried = <int>{};
  final _away = <int>{};
  final _timers = <Timer>[];
  final _answerKey = GlobalKey();
  int _attempt = 1;
  int? _chosen;
  int? _shaking;
  bool _hand = false;
  int _hintsHere = 0;

  ChoiceTrial get _t => widget.trial;
  int get _left => _t.options.length - _tried.length - _away.length;

  @override
  void initState() {
    super.initState();
    widget.ctx.hint.addListener(_onHint);
    widget.ctx.voicePick?.addListener(_onVoice);
    if (widget.ctx.startHelp != RoundHelp.none) {
      // Once the answers have arrived.
      _after(const Duration(milliseconds: 750), () => _help(widget.ctx.startHelp));
    }
  }

  @override
  void dispose() {
    widget.ctx.hint.removeListener(_onHint);
    widget.ctx.voicePick?.removeListener(_onVoice);
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _after(Duration d, VoidCallback f) => _timers.add(Timer(d, () {
        if (mounted) f();
      }));

  Offset? _answerCenter() {
    final box = _answerKey.currentContext?.findRenderObject() as RenderBox?;
    return box == null || !box.hasSize ? null : box.localToGlobal(box.size.center(Offset.zero));
  }

  void _onVoice() {
    final i = widget.ctx.voicePick?.value;
    if (i != null && i >= 0 && i < _t.options.length) _choose(i);
  }

  void _onHint() {
    if (_chosen != null) return;
    if (_t.speak != null) widget.ctx.speak(_t.speak!);
    _hintsHere++;
    _help(_hintsHere == 1 ? RoundHelp.firstStep : RoundHelp.show);
  }

  /// A first step floats one wrong answer away (when that still leaves a
  /// real choice); otherwise, and for a demonstration, the hand shows.
  void _help(RoundHelp help) {
    if (_chosen != null || help == RoundHelp.none) return;
    if (help == RoundHelp.firstStep) {
      final candidates = [for (var i = 0; i < _t.options.length; i++) if (i != _t.answer && !_tried.contains(i) && !_away.contains(i)) i];
      if (_left > 2 && candidates.isNotEmpty) {
        setState(() => _away.add(candidates[_t.answer % candidates.length]));
        widget.ctx.onMoment?.call(PlayMoment.firstStep, _answerCenter());
        return;
      }
    }
    setState(() => _hand = true);
    widget.ctx.onMoment?.call(PlayMoment.show, _answerCenter());
  }

  void _choose(int i) {
    if (_chosen != null || _tried.contains(i) || _away.contains(i)) return;
    final correct = _t.isCorrect(i);
    widget.ctx.onResponse(correct, attempt: _attempt);
    if (correct) {
      setState(() {
        _chosen = i;
        _hand = false;
      });
      _after(const Duration(milliseconds: 1100), widget.ctx.onDone);
      return;
    }
    setState(() {
      _tried.add(i);
      _shaking = i;
      _attempt++;
    });
    _after(const Duration(milliseconds: 480), () => setState(() => _shaking = null));
    if (_attempt > 2 || _left <= 1) {
      _after(const Duration(milliseconds: 900), () {
        if (_chosen != null) return;
        setState(() => _hand = true);
        widget.ctx.onMoment?.call(PlayMoment.reveal, _answerCenter());
      });
    }
  }

  HolderState _stateOf(int i) => i == _chosen
      ? HolderState.right
      : _tried.contains(i)
          ? HolderState.tried
          : _away.contains(i)
              ? HolderState.away
              : HolderState.idle;

  String _label(int i) {
    final l10n = widget.ctx.l10n;
    final v = _t.options[i];
    final what = switch (v) {
      TextVisual() => v.text,
      NumeralVisual() => numeral(v.value, widget.ctx.language),
      _ => l10n.choiceLabel(numeral(i + 1, widget.ctx.language)),
    };
    return _tried.contains(i) ? '$what. ${l10n.choiceTried}' : what;
  }

  @override
  Widget build(BuildContext context) {
    final look = widget.ctx.look;
    final holder = look.holder;
    return LayoutBuilder(
      builder: (context, box) {
        final n = _t.options.length;
        final hasQuestion = _t.question != null;
        const gap = 14.0;
        final short = math.min(box.maxWidth, box.maxHeight);
        final questionSize = (short * 0.3).clamp(76.0, 190.0);
        final questionHeight = hasQuestion ? questionSize + 24 + short * 0.04 : 0.0;
        final room = box.maxHeight - questionHeight - 8;
        // One row when it fits comfortably, otherwise two.
        final oneRow = (box.maxWidth - gap * (n - 1)) / n;
        final rows = n > 3 && oneRow < 110 ? 2 : 1;
        final cols = (n / rows).ceil();
        final width = math
            .min((box.maxWidth - gap * (cols - 1)) / cols, (room - gap * (rows - 1)) / rows / (holder.aspect + (holder == Holder.balloon || holder == Holder.bubble ? 0.12 : 0.04)))
            .clamp(64.0, _t.optionsAreBig ? 270.0 : 210.0);
        final content = HolderArt.contentSize(holder, width) * 0.94;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasQuestion) ...[
              QuestionFrame(look: look, child: VisualView(_t.question!, size: questionSize, language: widget.ctx.language)),
              SizedBox(height: short * 0.04),
            ],
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < n; i++)
                  ChoiceHolder(
                    key: i == _t.answer ? _answerKey : ValueKey('choice.$i'),
                    index: i,
                    look: look,
                    width: width,
                    state: _stateOf(i),
                    shaking: _shaking == i,
                    hand: _hand && i == _t.answer && _chosen == null,
                    mirrorHand: rtl,
                    delay: Duration(milliseconds: 90 * i),
                    phase: i * 0.27,
                    label: _label(i),
                    onTap: () => _choose(i),
                    child: VisualView(_t.options[i], size: content, language: widget.ctx.language),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// The frame around the question picture: a cream board with the place's
/// colour, pinned in the scene.
class QuestionFrame extends StatelessWidget {
  const QuestionFrame({super.key, required this.look, required this.child});
  final ChoiceLook look;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF2),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: look.deep, width: 4),
              boxShadow: const [BoxShadow(color: Color(0x332A1640), blurRadius: 14, offset: Offset(0, 6))],
            ),
            child: child,
          ),
          for (final side in [AlignmentDirectional.topStart, AlignmentDirectional.topEnd])
            Positioned.fill(
              top: -9,
              child: Align(
                alignment: side,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(color: look.tint, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                  ),
                ),
              ),
            ),
        ],
      );
}

/// One answer in the world. Tapping it chooses it.
class ChoiceHolder extends StatefulWidget {
  const ChoiceHolder({
    super.key,
    required this.index,
    required this.look,
    required this.width,
    required this.state,
    required this.label,
    required this.onTap,
    required this.child,
    this.shaking = false,
    this.hand = false,
    this.mirrorHand = false,
    this.delay = Duration.zero,
    this.phase = 0,
  });
  final int index;
  final ChoiceLook look;
  final double width;
  final HolderState state;
  final String label;
  final VoidCallback onTap;
  final Widget child;
  final bool shaking;

  /// The companion's hand is pointing at this one.
  final bool hand;
  final bool mirrorHand;
  final Duration delay;
  final double phase;

  bool get choosable => state == HolderState.idle;

  @override
  State<ChoiceHolder> createState() => _ChoiceHolderState();
}

class _ChoiceHolderState extends State<ChoiceHolder> with TickerProviderStateMixin {
  late final AnimationController _arrive = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  Timer? _start;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (NovaMotion.reduced(context)) {
      _arrive.value = 1;
    } else if (_arrive.value == 0 && _start == null) {
      _start = Timer(widget.delay, () {
        if (mounted) _arrive.forward();
      });
    }
  }

  @override
  void didUpdateWidget(ChoiceHolder old) {
    super.didUpdateWidget(old);
    if (widget.shaking && !old.shaking && !NovaMotion.reduced(context)) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _start?.cancel();
    _arrive.dispose();
    _shake.dispose();
    super.dispose();
  }

  Offset _arrivalOffset(double t, double h) {
    final k = 1 - t;
    return switch (widget.look.holder.arrival) {
      Arrival.drop => Offset(0, -h * 0.5 * k),
      Arrival.rise => Offset(0, h * 0.7 * k),
      Arrival.slide => Offset((Directionality.of(context) == TextDirection.rtl ? -1 : 1) * widget.width * 0.9 * k, 0),
      Arrival.pop => Offset.zero,
    };
  }

  @override
  Widget build(BuildContext context) {
    final holder = widget.look.holder;
    final h = widget.width * holder.aspect;
    final state = widget.state;
    final right = state == HolderState.right;
    final glow = right ? const Color(0xFF34C77B) : (widget.hand ? const Color(0xFFFFC83D) : null);

    Widget art = HolderArt(look: widget.look, width: widget.width, glow: glow, child: widget.child);

    // Success: floaty holders lift, the others hop, and a few stars burst.
    art = TweenAnimationBuilder<double>(
      tween: Tween(end: right ? 1 : 0),
      duration: NovaMotion.of(context, const Duration(milliseconds: 420)),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, -t * h * (holder.lifts ? 0.12 : 0.06)),
        child: Transform.scale(scale: 1 + t * 0.1, child: child),
      ),
      child: art,
    );

    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        art,
        if (right && !NovaMotion.reduced(context)) Positioned.fill(child: IgnorePointer(child: _StarBurst(size: widget.width))),
        if (widget.hand)
          PositionedDirectional(
            end: -widget.width * 0.12,
            bottom: h * 0.02,
            child: NovaPopIn(
              child: Transform.flip(flipX: widget.mirrorHand, child: PointingHand(size: (widget.width * 0.5).clamp(44.0, 96.0))),
            ),
          ),
      ],
    );

    final gone = state == HolderState.away;
    final rested = state == HolderState.tried;
    Widget body = AnimatedOpacity(
      duration: const Duration(milliseconds: 320),
      opacity: gone ? 0 : (rested ? 0.42 : 1),
      child: AnimatedSlide(
        duration: NovaMotion.of(context, const Duration(milliseconds: 520)),
        curve: Curves.easeInCubic,
        offset: gone ? Offset(0, holder.lifts ? -0.8 : 0.3) : Offset.zero,
        child: AnimatedScale(duration: const Duration(milliseconds: 260), scale: rested ? 0.9 : 1, child: stack),
      ),
    );

    body = AnimatedBuilder(
      animation: Listenable.merge([_arrive, _shake]),
      builder: (context, child) {
        final a = Curves.easeOutBack.transform(_arrive.value.clamp(0.0, 1.0));
        final shake = math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value);
        return Opacity(
          opacity: _arrive.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: _arrivalOffset(a, h) + Offset(shake, 0),
            child: Transform.scale(scale: holder.arrival == Arrival.pop ? 0.4 + 0.6 * a : 1, child: child),
          ),
        );
      },
      child: NovaFloat(phase: widget.phase, amplitude: widget.choosable ? 4 : 0, child: body),
    );

    return Semantics(
      button: true,
      enabled: widget.choosable,
      selected: right,
      label: widget.label,
      excludeSemantics: true,
      child: ExcludeSemantics(
        excluding: gone,
        child: IgnorePointer(
          ignoring: gone,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.choosable ? widget.onTap : null,
            child: SizedBox(width: widget.width, height: h, child: body),
          ),
        ),
      ),
    );
  }
}

/// A small burst of stars around a right answer.
class _StarBurst extends StatelessWidget {
  const _StarBurst({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        builder: (context, t, _) => LayoutBuilder(
          builder: (context, box) {
            final c = Offset(box.maxWidth / 2, box.maxHeight / 2);
            final star = size * 0.2;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < 6; i++)
                  Positioned(
                    left: c.dx + math.cos(i * math.pi / 3 - math.pi / 2) * box.maxWidth * 0.62 * t - star / 2,
                    top: c.dy + math.sin(i * math.pi / 3 - math.pi / 2) * box.maxHeight * 0.62 * t - star / 2,
                    child: Opacity(opacity: (1 - t).clamp(0.0, 1.0), child: StarShape(size: star)),
                  ),
              ],
            );
          },
        ),
      );
}
