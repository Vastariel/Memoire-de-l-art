import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabArtwork.
  ///
  /// In en, this message translates to:
  /// **'Artwork'**
  String get tabArtwork;

  /// No description provided for @tabInstances.
  ///
  /// In en, this message translates to:
  /// **'Ateliers'**
  String get tabInstances;

  /// No description provided for @tabCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get tabCollection;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionContribute.
  ///
  /// In en, this message translates to:
  /// **'Contribute'**
  String get actionContribute;

  /// No description provided for @actionJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get actionJoin;

  /// No description provided for @actionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// No description provided for @actionTake.
  ///
  /// In en, this message translates to:
  /// **'Take'**
  String get actionTake;

  /// No description provided for @actionBet.
  ///
  /// In en, this message translates to:
  /// **'Bet'**
  String get actionBet;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @actionCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get actionCopied;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdaySun;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'A colour family a day, an artwork a week.'**
  String get appTagline;

  /// No description provided for @mysteryArtworkOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Mystery artwork of the week'**
  String get mysteryArtworkOfWeek;

  /// No description provided for @revealedSunday.
  ///
  /// In en, this message translates to:
  /// **'Revealed Sunday'**
  String get revealedSunday;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @accountSyncNote.
  ///
  /// In en, this message translates to:
  /// **'An account keeps your score, streaks and collection across all your devices.'**
  String get accountSyncNote;

  /// No description provided for @consentText.
  ///
  /// In en, this message translates to:
  /// **'I accept the privacy policy and the processing of my data (GDPR). My photos are only visible within my ateliers.'**
  String get consentText;

  /// No description provided for @onbStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onbStart;

  /// No description provided for @onbStep2.
  ///
  /// In en, this message translates to:
  /// **'Step 2 · your identity'**
  String get onbStep2;

  /// No description provided for @onbWhatsYourName.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get onbWhatsYourName;

  /// No description provided for @onbPseudoHint.
  ///
  /// In en, this message translates to:
  /// **'Your pseudonym appears on the blocks you paint and on the leaderboard.'**
  String get onbPseudoHint;

  /// No description provided for @onbStep3.
  ///
  /// In en, this message translates to:
  /// **'Step 3 · an atelier'**
  String get onbStep3;

  /// No description provided for @onbJoinOrCreate.
  ///
  /// In en, this message translates to:
  /// **'Join or create a studio'**
  String get onbJoinOrCreate;

  /// No description provided for @viaCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get viaCode;

  /// No description provided for @viaLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get viaLink;

  /// No description provided for @viaQr.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get viaQr;

  /// No description provided for @onbMidWeekNote.
  ///
  /// In en, this message translates to:
  /// **'Mid-week? You play from tomorrow, and the photos you\'ve already taken are imported into the artwork.'**
  String get onbMidWeekNote;

  /// No description provided for @onbInstanceNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Atelier name'**
  String get onbInstanceNamePlaceholder;

  /// No description provided for @onbInstanceMode.
  ///
  /// In en, this message translates to:
  /// **'Atelier mode'**
  String get onbInstanceMode;

  /// No description provided for @modeSharedTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get modeSharedTitle;

  /// No description provided for @modeSeparateTitle.
  ///
  /// In en, this message translates to:
  /// **'Separate'**
  String get modeSeparateTitle;

  /// No description provided for @modeSharedDesc.
  ///
  /// In en, this message translates to:
  /// **'One photo a day feeds this atelier and your other shared ateliers.'**
  String get modeSharedDesc;

  /// No description provided for @modeSeparateDesc.
  ///
  /// In en, this message translates to:
  /// **'Requires a dedicated photo each day, on top of your other ateliers.'**
  String get modeSeparateDesc;

  /// No description provided for @onbJoinInstance.
  ///
  /// In en, this message translates to:
  /// **'Join the atelier'**
  String get onbJoinInstance;

  /// No description provided for @onbCreateInstance.
  ///
  /// In en, this message translates to:
  /// **'Create the atelier'**
  String get onbCreateInstance;

  /// No description provided for @onbScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR shared by your host, or show yours.'**
  String get onbScanQr;

  /// No description provided for @onbOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get onbOpen;

  /// No description provided for @devContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue (dev, no account)'**
  String get devContinue;

  /// No description provided for @todayOverline.
  ///
  /// In en, this message translates to:
  /// **'Week {week} · {weekday}'**
  String todayOverline(int week, String weekday);

  /// No description provided for @dayProgress.
  ///
  /// In en, this message translates to:
  /// **'Day {day} / 7'**
  String dayProgress(int day);

  /// No description provided for @familyOfDay.
  ///
  /// In en, this message translates to:
  /// **'Family of the day · {family}'**
  String familyOfDay(String family);

  /// No description provided for @variantToPhotograph.
  ///
  /// In en, this message translates to:
  /// **'your variant to photograph'**
  String get variantToPhotograph;

  /// No description provided for @changeVariant.
  ///
  /// In en, this message translates to:
  /// **'Change variant / portion'**
  String get changeVariant;

  /// No description provided for @photosToTakeToday.
  ///
  /// In en, this message translates to:
  /// **'Photos to take today'**
  String get photosToTakeToday;

  /// No description provided for @tasksLeft.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 left} other{{n} left}}'**
  String tasksLeft(int n);

  /// No description provided for @sharedPhoto.
  ///
  /// In en, this message translates to:
  /// **'Shared photo'**
  String get sharedPhoto;

  /// No description provided for @taskSharedSub.
  ///
  /// In en, this message translates to:
  /// **'Feeds {n} ateliers · variant {variant}'**
  String taskSharedSub(int n, String variant);

  /// No description provided for @taskSeparateSub.
  ///
  /// In en, this message translates to:
  /// **'Variant {variant} · dedicated photo'**
  String taskSeparateSub(String variant);

  /// No description provided for @photosHelpNote.
  ///
  /// In en, this message translates to:
  /// **'One shared photo feeds all your Shared ateliers. Each Separate atelier needs its own photo.'**
  String get photosHelpNote;

  /// No description provided for @catchupCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Catch up 1 missed colour} other{Catch up {count} missed colours}}'**
  String catchupCount(int count);

  /// No description provided for @betBanner.
  ///
  /// In en, this message translates to:
  /// **'Bet on the mystery artwork — guess early, score more'**
  String get betBanner;

  /// No description provided for @leaderTeaser.
  ///
  /// In en, this message translates to:
  /// **'You are {place} of {members} · {name}'**
  String leaderTeaser(int place, int members, String name);

  /// No description provided for @seeWeekLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'See this week\'s leaderboard'**
  String get seeWeekLeaderboard;

  /// No description provided for @weekProgress.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get weekProgress;

  /// No description provided for @unitDay.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get unitDay;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String streakDays(int days);

  /// No description provided for @claimYourPortion.
  ///
  /// In en, this message translates to:
  /// **'Claim your portion'**
  String get claimYourPortion;

  /// No description provided for @familyFirstCome.
  ///
  /// In en, this message translates to:
  /// **'Family {family} · first come, first served'**
  String familyFirstCome(String family);

  /// No description provided for @variantExplain.
  ///
  /// In en, this message translates to:
  /// **'Each variant covers a cluster of same-hue blocks. Solo, one photo covers the whole family.'**
  String get variantExplain;

  /// No description provided for @takenBy.
  ///
  /// In en, this message translates to:
  /// **'taken by {name}'**
  String takenBy(String name);

  /// No description provided for @blocksOpen.
  ///
  /// In en, this message translates to:
  /// **'{n} blocks · open'**
  String blocksOpen(int n);

  /// No description provided for @mine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get mine;

  /// No description provided for @shootMyVariant.
  ///
  /// In en, this message translates to:
  /// **'Shoot my variant'**
  String get shootMyVariant;

  /// No description provided for @catchupTitle.
  ///
  /// In en, this message translates to:
  /// **'Catch up'**
  String get catchupTitle;

  /// No description provided for @catchupLead.
  ///
  /// In en, this message translates to:
  /// **'Past days stay open.'**
  String get catchupLead;

  /// No description provided for @catchupSub.
  ///
  /// In en, this message translates to:
  /// **'No pressure: one photo per missed colour, any time this week.'**
  String get catchupSub;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get allCaughtUp;

  /// No description provided for @camTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get camTarget;

  /// No description provided for @camFrameSomething.
  ///
  /// In en, this message translates to:
  /// **'Frame something this colour'**
  String get camFrameSomething;

  /// No description provided for @colourAdded.
  ///
  /// In en, this message translates to:
  /// **'Colour added'**
  String get colourAdded;

  /// No description provided for @meltedInto.
  ///
  /// In en, this message translates to:
  /// **'Your photo melted into the {variant} variant.'**
  String meltedInto(String variant);

  /// No description provided for @flat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get flat;

  /// No description provided for @glass.
  ///
  /// In en, this message translates to:
  /// **'Glass'**
  String get glass;

  /// No description provided for @matchLabel.
  ///
  /// In en, this message translates to:
  /// **'match'**
  String get matchLabel;

  /// No description provided for @streakBonus.
  ///
  /// In en, this message translates to:
  /// **'+{pts} streak bonus'**
  String streakBonus(int pts);

  /// No description provided for @alsoFed.
  ///
  /// In en, this message translates to:
  /// **'This photo also fed “{name}”'**
  String alsoFed(String name);

  /// No description provided for @seeTheArtwork.
  ///
  /// In en, this message translates to:
  /// **'See the artwork'**
  String get seeTheArtwork;

  /// No description provided for @artworkOverline.
  ///
  /// In en, this message translates to:
  /// **'Artwork · week {week}'**
  String artworkOverline(int week);

  /// No description provided for @theArtwork.
  ///
  /// In en, this message translates to:
  /// **'The artwork'**
  String get theArtwork;

  /// No description provided for @renderGlass.
  ///
  /// In en, this message translates to:
  /// **'Stained glass — raw photos'**
  String get renderGlass;

  /// No description provided for @renderFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat view — pigments'**
  String get renderFlat;

  /// No description provided for @zoomHint.
  ///
  /// In en, this message translates to:
  /// **'Slide to zoom: pigments give way to the real photos.'**
  String get zoomHint;

  /// No description provided for @familiesCount.
  ///
  /// In en, this message translates to:
  /// **'{n} / 7 families'**
  String familiesCount(int n);

  /// No description provided for @coloursThisWeek.
  ///
  /// In en, this message translates to:
  /// **'colours laid this week'**
  String get coloursThisWeek;

  /// No description provided for @todaySuffix.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get todaySuffix;

  /// No description provided for @whichArtworkHides.
  ///
  /// In en, this message translates to:
  /// **'Which artwork hides here?'**
  String get whichArtworkHides;

  /// No description provided for @yourBet.
  ///
  /// In en, this message translates to:
  /// **'Your bet: {title}'**
  String yourBet(String title);

  /// No description provided for @variantLabel.
  ///
  /// In en, this message translates to:
  /// **'Variant'**
  String get variantLabel;

  /// No description provided for @leaveAStamp.
  ///
  /// In en, this message translates to:
  /// **'Leave a stamp'**
  String get leaveAStamp;

  /// No description provided for @stampBravo.
  ///
  /// In en, this message translates to:
  /// **'Bravo'**
  String get stampBravo;

  /// No description provided for @stampBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get stampBold;

  /// No description provided for @stampFind.
  ///
  /// In en, this message translates to:
  /// **'Great find'**
  String get stampFind;

  /// No description provided for @stampSpotOn.
  ///
  /// In en, this message translates to:
  /// **'Spot on'**
  String get stampSpotOn;

  /// No description provided for @stampLight.
  ///
  /// In en, this message translates to:
  /// **'Lovely light'**
  String get stampLight;

  /// No description provided for @betDayOverline.
  ///
  /// In en, this message translates to:
  /// **'Day {day} · earlier = more points'**
  String betDayOverline(int day);

  /// No description provided for @mysteryBet.
  ///
  /// In en, this message translates to:
  /// **'Mystery bet'**
  String get mysteryBet;

  /// No description provided for @betPointsHint.
  ///
  /// In en, this message translates to:
  /// **'if correct today · 60 pts Sunday'**
  String get betPointsHint;

  /// No description provided for @placeMyBet.
  ///
  /// In en, this message translates to:
  /// **'Place my bet'**
  String get placeMyBet;

  /// No description provided for @betRule.
  ///
  /// In en, this message translates to:
  /// **'One bet per week. Editable until Saturday.'**
  String get betRule;

  /// No description provided for @myInstances.
  ///
  /// In en, this message translates to:
  /// **'My ateliers'**
  String get myInstances;

  /// No description provided for @labelSolo.
  ///
  /// In en, this message translates to:
  /// **'solo'**
  String get labelSolo;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @weeklyTab.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weeklyTab;

  /// No description provided for @membersTab.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersTab;

  /// No description provided for @sharedExplain.
  ///
  /// In en, this message translates to:
  /// **'One photo a day feeds everyone.'**
  String get sharedExplain;

  /// No description provided for @separateExplain.
  ///
  /// In en, this message translates to:
  /// **'Everyone posts their own daily photo.'**
  String get separateExplain;

  /// No description provided for @soloInstance.
  ///
  /// In en, this message translates to:
  /// **'Solo atelier'**
  String get soloInstance;

  /// No description provided for @soloInstanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Your private atelier: no ranking, just your artwork.'**
  String get soloInstanceDesc;

  /// No description provided for @labelYou.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get labelYou;

  /// No description provided for @nPhotos.
  ///
  /// In en, this message translates to:
  /// **'{n}/7 photos'**
  String nPhotos(int n);

  /// No description provided for @unitPts.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get unitPts;

  /// No description provided for @inviteTo.
  ///
  /// In en, this message translates to:
  /// **'Invite to {name}'**
  String inviteTo(String name);

  /// No description provided for @inviteShareAny.
  ///
  /// In en, this message translates to:
  /// **'Share any of these to add a member.'**
  String get inviteShareAny;

  /// No description provided for @validDays.
  ///
  /// In en, this message translates to:
  /// **'Valid {n} days'**
  String validDays(int n);

  /// No description provided for @shareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share invite'**
  String get shareInvite;

  /// No description provided for @worksAcquired.
  ///
  /// In en, this message translates to:
  /// **'{n} works acquired'**
  String worksAcquired(int n);

  /// No description provided for @collectionLead.
  ///
  /// In en, this message translates to:
  /// **'Your private museum. Finish a week to reveal its artwork.'**
  String get collectionLead;

  /// No description provided for @lockedWork.
  ///
  /// In en, this message translates to:
  /// **'Locked artwork'**
  String get lockedWork;

  /// No description provided for @incompleteWeek.
  ///
  /// In en, this message translates to:
  /// **'Incomplete week'**
  String get incompleteWeek;

  /// No description provided for @weekShort.
  ///
  /// In en, this message translates to:
  /// **'W{n}'**
  String weekShort(int n);

  /// No description provided for @revealOverline.
  ///
  /// In en, this message translates to:
  /// **'Sunday · Week {week}'**
  String revealOverline(int week);

  /// No description provided for @artworkRevealed.
  ///
  /// In en, this message translates to:
  /// **'The artwork is revealed'**
  String get artworkRevealed;

  /// No description provided for @betWon.
  ///
  /// In en, this message translates to:
  /// **'Bet won'**
  String get betWon;

  /// No description provided for @shareCard.
  ///
  /// In en, this message translates to:
  /// **'Share card'**
  String get shareCard;

  /// No description provided for @addToCollection.
  ///
  /// In en, this message translates to:
  /// **'Add to collection'**
  String get addToCollection;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {month}'**
  String memberSince(String month);

  /// No description provided for @statStreak.
  ///
  /// In en, this message translates to:
  /// **'streak'**
  String get statStreak;

  /// No description provided for @statWorks.
  ///
  /// In en, this message translates to:
  /// **'works'**
  String get statWorks;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Streak · last 4 weeks'**
  String get attendance;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get dailyReminder;

  /// No description provided for @dailyReminderHint.
  ///
  /// In en, this message translates to:
  /// **'Daily at 09:00 (local, UTC-based)'**
  String get dailyReminderHint;

  /// No description provided for @revealRanking.
  ///
  /// In en, this message translates to:
  /// **'Reveal & ranking'**
  String get revealRanking;

  /// No description provided for @revealRankingHint.
  ///
  /// In en, this message translates to:
  /// **'Sunday reveal & round end'**
  String get revealRankingHint;

  /// No description provided for @privacyGdpr.
  ///
  /// In en, this message translates to:
  /// **'Privacy (GDPR)'**
  String get privacyGdpr;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get exportData;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccount;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'fr':
      return L10nFr();
  }

  throw FlutterError(
      'L10n.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
