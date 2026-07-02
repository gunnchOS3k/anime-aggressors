using System;
using System.Collections.Generic;
using UnityEngine;

namespace AnimeAggressors.Data
{
    [Serializable]
    public struct PlatformSpec
    {
        public Vector3 Center;
        public Vector3 Size;
        public Color Color;

        public PlatformSpec(Vector3 center, Vector3 size, Color color)
        {
            Center = center;
            Size = size;
            Color = color;
        }
    }

    /// <summary>
    /// Stage layout data: platforms, spawns, camera framing, and theme.
    /// Stages are built at runtime from primitives (PROXY — NOT FINAL ART).
    /// </summary>
    [Serializable]
    public class StageDefinition
    {
        public string Id;
        public string DisplayName;
        public string Description;
        public List<PlatformSpec> Platforms = new List<PlatformSpec>();
        public Vector3 SpawnP1;
        public Vector3 SpawnP2;
        public Vector3 CameraPosition;
        public Vector3 CameraEuler;
        public Color BackgroundColor;
        public Color ThemeColor;
        public bool Playable;

        public string StatusLabel => Playable ? "PLAYABLE" : "PROXY MAP";
    }
}
