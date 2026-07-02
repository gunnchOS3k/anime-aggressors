using AnimeAggressors.App;
using AnimeAggressors.UI;
using UnityEngine;
using UnityEngine.UI;

namespace AnimeAggressors.Battle
{
    /// <summary>
    /// Versus battle HUD: fighter name plates, live damage %, aura/shield
    /// bars for P1, and the match timer.
    /// </summary>
    public class BattleHudController : MonoBehaviour
    {
        BattleBootstrap _battle;
        Text _p1Damage;
        Text _p2Damage;
        Text _timer;
        Image _auraFill;
        Image _shieldFill;

        public void Init(BattleBootstrap battle)
        {
            _battle = battle;
            var def = GameState.SelectedCharacter;

            var canvas = UiKit.CreateCanvas("BattleHudCanvas");

            // P1 plate (bottom left).
            var p1 = UiKit.PanelBox(canvas.transform, "P1Plate", new Vector2(-540, -390), new Vector2(460, 120), UiKit.Panel);
            UiKit.PanelBox(p1.transform, "Stripe", new Vector2(-218, 0), new Vector2(12, 110), def.PrimaryColor);
            UiKit.Label(p1.transform, def.DisplayName, 24, new Vector2(15, 34), new Vector2(400, 34), UiKit.Ink, TextAnchor.MiddleLeft, true);
            _p1Damage = UiKit.Label(p1.transform, "0%", 34, new Vector2(150, -18), new Vector2(140, 50), UiKit.Ink, TextAnchor.MiddleRight, true);

            UiKit.Label(p1.transform, "AURA", 13, new Vector2(-125, -8), new Vector2(70, 20), UiKit.InkDim, TextAnchor.MiddleLeft);
            var auraBack = UiKit.PanelBox(p1.transform, "AuraBack", new Vector2(0, -8), new Vector2(160, 12), new Color(0.2f, 0.22f, 0.3f));
            _auraFill = UiKit.PanelBox(auraBack.transform, "AuraFill", Vector2.zero, new Vector2(160, 12), def.AuraColor);

            UiKit.Label(p1.transform, "SHIELD", 13, new Vector2(-125, -34), new Vector2(70, 20), UiKit.InkDim, TextAnchor.MiddleLeft);
            var shieldBack = UiKit.PanelBox(p1.transform, "ShieldBack", new Vector2(0, -34), new Vector2(160, 12), new Color(0.2f, 0.22f, 0.3f));
            _shieldFill = UiKit.PanelBox(shieldBack.transform, "ShieldFill", Vector2.zero, new Vector2(160, 12), new Color(0.3f, 0.9f, 1f));

            // P2 plate (bottom right).
            var p2 = UiKit.PanelBox(canvas.transform, "P2Plate", new Vector2(540, -390), new Vector2(460, 120), UiKit.Panel);
            UiKit.PanelBox(p2.transform, "Stripe", new Vector2(218, 0), new Vector2(12, 110), new Color(0.3f, 0.5f, 0.9f));
            UiKit.Label(p2.transform, "CPU DUMMY", 24, new Vector2(-15, 34), new Vector2(400, 34), UiKit.Ink, TextAnchor.MiddleRight, true);
            _p2Damage = UiKit.Label(p2.transform, "0%", 34, new Vector2(-150, -18), new Vector2(140, 50), UiKit.Ink, TextAnchor.MiddleLeft, true);

            // Timer (top center).
            var timerBox = UiKit.PanelBox(canvas.transform, "TimerBox", new Vector2(0, 400), new Vector2(160, 70), UiKit.Panel);
            _timer = UiKit.Label(timerBox.transform, "99", 42, Vector2.zero, new Vector2(150, 60), UiKit.Ink, TextAnchor.MiddleCenter, true);

            UiKit.Label(canvas.transform, $"{GameState.SelectedStage.DisplayName}  •  first to 150% or ring-out loses  •  Esc pause",
                15, new Vector2(0, 355), new Vector2(900, 24), new Color(0.5f, 0.55f, 0.68f));
        }

        void Update()
        {
            if (_battle == null || _battle.P1 == null || _battle.P2 == null) return;

            _p1Damage.text = $"{_battle.P1.DamagePercent:F0}%";
            _p1Damage.color = DamageColor(_battle.P1.DamagePercent);
            _p2Damage.text = $"{_battle.P2.DamagePercent:F0}%";
            _p2Damage.color = DamageColor(_battle.P2.DamagePercent);
            _timer.text = $"{_battle.TimeRemaining:F0}";

            var aura = Mathf.Clamp01(_battle.P1.Aura.Meter / 100f);
            _auraFill.rectTransform.sizeDelta = new Vector2(160f * aura, 12f);
            _auraFill.rectTransform.anchoredPosition = new Vector2(-80f + 80f * aura, 0);

            var shield = Mathf.Clamp01(_battle.P1.Shield.Health / _battle.P1.Shield.MaxHealth);
            _shieldFill.rectTransform.sizeDelta = new Vector2(160f * shield, 12f);
            _shieldFill.rectTransform.anchoredPosition = new Vector2(-80f + 80f * shield, 0);
        }

        static Color DamageColor(float dmg)
        {
            var t = Mathf.Clamp01(dmg / BattleBootstrap.KoDamage);
            return Color.Lerp(UiKit.Ink, new Color(1f, 0.25f, 0.2f), t);
        }
    }
}
