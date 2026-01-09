import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/common/screens/notifications_screen.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/features/common/repository_layer.dart';
import 'package:haticare/features/doctor/presentation/screens/appointment_detail.dart';
import 'package:haticare/features/doctor/presentation/screens/consultation_history.dart';
import 'package:haticare/features/doctor/presentation/screens/setting_screen.dart';
import 'package:haticare/features/doctor/presentation/viewModel/doctor_viewModel.dart';
import 'package:haticare/features/doctor/presentation/viewModel/logout_viewModel.dart';
import 'package:haticare/features/doctor/presentation/providers/doctor_user_provider.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:haticare/features/common/customNav_Bottom.dart';
import 'package:haticare/features/doctor/models/appointment_model.dart';
import 'package:provider/provider.dart';
import 'package:haticare/features/common/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileNotifier {
  static final ValueNotifier<String?> profileImageUrl = ValueNotifier(null);
  static final ValueNotifier<String?> doctorName = ValueNotifier(null);
}

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<DoctorHomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadLoginData();
  }

  Future<void> _loadLoginData() async {
    await SaveLoginResponse.loadLoginModel();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorUserProvider(),
      child: CustomBottomNav(
        screens: [
          ChangeNotifierProvider(
            create: (_) =>
                DoctorViewModel(RepositoryLayer(ApiClient()))
                  ..fetchPatientQueue(),
            child: const HomeScreen(),
          ),
          const ConsultationHistoryScreen(),
          MultiProvider(
            providers: [
              Provider<ApiClient>(create: (_) => ApiClient()),
              ProxyProvider<ApiClient, RepositoryLayer>(
                update: (_, apiClient, __) => RepositoryLayer(apiClient),
              ),
              ChangeNotifierProvider<AuthDViewModel>(
                create: (context) =>
                    AuthDViewModel(context.read<RepositoryLayer>()),
              ),
            ],
            child: const SettingsScreenWithAppBar(),
          ),
        ],
        tabs: const [
          TabItemData(title: "Home", iconPath: 'assets/icons/home.svg'),
          TabItemData(title: "History", iconPath: 'assets/icons/history.svg'),
          TabItemData(title: "Settings", iconPath: 'assets/icons/setting.svg'),
        ],
      ),
    );
  }
}

class SettingsScreenWithAppBar extends StatelessWidget {
  const SettingsScreenWithAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.transparent,
      ),
      body: const SafeArea(child: SettingsContent()),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  bool isOnline = false;
  bool? hasAdminApproval;

  late DoctorViewModel doctorViewModel;

  @override
  void initState() {
    super.initState();
    doctorViewModel = DoctorViewModel(RepositoryLayer(ApiClient()));
    doctorViewModel.fetchPatientQueue();
    _loadApprovalStatus();
  }

  Future<void> _loadApprovalStatus() async {
    // Load from SharedPreferences first
    final prefs = await SharedPreferences.getInstance();
    final cachedApproval = prefs.getBool('doctor_is_approved');

    if (mounted) {
      setState(() {
        hasAdminApproval = cachedApproval;
      });

      // Fetch fresh data from API
      final provider = context.read<DoctorUserProvider>();
      await provider.fetchProfile(forceRefresh: true);

      // Then update from provider after fetch completes
      if (mounted) {
        setState(() {
          hasAdminApproval = provider.isApproved;
        });
      }
    }
  }

  @override
  void dispose() {
    doctorViewModel.dispose();
    super.dispose();
  }

  @override // this method will called when doctor object change
  void didChangeDependencies() {
    super.didChangeDependencies();
    doctorViewModel = Provider.of<DoctorViewModel>(context);
  }

  Future<void> _onRefresh() async {
    // Fetch profile to check approval status
    final provider = context.read<DoctorUserProvider>();
    await provider.fetchProfile(forceRefresh: true);

    // Update local state from provider
    setState(() {
      hasAdminApproval = provider.isApproved;
    });

    // Fetch patient queue if approved
    if (hasAdminApproval == true) {
      await doctorViewModel.fetchPatientQueue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        top: true,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        headerView(),
                        const SizedBox(height: 20),
                        toggleView(),
                        const SizedBox(height: 20),
                        statsView(),
                        const SizedBox(height: 20),

                        if (hasAdminApproval == true)
                          const Text(
                            "Patient Queue",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                        if (hasAdminApproval == true) const SizedBox(height: 2),
                      ],
                    ),
                  ),

                  handleAppointment(context, doctorViewModel.appointments),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget handleAppointment(
    BuildContext context,
    List<AppointmentModel> appointments,
  ) {
    if (hasAdminApproval == false) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: waitingMessageView(),
      );
    }

    if (hasAdminApproval == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!isOnline) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: patientQueueView(),
      );
    }

    if (appointments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              "No New Requests Available",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(appointments.length, (index) {
        final appt = appointments[index];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: patientAppointmentView(context, appt),
        );
      }),
    );
  }

  Widget headerView() {
    final doctorProvider = context.watch<DoctorUserProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            doctorProvider.isLoading
                ? const CircleAvatar(
                    radius: 25,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                : CircleAvatar(
                    radius: 25,
                    backgroundImage: doctorProvider.profilePictureUrl.isNotEmpty
                        ? NetworkImage(doctorProvider.profilePictureUrl)
                        : null,
                    child: doctorProvider.profilePictureUrl.isEmpty
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome Back,",
                  style: TextStyle(color: Colors.grey),
                ),
                doctorProvider.isLoading
                    ? const SizedBox(
                        width: 100,
                        height: 18,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.grey,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      )
                    : Text(
                        doctorProvider.doctorName.isNotEmpty
                            ? (doctorProvider.doctorName.length > 15
                                  ? '${doctorProvider.doctorName.substring(0, 15)}...'
                                  : doctorProvider.doctorName)
                            : 'Doctor',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
              ],
            ),
          ],
        ),

        Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              icon: SvgPicture.asset(
                'assets/icons/notification.svg',
                height: 26,
                color: Colors.black87,
              ),
            ),
            const Positioned(
              right: 8,
              top: 8,
              child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget toggleView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isOnline ? "Online" : "Offline",
            style: TextStyle(
              fontSize: 16,
              color: isOnline ? const Color(0xFF34C759) : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          AbsorbPointer(
            absorbing: hasAdminApproval != true,
            child: Opacity(
              opacity: (hasAdminApproval == true) ? 1.0 : 0.5,
              child: Switch(
                value: isOnline,
                activeThumbColor: const Color(0xFFFFFFFF),
                activeTrackColor: const Color(0xFF34C759),
                onChanged: (value) async {
                  setState(() {
                    isOnline = value;
                  });
                  await doctorViewModel.isDoctorOnline(isOnline: value);
                  await doctorViewModel.fetchPatientQueue();
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
            opacity: hasAdminApproval == true ? 1.0 : 0.5,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFF54DCDF),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2443A9),
                      ),
                    ),
                    Text(
                      "Consultations Today",
                      style: TextStyle(
                        color: hasAdminApproval == true
                            ? Color(0xFF2443A9)
                            : Colors.grey,
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
            opacity: hasAdminApproval == true ? 1.0 : 0.5,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFF07498A),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Avg. Time",
                      style: TextStyle(
                        color: hasAdminApproval == true
                            ? Colors.white
                            : Colors.grey,
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
      child: Center(
        child: Text(
          isOnline
              ? "Waiting for patients..."
              : "Go online to see patient requests",
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget patientAppointmentView(
    BuildContext context,
    AppointmentModel appointment,
  ) {
    return GestureDetector(
      onTap: () { },
      child: Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Color(0x4D3C64ED)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: setupPatientCardLive(appointment),
      ),
    );
  }

  Widget setupPatientCardLive(AppointmentModel appointment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/appointment-Request.svg',
                      height: 24,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.primaryGradient.createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            ),
                        child: const Text(
                          "New Appointment Request",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              circularProgressBar(0.4, 9),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset('assets/icons/user-square.svg', height: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Patient", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      "${appointment.patientName}, ${appointment.patient.age}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset('assets/icons/sticky-note.svg', height: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Reason for Visit",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointment.rawComplaint,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Text(
                  doctorViewModel.formatAppointmentTime(appointment.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              // Expanded(
              //   child: OutlinedButton(
              //     onPressed: () {},
              //     style: OutlinedButton.styleFrom(
              //       backgroundColor: const Color(0xFFE3E8EF),
              //       side: const BorderSide(color: Color(0xFFE3E8EF)),
              //       foregroundColor: Colors.redAccent.shade400,
              //       padding: const EdgeInsets.symmetric(vertical: 12),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //     ),
              //     child: const Text("Decline"),
              //   ),
              // ),
              // const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      PersistentNavBarNavigator.pushNewScreen(
                        context,
                        screen: AppointmentDetailScreen(
                          appointment: appointment,
                          isCameFromAccept: true,
                        ),
                        withNavBar: false,
                        pageTransitionAnimation:
                            PageTransitionAnimation.cupertino,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "View Details",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Stack circularProgressBar(double progress, int minutesLeft) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Colors.grey[300],
            color: const Color(0xFF34C759),
          ),
        ),
        Text(
          "$minutesLeft",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF34C759),
          ),
        ),
      ],
    );
  }

  Widget waitingMessageView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_outlined,
                color: Colors.orange[700],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Waiting For Admin's Approval",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'No New Requests Available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
