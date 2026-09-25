import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nova_app/core/play/lexicon.dart';
import 'package:nova_app/core/play/trials.dart';

import '../art/pic_art.dart';
import '../theme/nova_theme.dart';
import '../theme/prompts.dart';
import '../widgets/jelly_button.dart';
import '../widgets/props.dart';
import 'visual_view.dart';

/// What every round view gets from the level screen.
class TrialContext {
  const TrialContext({
    required this.language,
    required this.onResponse,
    required this.onDone,
    required this.hint,
    required this.speak,
    required this.accent,
    this.voicePick,
  });
  final String language;

  /// Log one response (correct or not). Some rounds log several.
  final void Function(bool correct) onResponse;

  /// The round is over; move to the next.
  final VoidCallback onDone;

  /// Ticks each time the child asks for a hint.
  final ValueNotifier<int> hint;
  final void Function(String text) speak;
  final Color accent;

  /// A spoken answer, already matched: an option index for choice rounds,
  /// the number said for counting rounds.
  final ValueNotifier<int?>? voicePick;

  String p(String key, [Map<String, String> args = const {}]) => prompt(key, language, args);
}

Widget trialView(Trial trial, TrialContext ctx) => switch (trial) {
  ChoiceTrial() => ChoiceTrialView(trial: trial, ctx: ctx),
  DragCountTrial() => DragCountTrialView(trial: trial, ctx: ctx),
  TapCountTrial() => TapCountTrialView(trial: trial, ctx: ctx),
  JoinSeparateTrial() => JoinSeparateTrialView(trial: trial, ctx: ctx),
  NumberLineTrial() => NumberLineTrialView(trial: trial, ctx: ctx),
  SortTrial() => SortTrialView(trial: trial, ctx: ctx),
  PairsTrial() => PairsTrialView(trial: trial, ctx: ctx),
  SequenceTrial() => SequenceTrialView(trial: trial, ctx: ctx),
  StreamItemTrial() => StreamItemTrialView(trial: trial, ctx: ctx),
  ClapTrial() => ClapTrialView(trial: trial, ctx: ctx),
  PrintTrial() => PrintTrialView(trial: trial, ctx: ctx),
  BuildWordTrial() => BuildWordTrialView(trial: trial, ctx: ctx),
};

/// The instruction for a round, before any answer.
String trialPrompt(Trial t, String language, {String hostName = ''}) {
  String p(String key, [Map<String, String> args = const {}]) => prompt(key, language, args);
  return switch (t) {
    ChoiceTrial() => p(t.promptKey, {...t.promptArgs, if (t.promptArgs.containsKey('n')) 'n': numeral(int.parse(t.promptArgs['n']!), language)}),
    DragCountTrial() => p('drag_count', {'name': hostName, 'n': numeral(t.target, language), 'thing': _thing(t.item, t.target, language)}),
    TapCountTrial() => p('tap_count'),
    JoinSeparateTrial() => p('join'),
    NumberLineTrial() => p('number_line', {'n': numeral(t.target, language)}),
    SortTrial() => p(t.bordered ? 'sort_border' : (t.rule == SortRule.colour ? 'sort_colour' : 'sort_shape')),
    PairsTrial() => p('pairs'),
    SequenceTrial() => p('simon_watch'),
    StreamItemTrial() => t.targetLabel == null ? p('feed_fish') : p('catch'),
    ClapTrial() => p('clap'),
    PrintTrial() => p(t.startOnly ? 'print_start' : 'print_follow'),
    BuildWordTrial() => p('build'),
  };
}

/// "apples" / "apple" in English; the singular noun in Arabic, where the
/// numeral is shown beside it.
String _thing(Pic pic, int n, String language) {
  final word = wordFor(language, pic)?.text ?? '';
  if (language == 'ar' || n == 1) return word;
  return '${word}s';
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

/// A tappable card that can glow (right), shake (wrong) or pulse (hint).
class OptionCard extends StatefulWidget {
  const OptionCard({super.key, required this.child, required this.onTap, this.state = OptionState.idle, this.pulse = false, this.size = 120});
  final Widget child;
  final VoidCallback? onTap;
  final OptionState state;
  final bool pulse;
  final double size;

  @override
  State<OptionCard> createState() => _OptionCardState();
}

enum OptionState { idle, right, wrong, reveal, dim }

class _OptionCardState extends State<OptionCard> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(OptionCard old) {
    super.didUpdateWidget(old);
    if (widget.state == OptionState.wrong && old.state != OptionState.wrong) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ring = switch (widget.state) {
      OptionState.right || OptionState.reveal => const Color(0xFF34C77B),
      OptionState.wrong => const Color(0xFFFF7A6B),
      _ => widget.pulse ? const Color(0xFFFFC83D) : Colors.white,
    };
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(offset: Offset(math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value), 0), child: child),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: widget.state == OptionState.right ? 1.08 : (widget.pulse ? 1.06 : 1)),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        builder: (context, s, child) => Transform.scale(scale: s, child: child),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: widget.state == OptionState.dim ? 0.45 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: widget.size,
              height: widget.size,
              padding: EdgeInsets.all(widget.size * 0.08),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(widget.size * 0.22),
                border: Border.all(color: ring, width: widget.state == OptionState.idle && !widget.pulse ? 2 : 5),
                boxShadow: [
                  BoxShadow(
                    color: ring == Colors.white ? const Color(0x332A1640) : ring.withValues(alpha: 0.6),
                    blurRadius: ring == Colors.white ? 14 : 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

mixin _Pacing<T extends StatefulWidget> on State<T> {
  final _timers = <Timer>[];

  void after(Duration d, VoidCallback f) => _timers.add(
    Timer(d, () {
      if (mounted) f();
    }),
  );

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Choice
// ---------------------------------------------------------------------------

class ChoiceTrialView extends StatefulWidget {
  const ChoiceTrialView({super.key, required this.trial, required this.ctx});
  final ChoiceTrial trial;
  final TrialContext ctx;

  @override
  State<ChoiceTrialView> createState() => _ChoiceTrialViewState();
}

class _ChoiceTrialViewState extends State<ChoiceTrialView> with _Pacing {
  int? _chosen;
  bool _pulse = false;

  @override
  void initState() {
    super.initState();
    widget.ctx.hint.addListener(_onHint);
    widget.ctx.voicePick?.addListener(_onVoice);
  }

  @override
  void dispose() {
    widget.ctx.hint.removeListener(_onHint);
    widget.ctx.voicePick?.removeListener(_onVoice);
    super.dispose();
  }

  void _onVoice() {
    final i = widget.ctx.voicePick?.value;
    if (i != null && i >= 0 && i < widget.trial.options.length) _choose(i);
  }

  void _onHint() {
    if (widget.trial.speak != null) widget.ctx.speak(widget.trial.speak!);
    setState(() => _pulse = true);
    after(const Duration(milliseconds: 1400), () => setState(() => _pulse = false));
  }

  void _choose(int i) {
    if (_chosen != null) return;
    final correct = widget.trial.isCorrect(i);
    setState(() => _chosen = i);
    widget.ctx.onResponse(correct);
    after(Duration(milliseconds: correct ? 900 : 1500), widget.ctx.onDone);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trial;
    return LayoutBuilder(
      builder: (context, box) {
        final n = t.options.length;
        final short = math.min(box.maxWidth, box.maxHeight);
        final hasQuestion = t.question != null;
        final optionSize = math
            .min((box.maxWidth - 24) / n - 16, (hasQuestion ? box.maxHeight * 0.44 : box.maxHeight * 0.62))
            .clamp(72.0, t.optionsAreBig ? 280.0 : 210.0);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasQuestion) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(28)),
                child: VisualView(t.question!, size: (short * 0.3).clamp(80.0, 200.0), language: widget.ctx.language),
              ),
              SizedBox(height: short * 0.05),
            ],
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                for (var i = 0; i < n; i++)
                  OptionCard(
                    key: ValueKey(i),
                    size: optionSize,
                    pulse: _pulse && i == t.answer,
                    state: _chosen == null
                        ? OptionState.idle
                        : i == _chosen
                        ? (t.isCorrect(i) ? OptionState.right : OptionState.wrong)
                        : (i == t.answer ? OptionState.reveal : OptionState.dim),
                    onTap: () => _choose(i),
                    child: VisualView(t.options[i], size: optionSize * 0.8, language: widget.ctx.language),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// A row of numeral answers, used after counting or watching.
class NumberChoices extends StatelessWidget {
  const NumberChoices({super.key, required this.choices, required this.onPick, required this.language, this.chosen, this.answer, this.pulse = false});
  final List<int> choices;
  final void Function(int) onPick;
  final String language;
  final int? chosen;
  final int? answer;
  final bool pulse;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 14,
    children: [
      for (final c in choices)
        OptionCard(
          size: 92,
          pulse: pulse && c == answer,
          state: chosen == null
              ? OptionState.idle
              : (c == chosen ? (c == answer ? OptionState.right : OptionState.wrong) : (c == answer ? OptionState.reveal : OptionState.dim)),
          onTap: chosen == null ? () => onPick(c) : null,
          child: NumeralBadge(numeral(c, language), size: 70),
        ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Drag to count
// ---------------------------------------------------------------------------

class DragCountTrialView extends StatefulWidget {
  const DragCountTrialView({super.key, required this.trial, required this.ctx});
  final DragCountTrial trial;
  final TrialContext ctx;

  @override
  State<DragCountTrialView> createState() => _DragCountTrialViewState();
}

class _DragCountTrialViewState extends State<DragCountTrialView> with _Pacing {
  late final List<Pic> _pile = [
    for (var i = 0; i < widget.trial.pile; i++) widget.trial.item,
    for (var i = 0; i < widget.trial.distractorCount; i++) widget.trial.distractor!,
  ]..shuffle(math.Random(widget.trial.target * 31 + widget.trial.pile));
  final _placed = <int>[];
  bool _submitted = false;
  bool _pulse = false;

  @override
  void initState() {
    super.initState();
    widget.ctx.hint.addListener(_onHint);
  }

  @override
  void dispose() {
    widget.ctx.hint.removeListener(_onHint);
    super.dispose();
  }

  void _onHint() {
    setState(() => _pulse = true);
    after(const Duration(milliseconds: 1400), () => setState(() => _pulse = false));
  }

  void _submit() {
    if (_submitted) return;
    _submitted = true;
    final targets = _placed.where((i) => _pile[i] == widget.trial.item).length;
    final distractors = _placed.length - targets;
    widget.ctx.onResponse(widget.trial.isCorrect(targets, distractors));
    after(const Duration(milliseconds: 1100), widget.ctx.onDone);
  }

  @override
  Widget build(BuildContext context) {
    final a = 76.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DragTarget<int>(
          onAcceptWithDetails: (d) => setState(() => _placed.add(d.data)),
          builder: (context, candidate, _) => Transform.scale(
            scale: candidate.isNotEmpty ? 1.06 : 1,
            child: Plate3D(
              width: 300,
              glow: candidate.isNotEmpty ? 1 : (_pulse ? 0.7 : 0),
              child: Center(
                child: Wrap(spacing: -10, children: [for (final i in _placed) PicArt(_pile[i], size: a * 0.7)]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 10,
          children: [
            for (var i = 0; i < _pile.length; i++)
              if (_placed.contains(i))
                SizedBox(width: a, height: a)
              else
                Draggable<int>(
                  data: i,
                  feedback: Transform.rotate(angle: -0.1, child: PicArt(_pile[i], size: a * 1.2)),
                  childWhenDragging: SizedBox(width: a, height: a),
                  child: PicArt(_pile[i], size: a),
                ),
          ],
        ),
        const SizedBox(height: 18),
        JellyButton(onPressed: _submitted ? null : _submit, color: const Color(0xFF34C77B), icon: Icons.check_rounded, label: widget.ctx.p('done'), size: 64),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tap to count
// ---------------------------------------------------------------------------

class TapCountTrialView extends StatefulWidget {
  const TapCountTrialView({super.key, required this.trial, required this.ctx});
  final TapCountTrial trial;
  final TrialContext ctx;

  @override
  State<TapCountTrialView> createState() => _TapCountTrialViewState();
}

class _TapCountTrialViewState extends State<TapCountTrialView> with _Pacing {
  final _tapped = <int>[];
  int? _chosen;
  bool _pulse = false;

  @override
  void initState() {
    super.initState();
    widget.ctx.hint.addListener(_onHint);
    widget.ctx.voicePick?.addListener(_onVoice);
  }

  @override
  void dispose() {
    widget.ctx.hint.removeListener(_onHint);
    widget.ctx.voicePick?.removeListener(_onVoice);
    super.dispose();
  }

  void _onHint() {
    setState(() => _pulse = true);
    after(const Duration(milliseconds: 1400), () => setState(() => _pulse = false));
  }

  void _tap(int i) {
    if (_tapped.contains(i)) return;
    setState(() => _tapped.add(i));
    widget.ctx.speak(numeral(_tapped.length, widget.ctx.language));
  }

  void _onVoice() {
    final n = widget.ctx.voicePick?.value;
    if (n != null && widget.trial.choices.contains(n)) _pick(n);
  }

  void _pick(int n) {
    if (_chosen != null) return;
    setState(() => _chosen = n);
    widget.ctx.onResponse(widget.trial.isCorrect(n));
    after(const Duration(milliseconds: 1200), widget.ctx.onDone);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trial;
    return LayoutBuilder(
      builder: (context, box) {
        final field = Size(math.min(box.maxWidth - 20, 620), math.max(160, box.maxHeight - 150));
        final cols = t.scattered ? 5 : math.min(t.count, 10);
        final rows = (t.count / cols).ceil();
        final cell = math.min(field.width / cols, field.height / math.max(rows, t.scattered ? 4 : 1));
        final rng = math.Random(t.seed);
        final slots = [
          for (var r = 0; r < (t.scattered ? 4 : rows); r++)
            for (var c = 0; c < cols; c++) (r, c),
        ];
        if (t.scattered) slots.shuffle(rng);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: cols * cell,
              height: (t.scattered ? 4 : rows) * cell,
              child: Stack(
                children: [
                  for (var i = 0; i < t.count; i++)
                    Positioned(
                      left: slots[i].$2 * cell + (t.scattered ? rng.nextDouble() * cell * 0.1 : 0),
                      top: slots[i].$1 * cell,
                      child: GestureDetector(
                        onTap: () => _tap(i),
                        child: SizedBox(
                          width: cell,
                          height: cell,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: _tapped.contains(i) ? 1 : 0.55,
                                child: PicArt(t.pic, size: cell * 0.86),
                              ),
                              if (_tapped.contains(i))
                                Text(
                                  numeral(_tapped.indexOf(i) + 1, widget.ctx.language),
                                  style: novaText(
                                    cell * 0.34,
                                    weight: 800,
                                    color: Colors.white,
                                  ).copyWith(shadows: const [Shadow(blurRadius: 4, color: Colors.black54)]),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            NumberChoices(choices: t.choices, onPick: _pick, language: widget.ctx.language, chosen: _chosen, answer: t.count, pulse: _pulse),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Join and separate
// ---------------------------------------------------------------------------

class JoinSeparateTrialView extends StatefulWidget {
  const JoinSeparateTrialView({super.key, required this.trial, required this.ctx});
  final JoinSeparateTrial trial;
  final TrialContext ctx;

  @override
  State<JoinSeparateTrialView> createState() => _JoinSeparateTrialViewState();
}

class _JoinSeparateTrialViewState extends State<JoinSeparateTrialView> with SingleTickerProviderStateMixin, _Pacing {
  late final AnimationController _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  int? _chosen;
  bool _pulse = false;

  @override
  void initState() {
    super.initState();
    widget.ctx.hint.addListener(_onHint);
    widget.ctx.voicePick?.addListener(_onVoice);
    after(const Duration(milliseconds: 700), () => _move.forward());
  }

  @override
  void dispose() {
    widget.ctx.hint.removeListener(_onHint);
    widget.ctx.voicePick?.removeListener(_onVoice);
    _move.dispose();
    super.dispose();
  }

  void _onHint() {
    _move.forward(from: 0);
    setState(() => _pulse = true);
    after(const Duration(milliseconds: 1600), () => setState(() => _pulse = false));
  }

  void _onVoice() {
    final n = widget.ctx.voicePick?.value;
    if (n != null && widget.trial.choices.contains(n)) _pick(n);
  }

  void _pick(int n) {
    if (_chosen != null) return;
    setState(() => _chosen = n);
    widget.ctx.onResponse(widget.trial.isCorrect(n));
    after(const Duration(milliseconds: 1200), widget.ctx.onDone);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trial;
    final lang = widget.ctx.language;
    final joining = t.change > 0;
    final total = joining ? t.result : t.start;
    const item = 46.0;
    final sentence = '${numeral(t.start, lang)} ${joining ? '+' : '−'} ${numeral(t.change.abs(), lang)} = ?';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 380,
          height: 190,
          decoration: BoxDecoration(
            color: const Color(0xFFC98E55),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(90)),
            border: Border.all(color: const Color(0xFF8E5426), width: 6),
            boxShadow: const [BoxShadow(color: Color(0x552A1640), blurRadius: 18, offset: Offset(0, 10))],
          ),
          child: t.hidden
              ? Center(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(sentence, style: novaText(48, weight: 800, color: Colors.white)),
                  ),
                )
              : AnimatedBuilder(
                  animation: _move,
                  builder: (context, _) {
                    final v = Curves.easeInOut.transform(_move.value);
                    return Stack(
                      children: [
                        for (var i = 0; i < total; i++)
                          () {
                            final moving = joining ? i >= t.start : i >= t.result;
                            final home = Offset(18.0 + (i % 6) * 58, 22.0 + (i ~/ 6) * 56);
                            final away = Offset(home.dx + 260, -160);
                            final pos = !moving ? home : (joining ? Offset.lerp(away, home, v)! : Offset.lerp(home, away, v)!);
                            return Positioned(
                              left: pos.dx,
                              top: pos.dy,
                              child: Opacity(
                                opacity: moving ? (joining ? v : 1 - v * 0.6) : 1,
                                child: PicArt(t.pic, size: item),
                              ),
                            );
                          }(),
                      ],
                    );
                  },
                ),
        ),
        const SizedBox(height: 20),
        NumberChoices(choices: t.choices, onPick: _pick, language: lang, chosen: _chosen, answer: t.result, pulse: _pulse),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Number line
// ---------------------------------------------------------------------------

class NumberLineTrialView extends StatefulWidget {
  const NumberLineTrialView({super.key, required this.trial, required this.ctx});
  final NumberLineTrial trial;
  final TrialContext ctx;

  @override
  State<NumberLineTrialView> createState() => _NumberLineTrialViewState();
}

class _NumberLineTrialViewState extends State<NumberLineTrialView> with _Pacing {
  int? _mark;
  bool _pulse = false;

  @override
  void initState() {
    super.initState();
    widget.ctx.hint.addListener(_onHint);
  }

  @override
  void dispose() {
    widget.ctx.hint.removeListener(_onHint);
    super.dispose();
  }

  void _onHint() {
    setState(() => _pulse = true);
    after(const Duration(milliseconds: 1600), () => setState(() => _pulse = false));
  }

  void _tap(int mark) {
    if (_mark != null) return;
    setState(() => _mark = mark);
    widget.ctx.onResponse(widget.trial.isCorrect(mark));
    after(const Duration(milliseconds: 1400), widget.ctx.onDone);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trial;
    final lang = widget.ctx.language;
    // Number lines run left to right in both languages here, as in most
    // Arabic-medium maths textbooks' number lines; revisit with specialists.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, box) {
          final width = math.min(box.maxWidth - 40, 900.0);
          final step = width / t.max;
          bool labelled(int m) => m == 0 || m == t.max || (t.labelEvery > 0 && m % t.labelEvery == 0);
          final frogAt = _mark ?? 0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NumeralBadge(numeral(t.target, lang), size: 96),
              const SizedBox(height: 28),
              SizedBox(
                width: width + 40,
                height: 150,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 20,
                      right: 20,
                      top: 80,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(color: const Color(0xFF5B4A70), borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    for (var m = 0; m <= t.max; m++)
                      Positioned(
                        left: 20 + m * step - 22,
                        top: 56,
                        child: GestureDetector(
                          onTap: () => _tap(m),
                          child: SizedBox(
                            width: 44,
                            height: 90,
                            child: Column(
                              children: [
                                Container(
                                  width: 6,
                                  height: labelled(m) ? 50 : 34,
                                  margin: EdgeInsets.only(top: labelled(m) ? 4 : 12),
                                  decoration: BoxDecoration(
                                    color: _pulse && m == t.target ? const Color(0xFFFFC83D) : const Color(0xFF5B4A70),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                if (labelled(m)) Text(numeral(m, lang), style: novaText(18, weight: 800, color: const Color(0xFF3A2A4A))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutBack,
                      left: 20 + frogAt * step - 30,
                      top: _mark == null ? 0 : -6,
                      child: IgnorePointer(child: _Frog(ok: _mark == null ? null : t.isCorrect(_mark!))),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Frog extends StatelessWidget {
  const _Frog({this.ok});
  final bool? ok;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 60,
    height: 56,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: 56,
          height: 42,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.elliptical(56, 42)),
            gradient: RadialGradient(center: Alignment(-0.3, -0.4), colors: [Color(0xFFB5F28A), Color(0xFF4CC26B), Color(0xFF2E8A45)], stops: [0, 0.5, 1]),
          ),
        ),
        for (final dx in [-14.0, 14.0])
          Positioned(
            top: 0,
            left: 30 + dx - 9,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              alignment: Alignment.center,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1E1426)),
              ),
            ),
          ),
        if (ok != null)
          Positioned(
            bottom: 10,
            child: Text(ok! ? '◡' : '~', style: novaText(20, weight: 800, color: const Color(0xFF1E5A2E))),
          ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Sorting (one rule, or switching rules)
// ---------------------------------------------------------------------------

class SortTrialView extends StatefulWidget {
  const SortTrialView({super.key, required this.trial, required this.ctx});
  final SortTrial trial;
  final TrialContext ctx;

  @override
  State<SortTrialView> createState() => _SortTrialViewState();
}

class _SortTrialViewState extends State<SortTrialView> with _Pacing {
  int? _bin;
  bool _pulse = false;

  @override
  void initState() {
    super.initState();
    widget.ctx.hint.addListener(_onHint);
  }

  @override
  void dispose() {
    widget.ctx.hint.removeListener(_onHint);
    super.dispose();
  }

  void _onHint() {
    setState(() => _pulse = true);
    after(const Duration(milliseconds: 1400), () => setState(() => _pulse = false));
  }

  void _drop(int bin) {
    if (_bin != null) return;
    setState(() => _bin = bin);
    widget.ctx.onResponse(widget.trial.isCorrect(bin));
    after(const Duration(milliseconds: 900), widget.ctx.onDone);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trial;
    final card = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.bordered ? const Color(0xFFFFC83D) : Colors.white, width: t.bordered ? 8 : 2),
        boxShadow: const [BoxShadow(color: Color(0x442A1640), blurRadius: 14, offset: Offset(0, 8))],
      ),
      child: TokenArt(t.card, size: 110),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (t.switched)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFFF6FA5), borderRadius: BorderRadius.circular(30)),
              child: Text(widget.ctx.p('new_rule'), style: novaText(22, weight: 800, color: Colors.white)),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(t.rule == SortRule.colour ? Icons.palette_rounded : Icons.category_rounded, size: 40, color: const Color(0xFF5B4A70)),
            const SizedBox(width: 8),
            Text(widget.ctx.p(t.rule == SortRule.colour ? 'sort_colour' : 'sort_shape'), style: novaText(24, weight: 800, color: const Color(0xFF3A2A4A))),
          ],
        ),
        const SizedBox(height: 16),
        if (_bin == null)
          Draggable<int>(
            data: 0,
            feedback: Material(type: MaterialType.transparency, child: card),
            childWhenDragging: const SizedBox(width: 130, height: 130),
            child: card,
          )
        else
          const SizedBox(width: 130, height: 130),
        const SizedBox(height: 22),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < t.bins.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: DragTarget<int>(
                  onAcceptWithDetails: (_) => _drop(i),
                  builder: (context, candidate, _) => GestureDetector(
                    onTap: () => _drop(i),
                    child: _Bin(
                      label: t.bins[i],
                      highlight: candidate.isNotEmpty || (_pulse && i == t.answer),
                      state: _bin == null ? null : (i == _bin ? t.isCorrect(i) : null),
                      content: _bin == i ? TokenArt(t.card, size: 60) : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Bin extends StatelessWidget {
  const _Bin({required this.label, required this.highlight, this.state, this.content});
  final Token label;
  final bool highlight;
  final bool? state;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    final ring = state == null ? (highlight ? const Color(0xFFFFC83D) : Colors.white) : (state! ? const Color(0xFF34C77B) : const Color(0xFFFF7A6B));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 170,
      height: 150,
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE2A969), Color(0xFF9E6230)]),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(30)),
        border: Border.all(color: ring, width: highlight || state != null ? 6 : 3),
        boxShadow: const [BoxShadow(color: Color(0x552A1640), blurRadius: 16, offset: Offset(0, 10))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
              child: TokenArt(label, size: 64),
            ),
          ),
          if (content != null) Positioned(bottom: 6, child: content!),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pairs
// ---------------------------------------------------------------------------

class PairsTrialView extends StatefulWidget {
  const PairsTrialView({super.key, required this.trial, required this.ctx});
  final PairsTrial trial;
  final TrialContext ctx;

  @override
  State<PairsTrialView> createState() => _PairsTrialViewState();
}

class _PairsTrialViewState extends State<PairsTrialView> with _Pacing {
  final _found = <int>{};
  final _open = <int>[];
  int _wrong = 0;
  bool _peek = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.ctx.hint.addListener(_onHint);
    // All cards shown for a moment at the start (the game's first hint).
    after(Duration(milliseconds: 900 + widget.trial.pairs * 300), () => setState(() => _peek = false));
  }

  @override
  void dispose() {
    widget.ctx.hint.removeListener(_onHint);
    super.dispose();
  }

  void _onHint() {
    setState(() => _peek = true);
    after(const Duration(milliseconds: 900), () => setState(() => _peek = false));
  }

  void _flip(int i) {
    if (_busy || _peek || _found.contains(i) || _open.contains(i)) return;
    setState(() => _open.add(i));
    if (_open.length < 2) return;
    final cards = widget.trial.cards;
    final match = cards[_open[0]] == cards[_open[1]];
    _busy = true;
    after(Duration(milliseconds: match ? 450 : 900), () {
      setState(() {
        if (match) {
          _found.addAll(_open);
        } else {
          _wrong++;
        }
        _open.clear();
        _busy = false;
      });
      if (_found.length == cards.length) {
        widget.ctx.onResponse(widget.trial.isCorrect(_wrong));
        after(const Duration(milliseconds: 900), widget.ctx.onDone);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.trial.cards;
    final cols = cards.length <= 4 ? cards.length : (cards.length <= 6 ? 3 : 4);
    return LayoutBuilder(
      builder: (context, box) {
        final rows = (cards.length / cols).ceil();
        final size = math.min((box.maxWidth - 40) / cols - 14, (box.maxHeight - 20) / rows - 14).clamp(64.0, 170.0);
        return Center(
          child: SizedBox(
            width: cols * (size + 14),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (var i = 0; i < cards.length; i++)
                  GestureDetector(
                    onTap: () => _flip(i),
                    child: _FlipCard(
                      size: size,
                      faceUp: _peek || _found.contains(i) || _open.contains(i),
                      found: _found.contains(i),
                      child: PicArt(cards[i], size: size * 0.72),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FlipCard extends StatelessWidget {
  const _FlipCard({required this.size, required this.faceUp, required this.found, required this.child});
  final double size;
  final bool faceUp;
  final bool found;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: faceUp ? 1 : 0),
    duration: const Duration(milliseconds: 320),
    builder: (context, v, _) {
      final showFace = v > 0.5;
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateY(math.pi * (showFace ? 1 - v : v)),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.18),
            color: showFace ? Colors.white : null,
            gradient: showFace
                ? null
                : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF9B6BFF), Color(0xFF5B4AE0)]),
            border: Border.all(color: found ? const Color(0xFF34C77B) : Colors.white, width: found ? 5 : 3),
            boxShadow: const [BoxShadow(color: Color(0x442A1640), blurRadius: 12, offset: Offset(0, 6))],
          ),
          alignment: Alignment.center,
          child: showFace ? child : Icon(Icons.star_rounded, size: size * 0.4, color: Colors.white.withValues(alpha: 0.6)),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Sequence recall
// ---------------------------------------------------------------------------

class SequenceTrialView extends StatefulWidget {
  const SequenceTrialView({super.key, required this.trial, required this.ctx});
  final SequenceTrial trial;
  final TrialContext ctx;

  @override
  State<SequenceTrialView> createState() => _SequenceTrialViewState();
}

class _SequenceTrialViewState extends State<SequenceTrialView> with _Pacing {
  static const _colors = [Color(0xFFF0413B), Color(0xFF3C8DF2), Color(0xFFFFC83D), Color(0xFF34C77B)];
  int? _lit;
  bool _playing = true;
  final _response = <int>[];
  bool? _result;

  @override
  void initState() {
    super.initState();
    widget.ctx.hint.addListener(_play);
    after(const Duration(milliseconds: 700), _play);
  }

  @override
  void dispose() {
    widget.ctx.hint.removeListener(_play);
    super.dispose();
  }

  void _play() {
    if (_result != null) return;
    final slow = _response.isNotEmpty || widget.ctx.hint.value > 0;
    final step = slow ? 850 : 650;
    setState(() {
      _playing = true;
      _response.clear();
    });
    final seq = widget.trial.sequence;
    for (var i = 0; i < seq.length; i++) {
      after(Duration(milliseconds: i * step), () => setState(() => _lit = seq[i]));
      after(Duration(milliseconds: i * step + step * 2 ~/ 3), () => setState(() => _lit = null));
    }
    after(Duration(milliseconds: seq.length * step), () {
      setState(() => _playing = false);
      widget.ctx.speak(widget.ctx.p('simon_go'));
    });
  }

  void _tap(int pad) {
    if (_playing || _result != null) return;
    setState(() {
      _response.add(pad);
      _lit = pad;
    });
    after(const Duration(milliseconds: 220), () => setState(() => _lit = null));
    final seq = widget.trial.sequence;
    final i = _response.length - 1;
    if (_response[i] != seq[i] || _response.length == seq.length) {
      final ok = widget.trial.isCorrect(_response);
      setState(() => _result = ok);
      widget.ctx.onResponse(ok);
      after(const Duration(milliseconds: 1100), widget.ctx.onDone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.trial.sequence.length; i++)
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, color: i < _response.length ? const Color(0xFF7C6CF2) : Colors.white.withValues(alpha: 0.7)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            for (var p = 0; p < widget.trial.pads; p++)
              GestureDetector(
                onTap: () => _tap(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.4),
                      colors: _lit == p ? [Colors.white, _colors[p]] : [shade(_colors[p], 0.1), shade(_colors[p], -0.35)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _colors[p].withValues(alpha: _lit == p ? 0.9 : 0.25),
                        blurRadius: _lit == p ? 40 : 10,
                        spreadRadius: _lit == p ? 6 : 0,
                      ),
                    ],
                    border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 4),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stream (go/no-go, catch the target)
// ---------------------------------------------------------------------------

class StreamItemTrialView extends StatefulWidget {
  const StreamItemTrialView({super.key, required this.trial, required this.ctx});
  final StreamItemTrial trial;
  final TrialContext ctx;

  @override
  State<StreamItemTrialView> createState() => _StreamItemTrialViewState();
}

class _StreamItemTrialViewState extends State<StreamItemTrialView> with SingleTickerProviderStateMixin, _Pacing {
  late final AnimationController _travel = AnimationController(vsync: this, duration: widget.trial.showFor);
  bool _tapped = false;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _travel.addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    });
    after(const Duration(milliseconds: 250), () => _travel.forward());
  }

  @override
  void dispose() {
    _travel.dispose();
    super.dispose();
  }

  void _tap() {
    if (_tapped || _ended) return;
    setState(() => _tapped = true);
    after(const Duration(milliseconds: 380), _finish);
  }

  void _finish() {
    if (_ended) return;
    _ended = true;
    widget.ctx.onResponse(widget.trial.isCorrect(tapped: _tapped));
    after(const Duration(milliseconds: 250), widget.ctx.onDone);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trial;
    return LayoutBuilder(
      builder: (context, box) {
        final size = math.min(box.maxHeight * 0.4, 170.0);
        return Stack(
          children: [
            if (t.targetLabel != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFFC83D), width: 4),
                    ),
                    child: VisualView(t.targetLabel!, size: 76, language: widget.ctx.language),
                  ),
                ),
              ),
            AnimatedBuilder(
              animation: _travel,
              builder: (context, child) {
                final v = _travel.value;
                final pos = switch (t.theme) {
                  StreamTheme.sea => Offset(box.maxWidth + size - v * (box.maxWidth + size * 2), box.maxHeight * 0.45 + math.sin(v * math.pi * 3) * 16),
                  _ => Offset(box.maxWidth / 2 - size / 2 + math.sin(v * math.pi * 2) * box.maxWidth * 0.2, box.maxHeight - v * (box.maxHeight + size)),
                };
                return Positioned(left: pos.dx - (t.theme == StreamTheme.sea ? size : 0), top: pos.dy, child: child!);
              },
              child: GestureDetector(
                onTap: _tap,
                child: AnimatedScale(
                  scale: _tapped ? (t.isTarget ? 1.25 : 0.85) : 1,
                  duration: const Duration(milliseconds: 200),
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (t.theme == StreamTheme.balloons) PicArt(Pic.balloon, size: size),
                        if (t.theme == StreamTheme.bubbles)
                          Container(
                            width: size * 0.9,
                            height: size * 0.9,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.2),
                                  const Color(0xFFB9E4FF).withValues(alpha: 0.5),
                                  const Color(0xFF9B6BFF).withValues(alpha: 0.7),
                                ],
                                stops: const [0, 0.8, 1],
                              ),
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.only(bottom: t.theme == StreamTheme.balloons ? size * 0.3 : 0),
                          child: t.visual is PicVisual
                              ? Transform.flip(
                                  flipX: true,
                                  child: VisualView(t.visual, size: size, language: widget.ctx.language),
                                )
                              : _StreamLabel(t.visual, size * 0.5, widget.ctx.language),
                        ),
                        if (_tapped && t.isTarget) Icon(Icons.auto_awesome, size: size * 0.5, color: const Color(0xFFFFE27A)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StreamLabel extends StatelessWidget {
  const _StreamLabel(this.visual, this.size, this.language);
  final Visual visual;
  final double size;
  final String language;

  @override
  Widget build(BuildContext context) {
    final text = switch (visual) {
      NumeralVisual(:final value) => numeral(value, language),
      TextVisual(:final text) => text,
      _ => '',
    };
    return Text(
      text,
      style: novaText(size, weight: 800, color: Colors.white).copyWith(shadows: const [Shadow(blurRadius: 6, color: Color(0x88000000))]),
    );
  }
}

// ---------------------------------------------------------------------------
// Clap the syllables
// ---------------------------------------------------------------------------

class ClapTrialView extends StatefulWidget {
  const ClapTrialView({super.key, required this.trial, required this.ctx});
  final ClapTrial trial;
  final TrialContext ctx;

  @override
  State<ClapTrialView> createState() => _ClapTrialViewState();
}

class _ClapTrialViewState extends State<ClapTrialView> with _Pacing {
  int _taps = 0;
  bool _done = false;
  bool _showParts = false;

  @override
  void initState() {
    super.initState();
    widget.ctx.hint.addListener(_onHint);
    after(const Duration(milliseconds: 600), () => widget.ctx.speak(widget.trial.word.text));
  }

  @override
  void dispose() {
    widget.ctx.hint.removeListener(_onHint);
    super.dispose();
  }

  void _onHint() {
    setState(() => _showParts = true);
    widget.ctx.speak(widget.trial.word.parts.join('... '));
  }

  void _submit() {
    if (_done || _taps == 0) return;
    setState(() => _done = true);
    widget.ctx.onResponse(widget.trial.isCorrect(_taps));
    after(const Duration(milliseconds: 1100), widget.ctx.onDone);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.trial.word;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(onTap: () => widget.ctx.speak(w.text), child: PicArt(w.pic, size: 140)),
        const SizedBox(height: 6),
        Text(_showParts || _done ? w.parts.join(' · ') : w.text, style: novaText(30, weight: 800, color: const Color(0xFF3A2A4A))),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [for (var i = 0; i < _taps; i++) const Padding(padding: EdgeInsets.all(4), child: StarShape(size: 30))],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _done ? null : () => setState(() => _taps = math.min(_taps + 1, 6)),
              child: TweenAnimationBuilder<double>(
                key: ValueKey(_taps),
                tween: Tween(begin: 0.85, end: 1),
                duration: const Duration(milliseconds: 250),
                curve: Curves.elasticOut,
                builder: (context, v, child) => Transform.scale(scale: v, child: child),
                child: const PicArt(Pic.drum, size: 150),
              ),
            ),
            const SizedBox(width: 24),
            Column(
              children: [
                JellyButton(
                  onPressed: _done || _taps == 0 ? null : () => setState(() => _taps--),
                  color: const Color(0xFF9B8AA6),
                  icon: Icons.undo_rounded,
                  size: 52,
                ),
                const SizedBox(height: 12),
                JellyButton(
                  onPressed: _done || _taps == 0 ? null : _submit,
                  color: const Color(0xFF34C77B),
                  icon: Icons.check_rounded,
                  label: widget.ctx.p('done'),
                  size: 60,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Print concepts
// ---------------------------------------------------------------------------

class PrintTrialView extends StatefulWidget {
  const PrintTrialView({super.key, required this.trial, required this.ctx});
  final PrintTrial trial;
  final TrialContext ctx;

  @override
  State<PrintTrialView> createState() => _PrintTrialViewState();
}

class _PrintTrialViewState extends State<PrintTrialView> with _Pacing {
  final _taps = <(int, int)>[];
  bool? _result;
  bool _hinted = false;

  @override
  void initState() {
    super.initState();
    widget.ctx.hint.addListener(_onHint);
  }

  @override
  void dispose() {
    widget.ctx.hint.removeListener(_onHint);
    super.dispose();
  }

  void _onHint() => setState(() => _hinted = true);

  void _tap(int line, int index) {
    if (_result != null || _taps.contains((line, index))) return;
    setState(() => _taps.add((line, index)));
    final want = widget.trial.startOnly ? widget.trial.order.take(1).toList() : widget.trial.order;
    final i = _taps.length - 1;
    if (_taps[i] != want[i] || _taps.length == want.length) {
      final ok = widget.trial.isCorrect(_taps);
      setState(() => _result = ok);
      widget.ctx.onResponse(ok);
      after(const Duration(milliseconds: 1200), widget.ctx.onDone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trial;
    final next = _taps.length < t.order.length ? t.order[_taps.length] : null;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 28),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF0),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x442A1640), blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: Directionality(
          textDirection: t.rtl ? TextDirection.rtl : TextDirection.ltr,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_hinted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Icon(t.rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, size: 40, color: const Color(0xFFFF6FA5)),
                ),
              for (var l = 0; l < t.lines.length; l++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Wrap(
                    spacing: 14,
                    children: [
                      for (var i = 0; i < t.lines[l].length; i++)
                        GestureDetector(
                          onTap: () => _tap(l, i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _taps.contains((l, i))
                                  ? ((_result == false && _taps.last == (l, i)) ? const Color(0xFFFFD6D0) : const Color(0xFFC9F2D8))
                                  : (_hinted && next == (l, i) ? const Color(0xFFFFF0B3) : Colors.transparent),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(t.lines[l][i], style: novaText(40, weight: 700, color: const Color(0xFF2E2440))),
                          ),
                        ),
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

// ---------------------------------------------------------------------------
// Build a word
// ---------------------------------------------------------------------------

class BuildWordTrialView extends StatefulWidget {
  const BuildWordTrialView({super.key, required this.trial, required this.ctx});
  final BuildWordTrial trial;
  final TrialContext ctx;

  @override
  State<BuildWordTrialView> createState() => _BuildWordTrialViewState();
}

class _BuildWordTrialViewState extends State<BuildWordTrialView> with _Pacing {
  final _placed = <int>[]; // tile indices, in slot order
  int _wrong = 0;
  bool _done = false;
  int? _bounced;

  List<String> get _letters => widget.trial.word.letters;

  @override
  void initState() {
    super.initState();
    widget.ctx.hint.addListener(_onHint);
    after(const Duration(milliseconds: 500), () => widget.ctx.speak(widget.trial.word.text));
  }

  @override
  void dispose() {
    widget.ctx.hint.removeListener(_onHint);
    super.dispose();
  }

  void _onHint() {
    if (_placed.length < _letters.length) widget.ctx.speak(_letters[_placed.length]);
  }

  void _offer(int tile) {
    if (_done || _placed.contains(tile)) return;
    final want = _letters[_placed.length];
    if (widget.trial.tiles[tile] == want) {
      setState(() => _placed.add(tile));
      if (_placed.length == _letters.length) {
        _done = true;
        widget.ctx.speak(widget.trial.word.text);
        widget.ctx.onResponse(widget.trial.isCorrect(_wrong));
        after(const Duration(milliseconds: 1300), widget.ctx.onDone);
      }
    } else {
      setState(() {
        _wrong++;
        _bounced = tile;
      });
      after(const Duration(milliseconds: 450), () => setState(() => _bounced = null));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trial;
    Widget tile(String letter, {Color color = const Color(0xFF7C6CF2)}) => Container(
      width: 72,
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [shade(color, 0.3), color]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: shade(color, -0.5), offset: const Offset(0, 5))],
      ),
      child: Text(letter, style: novaText(44, weight: 800, color: Colors.white)),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(onTap: () => widget.ctx.speak(t.word.text), child: PicArt(t.word.pic, size: 130)),
        const SizedBox(height: 16),
        Directionality(
          textDirection: t.rtl ? TextDirection.rtl : TextDirection.ltr,
          child: _done
              ? Text(t.word.text, style: novaText(64, weight: 800, color: const Color(0xFF2E2440)))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var s = 0; s < _letters.length; s++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: s < _placed.length
                            ? tile(t.tiles[_placed[s]], color: const Color(0xFF34C77B))
                            : DragTarget<int>(
                                onAcceptWithDetails: (d) => _offer(d.data),
                                builder: (context, cand, _) => Container(
                                  width: 72,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: cand.isNotEmpty ? 0.95 : 0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: s == _placed.length ? const Color(0xFFFFC83D) : Colors.white, width: 3),
                                  ),
                                ),
                              ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < t.tiles.length; i++)
              if (_placed.contains(i))
                const SizedBox(width: 72, height: 80)
              else
                AnimatedSlide(
                  offset: _bounced == i ? const Offset(0, -0.25) : Offset.zero,
                  duration: const Duration(milliseconds: 180),
                  child: Draggable<int>(
                    data: i,
                    feedback: Material(type: MaterialType.transparency, child: tile(t.tiles[i])),
                    childWhenDragging: const SizedBox(width: 72, height: 80),
                    child: GestureDetector(
                      onTap: () => _offer(i),
                      child: tile(t.tiles[i], color: _bounced == i ? const Color(0xFFFF7A6B) : const Color(0xFF7C6CF2)),
                    ),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}
