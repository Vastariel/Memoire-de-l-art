// wikimedia.ts — fetch artwork metadata + image from a Wikipedia article or a
// Wikimedia Commons file URL, so the admin can pre-fill the form and start
// pixelising in one click.
//
// Two URL shapes are supported:
//   1. Commons file: https://commons.wikimedia.org/wiki/File:<name>
//      → query API returns the full-resolution image URL and extmetadata
//        (artist, year, license, description, source).
//   2. Wikipedia article: https://<lang>.wikipedia.org/wiki/<title>
//      → REST summary returns title + extract + originalimage; if the page
//        has a leading image we also pull its Commons metadata.

export interface WikimediaFetch {
  imageUrl: string;
  titleFr?: string;
  titleEn?: string;
  artist?: string;
  year?: number;
  descriptionFr?: string;
  descriptionEn?: string;
  sourceLicense: string;
}

interface ExtMetaField { value?: string }
interface ExtMetadata {
  Artist?: ExtMetaField;
  ObjectName?: ExtMetaField;
  ImageDescription?: ExtMetaField;
  DateTimeOriginal?: ExtMetaField;
  DateTime?: ExtMetaField;
  Credit?: ExtMetaField;
  LicenseShortName?: ExtMetaField;
  LicenseUrl?: ExtMetaField;
  UsageTerms?: ExtMetaField;
}

function stripHtml(s: string | undefined): string | undefined {
  if (!s) return undefined;
  const t = s.replace(/<[^>]*>/g, '').replace(/\s+/g, ' ').trim();
  return t || undefined;
}

function firstYear(s: string | undefined): number | undefined {
  if (!s) return undefined;
  const m = s.match(/-?\d{3,4}/);
  return m ? parseInt(m[0], 10) : undefined;
}

async function fetchCommonsFile(filename: string, pageUrl: string): Promise<WikimediaFetch> {
  const api = new URL('https://commons.wikimedia.org/w/api.php');
  api.searchParams.set('action', 'query');
  api.searchParams.set('format', 'json');
  api.searchParams.set('origin', '*');
  api.searchParams.set('prop', 'imageinfo');
  api.searchParams.set('iiprop', 'url|extmetadata|size');
  api.searchParams.set('iiurlwidth', '2400');
  api.searchParams.set('titles', `File:${filename}`);

  const r = await fetch(api.toString());
  if (!r.ok) throw new Error(`Wikimedia HTTP ${r.status}`);
  const j = await r.json();
  const pages = j?.query?.pages ?? {};
  const page = Object.values(pages)[0] as { imageinfo?: Array<{ url: string; thumburl?: string; extmetadata?: ExtMetadata }> } | undefined;
  const info = page?.imageinfo?.[0];
  if (!info) throw new Error('Aucune image trouvée pour ce fichier.');
  const m = info.extmetadata ?? {};

  const artist = stripHtml(m.Artist?.value);
  const description = stripHtml(m.ImageDescription?.value);
  const objectName = stripHtml(m.ObjectName?.value);
  const year = firstYear(m.DateTimeOriginal?.value ?? m.DateTime?.value);
  const license = stripHtml(m.LicenseShortName?.value) ?? stripHtml(m.UsageTerms?.value) ?? 'Wikimedia Commons';

  return {
    imageUrl: info.thumburl ?? info.url,
    titleFr: objectName,
    artist,
    year,
    descriptionFr: description,
    sourceLicense: `${license} — ${pageUrl}`,
  };
}

async function fetchWikipediaArticle(lang: string, title: string, pageUrl: string): Promise<WikimediaFetch> {
  const summary = await fetch(
    `https://${lang}.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(title)}`,
    { headers: { accept: 'application/json' } },
  );
  if (!summary.ok) throw new Error(`Wikipedia HTTP ${summary.status}`);
  const s = await summary.json();
  const image = s?.originalimage?.source ?? s?.thumbnail?.source;
  if (!image) throw new Error('Cet article n\'a pas d\'image principale.');

  // Try to enrich with Commons metadata if the image lives there.
  let enrich: Partial<WikimediaFetch> = {};
  const fileMatch = (image as string).match(/\/([^/]+\.(jpe?g|png|webp|tiff?))/i);
  if (fileMatch) {
    try {
      const filename = decodeURIComponent(fileMatch[1]);
      const c = await fetchCommonsFile(filename, image);
      enrich = { artist: c.artist, year: c.year, sourceLicense: c.sourceLicense };
    } catch { /* not on Commons or no metadata — fine */ }
  }

  const field = lang === 'fr' ? 'descriptionFr' : 'descriptionEn';
  const tField = lang === 'fr' ? 'titleFr' : 'titleEn';
  return {
    imageUrl: image,
    [tField]: s.title,
    [field]: s.extract,
    sourceLicense: enrich.sourceLicense ?? `Wikipédia — ${pageUrl}`,
    artist: enrich.artist,
    year: enrich.year,
  } as WikimediaFetch;
}

export async function fetchArtworkFromUrl(rawUrl: string): Promise<WikimediaFetch> {
  let url: URL;
  try { url = new URL(rawUrl.trim()); } catch { throw new Error('URL invalide.'); }

  // Commons File page → query the file directly.
  if (url.hostname.endsWith('wikimedia.org') && url.pathname.startsWith('/wiki/File:')) {
    const filename = decodeURIComponent(url.pathname.replace('/wiki/File:', ''));
    return fetchCommonsFile(filename, url.toString());
  }

  // Wikipedia article in any language.
  const wpMatch = url.hostname.match(/^([a-z]{2,3})\.wikipedia\.org$/);
  if (wpMatch && url.pathname.startsWith('/wiki/')) {
    const lang = wpMatch[1];
    const title = decodeURIComponent(url.pathname.replace('/wiki/', ''));
    return fetchWikipediaArticle(lang, title, url.toString());
  }

  throw new Error('URL non reconnue. Colle un lien Wikipédia ou un fichier Wikimedia Commons.');
}

/// Load a (CORS-enabled) image URL into an HTMLImageElement usable by canvas.
export function loadImage(src: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => resolve(img);
    img.onerror = () => reject(new Error('Échec du chargement de l\'image.'));
    img.src = src;
  });
}
