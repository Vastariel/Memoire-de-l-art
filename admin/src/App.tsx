import React, { useState } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Refine } from '@refinedev/core';
import { RefineThemes, ThemedLayoutV2, ThemedSiderV2, ThemedTitleV2 } from '@refinedev/antd';
import { ConfigProvider, App as AntdApp } from 'antd';
import frFR from 'antd/locale/fr_FR';
import { DashboardOutlined, PictureOutlined, CameraOutlined } from '@ant-design/icons';

import { Dashboard } from './pages/Dashboard';
import { ArtworksList } from './pages/ArtworksList';
import { ArtworkBuilder } from './pages/ArtworkBuilder';
import { Gallery } from './pages/Gallery';
import { Login } from './pages/Login';
import { hasToken } from './services/api';

const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: 1, staleTime: 10_000 } },
});

export const App: React.FC = () => {
  const [authed, setAuthed] = useState(hasToken());
  if (!authed) return <Login onLogin={() => setAuthed(true)} />;

  return (
    <QueryClientProvider client={queryClient}>
      <ConfigProvider theme={RefineThemes.Blue} locale={frFR}>
        <AntdApp>
          <BrowserRouter>
            <Refine
              resources={[
                { name: 'dashboard', list: '/', meta: { label: 'Tableau de bord', icon: <DashboardOutlined /> } },
                { name: 'artworks', list: '/artworks', create: '/artworks/new', meta: { label: 'Œuvres', icon: <PictureOutlined /> } },
                { name: 'gallery', list: '/gallery', meta: { label: 'Galerie', icon: <CameraOutlined /> } },
              ]}
            >
              <ThemedLayoutV2
                Sider={() => <ThemedSiderV2 Title={() => <ThemedTitleV2 collapsed={false} text="Mémoire de l'art" />} />}
              >
                <Routes>
                  <Route path="/" element={<Dashboard />} />
                  <Route path="/artworks" element={<ArtworksList />} />
                  <Route path="/artworks/new" element={<ArtworkBuilder />} />
                  <Route path="/artworks/:id/edit" element={<ArtworkBuilder />} />
                  <Route path="/gallery" element={<Gallery />} />
                  <Route path="*" element={<Navigate to="/" replace />} />
                </Routes>
              </ThemedLayoutV2>
            </Refine>
          </BrowserRouter>
        </AntdApp>
      </ConfigProvider>
    </QueryClientProvider>
  );
};
