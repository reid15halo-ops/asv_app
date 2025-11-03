import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:asv_app/models/notification.dart';
import 'package:asv_app/providers/notification_provider.dart';

/// Notification Center Screen - zeigt alle Benachrichtigungen an
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    // Lade Notifications beim Start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Benachrichtigungen'),
        actions: [
          // Settings
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: () => context.push('/notifications/settings'),
          ),
          // Filter Toggle (Ungelesen)
          IconButton(
            icon: Icon(_showUnreadOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            tooltip: _showUnreadOnly ? 'Alle anzeigen' : 'Nur ungelesene',
            onPressed: () {
              setState(() {
                _showUnreadOnly = !_showUnreadOnly;
              });
              if (_showUnreadOnly) {
                ref.read(notificationsProvider.notifier).loadUnreadNotifications();
              } else {
                ref.read(notificationsProvider.notifier).loadNotifications();
              }
            },
          ),
          // Mark All as Read
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'mark_all_read') {
                await ref.read(notificationsProvider.notifier).markAllAsRead();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alle als gelesen markiert')),
                  );
                }
              } else if (value == 'delete_all') {
                final confirmed = await _showDeleteAllDialog();
                if (confirmed && context.mounted) {
                  await ref.read(notificationsProvider.notifier).deleteAllNotifications();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Alle Benachrichtigungen gelöscht')),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all),
                    SizedBox(width: 8),
                    Text('Alle als gelesen markieren'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Alle löschen', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(notificationsProvider.notifier).refresh();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () => _handleNotificationTap(notification),
                  onMarkAsRead: () => _handleMarkAsRead(notification),
                  onDelete: () => _handleDelete(notification),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Fehler: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(notificationsProvider.notifier).refresh();
                },
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showUnreadOnly ? Icons.mark_email_read : Icons.notifications_none,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _showUnreadOnly
                ? 'Keine ungelesenen Benachrichtigungen'
                : 'Keine Benachrichtigungen',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // Markiere als gelesen
    if (!notification.read) {
      ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    }

    // Navigiere zu Action URL wenn vorhanden
    if (notification.actionUrl != null) {
      context.push(notification.actionUrl!);
    }
  }

  void _handleMarkAsRead(AppNotification notification) {
    ref.read(notificationsProvider.notifier).markAsRead(notification.id);
  }

  void _handleDelete(AppNotification notification) {
    ref.read(notificationsProvider.notifier).deleteNotification(notification.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Benachrichtigung gelöscht')),
    );
  }

  Future<bool> _showDeleteAllDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Alle löschen?'),
            content: const Text(
              'Möchtest du wirklich alle Benachrichtigungen löschen? Dies kann nicht rückgängig gemacht werden.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Löschen'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// Einzelne Notification Tile
class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = notification.type.getColor(context);

    return Dismissible(
      key: Key('notification_${notification.id}'),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.done, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right: Mark as read
          if (!notification.read) {
            onMarkAsRead();
          }
          return false; // Don't actually dismiss
        } else {
          // Swipe left: Delete
          return true;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeColor.withOpacity(0.2),
          child: Icon(notification.type.icon, color: typeColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ),
            if (!notification.read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              notification.getRelativeTime(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: notification.actionLabel != null
            ? Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400])
            : null,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
