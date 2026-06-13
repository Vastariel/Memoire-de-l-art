import React from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Table, Typography, Tag, Popconfirm, Button, Spin, message, Space } from 'antd';
import { DeleteOutlined } from '@ant-design/icons';
import { api, type AdminInstance } from '../services/api';

const { Title, Text } = Typography;

// "il y a 3 j" / "il y a 5 h" / "jamais"
function sinceLabel(iso: string | null): { text: string; stale: boolean } {
  if (!iso) return { text: 'jamais', stale: true };
  const ms = Date.now() - new Date(iso).getTime();
  const days = Math.floor(ms / 86_400_000);
  const hours = Math.floor(ms / 3_600_000);
  if (days >= 1) return { text: `il y a ${days} j`, stale: days >= 7 };
  if (hours >= 1) return { text: `il y a ${hours} h`, stale: false };
  return { text: "à l'instant", stale: false };
}

const MemberList: React.FC<{ id: string }> = ({ id }) => {
  const { data, isLoading } = useQuery({ queryKey: ['members', id], queryFn: () => api.instanceMembers(id) });
  if (isLoading) return <Spin size="small" />;
  if (!data || data.length === 0) return <Text type="secondary">Aucun membre.</Text>;
  return (
    <Table
      size="small"
      rowKey="id"
      pagination={false}
      dataSource={data}
      columns={[
        { title: 'Pseudo', dataIndex: 'pseudo' },
        { title: 'Points (sem.)', dataIndex: 'points', width: 120 },
        {
          title: 'Dernière photo', dataIndex: 'lastPhoto', width: 160,
          render: (v: string | null) => sinceLabel(v).text,
        },
        {
          title: 'Membre depuis', dataIndex: 'joinedAt', width: 160,
          render: (v: string) => new Date(v).toLocaleDateString('fr-FR'),
        },
      ]}
    />
  );
};

export const Instances: React.FC = () => {
  const qc = useQueryClient();
  const { data, isLoading } = useQuery({ queryKey: ['instances'], queryFn: () => api.instances() });

  async function remove(id: string) {
    try {
      await api.deleteInstance(id);
      message.success('Atelier supprimé (membres & contributions retirés).');
      qc.invalidateQueries({ queryKey: ['instances'] });
    } catch { message.error('Échec.'); }
  }

  const columns = [
    { title: 'Nom', dataIndex: 'name', render: (v: string | null) => v || <Text type="secondary">— sans nom —</Text> },
    { title: 'Code', dataIndex: 'code', render: (v: string) => <Tag>{v}</Tag> },
    {
      title: 'Mode', dataIndex: 'mode', width: 120,
      render: (_: string, r: AdminInstance) =>
        r.solo ? <Tag color="default">solo</Tag>
          : r.mode === 'shared' ? <Tag color="blue">partagé</Tag> : <Tag color="purple">séparé</Tag>,
    },
    { title: 'Membres', dataIndex: 'members', width: 90 },
    {
      title: 'Inactivité', dataIndex: 'lastActivity', width: 140,
      render: (v: string | null) => {
        const s = sinceLabel(v);
        return <Tag color={s.stale ? 'red' : 'green'}>{s.text}</Tag>;
      },
    },
    {
      title: '', width: 60,
      render: (_: unknown, r: AdminInstance) => (
        <Popconfirm title="Supprimer cet atelier ?" onConfirm={() => remove(r.id)} okText="Oui" cancelText="Non">
          <Button type="text" danger icon={<DeleteOutlined />} />
        </Popconfirm>
      ),
    },
  ];

  return (
    <div style={{ padding: 24 }}>
      <Space direction="vertical" size={2} style={{ marginBottom: 16 }}>
        <Title level={3} style={{ margin: 0 }}>Ateliers</Title>
        <Text type="secondary">Membres, inactivité (dernière contribution) et suppression. Tri par activité.</Text>
      </Space>
      {isLoading ? <Spin style={{ display: 'block', marginTop: 40 }} /> : (
        <Table
          rowKey="id"
          dataSource={data ?? []}
          columns={columns}
          expandable={{ expandedRowRender: r => <MemberList id={r.id} /> }}
          pagination={{ pageSize: 20 }}
        />
      )}
    </div>
  );
};
