$filePath = "d:\xampp\htdocs\medinote\lib\views\prescription_screen.dart"
$content = Get-Content $filePath -Raw -Encoding UTF8

$oldQuickAdd1 = @"
                                    _prescribedMeds.add({'id': (_medIdCounter++).toString(), 'name': name, 'dosage': info.defDosage, 'freq': info.defFreq, 'duration': info.defDuration, 'category': info.category, 'brands': info.brands});
"@
$newQuickAdd1 = @"
                                    _prescribedMeds.add({'id': (_medIdCounter++).toString(), 'name': name, 'dosage': info.defDosage, 'freq': info.defFreq, 'duration': info.defDuration, 'foodTiming': _selectedFoodTiming, 'category': info.category, 'brands': info.brands});
"@
$content = $content.Replace($oldQuickAdd1, $newQuickAdd1)

$oldQuickAdd2 = @"
                                          _prescribedMeds.add({'id': (_medIdCounter++).toString(), 'name': s, 'dosage': info.defDosage, 'freq': info.defFreq, 'duration': info.defDuration, 'category': info.category, 'brands': info.brands});
"@
$newQuickAdd2 = @"
                                          _prescribedMeds.add({'id': (_medIdCounter++).toString(), 'name': s, 'dosage': info.defDosage, 'freq': info.defFreq, 'duration': info.defDuration, 'foodTiming': _selectedFoodTiming, 'category': info.category, 'brands': info.brands});
"@
$content = $content.Replace($oldQuickAdd2, $newQuickAdd2)

$content | Set-Content $filePath -Encoding UTF8
Write-Host "Replaced quick add portions."
