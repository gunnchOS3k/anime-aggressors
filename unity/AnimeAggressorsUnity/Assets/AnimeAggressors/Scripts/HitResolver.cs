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

            if (defender.Shield.IsBlocking)
            {
                defender.Shield.ApplyShieldHit(move.shield_damage);
                resultTag = "SHIELD";
                defender.EnterShieldStun();
                return;
            }

            var kb = (move.base_knockback + defender.DamagePercent * move.knockback_growth) * (100f / defender.Weight);
            var rad = move.angle * Mathf.Deg2Rad;
            var dir = attacker.Facing;
            var launch = new Vector2(Mathf.Cos(rad) * kb * dir, Mathf.Sin(rad) * kb);
            defender.ApplyHit(move.damage, launch, move.hitstun_frames / MoveLibrary.SimFps, move.hitstop_frames / MoveLibrary.SimFps);
            attacker.ApplyHitstop(move.hitstop_frames / MoveLibrary.SimFps * 0.5f);
            resultTag = "HIT";
        }
    }
}
