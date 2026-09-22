import '../../models/app_category.dart';

/// Centralized application categorization engine mapping Android package names to categories.
class AppCategorizer {
  // Built-in package mapping database covering popular Android apps
  static final Map<String, AppCategory> _packageDatabase = {
    // ----------------------------------------------------
    // SOCIAL MEDIA
    // ----------------------------------------------------
    'com.instagram.android': AppCategory.socialMedia,
    'com.facebook.katana': AppCategory.socialMedia,
    'com.facebook.lite': AppCategory.socialMedia,
    'com.snapchat.android': AppCategory.socialMedia,
    'com.twitter.android': AppCategory.socialMedia,
    'com.twitter.android.lite': AppCategory.socialMedia,
    'com.reddit.frontpage': AppCategory.socialMedia,
    'com.zhiliaoapp.musically': AppCategory.socialMedia, // TikTok
    'com.zhiliaoapp.musically.go': AppCategory.socialMedia,
    'com.instagram.barcelona': AppCategory.socialMedia, // Threads
    'com.pinterest': AppCategory.socialMedia,
    'com.linkedin.android': AppCategory.socialMedia,
    'com.tumblr': AppCategory.socialMedia,
    'com.quora.android': AppCategory.socialMedia,
    'com.discord': AppCategory.socialMedia,
    'tv.twitch.android.app': AppCategory.socialMedia,
    'com.bereal.ft': AppCategory.socialMedia,

    // ----------------------------------------------------
    // GAMING
    // ----------------------------------------------------
    'com.pubg.imobile': AppCategory.gaming, // BGMI
    'com.tencent.ig': AppCategory.gaming, // PUBG Mobile
    'com.dts.freefireth': AppCategory.gaming, // Free Fire
    'com.dts.freefiremax': AppCategory.gaming, // Free Fire Max
    'com.activision.callofduty.shooter': AppCategory.gaming, // COD Mobile
    'com.supercell.clashofclans': AppCategory.gaming,
    'com.supercell.clashroyale': AppCategory.gaming,
    'com.supercell.brawlstars': AppCategory.gaming,
    'com.mojang.minecraftpe': AppCategory.gaming,
    'com.roblox.client': AppCategory.gaming,
    'com.mihoyo.genshinimpact': AppCategory.gaming,
    'com.king.candycrushsaga': AppCategory.gaming,
    'com.kiloo.subwaysurf': AppCategory.gaming,
    'com.imangi.templerun2': AppCategory.gaming,
    'com.ea.gp.fifamobile': AppCategory.gaming,
    'com.miniclip.eightballpool': AppCategory.gaming,
    'com.riotgames.league.wildrift': AppCategory.gaming,
    'com.innersloth.spacemafia': AppCategory.gaming, // Among Us
    'com.gameloft.android.anmp.glofta9hm': AppCategory.gaming, // Asphalt 9
    'com.chess': AppCategory.gaming,

    // ----------------------------------------------------
    // ENTERTAINMENT
    // ----------------------------------------------------
    'com.google.android.youtube': AppCategory.entertainment,
    'com.google.android.apps.youtube.music': AppCategory.entertainment,
    'com.netflix.mediaclient': AppCategory.entertainment,
    'com.amazon.avod.thirdpartyclient': AppCategory.entertainment, // Prime Video
    'com.disney.disneyplus': AppCategory.entertainment,
    'in.startv.hotstar': AppCategory.entertainment, // JioHotstar
    'com.spotify.music': AppCategory.entertainment,
    'com.spotify.lite': AppCategory.entertainment,
    'com.apple.android.music': AppCategory.entertainment,
    'com.soundcloud.android': AppCategory.entertainment,
    'com.mxtech.videoplayer.ad': AppCategory.entertainment, // MX Player
    'com.jio.media.ondemand': AppCategory.entertainment, // JioCinema
    'com.crunchyroll.crunchyroid': AppCategory.entertainment,
    'com.hulu.plus': AppCategory.entertainment,
    'com.gaana': AppCategory.entertainment,
    'com.jio.media.jiobeats': AppCategory.entertainment, // JioSaavn
    'com.audible.application': AppCategory.entertainment,

    // ----------------------------------------------------
    // EDUCATION
    // ----------------------------------------------------
    'com.google.android.apps.classroom': AppCategory.education,
    'com.coursera.android': AppCategory.education,
    'com.udemy.android': AppCategory.education,
    'com.duolingo': AppCategory.education,
    'org.khanacademy.android': AppCategory.education,
    'com.quizlet.quizletandroid': AppCategory.education,
    'com.instructure.candroid': AppCategory.education, // Canvas
    'org.edx.mobile': AppCategory.education,
    'com.sololearn': AppCategory.education,
    'co.brainly': AppCategory.education,
    'com.byjus.thelearningapp': AppCategory.education,
    'com.unacademyapp': AppCategory.education,
    'com.physicswallah.live': AppCategory.education,

    // ----------------------------------------------------
    // PRODUCTIVITY
    // ----------------------------------------------------
    'com.google.android.apps.docs': AppCategory.productivity,
    'com.google.android.apps.docs.editors.docs': AppCategory.productivity,
    'com.google.android.apps.docs.editors.sheets': AppCategory.productivity,
    'com.google.android.apps.docs.editors.slides': AppCategory.productivity,
    'com.google.android.keep': AppCategory.productivity,
    'com.google.android.gm': AppCategory.productivity, // Gmail
    'com.microsoft.teams': AppCategory.productivity,
    'com.microsoft.office.outlook': AppCategory.productivity,
    'com.microsoft.office.word': AppCategory.productivity,
    'com.microsoft.office.excel': AppCategory.productivity,
    'com.microsoft.office.onenote': AppCategory.productivity,
    'com.slack': AppCategory.productivity,
    'notion.id': AppCategory.productivity,
    'com.trello': AppCategory.productivity,
    'com.todoist': AppCategory.productivity,
    'com.evernote': AppCategory.productivity,
    'com.adobe.reader': AppCategory.productivity,
    'com.google.android.calendar': AppCategory.productivity,
    'com.anydo': AppCategory.productivity,
    'com.github.android': AppCategory.productivity,

    // ----------------------------------------------------
    // COMMUNICATION
    // ----------------------------------------------------
    'com.whatsapp': AppCategory.communication,
    'com.whatsapp.w4b': AppCategory.communication,
    'org.telegram.messenger': AppCategory.communication,
    'org.thunderdog.challegram': AppCategory.communication, // Telegram X
    'org.thoughtcrime.securesms': AppCategory.communication, // Signal
    'com.facebook.orca': AppCategory.communication, // Messenger
    'com.google.android.apps.messaging': AppCategory.communication,
    'com.google.android.dialer': AppCategory.communication,
    'com.google.android.contacts': AppCategory.communication,
    'com.google.android.apps.tachyon': AppCategory.communication, // Google Meet
    'us.zoom.videomeetings': AppCategory.communication,
    'com.viber.voip': AppCategory.communication,
    'com.skype.raider': AppCategory.communication,

    // ----------------------------------------------------
    // SHOPPING
    // ----------------------------------------------------
    'com.amazon.mshop.android.shopping': AppCategory.shopping,
    'com.flipkart.android': AppCategory.shopping,
    'com.myntra.android': AppCategory.shopping,
    'com.meesho.supply': AppCategory.shopping,
    'com.ebay.mobile': AppCategory.shopping,
    'com.alibaba.aliexpresshd': AppCategory.shopping,
    'com.shein.fashion': AppCategory.shopping,
    'com.contextlogic.wish': AppCategory.shopping,
    'in.swiggy.android': AppCategory.shopping,
    'com.application.zomato': AppCategory.shopping,
    'com.grofers.customerapp': AppCategory.shopping, // Blinkit
    'com.zepto.consumer': AppCategory.shopping,
  };

  // Custom user or dynamic category overrides
  static final Map<String, AppCategory> _customOverrides = {};

  /// Categorizes an application based on its Android package name and application name.
  static AppCategory categorize(String packageName, [String? appName]) {
    final cleanPkg = packageName.trim().toLowerCase();

    // 1. Check user/dynamic overrides
    if (_customOverrides.containsKey(cleanPkg)) {
      return _customOverrides[cleanPkg]!;
    }

    // 2. Check exact package database match
    if (_packageDatabase.containsKey(cleanPkg)) {
      return _packageDatabase[cleanPkg]!;
    }

    // 3. Heuristic Substring & Name Matching
    final nameLower = (appName ?? '').toLowerCase();

    // Gaming heuristics
    if (cleanPkg.contains('.game') ||
        cleanPkg.contains('.games') ||
        cleanPkg.contains('supercell') ||
        cleanPkg.contains('gameloft') ||
        cleanPkg.contains('ea.gp') ||
        nameLower.contains('game') ||
        nameLower.contains('clash') ||
        nameLower.contains('racer') ||
        nameLower.contains('pubg') ||
        nameLower.contains('craft') ||
        nameLower.contains('puzzle')) {
      return AppCategory.gaming;
    }

    // Social heuristics
    if (cleanPkg.contains('.social') ||
        cleanPkg.contains('instagram') ||
        cleanPkg.contains('facebook') ||
        cleanPkg.contains('twitter') ||
        cleanPkg.contains('snapchat') ||
        cleanPkg.contains('tiktok') ||
        nameLower.contains('social') ||
        nameLower.contains('community')) {
      return AppCategory.socialMedia;
    }

    // Entertainment / Video / Audio heuristics
    if (cleanPkg.contains('.music') ||
        cleanPkg.contains('.video') ||
        cleanPkg.contains('.player') ||
        cleanPkg.contains('.media') ||
        cleanPkg.contains('spotify') ||
        cleanPkg.contains('netflix') ||
        nameLower.contains('player') ||
        nameLower.contains('stream') ||
        nameLower.contains('tv') ||
        nameLower.contains('cinema') ||
        nameLower.contains('movie')) {
      return AppCategory.entertainment;
    }

    // Education heuristics
    if (cleanPkg.contains('.edu') ||
        cleanPkg.contains('.learn') ||
        cleanPkg.contains('academy') ||
        cleanPkg.contains('course') ||
        cleanPkg.contains('tutor') ||
        nameLower.contains('learn') ||
        nameLower.contains('study') ||
        nameLower.contains('course') ||
        nameLower.contains('dictionary')) {
      return AppCategory.education;
    }

    // Productivity heuristics
    if (cleanPkg.contains('.office') ||
        cleanPkg.contains('.docs') ||
        cleanPkg.contains('.notes') ||
        cleanPkg.contains('task') ||
        cleanPkg.contains('scanner') ||
        nameLower.contains('note') ||
        nameLower.contains('office') ||
        nameLower.contains('pdf') ||
        nameLower.contains('calendar') ||
        nameLower.contains('sheet')) {
      return AppCategory.productivity;
    }

    // Communication heuristics
    if (cleanPkg.contains('.chat') ||
        cleanPkg.contains('.messenger') ||
        cleanPkg.contains('.dialer') ||
        cleanPkg.contains('.sms') ||
        nameLower.contains('chat') ||
        nameLower.contains('message') ||
        nameLower.contains('call') ||
        nameLower.contains('mail')) {
      return AppCategory.communication;
    }

    // Shopping heuristics
    if (cleanPkg.contains('.shop') ||
        cleanPkg.contains('.store') ||
        cleanPkg.contains('.cart') ||
        nameLower.contains('shop') ||
        nameLower.contains('store') ||
        nameLower.contains('mart') ||
        nameLower.contains('delivery')) {
      return AppCategory.shopping;
    }

    // Default fallback
    return AppCategory.other;
  }

  /// Register custom category override
  static void registerOverride(String packageName, AppCategory category) {
    _customOverrides[packageName.trim().toLowerCase()] = category;
  }

  /// Clears dynamic overrides
  static void clearOverrides() {
    _customOverrides.clear();
  }
}
