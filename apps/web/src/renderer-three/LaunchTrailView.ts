import * as THREE from "three";

export class LaunchTrailView {
  readonly group = new THREE.Group();
  private points: THREE.Vector3[] = [];
  private line: THREE.Line;
  private maxPoints = 40;

  constructor() {
    const geo = new THREE.BufferGeometry();
    this.line = new THREE.Line(
      geo,
      new THREE.LineBasicMaterial({ color: 0xffee88, transparent: true, opacity: 0.75 }),
    );
    this.group.add(this.line);
  }

  addPoint(x: number, y: number): void {
    this.points.push(new THREE.Vector3(x, y + 0.8, 0.4));
    if (this.points.length > this.maxPoints) this.points.shift();
    this.line.geometry.setFromPoints(this.points);
  }

  clear(): void {
    this.points = [];
    this.line.geometry.setFromPoints(this.points);
  }

  setVisible(v: boolean): void {
    this.group.visible = v;
  }
}
