using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace AnimeAggressors.Data
{
    public static class StageDatabase
    {
        public static readonly List<StageDefinition> All = new List<StageDefinition>
        {
            new StageDefinition
            {
                Id = "training_grid", DisplayName = "Training Grid",
                Description = "A clean flat training platform. No hazards. The proving ground.",
                Platforms = new List<PlatformSpec>
                {
                    new PlatformSpec(new Vector3(0, -0.5f, 0), new Vector3(22f, 1f, 4f), new Color(0.16f, 0.20f, 0.28f)),
                },
                SpawnP1 = new Vector3(-3f, 1f, 0),
                SpawnP2 = new Vector3(3f, 1f, 0),
                CameraPosition = new Vector3(0, 4f, -12f),
                CameraEuler = new Vector3(10f, 0, 0),
                BackgroundColor = new Color(0.06f, 0.08f, 0.12f),
                ThemeColor = new Color(0.35f, 0.85f, 0.95f),
                Playable = true,
            },
            new StageDefinition
            {
                Id = "prototype_arena", DisplayName = "Prototype Arena",
                Description = "Main platform with two floating side ledges. Aerial routes open up.",
                Platforms = new List<PlatformSpec>
                {
                    new PlatformSpec(new Vector3(0, -0.5f, 0), new Vector3(16f, 1f, 4f), new Color(0.15f, 0.16f, 0.30f)),
                    new PlatformSpec(new Vector3(-6.5f, 2.4f, 0), new Vector3(4.5f, 0.4f, 3f), new Color(0.26f, 0.24f, 0.48f)),
                    new PlatformSpec(new Vector3(6.5f, 2.4f, 0), new Vector3(4.5f, 0.4f, 3f), new Color(0.26f, 0.24f, 0.48f)),
                },
                SpawnP1 = new Vector3(-4f, 1f, 0),
                SpawnP2 = new Vector3(4f, 1f, 0),
                CameraPosition = new Vector3(0, 4.5f, -13f),
                CameraEuler = new Vector3(10f, 0, 0),
                BackgroundColor = new Color(0.04f, 0.05f, 0.16f),
                ThemeColor = new Color(0.55f, 0.45f, 1.00f),
                Playable = false,
            },
            new StageDefinition
            {
                Id = "skyline_rooftop", DisplayName = "Skyline Rooftop",
                Description = "Two rooftops over a neon gap. Watch the drop between buildings.",
                Platforms = new List<PlatformSpec>
                {
                    new PlatformSpec(new Vector3(-6f, -0.5f, 0), new Vector3(9f, 1f, 4f), new Color(0.24f, 0.14f, 0.22f)),
                    new PlatformSpec(new Vector3(6f, -0.5f, 0), new Vector3(9f, 1f, 4f), new Color(0.24f, 0.14f, 0.22f)),
                    new PlatformSpec(new Vector3(-6f, -3.5f, 0), new Vector3(6f, 5f, 3.5f), new Color(0.14f, 0.09f, 0.15f)),
                    new PlatformSpec(new Vector3(6f, -3.5f, 0), new Vector3(6f, 5f, 3.5f), new Color(0.14f, 0.09f, 0.15f)),
                },
                SpawnP1 = new Vector3(-5f, 1f, 0),
                SpawnP2 = new Vector3(5f, 1f, 0),
                CameraPosition = new Vector3(0, 4.5f, -14f),
                CameraEuler = new Vector3(8f, 0, 0),
                BackgroundColor = new Color(0.13f, 0.05f, 0.14f),
                ThemeColor = new Color(1.00f, 0.45f, 0.60f),
                Playable = false,
            },
        };

        public static StageDefinition Get(string id) =>
            All.FirstOrDefault(s => s.Id == id) ?? All[0];
    }
}
