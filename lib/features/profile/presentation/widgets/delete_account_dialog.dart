import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_controller.dart';

class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const DeleteAccountDialog(),
        ) ??
        false;
  }

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _confirmationController = TextEditingController();
  bool _isDeleting = false;
  String? _error;

  bool get _isConfirmed =>
      _confirmationController.text.trim().toLowerCase() == 'confirm';

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!_isConfirmed || _isDeleting) return;
    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
      if (mounted) Navigator.of(context).pop(true);
    } on AuthFlowException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not delete your account. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFC74848);
    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action will permanently delete your account and log you out. '
              'To confirm, please type confirm below:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmationController,
              enabled: !_isDeleting,
              maxLines: 1,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                hintText: 'confirm',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: danger)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _isConfirmed && !_isDeleting ? _delete : null,
            style: TextButton.styleFrom(foregroundColor: danger),
            child: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
