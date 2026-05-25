# 🚀 Quick Start Guide

## ⚡ TL;DR - Deploy in 3 Steps

### 1. Merge Your Code
```bash
# On Windows PowerShell
git checkout develop
git merge feature/your-branch
git push origin develop

# Create PR from develop to main in GitHub UI
# Wait for GitHub Actions to pass
# Merge PR to main
```

### 2. Pull Latest Changes
```bash
git pull origin main
```

### 3. Deploy to Local Kubernetes
```powershell
# Run deployment script
.\deploy-local.ps1

# Wait for output with access information
# Copy the NodePort URL and open in browser
```

---

## 📖 Full Workflow

### Phase 1: Development (Your Feature Branch)
```bash
# Clone/navigate to project
cd C:\Users\bkupp\LearningProjects\DevOpsEnd2End

# Create or switch to feature branch
git checkout -b feature/my-feature

# Make changes to:
# - app.py
# - templates/index.html
# - Or other files

# Commit and push
git add .
git commit -m "Add my feature"
git push origin feature/my-feature
```

### Phase 2: Integration (Develop Branch)
```bash
# Switch to develop branch
git checkout develop

# Pull latest
git pull origin develop

# Merge feature branch
git merge feature/my-feature

# Push to develop
git push origin develop

# Optional: Delete feature branch
git push origin --delete feature/my-feature
```

### Phase 3: Release & Testing (Main Branch)
```bash
# In GitHub UI:
# 1. Go to Pull Requests
# 2. Create New PR: develop → main
# 3. Review CI/CD checks pass
# 4. Merge PR

# On local machine:
git pull origin main
```

### Phase 4: Kubernetes Deployment
```powershell
# Deploy to local kubeadm cluster
.\deploy-local.ps1

# Output will show:
# - Docker image pushed: balauppalapati/story-app:latest
# - Kubernetes pods deployed
# - Access URL: http://<NODE-IP>:30500
```

---

## 🖥️ Access Your Application

Once deployed, the script will output something like:

```
Node Information:
  NAME      STATUS   ROLES           AGE   VERSION   INTERNAL-IP      EXTERNAL-IP
  kubenode  Ready    control-plane   10d   v1.27.0   192.168.1.100    <none>

Access Instructions:
1. Find your kubeadm node's IP address: 192.168.1.100
2. Open browser: http://192.168.1.100:30500
3. Start submitting stories!
```

**Open in browser**: `http://192.168.1.100:30500` (use your actual node IP)

---

## 🔧 Useful PowerShell Commands

### Check Status
```powershell
# Check if Docker is running
docker ps

# Check if Kubernetes cluster is accessible
kubectl cluster-info

# Check pods
kubectl get pods

# Check services
kubectl get svc
```

### View Application
```powershell
# View logs
kubectl logs -f deployment/story-app

# Port forward (alternative access)
kubectl port-forward svc/story-app-service 8080:80
# Then open: http://localhost:8080
```

### Cleanup
```powershell
# Delete deployment
kubectl delete deployment story-app

# Delete service
kubectl delete svc story-app-service

# Delete storage
kubectl delete pvc story-pvc
kubectl delete pv story-pv
```

---

## 📁 File Purposes

| File | Purpose |
|------|---------|
| `app.py` | Flask application (form handler, storage) |
| `templates/index.html` | Web UI (form + story display) |
| `requirements.txt` | Python dependencies |
| `Dockerfile` | Container definition |
| `k8s/pv-pvc.yaml` | Storage configuration |
| `k8s/deployment.yaml` | Kubernetes deployment config |
| `k8s/service.yaml` | Service config (NodePort) |
| `.github/workflows/ci-cd.yml` | GitHub Actions automation |
| `deploy-local.ps1` | Deployment script (Windows) |
| `DEPLOYMENT.md` | Detailed guide (you're reading this!) |

---

## ❓ Troubleshooting

### "Docker push failed"
- Check Docker Hub credentials
- Verify Docker daemon is running: `docker ps`
- Check internet connection

### "Pod not starting"
- Check logs: `kubectl logs deployment/story-app`
- Check image exists: `docker pull balauppalapati/story-app:latest`
- Check resources: `kubectl describe deployment story-app`

### "Cannot access http://IP:30500"
- Verify NodePort service: `kubectl get svc story-app-service`
- Get correct node IP: `kubectl get nodes -o wide`
- Check firewall rules
- Verify pods are running: `kubectl get pods`

### GitHub Actions failing
- Check secrets are set: Settings → Secrets → DOCKERHUB_USERNAME, DOCKERHUB_TOKEN
- View workflow logs in GitHub Actions tab
- Verify code passes linting: `flake8 app.py`

---

## 📚 Full Documentation

See **DEPLOYMENT.md** for:
- Complete workflow explanation
- Detailed troubleshooting
- Scaling and optimization
- Advanced Kubernetes commands

---

## 🎯 Your Next Immediate Steps

1. **Set GitHub Secrets** (if not done):
   - Go to: GitHub → Settings → Secrets → Actions
   - Add: `DOCKERHUB_USERNAME` = `balauppalapati`
   - Add: `DOCKERHUB_TOKEN` = Your Docker Hub token

2. **Make a Test Change**:
   - Edit `app.py` or `templates/index.html`
   - Commit and push to feature branch
   - Create PR to develop
   - Merge to develop
   - Create PR to main
   - Merge to main

3. **Deploy**:
   ```powershell
   .\deploy-local.ps1
   ```

4. **Test**:
   - Open browser to output URL
   - Submit a story
   - Verify it appears on page

---

**That's it! You now have a complete DevOps pipeline.** 🎉
