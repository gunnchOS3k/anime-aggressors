using UnityEngine;

namespace AnimeAggressors
{
    public static class HitResolver
    {
        public static void Resolve(FighterController attacker, FighterController defender, MoveDefinition move, out string resultTag)
        {
            resultTag = "MISS";
            if (attacker == null || defender == null || move == null) return;

            if (move.is_grab)
            {
                attacker.TryGrabConnect(defender, out resultTag);
                return;
            }

            var contactPoint = defender.transform.position + Vector3.up * 1.2f;

            if (defender.Shield.IsBlocking)
            {
                defender.Shield.ApplyShieldHit(move.shield_damage);
                resultTag = "SHIELD";
                CombatVisuals.SpawnHitSpark(contactPoint, new Color(0.4f, 0.9f, 1f, 0.8f), 1.1f);
                Debug.Log($"[Combat] BLOCK {attacker.name} {move.move_id} -> {defender.name} shield ({defender.Shield.Health:F0} left)");
                return;
            }

            var kb = (move.base_knockback + defender.DamagePercent * move.knockback_growth) * (100f / defender.Weight);
            var rad = move.angle * Mathf.Deg2Rad;
            var dir = attacker.Facing;
            var launch = new Vector2(Mathf.Cos(rad) * kb * dir, Mathf.Sin(rad) * kb);
            defender.ApplyHit(move.damage, launch, move.hitstun_frames / MoveLibrary.SimFps, move.hitstop_frames / MoveLibrary.SimFps);
            attacker.ApplyHitstop(move.hitstop_frames / MoveLibrary.SimFps * 0.5f);
            CombatVisuals.SpawnHitSpark(contactPoint, new Color(1f, 0.85f, 0.2f, 0.9f), move.is_aura_burst ? 2.5f : 1.5f);
            Debug.Log($"[Combat] HIT {attacker.name} {move.move_id} -> {defender.name} dmg:{move.damage} total:{defender.DamagePercent:F0}% kb:{kb:F1}");
            resultTag = "HIT";
        }
    }
}
