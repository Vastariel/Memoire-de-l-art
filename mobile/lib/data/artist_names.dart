// Curated list of first names from famous artists across movements and eras.
// Used as autocomplete suggestions for user pseudonyms.
const List<String> kArtistFirstNames = [
  // Impressionnisme / Post-impressionnisme
  'Claude', 'Pierre-Auguste', 'Camille', 'Edgar', 'Berthe', 'Alfred',
  'Paul', 'Vincent', 'Georges', 'Henri', 'Mary',
  // Fauvisme / Expressionnisme
  'Wassily', 'Ernst', 'Franz', 'Egon', 'Edvard', 'Oskar',
  // Cubisme / Avant-garde
  'Pablo', 'Juan', 'Fernand', 'Marcel', 'Francis', 'Robert',
  // Surréalisme
  'Salvador', 'René', 'Joan', 'Max', 'Meret', 'Dorothea',
  // Art moderne (XX siècle)
  'Frida', 'Diego', 'Jackson', 'Mark', 'Franz', 'Lee',
  'Willem', 'Jasper', 'Robert', 'Andy', 'Roy', 'David',
  // Art contemporain
  'Yayoi', 'Cindy', 'Jeff', 'Damien', 'Banksy', 'Kara',
  'Jean-Michel', 'Keith', 'Louise', 'Anish', 'Olafur',
  // Classiques
  'Leonardo', 'Michelangelo', 'Raphaël', 'Titien', 'Caravage',
  'Rembrandt', 'Vermeer', 'Rubens', 'Turner', 'Constable',
  'Eugène', 'Gustave', 'Édouard', 'Jean-Baptiste',
  // Modernes européens
  'Gustav', 'Piet', 'Paul', 'Tamara', 'Sonia', 'Niki',
  'Alberto', 'Constantin', 'Amedeo', 'Giorgio', 'Marc',
  // Japonais / Asie
  'Hokusai', 'Hiroshige', 'Utamaro', 'Ai',
];

/// Returns [count] random names from the artist list.
List<String> randomArtistSuggestions(int count) {
  final copy = List<String>.from(kArtistFirstNames)..shuffle();
  return copy.take(count).toList()..sort();
}
