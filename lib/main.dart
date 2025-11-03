import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
    _controller.addListener(() => setState(() {}));
  }

  List<Widget> _buildScreens() {
    return const [
      HomeScreen(),
      Center(child: Text("History Screen")),
      Center(child: Text("Settings Screen")),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems(double itemWidth) {
    return [
      _buildNavItem("Home", 'assets/home.svg', 0, itemWidth),
      _buildNavItem("History", 'assets/history.svg', 1, itemWidth),
      _buildNavItem("Settings", 'assets/setting.svg', 2, itemWidth),
    ];
  }

  PersistentBottomNavBarItem _buildNavItem(
    String title,
    String iconPath,
    int index,
    double itemWidth,
  ) {
    final bool isSelected = _controller.index == index;

    final String selectedIconPath = iconPath.replaceFirst(
      '.svg',
      '_selected.svg',
    );
    final String unselectedIconPath = iconPath.replaceFirst(
      '.svg',
      '_unselected.svg',
    );

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
                        ? const Color(0x1A3861ED)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        isSelected ? selectedIconPath : unselectedIconPath,
                        height: 22,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF3861ED),
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
        child: Center(child: SvgPicture.asset(unselectedIconPath, height: 35)),
      ),
      title: "",
      activeColorPrimary: Colors.transparent,
      inactiveColorPrimary: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = screenWidth / 3;
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(padding: MediaQuery.of(context).padding.copyWith(bottom: 4)),
      child: PersistentTabView(
        context,
        controller: _controller,
        screens: _buildScreens(),
        items: _navBarsItems(itemWidth),
        backgroundColor: Colors.white,
        decoration: const NavBarDecoration(
          borderRadius: BorderRadius.zero,
          colorBehindNavBar: Colors.white,
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

// Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isOnline = false;
  bool hasAdminApproval = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headerView(),

            const SizedBox(height: 20),

            toggleView(),

            const SizedBox(height: 20),

            statsView(),

            const SizedBox(height: 25),

            if (hasAdminApproval)
              const Text(
                "Patient Queue",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),

            if (hasAdminApproval) const SizedBox(height: 10),

            hasAdminApproval ? patientQueueView() : waitingMessageView(),
          ],
        ),
      ),
    );
  }

  Widget headerView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 25,
              // backgroundImage: AssetImage('assets/doctor.jpg'),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Welcome Back,", style: TextStyle(color: Colors.grey)),
                Text(
                  "Dr. John Doe",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ],
        ),
        Stack(
          children: [
            SvgPicture.asset(
              'assets/notification.svg',
              height: 26,
              color: Colors.black87,
            ),
            const Positioned(
              right: 0,
              top: 0,
              child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget toggleView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isOnline ? "Online & Available" : "Offline",
            style: TextStyle(
              fontSize: 16,
              color: isOnline ? const Color(0xFF34C759) : Colors.grey,
            ),
          ),
          AbsorbPointer(
            absorbing: !hasAdminApproval,
            child: Opacity(
              opacity: hasAdminApproval ? 1.0 : 0.5,
              child: Switch(
                value: isOnline,
                activeThumbColor: const Color(0xFFFFFFFF),
                activeTrackColor: const Color(0xFF34C759),
                onChanged: (value) {
                  setState(() {
                    isOnline = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget statsView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Opacity(
            opacity: hasAdminApproval ? 1.0 : 0.5,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "0",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Consultations Today",
                      style: TextStyle(
                        color: hasAdminApproval ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Opacity(
            opacity: hasAdminApproval ? 1.0 : 0.5,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "0 min",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Avg. Time",
                      style: TextStyle(
                        color: hasAdminApproval ? Colors.purple : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget patientQueueView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          "Go online to see patient requests",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget waitingMessageView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SvgPicture.asset('assets/waitingApproval.svg', height: 120),
          const SizedBox(height: 15),
          const Text(
            "Waiting For Admin’s Approval.\nWe will get back to you in 24 hours.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}
