import React, { useState } from 'react';
import { Card, Form, Input, Button, Typography, Alert } from 'antd';
import { LockOutlined } from '@ant-design/icons';
import { setToken } from '../services/api';

const { Title, Text } = Typography;

interface Props { onLogin: () => void }

export const Login: React.FC<Props> = ({ onLogin }) => {
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const onFinish = async ({ token }: { token: string }) => {
    setLoading(true);
    try {
      const res = await fetch('/api/admin/stats', {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) { setToken(token); onLogin(); }
      else setError('Token invalide.');
    } catch { setError('Serveur inaccessible.'); }
    finally { setLoading(false); }
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center',
      justifyContent: 'center', background: '#f5f5f5' }}>
      <Card style={{ width: 380 }}>
        <div style={{ textAlign: 'center', marginBottom: 24 }}>
          <Title level={3} style={{ margin: 0 }}>Mémoire de l'art</Title>
          <Text type="secondary">Panneau d'administration</Text>
        </div>
        {error && <Alert type="error" message={error} style={{ marginBottom: 16 }} />}
        <Form onFinish={onFinish} layout="vertical">
          <Form.Item name="token" label="Token admin" rules={[{ required: true }]}>
            <Input.Password prefix={<LockOutlined />} placeholder="Bearer token" />
          </Form.Item>
          <Button type="primary" htmlType="submit" loading={loading} block>
            Se connecter
          </Button>
        </Form>
      </Card>
    </div>
  );
};
