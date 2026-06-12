import React from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Card, Row, Col, Image, Typography, Popconfirm, Button, Tag, Empty, Spin, message } from 'antd';
import { DeleteOutlined } from '@ant-design/icons';
import { api } from '../services/api';

const { Title, Text } = Typography;

export const Gallery: React.FC = () => {
  const qc = useQueryClient();
  const { data, isLoading } = useQuery({ queryKey: ['gallery'], queryFn: () => api.gallery() });

  async function remove(id: string) {
    try {
      await api.deletePhoto(id);
      message.success('Photo supprimée (les cellules reviennent à la couleur plate).');
      qc.invalidateQueries({ queryKey: ['gallery'] });
    } catch { message.error('Échec.'); }
  }

  return (
    <div style={{ padding: 24 }}>
      <Title level={3}>Galerie & modération</Title>
      <Text type="secondary">Photos envoyées (toutes instances). Supprimer une photo retire sa contribution.</Text>

      {isLoading ? <Spin style={{ display: 'block', marginTop: 40 }} /> :
        !data || data.length === 0 ? <Empty style={{ marginTop: 40 }} description="Aucune photo pour l'instant." /> : (
          <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
            {data.map(p => (
              <Col xs={12} sm={8} md={6} lg={4} key={p.id}>
                <Card
                  size="small"
                  cover={<Image src={p.url} height={140} style={{ objectFit: 'cover' }} />}
                  actions={[
                    <Popconfirm key="del" title="Supprimer ?" onConfirm={() => remove(p.id)} okText="Oui" cancelText="Non">
                      <DeleteOutlined style={{ color: '#cf1322' }} />
                    </Popconfirm>,
                  ]}
                >
                  <Card.Meta
                    title={<Text style={{ fontSize: 13 }}>{p.pseudo ?? 'Anonyme'}</Text>}
                    description={
                      <div>
                        <Tag>{p.target_variant_key}</Tag>
                        <Text type="secondary" style={{ fontSize: 11 }}>J{p.day_} · {p.taken_on}</Text>
                      </div>
                    }
                  />
                </Card>
              </Col>
            ))}
          </Row>
        )}
    </div>
  );
};
