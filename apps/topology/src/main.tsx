import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import ClawOps from './ClawOps';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ClawOps />
  </StrictMode>,
);
