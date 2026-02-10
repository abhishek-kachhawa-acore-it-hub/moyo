import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../widgets/user_service_list_card.dart';
import '../../AssignedandCompleteUserServiceDetailsScreen.dart';
import 'UserCompletedServiceProvider.dart';
import 'InvoiceScreen.dart'; // Import the new invoice screen

class UserCompletedService extends StatefulWidget {
  const UserCompletedService({super.key});

  @override
  State<UserCompletedService> createState() => _UserCompletedServiceState();
}

class _UserCompletedServiceState extends State<UserCompletedService> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CompletedServiceProvider>(
        context,
        listen: false,
      ).fetchCompletedServices();
    });
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String getDurationText(int value, String unit) {
    if (value <= 0) return 'N/A';
    return '$value ${unit}${value > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompletedServiceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    provider.fetchCompletedServices();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.services.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Completed Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your completed services will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchCompletedServices(),
          child: ListView.builder(
            itemCount: provider.services.length,
            itemBuilder: (context, index) {
              final service = provider.services[index];

              // Get the bid amount - use the first bid if available, otherwise use budget
              final bidAmount = service.bids.isNotEmpty
                  ? service.bids.first.amount.toStringAsFixed(0)
                  : (double.tryParse(service.budget) ?? 0).toStringAsFixed(0);

              return Column(
                children: [
                  UserServiceListCard(
                    category: service.category,
                    subCategory: service.service,
                    date: formatDate(service.createdAtFormatted),
                    dp:
                        service.customer.image ??
                        "https://picsum.photos/200/200",
                    price: bidAmount,
                    duration: getDurationText(
                      service.durationValue,
                      service.durationUnit,
                    ),
                    priceBy: bidAmount,
                    providerCount: int.tryParse(service.totalBids) ?? 0,
                    status: service.status,
                    onInvoicePress: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvoiceScreen(service: service),
                        ),
                      );
                    },
                    onPress: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AssignedandCompleteUserServiceDetailsScreen(
                                serviceId: service.id,
                              ),
                        ),
                      );
                    },
                  ),

                  // Invoice Button
                ],
              );
            },
          ),
        );
      },
    );
  }
}
