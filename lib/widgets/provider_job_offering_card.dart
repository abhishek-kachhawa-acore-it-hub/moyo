import 'package:flutter/material.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';

class ProviderJobOfferingCard extends StatelessWidget {
  final String subCat;
  final bool verified;
  final String? serviceName;
  final String? experience;
  final String? status;
  final bool isChecked;
  final bool showEditButton;
  final VoidCallback? onEdit;
  final Function(bool) onToggle;

  const ProviderJobOfferingCard({
    Key? key,
    required this.subCat,
    required this.verified,
    this.serviceName,
    this.experience,
    this.status,
    required this.isChecked,
    this.showEditButton = false,
    this.onEdit,
    required this.onToggle,
  }) : super(key: key);

  Color _getStatusColor() {
    if (status == null) return Colors.grey;

    switch (status!.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    if (status == null) return 'Unknown';
    return status!.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Title and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          subCat,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (verified) ...[
                        SizedBox(width: 8),
                        Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Service Name
            if (serviceName != null && serviceName!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.business_center_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Service: $serviceName',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
            ],

            // Experience
            if (experience != null && experience!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.work_history_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Experience: ${experience} ${int.tryParse(experience!) == 1 ? 'year' : 'years'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
            ],

            Divider(height: 1),
            SizedBox(height: 12),

            // Toggle and Edit Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Toggle Switch
                Row(
                  children: [
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(width: 8),
                    Switch(
                      value: isChecked,
                      onChanged: onToggle,
                      activeColor: ColorConstant.moyoGreen,
                      activeTrackColor: ColorConstant.moyoGreen.withOpacity(0.5),
                    ),
                  ],
                ),

                // Edit Button (only shown for rejected skills)
                if (showEditButton && onEdit != null)
                  ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}