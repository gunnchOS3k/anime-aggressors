# 🚀 Deployment Guide

This guide covers deploying Anime Aggressors to GitHub Pages with custom domain support.

## 📋 Prerequisites

- GitHub repository with Pages enabled
- Domain name (optional)
- GitHub Actions enabled

## 🔧 Setup

### 1. Enable GitHub Pages

1. Go to your repository Settings
2. Navigate to Pages section
3. Select "GitHub Actions" as source
4. The workflow will automatically deploy on push to main

### 2. Custom Domain (Optional)

#### Option A: Free .is-a.dev Subdomain

1. Visit [is-a.dev](https://is-a.dev)
2. Register for a free subdomain (e.g., `anime-aggressors.is-a.dev`)
3. Add CNAME record pointing to your GitHub Pages URL
4. Create `CNAME` file in repository root:

```bash
echo "anime-aggressors.is-a.dev" > CNAME
```

#### Option B: Custom Domain

1. Purchase domain from any registrar
2. Add CNAME record: `anime-aggressors.yourdomain.com` → `gunnchOS3k.github.io`
3. Create `CNAME` file:

```bash
echo "anime-aggressors.yourdomain.com" > CNAME
```

### 3. Environment Variables

The workflow automatically sets `BASE_URL` for GitHub Pages subpath:

```yaml
env:
  BASE_URL: /anime-aggressors/
```

## 🎯 Deployment Process

### Automatic Deployment

1. **Push to main branch**
2. **GitHub Actions runs**:
   - Installs dependencies
   - Builds the project
   - Deploys to gh-pages branch
3. **Pages updates** automatically

### Manual Deployment

```bash
# Build the project
pnpm build

# Deploy using gh-pages
pnpm deploy
```

## 🔍 Troubleshooting

### Common Issues

1. **404 on subpages**: Ensure `BASE_URL` is set correctly
2. **Assets not loading**: Check Vite base URL configuration
3. **Custom domain not working**: Verify CNAME record and DNS propagation

### Debug Steps

1. Check GitHub Actions logs
2. Verify Pages settings
3. Test locally with production build:

```bash
pnpm build
pnpm preview
```

## 📱 Multi-Device Testing

### Desktop
- Chrome/Edge: Best gamepad support
- Firefox: May have mapping issues with DualSense

### Mobile
- Chrome: Bluetooth controller support
- Touch controls: Fallback for mobile users

### Controller Testing

1. **PS5 DualSense**: 
   - USB: Works immediately
   - Bluetooth: Pair via system settings
   - Browser: Chrome/Edge recommended

2. **Switch Pro**:
   - USB: Works immediately  
   - Bluetooth: Pair via system settings
   - Browser: Chrome/Edge recommended

## 🌐 URL Structure

- **GitHub Pages**: `https://gunnchOS3k.github.io/anime-aggressors/`
- **Custom Domain**: `https://anime-aggressors.yourdomain.com`
- **Local Development**: `http://localhost:5173`

## 📊 Performance

### Optimization

- **Three.js**: Frustum culling enabled
- **Physics**: Fixed timestep for consistency
- **Input**: 60fps polling rate
- **Assets**: Compressed textures and models

### Metrics

- **Target**: <5ms script time per frame
- **FPS**: 60fps on mid-range laptops
- **Bundle Size**: <2MB gzipped

## 🔒 Security

- **HTTPS**: Required for gamepad API
- **CORS**: Configured for cross-origin requests
- **Content Security Policy**: Minimal restrictions for game functionality

## 📈 Analytics

Consider adding analytics to track:

- Controller usage patterns
- Performance metrics
- User engagement
- Error rates

## 🆘 Support

If you encounter issues:

1. Check browser console for errors
2. Verify controller connection
3. Test in incognito mode
4. Try different browsers
5. Check GitHub Actions logs

---

*For more help, see the [GitHub Pages documentation](https://docs.github.com/en/pages)*

