import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/features/doctor/data/consultation_history.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:haticare/features/doctor/data/customNav_Bottom.dart';
import 'model/appointment_model.dart';
import 'appointment_detail/appointment_detail.dart';
import 'package:haticare/features/doctor/data/theme_constant.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return CustomBottomNav(
      screens: const [
        HomeScreen(),
        ConsultationHistoryScreen(),
        Center(child: Text("Settings Screen")),
      ],
      tabs: const [
        TabItemData(title: "Home", iconPath: 'assets/home.svg'),
        TabItemData(title: "History", iconPath: 'assets/history.svg'),
        TabItemData(title: "Settings", iconPath: 'assets/setting.svg'),
      ],
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
  bool hasAdminApproval = true;
  final appointments = AppointmentModel.sampleData;

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

            isOnline
                ? handleAppointment(context, appointments)
                : patientQueueView(),
          ],
        ),
      ),
    );
  }

  Expanded handleAppointment(
    BuildContext context,
    List<AppointmentModel> appointments,
  ) {
    return Expanded(
      child: ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appt = appointments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: patientAppointmentView(context, appt),
          );
        },
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
              fontWeight: isOnline ? FontWeight.bold : FontWeight.normal,
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
                        color: hasAdminApproval
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
            opacity: hasAdminApproval ? 1.0 : 0.5,
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
                        color: hasAdminApproval ? Colors.white : Colors.grey,
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

  Widget patientAppointmentView(BuildContext context, AppointmentModel appt) {
    return GestureDetector(
      onTap: () {
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: AppointmentDetail(appointment: appt),
          withNavBar: false,
          pageTransitionAnimation: PageTransitionAnimation.cupertino,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(left: 2, right: 2),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: setupPatientCard(appt),
      ),
    );
  }

  Column setupPatientCard(AppointmentModel appt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/appointment-Request.svg',
                  height: 24,
                  color: const Color(0xFF3366FF),
                ),
                const SizedBox(width: 10),
                const Text(
                  "New Appointment Request",
                  style: TextStyle(
                    color: Color(0xFF3366FF),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            circularProgressBar(appt.progressValue, appt.minutesLeft),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset('assets/user-square.svg', height: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Patient", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(
                    "${appt.patientName}, ${appt.patientAge}",
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
            SvgPicture.asset('assets/sticky-note.svg', height: 24),
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
                    appt.reasonForVisit,
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

        Text(
          appt.appointmentTime,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Decline"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    PersistentNavBarNavigator.pushNewScreen(
                      context,
                      screen: AppointmentDetail(
                        appointment: appt,
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
                    "Accept",
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
