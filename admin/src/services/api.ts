import axios from 'axios';

// Token stored in sessionStorage for the current browser session
const getToken = () => sessionStorage.getItem('admin_token') ?? '';
export const setToken = (t: string) => sessionStorage.setItem('admin_token', t);
export const clearToken = () => sessionStorage.removeItem('admin_token');
export const hasToken = () => !!sessionStorage.getItem('admin_token');

const http = axios.create({ baseURL: '/api/admin' });
http.interceptors.request.use(cfg => {
  cfg.headers.Authorization = `Bearer ${getToken()}`;
  return cfg;
});

// ── Types ──────────────────────────────────────────────────────

export interface Stats {
  instances:   number;
  players:     number;
  photosToday: number;
  zonesTotal:  number;
  zonesFilled: number;
}

export interface AdminInstance {
  id:          string;
  code:        string;
  name:        string;
  year_:       number;
  month_:      number;
  players:     number;
  today_count: number;
  filled:      number;
}

export interface AdminArtwork {
  id:           string;
  title?:       string;
  artist?:      string;
  published_at: string | null;
  created_at:   string;
  zone_count:   number;
}

export interface SegmentResult {
  cols:  number;
  rows:  number;
  cells: Array<{ index: number; col: number; row: number; zoneId: string }>;
  zones: Array<{ id: string; pigment: string; cellCount: number; targetHex: string }>;
}

// ── Calls ──────────────────────────────────────────────────────

export const api = {
  stats:     () => http.get<Stats>('/stats').then(r => r.data),
  instances: () => http.get<{ instances: AdminInstance[] }>('/instances').then(r => r.data.instances),
  artworks:  () => http.get<{ artworks: AdminArtwork[] }>('/artworks').then(r => r.data.artworks),

  segment: (file: File, blockSize: number, maxZones: number) => {
    const fd = new FormData();
    fd.append('file', file);
    fd.append('blockSize', String(blockSize));
    fd.append('maxZones', String(maxZones));
    return http.post<SegmentResult>('/artworks/segment', fd).then(r => r.data);
  },

  publish: (payload: {
    cols: number; rows: number;
    cells: unknown[]; zones: unknown[];
    title?: string; artist?: string; year?: number; description?: string;
  }) => http.post<{ id: string; zonesCreated: number }>('/artworks/publish', payload).then(r => r.data),

  deleteArtwork: (id: string) => http.delete(`/artworks/${id}`),
};
