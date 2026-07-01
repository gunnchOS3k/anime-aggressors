using UnityEngine;

namespace AnimeAggressors
{
    public class GrabController
    {
        public FighterController GrabbedTarget { get; private set; }
        public float HoldTime { get; private set; }

        readonly FighterController _owner;

        public GrabController(FighterController owner) => _owner = owner;

        public bool HasTarget => GrabbedTarget != null;

        public void TryConnect(FighterController target, out bool success)
        {
            success = false;
            if (target == null || target == _owner) return;
            var dist = Mathf.Abs(target.transform.position.x - _owner.transform.position.x);
            if (dist > 1.6f) return;
            GrabbedTarget = target;
            target.OnGrabbed(_owner);
            HoldTime = 0f;
            success = true;
            _owner.StateMachine.Enter(FighterState.GrabHold);
        }

        public void Whiff() => _owner.StateMachine.Enter(FighterState.GrabWhiff);

        public void ReleaseThrow()
        {
            if (GrabbedTarget == null) return;
            var t = GrabbedTarget;
            GrabbedTarget = null;
            t.OnThrown(_owner);
            _owner.StateMachine.Enter(FighterState.ThrowRelease);
        }

        public void Tick(float dt)
        {
            if (GrabbedTarget == null) return;
            HoldTime += dt;
            GrabbedTarget.transform.position = _owner.transform.position + Vector3.right * _owner.Facing * 0.8f + Vector3.up * 0.5f;
            if (HoldTime > 2f) ReleaseThrow();
        }

        public void Clear()
        {
            if (GrabbedTarget != null) GrabbedTarget.OnGrabReleased();
            GrabbedTarget = null;
        }
    }
}
