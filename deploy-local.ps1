#Requires -Version 5.1
#Requires -RunAsAdministrator

param(
    [string]$DockerHubUsername = "balauppalapati",
    [string]$ImageName = "story-app",
    [string]$ImageTag = "latest",
    [string]$KubeNamespace = "default"
)

$ErrorActionPreference = "Stop"

function Write-ColorOutput {
    param([string]$Message, [string]$Type = "Info")
    $colors = @{"Info" = "Cyan"; "Success" = "Green"; "Warning" = "Yellow"; "Error" = "Red"}
    Write-Host "[$Type] $Message" -ForegroundColor $colors[$Type]
}

function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

try {
    Write-ColorOutput "========================================" "Info"
    Write-ColorOutput "Story App - Local kubeadm Deployment" "Info"
    Write-ColorOutput "========================================" "Info"
    Write-ColorOutput ""

    Write-ColorOutput "Checking prerequisites..." "Info"

    if (-not (Test-CommandExists "docker")) {
        throw "Docker is not installed. Please install Docker Desktop for Windows."
    }
    Write-ColorOutput "Docker found" "Success"

    if (-not (Test-CommandExists "kubectl")) {
        throw "kubectl is not installed. Please install kubectl."
    }
    Write-ColorOutput "kubectl found" "Success"

    Write-ColorOutput "Checking Docker daemon..." "Info"
    docker ps | Out-Null
    Write-ColorOutput "Docker daemon is running" "Success"

    Write-ColorOutput "Checking Kubernetes cluster..." "Info"
    kubectl cluster-info | Out-Null
    Write-ColorOutput "Kubernetes cluster is accessible" "Success"
    Write-ColorOutput ""

    Write-ColorOutput "Step 1: Building Docker image..." "Info"
    $imageFullName = "$DockerHubUsername/$ImageName`:$ImageTag"
    Write-ColorOutput "Building: $imageFullName" "Info"

    docker build -t $imageFullName -f Dockerfile .

    if ($LASTEXITCODE -ne 0) {
        throw "Docker build failed"
    }
    Write-ColorOutput "Docker image built successfully" "Success"
    Write-ColorOutput ""

    Write-ColorOutput "Step 2: Pushing image to Docker Hub..." "Info"
    Write-ColorOutput "Pushing: $imageFullName" "Info"

    docker push $imageFullName

    if ($LASTEXITCODE -ne 0) {
        throw "Docker push failed"
    }
    Write-ColorOutput "Image pushed to Docker Hub successfully" "Success"
    Write-ColorOutput ""

    Write-ColorOutput "Step 3: Preparing Kubernetes namespace..." "Info"
    kubectl create namespace $KubeNamespace --dry-run=client -o yaml | kubectl apply -f -
    Write-ColorOutput "Namespace is ready" "Success"
    Write-ColorOutput ""

    Write-ColorOutput "Step 4: Applying Kubernetes manifests..." "Info"

    $k8sDir = "./k8s"

    if (-not (Test-Path $k8sDir)) {
        throw "Kubernetes manifests directory not found"
    }

    Write-ColorOutput "Applying PersistentVolume and PersistentVolumeClaim..." "Info"
    kubectl apply -f "$k8sDir/pv-pvc.yaml" -n $KubeNamespace

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to apply PV/PVC manifests"
    }
    Write-ColorOutput "Storage manifests applied" "Success"

    Write-ColorOutput "Waiting for PVC to be bound..." "Info"
    $maxRetries = 30
    $retryCount = 0

    while ($retryCount -lt $maxRetries) {
        $pvcStatus = kubectl get pvc story-pvc -n $KubeNamespace -o jsonpath='{.status.phase}' 2>$null

        if ($pvcStatus -eq "Bound") {
            Write-ColorOutput "PVC is bound" "Success"
            break
        }

        $retryCount++
        if ($retryCount -eq $maxRetries) {
            Write-ColorOutput "Warning: PVC not bound after 30 seconds, continuing..." "Warning"
        }
        else {
            Start-Sleep -Seconds 1
        }
    }

    Write-ColorOutput "Applying Deployment..." "Info"
    kubectl apply -f "$k8sDir/deployment.yaml" -n $KubeNamespace

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to apply Deployment manifest"
    }
    Write-ColorOutput "Deployment manifest applied" "Success"

    Write-ColorOutput "Applying Service..." "Info"
    kubectl apply -f "$k8sDir/service.yaml" -n $KubeNamespace

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to apply Service manifest"
    }
    Write-ColorOutput "Service manifest applied" "Success"
    Write-ColorOutput ""

    Write-ColorOutput "Step 5: Waiting for deployment to be ready..." "Info"

    $deploymentName = "story-app"
    $maxRetries = 60
    $retryCount = 0

    while ($retryCount -lt $maxRetries) {
        $readyReplicas = kubectl get deployment $deploymentName -n $KubeNamespace -o jsonpath='{.status.readyReplicas}' 2>$null
        $desiredReplicas = kubectl get deployment $deploymentName -n $KubeNamespace -o jsonpath='{.spec.replicas}' 2>$null

        if ($readyReplicas -eq $desiredReplicas -and $readyReplicas -gt 0) {
            Write-ColorOutput "Deployment is ready ($readyReplicas/$desiredReplicas replicas)" "Success"
            break
        }

        $retryCount++
        if ($retryCount -eq $maxRetries) {
            Write-ColorOutput "Warning: Deployment not fully ready after 60 seconds" "Warning"
        }
        else {
            Start-Sleep -Seconds 1
        }
    }
    Write-ColorOutput ""

    Write-ColorOutput "Step 6: Deployment Information" "Info"
    Write-ColorOutput "========================================" "Info"

    $nodePort = kubectl get svc story-app-service -n $KubeNamespace -o jsonpath='{.spec.ports[0].nodePort}' 2>$null
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
    Write-ColorOutput "1. Find your kubeadm node's IP address (INTERNAL-IP column above)" "Info"
    Write-ColorOutput "2. Open browser: http://<NODE-IP>:$nodePort" "Info"
    Write-ColorOutput ""

    Write-ColorOutput "========================================" "Success"
    Write-ColorOutput "Deployment completed successfully!" "Success"
    Write-ColorOutput "========================================" "Success"

}
catch {
    Write-ColorOutput "ERROR: $_" "Error"
    exit 1
}
