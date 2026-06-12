import React from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Card, Table, Tag, Button, Space, Typography, Popconfirm, message } from 'antd';
import { PlusOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { api, type AdminArtwork, type ArtworkStatus } from '../services/api';

const { Title } = Typography;

const STATUS_COLOR: Record<ArtworkStatus, string> = {
  draft: 'default', planned: 'blue', active: 'green', revealed: 'purple',
};
const STATUS_LABEL: Record<ArtworkStatus, string> = {
  draft: 'Brouillon', planned: 'Planifiée', active: 'Active', revealed: 'Révélée',
};

export const ArtworksList: React.FC = () => {
  const qc = useQueryClient();
  const navigate = useNavigate();
  const { data, isLoading } = useQuery({ queryKey: ['artworks'], queryFn: api.artworks });

  async function setStatus(id: string, status: ArtworkStatus) {
    try {
      await api.setStatus(id, status);
      message.success(`Statut → ${STATUS_LABEL[status]}`);
      qc.invalidateQueries({ queryKey: ['artworks'] });
    } catch { message.error('Échec.'); }
  }

  async function remove(id: string) {
    try {
      await api.deleteArtwork(id);
      message.success('Œuvre supprimée.');
      qc.invalidateQueries({ queryKey: ['artworks'] });
    } catch { message.error('Échec.'); }
  }

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id', render: (v: string) => <Tag>{v}</Tag> },
    { title: 'Titre', dataIndex: 'title_fr', key: 'title_fr', render: (v: string | null) => v ?? '—' },
    { title: 'Artiste', dataIndex: 'artist', key: 'artist', render: (v: string | null) => v ?? '—' },
    {
      title: 'Semaine ISO', key: 'iso',
      render: (_: unknown, r: AdminArtwork) => r.iso_year ? `${r.iso_year}-S${r.iso_week}` : '—',
    },
    {
      title: 'Statut', dataIndex: 'status', key: 'status',
      render: (s: ArtworkStatus) => <Tag color={STATUS_COLOR[s]}>{STATUS_LABEL[s]}</Tag>,
    },
    {
      title: 'Actions', key: 'actions',
      render: (_: unknown, r: AdminArtwork) => (
        <Space>
          {r.status !== 'planned' && <Button size="small" onClick={() => setStatus(r.id, 'planned')}>Planifier</Button>}
          {r.status !== 'active' && <Button size="small" type="primary" ghost onClick={() => setStatus(r.id, 'active')}>Activer</Button>}
          {r.status !== 'revealed' && <Button size="small" onClick={() => setStatus(r.id, 'revealed')}>Révéler</Button>}
          <Popconfirm title="Supprimer cette œuvre ?" onConfirm={() => remove(r.id)} okText="Oui" cancelText="Non">
            <Button size="small" danger>Supprimer</Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  return (
    <div style={{ padding: 24 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <Title level={3} style={{ margin: 0 }}>Œuvres</Title>
        <Button type="primary" icon={<PlusOutlined />} onClick={() => navigate('/artworks/new')}>Nouvelle œuvre</Button>
      </div>
      <Card>
        <Table rowKey="id" loading={isLoading} dataSource={data ?? []} columns={columns} pagination={false} size="small" />
      </Card>
    </div>
  );
};
