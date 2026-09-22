import 'package:flutter_test/flutter_test.dart';
import 'package:habitguard/core/categorization/app_categorizer.dart';
import 'package:habitguard/models/app_category.dart';

void main() {
  group('AppCategorizer Tests', () {
    test('Correctly categorizes popular social media packages', () {
      expect(AppCategorizer.categorize('com.instagram.android'), equals(AppCategory.socialMedia));
      expect(AppCategorizer.categorize('com.facebook.katana'), equals(AppCategory.socialMedia));
      expect(AppCategorizer.categorize('com.snapchat.android'), equals(AppCategory.socialMedia));
      expect(AppCategorizer.categorize('com.twitter.android'), equals(AppCategory.socialMedia));
      expect(AppCategorizer.categorize('com.reddit.frontpage'), equals(AppCategory.socialMedia));
      expect(AppCategorizer.categorize('com.zhiliaoapp.musically'), equals(AppCategory.socialMedia));
      expect(AppCategorizer.categorize('com.instagram.barcelona'), equals(AppCategory.socialMedia));
    });

    test('Correctly categorizes popular gaming packages', () {
      expect(AppCategorizer.categorize('com.pubg.imobile'), equals(AppCategory.gaming));
      expect(AppCategorizer.categorize('com.dts.freefiremax'), equals(AppCategory.gaming));
      expect(AppCategorizer.categorize('com.activision.callofduty.shooter'), equals(AppCategory.gaming));
      expect(AppCategorizer.categorize('com.supercell.clashofclans'), equals(AppCategory.gaming));
      expect(AppCategorizer.categorize('com.mojang.minecraftpe'), equals(AppCategory.gaming));
      expect(AppCategorizer.categorize('com.chess'), equals(AppCategory.gaming));
    });

    test('Correctly categorizes popular entertainment packages', () {
      expect(AppCategorizer.categorize('com.google.android.youtube'), equals(AppCategory.entertainment));
      expect(AppCategorizer.categorize('com.netflix.mediaclient'), equals(AppCategory.entertainment));
      expect(AppCategorizer.categorize('in.startv.hotstar'), equals(AppCategory.entertainment));
      expect(AppCategorizer.categorize('com.spotify.music'), equals(AppCategory.entertainment));
    });

    test('Correctly categorizes education and productivity packages', () {
      expect(AppCategorizer.categorize('com.duolingo'), equals(AppCategory.education));
      expect(AppCategorizer.categorize('com.coursera.android'), equals(AppCategory.education));
      expect(AppCategorizer.categorize('com.google.android.apps.classroom'), equals(AppCategory.education));
      expect(AppCategorizer.categorize('com.google.android.apps.docs'), equals(AppCategory.productivity));
      expect(AppCategorizer.categorize('com.Slack'), equals(AppCategory.productivity));
      expect(AppCategorizer.categorize('notion.id'), equals(AppCategory.productivity));
    });

    test('Heuristic fallback categorizes unknown package with keywords', () {
      expect(AppCategorizer.categorize('com.sample.racing.games'), equals(AppCategory.gaming));
      expect(AppCategorizer.categorize('com.random.learn.physics'), equals(AppCategory.education));
      expect(AppCategorizer.categorize('org.community.social.feed'), equals(AppCategory.socialMedia));
      expect(AppCategorizer.categorize('com.unknown.store.shop'), equals(AppCategory.shopping));
      expect(AppCategorizer.categorize('com.unknown.generic.app'), equals(AppCategory.other));
    });

    test('Dynamic custom overrides take precedence', () {
      const customPkg = 'com.mycustom.app';
      expect(AppCategorizer.categorize(customPkg), equals(AppCategory.other));

      AppCategorizer.registerOverride(customPkg, AppCategory.productivity);
      expect(AppCategorizer.categorize(customPkg), equals(AppCategory.productivity));

      AppCategorizer.clearOverrides();
      expect(AppCategorizer.categorize(customPkg), equals(AppCategory.other));
    });
  });
}
