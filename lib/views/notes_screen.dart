import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  int _selectedCategory = 0;
  late AnimationController _fadeCtrl;

  static const List<_NoteCategory> _categories = [
    _NoteCategory(label: 'Clinical',     icon: Icons.local_hospital_outlined, color: Color(0xFF1F6B4A)),
    _NoteCategory(label: 'Research',     icon: Icons.science_outlined,        color: Color(0xFF3B82F6)),
    _NoteCategory(label: 'Observations', icon: Icons.visibility_outlined,     color: Color(0xFF8B5CF6)),
    _NoteCategory(label: 'Personal',     icon: Icons.person_outline_rounded,  color: Color(0xFFF59E0B)),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: CustomScrollView(
          slivers: [
            // ── Command Header ──────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader()),

            // ── Category Chips ──────────────────────────────────────────
            SliverToBoxAdapter(child: _buildCategoryRow()),

            // ── Empty State (no notes yet) ──────────────────────────────
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildCommandEmptyState(),
            ),
          ],
        ),
      ),

      // ── Primary action ─────────────────────────────────────────────────
      floatingActionButton: _buildFab(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Header
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cmdBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.cmdBorder, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text(
                        'CLINICAL NOTES',
                        style: TextStyle(
                          color: AppColors.cmdTeal,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('LIVE',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          )),
                    ]),
                    const SizedBox(height: 6),
                    const Text(
                      'Session Log',
                      style: AppStyles.darkHeading,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your private clinical notebook — secure and encrypted.',
                      style: AppStyles.darkCaption,
                    ),
                  ],
                ),
              ),
              // Right badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm + 4),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: const Icon(
                  Icons.note_alt_outlined,
                  color: AppColors.cmdTeal,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Category chips
  // ─────────────────────────────────────────────────────────────

  Widget _buildCategoryRow() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _categories.asMap().entries.map((e) {
            final isSelected = _selectedCategory == e.key;
            final cat = e.value;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cat.color.withValues(alpha: 0.12)
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected
                          ? cat.color.withValues(alpha: 0.35)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(cat.icon,
                          size: 14,
                          color: isSelected ? cat.color : AppColors.textTertiary),
                      const SizedBox(width: 7),
                      Text(
                        cat.label,
                        style: TextStyle(
                          color: isSelected ? cat.color : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Command Center Empty State
  // ─────────────────────────────────────────────────────────────

  Widget _buildCommandEmptyState() {
    final cat = _categories[_selectedCategory];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                  color: cat.color.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Icon(cat.icon, size: 40, color: cat.color.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 28),
          Text(
            'No ${cat.label} Notes Yet',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.3),
          ),
          const SizedBox(height: 10),
          Text(
            'Keep track of patient observations,\ncase studies, and medical insights here.\nYour notes are private and secure.',
            textAlign: TextAlign.center,
            style: AppStyles.caption.copyWith(height: 1.7, fontSize: 13),
          ),
          const SizedBox(height: 36),
          // Create Note primary button
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cat.color, cat.color.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.colorGlow(cat.color, intensity: 0.25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'CREATE ${cat.label.toUpperCase()} NOTE',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Secondary: Quick note outline
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.drive_file_rename_outline_rounded, size: 16),
            label: const Text('Quick Note'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  FAB
  // ─────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.tealGlow(),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('New Note',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteCategory {
  final String label;
  final IconData icon;
  final Color color;
  const _NoteCategory({required this.label, required this.icon, required this.color});
}

