import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:road_helperr/ui/screens/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  static const String routeName = "aboutscreen";

  final Color lightPrimary = const Color(0xFF023A87);
  final Color lightSecondary = const Color(0xFF86A5D9);
  final Color lightBackground = const Color(0xFFFDFEFF);

  const AboutScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'roadhelper200@gmail.com',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch email';
    }
  }

  @override
  Widget build(BuildContext context) {
    var lang = AppLocalizations.of(context)!;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.primaryBlue : lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [
                            AppColors.primaryBlue,
                            AppColors.primaryBlue.withOpacity(0.8)
                          ]
                        : [lightPrimary, lightSecondary],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              title: Text(
                lang.aboutUs,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  shadows: isDarkMode
                      ? null
                      : [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black.withOpacity(0.3),
                          )
                        ],
                ),
              ),
            ),
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: isDarkMode ? Colors.transparent : lightPrimary,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureCard(
                    icon: Icons.medical_services,
                    title: lang.emergencyServices,
                    content: lang.emergencyServicesDescription,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.local_gas_station,
                    title: lang.gasStations,
                    content: lang.gasStationsDescription,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.people,
                    title: lang.communityHelp,
                    content: lang.communityHelpDescription,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    lang.aboutTheApp,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : lightPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang.missionAndTechnologyDescription,
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white70
                          : lightPrimary.withOpacity(0.8),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoSection(isDarkMode, context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String content,
    required bool isDarkMode,
  }) {
    return Card(
      color: isDarkMode
          ? Colors.white.withOpacity(0.1)
          : lightSecondary.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: isDarkMode ? Colors.white : lightPrimary, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : lightPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white70
                          : lightPrimary.withOpacity(0.8),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(bool isDarkMode, BuildContext context) {
    var lang = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.1)
            : lightSecondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.info, lang.version, isDarkMode),
          _buildInfoRow(Icons.people_alt, lang.developer, isDarkMode),
          InkWell(
            onTap: _launchEmail,
            child: _buildInfoRow(
              Icons.email,
              lang.contactEmail,
              isDarkMode,
              isEmail: true,
            ),
          ),
          _buildInfoRow(Icons.copyright, lang.allRightsReserved, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDarkMode,
      {bool isEmail = false}) {
    final textColor =
        isDarkMode ? Colors.white70 : const Color(0xFF023A87).withOpacity(0.8);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: isEmail
                  ? isDarkMode
                      ? Colors.blue[200]
                      : const Color(0xFF023A87)
                  : textColor,
              size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isEmail
                    ? isDarkMode
                        ? Colors.blue[200]
                        : const Color(0xFF023A87)
                    : textColor,
                fontSize: 14,
                height: 1.3,
                decoration: isEmail ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
