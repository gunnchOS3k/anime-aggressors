using UnityEngine;

namespace AnimeAggressors
{
    public class ShieldController
    {
        public float MaxHealth = 100f;
        public float Health = 100f;
        public bool IsBlocking { get; private set; }
        public bool Broken { get; private set; }

        const float DrainPerSecond = 8f;
        const float RegenPerSecond = 15f;
        const float BrokenRecoverThreshold = 40f;

        readonly FighterController _owner;

        public ShieldController(FighterController owner)
        {
            _owner = owner;
        }

        public void SetBlocking(bool on)
        {
            if (Broken) { IsBlocking = false; return; }

            var st = _owner.StateMachine.Current;
            if (on && (st == FighterState.Hitstun || st == FighterState.Launched ||
                       st == FighterState.ShieldStun || st == FighterState.ShieldBreak || _owner.IsGrabbed))
                return;

            var was = IsBlocking;
            IsBlocking = on && _owner.IsGrounded;
            if (IsBlocking)
                _owner.StateMachine.Enter(FighterState.ShieldHold);
            else if (was && _owner.StateMachine.Current == FighterState.ShieldHold)
                _owner.StateMachine.Enter(FighterState.Idle);
        }

        public void ApplyShieldHit(float dmg)
        {
            Health -= dmg;
            if (Health <= 0f)
            {
                Health = 0f;
                Broken = true;
                IsBlocking = false;
                _owner.StateMachine.Enter(FighterState.ShieldBreak);
            }
            else
            {
                _owner.EnterShieldStun();
            }
        }

        public void Tick(float dt)
        {
            if (IsBlocking)
            {
                Health = Mathf.Max(0f, Health - DrainPerSecond * dt);
                if (Health <= 0f)
                {
                    Broken = true;
                    IsBlocking = false;
                    _owner.StateMachine.Enter(FighterState.ShieldBreak);
                }
            }
            else if (Health < MaxHealth)
            {
                Health = Mathf.Min(MaxHealth, Health + RegenPerSecond * dt);
                if (Broken && Health >= BrokenRecoverThreshold)
                    Broken = false;
            }
        }

        public void ResetShield()
        {
            Health = MaxHealth;
            Broken = false;
            IsBlocking = false;
        }
    }
}
