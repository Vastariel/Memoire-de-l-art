import React, { useState, useCallback, useEffect, useMemo } from 'react';
import {
  Form, Input, InputNumber, Button, Typography, Card, Steps,
  Alert, Divider, Spin, message, Popconfirm, Slider, Row, Col, Statistic,
} from 'antd';
import { InboxOutlined, CheckCircleOutlined, ArrowLeftOutlined } from '@ant-design/icons';
import { useQuery } from '@tanstack/react-query';
import { api } from '../services/api';
import type { SegmentResult } from '../services/api';
import { MosaicPreview } from '../components/MosaicPreview';

const { Title, Text } = Typography;
const { TextArea } = Input;


interface ImgSize { w: number; h: number }

export const ArtworkUpload: React.FC = () => {
  const [step,        setStep]        = useState(0);
  const [segResult,   setSegResult]   = useState<SegmentResult | null>(null);
  const [loading,     setLoading]     = useState(false);
  const [dragOver,    setDragOver]    = useState(false);
  const [file,        setFile]        = useState<File | null>(null);
  const [imgSize,     setImgSize]     = useState<ImgSize | null>(null);
  const [targetCells, setTargetCells] = useState(252); // ~14×18
  const [numZones,    setNumZones]    = useState(16);  // k-means clusters
  const [meta,        setMeta]        = useState<{
    title?: string; artist?: string; year?: number; description?: string;
  }>({});
  const [published, setPublished] = useState<string | null>(null);

  const { data: artworks } = useQuery({ queryKey: ['artworks'], queryFn: api.artworks });

  // Auto-read image dimensions when a file is loaded
  useEffect(() => {
    if (!file) { setImgSize(null); return; }
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      setImgSize({ w: img.naturalWidth, h: img.naturalHeight });
      URL.revokeObjectURL(url);
    };
    img.onerror = () => URL.revokeObjectURL(url);
    img.src = url;
  }, [file]);

  // Compute block size from image dimensions + target cells slider
  const blockSize = useMemo(() => {
    if (!imgSize) return 16;
    const bs = Math.round(Math.sqrt((imgSize.w * imgSize.h) / targetCells));
    return Math.max(4, bs);
  }, [imgSize, targetCells]);

  const gridCols = useMemo(() =>
    imgSize ? Math.min(Math.max(Math.round(imgSize.w / blockSize), 4), 32) : 0,
  [imgSize, blockSize]);

  const gridRows = useMemo(() =>
    imgSize ? Math.min(Math.max(Math.round(imgSize.h / blockSize), 4), 40) : 0,
  [imgSize, blockSize]);

  const totalCells = gridCols * gridRows;

  // ── Step 0: file drop ─────────────────────────────────────────

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault(); setDragOver(false);
    const f = e.dataTransfer.files[0];
    if (f && f.type.startsWith('image/')) setFile(f);
    else message.error('Veuillez déposer une image (PNG, JPG, WebP).');
  }, []);

  const handleFileInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0];
    if (f) setFile(f);
  };

  const handleSegment = async () => {
    if (!file) return;
    setLoading(true);
    try {
      const result = await api.segment(file, blockSize, numZones);
      setSegResult(result);
      setStep(1);
    } catch (err) {
      message.error('Erreur lors de la segmentation.');
      console.error(err);
    } finally { setLoading(false); }
  };

  // ── Step 1: validate + metadata ───────────────────────────────

  const handleValidate = (values: typeof meta) => {
    setMeta(values);
    setStep(2);
  };

  // ── Step 2: publish ───────────────────────────────────────────

  const handlePublish = async () => {
    if (!segResult) return;
    setLoading(true);
    try {
      const result = await api.publish({
        cols: segResult.cols, rows: segResult.rows,
        cells: segResult.cells, zones: segResult.zones,
        ...meta,
      });
      setPublished(result.id);
      setStep(3);
      message.success(`Œuvre publiée — ${result.zonesCreated} zones créées.`);
    } catch (err) {
      message.error('Erreur lors de la publication.');
      console.error(err);
    } finally { setLoading(false); }
  };

  const reset = () => {
    setStep(0); setFile(null); setImgSize(null);
    setSegResult(null); setMeta({}); setPublished(null);
    setTargetCells(252);
  };

  // ─────────────────────────────────────────────────────────────

  return (
    <div style={{ maxWidth: 800, margin: '0 auto', padding: 24 }}>
      <Title level={3}>Œuvre du mois</Title>

      <Steps
        current={step}
        style={{ marginBottom: 32 }}
        items={[
          { title: 'Import',       description: 'Importer l\'image' },
          { title: 'Métadonnées',  description: 'Titre + artiste' },
          { title: 'Publication',  description: 'Vérifier + publier' },
          { title: 'Terminé',      description: 'En ligne' },
        ]}
      />

      {/* ── Step 0: upload + auto grid ── */}
      {step === 0 && (
        <Card>
          {/* Drop zone */}
          <div
            onDragOver={e => { e.preventDefault(); setDragOver(true); }}
            onDragLeave={() => setDragOver(false)}
            onDrop={handleDrop}
            onClick={() => document.getElementById('fileInput')?.click()}
            style={{
              border: `2px dashed ${dragOver ? '#1677ff' : '#d9d9d9'}`,
              borderRadius: 8, padding: 32, textAlign: 'center',
              cursor: 'pointer', background: dragOver ? '#f0f7ff' : '#fafafa',
              transition: 'all .2s',
            }}
          >
            <InboxOutlined style={{ fontSize: 40, color: dragOver ? '#1677ff' : '#999' }} />
            <p style={{ margin: '8px 0 4px', fontWeight: 500 }}>
              {file ? file.name : 'Glisse l\'image ici ou clique pour importer'}
            </p>
            <p style={{ color: '#999', fontSize: 13 }}>PNG, JPG, WebP — max 20 Mo</p>
            {file && imgSize && (
              <p style={{ color: '#52c41a', marginTop: 8 }}>
                ✓ {file.name} — {imgSize.w} × {imgSize.h} px
              </p>
            )}
            <input id="fileInput" type="file" accept="image/*"
              style={{ display: 'none' }} onChange={handleFileInput} />
          </div>

          {/* Auto grid config — only shown after image is loaded */}
          {file && imgSize && (
            <>
              <Divider>Finesse de la mosaïque</Divider>

              <Row gutter={24} style={{ marginBottom: 8 }}>
                <Col span={6}>
                  <Statistic title="Colonnes" value={gridCols} />
                </Col>
                <Col span={6}>
                  <Statistic title="Lignes" value={gridRows} />
                </Col>
                <Col span={6}>
                  <Statistic title="Cellules" value={totalCells} />
                </Col>
                <Col span={6}>
                  <Statistic title="Couleurs" value={numZones} suffix="zones" />
                </Col>
              </Row>

              {/* Grid fineness */}
              <div style={{ padding: '0 8px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between',
                  fontSize: 12, color: '#999', marginBottom: 4 }}>
                  <span>Mosaïque grossière</span>
                  <span>Mosaïque fine</span>
                </div>
                <Slider
                  min={60}
                  max={600}
                  value={targetCells}
                  onChange={setTargetCells}
                  tooltip={{ formatter: v => `~${v} cellules` }}
                  marks={{
                    60:  'XS',
                    150: 'S',
                    252: 'M',
                    400: 'L',
                    600: 'XL',
                  }}
                />
                <p style={{ color: '#999', fontSize: 12, marginTop: 8 }}>
                  Taille du bloc : {blockSize} px — une cellule = 1 carré dans la mosaïque.
                </p>
              </div>

              {/* Number of colour zones */}
              <div style={{ padding: '0 8px', marginTop: 20 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between',
                  fontSize: 12, color: '#999', marginBottom: 4 }}>
                  <span>Peu de couleurs</span>
                  <span>Palette riche</span>
                </div>
                <Slider
                  min={8}
                  max={24}
                  value={numZones}
                  onChange={setNumZones}
                  tooltip={{ formatter: v => `${v} couleurs` }}
                  marks={{ 8: '8', 12: '12', 16: '16', 20: '20', 24: '24' }}
                />
                <p style={{ color: '#999', fontSize: 12, marginTop: 8 }}>
                  Nombre de zones colorées dans la mosaïque (k-means). 16 est un bon équilibre.
                </p>
              </div>

              <div style={{ marginTop: 24 }}>
                <Button
                  type="primary"
                  loading={loading}
                  onClick={handleSegment}
                  size="large"
                >
                  Segmenter l'image
                </Button>
              </div>
            </>
          )}

          {!file && (
            <p style={{ color: '#aaa', fontSize: 13, marginTop: 16, textAlign: 'center' }}>
              Importe une image pour configurer la mosaïque.
            </p>
          )}
        </Card>
      )}

      {/* ── Step 1: preview + metadata ── */}
      {step === 1 && segResult && (
        <Card title={`Aperçu — ${segResult.cols}×${segResult.rows} blocs, ${segResult.zones.length} zone(s)`}>
          <Spin spinning={loading}>
            <MosaicPreview result={segResult} />
          </Spin>

          <Divider />

          <Form layout="vertical" onFinish={handleValidate}
            initialValues={{ year: new Date().getFullYear() }}>
            <Form.Item name="title" label="Titre de l'œuvre"
              extra="Affiché au reveal de fin de mois.">
              <Input placeholder="Le Semeur" />
            </Form.Item>
            <Form.Item name="artist" label="Artiste">
              <Input placeholder="Vincent van Gogh" />
            </Form.Item>
            <Form.Item name="year" label="Année">
              <InputNumber min={1000} max={2100} style={{ width: 120 }} />
            </Form.Item>
            <Form.Item name="description" label="Texte du panneau">
              <TextArea rows={4} placeholder="Huile sur toile, 73 × 92 cm…" />
            </Form.Item>

            <div style={{ display: 'flex', gap: 12 }}>
              <Button icon={<ArrowLeftOutlined />} onClick={() => setStep(0)}>Retour</Button>
              <Button type="primary" htmlType="submit">Continuer</Button>
            </div>
          </Form>
        </Card>
      )}

      {/* ── Step 2: publish ── */}
      {step === 2 && segResult && (
        <Card>
          <div style={{ display: 'flex', gap: 24, alignItems: 'flex-start' }}>
            <div style={{ flex: 1 }}>
              <MosaicPreview result={segResult} maxPx={280} />
            </div>
            <div style={{ flex: 1 }}>
              <p><b>Grille :</b> {segResult.cols} × {segResult.rows}</p>
              <p><b>Zones :</b> {segResult.zones.length}</p>
              {meta.title       && <p><b>Titre :</b> {meta.title}</p>}
              {meta.artist      && <p><b>Artiste :</b> {meta.artist}</p>}
              {meta.year        && <p><b>Année :</b> {meta.year}</p>}
              {meta.description && <p><b>Description :</b> {meta.description}</p>}
              {artworks && artworks.length > 0 && (
                <Alert
                  type="warning"
                  message={`${artworks.length} œuvre(s) déjà publiée(s). La nouvelle remplacera le mois courant.`}
                  style={{ marginTop: 12 }}
                />
              )}
            </div>
          </div>
          <Divider />
          <div style={{ display: 'flex', gap: 12 }}>
            <Button icon={<ArrowLeftOutlined />} onClick={() => setStep(1)}>Retour</Button>
            <Popconfirm
              title="Publier l'œuvre ?"
              description="Elle sera immédiatement visible par toutes les instances."
              onConfirm={handlePublish}
              okText="Publier"
              cancelText="Annuler"
            >
              <Button type="primary" loading={loading}>Publier l'œuvre</Button>
            </Popconfirm>
          </div>
        </Card>
      )}

      {/* ── Step 3: done ── */}
      {step === 3 && published && (
        <Card>
          <div style={{ textAlign: 'center', padding: 48 }}>
            <CheckCircleOutlined style={{ fontSize: 56, color: '#52c41a', marginBottom: 16 }} />
            <Title level={4}>Œuvre publiée !</Title>
            <Text type="secondary">
              ID : <code>{published}</code><br />
              Elle est maintenant visible par toutes les instances actives.
            </Text>
            <div style={{ marginTop: 32 }}>
              <Button type="primary" onClick={reset}>Publier une autre œuvre</Button>
            </div>
          </div>
        </Card>
      )}
    </div>
  );
};
