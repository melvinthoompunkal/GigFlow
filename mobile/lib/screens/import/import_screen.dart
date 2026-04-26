import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/colors.dart';
import '../../utils/backend_api.dart';

class ImportScreen extends StatefulWidget {
  final bool isModal;
  const ImportScreen({super.key, this.isModal = false});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _csvLoading = false;

  void _navigateAfterImport() {
    if (widget.isModal) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/income-dashboard');
    }
  }

  Future<void> _connectToBank() async {
    final provider = context.read<UserProfileProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _PlaidConnectSheet(),
    );
    if (!mounted) return;
    provider.setIsBankConnected(true);
    _navigateAfterImport();
  }

  void _useDemo() {
    context.read<UserProfileProvider>().activateDemoMode();
    _navigateAfterImport();
  }

  void _enterManually() {
    if (widget.isModal) {
      Navigator.pop(context);
      Navigator.pushNamed(context, '/onboarding');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  Future<void> _uploadCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    final file = result.files.single;
    setState(() => _csvLoading = true);
    try {
      final data = await uploadCsv(file.bytes!, file.name);
      if (!mounted) return;
      final provider = context.read<UserProfileProvider>();
      provider.update((p) => p.copyWith(
        monthlyEarnings: (data['monthlyAverage'] as num?)?.toInt() ?? p.monthlyEarnings,
        isOnboarded: true,
      ));
      _navigateAfterImport();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not parse CSV — is the backend running?'),
          backgroundColor: kRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _csvLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (widget.isModal) ...[
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: kTextSecondary, size: 24),
              ),
              const SizedBox(height: 16),
            ],
            RichText(text: TextSpan(children: [
              TextSpan(text: 'gig', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
              TextSpan(text: 'Flow', style: GoogleFonts.dmSans(color: kGreen, fontSize: 22, fontWeight: FontWeight.w800)),
            ])),
            const SizedBox(height: 8),
            Text('How would you like to get started?', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Choose how to import your financial data.', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 14)),
            const SizedBox(height: 28),
            _ImportCard(
              icon: Icons.account_balance_rounded,
              iconColor: kBlue,
              iconBg: kBlueBg,
              title: 'Connect to Bank',
              subtitle: 'Securely import your transactions via Plaid',
              onTap: _connectToBank,
            ),
            const SizedBox(height: 12),
            _ImportCard(
              icon: Icons.auto_awesome_rounded,
              iconColor: kGreen,
              iconBg: kGreenBg,
              title: 'Demo Mode',
              subtitle: 'Explore with sample data — no account needed',
              onTap: _useDemo,
            ),
            const SizedBox(height: 12),
            _ImportCard(
              icon: Icons.edit_rounded,
              iconColor: kAmber,
              iconBg: kAmberBg,
              title: 'Enter Manually',
              subtitle: 'Input your earnings step by step',
              onTap: _enterManually,
            ),
            const SizedBox(height: 12),
            _ImportCard(
              icon: Icons.upload_file_rounded,
              iconColor: kTeal,
              iconBg: const Color(0xFFECFEFE),
              title: 'Upload CSV',
              subtitle: 'Import earnings from Uber, DoorDash, Lyft and more',
              onTap: _csvLoading ? null : _uploadCsv,
              trailing: _csvLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: kTeal, strokeWidth: 2))
                  : null,
            ),
            const SizedBox(height: 36),
            Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_outline_rounded, color: kTextMuted, size: 13),
                const SizedBox(width: 5),
                Text('Your data stays private and secure', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 12)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ImportCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ImportCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: kCardDecoration(),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
          ])),
          trailing ?? Icon(Icons.chevron_right_rounded, color: onTap == null ? kBorder : kTextMuted, size: 20),
        ]),
      ),
    );
  }
}

class _PlaidConnectSheet extends StatefulWidget {
  const _PlaidConnectSheet();

  @override
  State<_PlaidConnectSheet> createState() => _PlaidConnectSheetState();
}

class _PlaidConnectSheetState extends State<_PlaidConnectSheet> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: kBlueBg, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.account_balance_rounded, color: kBlue, size: 28),
        ),
        const SizedBox(height: 16),
        Text('Connecting to Plaid...', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Securely linking your bank account', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 13)),
        const SizedBox(height: 24),
        const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          child: LinearProgressIndicator(color: kBlue, backgroundColor: kBorder, minHeight: 4),
        ),
      ]),
    );
  }
}
