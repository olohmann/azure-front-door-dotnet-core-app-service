#!/usr/bin/env pwsh
#Requires -PSEdition Core

param 
(
    [Parameter(Mandatory = $true)]
    [ValidateLength(1,255)]
    [ValidateNotNull()]
    [string]
    $RegistryName,
    
    [Parameter(Mandatory = $true)]
    [ValidateLength(1,255)]
    [ValidateNotNull()]
    [string]
    $AppServiceName,
    
    [Parameter(Mandatory = $true)]
    [ValidateLength(1,255)]
    [ValidateNotNull()]
    [string]
    $AppServiceResourceGroupName,

    [Parameter(Mandatory = $false)]
    [ValidateLength(1,255)]
    [ValidateNotNull()]
    [string]
    $Tag = "latest",

    [Switch]
    $SkipDockerBuild,

    [Switch]
    $SkipDeploy
)

Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"


function RunAcrBuild {
    Write-Host "Running ACR Docker Build (and Push)"
    
    Write-Host "Building Image"
    az acr build -r $RegistryName -t "$($RegistryName).azurecr.io/py-app:$($Tag)" .
    if ($LastExitCode -gt 0) { throw "acr docker build error" }
}

function ConfigureAppService {
    Write-Host "Configure App Service with Docker Image"
    az webapp config container set --name "$AppServiceName" --resource-group "$AppServiceResourceGroupName" --docker-custom-image-name "$($RegistryName).azurecr.io/py-app:$($Tag)"
    if ($LastExitCode -gt 0) { throw "acr webapp config error" }
}

if (!$SkipDockerBuild) {
    RunAcrBuild
}

if (!$SkipDeploy) {
    ConfigureAppService
}
