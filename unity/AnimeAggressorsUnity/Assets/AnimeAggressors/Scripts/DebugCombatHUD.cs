using UnityEngine;

namespace AnimeAggressors
{
    public class DebugCombatHUD : MonoBehaviour
    {
        bool _showHitboxes;
        bool _showHurtboxes = true;
        GUIStyle _box;
        FighterController _p1;
        FighterController _dummy;

        void Start()
        {
            _p1 = FighterController.Player;
            _dummy = FighterController.Dummy;
            _box = new GUIStyle(GUI.skin.box) { alignment = TextAnchor.UpperLeft, fontSize = 14 };
        }

        void Update()
        {
            if (Input.GetKeyDown(KeyCode.F2)) _showHitboxes = !_showHitboxes;
            if (Input.GetKeyDown(KeyCode.F6)) _showHurtboxes = !_showHurtboxes;
            if (Input.GetKeyDown(KeyCode.R) && _p1 != null && _dummy != null)
            {
                _p1.ResetFighter(new Vector3(-3f, 1f, 0));
                _dummy.ResetFighter(new Vector3(3f, 1f, 0));
            }
            if (_p1 != null) _p1.SetDebugBoxes(_showHitboxes, false);
            if (_dummy != null) _dummy.SetDebugBoxes(false, _showHurtboxes);
        }

        void OnGUI()
        {
            _p1 = FighterController.Player ?? _p1;
            _dummy = FighterController.Dummy ?? _dummy;
            var lines = "=== COMBAT PROOF HUD ===\n";
            lines += "A/D move  W jump  J jab  H heavy  K special\n";
            lines += "L shield  U grab  I dodge  K+L aura  J@full burst  R reset\n";
            lines += "F2 hitboxes  F6 hurtboxes\n\n";
            if (_p1 != null)
            {
                var mr = _p1.MoveRunner;
                lines += $"P1 state: {_p1.StateMachine.Current}\n";
                lines += $"move: {(mr.Move?.move_id ?? "—")} frame:{mr.TotalFrame} phase:{mr.Phase}\n";
                lines += $"dmg:{_p1.DamagePercent:F0}% vel:{_p1.Velocity}\n";
                lines += $"shield:{_p1.Shield.Health:F0} aura:{_p1.Aura.Meter:F0}\n";
                lines += $"hitbox active:{mr.IsActivePhase} last:{_p1.LastHitResult} combo:{_p1.ComboCount}\n";
            }
            if (_dummy != null)
                lines += $"\nDummy dmg:{_dummy.DamagePercent:F0}% state:{_dummy.StateMachine.Current} last:{_dummy.LastHitResult}\n";
            GUI.Box(new Rect(10, 10, 420, 280), lines, _box);
        }
    }
}
