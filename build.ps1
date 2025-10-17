
$bundle_path = "./bundle"
$src = "./src"
$re_path = "reframework/autorun"
$replace_text = "-- {{INJECT_UTILS}} --"

$plugin_files = @("display_hitboxes.lua", "display_info.lua")
$utils_src = [IO.File]::ReadAllText("src/utils.lua")

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

Reset-Directory $bundle_path

foreach ($file in $plugin_files) {
    Write-Host "Bulding: $file"
    $file = Get-Item $file
    $plugin_dir = Join $bundle_path $file.BaseName
    $plugin_path = Join $plugin_dir $re_path
    Reset-Directory $plugin_path

    $plugin_path = Join $plugin_path $file.Name
    Copy-Item -Path $file.FullName -Destination $plugin_path

    $content = [IO.File]::ReadAllText($plugin_path).Replace($replace_text, $utils_src)
    [IO.File]::WriteAllText($plugin_path, $content)

    $zip_file = Join $bundle_path "$($file.BaseName).zip"
    Compress-Archive -Force $plugin_dir/* $zip_file
    Remove-Item -Force -Recurse -Path $plugin_dir
}
