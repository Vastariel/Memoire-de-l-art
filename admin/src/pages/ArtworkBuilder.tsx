import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  Alert, Card, Row, Col, Slider, InputNumber, Form, Input, Select, Button, Upload, Typography,
  Divider, Space, Tag, message,
} from 'antd';
import { InboxOutlined, UploadOutlined } from '@ant-design/icons';
import type { UploadProps } from 'antd';
import { useParams } from 'react-router-dom';
import { FAMILIES, VARIANTS } from '../lib/palette';
import { drawCrop, rebalanceByDay, renderPreview, type Cell, type CropParams } from '../lib/pixelize';
import { fetchArtworkFromUrl, loadImage } from '../lib/wikimedia';
import { api, type ArtworkStatus } from '../services/api';

const { Title, Text } = Typography;

function isoWeekNow(): { year: number; week: number } {
  const d = new Date();
  const date = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  const dayNum = (date.getUTCDay() + 6) % 7;
  date.setUTCDate(date.getUTCDate() - dayNum + 3);
  const ft = new Date(Date.UTC(date.getUTCFullYear(), 0, 4));
  const fdn = (ft.getUTCDay() + 6) % 7;
  ft.setUTCDate(ft.getUTCDate() - fdn + 3);
  const week = 1 + Math.round((date.getTime() - ft.getTime()) / (7 * 86400000));
  return { year: date.getUTCFullYear(), week };
}

export const ArtworkBuilder: React.FC = () => {
  const { id: editId } = useParams<{ id: string }>();
  const isEdit = !!editId;
  const [img, setImg] = useState<HTMLImageElement | null>(null);
  const [crop, setCrop] = useState<CropParams>({ zoom: 1, offsetX: 0, offsetY: 0 });
  const [cols, setCols] = useState(12);
  const [rows, setRows] = useState(16);
  const [cells, setCells] = useState<Cell[]>([]);
  const [dayByFamily, setDayByFamily] = useState<Record<string, number>>(
    Object.fromEntries(FAMILIES.map(f => [f.key, f.day])),
  );
  const [publishing, setPublishing] = useState(false);
  const [importing, setImporting] = useState(false);
  const [wikiUrl, setWikiUrl] = useState('');
  const [loadingEdit, setLoadingEdit] = useState(false);
  const [form] = Form.useForm();

  const gridRef = useRef<HTMLCanvasElement>(document.createElement('canvas'));
  const previewRef = useRef<HTMLCanvasElement>(null);

  const iso = useMemo(isoWeekNow, []);

  // ── Edit mode: load the existing artwork once ────────────────────────────
  useEffect(() => {
    if (!editId) return;
    let cancelled = false;
    setLoadingEdit(true);
    api.getArtwork(editId).then(a => {
      if (cancelled) return;
      setCols(a.cols); setRows(a.rows);
      setCells((a.cells as unknown as Cell[]) ?? []);
      const dayMap: Record<string, number> = {};
      for (const f of a.families ?? []) dayMap[f.key] = f.day;
      if (Object.keys(dayMap).length) setDayByFamily(dayMap);
      form.setFieldsValue({
        titleFr: a.titleFr, titleEn: a.titleEn, artist: a.artist, year: a.year,
        descriptionFr: a.descriptionFr, descriptionEn: a.descriptionEn,
        sourceLicense: a.sourceLicense, isoYear: a.isoYear, isoWeek: a.isoWeek, status: a.status,
      });
    }).catch(() => message.error('Impossible de charger l\'œuvre.'))
      .finally(() => { if (!cancelled) setLoadingEdit(false); });
    return () => { cancelled = true; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [editId]);

  // Re-render the preview when cells change without an image (edit mode).
  useEffect(() => {
    if (img) return;
    if (cells.length === 0 || !previewRef.current) return;
    renderPreview(previewRef.current, cells, cols, rows);
  }, [cells, cols, rows, img]);

  // Recompute cells + preview whenever the image, crop, grid or day mapping
  // changes. Cells are rebalanced so each family fills a quota ∝ its assigned
  // day (day-1 = few cells, day-7 = many).
  useEffect(() => {
    if (!img) return;
    drawCrop(img, gridRef.current, cols, rows, crop);
    const next = rebalanceByDay(gridRef.current, cols, rows, dayByFamily);
    setCells(next);
    if (previewRef.current) renderPreview(previewRef.current, next, cols, rows);
  }, [img, crop, cols, rows, dayByFamily]);

  const onFile: UploadProps['beforeUpload'] = file => {
    const url = URL.createObjectURL(file);
    const image = new Image();
    image.onload = () => setImg(image);
    image.src = url;
    return false; // prevent auto-upload
  };

  async function importFromWiki() {
    if (!wikiUrl.trim()) return;
    setImporting(true);
    try {
      const meta = await fetchArtworkFromUrl(wikiUrl);
      const image = await loadImage(meta.imageUrl);
      setImg(image);
      form.setFieldsValue({
        titleFr: meta.titleFr ?? form.getFieldValue('titleFr'),
        titleEn: meta.titleEn ?? form.getFieldValue('titleEn'),
        artist: meta.artist ?? form.getFieldValue('artist'),
        year: meta.year ?? form.getFieldValue('year'),
        descriptionFr: meta.descriptionFr ?? form.getFieldValue('descriptionFr'),
        descriptionEn: meta.descriptionEn ?? form.getFieldValue('descriptionEn'),
        sourceLicense: meta.sourceLicense,
      });
      message.success('Œuvre pré-remplie depuis Wikipédia/Wikimedia.');
    } catch (e: any) {
      message.error(e?.message ?? 'Import impossible.');
    } finally {
      setImporting(false);
    }
  }

  const familiesUsed = useMemo(() => {
    const s = new Set(cells.map(c => c.family));
    return FAMILIES.filter(f => s.has(f.key)).length;
  }, [cells]);

  const countByFamily = useMemo(() => {
    const m: Record<string, number> = {};
    for (const c of cells) m[c.family] = (m[c.family] ?? 0) + 1;
    return m;
  }, [cells]);

  async function publish() {
    let meta: any;
    try {
      meta = await form.validateFields();
    } catch {
      return;
    }
    if (cells.length === 0) { message.error('Importe d\'abord une image.'); return; }
    const days = Object.values(dayByFamily).sort((a, b) => a - b);
    if (days.join() !== '1,2,3,4,5,6,7') { message.error('Chaque jour (1→7) doit être attribué à une famille distincte.'); return; }

    const id = editId ?? `w${meta.isoYear}-${String(meta.isoWeek).padStart(2, '0')}`;
    setPublishing(true);
    try {
      await api.createArtwork({
        id,
        titleFr: meta.titleFr,
        titleEn: meta.titleEn,
        artist: meta.artist,
        year: meta.year,
        descriptionFr: meta.descriptionFr,
        descriptionEn: meta.descriptionEn,
        sourceLicense: meta.sourceLicense,
        cols, rows,
        status: meta.status as ArtworkStatus,
        isoYear: meta.isoYear,
        isoWeek: meta.isoWeek,
        cells,
        families: FAMILIES.map(f => ({ key: f.key, day: dayByFamily[f.key], nameFr: f.nameFr, nameEn: f.nameEn })),
        variants: VARIANTS.map(v => ({ key: v.key, familyKey: v.familyKey, nameFr: v.nameFr, nameEn: v.nameEn, hex: v.hex })),
      });
      message.success(`Œuvre ${id} enregistrée (${meta.status}).`);
    } catch (e: any) {
      message.error(e?.response?.data?.error ?? 'Échec de l\'enregistrement.');
    } finally {
      setPublishing(false);
    }
  }

  return (
    <div style={{ padding: 24 }}>
      <Title level={3}>{isEdit ? `Modifier · ${editId}` : 'Nouvelle œuvre'}</Title>
      <Text type="secondary">Image du domaine public uniquement — la source/licence est obligatoire.</Text>
      {isEdit && !img && (
        <Alert
          style={{ marginTop: 12 }}
          type="info"
          showIcon
          message="Mode édition"
          description="Les cellules existantes sont chargées. Re-importe une image pour re-pixelliser ; sinon, seuls les métadonnées et la planification seront mis à jour."
        />
      )}
      {loadingEdit && <Alert style={{ marginTop: 12 }} type="info" message="Chargement de l'œuvre…" />}

      <Row gutter={24} style={{ marginTop: 16 }}>
        {/* ── Left: image + crop + pixelisation ── */}
        <Col xs={24} lg={12}>
          <Card title="1 · Image & recadrage 3:4" size="small">
            <Space.Compact style={{ width: '100%', marginBottom: 12 }}>
              <Input
                placeholder="Lien Wikipédia ou Wikimedia Commons"
                value={wikiUrl}
                onChange={e => setWikiUrl(e.target.value)}
                onPressEnter={importFromWiki}
                allowClear
              />
              <Button type="primary" loading={importing} disabled={!wikiUrl.trim()} onClick={importFromWiki}>
                Importer
              </Button>
            </Space.Compact>
            <Text type="secondary" style={{ display: 'block', marginBottom: 12, fontSize: 12 }}>
              Pré-remplit le titre, l'artiste, l'année, la description et la licence depuis l'article ou le fichier.
            </Text>
            <Upload.Dragger beforeUpload={onFile} showUploadList={false} accept="image/*" style={{ marginBottom: 16 }}>
              <p className="ant-upload-drag-icon"><InboxOutlined /></p>
              <p className="ant-upload-text">…ou glisse une image ici</p>
            </Upload.Dragger>

            {img && (
              <>
                <Text strong>Zoom</Text>
                <Slider min={1} max={3} step={0.05} value={crop.zoom}
                  onChange={v => setCrop({ ...crop, zoom: v })} />
                <Text strong>Décalage horizontal</Text>
                <Slider min={-1} max={1} step={0.02} value={crop.offsetX}
                  onChange={v => setCrop({ ...crop, offsetX: v })} />
                <Text strong>Décalage vertical</Text>
                <Slider min={-1} max={1} step={0.02} value={crop.offsetY}
                  onChange={v => setCrop({ ...crop, offsetY: v })} />
              </>
            )}
          </Card>

          <Card title="2 · Pixelisation" size="small" style={{ marginTop: 16 }}>
            <Space>
              <span>Colonnes</span>
              <InputNumber min={6} max={24} value={cols} onChange={v => setCols(v ?? 12)} />
              <span>Lignes</span>
              <InputNumber min={8} max={32} value={rows} onChange={v => setRows(v ?? 16)} />
            </Space>
            <div style={{ marginTop: 8 }}>
              <Tag>{cols}×{rows} = {cols * rows} cellules</Tag>
              <Tag color={familiesUsed === 7 ? 'green' : 'orange'}>{familiesUsed}/7 familles présentes</Tag>
            </div>
            <Text type="secondary" style={{ display: 'block', marginTop: 8 }}>
              Chaque cellule est mappée vers le pigment de musée le plus proche (palette fixe de 21 teintes / 7 familles).
            </Text>
          </Card>
        </Col>

        {/* ── Right: live preview + day mapping ── */}
        <Col xs={24} lg={12}>
          <Card title="Aperçu (vue plate)" size="small">
            <div style={{ textAlign: 'center', background: '#faf7f0', padding: 12, borderRadius: 8 }}>
              {img
                ? <canvas ref={previewRef} style={{ maxWidth: '100%', borderRadius: 6, boxShadow: '0 2px 12px rgba(0,0,0,.12)' }} />
                : <Text type="secondary">Importe une image pour voir l'aperçu.</Text>}
            </div>
          </Card>

          <Card title="3 · Famille → jour (lundi=1 … dimanche=7)" size="small" style={{ marginTop: 16 }}>
            <Text type="secondary" style={{ display: 'block', marginBottom: 8 }}>
              Le nombre de cellules par famille est proportionnel au jour : J1 = peu de pixels, J7 = beaucoup. Plus la semaine avance, plus l'œuvre se remplit.
            </Text>
            <Row gutter={[8, 8]}>
              {FAMILIES.map(f => (
                <Col span={12} key={f.key}>
                  <Space>
                    <Tag>{f.nameFr}</Tag>
                    <Select size="small" style={{ width: 70 }} value={dayByFamily[f.key]}
                      onChange={d => setDayByFamily({ ...dayByFamily, [f.key]: d })}
                      options={[1, 2, 3, 4, 5, 6, 7].map(d => ({ value: d, label: `J${d}` }))} />
                    <Tag color="blue">{countByFamily[f.key] ?? 0} px</Tag>
                  </Space>
                </Col>
              ))}
            </Row>
          </Card>
        </Col>
      </Row>

      <Divider />

      <Card title="4 · Métadonnées & planification" size="small">
        <Form form={form} layout="vertical" initialValues={{ isoYear: iso.year, isoWeek: iso.week, status: 'planned' }}>
          <Row gutter={16}>
            <Col span={12}><Form.Item name="titleFr" label="Titre (FR)" rules={[{ required: true }]}><Input /></Form.Item></Col>
            <Col span={12}><Form.Item name="titleEn" label="Title (EN)"><Input /></Form.Item></Col>
            <Col span={12}><Form.Item name="artist" label="Artiste" rules={[{ required: true }]}><Input /></Form.Item></Col>
            <Col span={12}><Form.Item name="year" label="Année"><InputNumber style={{ width: '100%' }} /></Form.Item></Col>
            <Col span={12}><Form.Item name="descriptionFr" label="Description (FR)"><Input.TextArea rows={2} /></Form.Item></Col>
            <Col span={12}><Form.Item name="descriptionEn" label="Description (EN)"><Input.TextArea rows={2} /></Form.Item></Col>
            <Col span={24}>
              <Form.Item name="sourceLicense" label="Source / licence (domaine public — ex. Wikimedia Commons)"
                rules={[{ required: true }]}><Input placeholder="Domaine public — Wikimedia Commons" /></Form.Item>
            </Col>
            <Col span={8}><Form.Item name="isoYear" label="Année ISO" rules={[{ required: true }]}><InputNumber style={{ width: '100%' }} /></Form.Item></Col>
            <Col span={8}><Form.Item name="isoWeek" label="Semaine ISO" rules={[{ required: true }]}><InputNumber min={1} max={53} style={{ width: '100%' }} /></Form.Item></Col>
            <Col span={8}>
              <Form.Item name="status" label="Statut">
                <Select options={[
                  { value: 'draft', label: 'Brouillon' },
                  { value: 'planned', label: 'Planifiée' },
                  { value: 'active', label: 'Active (cette semaine)' },
                ]} />
              </Form.Item>
            </Col>
          </Row>
          <Button type="primary" icon={<UploadOutlined />} loading={publishing}
            disabled={!img && cells.length === 0} onClick={publish}>
            {isEdit ? 'Enregistrer les modifications' : 'Enregistrer l\'œuvre'}
          </Button>
        </Form>
      </Card>
    </div>
  );
};
