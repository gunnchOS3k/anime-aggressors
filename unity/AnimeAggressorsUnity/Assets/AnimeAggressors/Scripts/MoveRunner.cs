using System;
using UnityEngine;

namespace AnimeAggressors
{
    public class MoveRunner
    {
        public bool Active { get; private set; }
        public MoveDefinition Move { get; private set; }
        public string Phase { get; private set; } = "";
        public int TotalFrame { get; private set; }
        public int FrameInPhase { get; private set; }

        public event Action<MoveDefinition> MoveStarted;
        public event Action<string> PhaseChanged;
        public event Action MoveEnded;

        int _phaseFrame;

        public void Start(MoveDefinition move)
        {
            if (move == null) return;
            Move = move;
            Active = true;
            TotalFrame = 0;
            _phaseFrame = 0;
            SetPhase("startup");
            MoveStarted?.Invoke(move);
        }

        public void Cancel()
        {
            if (!Active) return;
            Active = false;
            Move = null;
            Phase = "";
            MoveEnded?.Invoke();
        }

        public void TickFrame()
        {
            if (!Active || Move == null) return;
            TotalFrame++;
            _phaseFrame++;
            switch (Phase)
            {
                case "startup":
                    if (_phaseFrame >= Move.startup_frames) SetPhase("active");
                    break;
                case "active":
                    if (_phaseFrame >= Move.active_frames) SetPhase("recovery");
                    break;
                case "recovery":
                    if (_phaseFrame >= Move.recovery_frames)
                    {
                        Active = false;
                        MoveEnded?.Invoke();
                        Phase = "";
                    }
                    break;
            }
        }

        void SetPhase(string p)
        {
            Phase = p;
            _phaseFrame = 0;
            PhaseChanged?.Invoke(p);
        }

        public bool IsActivePhase => Active && Phase == "active";
    }
}
