import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as ml;
import 'package:http/http.dart' as http;
import '../models/appointment.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';
import '../utils/constants.dart';
import '../drawing/drawing_controller.dart';
import '../drawing/drawing_canvas.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_mlkit_translation/google_mlkit_translation.dart'
    as trans;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as ml;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

// -------------------------------------------------------------
// V4 DESIGN SYSTEM CONSTANTS
// -------------------------------------------------------------
const Color _v4PrimaryGreen = Color(0xFF1F6B4A);
const Color _v4CreamBg = Color(0xFFF3EFE6);
const Color _v4Success = Color(0xFF2E8B57);
const Color _v4Warning = Color(0xFFF59E0B);
const Color _v4Error = Color(0xFFDC2626);
const Color _v4Divider = Color(0xFFE8DED0);
const Color _v4TextPrimary = Color(0xFF24332A);
const Color _v4TextSecondary = Color(0xFF6E6E6E);
const Color _v4White = Color(0xFFFFFFFF);

final String _openAiApiKey = dotenv.env['OPENAI_API_KEY'] ?? "";

// -------------------------------------------------------------
// CUSTOM HIGHLIGHTING CONTROLLER
// -------------------------------------------------------------
class HighlightingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<InlineSpan> children = [];
    final RegExp regExp = RegExp(r'::(.*?)::');
    int start = 0;

    regExp.allMatches(text).forEach((match) {
      if (match.start > start) {
        children.add(
          TextSpan(text: text.substring(start, match.start), style: style),
        );
      }
      children.add(
        TextSpan(
          text: match.group(1),
          style: style?.copyWith(
            backgroundColor: Colors.yellow.withValues(alpha: 0.5),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      );
      start = match.end;
    });

    if (start < text.length) {
      children.add(TextSpan(text: text.substring(start), style: style));
    }

    return TextSpan(children: children, style: style);
  }
}

// -------------------------------------------------------------
//  MEDICINE DATABASE (common Indian medicines)
// -------------------------------------------------------------
class MedInfo {
  final String generic;
  final String brands; // comma-separated brand names
  final String category;
  final String defDosage;
  final String defFreq;
  final String defDuration;
  final Color catColor;

  const MedInfo({
    required this.generic,
    required this.brands,
    required this.category,
    required this.defDosage,
    required this.defFreq,
    required this.defDuration,
    required this.catColor,
  });
}

const List<MedInfo> kMedicineDb = [
  // -- Analgesics / Antipyretics
  MedInfo(
    generic: 'Paracetamol',
    brands:
        'Dolo 650, Dolo 500, Calpol 650, Calpol 500, Crocin 650, Crocin Advance, Tylenol, Febrex Plus, Pacimol, Pyrigesic',
    category: 'Analgesic',
    defDosage: '650mg',
    defFreq: '1-0-1',
    defDuration: '3 Days',
    catColor: Color(0xFFE53E3E),
  ),
  MedInfo(
    generic: 'Ibuprofen',
    brands: 'Brufen 400, Brufen 200, Advil, Combiflam, Ibugesic Plus, Nurofen',
    category: 'Analgesic',
    defDosage: '400mg',
    defFreq: '1-0-1',
    defDuration: '5 Days',
    catColor: Color(0xFFE53E3E),
  ),
  MedInfo(
    generic: 'Diclofenac',
    brands: 'Voveran 50, Voveran SR, Voltaren, Voltaflam, Dynapar, Reactin',
    category: 'Analgesic',
    defDosage: '50mg',
    defFreq: '1-0-1',
    defDuration: '5 Days',
    catColor: Color(0xFFE53E3E),
  ),
  MedInfo(
    generic: 'Aceclofenac',
    brands: 'Zerodol P, Zerodol SP, Hifenac P, Acenac, Aceclo Plus, Dolowin',
    category: 'Analgesic',
    defDosage: '100mg',
    defFreq: '1-0-1',
    defDuration: '5 Days',
    catColor: Color(0xFFE53E3E),
  ),
  MedInfo(
    generic: 'Tramadol',
    brands: 'Contramal, Ultram, Tramazac, Dolonex',
    category: 'Analgesic',
    defDosage: '50mg',
    defFreq: '0-0-1',
    defDuration: '3 Days',
    catColor: Color(0xFFE53E3E),
  ),
  MedInfo(
    generic: 'Ketorolac',
    brands: 'Toradol, Ketanov, Ketosyn, Ketoflam',
    category: 'Analgesic',
    defDosage: '10mg',
    defFreq: '1-0-1',
    defDuration: '5 Days',
    catColor: Color(0xFFE53E3E),
  ),
  // -- Antibiotics
  MedInfo(
    generic: 'Amoxicillin',
    brands: 'Novamox 500, Mox 500, Amoxil, Wymox, Trimox',
    category: 'Antibiotic',
    defDosage: '500mg',
    defFreq: '1-1-1',
    defDuration: '7 Days',
    catColor: Color(0xFFD97706),
  ),
  MedInfo(
    generic: 'Azithromycin',
    brands:
        'Azithral 500, Azithral 250, Zithromax, Azee 500, Zycin, Atm, Azifast, Azibact',
    category: 'Antibiotic',
    defDosage: '500mg',
    defFreq: '1-0-0',
    defDuration: '5 Days',
    catColor: Color(0xFFD97706),
  ),
  MedInfo(
    generic: 'Amoxicillin+Clavulanate',
    brands:
        'Augmentin 625, Augmentin 1000, Clavet 625, Amoxyclav 625, Clavam 625',
    category: 'Antibiotic',
    defDosage: '625mg',
    defFreq: '1-0-1',
    defDuration: '7 Days',
    catColor: Color(0xFFD97706),
  ),
  MedInfo(
    generic: 'Ciprofloxacin',
    brands: 'Ciplox 500, Ciprodac 500, Cifran 500, Ciproxin, Zoxan',
    category: 'Antibiotic',
    defDosage: '500mg',
    defFreq: '1-0-1',
    defDuration: '7 Days',
    catColor: Color(0xFFD97706),
  ),
  MedInfo(
    generic: 'Doxycycline',
    brands: 'Doxolin, Biodoxi, Vibramycin, Doxt SL, Doxy 100',
    category: 'Antibiotic',
    defDosage: '100mg',
    defFreq: '1-0-1',
    defDuration: '7 Days',
    catColor: Color(0xFFD97706),
  ),
  MedInfo(
    generic: 'Metronidazole',
    brands: 'Flagyl 400, Metrogyl 400, Aldezol 400, Metron, Aristogyl',
    category: 'Antibiotic',
    defDosage: '400mg',
    defFreq: '1-1-1',
    defDuration: '5 Days',
    catColor: Color(0xFFD97706),
  ),
  MedInfo(
    generic: 'Cefixime',
    brands: 'Taxim-O 200, Taxim-O 100, Zifi 200, Cefolac, Topcef, Supacef',
    category: 'Antibiotic',
    defDosage: '200mg',
    defFreq: '1-0-1',
    defDuration: '7 Days',
    catColor: Color(0xFFD97706),
  ),
  MedInfo(
    generic: 'Levofloxacin',
    brands: 'Levoflox 500, Tavanic 500, Levocin, Liqforce, L-Cin',
    category: 'Antibiotic',
    defDosage: '500mg',
    defFreq: '1-0-0',
    defDuration: '7 Days',
    catColor: Color(0xFFD97706),
  ),
  MedInfo(
    generic: 'Cefpodoxime',
    brands: 'Cepodem, Pedpod, Cepdoz, Moxikind, Cefoprox',
    category: 'Antibiotic',
    defDosage: '200mg',
    defFreq: '1-0-1',
    defDuration: '7 Days',
    catColor: Color(0xFFD97706),
  ),
  // -- Antacids / GI
  MedInfo(
    generic: 'Omeprazole',
    brands: 'Omez 20, Prilosec, Lomac, Omifast, Belmazol',
    category: 'Antacid',
    defDosage: '20mg',
    defFreq: '1-0-0',
    defDuration: '1 Week',
    catColor: Color(0xFF059669),
  ),
  MedInfo(
    generic: 'Pantoprazole',
    brands: 'Pan 40, Pantocid 40, Pantocar, Pantop 40, P-Zole, Pantex',
    category: 'Antacid',
    defDosage: '40mg',
    defFreq: '1-0-0',
    defDuration: '2 Weeks',
    catColor: Color(0xFF059669),
  ),
  MedInfo(
    generic: 'Pantoprazole+Domperidone',
    brands: 'Pan D, Pantocid D, Pantowin, Rantac D, Nexpro D',
    category: 'Antacid',
    defDosage: '40mg',
    defFreq: '1-0-1',
    defDuration: '1 Week',
    catColor: Color(0xFF059669),
  ),
  MedInfo(
    generic: 'Rabeprazole',
    brands: 'Razo 20, Rablet 20, Raciper, Rabium, Rabiloz',
    category: 'Antacid',
    defDosage: '20mg',
    defFreq: '1-0-0',
    defDuration: '1 Week',
    catColor: Color(0xFF059669),
  ),
  MedInfo(
    generic: 'Domperidone',
    brands: 'Domstal 10, Motilium, Domcet, Domperi, Domped',
    category: 'Antacid',
    defDosage: '10mg',
    defFreq: '1-1-1',
    defDuration: '5 Days',
    catColor: Color(0xFF059669),
  ),
  MedInfo(
    generic: 'Ondansetron',
    brands: 'Emeset 4, Emeset 8, Vomistop, Zofran, Ondem, Emetrol',
    category: 'Antacid',
    defDosage: '4mg',
    defFreq: '1-0-1',
    defDuration: '3 Days',
    catColor: Color(0xFF059669),
  ),
  MedInfo(
    generic: 'Ranitidine',
    brands: 'Rantac 150, Aciloc 150, Zinetac 150, Histac, Ranidom',
    category: 'Antacid',
    defDosage: '150mg',
    defFreq: '1-0-1',
    defDuration: '2 Weeks',
    catColor: Color(0xFF059669),
  ),
  // -- Antihistamines
  MedInfo(
    generic: 'Cetirizine',
    brands: 'Cetzine 10, Alerid 10, Zyrtec, Okacet, Cetcip, L-Cet',
    category: 'Antihistamine',
    defDosage: '10mg',
    defFreq: '0-0-1',
    defDuration: '7 Days',
    catColor: Color(0xFF7C3AED),
  ),
  MedInfo(
    generic: 'Levocetirizine',
    brands: 'Vozet 5, Levoril 5, Xyzal, Levucin, Teczine',
    category: 'Antihistamine',
    defDosage: '5mg',
    defFreq: '0-0-1',
    defDuration: '7 Days',
    catColor: Color(0xFF7C3AED),
  ),
  MedInfo(
    generic: 'Loratadine',
    brands: 'Lorfast 10, Lorastine, Clarityne, Loratin, Clarinase',
    category: 'Antihistamine',
    defDosage: '10mg',
    defFreq: '1-0-0',
    defDuration: '7 Days',
    catColor: Color(0xFF7C3AED),
  ),
  MedInfo(
    generic: 'Fexofenadine',
    brands: 'Allegra 120, Allegra 180, Fexova, Telekast, Fexo',
    category: 'Antihistamine',
    defDosage: '120mg',
    defFreq: '1-0-0',
    defDuration: '7 Days',
    catColor: Color(0xFF7C3AED),
  ),
  MedInfo(
    generic: 'Montelukast+Levocetirizine',
    brands: 'Montair LC, Extor L, Montek LC, Alerid M, Lezyncet',
    category: 'Antihistamine',
    defDosage: '10mg',
    defFreq: '0-0-1',
    defDuration: '2 Weeks',
    catColor: Color(0xFF7C3AED),
  ),
  // -- Antidiabetics
  MedInfo(
    generic: 'Metformin',
    brands: 'Glycomet 500, Glycomet SR, Glucophage, Bigomet, Eclimet',
    category: 'Antidiabetic',
    defDosage: '500mg',
    defFreq: '1-0-1',
    defDuration: '1 Month',
    catColor: Color(0xFF2563EB),
  ),
  MedInfo(
    generic: 'Glimepiride',
    brands: 'Amaryl 2mg, Glimer, Triglynase, Glimpid, Glimisave',
    category: 'Antidiabetic',
    defDosage: '2mg',
    defFreq: '1-0-0',
    defDuration: '1 Month',
    catColor: Color(0xFF2563EB),
  ),
  MedInfo(
    generic: 'Sitagliptin',
    brands: 'Januvia 100, Istavel, Janumet, Sitaglu',
    category: 'Antidiabetic',
    defDosage: '100mg',
    defFreq: '1-0-0',
    defDuration: '1 Month',
    catColor: Color(0xFF2563EB),
  ),
  // -- Antihypertensives
  MedInfo(
    generic: 'Amlodipine',
    brands: 'Amlokind 5, Amlong 5, Norvasc, Stamlo, Amlosafe',
    category: 'Antihypertensive',
    defDosage: '5mg',
    defFreq: '1-0-0',
    defDuration: '1 Month',
    catColor: Color(0xFFDB2777),
  ),
  MedInfo(
    generic: 'Atenolol',
    brands: 'Aten 50, Betacard 50, Tenormin, Betazok, Atenol',
    category: 'Antihypertensive',
    defDosage: '50mg',
    defFreq: '1-0-0',
    defDuration: '1 Month',
    catColor: Color(0xFFDB2777),
  ),
  MedInfo(
    generic: 'Losartan',
    brands: 'Repace 50, Losar 50, Cozaar, Losacar, Sartan',
    category: 'Antihypertensive',
    defDosage: '50mg',
    defFreq: '1-0-0',
    defDuration: '1 Month',
    catColor: Color(0xFFDB2777),
  ),
  MedInfo(
    generic: 'Telmisartan',
    brands: 'Telma 40, Telsartan 40, Micardis, Telmikind, Cresar',
    category: 'Antihypertensive',
    defDosage: '40mg',
    defFreq: '1-0-0',
    defDuration: '1 Month',
    catColor: Color(0xFFDB2777),
  ),
  // -- Vitamins / Supplements
  MedInfo(
    generic: 'Vitamin D3',
    brands: 'Calcirol 60K, Tayo 60K, D-Cal, Uprise D3, Arachitol',
    category: 'Vitamin',
    defDosage: '60000 IU',
    defFreq: '1-0-0',
    defDuration: '4 Weeks',
    catColor: Color(0xFF0891B2),
  ),
  MedInfo(
    generic: 'Vitamin B12',
    brands:
        'Neurobion Forte, Cobadex Forte, Mecobalamin 500, Mecord, Methycobal',
    category: 'Vitamin',
    defDosage: '500mcg',
    defFreq: '1-0-0',
    defDuration: '1 Month',
    catColor: Color(0xFF0891B2),
  ),
  MedInfo(
    generic: 'Calcium+D3',
    brands: 'Shelcal 500, Calcimax 500, Corcal, Caldikind, Calcitas',
    category: 'Vitamin',
    defDosage: '500mg',
    defFreq: '0-1-0',
    defDuration: '1 Month',
    catColor: Color(0xFF0891B2),
  ),
  MedInfo(
    generic: 'Iron+Folic Acid',
    brands: 'Feronia XT, Fefol, Autrin, Livogen, Ferro 200',
    category: 'Vitamin',
    defDosage: '150mg',
    defFreq: '0-1-0',
    defDuration: '1 Month',
    catColor: Color(0xFF0891B2),
  ),
  // -- Respiratory
  MedInfo(
    generic: 'Salbutamol',
    brands: 'Asthalin 4mg, Asthalin Inhaler, Ventolin, Salbetol, Salmaplon',
    category: 'Respiratory',
    defDosage: '4mg',
    defFreq: '1-1-1',
    defDuration: '5 Days',
    catColor: Color(0xFF1F6B4A),
  ),
  MedInfo(
    generic: 'Montelukast',
    brands: 'Montair 10, Singulair, Montek 10, Asthafen, Montec',
    category: 'Respiratory',
    defDosage: '10mg',
    defFreq: '0-0-1',
    defDuration: '1 Month',
    catColor: Color(0xFF1F6B4A),
  ),
  MedInfo(
    generic: 'Ambroxol',
    brands: 'Ambril, Mucosolvan, Ambrex, Mucaine, Ambrodil',
    category: 'Respiratory',
    defDosage: '30mg',
    defFreq: '1-1-1',
    defDuration: '5 Days',
    catColor: Color(0xFF1F6B4A),
  ),
  MedInfo(
    generic: 'Budesonide',
    brands: 'Budamate, Pulmicort, Symbicort, Foracort, Budenase',
    category: 'Respiratory',
    defDosage: '200mcg',
    defFreq: '1-0-1',
    defDuration: '1 Month',
    catColor: Color(0xFF1F6B4A),
  ),
  // -- Musculoskeletal
  MedInfo(
    generic: 'Tizanidine',
    brands: 'Sirdalud 4mg, Tizan 4mg, Nuflex, Tizpa, Tizan 2mg',
    category: 'Muscle Relaxant',
    defDosage: '4mg',
    defFreq: '0-0-1',
    defDuration: '5 Days',
    catColor: Color(0xFFB45309),
  ),
  MedInfo(
    generic: 'Pregabalin',
    brands: 'Lyrica 75, Pregaba 75, Nervigesic, Pregalin, Maxgalin',
    category: 'Neuropathic',
    defDosage: '75mg',
    defFreq: '1-0-1',
    defDuration: '1 Month',
    catColor: Color(0xFFB45309),
  ),
  // -- Thyroid
  MedInfo(
    generic: 'Levothyroxine',
    brands: 'Eltroxin 50, Thyronorm 50, Synthroid, Thyrox 50, Thyroxine',
    category: 'Thyroid',
    defDosage: '50mcg',
    defFreq: '1-0-0',
    defDuration: '1 Month',
    catColor: Color(0xFF7C3AED),
  ),
];

// -------------------------------------------------------------
//  SUGGESTION RESULT  (brand-aware)
// -------------------------------------------------------------
class SuggestionResult {
  final String displayName; // what to show BIG (could be brand OR generic)
  final String subtitle; // secondary line
  final MedInfo medInfo;
  final bool isBrandMatch; // true ? user searched a brand name

  const SuggestionResult({
    required this.displayName,
    required this.subtitle,
    required this.medInfo,
    required this.isBrandMatch,
  });
}

// -------------------------------------------------------------
//  INK PAINTER  (ML handwriting in notes area)
// -------------------------------------------------------------
class InkPainter extends CustomPainter {
  final ml.Ink ink;
  InkPainter({required this.ink, required Listenable super.repaint});

  @override
  void paint(Canvas canvas, Size size) {
    if (ink.strokes.isEmpty) return;
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.4
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    for (final stroke in ink.strokes) {
      if (stroke.points.isEmpty) continue;
      final path = Path();
      final points = stroke.points;
      path.moveTo(points.first.x, points.first.y);

      if (points.length < 3) {
        // Just draw lines for very short strokes
        for (final p in points) {
          path.lineTo(p.x, p.y);
        }
      } else {
        // Quadratic bezier smoothing
        for (int i = 0; i < points.length - 1; i++) {
          final p1 = points[i];
          final p2 = points[i + 1];
          final mid = Offset((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
          path.quadraticBezierTo(p1.x, p1.y, mid.dx, mid.dy);
        }
        path.lineTo(points.last.x, points.last.y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant InkPainter oldDelegate) => false;
}

// -------------------------------------------------------------
//  PRESCRIPTION SCREEN
// -------------------------------------------------------------
class PrescriptionScreen extends StatefulWidget {
  final Appointment? appointment;
  final User? doctor;
  const PrescriptionScreen({super.key, this.appointment, this.doctor});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen>
    with TickerProviderStateMixin {
  // -- Colors ------------------------------------------------
  static const Color _teal = Color(0xFF1F6B4A);
  static const Color _tealLight = Color(0xFFE6F7F6);
  static const Color _slate = Color(0xFF1E293B);
  static const Color _slateLight = Color(0xFFF3EFE6);

  // -- Drawing engine ----------------------------------------
  late final DrawingController _drawCtrl;
  bool _isDrawingMode = true;
  static const double _exportPageHeight = 1100.0;
  static const double _exportPageWidth = 850.0;

  // -- ML Ink ------------------------------------------------
  final ml.DigitalInkRecognizer _digitalInkRecognizer = ml.DigitalInkRecognizer(
    languageCode: 'en',
  );
  final ml.Ink _ink = ml.Ink();
  bool _isInkRecognitionEnabled = true;
  Timer? _inkRecognitionTimer;
  final ChangeNotifier _inkRepaintNotifier = ChangeNotifier();
  final List<ml.Ink> _inkUndoStack = [];
  bool _isAIProcessing = false;
  String _patientContext = "Fetching patient history...";

  // -- Speech to Text ----------------------------------------
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords =
      ''; // The words currently being recognized (current segment)
  String _committedText = ''; // The finalized text before the current segment

  // -- Multi-Language & Translation --------------------------
  // Reverted to English-only as per user request for real-time performance
  bool _isModelDownloading = false;
  String _textBeforeSpeech = "";
  bool _showStylusInk = false;
  double _soundLevel = 0.0;
  String _sttStatus = "Ready";
  final FocusNode _notesFocusNode = FocusNode();
  List<String> _inkSuggestions = [];

  // -- Mode --------------------------------------------------
  bool _isDigitalMode = true;

  // -- Vitals panel -----------------------------------------
  bool _showVitalsPanel = false;

  // -- Vitals controllers ------------------------------------
  final TextEditingController _bpCtrl = TextEditingController();
  final TextEditingController _spo2Ctrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _tempCtrl = TextEditingController();
  final TextEditingController _pulseCtrl = TextEditingController();

  // ---------------------------------------------------------
  //  RX  Draggable Floating Card state
  // ---------------------------------------------------------
  bool _rxCardVisible = false;
  bool _rxCardInitialized = false;
  bool _rxCardMinimized = false;
  bool _rxCardPinned = false; // when true, card cannot be dragged
  Offset _rxCardOffset = Offset.zero;

  // -- Stable medicine IDs (fixes Dismissible crash) ---------
  int _medIdCounter = 0;
  final List<Map<String, String>> _prescribedMeds = [];
  final TextEditingController _medNameCtrl = TextEditingController();
  final TextEditingController _doseCtrl = TextEditingController(text: '500mg');
  String _selectedFreq = '1-0-1';
  String _selectedDuration = '3 Days';
  String _selectedFoodTiming = 'After Food';

  // -- Autocomplete state ------------------------------------
  List<MedInfo> _suggestions = []; // kept for compatibility
  List<SuggestionResult> _suggestionResults = [];
  bool _showSuggestions = false;
  MedInfo? _selectedMedInfo;
  Timer? _searchDebounce;
  bool _isSearchingMeds = false;

  // -- Recent medicines (last added generics, max 8) ---------
  final List<String> _recentMedicines = [];
  String _rxCategoryFilter = 'All';

  // -- Labs --------------------------------------------------
  List<Map<String, dynamic>> _allLabServices = [];
  bool _isLoadingLabs = true;
  String _selectedDept = 'Pathology';
  String _labSearchQuery = '';
  final List<String> _selectedTests = [];
  final TextEditingController _labSearchCtrl = TextEditingController();

  // -- Notes -------------------------------------------------
  final HighlightingController _notesCtrl = HighlightingController();

  // -- Misc --------------------------------------------------
  final ApiService _apiService = ApiService();
  bool _isSubmitting = false;
  late Appointment _appointment;
  late User _doctor;

  // -- Animations --------------------------------------------
  late AnimationController _vitalsAnimCtrl;
  late AnimationController _labAnimCtrl;
  late AnimationController _rxCardAnimCtrl;
  late Animation<double> _vitalsAnim;
  late Animation<double> _labAnim;
  late Animation<double> _rxCardAnim;
  bool _showLabPanel = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _drawCtrl = DrawingController();
    _initSpeech();
    _checkAndDownloadModels();
    // Rebuild only the toolbar badge / undo count when strokes change
    _drawCtrl.addListener(_onDrawingChanged);

    _fetchLabServices();

    _appointment =
        widget.appointment ??
        Appointment(
          appointmentId: 'APP-001',
          patientId: 'PAT-102',
          patientName: 'Guest Patient',
          phoneNumber: '000-000-0000',
          age: 'N/A',
          gender: 'N/A',
        );
    
    _populateVitals();
    
    _doctor =
        widget.doctor ??
        User(
          id: 'DOC-000',
          username: 'doctor',
          role: 'doctor',
          fullName: 'Doctor Name',
          specialization: 'General Physician',
        );

    _vitalsAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _labAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _rxCardAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _vitalsAnim = CurvedAnimation(
      parent: _vitalsAnimCtrl,
      curve: Curves.easeOutCubic,
    );
    _labAnim = CurvedAnimation(
      parent: _labAnimCtrl,
      curve: Curves.easeOutCubic,
    );
    _rxCardAnim = CurvedAnimation(
      parent: _rxCardAnimCtrl,
      curve: Curves.easeOutBack,
    );

    _medNameCtrl.addListener(_onMedNameChanged);
    _notesFocusNode.addListener(() {
      if (_notesFocusNode.hasFocus && _showStylusInk) {
        // Automatically hide stylus if user manually taps text field (optional but good)
        // setState(() => _showStylusInk = false);
      }
    });

    _fetchPatientContext();
  }

  Future<void> _fetchPatientContext() async {
    try {
      final records = await ApiService().getPrescriptionsRaw(patientId: _appointment.patientId);
      if (records.isNotEmpty) {
        final recent = records.first;
        setState(() {
          _patientContext = "Recent diagnosis: ${recent['diagnosis'] ?? 'None'}, Medicines: ${recent['medicines'] ?? 'None'}, Tests: ${recent['lab_tests'] ?? 'None'}";
        });
      } else {
        setState(() => _patientContext = "No prior history.");
      }
    } catch (e) {
      setState(() => _patientContext = "Failed to load history.");
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _inkRepaintNotifier.dispose();
    _drawCtrl.removeListener(_onDrawingChanged);
    _drawCtrl.dispose();
    _scrollController.dispose();
    _bpCtrl.dispose();
    _spo2Ctrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _tempCtrl.dispose();
    _notesCtrl.dispose();
    _notesFocusNode.dispose();
    _medNameCtrl.dispose();
    _doseCtrl.dispose();
    _labSearchCtrl.dispose();
    _digitalInkRecognizer.close();
    _vitalsAnimCtrl.dispose();
    _labAnimCtrl.dispose();
    _rxCardAnimCtrl.dispose();
    super.dispose();
  }

  void _populateVitals() {
    if (_appointment.vitalSigns != null && _appointment.vitalSigns!.isNotEmpty) {
      try {
        final vitals = json.decode(_appointment.vitalSigns!);
        if (vitals is Map) {
          _bpCtrl.text = (vitals['bp'] ?? vitals['BP'])?.toString() ?? '';
          _spo2Ctrl.text = (vitals['spo2'] ?? vitals['SPO2'])?.toString() ?? '';
          _tempCtrl.text = (vitals['temp'] ?? vitals['Temp'])?.toString() ?? '';
          _pulseCtrl.text = (vitals['pulse'] ?? vitals['Pulse'])?.toString() ?? '';
          _weightCtrl.text = (vitals['weight'] ?? vitals['Weight'])?.toString() ?? '';
        }
      } catch (e) {
        debugPrint("Error parsing vital_signs: $e");
      }
    }
  }

  // Only rebuild UI chrome (undo count, page selector)  NOT the canvas itself
  void _onDrawingChanged() => setState(() {});

  Future<void> _checkAndDownloadModels() async {
    setState(() => _isModelDownloading = true);
    try {
      // 1. Digital Ink model (English)
      final inkModelManager = ml.DigitalInkRecognizerModelManager();
      bool inkDownloaded = await inkModelManager.isModelDownloaded('en');
      if (!inkDownloaded) {
        await inkModelManager.downloadModel('en');
      }

      // 2. Translation models will be downloaded on-demand when language is changed
    } catch (e) {
      debugPrint("Model download error: $e");
    } finally {
      if (mounted) setState(() => _isModelDownloading = false);
    }
  }

  void _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (mounted) setState(() => _sttStatus = status);
          debugPrint("STT Status: $status");

          // Continuous listening logic:
          // If it stops but we still want it to be listening, restart it.
          if ((status == 'done' || status == 'notListening') && _isListening) {
            _restartTimeLimitedListening();
          }
        },
        onError: (err) {
          debugPrint("STT Error: $err");
          if (err.permanent) {
            if (mounted) setState(() => _isListening = false);
          } else {
            // For transient errors, try to restart if we should be listening
            if (_isListening) _restartTimeLimitedListening();
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Speech init error: $e");
    }
  }

  void _restartTimeLimitedListening() {
    // Small delay to let the engine fully clean up before restarting
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_isListening && mounted) {
        _startListening(isAutoRestart: true);
      }
    });
  }

  void _startListening({bool isAutoRestart = false}) async {
    if (!isAutoRestart && _isListening) return;

    // Fix: Always sync _committedText right before starting so manual typed edits are never overwritten.
    _committedText = _notesCtrl.text;
    _lastWords = '';

    if (!isAutoRestart) {
      if (mounted)
        setState(() {
          _isListening = true;
          _sttStatus = "Starting...";
        });
    }

    try {
      await _speech.listen(
        localeId: 'en-US',
        listenMode: stt.ListenMode.dictation,
        onDevice: false,
        listenFor: const Duration(hours: 1),
        pauseFor: const Duration(seconds: 20),
        onSoundLevelChange: (level) {
          if (mounted) setState(() => _soundLevel = level);
        },
        onResult: (val) {
          if (mounted) {
            setState(() {
              _lastWords = val.recognizedWords;
              final spacer = _committedText.isEmpty
                  ? ""
                  : (_committedText.endsWith(" ") ? "" : " ");
              _notesCtrl.text = "$_committedText$spacer$_lastWords";

              _notesCtrl.selection = TextSelection.fromPosition(
                TextPosition(offset: _notesCtrl.text.length),
              );

              // Fix: properly update committed baseline upon final segment completion
              if (val.finalResult) {
                _committedText = _notesCtrl.text;
                _lastWords = '';
              }
            });
          }
        },
      );
    } catch (e) {
      debugPrint("Listen error: $e");
      if (!isAutoRestart && mounted) setState(() => _isListening = false);
    }
  }

  void _stopListening() async {
    setState(() => _isListening = false);
    await _speech.stop();
  }

  // -------------------------------------------------------------
  //  BRAND-AWARE AUTOCOMPLETE
  // -------------------------------------------------------------

  /// Returns the first brand token from [med] that contains [query].
  String? _matchedBrand(MedInfo med, String query) {
    final q = query.toLowerCase();
    for (final brand in med.brands.split(',').map((b) => b.trim())) {
      if (brand.toLowerCase().contains(q)) return brand;
    }
    return null;
  }

  void _onMedNameChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    final raw = _medNameCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _suggestionResults = [];
        _showSuggestions = false;
        _selectedMedInfo = null;
        _isSearchingMeds = false;
      });
      return;
    }

    setState(() {
      _selectedMedInfo = null;
      _isSearchingMeds = true;
      _showSuggestions = true;
    });

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final query = _medNameCtrl.text.trim();
      if (query.isEmpty) return;

      final results = await _apiService.searchMedicines(query);
      if (!mounted) return;

      final List<SuggestionResult> newSuggestions = [];
      for (final r in results) {
        final String name = r['product_name'] ?? 'Unknown';
        final String strength = r['strength'] ?? '';
        final medInfo = MedInfo(
          generic: name,
          brands: '',
          category: 'General',
          defDosage: strength.isNotEmpty ? strength : '',
          defFreq: '1-0-1',
          defDuration: '3 Days',
          catColor: Colors.blueGrey,
        );
        newSuggestions.add(
          SuggestionResult(
            displayName: name,
            subtitle: strength.isNotEmpty
                ? 'Strength: $strength'
                : 'Generic Medicine',
            medInfo: medInfo,
            isBrandMatch: false,
          ),
        );
      }

      setState(() {
        _suggestionResults = newSuggestions;
        _isSearchingMeds = false;
      });
    });
  }

  void _selectSuggestion(SuggestionResult result) {
    setState(() {
      // Fill the field with the brand name if matched by brand, otherwise generic
      _medNameCtrl.text = result.displayName;
      _doseCtrl.text = result.medInfo.defDosage;
      _selectedMedInfo = result.medInfo;
      _selectedFreq = result.medInfo.defFreq;
      _selectedDuration = result.medInfo.defDuration;
      _suggestionResults = [];
      _showSuggestions = false;
    });
    HapticFeedback.selectionClick();
  }

  // Keep old _selectMedicine for compatibility with recent chips
  void _selectMedicine(MedInfo med) {
    setState(() {
      _medNameCtrl.text = med.generic;
      _doseCtrl.text = med.defDosage;
      _selectedMedInfo = med;
      _selectedFreq = med.defFreq;
      _selectedDuration = med.defDuration;
      _suggestionResults = [];
      _showSuggestions = false;
    });
    HapticFeedback.selectionClick();
  }

  void _showMedicineUnavailableDialog(String medName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.inventory_2_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text(
              'Product Not Found',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"$medName" is not in the store records.',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _slate,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This medicine is currently unavailable in our store inventory. Would you like to add it to the prescription anyway?',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blueGrey,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'SEARCH AGAIN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _executeAddMedicine(medName);
            },
            child: const Text(
              'ADD ANYWAY',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  void _addMedicine() {
    final name = _medNameCtrl.text.trim();
    if (name.isEmpty) return;

    // Standard check: If medicine is not verified from database, show the popup
    if (_selectedMedInfo == null) {
      _showMedicineUnavailableDialog(name);
      return;
    }

    _executeAddMedicine(name);
  }

  void _executeAddMedicine(String name) {
    HapticFeedback.lightImpact();
    setState(() {
      // Use a stable unique ID so Dismissible does not crash on reorder
      _prescribedMeds.add({
        'id': '${_medIdCounter++}', // <-- stable key
        'name': name,
        'dosage': _doseCtrl.text,
        'freq': _selectedFreq,
        'duration': _selectedDuration,
        'foodTiming': _selectedFoodTiming,
        'category': _selectedMedInfo?.category ?? 'General',
        'brands': _selectedMedInfo?.brands ?? '',
      });
      // Track recent (max 8)
      _recentMedicines.remove(name);
      _recentMedicines.insert(0, name);
      if (_recentMedicines.length > 8) _recentMedicines.removeLast();
      // Reset
      _medNameCtrl.clear();
      _selectedMedInfo = null;
      _showSuggestions = false;
    });
  }

  Future<void> _fetchLabServices() async {
    try {
      final services = await _apiService.getAllLabServices();
      if (mounted)
        setState(() {
          _allLabServices = services;
          _isLoadingLabs = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoadingLabs = false);
    }
  }

  // ---------------------------------------------------------
  //  DRAWING HELPERS  delegated to DrawingController
  // ---------------------------------------------------------
  void _addPage() {
    _drawCtrl.addPage();
    setState(() {});
  }

  void _removePage(int i) {
    _drawCtrl.removePage(i);
    setState(() {});
  }

  void _addInkPoint(Offset o) {
    if (_ink.strokes.isEmpty) return;
    _ink.strokes.last.points.add(
      ml.StrokePoint(
        x: o.dx,
        y: o.dy,
        t: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> _recognizeText() async {
    if (_ink.strokes.isEmpty) return;
    try {
      final candidates = await _digitalInkRecognizer.recognize(_ink);
      if (candidates.isNotEmpty) {
        final rawText = candidates.first.text;
        final candidateList = candidates.take(3).map((e) => e.text).toList();
        
        setState(() {
          _isAIProcessing = true;
          // Clear ink immediately so user can keep writing
          _ink.strokes.clear();
          _inkSuggestions.clear();
          _inkUndoStack.clear();
        });
        _inkRepaintNotifier.notifyListeners();

        // 2. Pass candidates to AI Contextual Correction Layer
        final aiResult = await _correctTextWithAI(candidateList);

        setState(() => _isAIProcessing = false);

        int confidence = aiResult['confidence'] ?? 100;
        String recognizedText = aiResult['recognized_text'] ?? rawText;
        List<String> alternatives = List<String>.from(aiResult['alternatives'] ?? []);

        if (confidence < 90 && alternatives.isNotEmpty) {
          _showAlternativesDialog(recognizedText, alternatives);
        } else {
          setState(() {
            if (_notesCtrl.text.isNotEmpty && !_notesCtrl.text.endsWith(' ') && !_notesCtrl.text.endsWith('\n')) {
              _notesCtrl.text += ' ';
            }
            _notesCtrl.text += recognizedText;
          });
        }
      }
    } catch (_) {
      setState(() => _isAIProcessing = false);
    }
  }

  void _showAlternativesDialog(String bestGuess, List<String> alternatives) {
    showDialog(
      context: context,
      builder: (context) {
        final allOptions = [bestGuess, ...alternatives].toSet().toList();
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: Container(
            width: 400,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: _v4Warning, size: 28),
                    const SizedBox(width: 12),
                    const Text('Low Confidence', style: TextStyle(color: _slate, fontWeight: FontWeight.w800, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('The handwritten stroke was unclear. Select the correct medical term:', style: TextStyle(color: _slate.withValues(alpha: 0.7), fontSize: 14)),
                const SizedBox(height: 24),
                ...allOptions.map((term) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          if (_notesCtrl.text.isNotEmpty && !_notesCtrl.text.endsWith(' ') && !_notesCtrl.text.endsWith('\n')) {
                            _notesCtrl.text += ' ';
                          }
                          _notesCtrl.text += term;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: _v4CreamBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _v4Divider),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(term, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _v4PrimaryGreen))),
                            const Icon(Icons.check_circle_outline, color: _v4PrimaryGreen),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }
    );
  }

  String _buildSystemPrompt() {
    return '''You are an expert Medical Prescription Recognition AI.
Your responsibility is to convert a doctor's handwritten prescription into the most accurate medical text possible.
This is NOT normal OCR. This is medical handwriting interpretation.

OBJECTIVE
Recognize exactly what the doctor intended to write.
Do not generate random English words. Always prioritize medical terminology.

RULES
Never guess random words. Never replace medicine names with similar English words.
Always use medical reasoning, medical context, and analyze sentence context.
Always analyze nearby words and prescription format.

MEDICINE MATCHING
Compare every recognized word against Generic Medicines, Brand Medicines, Hospital Medicine Database, Medical Dictionary, and Drug Names.

LAB TEST MATCHING
Recognize CBC, LFT, KFT, ECG, MRI, CT, X-Ray, Echo, Blood Sugar, HbA1c, Urine Test, Lipid Profile, Thyroid Profile, Vitamin D, and all common laboratory investigations.

MEDICAL ABBREVIATIONS
Understand Tab, Cap, Inj, Syp, OD, BD, TDS, QID, SOS, HS, PO, IV, IM, SC, AC, PC, PRN, Stat, Rx, Dx.

DOSAGE
Recognize 500 mg, 250 mg, 650 mg, 5 ml, 10 ml, 1-0-1, 1-1-1, 0-1-0, ½ Tablet, Morning, Night, Before Food, After Food, SOS, For 5 Days, For 7 Days.

HANDWRITING
Understand Connected Letters, Curved Letters, Fast Writing, Missing Strokes, Broken Characters, Joined Characters, Overlapping Characters, Incomplete Letters, Slanted Writing, Medical Shortcuts.

MEDICAL CONTEXT
If handwriting is unclear never invent words. Instead predict the most probable medical term using:
Department & Specialization: ${_doctor.specialization}
Patient Context & Diagnosis: $_patientContext
Symptoms: ${_appointment.complaint ?? "None"}
Previous Text in Prescription: ${_notesCtrl.text.trim()}

OUTPUT
Return JSON EXACTLY in this format:
{
  "recognized_text": "...",
  "confidence": 98,
  "alternatives": ["...", "...", "..."],
  "reason": "Why this medical word was selected."
}''';
  }

  Future<Map<String, dynamic>> _correctTextWithAI(List<String> rawCandidates) async {
    try {
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'response_format': { "type": "json_object" },
          'messages': [
            {
              'role': 'system',
              'content': _buildSystemPrompt()
            },
            {
              'role': 'user',
              'content': 'Top ML Kit OCR Guesses: ${rawCandidates.join(', ')}'
            }
          ],
          'temperature': 0.1,
          'max_tokens': 250,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'].toString().trim();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("AI Correction Error: $e");
    }
    return {'recognized_text': rawCandidates.isNotEmpty ? rawCandidates.first : '', 'confidence': 100};
  }

  // -------------------------------------------------------------
  // CLINICAL EXPORT (PDF, PRINT, SHARE)
  // -------------------------------------------------------------

  Future<void> _printPrescription() async {
    final pdf = await _generatePrescriptionPdf();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _exportPdf() async {
    final pdf = await _generatePrescriptionPdf();
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Prescription_${_appointment.patientName}.pdf',
    );
  }

  Future<void> _sharePrescription() async {
    final pdf = await _generatePrescriptionPdf();
    final bytes = await pdf.save();
    // Use share_plus to share the PDF
    await Share.shareXFiles([
      XFile.fromData(
        bytes,
        name: 'Prescription_${_appointment.patientName}.pdf',
        mimeType: 'application/pdf',
      ),
    ], text: 'Clinical Prescription for ${_appointment.patientName}');
  }

  Future<pw.Document> _generatePrescriptionPdf() async {
    final pdf = pw.Document();

    // Attempt to load logo/hospital name
    final hospitalName = widget.doctor?.hospitalName ?? "GM Hospital";
    final doctorName =
        widget.doctor?.fullName ?? "Dr. ${widget.doctor?.username ?? 'Doctor'}";
    final specialization = widget.doctor?.specialization ?? "General Physician";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          // Header Section
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    hospitalName,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal,
                    ),
                  ),
                  pw.Text(
                    'Digital Clinical Prescription',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    doctorName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    specialization,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    DateFormat('dd MMMM yyyy, hh:mm a').format(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 2, color: PdfColors.grey300),
          pw.SizedBox(height: 20),

          // Patient Details Row
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PATIENT:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      _appointment.patientName,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'AGE/GENDER:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      '${_appointment.age} / ${_appointment.gender}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ID:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      _appointment.patientId,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),

          // Clinical Notes
          pw.Text(
            'CLINICAL NOTES / CASE SUMMARY',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            _notesCtrl.text.isEmpty
                ? 'No clinical notes provided.'
                : _notesCtrl.text.replaceAll('::', ''),
            style: const pw.TextStyle(fontSize: 10, lineSpacing: 3),
          ),
          pw.SizedBox(height: 20),

          // Lab Tests (Selected Tests) - One by One display
          if (_selectedTests.isNotEmpty) ...[
            pw.Text(
              'CLINICAL INVESTIGATIONS / LAB TESTS',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: _selectedTests.map((id) {
                final test = _allLabServices.firstWhere(
                  (s) => s['service_id'].toString() == id,
                  orElse: () => {'service_name': id},
                );
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Bullet(
                    text: test['service_name'].toString(),
                    style: const pw.TextStyle(fontSize: 10),
                    bulletSize: 3,
                  ),
                );
              }).toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          // Medications Table
          if (_prescribedMeds.isNotEmpty) ...[
            pw.Text(
              'PRESCRIPTION / MEDICATIONS',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Medicine',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Dosage',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Frequency',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Duration',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                ..._prescribedMeds.map(
                  (m) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          m['name'] ?? '',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          m['dosage'] ?? '',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          m['frequency'] ?? '',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          m['duration'] ?? '',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          pw.Spacer(),
          pw.Divider(thickness: 1, color: PdfColors.grey200),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated via Medinote Clinical Command Center',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
              pw.Text(
                'Doctor Signature: __________________',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf;
  }

  Future<void> _submitPrescription() async {
    setState(() => _isSubmitting = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final customDir = Directory('${dir.path}/GM_HMS/assets/precision_data');
      if (!await customDir.exists()) await customDir.create(recursive: true);
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final pages = _drawCtrl.allPagesSnapshot;
      List<File> files = [];
      final ec = ScreenshotController();
      for (int i = 0; i < pages.length; i++) {
        final bytes = await ec.captureFromWidget(
          Material(
            color: Colors.white,
            child: SizedBox(
              width: _exportPageWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i == 0) _buildPremiumHeader(),
                  SizedBox(
                    height: _exportPageHeight,
                    width: _exportPageWidth,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: StrokePainter(
                              strokes: pages[i],
                              showLinedPaper: false,
                            ),
                            size: Size(_exportPageWidth, _exportPageHeight),
                          ),
                        ),
                        if (i == pages.length - 1)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: _buildFooter(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          context: context,
          delay: const Duration(milliseconds: 500),
        );
        final f = File(
          '${customDir.path}/${_appointment.patientId}_${ts}_P${i + 1}.png',
        );
        await f.writeAsBytes(bytes);
        files.add(f);
      }
      if (files.isNotEmpty) {
        // Construct Vitals JSON
        final String vitalsJson = jsonEncode({
          "bp": _bpCtrl.text,
          "spo2": _spo2Ctrl.text,
          "temp": _tempCtrl.text,
          "pulse": _pulseCtrl.text,
          "weight": _weightCtrl.text,
          "height": _heightCtrl.text,
        });

        // Construct Meds JSON (soap_plan)
        final String medsJson = jsonEncode(_prescribedMeds);

        // Construct Labs (soap_objective)
        final String labsData = _selectedTests.join(', ');

        final result = await _apiService.savePrescription(
          patientName: _appointment.patientName,
          patientId: _appointment.patientId,
          doctorId: _doctor.id,
          appointmentId: _appointment.appointmentId,
          followUpDate: DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.now().add(const Duration(days: 7))),
          imageFiles: files,
          vitalSigns: vitalsJson,
          clinicalNotes: _notesCtrl.text,
          labData: labsData,
          rxData: medsJson,
        );
        if (mounted) {
          final ok = result['success'] == true;
          _showStatusDialog(
            success: ok,
            message:
                (result['message'] as String?) ??
                (ok
                    ? 'Prescription & Consultation Saved!'
                    : 'Failed to save data.'),
          );
        }
      }
    } catch (e) {
      if (mounted) _showStatusDialog(success: false, message: 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ---------------------------------------------------------
  //  BUILD
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final s = MediaQuery.of(context).size;
    // Initialize rx card position to center on first build
    if (!_rxCardInitialized && s.width > 0) {
      _rxCardOffset = Offset((s.width - 480) / 2, (s.height - 680) / 2 - 40);
      _rxCardInitialized = true;
    }
    return Scaffold(
      backgroundColor: _v4CreamBg,
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(),
      body: _isDigitalMode
          ? _buildDrawingBoard(r, s)
          : _buildSmartFormMode(r, s.width, s.height),
    );
  }

  // ---------------------------------------------------------
  //  APP BAR — Command Center Edition
  // ---------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: AppBar(
        backgroundColor: _v4PrimaryGreen,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_hospital_rounded, color: _v4PrimaryGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Clinical Portal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Prescription',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // iOS Segmented Mode Toggle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isDigitalMode = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isDigitalMode ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.draw_rounded, size: 14, color: _isDigitalMode ? _v4PrimaryGreen : Colors.white),
                        const SizedBox(width: 4),
                        Text('Pen', style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _isDigitalMode ? _v4PrimaryGreen : Colors.white,
                        )),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isDigitalMode = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: !_isDigitalMode ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.text_snippet_rounded, size: 14, color: !_isDigitalMode ? _v4PrimaryGreen : Colors.white),
                        const SizedBox(width: 4),
                        Text('Note', style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: !_isDigitalMode ? _v4PrimaryGreen : Colors.white,
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Finish Button
          GestureDetector(
            onTap: _isSubmitting ? null : _submitPrescription,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: _v4Error,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _v4Error.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'FINISH',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
            onSelected: (val) {
              if (val == 'print') _printPrescription();
              if (val == 'pdf') _exportPdf();
              if (val == 'share') _sharePrescription();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'print',
                child: Row(
                children: [
                  Icon(Icons.print_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Print Prescription'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'pdf',
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Save as PDF'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Share with Patient'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    ),
  );
}

  Widget _modeToggle(
    String title,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _teal : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _teal.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : Colors.white38,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  //  DRAWING BOARD
  // ---------------------------------------------------------
  Widget _buildDrawingBoard(R r, Size s) {
    return Stack(
      children: [
        // -- Canvas (Premium Paper Look)
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              height: s.height * 0.75, // Approximating 70-75% height to leave room for header
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildPageCanvas(
                  _drawCtrl.currentPage,
                  s.width * 0.85, // Give some horizontal breathing room
                  s.height * 0.75,
                  key: ValueKey(_drawCtrl.currentPage),
                ),
              ),
            ),
          ),
        ),

        // -- Integrated Patient HUD + Vitals
        Positioned(
          top: 10,
          left: r.isPhone ? 50 : 66,
          right: 12,
          child: _buildIntegratedPatientHeader(),
        ),

        // -- Side toolbar
        if (_isDrawingMode) _buildSideToolbar(r),

        // -- Stylus undo/clear floating pill (visible when strokes exist)
        if (_isDrawingMode && _drawCtrl.hasStrokes)
          Positioned(
            bottom: 30, // Pushed closer to bottom edge
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // -- Eraser quick-toggle
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(
                          () => _drawCtrl.tool = _drawCtrl.tool == 'Eraser'
                              ? 'Pen'
                              : 'Eraser',
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _drawCtrl.tool == 'Eraser'
                              ? Colors.orange.withValues(alpha: 0.18)
                              : Colors.blueGrey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _drawCtrl.tool == 'Eraser'
                                ? Colors.orange
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _drawCtrl.tool == 'Eraser'
                                  ? Icons.edit_rounded
                                  : Icons.auto_fix_normal_rounded,
                              size: 16,
                              color: _drawCtrl.tool == 'Eraser'
                                  ? Colors.orange
                                  : Colors.blueGrey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _drawCtrl.tool == 'Eraser' ? 'Drawing' : 'Eraser',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _drawCtrl.tool == 'Eraser'
                                    ? Colors.orange
                                    : Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // -- Undo
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _drawCtrl.undo();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.undo_rounded,
                              size: 16,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Undo (${_drawCtrl.undoCount})',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Clear page
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              'Clear Page?',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            content: const Text(
                              'All strokes on this page will be removed.',
                              style: TextStyle(fontSize: 13),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  _drawCtrl.clearPage();
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.delete_sweep_rounded,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Clear Page',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // -- Page selector
        Positioned(
          bottom: 90,
          left: 0,
          right: 0,
          child: Center(child: _buildPageSelector()),
        ),

        // -- Bottom Toolbar (Rx, Lab, etc)
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(child: _buildFloatingDock()),
        ),

        // -- Bottom Actions (Floating)
        Positioned(
          top: 140,
          right: 24,
          child: _buildBottomActions(),
        ),

        // -- DRAGGABLE RX CARD
        if (_rxCardVisible)
          Positioned(
            left: _rxCardOffset.dx.clamp(
              0.0,
              s.width > 480 ? s.width - 480 : 0.0,
            ),
            top: _rxCardOffset.dy.clamp(
              0.0,
              s.height > (_rxCardMinimized ? 80 : 680)
                  ? s.height - (_rxCardMinimized ? 80 : 680)
                  : 0.0,
            ),
            child: ScaleTransition(
              scale: _rxCardAnim,
              child: _buildDraggableRxCard(s),
            ),
          ),

        // -- Lab bottom sheet overlay
        if (_showLabPanel) Positioned.fill(child: _buildLabOverlay()),
      ],
    );
  }

  // ---------------------------------------------------------
  //  DRAGGABLE RX CARD
  // ---------------------------------------------------------
  Widget _buildDraggableRxCard(Size screenSize) {
    // Category filter tabs
    const categories = ['All', 'Antibiotic', 'Analgesic', 'Antacid', 'Diabetic', 'Cardiac', 'Vitamin'];
    const catIcons = {
      'All': Icons.apps_rounded,
      'Antibiotic': Icons.coronavirus_rounded,
      'Analgesic': Icons.healing_rounded,
      'Antacid': Icons.local_dining_rounded,
      'Diabetic': Icons.monitor_heart_rounded,
      'Cardiac': Icons.favorite_rounded,
      'Vitamin': Icons.eco_rounded,
    };

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 520,
        constraints: BoxConstraints(
          maxHeight: _rxCardMinimized ? 72 : (_showSuggestions ? 820 : 760),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FAFA),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF1F6B4A).withValues(alpha: 0.18), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 60, offset: const Offset(0, 24)),
            BoxShadow(color: const Color(0xFF1F6B4A).withValues(alpha: 0.12), blurRadius: 40),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // -------------------- HEADER --------------------
              GestureDetector(
                onPanUpdate: _rxCardPinned
                    ? null
                    : (details) {
                        setState(() {
                          final newX = (_rxCardOffset.dx + details.delta.dx).clamp(0.0, screenSize.width > 520 ? screenSize.width - 520 : 0.0);
                          final newY = (_rxCardOffset.dy + details.delta.dy).clamp(0.0, screenSize.height > (_rxCardMinimized ? 80 : 760) ? screenSize.height - (_rxCardMinimized ? 80 : 760) : 0.0);
                          _rxCardOffset = Offset(newX, newY);
                        });
                      },
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF1F6B4A), Color(0xFF1F6B4A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [BoxShadow(color: const Color(0xFF1F6B4A).withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Grip lines
                      if (!_rxCardPinned)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (_) => Container(
                              margin: const EdgeInsets.only(bottom: 3.5),
                              width: 16,
                              height: 2,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(2)),
                            )),
                          ),
                        ),
                      // Rx logo pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        child: const Text('\u211e', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Prescription Pad', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.3)),
                            if (!_rxCardMinimized)
                              Text(
                                _prescribedMeds.isEmpty ? 'Tap \u002b to add medicines' : '${_prescribedMeds.length} medicine${_prescribedMeds.length > 1 ? "s" : ""} prescribed',
                                style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.8)),
                              ),
                          ],
                        ),
                      ),
                      // Medicine count pill
                      if (_prescribedMeds.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                          child: Text('${_prescribedMeds.length}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1F6B4A))),
                        ),
                      // Pin
                      _headerBtn(
                        icon: _rxCardPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                        active: _rxCardPinned,
                        onTap: () { setState(() => _rxCardPinned = !_rxCardPinned); HapticFeedback.selectionClick(); },
                      ),
                      const SizedBox(width: 5),
                      // Minimize
                      _headerBtn(
                        icon: _rxCardMinimized ? Icons.expand_more_rounded : Icons.remove_rounded,
                        onTap: () => setState(() => _rxCardMinimized = !_rxCardMinimized),
                      ),
                      const SizedBox(width: 5),
                      // Close
                      _headerBtn(
                        icon: Icons.close_rounded,
                        onTap: () => _rxCardAnimCtrl.reverse().then((_) => setState(() => _rxCardVisible = false)),
                      ),
                    ],
                  ),
                ),
              ),

              if (!_rxCardMinimized) ...[
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // -------- SEARCH FIELD --------
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _showSuggestions ? const Color(0xFF1F6B4A) : Colors.grey.withValues(alpha: 0.22), width: _showSuggestions ? 2 : 1),
                            boxShadow: [BoxShadow(color: _showSuggestions ? const Color(0xFF1F6B4A).withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          child: TextField(
                            controller: _medNameCtrl,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addMedicine(),
                            decoration: InputDecoration(
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(13),
                                child: Icon(Icons.search_rounded, color: _showSuggestions ? const Color(0xFF1F6B4A) : Colors.grey.shade400, size: 22),
                              ),
                              suffixIcon: _medNameCtrl.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () { _medNameCtrl.clear(); setState(() { _showSuggestions = false; _suggestionResults = []; _selectedMedInfo = null; }); },
                                      child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.close_rounded, color: Colors.grey, size: 18)),
                                    )
                                  : null,
                              hintText: 'Search medicine, brand or generic...',
                              hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey.shade400, fontWeight: FontWeight.w400),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              isDense: true,
                            ),
                          ),
                        ),

                        // -------- SEARCH DROPDOWN --------
                        if (_showSuggestions)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            constraints: const BoxConstraints(maxHeight: 280),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8))],
                            ),
                            child: _isSearchingMeds
                                ? const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1F6B4A)))),
                                  )
                                : _suggestionResults.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.search_off_rounded, size: 32, color: Colors.grey.shade300),
                                      const SizedBox(height: 8),
                                      Text('No medicines found', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                                    ])),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      itemCount: _suggestionResults.length,
                                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withValues(alpha: 0.08)),
                                      itemBuilder: (context, i) {
                                        final result = _suggestionResults[i];
                                        return InkWell(
                                          onTap: () => _selectSuggestion(result),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(color: i == 0 ? const Color(0xFF1F6B4A).withValues(alpha: 0.03) : Colors.transparent),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 38, height: 38,
                                                  decoration: BoxDecoration(color: result.medInfo.catColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                                  child: Icon(Icons.medication_rounded, size: 18, color: result.medInfo.catColor),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                    Row(children: [
                                                      if (result.isBrandMatch)
                                                        Container(
                                                          margin: const EdgeInsets.only(right: 6),
                                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                          decoration: BoxDecoration(color: result.medInfo.catColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                                          child: Text('Brand', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: result.medInfo.catColor)),
                                                        ),
                                                      Expanded(child: Text(result.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis)),
                                                    ]),
                                                    const SizedBox(height: 2),
                                                    Text(result.subtitle, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  ]),
                                                ),
                                                const SizedBox(width: 8),
                                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(color: result.medInfo.catColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7)),
                                                    child: Text(result.medInfo.defDosage, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: result.medInfo.catColor)),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(result.medInfo.defFreq, style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                                                ]),
                                                const SizedBox(width: 6),
                                                Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade300),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),

                        // -------- SELECTED MED INFO --------
                        if (_selectedMedInfo != null && !_showSuggestions) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [_selectedMedInfo!.catColor.withValues(alpha: 0.09), _selectedMedInfo!.catColor.withValues(alpha: 0.04)]),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _selectedMedInfo!.catColor.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(color: _selectedMedInfo!.catColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                                  child: Icon(Icons.medication_rounded, size: 15, color: _selectedMedInfo!.catColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(_selectedMedInfo!.generic, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _selectedMedInfo!.catColor)),
                                  if (_selectedMedInfo!.brands.isNotEmpty)
                                    Text(_selectedMedInfo!.brands.split(',').take(2).join(', '), style: TextStyle(fontSize: 10, color: _selectedMedInfo!.catColor.withValues(alpha: 0.7)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ])),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: _selectedMedInfo!.catColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                  child: Text(_selectedMedInfo!.category, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _selectedMedInfo!.catColor)),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // -------- DOSAGE PANEL --------
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Label row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(color: const Color(0xFF1F6B4A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.tune_rounded, size: 13, color: Color(0xFF1F6B4A)),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Dosage Settings', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: _addMedicine,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Color(0xFF1F6B4A), Color(0xFF065F46)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [BoxShadow(color: const Color(0xFF1F6B4A).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
                                      ),
                                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(Icons.add_rounded, color: Colors.white, size: 16),
                                        SizedBox(width: 5),
                                        Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                                      ]),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Dosage
                                  Expanded(
                                    child: _dosageField(
                                      label: 'DOSE',
                                      icon: Icons.medical_services_outlined,
                                      color: const Color(0xFF3730A3),
                                      child: TextField(
                                        controller: _doseCtrl,
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF3730A3)),
                                        decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: '500mg', hintStyle: TextStyle(fontSize: 11, color: Colors.grey), contentPadding: EdgeInsets.zero),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Frequency
                                  Expanded(
                                    child: _dosageField(
                                      label: 'FREQ',
                                      icon: Icons.schedule_rounded,
                                      color: const Color(0xFF1F6B4A),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedFreq,
                                          isExpanded: true,
                                          isDense: true,
                                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: Color(0xFF1F6B4A)),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1F6B4A)),
                                          items: ['1-0-0', '0-1-0', '0-0-1', '1-0-1', '1-1-0', '1-1-1', 'SOS', 'OD', 'BD', 'TDS', 'QID']
                                              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                          onChanged: (v) => setState(() => _selectedFreq = v!),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Duration
                                  Expanded(
                                    child: _dosageField(
                                      label: 'DAYS',
                                      icon: Icons.calendar_month_rounded,
                                      color: const Color(0xFFD97706),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedDuration,
                                          isExpanded: true,
                                          isDense: true,
                                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: Color(0xFFD97706)),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                                          items: ['1 Day', '2 Days', '3 Days', '5 Days', '7 Days', '10 Days', '2 Weeks', '1 Month', '2 Months', '3 Months']
                                              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                          onChanged: (v) => setState(() => _selectedDuration = v!),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Food Timing
                                  Expanded(
                                    child: _dosageField(
                                      label: 'TIMING',
                                      icon: Icons.restaurant_rounded,
                                      color: const Color(0xFFC026D3),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedFoodTiming,
                                          isExpanded: true,
                                          isDense: true,
                                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: Color(0xFFC026D3)),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFC026D3)),
                                          items: ['Before Food', 'After Food', 'Empty Stomach']
                                              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                          onChanged: (v) => setState(() => _selectedFoodTiming = v!),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // -------- CATEGORY FILTER TABS --------
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 7),
                            itemBuilder: (_, i) {
                              final cat = categories[i];
                              final isSelected = _rxCategoryFilter == cat;
                              return GestureDetector(
                                onTap: () => setState(() => _rxCategoryFilter = cat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF1F6B4A) : Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: isSelected ? const Color(0xFF1F6B4A) : Colors.grey.withValues(alpha: 0.2)),
                                    boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF1F6B4A).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(catIcons[cat] ?? Icons.circle_rounded, size: 11, color: isSelected ? Colors.white : Colors.grey.shade500),
                                    const SizedBox(width: 5),
                                    Text(cat, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : Colors.grey.shade600)),
                                  ]),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // -------- RECENT MEDICINES --------
                        if (_recentMedicines.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.history_rounded, size: 12, color: Color(0xFF1F6B4A)),
                              const SizedBox(width: 5),
                              Text('RECENTLY USED', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 0.8)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 7, runSpacing: 6,
                            children: _recentMedicines.map((name) {
                              final already = _prescribedMeds.any((m) => m['name'] == name);
                              return GestureDetector(
                                onTap: already ? null : () {
                                  final info = kMedicineDb.firstWhere((m) => m.generic == name, orElse: () => MedInfo(generic: name, brands: '', category: 'General', defDosage: _doseCtrl.text, defFreq: _selectedFreq, defDuration: _selectedDuration, catColor: Colors.grey));
                                  setState(() {
                                    _prescribedMeds.add({'id': (_medIdCounter++).toString(), 'name': name, 'dosage': info.defDosage, 'freq': info.defFreq, 'duration': info.defDuration, 'foodTiming': _selectedFoodTiming, 'category': info.category, 'brands': info.brands});
                                  });
                                  HapticFeedback.lightImpact();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: already ? const Color(0xFF1F6B4A) : Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: already ? const Color(0xFF1F6B4A) : Colors.grey.withValues(alpha: 0.22)),
                                    boxShadow: already ? [BoxShadow(color: const Color(0xFF1F6B4A).withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))] : null,
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(already ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, size: 12, color: already ? Colors.white : Colors.grey.shade400),
                                    const SizedBox(width: 5),
                                    Text(name, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: already ? Colors.white : Colors.blueGrey.shade700)),
                                  ]),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // -------- MEDICINE LIST HEADER --------
                        if (_prescribedMeds.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(color: const Color(0xFF1F6B4A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.medication_rounded, size: 13, color: Color(0xFF1F6B4A)),
                              ),
                              const SizedBox(width: 8),
                              Text('MEDICINES (${_prescribedMeds.length})', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 0.8)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setState(() => _prescribedMeds.clear()),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(10)),
                                  child: const Text('Clear all', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.redAccent)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('\u27fa hold \u2261 to reorder  \u2022  \u2190 swipe to delete  \u2022  tap \u270e to edit', style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                          const SizedBox(height: 10),
                        ],

                        // -------- EMPTY STATE --------
                        if (_prescribedMeds.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(vertical: 28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [const Color(0xFF1F6B4A).withValues(alpha: 0.08), const Color(0xFF1F6B4A).withValues(alpha: 0.03)]),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.medication_liquid_rounded, size: 40, color: const Color(0xFF1F6B4A).withValues(alpha: 0.5)),
                                ),
                                const SizedBox(height: 14),
                                const Text('No medicines prescribed yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                                const SizedBox(height: 4),
                                Text('Search a medicine above and tap Add', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                const SizedBox(height: 16),
                                // Quick-add tip chips
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 6,
                                  runSpacing: 5,
                                  children: ['Paracetamol', 'Amoxicillin', 'Pantoprazole', 'Metformin'].map((s) =>
                                    GestureDetector(
                                      onTap: () {
                                        final info = kMedicineDb.firstWhere((m) => m.generic == s, orElse: () => MedInfo(generic: s, brands: '', category: 'General', defDosage: '500mg', defFreq: '1-0-1', defDuration: '3 Days', catColor: Colors.teal));
                                        setState(() {
                                          _prescribedMeds.add({'id': (_medIdCounter++).toString(), 'name': s, 'dosage': info.defDosage, 'freq': info.defFreq, 'duration': info.defDuration, 'foodTiming': _selectedFoodTiming, 'category': info.category, 'brands': info.brands});
                                        });
                                        HapticFeedback.lightImpact();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1F6B4A).withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: const Color(0xFF1F6B4A).withValues(alpha: 0.18)),
                                        ),
                                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                                          const Icon(Icons.add_rounded, size: 12, color: Color(0xFF1F6B4A)),
                                          const SizedBox(width: 4),
                                          Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1F6B4A))),
                                        ]),
                                      ),
                                    ),
                                  ).toList(),
                                ),
                              ],
                            ),
                          ),

                        // -------- MEDICINE CARDS (Reorderable) --------
                        if (_prescribedMeds.isNotEmpty)
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            onReorder: (oi, ni) {
                              setState(() {
                                if (ni > oi) ni--;
                                final item = _prescribedMeds.removeAt(oi);
                                _prescribedMeds.insert(ni, item);
                              });
                              HapticFeedback.selectionClick();
                            },
                            proxyDecorator: (child, _, anim) => AnimatedBuilder(
                              animation: anim,
                              builder: (_, __) => Material(elevation: 14, borderRadius: BorderRadius.circular(18), color: Colors.transparent, child: child),
                            ),
                            itemCount: _prescribedMeds.length,
                            itemBuilder: (_, idx) {
                              final med = _prescribedMeds[idx];
                              return _rxMedCard(med, idx, key: ValueKey('med_${med['id']}'));
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerBtn({required IconData icon, VoidCallback? onTap, bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: active ? Colors.white.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _dosageField({required String label, required IconData icon, required Color color, required Widget child}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.6)),
      ]),
      const SizedBox(height: 5),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(11), border: Border.all(color: color.withValues(alpha: 0.18))),
        child: child,
      ),
    ]);
  }

  // -- State to track which med is being edited
  String? _editingMedId;

  Widget _rxMedCard(Map<String, String> med, int idx, {required Key key}) {
    final catColor = kMedicineDb
        .firstWhere(
          (m) => m.generic == med['name'],
          orElse: () => MedInfo(
            generic: '',
            brands: '',
            category: '',
            defDosage: '',
            defFreq: '',
            defDuration: '',
            catColor: Colors.teal,
          ),
        )
        .catColor;

    final stableId = med['id'] ?? 'med_$idx';
    final isEditing = _editingMedId == stableId;

    // Inline edit controllers
    final editDoseCtrl = TextEditingController(text: med['dosage']);
    final editFreqs = [
      '1-0-0', '0-1-0', '0-0-1', '1-0-1', '1-1-0', '1-1-1', 'SOS', 'OD', 'BD', 'TDS', 'QID'
    ];
    final editDurs = [
      '1 Day', '2 Days', '3 Days', '5 Days', '7 Days', '10 Days', '2 Weeks', '1 Month', '2 Months', '3 Months'
    ];
    String editFreq = editFreqs.contains(med['freq']) ? med['freq']! : '1-0-1';
    String editDur = editDurs.contains(med['duration']) ? med['duration']! : '3 Days';

    return Dismissible(
      key: ValueKey('dismissible_$stableId'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        setState(() => _prescribedMeds.removeWhere((m) => m['id'] == stableId));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.withValues(alpha: 0.05),
              Colors.redAccent.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 26),
            const SizedBox(height: 2),
            const Text(
              'Delete',
              style: TextStyle(fontSize: 9, color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      child: StatefulBuilder(
        builder: (context, setLocal) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            key: ValueKey('card_$stableId'),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEditing
                    ? catColor.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.13),
                width: isEditing ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isEditing
                      ? catColor.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: isEditing ? 16 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -- Main row
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Row(
                    children: [
                      // Color dot + number
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: catColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: catColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            if ((med['brands'] ?? '').isNotEmpty)
                              Text(
                                med['brands']!.split(',').first.trim(),
                                style: TextStyle(fontSize: 9.5, color: Colors.grey.shade400),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 5),
                            // Badges row
                            Row(
                              children: [
                                _rxBadge(med['dosage'] ?? '', const Color(0xFF3730A3)),
                                const SizedBox(width: 5),
                                _rxBadge(med['freq'] ?? '', const Color(0xFF1F6B4A)),
                                const SizedBox(width: 5),
                                _rxBadge(med['duration'] ?? '', const Color(0xFFD97706)),
                                const SizedBox(width: 5),
                                _rxBadge(med['foodTiming'] ?? 'After Food', const Color(0xFFC026D3)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Action buttons
                      Column(
                        children: [
                          // Edit toggle
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _editingMedId = isEditing ? null : stableId;
                              });
                              HapticFeedback.selectionClick();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: isEditing
                                    ? catColor.withValues(alpha: 0.15)
                                    : const Color(0xFFF3EFE6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isEditing ? Icons.check_rounded : Icons.edit_rounded,
                                size: 15,
                                color: isEditing ? catColor : Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Delete
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _prescribedMeds.removeWhere((m) => m['id'] == stableId));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 15,
                                color: Colors.redAccent.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      // Drag handle
                      ReorderableDragStartListener(
                        index: idx,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            color: Colors.grey.shade300,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // -- Inline edit panel (expands when editing)
                if (isEditing)
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      children: [
                        Divider(height: 1, color: catColor.withValues(alpha: 0.15)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Dosage edit
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Dosage', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3EFE6),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                                    ),
                                    child: TextField(
                                      controller: editDoseCtrl,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (v) {
                                        setState(() {
                                          final i = _prescribedMeds.indexWhere((m) => m['id'] == stableId);
                                          if (i != -1) _prescribedMeds[i]['dosage'] = v;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Frequency edit
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Frequency', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
                                  const SizedBox(height: 4),
                                  StatefulBuilder(
                                    builder: (ctx, setF) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3EFE6),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: editFreq,
                                          isExpanded: true,
                                          isDense: true,
                                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1F6B4A)),
                                          items: editFreqs.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                          onChanged: (v) {
                                            setF(() => editFreq = v!);
                                            setState(() {
                                              final i = _prescribedMeds.indexWhere((m) => m['id'] == stableId);
                                              if (i != -1) _prescribedMeds[i]['freq'] = v!;
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
                                        color: const Color(0xFFF3EFE6),
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
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Save edit button
                        GestureDetector(
                          onTap: () => setState(() => _editingMedId = null),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  catColor,
                                  catColor.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 15, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _rxBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _rxDrop(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFE6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF1F6B4A)),
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  //  PATIENT HUD
  // ---------------------------------------------------------
  // -- Integrated Patient Header (HUD + Vitals in one card) ------------------
  Widget _buildIntegratedPatientHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: _v4White,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // - Row 1: Patient Primary Info
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_v4PrimaryGreen, _v4Success],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _v4Success.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _appointment.patientName.isNotEmpty ? _appointment.patientName[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Patient Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PATIENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: _v4TextSecondary.withValues(alpha: 0.8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _appointment.patientName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _v4TextPrimary,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Age / Sex
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _v4CreamBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'AGE / SEX',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: _v4TextSecondary.withValues(alpha: 0.8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_appointment.age ?? '--'} / ${_appointment.gender?.isNotEmpty == true ? _appointment.gender![0].toUpperCase() : '-'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _v4TextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Container(height: 1, color: _v4Divider),
          const SizedBox(height: 20),

          // - Row 2: Vitals Chips View
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _v4VitalChip('BP', _bpCtrl.text.isEmpty ? '--' : _bpCtrl.text, Icons.favorite_border_rounded),
                const SizedBox(width: 12),
                _v4VitalChip('SpO2', _spo2Ctrl.text.isEmpty ? '--' : '${_spo2Ctrl.text}%', Icons.water_drop_outlined),
                const SizedBox(width: 12),
                _v4VitalChip('Temp', _tempCtrl.text.isEmpty ? '--' : '${_tempCtrl.text}°F', Icons.thermostat_rounded),
                const SizedBox(width: 12),
                _v4VitalChip('Pulse', _pulseCtrl.text.isEmpty ? '--' : '${_pulseCtrl.text} bpm', Icons.monitor_heart_outlined),
                const SizedBox(width: 12),
                _v4VitalChip('Wt', _weightCtrl.text.isEmpty ? '--' : '${_weightCtrl.text} kg', Icons.scale_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _v4VitalChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _v4CreamBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _v4PrimaryGreen),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: _v4TextSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _v4TextPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPatientHUD() {
    // Kept for backward compatibility or future use, but replaced in main Drawing Board
    return const SizedBox.shrink();
  }

  Widget _vitalBadge(String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --- Vitals panel - always visible below patient HUD ----------------
  Widget _buildVitalsPanel() {
    // Kept for backward compatibility or future use, but replaced in main Drawing Board
    return const SizedBox.shrink();
  }

  Widget _vDivider() => Container(
    width: 1,
    height: 28,
    color: const Color(0xFFE2E8F0),
    margin: const EdgeInsets.symmetric(horizontal: 6),
  );

  Widget _plainVital(String label, TextEditingController ctrl) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label : ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _slate,
          ),
        ),
        SizedBox(
          width: 60,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.text,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F6B4A),
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: '--',
            ),
          ),
        ),
      ],
    );
  }

  // --- Old vitals dropdown panel (kept for compatibility) -----------------
  Widget _buildVitalsDropdownPanel() {
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.99),
                  Colors.white.withValues(alpha: 0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.redAccent, Color(0xFFE11D48)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.30),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.monitor_heart_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Vitals',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: _slate,
                          ),
                        ),
                        Text(
                          'Tap any field to enter value',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _showVitalsPanel = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_teal, Color(0xFF0F766E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _teal.withValues(alpha: 0.30),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFEEF2F7)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _vitalCard(
                        'BP',
                        'mmHg',
                        _bpCtrl,
                        Icons.monitor_heart_rounded,
                        Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _vitalCard(
                        'SpO2',
                        '%',
                        _spo2Ctrl,
                        Icons.air_rounded,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _vitalCard(
                        'Temp',
                        '°F',
                        _tempCtrl,
                        Icons.thermostat_rounded,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _vitalCard(
                        'Pulse',
                        'bpm',
                        _pulseCtrl,
                        Icons.timeline_rounded,
                        Colors.pink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _vitalCard(
                        'Weight',
                        'kg',
                        _weightCtrl,
                        Icons.scale_rounded,
                        Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _vitalCard(
    String label,
    String unit,
    TextEditingController ctrl,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _slate,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: '--',
              hintStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.grey.shade300,
              ),
              suffixText: unit,
              suffixStyle: TextStyle(fontSize: 8, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  // --- Bottom Actions (PDF, Print, etc.) --------------------------------
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: _v4White,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _v4ActionItem(Icons.picture_as_pdf_rounded, 'Save PDF', _exportPdf),
          const SizedBox(height: 12),
          _v4ActionItem(Icons.print_rounded, 'Print', _printPrescription),
          const SizedBox(height: 12),
          _v4ActionItem(Icons.share_rounded, 'Share', _sharePrescription),
          const SizedBox(height: 12),
          _v4ActionItem(Icons.wechat_rounded, 'WhatsApp', _shareViaWhatsApp),
          const SizedBox(height: 12),
          _v4ActionItem(Icons.email_rounded, 'Email', _shareViaEmail),
        ],
      ),
    );
  }

  Future<void> _shareViaWhatsApp() async {
    final pdf = await _generatePrescriptionPdf();
    final bytes = await pdf.save();
    await Share.shareXFiles([
      XFile.fromData(
        bytes,
        name: 'Prescription_${_appointment.patientName}.pdf',
        mimeType: 'application/pdf',
      ),
    ], text: 'Please find attached the prescription for ${_appointment.patientName} from GM Hospital.\n\nRegards,\nDr. ${_doctor.fullName}');
  }

  Future<void> _shareViaEmail() async {
    final pdf = await _generatePrescriptionPdf();
    final bytes = await pdf.save();
    await Share.shareXFiles([
      XFile.fromData(
        bytes,
        name: 'Prescription_${_appointment.patientName}.pdf',
        mimeType: 'application/pdf',
      ),
    ], subject: 'Prescription: ${_appointment.patientName}', text: 'Please find attached the prescription for ${_appointment.patientName} from GM Hospital.');
  }

  // --- Floating Bottom Toolbar -----------------------------------------
  Widget _buildFloatingDock() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _v4White,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _v4DockBtn(
            icon: Icons.medication_rounded,
            label: 'Rx',
            isActive: _rxCardVisible,
            badge: _prescribedMeds.isNotEmpty ? '${_prescribedMeds.length}' : null,
            onTap: () {
              setState(() => _rxCardVisible = !_rxCardVisible);
              if (_rxCardVisible) {
                _rxCardMinimized = false;
                _rxCardAnimCtrl.forward(from: 0);
              } else {
                _rxCardAnimCtrl.reverse();
              }
            },
          ),
          const SizedBox(width: 8),
          _v4DockBtn(
            icon: Icons.science_rounded,
            label: 'Lab',
            isActive: _showLabPanel,
            badge: _selectedTests.isNotEmpty ? '${_selectedTests.length}' : null,
            onTap: () {
              setState(() => _showLabPanel = !_showLabPanel);
              if (_showLabPanel) {
                _labAnimCtrl.forward(from: 0);
              } else {
                _labAnimCtrl.reverse();
              }
            },
          ),
          const SizedBox(width: 8),
          _v4DockBtn(icon: Icons.lightbulb_rounded, label: 'Advice', isActive: false, onTap: () {
            setState(() {
              _isDigitalMode = false; // Auto-switch to Note mode so it's visible
              _notesCtrl.text += '\n\nAdvice:\n- ';
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added Advice Section')));
          }),
          const SizedBox(width: 8),
          _v4DockBtn(icon: Icons.calendar_month_rounded, label: 'Follow-up', isActive: false, onTap: () {
            setState(() {
              _isDigitalMode = false; // Auto-switch to Note mode so it's visible
              _notesCtrl.text += '\n\nFollow-up: After 5 days.';
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added Follow-up Section')));
          }),
          const SizedBox(width: 8),
          _v4DockBtn(icon: Icons.mic_rounded, label: 'Voice', isActive: _isListening, onTap: () {
            if (_isListening) {
              _stopListening();
            } else {
              _startListening();
            }
          }),
        ],
      ),
    );
  }

  Widget _v4DockBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? _v4PrimaryGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: isActive ? _v4White : _v4TextSecondary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? _v4White : _v4TextSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _v4Error,
                  shape: BoxShape.circle,
                  border: Border.all(color: _v4White, width: 1.5),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 9,
                    color: _v4White,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  //  LAB OVERLAY (bottom sheet)
  // ---------------------------------------------------------
  Widget _buildLabOverlay() {
    final List<String> depts = ['Pathology', 'Radiology', 'Other'];
    final filtered = _allLabServices.where((s) {
      return s['category'] == _selectedDept &&
          (_labSearchQuery.isEmpty ||
              (s['service_name'] ?? '').toString().toLowerCase().contains(
                _labSearchQuery.toLowerCase(),
              ));
    }).toList();

    return GestureDetector(
      onTap: () => setState(() => _showLabPanel = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: AnimatedBuilder(
              animation: _labAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, (1 - _labAnim.value) * 500),
                child: child,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.74,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    _labHeader(filtered.length),
                    _labSearchBar(),
                    const SizedBox(height: 8),
                    _labDeptTabs(depts),
                    const SizedBox(height: 8),
                    Expanded(child: _labGrid(filtered)),
                    if (_selectedTests.isNotEmpty) _labSelectionTray(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _labHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.science_rounded,
              color: Color(0xFF7C3AED),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lab & Radiology Tests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _slate,
                  ),
                ),
                Text(
                  '$count tests in $_selectedDept',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedTests.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedTests.length} selected',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _showLabPanel = false),
            child: const Icon(
              Icons.close_rounded,
              color: Colors.blueGrey,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _labSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _labSearchCtrl,
        onChanged: (v) => setState(() => _labSearchQuery = v),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.blueGrey,
            size: 18,
          ),
          hintText: 'Search tests in $_selectedDept...',
          hintStyle: const TextStyle(fontSize: 12),
          filled: true,
          fillColor: const Color(0xFFF3EFE6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          isDense: true,
          suffixIcon: _labSearchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () {
                    _labSearchCtrl.clear();
                    setState(() => _labSearchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _labDeptTabs(List<String> depts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: depts.map((dept) {
          final isSel = _selectedDept == dept;
          final count = _allLabServices
              .where((s) => s['category'] == dept)
              .length;
          final icon = dept == 'Pathology'
              ? Icons.biotech_rounded
              : dept == 'Radiology'
              ? Icons.blur_circular_rounded
              : Icons.medical_services_rounded;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedDept = dept;
                  _labSearchQuery = '';
                  _labSearchCtrl.clear();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSel
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFFF3EFE6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSel
                        ? Colors.transparent
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF7C3AED,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSel ? Colors.white : Colors.blueGrey,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dept,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isSel ? Colors.white : Colors.blueGrey,
                      ),
                    ),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 8.5,
                        color: isSel
                            ? Colors.white.withValues(alpha: 0.75)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _labGrid(List<Map<String, dynamic>> list) {
    if (_isLoadingLabs)
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
      );
    if (list.isEmpty)
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 44,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 8),
            Text(
              _labSearchQuery.isNotEmpty
                  ? 'No tests match "$_labSearchQuery"'
                  : 'No tests in $_selectedDept',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final test = list[i];
        final testId = test['service_id'].toString();
        final testName = test['service_name'].toString();
        final isSel = _selectedTests.contains(testId);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (isSel)
                _selectedTests.remove(testId);
              else
                _selectedTests.add(testId);
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSel
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSel
                    ? const Color(0xFF7C3AED)
                    : Colors.grey.withValues(alpha: 0.2),
                width: isSel ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF7C3AED) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel
                          ? const Color(0xFF7C3AED)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: isSel
                      ? const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    testName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      color: isSel
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF374151),
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _labSelectionTray() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.science_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${_selectedTests.length} Test${_selectedTests.length > 1 ? "s" : ""} Selected',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: _slate,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedTests.clear()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _showLabPanel = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  //  PAGE CANVAS
  // ---------------------------------------------------------
  Widget _buildPageCanvas(
    int pageIndex,
    double pageWidth,
    double pageHeight, {
    Key? key,
  }) {
    return Container(
      key: key,
      width: pageWidth,
      height: pageHeight,
      decoration: BoxDecoration(
        color: _v4White,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // - Drawing canvas (isolated RepaintBoundary — no full-screen setState)
          Positioned.fill(
            child: DrawingCanvas(
              controller: _drawCtrl,
              pageIndex: pageIndex,
              enabled:
                  _isDrawingMode &&
                  !_showVitalsPanel &&
                  !_showLabPanel &&
                  !_rxCardVisible,
            ),
          ),
          // - Footer watermark
          Positioned(bottom: 20, left: 0, right: 0, child: _buildFooter()),
        ],
      ),
    );
  }

  // --- Side toolbar -----------------------------------------
  Widget _buildSideToolbar(R r) {
    return Positioned(
      left: 16,
      top: r.isPhone ? 140.0 : 180.0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: _v4White,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _v4ToolItem(Icons.edit_rounded, 'Pen', tooltip: 'Pen'),
            const SizedBox(height: 12),
            _v4ToolItem(Icons.brush_rounded, 'Marker', tooltip: 'Highlighter'),
            const SizedBox(height: 12),
            _v4ToolItem(Icons.auto_fix_normal_rounded, 'Eraser', tooltip: 'Eraser'),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(width: 20, child: Divider(height: 1, color: _v4Divider)),
            ),
            
            _colorDot(Colors.black),
            const SizedBox(height: 12),
            _colorDot(const Color(0xFF0284C7)),
            const SizedBox(height: 12),
            _colorDot(const Color(0xFFDC2626)),
            const SizedBox(height: 12),
            _colorDot(_v4PrimaryGreen),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(width: 20, child: Divider(height: 1, color: _v4Divider)),
            ),
            
            _v4ActionItem(Icons.undo_rounded, 'Undo', () => _drawCtrl.undo()),
            const SizedBox(height: 12),
            _v4ActionItem(Icons.delete_sweep_rounded, 'Clear', () => _drawCtrl.clearPage()),
          ],
        ),
      ),
    );
  }

  Widget _v4ToolItem(IconData icon, String toolName, {required String tooltip}) {
    final bool isSelected = _drawCtrl.tool == toolName;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          setState(() => _drawCtrl.tool = toolName);
          HapticFeedback.selectionClick();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? _v4PrimaryGreen : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.white : _v4TextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _v4ActionItem(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          onTap();
          HapticFeedback.mediumImpact();
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: _v4TextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _toolAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _colorDot(Color color) {
    final active = _drawCtrl.strokeColor == color;
    return GestureDetector(
      onTap: () => setState(() => _drawCtrl.strokeColor = color),
      child: Container(
        width: 22,
        height: 22,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: active ? Border.all(color: Colors.white, width: 2.5) : null,
          boxShadow: active
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
              : null,
        ),
      ),
    );
  }

  Widget _sizeBtn(double size, String label) {
    final active = _drawCtrl.strokeSize == size;
    // Dot diameter visually represents stroke thickness
    final dotD = size == 1.5 ? 5.0 : 9.0;
    return GestureDetector(
      onTap: () => setState(() => _drawCtrl.strokeSize = size),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34,
        height: 34,
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.black87 : Colors.transparent,
          shape: BoxShape.circle,
          border: active ? null : Border.all(color: Colors.black12, width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: dotD,
              height: dotD,
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.black54,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.black45,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Page selector -----------------------------------------
  Widget _buildPageSelector() {
    final pageCount = _drawCtrl.pageCount;
    final currentPage = _drawCtrl.currentPage;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(pageCount, (i) {
                final active = currentPage == i;
                return GestureDetector(
                  onTap: () {
                    _drawCtrl.switchPage(i);
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: active ? _teal : const Color(0xFFF3EFE6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: active
                            ? Colors.transparent
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: _teal.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          active
                              ? Icons.description
                              : Icons.description_outlined,
                          size: 13,
                          color: active ? Colors.white : Colors.black54,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'PG ${i + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: active ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (pageCount > 1) ...[
                          const SizedBox(width: 7),
                          GestureDetector(
                            onTap: () => _removePage(i),
                            child: Icon(
                              Icons.close_rounded,
                              size: 12,
                              color: active
                                  ? Colors.white.withValues(alpha: 0.75)
                                  : Colors.black38,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _addPage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF7DD3FC).withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 15,
                        color: Color(0xFF0284C7),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'ADD',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  //  SMART FORM MODE
  Widget _buildSmartFormMode(R r, double width, double height) {
    return Column(
      children: [
        _buildPremiumHeader(),

        Expanded(
          child: Stack(
            children: [
              // The massive advanced text editor
              Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
                      child: TextField(
                        controller: _notesCtrl,
                        focusNode: _notesFocusNode,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.8,
                          color: _v4TextPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Start clinical documentation here...\n\nTap the magic wand for templates or use voice dictation.',
                          hintStyle: TextStyle(
                            color: _v4TextSecondary.withValues(alpha: 0.5),
                            fontSize: 18,
                            height: 1.8,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  if (_showStylusInk)
                    Container(
                      height: 280,
                      margin: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        bottom: 80,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Stylus Feature Bar
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'STYLUS INPUT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.blueGrey.shade400,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    if (_isAIProcessing) ...[
                                      const SizedBox(width: 12),
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: _v4PrimaryGreen),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'AI Contextualizing...',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _v4PrimaryGreen,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const Spacer(),
                                _stylusAction(
                                  Icons.undo_rounded,
                                  'Undo',
                                  _inkUndo,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 12),
                                _stylusAction(
                                  Icons.delete_outline_rounded,
                                  'Clear',
                                  _inkClear,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 12),
                                _stylusAction(
                                  Icons.keyboard_return_rounded,
                                  'Next Line',
                                  () => setState(() => _notesCtrl.text += '\n'),
                                  color: _teal,
                                ),
                                const SizedBox(width: 12),
                                _stylusAction(
                                  Icons.close_rounded,
                                  'Cancel',
                                  () => setState(() => _showStylusInk = false),
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: RepaintBoundary(
                                    child: Listener(
                                      onPointerDown: (e) {
                                        _inkRecognitionTimer?.cancel();
                                        _inkSaveUndo();
                                        _ink.strokes.add(ml.Stroke());
                                        _addInkPoint(e.localPosition);
                                        _inkRepaintNotifier.notifyListeners();
                                      },
                                      onPointerMove: (e) {
                                        _addInkPoint(e.localPosition);
                                        _inkRepaintNotifier.notifyListeners();
                                      },
                                      onPointerUp: (e) {
                                        _addInkPoint(e.localPosition);
                                        _inkRepaintNotifier.notifyListeners();
                                        if (_isInkRecognitionEnabled) {
                                          _inkRecognitionTimer?.cancel();
                                          _inkRecognitionTimer = Timer(
                                            const Duration(milliseconds: 600),
                                            () {
                                              if (_ink.strokes.isNotEmpty)
                                                _recognizeText();
                                            },
                                          );
                                        }
                                      },
                                      child: CustomPaint(
                                        painter: InkPainter(
                                          ink: _ink,
                                          repaint: _inkRepaintNotifier,
                                        ),
                                        size: Size.infinite,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              // AI Smart Suggestions Bar
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    height: 35,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _aiSuggestionChip('Advise rest and hydration.'),
                        _aiSuggestionChip('Rx Paracetamol 500mg'),
                        _aiSuggestionChip('Order CBC Lab Test'),
                      ],
                    ),
                  ),
                ),
              ),
              // Floating Toolbar (bottom center)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Row 1: Primary Inputs
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _noteTool(
                                    icon: _isListening
                                        ? Icons.mic_rounded
                                        : Icons.mic_none_rounded,
                                    label: 'Dictate',
                                    color: _isListening
                                        ? Colors.redAccent
                                        : _teal,
                                    active: _isListening,
                                    pulsate: _isListening,
                                    onTap: _isListening
                                        ? _stopListening
                                        : _startListening,
                                  ),
                                  _vSpacer(),
                                  _noteTool(
                                    icon: Icons.access_time_rounded,
                                    label: 'Timestamp',
                                    color: Colors.blueGrey,
                                    onTap: () {
                                      setState(
                                        () => _notesCtrl.text +=
                                            '\n[${DateFormat('hh:mm a').format(DateTime.now())}] - ',
                                      );
                                    },
                                  ),
                                  _vSpacer(),
                                  _noteTool(
                                    icon: Icons.draw_rounded,
                                    label: 'Stylus',
                                    color: _showStylusInk
                                        ? const Color(0xFF7C3AED)
                                        : Colors.blueGrey,
                                    active: _showStylusInk,
                                    onTap: () {
                                      if (!_showStylusInk) {
                                        _notesFocusNode.unfocus();
                                      }
                                      setState(
                                        () => _showStylusInk = !_showStylusInk,
                                      );
                                    },
                                  ),
                                  _vSpacer(),
                                  _noteTool(
                                    icon: Icons.backspace_outlined,
                                    label: 'Del Word',
                                    color: Colors.redAccent,
                                    onTap: _deleteLastWord,
                                  ),
                                  _vSpacer(),
                                  _noteTool(
                                    icon: Icons.highlight_rounded,
                                    label: 'Highlight',
                                    color: Colors.amber,
                                    onTap: () {
                                      final sel = _notesCtrl.selection;
                                      if (sel.isValid && !sel.isCollapsed) {
                                        final current = _notesCtrl.text;
                                        final before = current.substring(
                                          0,
                                          sel.start,
                                        );
                                        final targeted = current.substring(
                                          sel.start,
                                          sel.end,
                                        );
                                        final after = current.substring(
                                          sel.end,
                                        );
                                        setState(
                                          () => _notesCtrl.text =
                                              "$before::$targeted::$after",
                                        );
                                      } else {
                                        setState(
                                          () => _notesCtrl.text += " :: :: ",
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Row 2: Structure & AI
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _iconTool(
                                    Icons.format_list_bulleted_rounded,
                                    () => setState(
                                      () => _notesCtrl.text += '\n ',
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _iconTool(
                                    Icons.format_list_numbered_rounded,
                                    () => setState(
                                      () => _notesCtrl.text += '\n1. ',
                                    ),
                                  ),
                                  _vSpacer(),
                                  _noteTool(
                                    icon: Icons.history_rounded,
                                    label: 'Timeline',
                                    color: const Color(0xFF7C3AED),
                                    onTap: _showTimelinePanel,
                                  ),
                                  _vSpacer(),
                                  _noteTool(
                                    icon: Icons.psychology_alt_rounded,
                                    label: 'SOAP Auto',
                                    color: const Color(0xFFE11D48), // Rose
                                    onTap: _formatSOAP,
                                  ),
                                  _vSpacer(),
                                  _noteTool(
                                    icon: Icons.auto_awesome_motion_rounded,
                                    label: 'Templates',
                                    color: Colors.orange,
                                    onTap: _showTemplateMenu,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _slate,
            ),
          ),
        ],
      ),
    );
  }

  // Deleted _buildVitalsFormGrid and _buildNotesSection!

  void _formatSOAP() {
    String raw = _notesCtrl.text;
    if (raw.trim().isEmpty) return;

    // Professional Clinical SOAP Layout with dividers
    const div = "----------------------------------------\n";
    String structured =
        "SUBJECTIVE:\n" +
        raw.trim() +
        "\n\n" +
        div +
        "OBJECTIVE:\n\n" +
        div +
        "ASSESSMENT:\n[Handwritten context will appear here]\n\n" +
        div +
        "PLAN:\n[Suggested medications and follow-up]";

    setState(() => _notesCtrl.text = structured);
    HapticFeedback.heavyImpact();
  }

  void _deleteLastWord() {
    setState(() {
      String text = _notesCtrl.text.trimRight();
      if (text.isEmpty) return;
      List<String> words = text.split(' ');
      if (words.isNotEmpty) {
        words.removeLast();
        _notesCtrl.text = words.join(' ');
        if (_notesCtrl.text.isNotEmpty)
          _notesCtrl.text += ' '; // Keep a trailing space
      }
    });
    HapticFeedback.lightImpact();
  }

  void _showCompareNotesOverlay(String date, String pastNoteText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.compare_arrows_rounded,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Compare Notes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _slate,
                        ),
                      ),
                      Text(
                        'Past Visit ($date) vs Current Note',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.blueGrey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Pane: Past Note
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EFE6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PAST NOTE: $date',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const Divider(height: 24),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                pastNoteText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: _slate,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right Pane: Current Note
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _teal.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CURRENT NOTE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _teal,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const Divider(height: 24),
                          Expanded(
                            child: TextField(
                              controller: _notesCtrl,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Active clinical note...',
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: _slate,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Done Comparing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _inkSaveUndo() {
    // deep copy the current ink state
    final clone = ml.Ink();
    for (final s in _ink.strokes) {
      final newStroke = ml.Stroke();
      for (final p in s.points) {
        newStroke.points.add(ml.StrokePoint(x: p.x, y: p.y, t: p.t));
      }
      clone.strokes.add(newStroke);
    }
    _inkUndoStack.add(clone);
    if (_inkUndoStack.length > 30) _inkUndoStack.removeAt(0);
  }

  void _inkUndo() {
    _inkRecognitionTimer?.cancel();
    if (_inkUndoStack.isEmpty) return;
    _ink.strokes.clear();
    final last = _inkUndoStack.removeLast();
    for (final s in last.strokes) {
      _ink.strokes.add(s);
    }
    _inkRepaintNotifier.notifyListeners();
    // Re-trigger recognition for the modified state
    if (_ink.strokes.isNotEmpty)
      _recognizeText();
    else
      setState(() => _inkSuggestions.clear());
  }

  void _inkClear() {
    _inkSaveUndo();
    setState(() {
      _ink.strokes.clear();
    });
    _inkRepaintNotifier.notifyListeners();
  }

  Widget _stylusAction(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color color = Colors.blueGrey,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inkStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isInkRecognitionEnabled ? _teal : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isInkRecognitionEnabled
              ? _teal
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 12,
            color: _isInkRecognitionEnabled ? Colors.white : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            'AUTO-CONVERT',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: _isInkRecognitionEnabled ? Colors.white : Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        setState(
          () => _notesCtrl.text += (_notesCtrl.text.isEmpty ? "" : " ") + text,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.indigo.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 12,
              color: Colors.indigo,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteTool({
    required IconData icon,
    required String label,
    required Color color,
    bool pulsate = false,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.8)
              : (pulsate ? color.withValues(alpha: 0.15) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconTool(
    IconData icon,
    VoidCallback onTap, {
    Color color = Colors.blueGrey,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _vSpacer() => Container(
    width: 1,
    height: 20,
    color: Colors.grey.withValues(alpha: 0.2),
    margin: const EdgeInsets.symmetric(horizontal: 10),
  );

  void _showTimelinePanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient Timeline',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _slate,
                        ),
                      ),
                      Text(
                        'Compare previous visit notes',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.blueGrey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) {
                  final dates = ['12 Oct 2023', '05 Aug 2023', '10 Mar 2023'];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EFE6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dates[i],
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: _teal,
                              ),
                            ),
                            const Text(
                              'Dr. Smith (General)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Patient presented with mild fever. Advised paracetamol and rest. Vitals stable.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: _slate,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(
                                  () => _notesCtrl.text +=
                                      '\n\n--- Copied from ${dates[i]} ---\nPatient presented with mild fever. Advised paracetamol and rest. Vitals stable.',
                                );
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Copy to today\'s note',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                _showCompareNotesOverlay(
                                  dates[i],
                                  'Patient presented with mild fever. Advised paracetamol and rest. Vitals stable.',
                                );
                              },
                              child: const Text(
                                'Compare Side-by-Side',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateMenu() {
    final templates = {
      'OPD Routine':
          'Subjective:\nPatient presents with \n\nObjective:\nVitals stable.\n\nAssessment:\nRoutine checkup.\n\nPlan:\nContinue current medication.',
      'Emergency Consult':
          'Chief Complaint:\n\nPrimary Assessment:\n\nIntervention:\n\nDisposition:',
      'Follow-up':
          'Status since last visit:\n\nChanges in symptoms:\n\nNext steps:',
    };
    final quickPhrases = [
      'Patient is hemodynamically stable.',
      'No signs of respiratory distress.',
      'Advised high fluid intake.',
      'RTC if symptoms persist.',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_motion_rounded,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto Templates',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _slate,
                        ),
                      ),
                      Text(
                        'Insert predefined structures & phrases',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.blueGrey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'FULL TEMPLATES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.blueGrey,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: templates.entries
                  .map(
                    (e) => GestureDetector(
                      onTap: () {
                        setState(() {
                          _notesCtrl.text +=
                              (_notesCtrl.text.isEmpty ? "" : "\n\n") + e.value;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          e.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'QUICK PHRASES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.blueGrey,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: quickPhrases.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  leading: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: _teal,
                  ),
                  title: Text(
                    quickPhrases[i],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _notesCtrl.text +=
                          (_notesCtrl.text.isEmpty ? "" : "\n") +
                          quickPhrases[i];
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Deleted _buildRxFormSection and _buildLabsPanel!

  // ---------------------------------------------------------
  //  PREMIUM HEADER
  // ---------------------------------------------------------
  Widget _buildPremiumHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.standardCard,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EFE6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.15),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/gm_logoo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.local_hospital_rounded, color: _teal),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GM HOSPITAL',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _slate,
                    ),
                  ),
                  Text(
                    'Clinical Portal',
                    style: TextStyle(fontSize: 10, color: Colors.blueGrey),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                decoration: BoxDecoration(
                  color: _tealLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: _teal, size: 15),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'DR. ${_doctor.fullName?.toUpperCase() ?? "DOCTOR"}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: _teal,
                          ),
                        ),
                        Text(
                          _doctor.specialization?.toUpperCase() ??
                              'GENERAL MEDICINE',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(height: 1, color: const Color(0xFFF3EFE6)),
          ),
          Row(
            children: [
              _patientCard(
                'PATIENT',
                _appointment.patientName,
                Icons.person_rounded,
                flex: 3,
              ),
              const SizedBox(width: 10),
              _patientCard(
                'AGE / SEX',
                '${_appointment.age ?? "--"} / ${_appointment.gender ?? "--"}',
                Icons.face_rounded,
                flex: 2,
              ),
              const SizedBox(width: 10),
              _patientCard(
                'BLOOD',
                _appointment.bloodGroup ?? 'N/A',
                Icons.bloodtype_rounded,
                flex: 2,
                isRed: true,
              ),
              const SizedBox(width: 10),
              _patientCard(
                'DATE',
                DateFormat('dd MMM yyyy').format(DateTime.now()),
                Icons.calendar_month_rounded,
                flex: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _patientCard(
    String label,
    String value,
    IconData icon, {
    int flex = 1,
    bool isRed = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EFE6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isRed
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.blueGrey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 13,
                color: isRed ? Colors.red : Colors.blueGrey,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isRed ? Colors.red.shade700 : _slate,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CONFIDENTIAL MEDICAL RECORD',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Generated via Medinote Clinical Portal',
                style: TextStyle(fontSize: 7, color: Colors.grey),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 1.5,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 6),
              Text(
                _doctor.fullName ?? 'DOCTOR',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: _teal,
                ),
              ),
              const Text(
                'AUTHORIZED SIGNATURE',
                style: TextStyle(
                  fontSize: 6,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStatusDialog({required bool success, required String message}) {
    // Sanitize the message to ensure no ugly server file paths or raw HTML are shown to the user
    String safeMessage = message;
    if (safeMessage.toLowerCase().contains('htdocs') || safeMessage.toLowerCase().contains('.php on line') || safeMessage.contains('<b>')) {
      safeMessage = 'A server error occurred while processing your request. Please try again.';
    }
    safeMessage = safeMessage.replaceAll(RegExp(r'Exception:\s*'), '');

    showDialog(
      context: context,
      barrierDismissible: !success,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: success ? const Color(0xFF1F6B4A).withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon container
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 600),
                tween: Tween<double>(begin: 0.5, end: 1.0),
                curve: Curves.elasticOut,
                builder: (context, double scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: success ? const Color(0xFF1F6B4A).withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        success ? Icons.check_circle_rounded : Icons.error_rounded,
                        color: success ? const Color(0xFF1F6B4A) : Colors.redAccent,
                        size: 50,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                success ? 'Success!' : 'Action Failed',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                safeMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (success) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: success ? const Color(0xFF1F6B4A) : Colors.blueGrey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    success ? 'CONTINUE' : 'CLOSE',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





