import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../utils/app_colors.dart';

/// Widget to display place details in a bottom sheet
class PlaceDetailsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> details;

  const PlaceDetailsBottomSheet({
    super.key,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: AppColors.getBorderField(context).withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.getBorderField(context).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDragHandle(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 12),
                  if (details['rating'] != null) _buildRating(context),
                  const SizedBox(height: 16),
                  _buildAddress(context),
                  const Spacer(),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.getBorderField(context).withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                details['name'] as String? ?? 'Unknown Place',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getLabelTextField(context),
                ),
              ),
            ),
            if (details['opening_hours'] != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      (details['opening_hours']['open_now'] as bool?) ?? false
                          ? AppColors.basicButton.withOpacity(0.2)
                          : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        (details['opening_hours']['open_now'] as bool?) ?? false
                            ? AppColors.basicButton
                            : Colors.red,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  (details['opening_hours']['open_now'] as bool?) ?? false
                      ? 'Open'
                      : 'Closed',
                  style: TextStyle(
                    color:
                        (details['opening_hours']['open_now'] as bool?) ?? false
                            ? AppColors.getLabelTextField(context)
                            : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        // إضافة نوع المكان إذا كان متوفراً
        if (details['place_category'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.getSignAndRegister(context).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                details['place_category'] as String,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getSignAndRegister(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRating(BuildContext context) {
    double rating = (details['rating'] as num).toDouble();
    return Row(
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < rating.floor()
                ? Icons.star
                : index < rating
                    ? Icons.star_half
                    : Icons.star_border,
            color: AppColors.getSignAndRegister(context),
            size: 20,
          );
        }),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 16,
            color: AppColors.getLabelTextField(context).withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAddress(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          color: AppColors.getLabelTextField(context).withOpacity(0.8),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            details['formatted_address'] as String? ?? 'No address available',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getLabelTextField(context).withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          context: context,
          icon: Icons.directions,
          label: 'Directions',
          onTap: () => _openDirections(),
        ),
        if (details['formatted_phone_number'] != null)
          _buildActionButton(
            context: context,
            icon: Icons.phone,
            label: 'Call',
            onTap: () =>
                _makePhoneCall(details['formatted_phone_number'] as String),
          ),
        _buildActionButton(
          context: context,
          icon: Icons.share,
          label: 'Share',
          onTap: () => _sharePlaceDetails(),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.basicButton.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.basicButton.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.getLabelTextField(context), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.getLabelTextField(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDirections() async {
    try {
      final lat = (details['geometry']['location']['lat'] as num).toDouble();
      final lng = (details['geometry']['location']['lng'] as num).toDouble();
      final url =
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';

      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening directions: $e');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final Uri uri = Uri.parse('tel:$phoneNumber');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error making call: $e');
    }
  }

  Future<void> _sharePlaceDetails() async {
    try {
      // Implementation for sharing place details
      // This could use a share package like share_plus
      debugPrint('Share functionality to be implemented');
    } catch (e) {
      debugPrint('Error sharing place details: $e');
    }
  }

  /// Show place details in a modal bottom sheet
  static void show(BuildContext context, Map<String, dynamic> details) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaceDetailsBottomSheet(details: details),
    );
  }
}
