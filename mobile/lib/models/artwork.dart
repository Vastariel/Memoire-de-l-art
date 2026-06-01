import 'zone.dart';

// A mosaic cell — one square block in the pixel grid.
class MosaicCell {
  final int index;
  final int col;
  final int row;
  final String zoneId;

  const MosaicCell({
    required this.index,
    required this.col,
    required this.row,
    required this.zoneId,
  });
}

class Artwork {
  final String id;
  final int cols;
  final int rows;
  final List<MosaicCell> cells;
  final Map<String, Zone> zones;
  final int year;
  final String? title;           // revealed at month end
  final String? artist;          // revealed at month end
  final String? description;     // revealed at month end
  final String? thumbnailUrl;
  final String? hdUrl;           // original HD image, revealed at month end

  const Artwork({
    required this.id,
    required this.cols,
    required this.rows,
    required this.cells,
    required this.zones,
    this.year = 0,
    this.title,
    this.artist,
    this.description,
    this.thumbnailUrl,
    this.hdUrl,
  });

  int get totalCells  => cells.length;
  int get filledCells => cells.where((c) => zones[c.zoneId]?.isFilled ?? false).length;
  double get progress => totalCells == 0 ? 0 : filledCells / totalCells;

  Zone? zoneForCell(MosaicCell cell) => zones[cell.zoneId];

  factory Artwork.fromJson(Map<String, dynamic> json) {
    final zonesRaw = (json['zones'] as List)
        .map((z) => Zone.fromJson(z as Map<String, dynamic>))
        .toList();
    final zonesMap = {for (final z in zonesRaw) z.id: z};

    final cells = (json['cells'] as List).map((c) {
      final m = c as Map<String, dynamic>;
      return MosaicCell(
        index: m['index'] as int,
        col: m['col'] as int,
        row: m['row'] as int,
        zoneId: m['zone_id'] as String,
      );
    }).toList();

    return Artwork(
      id: json['id'] as String,
      cols: json['cols'] as int,
      rows: json['rows'] as int,
      cells: cells,
      zones: zonesMap,
      year:  json['year'] as int? ?? 0,
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      hdUrl:        json['hd_url']        as String?,
    );
  }
}
