import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/tv_auth_provider.dart';
import '../providers/tv_home_provider.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          width: 560,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 26),
          decoration: BoxDecoration(
            color: TVColors.surfaceBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.50),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Profiles (Left) and Edit (Right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Profiles",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  TVFocusable(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: TVColors.surfaceBg,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: TVColors.primary.withValues(alpha: 0.3)),
                          ),
                          content: Text(
                            "Kelola nama atau avatar profil dapat dilakukan melalui aplikasi Nexstream di Smartphone atau Web.",
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    focusBorderColor: TVColors.primary,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/ic_edit.png',
                            width: 14,
                            height: 14,
                            color: TVColors.primary,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.edit_outlined,
                              color: TVColors.primary,
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Edit",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: TVColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 2. Profiles Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile
                  _buildProfileItem(
                    name: (auth.currentUser?.name?.isNotEmpty == true)
                        ? auth.currentUser!.name!
                        : "User",
                    image: auth.currentUser?.image,
                    isActive: !Constant.userIsKid,
                    isKid: false,
                    onTap: () async {
                      if (Constant.userIsKid) {
                        await auth.switchProfile(isKid: false);
                        if (mounted) {
                          Provider.of<TVHomeProvider>(context, listen: false).reloadForProfileChange();
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 24),

                  // Kids Profile
                  _buildProfileItem(
                    name: "Kids",
                    image: null,
                    isActive: Constant.userIsKid,
                    isKid: true,
                    onTap: () async {
                      if (!Constant.userIsKid) {
                        await auth.switchProfile(isKid: true);
                        if (mounted) {
                          Provider.of<TVHomeProvider>(context, listen: false).reloadForProfileChange();
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Subtle divider
              Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
              const SizedBox(height: 16),

              // 3. Account Info Row
              Row(
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    color: TVColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      auth.currentUser?.email?.isNotEmpty == true
                          ? auth.currentUser!.email!
                          : (auth.currentUser?.name ?? "Pengguna Nexstream"),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: TVColors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: TVColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TVColors.primary.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      Constant.userIsKid ? "Profil Anak Aktif" : "Profil Utama Aktif",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: TVColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Logout Button
              TVFocusable(
                onPressed: () async {
                  await auth.logout();
                  if (mounted) {
                    auth.requestTVCode();
                  }
                },
                borderRadius: BorderRadius.circular(10),
                focusBorderColor: Colors.redAccent,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Keluar Akun",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildProfileItem({
    required String name,
    required String? image,
    required bool isActive,
    required bool isKid,
    required VoidCallback onTap,
  }) {
    final String initial = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : (isKid ? 'K' : 'U');

    return TVFocusable(
      onPressed: onTap,
      scaleFactor: 1.08,
      borderRadius: BorderRadius.circular(46),
      focusBorderColor: TVColors.primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 84,
            height: 90,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // Circular Avatar
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? Colors.white : Colors.transparent,
                      width: 2.0,
                    ),
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: ClipOval(
                    child: isKid
                        ? Image.asset(
                            'assets/images/kids.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFF39C12),
                              alignment: Alignment.center,
                              child: Text(
                                "KiDS",
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : (image != null && image.isNotEmpty && !image.contains('no_img')
                            ? Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildLetterAvatar(initial),
                              )
                            : _buildLetterAvatar(initial)),
                  ),
                ),

                // Active dot indicator at the bottom edge of the circle
                if (isActive)
                  Positioned(
                    bottom: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(1.5),
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: TVColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 90,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterAvatar(String initial) {
    return Container(
      color: const Color(0xFFBA3928),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActivationCodeView(TVAuthProvider auth) {
    final code = auth.tvCode ?? "----";
    final characters = code.padRight(4, '-').split('');

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Column: Instructions and 4-Digit Boxes
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Aktivasi Akun di Smart TV",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Masuk ke akun Nexstream Anda dengan mudah tanpa mengetik kata sandi di TV.",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: TVColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Steps
                  _buildStep("1", "Buka aplikasi Nexstream di Smartphone Anda"),
                  const SizedBox(height: 8),
                  _buildStep("2", "Buka menu Profil lalu pilih 'Aktifkan TV'"),
                  const SizedBox(height: 8),
                  _buildStep("3", "Masukkan 4 digit kode di bawah ini:"),
                  const SizedBox(height: 16),

                  // Code Boxes
                  Row(
                    children: characters.map((char) {
                      return Container(
                        width: 48,
                        height: 52,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: TVColors.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: TVColors.primary.withValues(alpha: 0.60),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: TVColors.primary.withValues(alpha: 0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          char,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Status / Refresh Button
                  Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: TVColors.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Menunggu konfirmasi dari smartphone...",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: TVColors.accent,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 14),
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
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.15),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: code.isNotEmpty && code != "----" ? "nexstream://tv_login?code=$code" : "nexstream://tv_login",
                    version: QrVersions.auto,
                    size: 155.0,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: TVColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
