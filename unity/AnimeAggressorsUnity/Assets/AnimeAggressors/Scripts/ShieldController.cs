using UnityEngine;

namespace AnimeAggressors
{
    public class ShieldController
    {
        public float MaxHealth = 100f;
        public float Health = 100f;
        public bool IsBlocking { get; private set; }
        public bool Broken { get; private set; }

        readonly FighterController _owner;

        public ShieldController(FighterController owner)
        {
            _owner = owner;
        }

        public void SetBlocking(bool on)
        {
            if (Broken) { IsBlocking = false; return; }
            IsBlocking = on && _owner.IsGrounded;
            if (IsBlocking)
                _owner.StateMachine.Enter(FighterState.ShieldHold);
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
                _owner.StateMachine.Enter(FighterState.ShieldStun);
            }
        }

        public void Tick(float dt)
        {
            if (IsBlocking)
                Health = Mathf.Max(0f, Health - 12f * dt);
        }

        public void ResetShield()
        {
            Health = MaxHealth;
            Broken = false;
            IsBlocking = false;
        }
    }
}
