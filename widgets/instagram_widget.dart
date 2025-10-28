import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:asv_app/config/social_media_config.dart';

/// Standard Instagram Widget für Aktive und Senioren
class InstagramWidget extends StatelessWidget {
  const InstagramWidget({super.key});

  Future<void> _openInstagram() async {
    final uri = Uri.parse(SocialMediaConfig.instagramUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _openInstagram,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF58529),
                          Color(0xFFDD2A7B),
                          Color(0xFF8134AF),
                          Color(0xFF515BD4),
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Folge uns auf Instagram',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${SocialMediaConfig.instagramUsername}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Verpasse keine Updates, Fänge und Events!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kompakte Instagram-Badge für kleinere Darstellung
class InstagramBadge extends StatelessWidget {
  const InstagramBadge({super.key});

  Future<void> _openInstagram() async {
    final uri = Uri.parse(SocialMediaConfig.instagramUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openInstagram,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFF58529),
              Color(0xFFDD2A7B),
              Color(0xFF8134AF),
              Color(0xFF515BD4),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDD2A7B).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              '@${SocialMediaConfig.instagramUsername}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Instagram-Button als Action-Element
class InstagramButton extends StatelessWidget {
  const InstagramButton({super.key});

  Future<void> _openInstagram() async {
    final uri = Uri.parse(SocialMediaConfig.instagramUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _openInstagram,
      icon: const Icon(Icons.camera_alt),
      label: const Text('Instagram'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE4405F),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
