// Core domain types shared by routes and services

export interface Zone {
  id:        string;
  artworkId: string;
  pigment:   string;   // zone slug (e.g. "zone-03")
  label:     string;   // evocative French name
  cellCount: number;
  targetHex: string;   // k-means centroid hex
}

export interface ZoneAssignment {
  id: string;
  zoneId: string;
  instanceId: string;
  playerId: string;
  assignedDate: string;
  submittedAt?: string;
  photoUrl?: string;
  colorDelta?: number;
  blendMode?: 'replace' | 'rejected';
}

export interface Artwork {
  id: string;
  cols: number;
  rows: number;
  cells: MosaicCell[];
  // Revealed only at month end
  title?: string;
  artist?: string;
  year?: number;
  description?: string;
  thumbnailUrl?: string;
  publishedAt?: string;
}

export interface MosaicCell {
  index: number;
  col: number;
  row: number;
  zoneId: string;
}

export interface Instance {
  id: string;
  code: string;               // 6-char alphanumeric
  artworkId: string;
  year: number;
  month: number;              // 1–12
  createdAt: string;
}

export interface Player {
  id: string;
  instanceId: string;
  pseudo?: string;
  avatarPigment: string;
  fcmToken?: string;          // for push notifications
  notifHour: number;          // 0–23
  notifMinute: number;        // 0 | 15 | 30 | 45
  customServerUrl?: string;
  createdAt: string;
  deletedAt?: string;         // GDPR soft-delete
}

export interface ColorMatchResult {
  delta:   number;
  mode:    'replace' | 'rejected';
  verdict: 'parfait' | 'correct' | 'rejeté';
}
