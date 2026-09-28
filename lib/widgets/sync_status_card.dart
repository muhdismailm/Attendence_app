import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/attendance_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import 'dynamic_sync_button.dart';

class SyncStatusCard extends StatelessWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final attProv = context.watch<AttendanceProvider>();
    final pendingCount = attProv.pendingSyncCount;
    final isSyncing = attProv.isSyncing;
    final lastSyncTime = attProv.lastSyncTime;
    final syncError = attProv.syncError;

    final String lastSyncText = lastSyncTime != null
        ? 'Last synced: ${DateFormat('MMM d, hh:mm a').format(lastSyncTime)}'
        : 'Offline-first database active';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: pendingCount > 0
                      ? const Color(0xFFFEF3C7) // Amber
                      : const Color(0xFFEFF6FF), // Blue
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  pendingCount > 0 ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
                  color: pendingCount > 0 ? const Color(0xFFD97706) : AppColors.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attendance Cloud Sync',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lastSyncText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Informational pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 16, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pendingCount > 0
                        ? '$pendingCount record(s) stored locally on this device, waiting for sync.'
                        : 'All offline attendance records are synchronized with Firestore.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (syncError != null && !isSyncing) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.absentLightBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.absentRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.absentRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      syncError,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.absentRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Dynamic Sync Button
          const SizedBox(
            width: double.infinity,
            child: DynamicSyncButton(),
          ),
        ],
      ),
    );
  }
}
