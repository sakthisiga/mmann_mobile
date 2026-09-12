import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmann_mobile/core/localization/app_localizations.dart';
import 'package:mmann_mobile/features/farm/data/farm_model.dart';
import 'package:mmann_mobile/features/farm/state/farm_state.dart';

void main() {
  group('Localization Tests', () {
    test('All 5 regional languages provide valid localized strings', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final loc = AppLocalizations(locale);
        expect(loc.tr('enter_mobile'), isNotEmpty);
        expect(loc.tr('send_otp'), isNotEmpty);
        expect(loc.tr('otp_verification'), isNotEmpty);
        expect(loc.tr('verify_and_continue'), isNotEmpty);
        expect(loc.tr('active_farms'), isNotEmpty);
        expect(loc.tr('phone_already_exists'), isNotEmpty);
        expect(loc.tr('sign_in_instead'), isNotEmpty);
        expect(loc.tr('edit_profile_details'), isNotEmpty);
        expect(loc.tr('save_changes'), isNotEmpty);
        expect(loc.tr('profile_updated_successfully'), isNotEmpty);
        expect(loc.tr('edit_farm'), isNotEmpty);
        expect(loc.tr('farm_updated_successfully'), isNotEmpty);
      }
    });

    test('Tamil localization returns native Tamil text', () {
      final loc = AppLocalizations(const Locale('ta'));
      expect(loc.tr('enter_mobile'), 'கைப்பேசி எண் உள்ளிடவும்');
      expect(loc.tr('send_otp'), 'OTP அனுப்பவும்');
      expect(loc.tr('step_1_indicator'), 'படி 1 / 2 · கைப்பேசி உள்நுழைவு');
      expect(loc.tr('step_2_indicator'), 'படி 2 / 2 · சரிபார்ப்பு');
      expect(loc.translateUnit('acre'), 'ஏக்கர்');
      expect(loc.translateUnit('cent'), 'சென்ட்');
      expect(loc.translateState('TN'), 'தமிழ்நாடு');
    });

    test('Telugu localization returns native Telugu text', () {
      final loc = AppLocalizations(const Locale('te'));
      expect(loc.tr('enter_mobile'), 'మొబైల్ నంబర్ నమోదు చేయండి');
      expect(loc.tr('step_2_indicator'), 'దశ 2 / 2 · ధృవీకరణ');
      expect(loc.translateUnit('guntha'), 'గుంట');
      expect(loc.translateState('AP'), 'ఆంధ్రప్రదేశ్');
    });
  });

  group('Farm Model & Multi-Farm Tests', () {
    test('Farm model converts to/from SQLite map', () {
      final farm = Farm(
        id: 'f1',
        name: 'Thanjavur Delta Farm',
        village: 'Thiruvaiyaru',
        district: 'Thanjavur',
        stateCode: 'TN',
        pincode: '613204',
        totalAreaSqm: 10117.15,
        enteredArea: 2.5,
        enteredUnit: 'acre',
        isPrimary: true,
        rev: 1,
      );

      final sqliteMap = farm.toSqlite();
      expect(sqliteMap['name'], 'Thanjavur Delta Farm');
      expect(sqliteMap['is_primary'], 1);

      final restored = Farm.fromSqlite(sqliteMap);
      expect(restored.name, 'Thanjavur Delta Farm');
      expect(restored.isPrimary, true);
      expect(restored.displayArea, '2.5 acre');
    });

    test('Farm copyWith creates updated instance with modified properties', () {
      final farm = Farm(
        id: 'f1',
        name: 'Old Farm Name',
        village: 'Old Village',
        enteredArea: 2.0,
      );

      final updated = farm.copyWith(
        name: 'New Farm Name',
        village: 'New Village',
        enteredArea: 3.5,
      );

      expect(updated.id, 'f1');
      expect(updated.name, 'New Farm Name');
      expect(updated.village, 'New Village');
      expect(updated.enteredArea, 3.5);
    });

    test('FarmState calculates total cultivable acreage correctly', () {
      final farm1 = Farm(
        id: 'f1',
        name: 'Farm 1',
        enteredArea: 2.5,
        enteredUnit: 'acre',
      );
      final farm2 = Farm(
        id: 'f2',
        name: 'Farm 2',
        enteredArea: 100.0,
        enteredUnit: 'cent', // 100 cents = 1.0 acre
      );

      final state = FarmState(
        farmsList: [farm1, farm2],
        activeFarm: farm1,
      );

      expect(state.totalCultivableAcres, 3.5);
    });
  });
}
