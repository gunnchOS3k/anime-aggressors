import React, { lazy, Suspense } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Home from './pages/Home';

// Lazy load the 3D game
const Play = lazy(() => import('./pages/Play'));

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route 
          path="/play" 
          element={
            <Suspense fallback={<div className="loading">Loading 3D Arena...</div>}>
              <Play />
            </Suspense>
          } 
        />
      </Routes>
    </Router>
  );
}

export default App;
