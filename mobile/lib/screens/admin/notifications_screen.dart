import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/empty_and_error.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await ApiClient().get(ApiConstants.notifications);
    if (!mounted) return;

    if (res.success && res.data is Map) {
      setState(() {
        _notifications = res.data['notifications'] ?? [];
        _unreadCount = res.data['unread_count'] ?? 0;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'Failed to load notifications';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int notifId) async {
    final res = await ApiClient().post('${ApiConstants.notifications}/$notifId/read');
    if (res.success) {
      setState(() {
        for (var n in _notifications) {
          if (n['id'] == notifId) {
            n['is_read'] = true;
          }
        }
        if (_unreadCount > 0) _unreadCount--;
      });
    }
  }

  Future<void> _markAllRead() async {
    final res = await ApiClient().post('${ApiConstants.notifications}/read-all');
    if (res.success) {
      setState(() {
        for (var n in _notifications) {
          n['is_read'] = true;
        }
        _unreadCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _notifications.where((n) {
      if (_selectedFilter == 'ALL') return true;
      final type = (n['type'] ?? '').toString().toUpperCase();
      return type == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount New',
                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark All Read'),
              onPressed: _markAllRead,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _fetchNotifications)
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('ALL', 'All (${_notifications.length})'),
                            const SizedBox(width: 8),
                            _buildFilterChip('PAYMENT', 'Payments'),
                            const SizedBox(width: 8),
                            _buildFilterChip('INVENTORY', 'Inventory'),
                            const SizedBox(width: 8),
                            _buildFilterChip('INVOICE', 'Billing'),
                            const SizedBox(width: 8),
                            _buildFilterChip('PURCHASE', 'Purchases'),
                            const SizedBox(width: 8),
                            _buildFilterChip('SYSTEM', 'System'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (filtered.isEmpty)
                        const EmptyStateView(
                          icon: Icons.notifications_none,
                          title: 'All Caught Up!',
                          message: 'No notifications matching the selected filter.',
                        )
                      else
                        ...filtered.map((n) => _buildNotificationCard(n)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (val) => setState(() => _selectedFilter = key),
      selectedColor: AppColors.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.secondaryText,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? AppColors.primaryBlue : AppColors.border),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n) {
    final bool isRead = n['is_read'] == true;
    final type = (n['type'] ?? 'SYSTEM').toString().toUpperCase();
    final title = n['title'] ?? 'Notification';
    final msg = n['message'] ?? '';
    final createdAt = (n['created_at'] ?? '').toString();

    IconData icon = Icons.info_outline;
    Color iconColor = AppColors.primaryBlue;

    if (type == 'PAYMENT') {
      icon = Icons.payments_outlined;
      iconColor = AppColors.success;
    } else if (type == 'INVENTORY' || type == 'LOW_STOCK') {
      icon = Icons.warning_amber_rounded;
      iconColor = AppColors.warning;
    } else if (type == 'INVOICE') {
      icon = Icons.receipt_long_outlined;
      iconColor = AppColors.primaryBlue;
    } else if (type == 'PURCHASE') {
      icon = Icons.shopping_bag_outlined;
      iconColor = AppColors.secondaryIndigo;
    }

    return GestureDetector(
      onTap: () {
        if (!isRead) _markAsRead(n['id']);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFEFF6FF), // soft blue tint for unread
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? AppColors.border : AppColors.primaryBlue.withOpacity(0.3),
            width: isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg,
                    style: TextStyle(
                      fontSize: 12,
                      color: isRead ? AppColors.secondaryText : AppColors.primaryText,
                    ),
                  ),
                  if (createdAt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      createdAt.length > 16 ? createdAt.substring(0, 16) : createdAt,
                      style: TextStyle(fontSize: 10, color: AppColors.secondaryText),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
