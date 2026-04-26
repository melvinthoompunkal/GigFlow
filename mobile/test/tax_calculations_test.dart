import 'package:flutter_test/flutter_test.dart';
import 'package:gigflow/utils/tax_calculations.dart';
import 'package:gigflow/models/user_profile.dart';

void main() {
  group('estimateStateTax', () {
    test('Texas returns 0 (no income tax)', () {
      expect(estimateStateTax(50000, 'TX'), 0);
    });

    test('Florida returns 0 (no income tax)', () {
      expect(estimateStateTax(50000, 'FL'), 0);
    });

    test('California uses progressive brackets', () {
      final tax = estimateStateTax(50000, 'CA');
      expect(tax, greaterThan(1500));
      expect(tax, lessThan(4000));
    });

    test('New York uses progressive brackets', () {
      final tax = estimateStateTax(60000, 'NY');
      expect(tax, greaterThan(2000));
      expect(tax, lessThan(5000));
    });

    test('Unknown state uses 5% fallback', () {
      expect(estimateStateTax(40000, 'ZZ'), 2000);
    });
  });

  group('estimateFederalTax', () {
    test('dependentCount=0 has no child tax credit', () {
      final withZero = estimateFederalTax(60000, FilingStatus.single, 0);
      final withOne  = estimateFederalTax(60000, FilingStatus.single, 1);
      expect(withOne, lessThan(withZero));
      expect(withZero - withOne, 2000);
    });

    test('dependentCount=2 reduces tax by up to \$4,000', () {
      final withZero = estimateFederalTax(60000, FilingStatus.single, 0);
      final withTwo  = estimateFederalTax(60000, FilingStatus.single, 2);
      expect(withZero - withTwo, 4000);
    });

    test('credit does not drive tax below zero', () {
      expect(estimateFederalTax(5000, FilingStatus.single, 10), 0);
    });

    test('estimateFederalTax includes 37% bracket for high earner', () {
      final tax = estimateFederalTax(700000, FilingStatus.single, 0);
      expect(tax, greaterThan(180000));
    });
  });

  group('generatePlatformBreakdown', () {
    test('uses platformEarnings directly when provided', () {
      final profile = UserProfile(
        platforms: [Platform.uber, Platform.doordash],
        platformEarnings: {'uber': 2000, 'doordash': 1000},
        monthlyEarnings: 3000,
      );
      final breakdown = generatePlatformBreakdown(profile);
      final uber = breakdown.firstWhere((b) => b.platform == Platform.uber);
      final dd   = breakdown.firstWhere((b) => b.platform == Platform.doordash);
      expect(uber.monthly, 2000);
      expect(dd.monthly, 1000);
    });

    test('falls back to even split when platformEarnings is empty', () {
      final profile = UserProfile(
        platforms: [Platform.uber, Platform.lyft],
        platformEarnings: const {},
        monthlyEarnings: 2000,
      );
      final breakdown = generatePlatformBreakdown(profile);
      expect(breakdown.length, 2);
      for (final b in breakdown) {
        expect(b.monthly, greaterThan(0));
      }
    });
  });
}
