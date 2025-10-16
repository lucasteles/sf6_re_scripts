
$bundle_path = ".\bundle"
$src = ".\src"
$re_path = "reframework\autorun"
$plugin_files = @("display_hitboxes.lua", "display_info.lua")
$utils_files = @("utils.lua")

function Reset-Directory($path) {
    if (Test-Path $path -PathType Leaf) { throw "Path '$path' is not a directory" }
    if (Test-Path $path) { Remove-Item -Force -Recurse -Path $path }
    New-Item -ItemType Directory -Path $path | Out-Null
}
function Join() {
    param (
        [parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [string[]] $paths
    )
    return [IO.Path]::Combine($paths)
}

[array] $plugin_files = $plugin_files | ForEach-Object { Join $src $_ }
[array] $utils_files = $utils_files | ForEach-Object { Join $src $_ }

Reset-Directory $bundle_path

foreach ($file in $plugin_files) {
    Write-Host "Bulding: $file"
    $file = Get-Item $file
    $plugin_dir = Join $bundle_path $file.BaseName
    $plugin_path = Join $plugin_dir $re_path
    Reset-Directory $plugin_path

    Copy-Item -Path @($utils_files + $file.FullName) -Destination $plugin_path

    $zip_file = Join $bundle_path "$($file.BaseName).zip"
    Compress-Archive -Force $plugin_dir/* $zip_file
    Remove-Item -Force -Recurse -Path $plugin_dir
}
