using System;
using UnityEngine;

namespace AnimeAggressors
{
    public class FighterStateMachine
    {
        public FighterState Current { get; private set; } = FighterState.Idle;
        public float StateTime { get; private set; }
        public event Action<FighterState> StateChanged;

        public void Enter(FighterState next)
        {
            if (Current == next) return;
            Current = next;
            StateTime = 0f;
            StateChanged?.Invoke(Current);
        }

        public void Tick(float dt)
        {
            StateTime += dt;
        }

        public bool LocksMovement => Current switch
        {
            FighterState.AttackStartup or FighterState.AttackActive or FighterState.AttackRecovery => true,
            FighterState.ShieldHold or FighterState.ShieldStun or FighterState.ShieldBreak => true,
            FighterState.GrabStartup or FighterState.GrabActive or FighterState.GrabWhiff or FighterState.GrabHold => true,
            FighterState.ThrowRelease => true,
            FighterState.AuraCharge or FighterState.AuraReady or FighterState.AuraBurstStartup or FighterState.AuraBurstActive or FighterState.AuraBurstRecovery => true,
            FighterState.Hitstun or FighterState.Launched => true,
            _ => false,
        };

        public bool LocksActions => LocksMovement || Current == FighterState.Dodge;
    }
}
