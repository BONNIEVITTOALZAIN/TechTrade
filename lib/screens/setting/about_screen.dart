import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String appName = '';
  String packageName = '';
  String version = '';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    _getAppInfo();
  }

  Future<void> _getAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appName = info.appName;
      packageName = info.packageName;
      version = info.version;
      buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tentang Aplikasi',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoCard(
                    context: context,
                    title: 'Informasi Versi',
                    children: [
                      _buildInfoRow(
                        context: context,
                        icon: Icons.info_outline,
                        label: 'Versi Aplikasi',
                        value: version.isNotEmpty ? version : 'Loading...',
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        context: context,
                        icon: Icons.build_outlined,
                        label: 'Build Number',
                        value:
                            buildNumber.isNotEmpty ? buildNumber : 'Loading...',
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        context: context,
                        icon: Icons.folder_outlined,
                        label: 'Package Name',
                        value:
                            packageName.isNotEmpty ? packageName : 'Loading...',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Features Card
                  _buildInfoCard(
                    context: context,
                    title: 'Fitur Unggulan',
                    children: [
                      _buildFeatureRow(
                        context: context,
                        icon: Icons.security,
                        title: 'Keamanan Terjamin',
                        description:
                            'Transaksi aman dengan enkripsi end-to-end',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureRow(
                        context: context,
                        icon: Icons.speed,
                        title: 'Performa Cepat',
                        description:
                            'Interface responsif dan loading yang cepat',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureRow(
                        context: context,
                        icon: Icons.support_agent,
                        title: 'Dukungan 24/7',
                        description:
                            'Customer service siap membantu kapan saja',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Contact Information Card
                  _buildInfoCard(
                    context: context,
                    title: 'Hubungi Kami',
                    children: [
                      _buildContactRow(
                        context: context,
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: 'support@techtrade.com',
                      ),
                      const Divider(height: 24),
                      _buildContactRow(
                        context: context,
                        icon: Icons.phone_outlined,
                        label: 'Telepon',
                        value: '+62 123 456 7890',
                      ),
                      const Divider(height: 24),
                      _buildContactRow(
                        context: context,
                        icon: Icons.language_outlined,
                        label: 'Website',
                        value: 'www.techtrade.com',
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Copyright Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.copyright,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '© 2025 TechTrade',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Seluruh hak cipta dilindungi undang-undang.\nDibuat dengan ❤️ di Indonesia',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                theme.brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                theme.brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      theme.brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      theme.brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      theme.brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
