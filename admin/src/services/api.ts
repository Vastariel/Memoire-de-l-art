import axios from 'axios';
import type { Cell } from '../lib/pixelize';

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
  instances: number;
  users: number;
  photosToday: number;
  weeksPlanned: number;
  currentIsoWeek: string;
}

export type ArtworkStatus = 'draft' | 'planned' | 'active' | 'revealed';

export interface AdminArtwork {
  id: string;
  title_fr: string | null;
  artist: string | null;
  year_: number | null;
  status: ArtworkStatus;
  iso_year: number | null;
  iso_week: number | null;
  created_at: string;
}

export interface AdminPhoto {
  id: string;
  url: string;
  taken_on: string;
  day_: number;
  target_variant_key: string;
  delta_e: number | null;
  pseudo: string | null;
}

export interface ArtworkPayload {
  id: string;
  titleFr?: string;
  titleEn?: string;
  artist?: string;
  year?: number;
  descriptionFr?: string;
  descriptionEn?: string;
  sourceLicense?: string;
  cols: number;
  rows: number;
  hdUrl?: string;
  status: ArtworkStatus;
  isoYear: number;
  isoWeek: number;
  cells: Cell[];
  families: { key: string; day: number; nameFr: string; nameEn: string }[];
  variants: { key: string; familyKey: string; nameFr: string; nameEn: string; hex: string }[];
}

// ── Calls ──────────────────────────────────────────────────────
export const api = {
  stats: () => http.get<Stats>('/stats').then(r => r.data),
  artworks: () => http.get<{ artworks: AdminArtwork[] }>('/artworks').then(r => r.data.artworks),
  createArtwork: (p: ArtworkPayload) => http.post<{ ok: boolean; id: string }>('/artworks', p).then(r => r.data),
  setStatus: (id: string, status: ArtworkStatus) =>
    http.post(`/artworks/${id}/status`, { status }).then(r => r.data),
  deleteArtwork: (id: string) => http.delete(`/artworks/${id}`),
  gallery: (params: { instanceId?: string; userId?: string } = {}) =>
    http.get<{ photos: AdminPhoto[] }>('/gallery', { params }).then(r => r.data.photos),
  deletePhoto: (id: string) => http.delete(`/photos/${id}`),
};
