import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/tv_auth_provider.dart';
import '../utils/color.dart';
import '../widgets/tv_focusable.dart';

class TVLoginPage extends StatefulWidget {
  const TVLoginPage({super.key});

  @override
  State<TVLoginPage> createState() => _TVLoginPageState();
}

class _TVLoginPageState extends State<TVLoginPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<TVAuthProvider>(context, listen: false);
      if (!auth.isLoggedIn) {
        auth.requestTVCode();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<TVAuthProvider>(context);

    return Scaffold(
      backgroundColor: TVColors.appBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Back Button
              TVFocusable(
                onPressed: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: auth.isLoggedIn
                    ? _buildLoggedInView(auth)
                    : _buildActivationCodeView(auth),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedInView(TVAuthProvider auth) {
    return Center(
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: TVColors.surfaceBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle_rounded, color: TVColors.accent, size: 72),
            const SizedBox(height: 16),
            Text(
              auth.currentUser?.name ?? "Pengguna Nexstream",
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              auth.currentUser?.email ?? "",
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: TVColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),

            TVFocusable(
              onPressed: () async {
                await auth.logout();
                if (mounted) {
                  auth.requestTVCode();
                }
              },
              borderRadius: BorderRadius.circular(8),
              focusBorderColor: TVColors.primary,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Keluar Akun",
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivationCodeView(TVAuthProvider auth) {
    final code = auth.tvCode ?? "----";
    final characters = code.padRight(4, '-').split('');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Column: Instructions and 4-Digit Boxes
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Aktivasi Akun di Smart TV",
                style: GoogleFonts.outfit(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Masuk ke akun Nexstream Anda dengan mudah tanpa mengetik kata sandi di TV.",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: TVColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Steps
              _buildStep("1", "Buka aplikasi Nexstream di Smartphone Anda"),
              const SizedBox(height: 12),
              _buildStep("2", "Buka menu Profil lalu pilih 'Aktifkan TV'"),
              const SizedBox(height: 12),
              _buildStep("3", "Masukkan 4 digit kode di bawah ini:"),
              const SizedBox(height: 24),

              // Code Boxes
              Row(
                children: characters.map((char) {
                  return Container(
                    width: 58,
                    height: 64,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: TVColors.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: TVColors.primary.withValues(alpha: 0.60),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: TVColors.primary.withValues(alpha: 0.25),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      char,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Status / Refresh Button
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TVColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Menunggu konfirmasi dari smartphone...",
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: TVColors.accent,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 20),
                  TVFocusable(
                    onPressed: () => auth.requestTVCode(),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Muat Ulang Kode",
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Right Column: QR Code
        Expanded(
          flex: 4,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: QrImageView(
                data: code.isNotEmpty ? "nexstream://tv_login?code=$code" : "nexstream://tv_login",
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String num, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: TVColors.primary.withValues(alpha: 0.20),
            shape: BoxShape.circle,
            border: Border.all(color: TVColors.primary, width: 1.2),
          ),
          alignment: Alignment.center,
          child: Text(
            num,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: TVColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
