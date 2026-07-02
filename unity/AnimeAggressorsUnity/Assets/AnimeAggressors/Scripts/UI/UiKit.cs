using System;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace AnimeAggressors.UI
{
    /// <summary>
    /// Code-built uGUI helpers so every screen shares one visual language:
    /// dark panels, bold headers, accent-colored buttons. PROXY styling —
    /// readable and game-like, not final art.
    /// </summary>
    public static class UiKit
    {
        public static readonly Color Ink = new Color(0.93f, 0.95f, 1.00f);
        public static readonly Color InkDim = new Color(0.62f, 0.66f, 0.78f);
        public static readonly Color Backdrop = new Color(0.045f, 0.055f, 0.095f);
        public static readonly Color Panel = new Color(0.10f, 0.12f, 0.19f, 0.96f);
        public static readonly Color PanelHi = new Color(0.15f, 0.18f, 0.28f, 0.98f);
        public static readonly Color Accent = new Color(1.00f, 0.45f, 0.15f);

        static Font _font;
        public static Font Font
        {
            get
            {
                if (_font == null)
                    _font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
                return _font;
            }
        }

        public static Canvas CreateCanvas(string name)
        {
            var go = new GameObject(name);
            var canvas = go.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 10;
            var scaler = go.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1600, 900);
            scaler.matchWidthOrHeight = 0.5f;
            go.AddComponent<GraphicRaycaster>();
            EnsureEventSystem();
            return canvas;
        }

        public static void EnsureEventSystem()
        {
            if (UnityEngine.Object.FindFirstObjectByType<EventSystem>() != null) return;
            var go = new GameObject("EventSystem");
            go.AddComponent<EventSystem>();
            go.AddComponent<StandaloneInputModule>();
        }

        static RectTransform Rect(GameObject go, Transform parent, Vector2 anchoredPos, Vector2 size)
        {
            var rt = go.AddComponent<RectTransform>();
            rt.SetParent(parent, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.anchoredPosition = anchoredPos;
            rt.sizeDelta = size;
            return rt;
        }

        public static Image Fullscreen(Transform parent, Color color)
        {
            var go = new GameObject("Backdrop");
            var rt = go.AddComponent<RectTransform>();
            rt.SetParent(parent, false);
            rt.anchorMin = Vector2.zero;
            rt.anchorMax = Vector2.one;
            rt.offsetMin = rt.offsetMax = Vector2.zero;
            var img = go.AddComponent<Image>();
            img.color = color;
            img.raycastTarget = false;
            return img;
        }

        public static Image PanelBox(Transform parent, string name, Vector2 pos, Vector2 size, Color color)
        {
            var go = new GameObject(name);
            Rect(go, parent, pos, size);
            var img = go.AddComponent<Image>();
            img.color = color;
            // Decorative by default; cards that become Buttons re-enable this.
            img.raycastTarget = false;
            return img;
        }

        public static Text Label(Transform parent, string text, int size, Vector2 pos, Vector2 area, Color color,
            TextAnchor align = TextAnchor.MiddleCenter, bool bold = false)
        {
            var go = new GameObject("Label");
            Rect(go, parent, pos, area);
            var t = go.AddComponent<Text>();
            t.font = Font;
            t.text = text;
            t.fontSize = size;
            t.color = color;
            t.alignment = align;
            t.fontStyle = bold ? FontStyle.Bold : FontStyle.Normal;
            t.horizontalOverflow = HorizontalWrapMode.Wrap;
            t.verticalOverflow = VerticalWrapMode.Overflow;
            t.raycastTarget = false;
            return t;
        }

        public static Button MenuButton(Transform parent, string label, Vector2 pos, Vector2 size, Action onClick,
            Color? accent = null, int fontSize = 26)
        {
            var color = accent ?? Accent;
            var go = new GameObject($"Button_{label}");
            Rect(go, parent, pos, size);
            var img = go.AddComponent<Image>();
            img.color = PanelHi;
            var btn = go.AddComponent<Button>();
            var colors = btn.colors;
            colors.normalColor = Color.white;
            colors.highlightedColor = new Color(1.25f, 1.25f, 1.35f);
            colors.pressedColor = new Color(0.8f, 0.8f, 0.8f);
            colors.selectedColor = new Color(1.15f, 1.15f, 1.25f);
            btn.colors = colors;
            btn.onClick.AddListener(() => onClick?.Invoke());

            // Accent edge on the left of the button.
            var edge = new GameObject("Edge");
            var ert = edge.AddComponent<RectTransform>();
            ert.SetParent(go.transform, false);
            ert.anchorMin = new Vector2(0, 0);
            ert.anchorMax = new Vector2(0, 1);
            ert.offsetMin = Vector2.zero;
            ert.offsetMax = new Vector2(6, 0);
            var eimg = edge.AddComponent<Image>();
            eimg.color = color;
            eimg.raycastTarget = false;

            Label(go.transform, label, fontSize, Vector2.zero, size - new Vector2(24, 6), Ink, TextAnchor.MiddleCenter, true);
            return btn;
        }

        public static Text Header(Transform parent, string title, string subtitle, Color accent)
        {
            PanelBox(parent, "HeaderBar", new Vector2(0, 395), new Vector2(1700, 6), accent);
            var h = Label(parent, title, 46, new Vector2(0, 350), new Vector2(1400, 70), Ink, TextAnchor.MiddleCenter, true);
            if (!string.IsNullOrEmpty(subtitle))
                Label(parent, subtitle, 20, new Vector2(0, 302), new Vector2(1400, 34), InkDim);
            return h;
        }
    }
}
