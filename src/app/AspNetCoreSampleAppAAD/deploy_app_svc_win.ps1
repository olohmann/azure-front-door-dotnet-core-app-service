#!/usr/bin/env pwsh
#Requires -PSEdition Core

param
(
    [Parameter(Mandatory = $true)]
    [ValidateLength(1,255)]
    [ValidateNotNull()]
    [string]
    $AppServiceName,

    [Parameter(Mandatory = $true)]
    [ValidateLength(1,255)]
    [ValidateNotNull()]
    [string]
    $AppServiceResourceGroupName
)

Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

function BuildAndPublish {
    Write-Host "Running Build and Publish"
    dotnet publish -o out
    if ($LastExitCode -gt 0) { throw "dotnet build error" }
    
    Push-Location
    Set-Location ./out
    zip -r app.zip .
    if ($LastExitCode -gt 0) { throw "zip error" }
    
    az webapp deployment source config-zip --resource-group $AppServiceResourceGroupName --name $AppServiceName --src app.zip
    if ($LastExitCode -gt 0) { throw "az cli error" }

    Pop-Location
    Remove-Item -Force -Recurse ./out
}

BuildAndPublish
