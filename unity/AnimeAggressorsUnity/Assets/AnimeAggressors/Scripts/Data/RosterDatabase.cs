using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace AnimeAggressors.Data
{
    /// <summary>
    /// The original seven-fighter roster. Ember Vale is the first proof
    /// fighter; everyone else shares her combat systems for now and is
    /// clearly labeled as a proxy on the select screen.
    /// </summary>
    public static class RosterDatabase
    {
        public static readonly List<CharacterDefinition> All = new List<CharacterDefinition>
        {
            new CharacterDefinition
            {
                Id = "ember_vale", DisplayName = "Ember Vale",
                Element = "Fire / Aura", Archetype = "All-rounder / Rushdown",
                StyleDescription = "Bold and direct. Readable jab, strong heavy, fire burst aura.",
                PrimaryColor = new Color(0.90f, 0.35f, 0.20f),
                SecondaryColor = new Color(1.00f, 0.75f, 0.30f),
                AuraColor = new Color(1.00f, 0.55f, 0.10f),
                Playable = true,
            },
            new CharacterDefinition
            {
                Id = "rook_ironside", DisplayName = "Rook Ironside",
                Element = "Steel / Earth", Archetype = "Heavy Bruiser",
                StyleDescription = "Slow and unstoppable. High weight, huge knockback, armored swings.",
                PrimaryColor = new Color(0.55f, 0.57f, 0.62f),
                SecondaryColor = new Color(0.80f, 0.60f, 0.30f),
                AuraColor = new Color(0.75f, 0.72f, 0.55f),
                Playable = false,
            },
            new CharacterDefinition
            {
                Id = "juno_spark", DisplayName = "Juno Spark",
                Element = "Electricity", Archetype = "Fast Rushdown",
                StyleDescription = "Blinding speed. Quick jabs, electric stuns, featherweight.",
                PrimaryColor = new Color(0.95f, 0.85f, 0.20f),
                SecondaryColor = new Color(0.30f, 0.75f, 1.00f),
                AuraColor = new Color(1.00f, 0.95f, 0.35f),
                Playable = false,
            },
            new CharacterDefinition
            {
                Id = "kaia_windrow", DisplayName = "Kaia Windrow",
                Element = "Wind", Archetype = "Aerial Mobility",
                StyleDescription = "Owns the sky. Strong air drift, aerial specials, deep recovery.",
                PrimaryColor = new Color(0.35f, 0.85f, 0.70f),
                SecondaryColor = new Color(0.90f, 0.98f, 0.95f),
                AuraColor = new Color(0.55f, 0.95f, 0.80f),
                Playable = false,
            },
            new CharacterDefinition
            {
                Id = "nix_calder", DisplayName = "Nix Calder",
                Element = "Ice", Archetype = "Control / Spacing",
                StyleDescription = "Cold precision. Slows, counters, slippery footwork.",
                PrimaryColor = new Color(0.55f, 0.80f, 0.95f),
                SecondaryColor = new Color(0.85f, 0.95f, 1.00f),
                AuraColor = new Color(0.65f, 0.90f, 1.00f),
                Playable = false,
            },
            new CharacterDefinition
            {
                Id = "orion_vell", DisplayName = "Orion Vell",
                Element = "Cosmic / Star Energy", Archetype = "Sword / Midrange",
                StyleDescription = "Clean arcs at range. Starlit blades and a cosmic burst.",
                PrimaryColor = new Color(0.45f, 0.35f, 0.85f),
                SecondaryColor = new Color(0.95f, 0.90f, 0.60f),
                AuraColor = new Color(0.70f, 0.60f, 1.00f),
                Playable = false,
            },
            new CharacterDefinition
            {
                Id = "vesper_nyx", DisplayName = "Vesper Nyx",
                Element = "Shadow", Archetype = "Trickster",
                StyleDescription = "Never where you think. Feints, dodges, shadow steps.",
                PrimaryColor = new Color(0.25f, 0.18f, 0.35f),
                SecondaryColor = new Color(0.75f, 0.30f, 0.85f),
                AuraColor = new Color(0.55f, 0.20f, 0.75f),
                Playable = false,
            },
        };

        public static CharacterDefinition Get(string id) =>
            All.FirstOrDefault(c => c.Id == id) ?? All[0];
    }
}
