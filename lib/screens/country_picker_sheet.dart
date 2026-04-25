import 'package:flutter/material.dart';

// ─── Country model ────────────────────────────────────────────────────────────
class CountryEntry {
  final String flag;
  final String name;
  final String dialCode;

  /// Expected number of digits the user types locally.
  /// 0 = flexible (7–15 digits accepted).
  final int expectedLocalDigits;

  const CountryEntry({
    required this.flag,
    required this.name,
    required this.dialCode,
    this.expectedLocalDigits = 0,
  });
}

// ─── Country list (Bangladesh default / first) ────────────────────────────────
const kCountries = <CountryEntry>[
  // ── South Asia ──
  CountryEntry(flag: '🇧🇩', name: 'Bangladesh',  dialCode: '+880', expectedLocalDigits: 11),
  CountryEntry(flag: '🇮🇳', name: 'India',        dialCode: '+91',  expectedLocalDigits: 10),
  CountryEntry(flag: '🇵🇰', name: 'Pakistan',     dialCode: '+92',  expectedLocalDigits: 10),
  CountryEntry(flag: '🇳🇵', name: 'Nepal',        dialCode: '+977', expectedLocalDigits: 10),
  CountryEntry(flag: '🇱🇰', name: 'Sri Lanka',    dialCode: '+94',  expectedLocalDigits: 10),
  CountryEntry(flag: '🇲🇻', name: 'Maldives',     dialCode: '+960', expectedLocalDigits: 7),
  CountryEntry(flag: '🇧🇹', name: 'Bhutan',       dialCode: '+975', expectedLocalDigits: 8),
  CountryEntry(flag: '🇲🇲', name: 'Myanmar',      dialCode: '+95',  expectedLocalDigits: 9),
  // ── Middle East ──
  CountryEntry(flag: '🇸🇦', name: 'Saudi Arabia', dialCode: '+966', expectedLocalDigits: 9),
  CountryEntry(flag: '🇦🇪', name: 'UAE',          dialCode: '+971', expectedLocalDigits: 9),
  CountryEntry(flag: '🇶🇦', name: 'Qatar',        dialCode: '+974', expectedLocalDigits: 8),
  CountryEntry(flag: '🇰🇼', name: 'Kuwait',       dialCode: '+965', expectedLocalDigits: 8),
  CountryEntry(flag: '🇧🇭', name: 'Bahrain',      dialCode: '+973', expectedLocalDigits: 8),
  CountryEntry(flag: '🇴🇲', name: 'Oman',         dialCode: '+968', expectedLocalDigits: 8),
  CountryEntry(flag: '🇮🇶', name: 'Iraq',         dialCode: '+964'),
  CountryEntry(flag: '🇮🇷', name: 'Iran',         dialCode: '+98'),
  // ── Southeast Asia ──
  CountryEntry(flag: '🇲🇾', name: 'Malaysia',     dialCode: '+60',  expectedLocalDigits: 10),
  CountryEntry(flag: '🇸🇬', name: 'Singapore',    dialCode: '+65',  expectedLocalDigits: 8),
  CountryEntry(flag: '🇹🇭', name: 'Thailand',     dialCode: '+66',  expectedLocalDigits: 9),
  CountryEntry(flag: '🇮🇩', name: 'Indonesia',    dialCode: '+62',  expectedLocalDigits: 11),
  CountryEntry(flag: '🇵🇭', name: 'Philippines',  dialCode: '+63',  expectedLocalDigits: 10),
  CountryEntry(flag: '🇻🇳', name: 'Vietnam',      dialCode: '+84',  expectedLocalDigits: 10),
  // ── East Asia ──
  CountryEntry(flag: '🇨🇳', name: 'China',        dialCode: '+86',  expectedLocalDigits: 11),
  CountryEntry(flag: '🇯🇵', name: 'Japan',        dialCode: '+81',  expectedLocalDigits: 10),
  CountryEntry(flag: '🇰🇷', name: 'South Korea',  dialCode: '+82',  expectedLocalDigits: 10),
  // ── North America ──
  CountryEntry(flag: '🇺🇸', name: 'United States',dialCode: '+1',   expectedLocalDigits: 10),
  CountryEntry(flag: '🇨🇦', name: 'Canada',       dialCode: '+1',   expectedLocalDigits: 10),
  // ── Europe ──
  CountryEntry(flag: '🇬🇧', name: 'United Kingdom',dialCode: '+44', expectedLocalDigits: 10),
  CountryEntry(flag: '🇩🇪', name: 'Germany',      dialCode: '+49'),
  CountryEntry(flag: '🇫🇷', name: 'France',       dialCode: '+33',  expectedLocalDigits: 9),
  CountryEntry(flag: '🇮🇹', name: 'Italy',        dialCode: '+39'),
  CountryEntry(flag: '🇪🇸', name: 'Spain',        dialCode: '+34',  expectedLocalDigits: 9),
  CountryEntry(flag: '🇹🇷', name: 'Turkey',       dialCode: '+90',  expectedLocalDigits: 10),
  // ── Oceania ──
  CountryEntry(flag: '🇦🇺', name: 'Australia',    dialCode: '+61',  expectedLocalDigits: 9),
  CountryEntry(flag: '🇳🇿', name: 'New Zealand',  dialCode: '+64',  expectedLocalDigits: 9),
  // ── Africa ──
  CountryEntry(flag: '🇿🇦', name: 'South Africa', dialCode: '+27',  expectedLocalDigits: 9),
  CountryEntry(flag: '🇳🇬', name: 'Nigeria',      dialCode: '+234', expectedLocalDigits: 10),
  CountryEntry(flag: '🇪🇬', name: 'Egypt',        dialCode: '+20',  expectedLocalDigits: 10),
  // ── Latin America ──
  CountryEntry(flag: '🇧🇷', name: 'Brazil',       dialCode: '+55'),
  CountryEntry(flag: '🇲🇽', name: 'Mexico',       dialCode: '+52'),
];

// ─── Show bottom sheet helper ─────────────────────────────────────────────────
Future<CountryEntry?> showCountryPicker(BuildContext context) {
  return showModalBottomSheet<CountryEntry>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CountryPickerSheet(),
  );
}

// ─── Bottom sheet widget ──────────────────────────────────────────────────────
class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<CountryEntry> _filtered = kCountries;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String q) {
    final lower = q.toLowerCase().trim();
    setState(() {
      _filtered = lower.isEmpty
          ? kCountries
          : kCountries
              .where((c) =>
                  c.name.toLowerCase().contains(lower) ||
                  c.dialCode.contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxH       = MediaQuery.of(context).size.height * 0.78;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Country',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              autofocus: true,
              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'Search country or dial code...',
                hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8), fontSize: 13.5),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF94A3B8), size: 20),
                filled: true,
                fillColor: const Color(0xFFF1F5FB),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE2E8F0), height: 1),

          // Country list
          Flexible(
            child: _filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No country found',
                      style: TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                        color: Color(0xFFE2E8F0),
                        height: 1,
                        indent: 16),
                    itemBuilder: (_, i) {
                      final c = _filtered[i];
                      return ListTile(
                        onTap: () => Navigator.pop(context, c),
                        leading: Text(c.flag,
                            style: const TextStyle(fontSize: 26)),
                        title: Text(
                          c.name,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Text(
                          c.dialCode,
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: safeBottom + 12),
        ],
      ),
    );
  }
}
