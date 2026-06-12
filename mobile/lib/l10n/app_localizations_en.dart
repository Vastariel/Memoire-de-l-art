// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get tabToday => 'Today';

  @override
  String get tabArtwork => 'Artwork';

  @override
  String get tabInstances => 'Ateliers';

  @override
  String get tabCollection => 'Collection';

  @override
  String get tabProfile => 'Profile';

  @override
  String get actionBack => 'Back';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionShare => 'Share';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionContribute => 'Contribute';

  @override
  String get actionJoin => 'Join';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionTake => 'Take';

  @override
  String get actionBet => 'Bet';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionCopied => 'Copied';

  @override
  String get weekdayMon => 'Monday';

  @override
  String get weekdayTue => 'Tuesday';

  @override
  String get weekdayWed => 'Wednesday';

  @override
  String get weekdayThu => 'Thursday';

  @override
  String get weekdayFri => 'Friday';

  @override
  String get weekdaySat => 'Saturday';

  @override
  String get weekdaySun => 'Sunday';

  @override
  String get appTagline => 'A colour family a day, an artwork a week.';

  @override
  String get mysteryArtworkOfWeek => 'Mystery artwork of the week';

  @override
  String get revealedSunday => 'Revealed Sunday';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get accountSyncNote =>
      'An account keeps your score, streaks and collection across all your devices.';

  @override
  String get consentText =>
      'I accept the privacy policy and the processing of my data (GDPR). My photos are only visible within my ateliers.';

  @override
  String get onbStart => 'Start';

  @override
  String get onbStep2 => 'Step 2 · your identity';

  @override
  String get onbWhatsYourName => 'What should we call you?';

  @override
  String get onbPseudoHint =>
      'Your pseudonym appears on the blocks you paint and on the leaderboard.';

  @override
  String get onbStep3 => 'Step 3 · an atelier';

  @override
  String get onbJoinOrCreate => 'Join or create a studio';

  @override
  String get viaCode => 'Code';

  @override
  String get viaLink => 'Link';

  @override
  String get viaQr => 'QR';

  @override
  String get onbMidWeekNote =>
      'Mid-week? You play from tomorrow, and the photos you\'ve already taken are imported into the artwork.';

  @override
  String get onbInstanceNamePlaceholder => 'Atelier name';

  @override
  String get onbInstanceMode => 'Atelier mode';

  @override
  String get modeSharedTitle => 'Shared';

  @override
  String get modeSeparateTitle => 'Separate';

  @override
  String get modeSharedDesc =>
      'One photo a day feeds this atelier and your other shared ateliers.';

  @override
  String get modeSeparateDesc =>
      'Requires a dedicated photo each day, on top of your other ateliers.';

  @override
  String get onbJoinInstance => 'Join the atelier';

  @override
  String get onbCreateInstance => 'Create the atelier';

  @override
  String get onbScanQr => 'Scan the QR shared by your host, or show yours.';

  @override
  String get onbOpen => 'Open';

  @override
  String get devContinue => 'Continue (dev, no account)';

  @override
  String todayOverline(int week, String weekday) {
    return 'Week $week · $weekday';
  }

  @override
  String dayProgress(int day) {
    return 'Day $day / 7';
  }

  @override
  String familyOfDay(String family) {
    return 'Family of the day · $family';
  }

  @override
  String get variantToPhotograph => 'your variant to photograph';

  @override
  String get changeVariant => 'Change variant / portion';

  @override
  String get photosToTakeToday => 'Photos to take today';

  @override
  String tasksLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n left',
      one: '1 left',
    );
    return '$_temp0';
  }

  @override
  String get sharedPhoto => 'Shared photo';

  @override
  String taskSharedSub(int n, String variant) {
    return 'Feeds $n ateliers · variant $variant';
  }

  @override
  String taskSeparateSub(String variant) {
    return 'Variant $variant · dedicated photo';
  }

  @override
  String get photosHelpNote =>
      'One shared photo feeds all your Shared ateliers. Each Separate atelier needs its own photo.';

  @override
  String catchupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Catch up $count missed colours',
      one: 'Catch up 1 missed colour',
    );
    return '$_temp0';
  }

  @override
  String get betBanner =>
      'Bet on the mystery artwork — guess early, score more';

  @override
  String leaderTeaser(int place, int members, String name) {
    return 'You are $place of $members · $name';
  }

  @override
  String get seeWeekLeaderboard => 'See this week\'s leaderboard';

  @override
  String get weekProgress => 'This week';

  @override
  String get unitDay => 'day';

  @override
  String streakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get claimYourPortion => 'Claim your portion';

  @override
  String familyFirstCome(String family) {
    return 'Family $family · first come, first served';
  }

  @override
  String get variantExplain =>
      'Each variant covers a cluster of same-hue blocks. Solo, one photo covers the whole family.';

  @override
  String takenBy(String name) {
    return 'taken by $name';
  }

  @override
  String blocksOpen(int n) {
    return '$n blocks · open';
  }

  @override
  String get mine => 'Mine';

  @override
  String get shootMyVariant => 'Shoot my variant';

  @override
  String get catchupTitle => 'Catch up';

  @override
  String get catchupLead => 'Past days stay open.';

  @override
  String get catchupSub =>
      'No pressure: one photo per missed colour, any time this week.';

  @override
  String get allCaughtUp => 'All caught up';

  @override
  String get camTarget => 'Target';

  @override
  String get camFrameSomething => 'Frame something this colour';

  @override
  String get colourAdded => 'Colour added';

  @override
  String meltedInto(String variant) {
    return 'Your photo melted into the $variant variant.';
  }

  @override
  String get flat => 'Flat';

  @override
  String get glass => 'Glass';

  @override
  String get matchLabel => 'match';

  @override
  String streakBonus(int pts) {
    return '+$pts streak bonus';
  }

  @override
  String alsoFed(String name) {
    return 'This photo also fed “$name”';
  }

  @override
  String get seeTheArtwork => 'See the artwork';

  @override
  String artworkOverline(int week) {
    return 'Artwork · week $week';
  }

  @override
  String get theArtwork => 'The artwork';

  @override
  String get renderGlass => 'Stained glass — raw photos';

  @override
  String get renderFlat => 'Flat view — pigments';

  @override
  String get zoomHint => 'Slide to zoom: pigments give way to the real photos.';

  @override
  String familiesCount(int n) {
    return '$n / 7 families';
  }

  @override
  String get coloursThisWeek => 'colours laid this week';

  @override
  String get todaySuffix => 'today';

  @override
  String get whichArtworkHides => 'Which artwork hides here?';

  @override
  String yourBet(String title) {
    return 'Your bet: $title';
  }

  @override
  String get variantLabel => 'Variant';

  @override
  String get leaveAStamp => 'Leave a stamp';

  @override
  String get stampBravo => 'Bravo';

  @override
  String get stampBold => 'Bold';

  @override
  String get stampFind => 'Great find';

  @override
  String get stampSpotOn => 'Spot on';

  @override
  String get stampLight => 'Lovely light';

  @override
  String betDayOverline(int day) {
    return 'Day $day · earlier = more points';
  }

  @override
  String get mysteryBet => 'Mystery bet';

  @override
  String get betPointsHint => 'if correct today · 60 pts Sunday';

  @override
  String get placeMyBet => 'Place my bet';

  @override
  String get betRule => 'One bet per week. Editable until Saturday.';

  @override
  String get myInstances => 'My ateliers';

  @override
  String get labelSolo => 'solo';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get weeklyTab => 'Weekly';

  @override
  String get membersTab => 'Members';

  @override
  String get sharedExplain => 'One photo a day feeds everyone.';

  @override
  String get separateExplain => 'Everyone posts their own daily photo.';

  @override
  String get soloInstance => 'Solo atelier';

  @override
  String get soloInstanceDesc =>
      'Your private atelier: no ranking, just your artwork.';

  @override
  String get labelYou => 'you';

  @override
  String nPhotos(int n) {
    return '$n/7 photos';
  }

  @override
  String get unitPts => 'pts';

  @override
  String inviteTo(String name) {
    return 'Invite to $name';
  }

  @override
  String get inviteShareAny => 'Share any of these to add a member.';

  @override
  String validDays(int n) {
    return 'Valid $n days';
  }

  @override
  String get shareInvite => 'Share invite';

  @override
  String worksAcquired(int n) {
    return '$n works acquired';
  }

  @override
  String get collectionLead =>
      'Your private museum. Finish a week to reveal its artwork.';

  @override
  String get lockedWork => 'Locked artwork';

  @override
  String get incompleteWeek => 'Incomplete week';

  @override
  String weekShort(int n) {
    return 'W$n';
  }

  @override
  String revealOverline(int week) {
    return 'Sunday · Week $week';
  }

  @override
  String get artworkRevealed => 'The artwork is revealed';

  @override
  String get betWon => 'Bet won';

  @override
  String get shareCard => 'Share card';

  @override
  String get addToCollection => 'Add to collection';

  @override
  String memberSince(String month) {
    return 'Member since $month';
  }

  @override
  String get statStreak => 'streak';

  @override
  String get statWorks => 'works';

  @override
  String get attendance => 'Streak · last 4 weeks';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get notifications => 'Notifications';

  @override
  String get dailyReminder => 'Daily reminder';

  @override
  String get dailyReminderHint => 'Daily at 09:00 (local, UTC-based)';

  @override
  String get revealRanking => 'Reveal & ranking';

  @override
  String get revealRankingHint => 'Sunday reveal & round end';

  @override
  String get privacyGdpr => 'Privacy (GDPR)';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get exportData => 'Export my data';

  @override
  String get deleteAccount => 'Delete my account';

  @override
  String get signOut => 'Sign out';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get renameTitle => 'Your nickname';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get exportDone => 'Data exported';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountBody =>
      'Your photos and contributions will be permanently erased. This cannot be undone.';
}
