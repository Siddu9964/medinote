$filePath = "d:\xampp\htdocs\medinote\lib\views\prescription_screen.dart"
$content = Get-Content $filePath -Raw -Encoding UTF8

# 1. Add editTimings to the top of the _rxMedCard
$rxMedCardTopOld = @"
    ];
    String editFreq = editFreqs.contains(med['freq']) ? med['freq']! : '1-0-1';
    String editDur = editDurs.contains(med['duration']) ? med['duration']! : '3 Days';

    return Dismissible(
"@
$rxMedCardTopNew = @"
    ];
    List<String> editTimings = ['Before Food', 'After Food', 'Empty Stomach'];
    String editFreq = editFreqs.contains(med['freq']) ? med['freq']! : '1-0-1';
    String editDur = editDurs.contains(med['duration']) ? med['duration']! : '3 Days';
    String editTiming = editTimings.contains(med['foodTiming']) ? med['foodTiming']! : 'After Food';

    return Dismissible(
"@
$content = $content.Replace($rxMedCardTopOld, $rxMedCardTopNew)

# 2. Add the Food Timing edit column
$durationColumnOld = @"
                            // Duration edit
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Duration', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
                                  const SizedBox(height: 4),
                                  StatefulBuilder(
                                    builder: (ctx, setD) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: editDur,
                                          isExpanded: true,
                                          isDense: true,
                                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
                                          items: editDurs.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                          onChanged: (v) {
                                            setD(() => editDur = v!);
                                            setState(() {
                                              final i = _prescribedMeds.indexWhere((m) => m['id'] == stableId);
                                              if (i != -1) _prescribedMeds[i]['duration'] = v!;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
"@
$durationColumnNew = @"
                            // Duration edit
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Duration', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
                                  const SizedBox(height: 4),
                                  StatefulBuilder(
                                    builder: (ctx, setD) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: editDur,
                                          isExpanded: true,
                                          isDense: true,
                                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
                                          items: editDurs.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                          onChanged: (v) {
                                            setD(() => editDur = v!);
                                            setState(() {
                                              final i = _prescribedMeds.indexWhere((m) => m['id'] == stableId);
                                              if (i != -1) _prescribedMeds[i]['duration'] = v!;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Food Timing edit
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Timing', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
                                  const SizedBox(height: 4),
                                  StatefulBuilder(
                                    builder: (ctx, setT) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: editTiming,
                                          isExpanded: true,
                                          isDense: true,
                                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFC026D3)),
                                          items: editTimings.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                                          onChanged: (v) {
                                            setT(() => editTiming = v!);
                                            setState(() {
                                              final i = _prescribedMeds.indexWhere((m) => m['id'] == stableId);
                                              if (i != -1) _prescribedMeds[i]['foodTiming'] = v!;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
"@
$content = $content.Replace($durationColumnOld, $durationColumnNew)

$content | Set-Content $filePath -Encoding UTF8
Write-Host "Replaced UI portions."
