import { EventEmitter } from 'events';

export interface GestureEvent {
  type: 'swipeL' | 'swipeR' | 'swipeU' | 'swipeD' | 'thrust' | 'tap' | 'hold';
  confidence: number;
  timestamp: number;
  deviceId: string;
}

export interface EdgeIOConfig {
  autoConnect: boolean;
  scanTimeout: number;
  gestureThreshold: number;
}

export class EdgeIO extends EventEmitter {
  private config: EdgeIOConfig;
  private connectedDevices: Map<string, any> = new Map();
  private isScanning = false;

  constructor(config: Partial<EdgeIOConfig> = {}) {
    super();
    this.config = {
      autoConnect: true,
      scanTimeout: 10000,
      scanTimeout: 0.7,
      ...config
    };
  }

  async connect(): Promise<void> {
    try {
      console.log('🔌 Connecting to Edge-IO devices...');
      
      if (this.config.autoConnect) {
        await this.scanForDevices();
      }
      
      this.emit('connected');
    } catch (error) {
      console.error('❌ Edge-IO connection failed:', error);
      this.emit('error', error);
    }
  }

  async scanForDevices(): Promise<void> {
    if (this.isScanning) return;
    
    this.isScanning = true;
    console.log('🔍 Scanning for Edge-IO devices...');
    
    // Simulate device discovery
    setTimeout(() => {
      this.isScanning = false;
      this.emit('devicesFound', []);
    }, this.config.scanTimeout);
  }

  onGesture(callback: (gesture: GestureEvent) => void): void {
    this.on('gesture', callback);
  }

  async disconnect(): Promise<void> {
    this.connectedDevices.clear();
    this.emit('disconnected');
  }

  // Gesture detection methods
  private detectGesture(data: any): GestureEvent | null {
    // Simulate gesture detection based on IMU data
    const { accel, gyro, timestamp, deviceId } = data;
    
    // Simple gesture detection logic
    if (this.isSwipeGesture(accel)) {
      return {
        type: this.getSwipeDirection(accel),
        confidence: 0.8,
        timestamp,
        deviceId
      };
    }
    
    if (this.isThrustGesture(accel)) {
      return {
        type: 'thrust',
        confidence: 0.9,
        timestamp,
        deviceId
      };
    }
    
    if (this.isTapGesture(accel)) {
      return {
        type: 'tap',
        confidence: 0.7,
        timestamp,
        deviceId
      };
    }
    
    return null;
  }

  private isSwipeGesture(accel: any): boolean {
    const threshold = 2.0;
    return Math.abs(accel.x) > threshold || Math.abs(accel.y) > threshold;
  }

  private getSwipeDirection(accel: any): GestureEvent['type'] {
    if (Math.abs(accel.x) > Math.abs(accel.y)) {
      return accel.x > 0 ? 'swipeR' : 'swipeL';
    } else {
      return accel.y > 0 ? 'swipeU' : 'swipeD';
    }
  }

  private isThrustGesture(accel: any): boolean {
    return accel.z > 3.0; // Strong forward thrust
  }

  private isTapGesture(accel: any): boolean {
    return Math.abs(accel.z) > 1.5 && Math.abs(accel.z) < 2.5;
  }
}
