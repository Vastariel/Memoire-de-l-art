// mock_data.dart — état initial simulé (port de app.jsx + screens*.jsx).
// Permet un prototype v2 pleinement cliquable et fidèle au design, avant API.

import '../models/game_models.dart';

class MockData {
  static const int week = 19;
  static const int weekDay = 3; // mercredi
  static const String pseudo = 'Camille';
  static const String myPig = 'safran';
  static const int points = 1240;
  static const int streak = 5;

  static const List<InstanceSummary> instances = [
    InstanceSummary(id: 'ARL8', name: 'Atelier du jeudi', mode: InstanceMode.shared, members: 5, place: 2),
    InstanceSummary(id: 'KOI2', name: 'Famille Tran', mode: InstanceMode.separate, members: 3, place: 1),
    InstanceSummary(id: 'SOLO', name: 'Mes essais', mode: InstanceMode.shared, members: 1, solo: true),
  ];

  static const String activeInstance = 'ARL8';

  static const List<DailyTask> tasks = [
    DailyTask(id: 'shared', kind: InstanceMode.shared, variant: 'olive', covers: ['ARL8', 'SOLO']),
    DailyTask(id: 'KOI2', kind: InstanceMode.separate, variant: 'sauge', instanceId: 'KOI2', instanceName: 'Famille Tran'),
  ];

  static const List<LeaderEntry> members = [
    LeaderEntry(pseudo: 'Camille', pig: 'safran', points: 1240, streak: 5, photos: 6, you: true),
    LeaderEntry(pseudo: 'Théo', pig: 'veronese', points: 1180, streak: 7, photos: 7),
    LeaderEntry(pseudo: 'Naomi', pig: 'cobalt', points: 980, streak: 2, photos: 5),
    LeaderEntry(pseudo: 'Inès', pig: 'garance', points: 760, streak: 0, photos: 4),
    LeaderEntry(pseudo: 'Lucas', pig: 'ocre', points: 540, streak: 1, photos: 3),
  ];

  static const List<CollectionItem> gallery = [
    CollectionItem(id: 1, title: 'La Nuit étoilée', artist: 'Van Gogh', year: 1889, week: 18, unlocked: true, seed: ['cobalt', 'ardoise', 'safran']),
    CollectionItem(id: 2, title: 'Les Tournesols', artist: 'Van Gogh', year: 1888, week: 17, unlocked: true, seed: ['safran', 'ambre', 'veronese']),
    CollectionItem(id: 3, title: 'La Grande Vague', artist: 'Hokusai', year: 1831, week: 16, unlocked: true, seed: ['cobalt', 'azur', 'lin']),
    CollectionItem(id: 4, title: 'Le Baiser', artist: 'Klimt', year: 1908, week: 15, unlocked: false, seed: ['safran', 'ocre']),
    CollectionItem(id: 5, title: 'Composition VIII', artist: 'Kandinsky', year: 1923, week: 14, unlocked: true, seed: ['vermillon', 'cobalt', 'safran']),
    CollectionItem(id: 6, title: 'Nymphéas', artist: 'Monet', year: 1916, week: 13, unlocked: true, seed: ['veronese', 'azur', 'rose']),
  ];

  // Note : seed utilise des clés famille pour les MiniArt (mappées vers une
  // variante représentative dans le widget).
  static const Map<String, BlockContribution> contributors = {
    'outremer': BlockContribution('Naomi', 'lun.', 88),
    'cobalt': BlockContribution('Lucas', 'lun.', 81),
    'azur': BlockContribution('Inès', 'lun.', 76),
    'safran': BlockContribution('Camille', 'mar.', 92),
    'ocre': BlockContribution('Théo', 'mar.', 79),
    'ambre': BlockContribution('Sofia', 'mar.', 85),
  };

  static const List<BetOption> betOptions = [
    BetOption('semeur', 'Le Semeur au soleil couchant', 'Vincent van Gogh', 1888),
    BetOption('nuit', 'La Nuit étoilée', 'Vincent van Gogh', 1889),
    BetOption('tournesols', 'Les Tournesols', 'Vincent van Gogh', 1888),
    BetOption('champ', 'Champ de blé aux corbeaux', 'Vincent van Gogh', 1890),
  ];

  // Variantes déjà prises sur la famille du jour (Choix de variante).
  // (clé variante → pseudo)
  static const Map<String, String> takenVariants = {
    'veronese': 'Théo',
    'sauge': 'Inès',
  };
}
