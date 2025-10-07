import React, { useState, useEffect } from 'react';
import { generateFrames, generateSwipeRightSequence } from '@anime-aggressors/edgeio';
import { detectGestures } from '@anime-aggressors/edgeio';

function App() {
  const [status, setStatus] = useState('Ready');
  const [gestures, setGestures] = useState<string[]>([]);
  const [sensorData, setSensorData] = useState<any[]>([]);

  useEffect(() => {
    setStatus('Loaded');
    
    // Demo: Generate fake sensor data and detect gestures
    const frames = generateSwipeRightSequence();
    setSensorData(frames);
    
    const detectedGestures = detectGestures(frames);
    setGestures(detectedGestures.map(g => g.type));
  }, []);

  return (
    <div style={{ 
      fontFamily: 'system-ui, -apple-system, sans-serif', 
      padding: '20px',
      maxWidth: '800px',
      margin: '0 auto'
    }}>
      <h1>Anime Aggressors — Web</h1>
      <p>Status: {status}</p>
      
      <div style={{ margin: '20px 0' }}>
        <h2>Sensor Data (Demo)</h2>
        <div style={{ 
          background: '#f5f5f5', 
          padding: '10px', 
          borderRadius: '4px',
          fontFamily: 'monospace',
          fontSize: '12px'
        }}>
          {sensorData.map((frame, i) => (
            <div key={i}>
              t:{frame.t} ax:{frame.ax} ay:{frame.ay} az:{frame.az}
            </div>
          ))}
        </div>
      </div>

      <div style={{ margin: '20px 0' }}>
        <h2>Detected Gestures</h2>
        <div style={{ 
          background: '#e8f4fd', 
          padding: '10px', 
          borderRadius: '4px'
        }}>
          {gestures.length > 0 ? (
            gestures.map((gesture, i) => (
              <span key={i} style={{ 
                background: '#007acc', 
                color: 'white', 
                padding: '4px 8px', 
                borderRadius: '4px',
                margin: '2px',
                display: 'inline-block'
              }}>
                {gesture}
              </span>
            ))
          ) : (
            <span>No gestures detected</span>
          )}
        </div>
      </div>

      <div style={{ margin: '20px 0' }}>
        <h2>Web BLE Support</h2>
        <p>
          {navigator.bluetooth ? '✅ Web Bluetooth supported' : '❌ Web Bluetooth not supported'}
        </p>
        <button 
          onClick={() => {
            if (navigator.bluetooth) {
              setStatus('Scanning for devices...');
            } else {
              setStatus('Web Bluetooth not available');
            }
          }}
          style={{
            background: '#007acc',
            color: 'white',
            border: 'none',
            padding: '10px 20px',
            borderRadius: '4px',
            cursor: 'pointer'
          }}
        >
          Scan for Edge-IO Devices
        </button>
      </div>
    </div>
  );
}

export default App;
