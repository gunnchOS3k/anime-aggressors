using System;
using UnityEngine;

namespace AnimeAggressors.Data
{
    /// <summary>
    /// Roster card data. Only characters with Playable=true have fully proven
    /// combat; the rest are selectable proxies until their kits are built.
    /// </summary>
    [Serializable]
    public class CharacterDefinition
    {
        public string Id;
        public string DisplayName;
        public string Element;
        public string Archetype;
        public string StyleDescription;
        public Color PrimaryColor;
        public Color SecondaryColor;
        public Color AuraColor;
        public bool Playable;

        public string StatusLabel => Playable ? "PLAYABLE" : "PROXY — NOT FULLY PLAYABLE YET";
    }
}
