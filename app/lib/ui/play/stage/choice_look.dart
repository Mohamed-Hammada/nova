import 'package:flutter/material.dart';

import '../../world/activity_world.dart';

/// The object that carries one answer in a choice round. Each belongs to a
/// place, so answers are things in the world (a basket in the orchard, a
/// balloon over the hills, a bubble by the cove) rather than cards on a form.
enum Holder {
  card(aspect: 1, face: Rect.fromLTRB(0.1, 0.1, 0.9, 0.9), arrival: Arrival.pop, lifts: false),
  basket(aspect: 1.08, face: Rect.fromLTRB(0.14, 0.14, 0.86, 0.6), arrival: Arrival.drop, lifts: false),
  balloon(aspect: 1.3, face: Rect.fromLTRB(0.15, 0.08, 0.85, 0.66), arrival: Arrival.rise, lifts: true),
  bubble(aspect: 1, face: Rect.fromLTRB(0.17, 0.17, 0.83, 0.83), arrival: Arrival.rise, lifts: true),
  lilyPad(aspect: 1.08, face: Rect.fromLTRB(0.16, 0.06, 0.84, 0.68), arrival: Arrival.pop, lifts: false),
  signpost(aspect: 1.22, face: Rect.fromLTRB(0.1, 0.08, 0.9, 0.68), arrival: Arrival.drop, lifts: false),
  cloud(aspect: 0.9, face: Rect.fromLTRB(0.17, 0.18, 0.83, 0.8), arrival: Arrival.slide, lifts: true),
  carriage(aspect: 0.98, face: Rect.fromLTRB(0.12, 0.12, 0.88, 0.7), arrival: Arrival.slide, lifts: false),
  crystal(aspect: 1.1, face: Rect.fromLTRB(0.18, 0.16, 0.82, 0.8), arrival: Arrival.pop, lifts: false);

  const Holder({required this.aspect, required this.face, required this.arrival, required this.lifts});

  /// Height over width.
  final double aspect;

  /// Where the answer's picture sits, in unit coordinates of the holder.
  final Rect face;

  /// How it comes into the scene at the start of a round.
  final Arrival arrival;

  /// On success it floats up (balloons, bubbles, clouds) instead of hopping.
  final bool lifts;
}

/// How holders enter a round.
enum Arrival { pop, drop, rise, slide }

/// How one choice game looks in one place: the holders, their colours and
/// the frame around the question. Pure presentation data -- the round's
/// content and mechanic are unchanged.
@immutable
class ChoiceLook {
  const ChoiceLook({required this.holder, required this.tint, required this.deep, this.ground = const Color(0xFFB8E27A)});

  final Holder holder;

  /// The place's colour, for holders that take it (balloons, carriages).
  final Color tint;

  /// A deep version for rims and the question frame (contrast on cream).
  final Color deep;

  /// The place's light ground, for the patch the answers stand on.
  final Color ground;

  static const plain = ChoiceLook(holder: Holder.card, tint: Color(0xFFFF9A2E), deep: Color(0xFFD9670B));

  /// Each place's own answer holders.
  static const byPlace = <ActivityCategory, Holder>{
    ActivityCategory.numbers: Holder.basket,
    ActivityCategory.language: Holder.signpost,
    ActivityCategory.sounds: Holder.cloud,
    ActivityCategory.feelings: Holder.balloon,
    ActivityCategory.memory: Holder.bubble,
    ActivityCategory.discovery: Holder.crystal,
    ActivityCategory.movement: Holder.lilyPad,
  };

  /// Games whose story fixes the holder wherever they are played (the
  /// pattern train is always a train); colours still follow the place.
  static const byGame = <String, Holder>{
    'game.math.pattern-train': Holder.carriage,
  };

  /// The look for [gameId] played in [place]. The same game played in a
  /// different stage looks different.
  static ChoiceLook of(String gameId, ActivityCategory place) =>
      ChoiceLook(holder: byGame[gameId] ?? byPlace[place] ?? Holder.card, tint: place.color, deep: place.deep, ground: place.scene.groundLight);

  @override
  bool operator ==(Object other) => other is ChoiceLook && other.holder == holder && other.tint == tint && other.deep == deep && other.ground == ground;

  @override
  int get hashCode => Object.hash(holder, tint, deep, ground);
}
