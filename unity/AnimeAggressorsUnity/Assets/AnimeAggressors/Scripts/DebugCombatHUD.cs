using System.Text;
using UnityEngine;

namespace AnimeAggressors
{
    /// <summary>
    /// Mandatory combat-proof HUD (§12). F1 toggles the HUD, F2 hitbox
    /// overlays, F6 hurtbox overlays, R resets fighters, Esc pauses.
    /// </summary>
    public class DebugCombatHUD : MonoBehaviour
    {
        public static readonly Vector3 P1Spawn = new Vector3(-3f, 1f, 0);
        public static readonly Vector3 DummySpawn = new Vector3(3f, 1f, 0);

        bool _showHud = true;
        bool _showHitboxes = true;
        bool _showHurtboxes = true;
        bool _paused;
        GUIStyle _box;
        FighterController _p1;
        FighterController _dummy;

        static readonly KeyCode[] TrackedKeys =
        {
            KeyCode.A, KeyCode.D, KeyCode.W, KeyCode.S, KeyCode.J, KeyCode.H,
            KeyCode.K, KeyCode.L, KeyCode.U, KeyCode.I, KeyCode.B, KeyCode.LeftShift,
        };

        void Update()
        {
            _p1 = FighterController.Player ?? _p1;
            _dummy = FighterController.Dummy ?? _dummy;

            if (Input.GetKeyDown(KeyCode.F1)) _showHud = !_showHud;
            if (Input.GetKeyDown(KeyCode.F2)) _showHitboxes = !_showHitboxes;
            if (Input.GetKeyDown(KeyCode.F6)) _showHurtboxes = !_showHurtboxes;

            if (Input.GetKeyDown(KeyCode.Escape))
            {
                _paused = !_paused;
                Time.timeScale = _paused ? 0f : 1f;
            }

            if (Input.GetKeyDown(KeyCode.R) && _p1 != null && _dummy != null)
            {
                _p1.ResetFighter(P1Spawn);
                _dummy.ResetFighter(DummySpawn);
                Debug.Log("[Combat] RESET fighters to spawn positions");
            }

            if (_p1 != null) _p1.SetOverlay(_showHitboxes, _showHurtboxes);
            if (_dummy != null) _dummy.SetOverlay(_showHitboxes, _showHurtboxes);
        }

        void OnGUI()
        {
            if (!_showHud) return;
            if (_box == null)
                _box = new GUIStyle(GUI.skin.box) { alignment = TextAnchor.UpperLeft, fontSize = 13 };

            var sb = new StringBuilder();
            sb.AppendLine("=== COMBAT PROOF HUD (PROXY — NOT FINAL ART) ===");
            sb.AppendLine("A/D move  Shift run  W jump/double-jump  S fast-fall");
            sb.AppendLine("J jab  H heavy  K special  L shield  U grab  I dodge");
            sb.AppendLine("K+L aura charge  J@full-aura burst  B dummy shield");
            sb.AppendLine("R reset  F1 HUD  F2 hitboxes  F6 hurtboxes  Esc pause");
            sb.AppendLine();

            if (_paused) sb.AppendLine("*** PAUSED (Esc to resume) ***");

            if (_p1 != null)
            {
                var mr = _p1.MoveRunner;
                sb.AppendLine($"P1 state: {_p1.StateMachine.Current}");
                sb.AppendLine($"  move: {(mr.Move != null ? mr.Move.move_id : "—")}  frame: {mr.TotalFrame}  phase: {(string.IsNullOrEmpty(mr.Phase) ? "—" : mr.Phase)}");
                sb.AppendLine($"  hitbox active: {mr.IsActivePhase}");
                sb.AppendLine($"  damage: {_p1.DamagePercent:F0}%  velocity: ({_p1.Velocity.x:F1}, {_p1.Velocity.y:F1})");
                sb.AppendLine($"  grounded: {_p1.IsGrounded}");
                sb.AppendLine($"  shield: {_p1.Shield.Health:F0}/{_p1.Shield.MaxHealth:F0}{(_p1.Shield.Broken ? " BROKEN" : "")}  aura: {_p1.Aura.Meter:F0}/100{(_p1.Aura.IsReady ? " READY" : "")}");
                sb.AppendLine($"  grabbing: {_p1.Grab.HasTarget}  grabbed: {_p1.IsGrabbed}");
                sb.AppendLine($"  last hit: {_p1.LastHitResult}  combo: {_p1.ComboCount}");
            }

            if (_dummy != null)
            {
                sb.AppendLine();
                sb.AppendLine($"Dummy state: {_dummy.StateMachine.Current}");
                sb.AppendLine($"  damage: {_dummy.DamagePercent:F0}%  grounded: {_dummy.IsGrounded}");
                sb.AppendLine($"  shield: {_dummy.Shield.Health:F0}{(_dummy.Shield.IsBlocking ? " (blocking)" : "")}{(_dummy.Shield.Broken ? " BROKEN" : "")}");
                sb.AppendLine($"  grabbed: {_dummy.IsGrabbed}  last hit: {_dummy.LastHitResult}");
            }

            sb.AppendLine();
            sb.Append("pressed:");
            foreach (var k in TrackedKeys)
                if (Input.GetKey(k)) sb.Append(' ').Append(k);
            sb.AppendLine();
            sb.Append($"overlays — hitbox: {(_showHitboxes ? "ON" : "off")}  hurtbox: {(_showHurtboxes ? "ON" : "off")}");

            GUI.Box(new Rect(10, 10, 460, 400), sb.ToString(), _box);
        }
    }
}
