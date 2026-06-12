import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Card, Statistic, Row, Col, Typography, Spin, Alert, Tag } from 'antd';
import { TeamOutlined, CameraOutlined, CalendarOutlined, AppstoreOutlined } from '@ant-design/icons';
import { api } from '../services/api';

const { Title } = Typography;

export const Dashboard: React.FC = () => {
  const { data: stats, isLoading, error } =
    useQuery({ queryKey: ['stats'], queryFn: api.stats, refetchInterval: 30_000 });

  if (error) return <div style={{ padding: 24 }}><Alert type="error" message="Impossible de charger les statistiques (token ou serveur)." /></div>;

  return (
    <div style={{ padding: 24 }}>
      <Title level={3} style={{ marginBottom: 8 }}>Tableau de bord</Title>
      {stats && <Tag color="blue" style={{ marginBottom: 24 }}>Semaine ISO courante : {stats.currentIsoWeek}</Tag>}

      {isLoading ? <Spin /> : stats && (
        <Row gutter={16}>
          <Col span={6}><Card><Statistic title="Ateliers" value={stats.instances} prefix={<TeamOutlined />} /></Card></Col>
          <Col span={6}><Card><Statistic title="Joueurs" value={stats.users} prefix={<TeamOutlined />} /></Card></Col>
          <Col span={6}><Card><Statistic title="Photos aujourd'hui" value={stats.photosToday} prefix={<CameraOutlined />} /></Card></Col>
          <Col span={6}><Card><Statistic title="Semaines planifiées" value={stats.weeksPlanned} prefix={<CalendarOutlined />} /></Card></Col>
        </Row>
      )}

      <Card style={{ marginTop: 24 }}>
        <Typography.Paragraph>
          <AppstoreOutlined /> Crée une œuvre dans <b>Œuvres → Nouvelle œuvre</b> : importe une image du domaine public,
          recadre en 3:4, ajuste la pixelisation, puis planifie la semaine ISO. L'œuvre <b>active</b> de la semaine
          courante est servie à l'app.
        </Typography.Paragraph>
      </Card>
    </div>
  );
};
