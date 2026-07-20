$filePath = "d:\xampp\htdocs\medinote\lib\views\prescription_screen.dart"
$lines = Get-Content $filePath -Encoding UTF8
$keepLines = @()
$startDel = 3091
$endDel = 3929

for ($i = 0; $i -lt $lines.Length; $i++) {
    $lineNum = $i + 1
    if ($lineNum -lt $startDel -or $lineNum -gt $endDel) {
        $keepLines += $lines[$i]
    }
}

$keepLines | Set-Content $filePath -Encoding UTF8
Write-Host "Done. Removed lines $startDel-$endDel. Total lines now: $($keepLines.Length)"
