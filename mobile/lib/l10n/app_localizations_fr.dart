// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class L10nFr extends L10n {
  L10nFr([String locale = 'fr']) : super(locale);

  @override
  String get tabToday => 'Aujourd\'hui';

  @override
  String get tabArtwork => 'Œuvre';

  @override
  String get tabInstances => 'Ateliers';

  @override
  String get tabCollection => 'Collection';

  @override
  String get tabProfile => 'Profil';

  @override
  String get actionBack => 'Retour';

  @override
  String get actionContinue => 'Continuer';

  @override
  String get actionShare => 'Partager';

  @override
  String get actionEdit => 'Modifier';

  @override
  String get actionContribute => 'Contribuer';

  @override
  String get actionJoin => 'Rejoindre';

  @override
  String get actionCreate => 'Créer';

  @override
  String get actionTake => 'Rattraper';

  @override
  String get actionBet => 'Parier';

  @override
  String get actionCopy => 'Copier';

  @override
  String get actionCopied => 'Copié';

  @override
  String get weekdayMon => 'lundi';

  @override
  String get weekdayTue => 'mardi';

  @override
  String get weekdayWed => 'mercredi';

  @override
  String get weekdayThu => 'jeudi';

  @override
  String get weekdayFri => 'vendredi';

  @override
  String get weekdaySat => 'samedi';

  @override
  String get weekdaySun => 'dimanche';

  @override
  String get appTagline =>
      'Une famille de couleur par jour, une œuvre par semaine.';

  @override
  String get mysteryArtworkOfWeek => 'Œuvre mystère de la semaine';

  @override
  String get revealedSunday => 'Révélée dimanche';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get accountSyncNote =>
      'Un compte conserve ton score, tes streaks et ta collection sur tous tes appareils.';

  @override
  String get consentText =>
      'J\'accepte la politique de confidentialité et le traitement de mes données (RGPD). Mes photos ne sont visibles que dans mes ateliers.';

  @override
  String get onbStart => 'Commencer';

  @override
  String get onbStep2 => 'Étape 2 · ton identité';

  @override
  String get onbWhatsYourName => 'Comment t\'appelle-t-on ?';

  @override
  String get onbPseudoHint =>
      'Ton pseudo apparaît sur les blocs que tu peins et au classement.';

  @override
  String get onbStep3 => 'Étape 3 · un atelier';

  @override
  String get onbJoinOrCreate => 'Rejoins ou crée un atelier';

  @override
  String get viaCode => 'Code';

  @override
  String get viaLink => 'Lien';

  @override
  String get viaQr => 'QR';

  @override
  String get onbMidWeekNote =>
      'En cours de semaine ? Tu joues dès demain, et tes photos déjà prises sont importées dans l\'œuvre.';

  @override
  String get onbInstanceNamePlaceholder => 'Nom de l\'atelier';

  @override
  String get onbInstanceMode => 'Mode de l\'atelier';

  @override
  String get modeSharedTitle => 'Partagé';

  @override
  String get modeSeparateTitle => 'Séparé';

  @override
  String get modeSharedDesc =>
      'Une seule photo par jour nourrit cet atelier et tes autres ateliers partagés.';

  @override
  String get modeSeparateDesc =>
      'Exige une photo dédiée chaque jour, en plus de tes autres ateliers.';

  @override
  String get onbJoinInstance => 'Rejoindre l\'atelier';

  @override
  String get onbCreateInstance => 'Créer l\'atelier';

  @override
  String get onbScanQr =>
      'Scanne le QR partagé par ton hôte, ou montre le tien.';

  @override
  String get onbOpen => 'Ouvrir';

  @override
  String get devContinue => 'Continuer (dev, sans compte)';

  @override
  String todayOverline(int week, String weekday) {
    return 'Semaine $week · $weekday';
  }

  @override
  String dayProgress(int day) {
    return 'Jour $day / 7';
  }

  @override
  String familyOfDay(String family) {
    return 'Famille du jour · $family';
  }

  @override
  String get variantToPhotograph => 'ta variante à photographier';

  @override
  String get changeVariant => 'Changer de variante / portion';

  @override
  String get photosToTakeToday => 'Photos à faire aujourd\'hui';

  @override
  String tasksLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n restantes',
      one: '1 restante',
    );
    return '$_temp0';
  }

  @override
  String get sharedPhoto => 'Photo partagée';

  @override
  String taskSharedSub(int n, String variant) {
    return 'Nourrit $n ateliers · variante $variant';
  }

  @override
  String taskSeparateSub(String variant) {
    return 'Variante $variant · photo dédiée';
  }

  @override
  String get photosHelpNote =>
      'Une photo partagée alimente tous tes ateliers « Partagés ». Chaque atelier « Séparé » réclame sa propre photo.';

  @override
  String catchupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rattrape $count couleurs manquées',
      one: 'Rattrape 1 couleur manquée',
    );
    return '$_temp0';
  }

  @override
  String get betBanner =>
      'Parie sur l\'œuvre mystère — deviner tôt rapporte plus';

  @override
  String leaderTeaser(int place, int members, String name) {
    return 'Tu es $place sur $members · $name';
  }

  @override
  String get seeWeekLeaderboard => 'Voir le classement de la semaine';

  @override
  String get weekProgress => 'Progression de la semaine';

  @override
  String get unitDay => 'jour';

  @override
  String streakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get claimYourPortion => 'Choisis ta portion';

  @override
  String familyFirstCome(String family) {
    return 'Famille $family · premier arrivé, premier servi';
  }

  @override
  String get variantExplain =>
      'Chaque variante couvre un groupe de blocs de la même teinte. En solo, une photo couvre toute la famille.';

  @override
  String takenBy(String name) {
    return 'prise par $name';
  }

  @override
  String blocksOpen(int n) {
    return '$n blocs · libre';
  }

  @override
  String get mine => 'Ma portion';

  @override
  String get shootMyVariant => 'Photographier ma variante';

  @override
  String get catchupTitle => 'Rattrapage';

  @override
  String get catchupLead => 'Les blocs des jours passés restent ouverts.';

  @override
  String get catchupSub =>
      'Aucune pression : rattrape une photo par couleur manquée quand tu veux cette semaine.';

  @override
  String get allCaughtUp => 'Tu es à jour';

  @override
  String get camTarget => 'Cible';

  @override
  String get camFrameSomething => 'Vise un objet de cette couleur';

  @override
  String get colourAdded => 'Couleur déposée';

  @override
  String meltedInto(String variant) {
    return 'Ta photo s\'est fondue dans la variante $variant.';
  }

  @override
  String get flat => 'Plat';

  @override
  String get glass => 'Vitrail';

  @override
  String get matchLabel => 'fidélité';

  @override
  String streakBonus(int pts) {
    return '+$pts bonus de série';
  }

  @override
  String alsoFed(String name) {
    return 'Cette photo a aussi nourri « $name »';
  }

  @override
  String get seeTheArtwork => 'Voir l\'œuvre';

  @override
  String artworkOverline(int week) {
    return 'Œuvre de la semaine $week';
  }

  @override
  String get theArtwork => 'L\'œuvre';

  @override
  String get renderGlass => 'Vitrail — photos brutes';

  @override
  String get renderFlat => 'Vue plate — pigments';

  @override
  String get zoomHint =>
      'Glisse pour zoomer : les pigments laissent place aux vraies photos.';

  @override
  String familiesCount(int n) {
    return '$n / 7 familles';
  }

  @override
  String get coloursThisWeek => 'couleurs déposées cette semaine';

  @override
  String get todaySuffix => 'aujourd\'hui';

  @override
  String get whichArtworkHides => 'Quelle œuvre se cache ici ?';

  @override
  String yourBet(String title) {
    return 'Ton pari : $title';
  }

  @override
  String get variantLabel => 'Variante';

  @override
  String get leaveAStamp => 'Laisse un tampon';

  @override
  String get stampBravo => 'Bravo';

  @override
  String get stampBold => 'Audacieux';

  @override
  String get stampFind => 'Trouvaille';

  @override
  String get stampSpotOn => 'Pile la teinte';

  @override
  String get stampLight => 'Belle lumière';

  @override
  String betDayOverline(int day) {
    return 'Jour $day · plus tôt = plus de points';
  }

  @override
  String get mysteryBet => 'Pari mystère';

  @override
  String get betPointsHint =>
      'si tu trouves dès aujourd\'hui · 60 pts dimanche';

  @override
  String get placeMyBet => 'Valider mon pari';

  @override
  String get betRule => 'Un seul pari par semaine. Modifiable jusqu\'à samedi.';

  @override
  String get myInstances => 'Mes ateliers';

  @override
  String get labelSolo => 'solo';

  @override
  String get leaderboard => 'Classement';

  @override
  String get weeklyTab => 'Classement hebdo';

  @override
  String get membersTab => 'Membres';

  @override
  String get sharedExplain => 'Une photo par jour nourrit tout le monde.';

  @override
  String get separateExplain => 'Chacun doit poster sa propre photo du jour.';

  @override
  String get soloInstance => 'Atelier solo';

  @override
  String get soloInstanceDesc =>
      'Ton atelier perso : pas de classement, juste ton œuvre.';

  @override
  String get labelYou => 'toi';

  @override
  String nPhotos(int n) {
    return '$n/7 photos';
  }

  @override
  String get unitPts => 'pts';

  @override
  String inviteTo(String name) {
    return 'Inviter dans $name';
  }

  @override
  String get inviteShareAny =>
      'Partage l\'un de ces moyens pour ajouter un membre.';

  @override
  String validDays(int n) {
    return 'Valable $n jours';
  }

  @override
  String get shareInvite => 'Partager l\'invitation';

  @override
  String worksAcquired(int n) {
    return '$n œuvres acquises';
  }

  @override
  String get collectionLead =>
      'Ton musée personnel. Termine une semaine pour révéler l\'œuvre.';

  @override
  String get lockedWork => 'Œuvre verrouillée';

  @override
  String get incompleteWeek => 'Semaine incomplète';

  @override
  String weekShort(int n) {
    return 'S$n';
  }

  @override
  String revealOverline(int week) {
    return 'Dimanche · Semaine $week';
  }

  @override
  String get artworkRevealed => 'L\'œuvre est révélée';

  @override
  String get betWon => 'Pari gagné';

  @override
  String get shareCard => 'Partager la carte';

  @override
  String get addToCollection => 'Ajouter à ma collection';

  @override
  String memberSince(String month) {
    return 'Membre depuis $month';
  }

  @override
  String get statStreak => 'série';

  @override
  String get statWorks => 'œuvres';

  @override
  String get attendance => 'Assiduité · 4 dernières semaines';

  @override
  String get settings => 'Réglages';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get notifications => 'Notifications';

  @override
  String get dailyReminder => 'Rappel quotidien';

  @override
  String get dailyReminderHint =>
      'Chaque jour à 09:00 (heure locale, basé UTC)';

  @override
  String get revealRanking => 'Reveal & classement';

  @override
  String get revealRankingHint => 'Reveal du dimanche et fin de manche';

  @override
  String get privacyGdpr => 'Confidentialité (RGPD)';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get exportData => 'Exporter mes données';

  @override
  String get deleteAccount => 'Supprimer mon compte';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get reminderTime => 'Heure du rappel';

  @override
  String get renameTitle => 'Ton pseudo';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get exportDone => 'Données exportées';

  @override
  String get exportFailed => 'Export impossible';

  @override
  String get deleteAccountTitle => 'Supprimer le compte ?';

  @override
  String get deleteAccountBody =>
      'Tes photos et contributions seront effacées définitivement. Cette action est irréversible.';
}
