import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/ui/theme/age_band.dart';

void main() {
  test('a game belongs to every band its age range touches', () {
    expect(AgeBand.tiny.overlaps([3, 5]), isTrue);
    expect(AgeBand.explorer.overlaps([3, 5]), isTrue);
    expect(AgeBand.champion.overlaps([3, 5]), isFalse);
    expect(AgeBand.champion.overlaps([4, 6]), isTrue);
    expect(AgeBand.tiny.overlaps([4, 6]), isFalse);
  });

  test('bands cover ages 2 to 8 without gaps', () {
    for (var age = 2; age <= 8; age++) {
      expect(AgeBand.values.where((b) => b.overlaps([age, age])), hasLength(1), reason: 'age $age');
    }
  });

  test('the youngest get the biggest interface', () {
    expect(AgeBand.tiny.uiScale, greaterThan(AgeBand.explorer.uiScale));
    expect(AgeBand.explorer.uiScale, greaterThan(AgeBand.champion.uiScale));
  });
}
