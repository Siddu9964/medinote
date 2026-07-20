$targetDir = "d:\xampp\htdocs\medinote\lib"

$replacements = @{
    "0xFF112B21" = "0xFF1F6B4A"
    "0xFF1A2B24" = "0xFF1F6B4A"
    "0xFF031A19" = "0xFF1F6B4A"
    "0xFF0D9488" = "0xFF1F6B4A"
    "0xFF14B8A6" = "0xFF1F6B4A"
    "0xFF2DD4BF" = "0xFF1F6B4A"
    "0xFF006064" = "0xFF1F6B4A"
    "0xFF26A69A" = "0xFF1F6B4A"
    "0xFF1FAE9A" = "0xFF1F6B4A"
    "0xFF4FD1C5" = "0xFF1F6B4A"
    
    "0xFFF0F4F8" = "0xFFF3EFE6"
    "0xFFF8FAFC" = "0xFFF3EFE6"
    "0xFFF1F5F9" = "0xFFF3EFE6"
    "0xFFF0FFF4" = "0xFFF3EFE6"
}

Get-ChildItem -Path $targetDir -Filter "*.dart" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $modified = $false
    
    foreach ($key in $replacements.Keys) {
        if ($content -match $key) {
            $content = $content -replace $key, $replacements[$key]
            $modified = $true
        }
    }
    
    if ($modified) {
        Set-Content -Path $_.FullName -Value $content
        Write-Host "Updated $($_.FullName)"
    }
}
Write-Host "Done!"
