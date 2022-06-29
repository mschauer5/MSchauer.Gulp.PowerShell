function Set-Version {
    $workingDirectory = (Get-Item .).FullName;

    $json_package_path = $workingDirectory + '\package.json';
    $json_package = Get-Content -Raw -Path $json_package_path | ConvertFrom-Json;

    $version = $json_package.version;

    # Looks for the contants.json file so it can update the version from the package version for code reference
    $json_constants_path = $workingDirectory + '\src\shared\constants\constants.json';
    $json_constants_exists = Test-Path -Path $json_constants_path -PathType Leaf
    if ($json_constants_exists) {
        $json_constants = Get-Content -Raw -Path $json_constants_path | ConvertFrom-Json;
        $json_constants.version = $version
        $json_constants | ConvertTo-Json -depth 32 | set-content $json_constants_path
        Write-Host `Constants version set to $version`
    }

     # Looks for the package-solution.json file so it can update the version from the package version for SharePoint
    $json_package_solution_path = $workingDirectory + '\config\package-solution.json';
    $json_package_solution = Get-Content -Raw -Path $json_package_solution_path | ConvertFrom-Json;

    $json_package_solution.solution.version = $version + '.0'
    $json_package_solution | ConvertTo-Json -depth 32 | set-content $json_package_solution_path
    Write-Host `Set SharePoint Version set to $version'.0'`
}

function gulp.bundle {
    param(
    [string] $WorkDirectory
  )
    If($PSBoundParameters.ContainsKey("WorkDirectory")) {
        Set-Location $WorkDirectory
    }

    Set-Version

    $command = 'gulp clean';
    Invoke-Expression $command;
    $command = 'gulp bundle --ship';
    Invoke-Expression $command;
    $command = 'gulp package-solution --ship';
    Invoke-Expression $command;

}

function gulp.ext {
 $jsondata = Get-Content -Raw -Path 'config/serve.json' | ConvertFrom-Json
 $pageUrl = $jsondata.serveConfigurations.default.pageUrl;
 $customAction = $jsondata.serveConfigurations.default.customActions;
 $guid = ($customAction | get-member)[-1].Name

 $props = $customAction.$guid |  Select-Object -ExpandProperty 'properties'

 $properties = '';
 foreach ($Property in $props.PSObject.Properties) {
     $properties += '"' + $Property.Name + '":' + '"' + $Property.Value + '",'
 }

 $properties = $properties.TrimEnd(',')

 $url = $pageUrl + '?debugManifestsFile=https://localhost:4321/temp/manifests.js&loadSPFX=true&customActions={"' + $guid + '":{"location":"ClientSideExtension.ApplicationCustomizer","properties":{'+ $properties +'}}}';


Start-Process $url;
}

function gulp.serve {
    $command = 'npm run serve';
    Invoke-Expression $command;
  }

  Export-ModuleMember -Function gulp.serve
  Export-ModuleMember -Function gulp.bundle
  Export-ModuleMember -Function gulp.ext