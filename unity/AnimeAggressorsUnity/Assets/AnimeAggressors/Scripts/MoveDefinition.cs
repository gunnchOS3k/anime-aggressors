using System;
using System.Collections.Generic;
using UnityEngine;

namespace AnimeAggressors
{
    [Serializable]
    public class MoveDefinition
    {
        public string move_id;
        public string display_name;
        public int startup_frames;
        public int active_frames;
        public int recovery_frames;
        public float damage;
        public float angle;
        public float base_knockback;
        public float knockback_growth;
        public Vector2 hitbox_size = new Vector2(1.2f, 1.4f);
        public Vector2 hitbox_offset = new Vector2(0.8f, 0.2f);
        public float shield_damage = 3f;
        public int hitstun_frames = 12;
        public int hitstop_frames = 3;
        public bool is_grab;
        public bool is_throw;
        public bool is_aura_burst;
    }

    [Serializable]
    public class MoveDatabase
    {
        public List<MoveDefinition> moves = new List<MoveDefinition>();
    }

    public static class MoveLibrary
    {
        public const float SimFps = 60f;

        public static MoveDatabase LoadFromResources()
        {
            var text = Resources.Load<TextAsset>("default_moves");
            if (text == null)
            {
                Debug.LogWarning("default_moves.json not in Resources — using embedded defaults.");
                return BuildDefaults();
            }
            return JsonUtility.FromJson<MoveDatabase>(WrapJson(text.text));
        }

        static string WrapJson(string raw)
        {
            if (raw.TrimStart().StartsWith("{")) return raw;
            return "{\"moves\":" + raw + "}";
        }

        public static MoveDatabase BuildDefaults()
        {
            return new MoveDatabase
            {
                moves = new List<MoveDefinition>
                {
                    Def("jab", "Jab", 4, 3, 10, 3f, 45f, 4f, 1.1f),
                    Def("heavy", "Heavy", 8, 4, 18, 9f, 50f, 12f, 1.2f, 1.6f, 1.6f),
                    Def("neutral_special", "Neutral Special", 10, 5, 22, 11f, 55f, 14f, 1.15f),
                    Grab("grab", "Grab"),
                    Throw("throw", "Throw"),
                    Def("aura_burst", "Aura Burst", 12, 8, 28, 18f, 45f, 22f, 1.1f, 2f, 2f, true),
                }
            };
        }

        static MoveDefinition Def(string id, string name, int su, int ac, int rec, float dmg, float ang, float kb, float grow,
            float w = 1.2f, float h = 1.4f, bool aura = false)
        {
            return new MoveDefinition
            {
                move_id = id,
                display_name = name,
                startup_frames = su,
                active_frames = ac,
                recovery_frames = rec,
                damage = dmg,
                angle = ang,
                base_knockback = kb,
                knockback_growth = grow,
                hitbox_size = new Vector2(w, h),
                hitbox_offset = new Vector2(0.9f, 0.25f),
                shield_damage = dmg * 0.9f,
                hitstun_frames = Mathf.Max(8, (int)(kb * 1.2f)),
                hitstop_frames = 3,
                is_aura_burst = aura,
            };
        }

        static MoveDefinition Grab(string id, string name) => new MoveDefinition
        {
            move_id = id, display_name = name, startup_frames = 7, active_frames = 2, recovery_frames = 20,
            damage = 0, is_grab = true, hitbox_size = new Vector2(1.4f, 1.5f), hitbox_offset = new Vector2(1f, 0.2f),
        };

        static MoveDefinition Throw(string id, string name) => new MoveDefinition
        {
            move_id = id, display_name = name, startup_frames = 4, active_frames = 3, recovery_frames = 12,
            damage = 7f, base_knockback = 16f, knockback_growth = 1.1f, angle = 45f, is_throw = true,
            hitbox_size = new Vector2(1.2f, 1.4f), hitbox_offset = new Vector2(1f, 0.2f),
            hitstun_frames = 18, hitstop_frames = 4,
        };
    }
}
