import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/session_controller.dart';
import '../../../l10n/locale_text.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/flex_bottom_nav.dart';

class MemberBookingsScreen extends StatefulWidget {
  const MemberBookingsScreen({super.key});

  @override
  State<MemberBookingsScreen> createState() => _MemberBookingsScreenState();
}

class _MemberBookingsScreenState extends State<MemberBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingController>().fetchMemberBookings();
    });

    // Ensure sessions are loaded so we can display titles for bookings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionController>().fetchAllSessions();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingController>().bookings;
    final sessions = context.watch<SessionController>().sessions;
    final allSessions = context.watch<SessionController>().allSessions;
    final sessionsById = {
      for (final session in [...sessions, ...allSessions]) session.id: session,
    };

    return Scaffold(
      appBar: const FlexAppBar(title: 'My Bookings', badgeText: 'Member'),
      bottomNavigationBar: FlexBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) context.go('/member/home');
          if (index == 1) context.go('/member/explore');
          if (index == 3) context.go('/member/profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'EXPLORE'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'MY BOOKINGS'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            labelColor: AppColors.sageDark,
            tabs: [
              Tab(text: context.t('Bookings', 'Réservations')),
              Tab(text: context.t('🧾 Payments', '🧾 Paiements')),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (_, i) {
                    final b = bookings[i];
                    final upcoming = b.status == 'confirmed';
                    final sessionTitle = sessionsById[b.sessionId]?.title ??
                        b.sessionId.substring(0, 6);

                    return Opacity(
                      opacity: upcoming ? 1 : 0.65,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(
                                    '${context.t('Session', 'Séance')} $sessionTitle',
                                    style: AppTextStyles.body)),
                            ChipBadge(
                                text: upcoming ? 'Confirmed' : 'Done',
                                variant: upcoming
                                    ? ChipBadgeVariant.green
                                    : ChipBadgeVariant.sage),
                            if (upcoming) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => context
                                    .read<BookingController>()
                                    .cancelBooking(b.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.redLight,
                                  foregroundColor: AppColors.redDark,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(context.t('Cancel', 'Annuler')),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...bookings.map(
                      (b) => ListTile(
                        tileColor: AppColors.white,
                        title: Text(
                          '${context.t('Payment', 'Paiement')} ${sessionsById[b.sessionId]?.title ?? b.sessionId.substring(0, 6)}',
                        ),
                        subtitle:
                            Text('${b.paidAmountTnd.toStringAsFixed(0)} TND'),
                        trailing: ChipBadge(
                          text: b.paymentStatus == 'paid' ? 'Paid' : 'Pending',
                          variant: b.paymentStatus == 'paid'
                              ? ChipBadgeVariant.green
                              : ChipBadgeVariant.amber,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                        '${context.t('Monthly total', 'Total mensuel')}: ${bookings.fold<double>(0, (sum, b) => sum + b.paidAmountTnd).toStringAsFixed(0)} TND',
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
