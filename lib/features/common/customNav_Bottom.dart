import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class CustomBottomNav extends StatefulWidget {
  final List<Widget> screens;
  final List<TabItemData> tabs;
  final int initialIndex;
  final Color selectedColor;
  final Color backgroundColor;

  const CustomBottomNav({
    super.key,
    required this.screens,
    required this.tabs,
    this.initialIndex = 0,
    this.selectedColor = const Color(0xFF3861ED),
    this.backgroundColor = Colors.white,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: widget.initialIndex);
    _controller.addListener(() => setState(() {}));
  }

  List<PersistentBottomNavBarItem> _navBarsItems(double itemWidth) {
    return widget.tabs.asMap().entries.map((entry) {
      final index = entry.key;
      final tab = entry.value;
      final bool isSelected = _controller.index == index;

      final String selectedIconPath =
          tab.iconPath.replaceFirst('.svg', '_selected.svg');
      final String unselectedIconPath =
          tab.iconPath.replaceFirst('.svg', '_unselected.svg');

      return PersistentBottomNavBarItem(
        icon: SizedBox(
          width: itemWidth,
          height: 80,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: FittedBox(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.selectedColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          isSelected
                              ? selectedIconPath
                              : unselectedIconPath,
                          height: 22,
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Text(
                            tab.title,
                            style: TextStyle(
                              color: widget.selectedColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        inactiveIcon: SizedBox(
          width: itemWidth,
          height: 80,
          child: Center(
            child: SvgPicture.asset(unselectedIconPath, height: 35),
          ),
        ),
        title: "",
        activeColorPrimary: Colors.transparent,
        inactiveColorPrimary: Colors.transparent,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = screenWidth / widget.tabs.length;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: MediaQuery.of(context).padding.copyWith(bottom: 4),
      ),
      child: PersistentTabView(
        context,
        controller: _controller,
        screens: widget.screens,
        items: _navBarsItems(itemWidth),
        backgroundColor: widget.backgroundColor,
        decoration: NavBarDecoration(
          borderRadius: BorderRadius.zero,
          colorBehindNavBar: widget.backgroundColor,
        ),
        navBarHeight: 80,
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        confineToSafeArea: true,
        navBarStyle: NavBarStyle.style6,
      ),
    );
  }
}

class TabItemData {
  final String title;
  final String iconPath;
  const TabItemData({required this.title, required this.iconPath});
}
