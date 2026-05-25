#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
Local deployment script for Story App to kubeadm cluster on Windows

.DESCRIPTION
This script automates the deployment of the Story App to a local kubeadm Kubernetes cluster.
It builds the Docker image, pushes it to Docker Hub, and applies Kubernetes manifests.

.PARAMETER DockerHubUsername
Docker Hub username (default: balauppalapati)

.PARAMETER ImageName
Docker image name (default: story-app)

.PARAMETER ImageTag
Docker image tag (default: latest)

.PARAMETER KubeNamespace
Kubernetes namespace (default: default)

.EXAMPLE
.\deploy-local.ps1

.EXAMPLE
.\deploy-local.ps1 -ImageTag "v1.0.0"
#>

param(
    [string]$DockerHubUsername = "balauppalapati",
    [string]$ImageName = "story-app",
    [string]$ImageTag = "latest",
    [string]$KubeNamespace = "default"
)

# Error handling
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

# Color output helper
function Write-ColorOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Type = "Info"
    )

    $colors = @{
        "Info"    = "Cyan"
        "Success" = "Green"
        "Warning" = "Yellow"
        "Error"   = "Red"
    }

    Write-Host "[$Type] $Message" -ForegroundColor $colors[$Type]
}

# Function to check if command exists
function Test-CommandExists {
    param(
        [string]$Command
    )

    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Script execution
try {
    Write-ColorOutput "========================================" "Info"
    Write-ColorOutput "Story App - Local kubeadm Deployment" "Info"
    Write-ColorOutput "========================================" "Info"
    Write-ColorOutput ""

    # Prerequisites check
    Write-ColorOutput "Checking prerequisites..." "Info"

    if (-not (Test-CommandExists "docker")) {
        throw "Docker is not installed or not in PATH. Please install Docker Desktop for Windows."
    }
    Write-ColorOutput "✓ Docker found" "Success"

    if (-not (Test-CommandExists "kubectl")) {
        throw "kubectl is not installed or not in PATH. Please install kubectl."
    }
    Write-ColorOutput "✓ kubectl found" "Success"

    # Check Docker daemon
    Write-ColorOutput "Checking Docker daemon..." "Info"
    try {
        docker ps | Out-Null
    }
    catch {
        throw "Docker daemon is not running. Please start Docker Desktop."
    }
    Write-ColorOutput "✓ Docker daemon is running" "Success"

    # Check Kubernetes cluster
    Write-ColorOutput "Checking Kubernetes cluster..." "Info"
    try {
        kubectl cluster-info | Out-Null
    }
    catch {
        throw "Cannot connect to Kubernetes cluster. Please verify kubeadm cluster is running."
    }
    Write-ColorOutput "✓ Kubernetes cluster is accessible" "Success"
    Write-ColorOutput ""

    # Build Docker image
    Write-ColorOutput "Step 1: Building Docker image..." "Info"
    $imageFullName = "$DockerHubUsername/$ImageName`:$ImageTag"
    Write-ColorOutput "Building: $imageFullName" "Info"

    docker build -t $imageFullName -f Dockerfile .

    if ($LASTEXITCODE -ne 0) {
        throw "Docker build failed with exit code $LASTEXITCODE"
    }
    Write-ColorOutput "✓ Docker image built successfully: $imageFullName" "Success"
    Write-ColorOutput ""

    # Push to Docker Hub
    Write-ColorOutput "Step 2: Pushing image to Docker Hub..." "Info"
    Write-ColorOutput "Pushing: $imageFullName" "Info"

    docker push $imageFullName

    if ($LASTEXITCODE -ne 0) {
        throw "Docker push failed with exit code $LASTEXITCODE"
    }
    Write-ColorOutput "✓ Image pushed to Docker Hub successfully" "Success"
    Write-ColorOutput "  Repository: https://hub.docker.com/r/$DockerHubUsername/$ImageName" "Info"
    Write-ColorOutput ""

    # Create namespace if it doesn't exist
    Write-ColorOutput "Step 3: Preparing Kubernetes namespace..." "Info"

    kubectl create namespace $KubeNamespace --dry-run=client -o yaml | kubectl apply -f -
    Write-ColorOutput "✓ Namespace '$KubeNamespace' is ready" "Success"
    Write-ColorOutput ""

    # Apply Kubernetes manifests
    Write-ColorOutput "Step 4: Applying Kubernetes manifests..." "Info"

    $k8sDir = "./k8s"

    if (-not (Test-Path $k8sDir)) {
        throw "Kubernetes manifests directory '$k8sDir' not found"
    }

    # Apply PV and PVC first
    Write-ColorOutput "Applying PersistentVolume and PersistentVolumeClaim..." "Info"
    kubectl apply -f "$k8sDir/pv-pvc.yaml" -n $KubeNamespace

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to apply PV/PVC manifests"
    }
    Write-ColorOutput "✓ Storage manifests applied" "Success"

    # Wait for PVC to be bound
    Write-ColorOutput "Waiting for PVC to be bound..." "Info"
    $maxRetries = 30
    $retryCount = 0

    while ($retryCount -lt $maxRetries) {
        $pvcStatus = kubectl get pvc story-pvc -n $KubeNamespace -o jsonpath='{.status.phase}' 2>$null

        if ($pvcStatus -eq "Bound") {
            Write-ColorOutput "✓ PVC is bound" "Success"
            break
        }

        $retryCount++
        if ($retryCount -eq $maxRetries) {
            Write-ColorOutput "Warning: PVC not bound after 30 seconds, continuing anyway..." "Warning"
        }
        else {
            Write-Host "  Waiting for PVC... ($retryCount/$maxRetries)" -ForegroundColor Cyan
            Start-Sleep -Seconds 1
        }
    }

    # Apply Deployment
    Write-ColorOutput "Applying Deployment..." "Info"
    kubectl apply -f "$k8sDir/deployment.yaml" -n $KubeNamespace

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to apply Deployment manifest"
    }
    Write-ColorOutput "✓ Deployment manifest applied" "Success"

    # Apply Service
    Write-ColorOutput "Applying Service..." "Info"
    kubectl apply -f "$k8sDir/service.yaml" -n $KubeNamespace

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to apply Service manifest"
    }
    Write-ColorOutput "✓ Service manifest applied" "Success"
    Write-ColorOutput ""

    # Wait for deployment to be ready
    Write-ColorOutput "Step 5: Waiting for deployment to be ready..." "Info"

    $deploymentName = "story-app"
    $maxRetries = 60
    $retryCount = 0

    while ($retryCount -lt $maxRetries) {
        $readyReplicas = kubectl get deployment $deploymentName -n $KubeNamespace -o jsonpath='{.status.readyReplicas}' 2>$null
        $desiredReplicas = kubectl get deployment $deploymentName -n $KubeNamespace -o jsonpath='{.spec.replicas}' 2>$null

        if ($readyReplicas -eq $desiredReplicas -and $readyReplicas -gt 0) {
            Write-ColorOutput "✓ Deployment is ready ($readyReplicas/$desiredReplicas replicas)" "Success"
            break
        }

        $retryCount++
        if ($retryCount -eq $maxRetries) {
            Write-ColorOutput "Warning: Deployment not fully ready after 60 seconds" "Warning"
            Write-ColorOutput "Ready replicas: $readyReplicas/$desiredReplicas" "Warning"
        }
        else {
            Write-Host "  Waiting for deployment... ($retryCount/$maxRetries) - Ready: $readyReplicas/$desiredReplicas replicas" -ForegroundColor Cyan
            Start-Sleep -Seconds 1
        }
    }
    Write-ColorOutput ""

    # Get access information
    Write-ColorOutput "Step 6: Deployment Information" "Info"
    Write-ColorOutput "========================================" "Info"

    # Get NodePort
    $nodePort = kubectl get svc story-app-service -n $KubeNamespace -o jsonpath='{.spec.ports[0].nodePort}' 2>$null

    # Get node IP
    $nodeInfo = kubectl get nodes -o wide --no-headers 2>$null

    Write-ColorOutput "Service Details:" "Info"
    Write-ColorOutput "  Service Name: story-app-service" "Info"
    Write-ColorOutput "  Service Type: NodePort" "Info"
    Write-ColorOutput "  NodePort: $nodePort" "Info"
    Write-ColorOutput ""

    Write-ColorOutput "Node Information:" "Info"
    Write-ColorOutput "$nodeInfo" "Info"
    Write-ColorOutput ""

    Write-ColorOutput "Access Instructions:" "Info"
    Write-ColorOutput "1. Find your kubeadm node's IP address from the list above (INTERNAL-IP column)" "Info"
    Write-ColorOutput "2. Open your browser and navigate to: http://<NODE-IP>:$nodePort" "Info"
    Write-ColorOutput "3. Example: http://192.168.1.100:$nodePort" "Info"
    Write-ColorOutput ""

    # Deployment summary
    Write-ColorOutput "Deployment Summary:" "Info"
    Write-ColorOutput "  Namespace: $KubeNamespace" "Info"
    Write-ColorOutput "  Image: $imageFullName" "Info"
    Write-ColorOutput "  Replicas: $(kubectl get deployment $deploymentName -n $KubeNamespace -o jsonpath='{.spec.replicas}')" "Info"
    Write-ColorOutput ""

    # Show pods status
    Write-ColorOutput "Pod Status:" "Info"
    kubectl get pods -n $KubeNamespace -l app=story-app --no-headers 2>$null | ForEach-Object {
        Write-ColorOutput "  $_" "Info"
    }
    Write-ColorOutput ""

    # Show volumes status
    Write-ColorOutput "Storage Status:" "Info"
    kubectl get pv,pvc -n $KubeNamespace --no-headers 2>$null | ForEach-Object {
        Write-ColorOutput "  $_" "Info"
    }
    Write-ColorOutput ""

    # Useful commands
    Write-ColorOutput "Useful Commands:" "Info"
    Write-ColorOutput "  View logs: kubectl logs -f deployment/story-app -n $KubeNamespace" "Info"
    Write-ColorOutput "  Scale replicas: kubectl scale deployment story-app --replicas=3 -n $KubeNamespace" "Info"
    Write-ColorOutput "  Describe deployment: kubectl describe deployment story-app -n $KubeNamespace" "Info"
    Write-ColorOutput "  Delete deployment: kubectl delete deployment story-app -n $KubeNamespace" "Info"
    Write-ColorOutput ""

    Write-ColorOutput "========================================" "Success"
    Write-ColorOutput "✓ Deployment completed successfully!" "Success"
    Write-ColorOutput "========================================" "Success"

}
catch {
    Write-ColorOutput "ERROR: $_" "Error"
    Write-ColorOutput "Deployment failed. Please check the error message above." "Error"
    exit 1
}
