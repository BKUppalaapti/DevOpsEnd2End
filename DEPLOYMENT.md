# Story App - Complete Deployment Guide

## 📋 Overview

This project is a complete DevOps end-to-end solution for a Flask Story Submission Platform with:
- ✅ Flask web application with form handling
- ✅ Docker containerization (multi-stage build)
- ✅ Kubernetes deployment (kubeadm local cluster)
- ✅ PersistentVolume for story storage
- ✅ GitHub Actions CI/CD pipeline
- ✅ Windows PowerShell deployment automation

## 🏗️ Project Structure

```
DevOpsEnd2End/
├── app.py                          # Flask application
├── requirements.txt                # Python dependencies
├── Dockerfile                      # Multi-stage Docker build
├── .dockerignore                   # Docker ignore patterns
├── templates/
│   └── index.html                  # Web form UI
├── k8s/
│   ├── pv-pvc.yaml               # PersistentVolume & PersistentVolumeClaim
│   ├── deployment.yaml            # Kubernetes Deployment
│   └── service.yaml               # Kubernetes Service (NodePort)
├── .github/
│   └── workflows/
│       └── ci-cd.yml              # GitHub Actions pipeline
├── deploy-local.ps1               # Windows PowerShell deployment script
├── DEPLOYMENT.md                  # This file
└── README.md                       # Project description
```

## 📝 Prerequisites

### Windows Local Environment
- **Windows 11** with PowerShell 5.1+
- **Docker Desktop for Windows** (with WSL2 or Hyper-V backend)
- **kubectl** installed and configured
- **kubeadm cluster** running locally
- **Git** for version control
- **Docker Hub account** with username: `balauppalapati`

### Verify Prerequisites

```powershell
# Check Docker
docker --version
docker ps

# Check kubectl
kubectl --version
kubectl cluster-info

# Check kubeadm nodes
kubectl get nodes -o wide
```

## 🔧 Configuration Files

### Docker Hub Credentials
Pre-filled with: `balauppalapati`

All configuration files use this username. To change it:
1. Update `k8s/deployment.yaml` - change image reference
2. Update `deploy-local.ps1` - change `-DockerHubUsername` parameter
3. Update `.github/workflows/ci-cd.yml` - update `IMAGE_NAME`

### GitHub Actions Secrets
Required for automated CI/CD:

1. Go to GitHub repository → Settings → Secrets and variables → Actions
2. Add these secrets:
   - `DOCKERHUB_USERNAME`: `balauppalapati`
   - `DOCKERHUB_TOKEN`: Your Docker Hub personal access token

### Kubernetes Storage
The PVC uses a local `hostPath` volume:
- **Local path**: `/mnt/data/stories`
- **Storage capacity**: 5Gi
- **Access mode**: ReadWriteOnce

## 🚀 Deployment Workflow

### 1. Feature Branch Development
```bash
# Create feature branch from main
git checkout -b feature/story-form

# Make your changes
# Commit and push
git push origin feature/story-form
```

### 2. Merge to Develop Branch
```bash
# Switch to develop
git checkout develop

# Merge feature branch
git merge feature/story-form

# Push to develop
git push origin develop
```

### 3. Create Pull Request to Main
```bash
# GitHub UI: Create PR from develop → main
# This triggers the GitHub Actions pipeline
```

### 4. GitHub Actions Pipeline
The `.github/workflows/ci-cd.yml` runs:
1. **Linting** - Python code quality checks (Flake8, Pylint)
2. **Security** - Vulnerability scanning (Bandit, Safety, Hadolint)
3. **Docker Build Verification** - Builds image without pushing
4. **On main merge**:
   - Builds Docker image
   - Pushes to Docker Hub (`balauppalapati/story-app:latest`)
   - Creates tagged image (`balauppalapati/story-app:<commit-sha>`)

### 5. Local Deployment to kubeadm
```powershell
# After merging to main, run deployment script on Windows:
./deploy-local.ps1

# Optional parameters:
./deploy-local.ps1 -DockerHubUsername "balauppalapati" -ImageTag "latest"
```

## 📚 Detailed Deployment Steps

### Step-by-Step: Local Kubernetes Deployment

#### 1. Pull Latest Changes
```bash
git pull origin main
```

#### 2. Run PowerShell Deployment Script
```powershell
# Navigate to project directory
cd C:\Users\bkupp\LearningProjects\DevOpsEnd2End

# Run deployment script
.\deploy-local.ps1
```

The script will:
1. ✓ Verify Docker daemon is running
2. ✓ Verify kubectl can access cluster
3. ✓ Build Docker image locally
4. ✓ Push image to Docker Hub
5. ✓ Create Kubernetes namespace
6. ✓ Apply PV/PVC manifests
7. ✓ Apply Deployment manifest (2 replicas)
8. ✓ Apply Service manifest (NodePort 30500)
9. ✓ Wait for pods to be ready
10. ✓ Display access information

#### 3. Access the Application

The script outputs your kubeadm node's IP and NodePort. Example:

```
Node Information:
  NAME      STATUS   ROLES           AGE   VERSION   INTERNAL-IP      EXTERNAL-IP
  kubenode  Ready    control-plane   10d   v1.27.0   192.168.1.100    <none>

Access Instructions:
1. Find your kubeadm node's IP address: 192.168.1.100
2. Open browser: http://192.168.1.100:30500
3. Start submitting stories!
```

### Manual Kubernetes Commands

```bash
# Check deployment status
kubectl get deployment -n default
kubectl get pods -n default -l app=story-app
kubectl describe deployment story-app -n default

# View logs
kubectl logs -f deployment/story-app -n default
kubectl logs <pod-name> -n default

# Check storage
kubectl get pv,pvc -n default

# Scale replicas
kubectl scale deployment story-app --replicas=3 -n default

# Edit deployment
kubectl edit deployment story-app -n default

# Delete deployment
kubectl delete deployment story-app -n default
kubectl delete svc story-app-service -n default
```

## 🔐 Application Features

### Form Fields (Required: *)
- **First Name** *
- **Last Name** *
- **Phone Number**
- **Email** *
- **Story Name** *
- **Story About** (Theme/Topic)
- **Story Writing** *

### Backend Storage
- Each submission saved as JSON file: `/app/stories/story_YYYYMMDD_HHMMSS_mmm.json`
- Persisted via Kubernetes PVC
- Survives pod restarts and redeployments

### API Endpoints
- `GET /` - Story submission form
- `POST /submit` - Submit story form
- `GET /stories` - Get all stories (JSON)
- `GET /health` - Health check (used by K8s probes)

## 📊 Kubernetes Resources

### Deployment Configuration
- **Replicas**: 2 (for high availability)
- **Strategy**: RollingUpdate
- **Image Pull Policy**: Always
- **Resource Limits**: 500m CPU, 512Mi Memory
- **Resource Requests**: 100m CPU, 128Mi Memory

### Health Checks
- **Liveness Probe**: HTTP GET `/health` every 20s (starts at 15s)
- **Readiness Probe**: HTTP GET `/health` every 10s (starts at 10s)
- **Health Check**: Verifies stories directory is accessible

### Security
- **Non-root user**: appuser (UID 1000)
- **Read-only root filesystem**: Disabled (app writes to /app/stories)
- **Pod security context**: FSGroup 1000
- **Network policies**: None (modify as needed)

## 🐳 Docker Image Details

### Base Image
- **Runtime**: `python:3.11-slim`
- **Size**: ~150MB (optimized)

### Multi-stage Build
- **Stage 1 (Builder)**: Installs dependencies
- **Stage 2 (Runtime)**: Minimal final image
- **Benefits**: Reduced image size, improved security

### Health Check
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3
```

## 🔄 Git Workflow Summary

```
feature/* → develop → main
    ↓          ↓        ↓
  LOCAL      LOCAL    CI/CD (GitHub Actions)
  WORK       TESTING       ↓
                       BUILD & PUSH
                       TO DOCKER HUB
                            ↓
                       TRIGGER: Pull main
                            ↓
                       ./deploy-local.ps1
                            ↓
                       LOCAL KUBEADM
                       DEPLOYMENT
```

## 🛠️ Troubleshooting

### Docker Build Fails
```powershell
# Clear Docker cache
docker system prune -a

# Rebuild without cache
docker build --no-cache -t balauppalapati/story-app:latest .
```

### Pod not starting
```bash
# Check pod events
kubectl describe pod <pod-name> -n default

# View pod logs
kubectl logs <pod-name> -n default

# Check image pull
docker pull balauppalapati/story-app:latest
```

### PVC not binding
```bash
# Check PV status
kubectl get pv
kubectl describe pv story-pv

# Check directory on kubeadm node
ls -la /mnt/data/stories
```

### Cannot access NodePort
```bash
# Get node IP
kubectl get nodes -o wide

# Verify service is active
kubectl get svc story-app-service

# Check firewall rules
netstat -ano | findstr :30500  # Windows
ss -tuln | grep :30500         # Linux
```

### GitHub Actions Secrets Error
```
Error: Could not find image 'balauppalapati/story-app:latest'

Solution:
1. Verify DOCKERHUB_TOKEN secret is set correctly
2. Check Docker Hub credentials are valid
3. Verify Docker Hub account has this repository
```

## 📈 Scaling and Optimization

### Scale Deployment
```bash
# Increase replicas to 3
kubectl scale deployment story-app --replicas=3 -n default

# Edit replicas in deployment
kubectl set replicas deployment/story-app=5 -n default
```

### Increase Storage
```yaml
# In k8s/pv-pvc.yaml, increase storage:
capacity:
  storage: 20Gi  # Change from 5Gi
resources:
  requests:
    storage: 20Gi
```

### Resource Limits
Modify in `k8s/deployment.yaml`:
```yaml
resources:
  requests:
    cpu: 200m      # Increase from 100m
    memory: 256Mi  # Increase from 128Mi
  limits:
    cpu: 1000m     # Increase from 500m
    memory: 1Gi    # Increase from 512Mi
```

## 📝 Common Tasks

### Deploy a specific version
```powershell
./deploy-local.ps1 -ImageTag "v1.0.0"
```

### Deploy to different namespace
```powershell
./deploy-local.ps1 -KubeNamespace "story-app-prod"
```

### View real-time logs
```bash
kubectl logs -f deployment/story-app -n default
```

### Update image in running deployment
```bash
kubectl set image deployment/story-app story-app=balauppalapati/story-app:v1.0.0
```

### Restart pods
```bash
kubectl rollout restart deployment/story-app -n default
```

## 🧪 Testing the Application

### Local Testing (Before Kubernetes)
```bash
# Build image
docker build -t balauppalapati/story-app:latest .

# Run container locally
docker run -p 5000:5000 -v stories:/app/stories balauppalapati/story-app:latest

# Access: http://localhost:5000
```

### Kubernetes Testing
```bash
# Port forward to local machine
kubectl port-forward svc/story-app-service 8080:80 -n default

# Access: http://localhost:8080
```

## 📞 Support Resources

- **Kubernetes Docs**: https://kubernetes.io/docs/
- **Docker Docs**: https://docs.docker.com/
- **Flask Documentation**: https://flask.palletsprojects.com/
- **kubeadm**: https://kubernetes.io/docs/reference/setup-tools/kubeadm/

## 🎯 Next Steps

1. ✅ Review all generated files
2. ✅ Configure GitHub Actions secrets
3. ✅ Push feature branch to develop
4. ✅ Create PR to main
5. ✅ Verify GitHub Actions passes
6. ✅ Merge to main
7. ✅ Run `./deploy-local.ps1`
8. ✅ Test the application
9. ✅ Submit stories and verify storage

## 📄 License

This project is configured for educational and development purposes.

---

**Generated**: 2026-05-25
**Configuration**: Docker Hub: `balauppalapati` | K8s: Local kubeadm | OS: Windows 11
