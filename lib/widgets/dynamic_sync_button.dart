import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/attendance_provider.dart';
import '../theme/app_colors.dart';

class DynamicSyncButton extends StatelessWidget {
  final bool isCompact;

  const DynamicSyncButton({
    super.key,
    this.isCompact = false,
  });

  void _handleSync(BuildContext context) async {
    final attProv = context.read<AttendanceProvider>();
    final success = await attProv.syncPendingAttendance(isManual: true);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    attProv.syncSuccessMessage ?? 'All attendance records synced successfully!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.presentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    attProv.syncError ?? 'Attendance records remain safely stored on this device.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFD97706), // Amber warning
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => attProv.syncPendingAttendance(isManual: true),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attProv = context.watch<AttendanceProvider>();
    final isSyncing = attProv.isSyncing;
    final pendingCount = attProv.pendingSyncCount;
    final hasError = attProv.syncError != null && !isSyncing;

    // STATE 3: Currently syncing
    if (isSyncing) {
      return Container(
        height: isCompact ? 38 : 48,
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(width: 10),
            Text(
              '⟳ Syncing...',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      );
    }

    // STATE 2: Pending records exist
    if (pendingCount > 0) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleSync(context),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: isCompact ? 38 : 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)], // Vibrant amber/orange
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sync_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  '🔄 Pending to Sync ($pendingCount)',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // STATE 5: Failed with error
    if (hasError) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleSync(context),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: isCompact ? 38 : 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.absentLightBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.absentRed.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.absentRed, size: 18),
                SizedBox(width: 8),
                Text(
                  '⚠ Sync Failed (Tap to Retry)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.absentRed,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // STATE 1 & 4: No pending records / Updated
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleSync(context),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: isCompact ? 38 : 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
              SizedBox(width: 8),
              Text(
                '✓ Updated',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
