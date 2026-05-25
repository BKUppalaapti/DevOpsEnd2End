# 🎯 Setup Instructions - Complete DevOps Project

## ✅ Files Generated

Your complete DevOps project has been generated with the following structure:

```
DevOpsEnd2End/
│
├─ 📄 Application Files
│  ├── app.py                           (Flask application with form handling)
│  ├── requirements.txt                 (Python dependencies: Flask, Werkzeug, Jinja2)
│  └── templates/index.html             (Responsive web UI with form and story display)
│
├─ 🐳 Docker Configuration
│  ├── Dockerfile                       (Multi-stage optimized container image)
│  └── .dockerignore                    (Excludes unnecessary files from image)
│
├─ ☸️ Kubernetes Configuration
│  └── k8s/
│      ├── pv-pvc.yaml                 (PersistentVolume + PersistentVolumeClaim)
│      ├── deployment.yaml             (2-replica deployment with health checks)
│      └── service.yaml                (NodePort service on port 30500)
│
├─ 🚀 Automation & CI/CD
│  ├── .github/workflows/ci-cd.yml     (GitHub Actions pipeline)
│  └── deploy-local.ps1                (Windows PowerShell deployment script)
│
├─ 📚 Documentation
│  ├── DEPLOYMENT.md                   (Complete guide with troubleshooting)
│  ├── QUICK_START.md                  (Quick reference for common tasks)
│  ├── SETUP_INSTRUCTIONS.md           (This file - initial setup)
│  └── README.md                       (Project overview)
│
└─ ⚙️ Git Configuration
   └── .gitignore                      (Excludes unnecessary files from git)
```

---

## 🔑 Key Configuration Details

### Docker Hub Configuration
- **Username**: `balauppalapati` (pre-filled in all configs)
- **Image Name**: `story-app`
- **Image Tag**: `latest`
- **Full Image**: `balauppalapati/story-app:latest`

### Kubernetes Configuration
- **Namespace**: `default`
- **Deployment**: 2 replicas (high availability)
- **Service Type**: NodePort (port 30500)
- **Storage**: PersistentVolume with hostPath at `/mnt/data/stories`

### Application Endpoints
- **Web UI**: `http://<NODE-IP>:30500`
- **API (Stories)**: `http://<NODE-IP>:30500/stories`
- **Health Check**: `http://<NODE-IP>:30500/health`

---

## 📋 Pre-Deployment Checklist

### 1. GitHub Configuration
- [ ] Repository created and initialized
- [ ] Feature branch created
- [ ] Code committed to feature branch

### 2. GitHub Actions Secrets (IMPORTANT)
Navigate to: **GitHub → Repository → Settings → Secrets and variables → Actions**

Add these secrets:
- [ ] `DOCKERHUB_USERNAME` = `balauppalapati`
- [ ] `DOCKERHUB_TOKEN` = Your Docker Hub token (from Docker Hub → Account → Security)

**How to get Docker Hub token:**
1. Go to https://hub.docker.com/settings/security
2. Click "New Access Token"
3. Create token with read/write permissions
4. Copy and save in GitHub Secrets

### 3. Local Environment
- [ ] Docker Desktop running on Windows
- [ ] kubeadm Kubernetes cluster running
- [ ] kubectl configured and accessible
- [ ] PowerShell execution policy allows running scripts

**Allow PowerShell script execution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 4. Network & Firewall
- [ ] Firewall allows port 30500 on kubeadm node
- [ ] Docker can reach Docker Hub
- [ ] kubeadm nodes can pull from Docker Hub

---

## 🚀 Step-by-Step Deployment Guide

### Step 1: Commit All Files to Feature Branch
```powershell
# Navigate to project
cd C:\Users\bkupp\LearningProjects\DevOpsEnd2End

# Verify you're on feature branch
git branch

# Stage all files
git add .

# Commit
git commit -m "feat: Add complete DevOps pipeline with Flask app, Docker, K8s, and GitHub Actions"

# Push to feature branch
git push origin feature/devops-pipeline
```

### Step 2: Merge to Develop Branch
```powershell
# Switch to develop
git checkout develop

# Pull latest
git pull origin develop

# Merge feature branch
git merge feature/devops-pipeline

# Push to develop
git push origin develop
```

### Step 3: Create Pull Request to Main
1. Go to GitHub repository
2. Click **Pull Requests**
3. Click **New Pull Request**
4. Set: `base: main` ← `compare: develop`
5. Click **Create Pull Request**
6. Add description (optional)
7. Review the GitHub Actions checks:
   - ✅ Linting
   - ✅ Security scanning
   - ✅ Docker build verification

### Step 4: Merge to Main (Triggers CI/CD)
1. Verify all checks pass in GitHub Actions
2. Click **Merge pull request**
3. Confirm merge
4. GitHub Actions will automatically:
   - Build Docker image
   - Push to Docker Hub
   - Create tagged images

### Step 5: Pull Latest to Local Machine
```powershell
git pull origin main
```

### Step 6: Deploy to Local Kubernetes
```powershell
# Run the deployment script
.\deploy-local.ps1
```

**The script will:**
1. ✅ Verify Docker daemon is running
2. ✅ Verify kubectl can access cluster
3. ✅ Build Docker image locally
4. ✅ Push image to Docker Hub
5. ✅ Create Kubernetes namespace
6. ✅ Apply storage manifests (PV/PVC)
7. ✅ Apply deployment manifest
8. ✅ Apply service manifest
9. ✅ Wait for pods to be ready
10. ✅ Display access information

### Step 7: Access the Application
The script output will show:
```
Node Information:
  NAME         STATUS   INTERNAL-IP      
  kubenode     Ready    192.168.1.100    

Access Instructions:
Open browser: http://192.168.1.100:30500
```

**Visit the URL in your browser!**

---

## 🧪 Test the Application

### Test Story Submission
1. Open the application in browser
2. Fill in the form:
   - First Name: `John`
   - Last Name: `Doe`
   - Email: `john@example.com`
   - Story Name: `My First Story`
   - Story About: `Adventure`
   - Story Writing: `Once upon a time...`
3. Click **Submit Story**
4. Verify success message appears
5. Verify story appears in "Recent Stories" section

### Verify Storage Persistence
1. Get pod name: `kubectl get pods -l app=story-app`
2. Delete a pod: `kubectl delete pod <pod-name>`
3. Kubernetes automatically restarts the pod
4. Access application - stories should still be there!

### Check Story Files
Stories are stored as JSON in `/mnt/data/stories/` on your kubeadm node:
```bash
# SSH into kubeadm node
ls -la /mnt/data/stories/
cat /mnt/data/stories/story_*.json
```

---

## 🔄 Continuous Workflow

After initial setup, your workflow is:

```
┌─ Make Changes in Feature Branch
├─ Commit & Push to feature/*
├─ Merge to develop
├─ Create PR to main (GitHub Actions runs)
├─ Merge to main (CI/CD builds & pushes image)
├─ Pull latest locally
├─ Run: .\deploy-local.ps1
└─ Test in browser
```

---

## 📚 Documentation Files

### For Quick Reference:
→ Read **QUICK_START.md** (3-step deployment, common commands)

### For Complete Details:
→ Read **DEPLOYMENT.md** (full guide, troubleshooting, scaling)

### For Specific Tasks:
- Want to scale to 5 replicas? See: DEPLOYMENT.md → Scaling
- Pod not starting? See: DEPLOYMENT.md → Troubleshooting
- Need new API endpoint? See: app.py comments
- Need to modify UI? See: templates/index.html
- Need custom Kubernetes config? See: k8s/ manifests

---

## ⚡ Important PowerShell Commands

### View Application Status
```powershell
# All pods
kubectl get pods

# Deployment info
kubectl describe deployment story-app

# Service info
kubectl get svc story-app-service

# Storage info
kubectl get pv,pvc
```

### View Logs
```powershell
# Recent logs
kubectl logs deployment/story-app

# Follow logs (real-time)
kubectl logs -f deployment/story-app

# Specific pod
kubectl logs <pod-name>
```

### Access Application (Alternative)
```powershell
# Port forward
kubectl port-forward svc/story-app-service 8080:80

# Then open: http://localhost:8080
```

### Cleanup
```powershell
# Delete everything
kubectl delete deployment story-app
kubectl delete svc story-app-service
kubectl delete pvc story-pvc
```

---

## 🐛 Quick Troubleshooting

### "Docker build failed"
```powershell
# Clear cache and retry
docker system prune -a
.\deploy-local.ps1
```

### "Push failed - authentication error"
- Verify `DOCKERHUB_TOKEN` secret in GitHub
- Check Docker Hub credentials: `docker login`

### "Pods not starting"
```powershell
# Check pod status
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>
```

### "Cannot access NodePort"
```powershell
# Verify service is running
kubectl get svc

# Get node IP
kubectl get nodes -o wide

# Verify port is open
Test-NetConnection -ComputerName <NODE-IP> -Port 30500
```

---

## 🎓 Learning Resources

### Application Code
- **app.py**: Flask routing, form handling, file storage
- **templates/index.html**: Frontend form, JavaScript, REST API calls

### Docker
- **Dockerfile**: Multi-stage build, optimization, health checks

### Kubernetes
- **k8s/deployment.yaml**: Pod specs, health probes, resource limits
- **k8s/service.yaml**: Service networking, NodePort exposure
- **k8s/pv-pvc.yaml**: Persistent storage configuration

### CI/CD
- **.github/workflows/ci-cd.yml**: GitHub Actions, linting, security scanning
- **deploy-local.ps1**: Automation scripting, error handling

---

## 🎯 Next Immediate Steps

### Right Now:
1. ✅ Read this file (you're doing it!)
2. ✅ Review all generated files
3. ✅ Add GitHub Secrets (DOCKERHUB_USERNAME, DOCKERHUB_TOKEN)

### Before First Deployment:
1. ✅ Set PowerShell execution policy
2. ✅ Ensure Docker Desktop is running
3. ✅ Ensure kubeadm cluster is running
4. ✅ Verify kubectl access: `kubectl get nodes`

### First Deployment:
1. ✅ Follow "Step-by-Step Deployment Guide" above
2. ✅ Access application in browser
3. ✅ Submit a test story
4. ✅ Verify storage persistence

### Iterate:
1. ✅ Make changes to app.py or templates/index.html
2. ✅ Commit and push to feature branch
3. ✅ Create PR and merge to main
4. ✅ Run `.\deploy-local.ps1`
5. ✅ Test in browser
6. ✅ Repeat!

---

## 📞 Questions?

See the relevant documentation file:
- **QUICK_START.md** - Fast answers for common tasks
- **DEPLOYMENT.md** - Detailed explanations and troubleshooting

---

## 🎉 Summary

You now have:
- ✅ Production-ready Flask application
- ✅ Optimized Docker containerization
- ✅ Kubernetes deployment configuration
- ✅ Persistent storage setup
- ✅ GitHub Actions CI/CD pipeline
- ✅ Windows PowerShell deployment script
- ✅ Complete documentation

**Everything is configured for Windows with Docker Hub username: `balauppalapati`**

---

**Ready to deploy? Follow the "Step-by-Step Deployment Guide" above!** 🚀

Generated: 2026-05-25 | Configuration: Windows 11 | Docker: balauppalapati | Kubernetes: Local kubeadm
