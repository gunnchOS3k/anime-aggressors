# Root `/play` Redirect (Optional)

GitHub Pages **project sites** for this repository are served at:

```text
https://gunnchos3k.github.io/anime-aggressors/
```

The correct direct play link is:

```text
https://gunnchos3k.github.io/anime-aggressors/#/play
```

The URL:

```text
https://gunnchos3k.github.io/play
```

will **404** unless you configure a separate **user/organization site** repository named `gunnchos3k.github.io`. That root site is not controlled by the `anime-aggressors` project repo alone.

## Make `/play` redirect (user-site repo)

1. Create or open the repository: `gunnchos3k/gunnchos3k.github.io`
2. Enable GitHub Pages for that repo (usually from the `main` branch root).
3. Add a file at `play/index.html` with:

```html
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>Anime Aggressors Play Redirect</title>
    <meta http-equiv="refresh" content="0; url=https://gunnchos3k.github.io/anime-aggressors/#/play" />
    <link rel="canonical" href="https://gunnchos3k.github.io/anime-aggressors/#/play" />
  </head>
  <body>
    <p>Redirecting to <a href="https://gunnchos3k.github.io/anime-aggressors/#/play">Anime Aggressors Play</a>...</p>
  </body>
</html>
```

4. After Pages deploys, visiting `https://gunnchos3k.github.io/play/` redirects to the project play route.

## Other useful hash routes

| Mode | URL |
|------|-----|
| Home | `https://gunnchos3k.github.io/anime-aggressors/#/` |
| Play Match | `https://gunnchos3k.github.io/anime-aggressors/#/play` |
| Impact Dummy Derby | `https://gunnchos3k.github.io/anime-aggressors/#/impact-dummy-derby` |
| Create Fighter | `https://gunnchos3k.github.io/anime-aggressors/#/create-fighter` |
| Training | `https://gunnchos3k.github.io/anime-aggressors/#/training` |
