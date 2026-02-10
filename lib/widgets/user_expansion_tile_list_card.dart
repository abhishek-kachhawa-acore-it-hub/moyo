import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:flutter/material.dart';

class UserExpansionTileListCard extends StatelessWidget {
  final String dp;
  final String title;
  final String subtitle;
  final void Function(String serviceType)? onServiceTypeSelected; // Changed to String and nullable

  const UserExpansionTileListCard({
    super.key,
    required this.dp,
    required this.title,
    required this.subtitle,
    this.onServiceTypeSelected, // Made optional
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ExpansionTile(
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(100)),
          height: 45,
          width: 45,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CachedNetworkImage(
                imageUrl: dp.isNotEmpty ? dp : 'https://picsum.photos/200/200',
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Image.asset('assets/images/moyo_image_placeholder.png'),
                errorWidget: (context, url, error) =>
                    Image.asset('assets/images/moyo_image_placeholder.png'),
              ),
            ],
          ),
        ),
        title: Text(
          title.isNotEmpty ? title : 'Unknown Service',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(subtitle.isNotEmpty ? subtitle : 'Service'),
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Service Type',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: ColorConstant.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildServiceButtons(context),
        ],
      ),
    );
  }

  Widget _buildServiceButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              onServiceTypeSelected?.call('instant');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstant.moyoOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Instant',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              onServiceTypeSelected?.call('later');
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: ColorConstant.moyoOrange, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Later',
              style: TextStyle(
                color: ColorConstant.moyoOrange,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
