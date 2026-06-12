import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  Card, Row, Col, Slider, InputNumber, Form, Input, Select, Button, Upload, Typography,
  Divider, Space, Tag, message,
} from 'antd';
import { InboxOutlined, UploadOutlined } from '@ant-design/icons';
import type { UploadProps } from 'antd';
import { FAMILIES, VARIANTS } from '../lib/palette';
import { drawCrop, cellsFromCanvas, renderPreview, type Cell, type CropParams } from '../lib/pixelize';
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
  const [img, setImg] = useState<HTMLImageElement | null>(null);
  const [crop, setCrop] = useState<CropParams>({ zoom: 1, offsetX: 0, offsetY: 0 });
  const [cols, setCols] = useState(12);
  const [rows, setRows] = useState(16);
  const [cells, setCells] = useState<Cell[]>([]);
  const [dayByFamily, setDayByFamily] = useState<Record<string, number>>(
    Object.fromEntries(FAMILIES.map(f => [f.key, f.day])),
  );
  const [publishing, setPublishing] = useState(false);
  const [form] = Form.useForm();

  const gridRef = useRef<HTMLCanvasElement>(document.createElement('canvas'));
  const previewRef = useRef<HTMLCanvasElement>(null);

  const iso = useMemo(isoWeekNow, []);

  // Recompute cells + preview whenever the image or params change.
  useEffect(() => {
    if (!img) return;
    drawCrop(img, gridRef.current, cols, rows, crop);
    const next = cellsFromCanvas(gridRef.current, cols, rows);
    setCells(next);
    if (previewRef.current) renderPreview(previewRef.current, next, cols, rows);
  }, [img, crop, cols, rows]);

  const onFile: UploadProps['beforeUpload'] = file => {
    const url = URL.createObjectURL(file);
    const image = new Image();
    image.onload = () => setImg(image);
    image.src = url;
    return false; // prevent auto-upload
  };

  const familiesUsed = useMemo(() => {
    const s = new Set(cells.map(c => c.family));
    return FAMILIES.filter(f => s.has(f.key)).length;
  }, [cells]);

  async function publish() {
    let meta: any;
    try {
      meta = await form.validateFields();
    } catch {
      return;
    }
    if (!img || cells.length === 0) { message.error('Importe d\'abord une image.'); return; }
    const days = Object.values(dayByFamily).sort((a, b) => a - b);
    if (days.join() !== '1,2,3,4,5,6,7') { message.error('Chaque jour (1→7) doit être attribué à une famille distincte.'); return; }

    const id = `w${meta.isoYear}-${String(meta.isoWeek).padStart(2, '0')}`;
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
      <Title level={3}>Nouvelle œuvre</Title>
      <Text type="secondary">Image du domaine public uniquement — la source/licence est obligatoire.</Text>

      <Row gutter={24} style={{ marginTop: 16 }}>
        {/* ── Left: image + crop + pixelisation ── */}
        <Col xs={24} lg={12}>
          <Card title="1 · Image & recadrage 3:4" size="small">
            <Upload.Dragger beforeUpload={onFile} showUploadList={false} accept="image/*" style={{ marginBottom: 16 }}>
              <p className="ant-upload-drag-icon"><InboxOutlined /></p>
              <p className="ant-upload-text">Glisse une image ici ou clique</p>
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
            <Row gutter={[8, 8]}>
              {FAMILIES.map(f => (
                <Col span={12} key={f.key}>
                  <Space>
                    <Tag>{f.nameFr}</Tag>
                    <Select size="small" style={{ width: 70 }} value={dayByFamily[f.key]}
                      onChange={d => setDayByFamily({ ...dayByFamily, [f.key]: d })}
                      options={[1, 2, 3, 4, 5, 6, 7].map(d => ({ value: d, label: `J${d}` }))} />
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
          <Button type="primary" icon={<UploadOutlined />} loading={publishing} disabled={!img} onClick={publish}>
            Enregistrer l'œuvre
          </Button>
        </Form>
      </Card>
    </div>
  );
};
