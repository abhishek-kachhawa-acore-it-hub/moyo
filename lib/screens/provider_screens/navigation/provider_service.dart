import 'package:first_flutter/screens/provider_screens/navigation/provider_service_tab_body/provider_bid_service.dart';
import 'package:first_flutter/screens/provider_screens/navigation/provider_service_tab_body/provider_confirmed_service.dart';
import 'package:first_flutter/screens/provider_screens/navigation/provider_service_tab_body/provider_re_bid_service.dart';
import 'package:flutter/material.dart';

import '../../../widgets/provider_tab_bar.dart';

class ProviderService extends StatefulWidget {
  const ProviderService({super.key});

  @override
  State<ProviderService> createState() => _ProviderServiceState();
}

class _ProviderServiceState extends State<ProviderService>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Keys for each tab to force refresh
  final List<GlobalKey> _tabKeys = [GlobalKey(), GlobalKey(), GlobalKey()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabController = DefaultTabController.of(context);
      _tabController.addListener(_handleTabChange);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_handleTabChange);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshCurrentTab();
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
        // Generate new key to force rebuild
        _tabKeys[_currentTabIndex] = GlobalKey();
      });
    }
  }

  void _refreshCurrentTab() {
    setState(() {
      _tabKeys[_currentTabIndex] = GlobalKey();
    });
  }

  @override
  bool get wantKeepAlive => false; // Don't keep state alive

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          ProviderTabBar(),
          Expanded(child: _tabBarView(context)),
        ],
      ),
    );
  }

  Widget _tabBarView(BuildContext context) {
    return TabBarView(
      children: [
        ProviderBidService(key: _tabKeys[0]),
        ProviderReBidService(key: _tabKeys[1]),
        ProviderConfirmedService(key: _tabKeys[2]),
      ],
    );
  }
}
