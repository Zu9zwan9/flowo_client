import 'package:cupertino_sidebar/cupertino_sidebar.dart';
import 'package:flutter/cupertino.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isExpanded;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSidebarCollapsible(
      isExpanded: isExpanded,
      child: CupertinoSidebar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        navigationBar: const SidebarNavigationBar(
          title: Text('Sidebar'),
        ),
        children: const [
          SidebarDestination(
            icon: Icon(CupertinoIcons.calendar),
            label: Text('Calendar'),
          ),
          SidebarDestination(
            icon: Icon(CupertinoIcons.list_bullet),
            label: Text('Tasks'),
          ),
          SidebarDestination(
            icon: Icon(CupertinoIcons.add),
            label: Text('Add Task'),
          ),
          SidebarDestination(
            icon: Icon(CupertinoIcons.person),
            label: Text('Profile'),
          ),
          SidebarDestination(
            icon: Icon(CupertinoIcons.settings),
            label: Text('Settings'),
          ),
        ],
      ),
    );
  }
}
