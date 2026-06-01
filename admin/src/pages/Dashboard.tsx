import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Card, Statistic, Row, Col, Typography, Progress, Table, Spin, Alert, Tag } from 'antd';
import { TeamOutlined, PictureOutlined, CameraOutlined, CheckCircleOutlined } from '@ant-design/icons';
import { api } from '../services/api';

const { Title } = Typography;

export const Dashboard: React.FC = () => {
  const { data: stats, isLoading: loadingStats, error: statsErr } =
    useQuery({ queryKey: ['stats'], queryFn: api.stats, refetchInterval: 30_000 });

  const { data: instances, isLoading: loadingInst } =
    useQuery({ queryKey: ['instances'], queryFn: api.instances, refetchInterval: 30_000 });

  const now = new Date();
  const monthName = now.toLocaleString('fr-FR', { month: 'long', year: 'numeric' });

  const columns = [
    { title: 'Code', dataIndex: 'code', key: 'code',
      render: (v: string) => <Tag>{v}</Tag> },
    { title: 'Nom', dataIndex: 'name', key: 'name',
      render: (v: string) => v || <span style={{ color: '#999' }}>—</span> },
    { title: 'Joueurs', dataIndex: 'players', key: 'players' },
    { title: 'Photos aujourd\'hui', dataIndex: 'today_count', key: 'today_count' },
    { title: 'Zones remplies', dataIndex: 'filled', key: 'filled' },
  ];

  if (statsErr) return <Alert type="error" message="Impossible de charger les statistiques." />;

  return (
    <div style={{ padding: 24 }}>
      <Title level={3} style={{ marginBottom: 24 }}>
        Tableau de bord — {monthName}
      </Title>

      {loadingStats ? <Spin /> : stats && (
        <Row gutter={16} style={{ marginBottom: 24 }}>
          <Col span={6}>
            <Card>
              <Statistic title="Instances actives" value={stats.instances}
                prefix={<PictureOutlined />} />
            </Card>
          </Col>
          <Col span={6}>
            <Card>
              <Statistic title="Joueurs actifs" value={stats.players}
                prefix={<TeamOutlined />} />
            </Card>
          </Col>
          <Col span={6}>
            <Card>
              <Statistic title="Photos aujourd'hui" value={stats.photosToday}
                prefix={<CameraOutlined />} />
            </Card>
          </Col>
          <Col span={6}>
            <Card>
              <Statistic title="Zones remplies" value={stats.zonesFilled}
                suffix={`/ ${stats.zonesTotal}`}
                prefix={<CheckCircleOutlined />}
              />
              {stats.zonesTotal > 0 && (
                <Progress
                  percent={Math.round(stats.zonesFilled / stats.zonesTotal * 100)}
                  size="small" style={{ marginTop: 8 }}
                />
              )}
            </Card>
          </Col>
        </Row>
      )}

      <Card title="Instances actives">
        <Table
          columns={columns}
          dataSource={instances ?? []}
          rowKey="id"
          loading={loadingInst}
          pagination={false}
          size="small"
        />
      </Card>
    </div>
  );
};
