using UnityEngine;

namespace AnimeAggressors
{
    public class AuraController
    {
        public float Meter { get; private set; }
        public bool IsReady => Meter >= 100f;
        public bool Charging { get; private set; }

        readonly FighterController _owner;

        public AuraController(FighterController owner) => _owner = owner;

        public void SetCharging(bool on)
        {
            Charging = on;
            if (on)
            {
                _owner.StateMachine.Enter(Meter >= 100f ? FighterState.AuraReady : FighterState.AuraCharge);
            }
        }

        public void TickCharge(float dt)
        {
            if (!Charging) return;
            Meter = Mathf.Min(100f, Meter + 35f * dt);
            if (Meter >= 100f) _owner.StateMachine.Enter(FighterState.AuraReady);
        }

        public bool TryBurst(MoveDefinition burstMove)
        {
            if (Meter < 100f || burstMove == null) return false;
            Meter = 0f;
            Charging = false;
            _owner.StartMove(burstMove);
            return true;
        }

        public void Fill() => Meter = 100f;
        public void Clear() { Meter = 0f; Charging = false; }
    }
}
