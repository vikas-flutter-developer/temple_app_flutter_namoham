import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/features/block/presentation/providers/block_provider.dart';
import 'package:flutter_user_app/features/block/data/models/block_model.dart';
import '../../../../widgets/custom_widgets/custom_network_image.dart';

class BlockListScreen extends StatefulWidget {
  const BlockListScreen({super.key});

  @override
  State<BlockListScreen> createState() => _BlockListScreenState();
}

class _BlockListScreenState extends State<BlockListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BlockProvider>().loadBlockList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Block List'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Consumer<BlockProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.blockList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.blockList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text('Error: ${provider.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => provider.loadBlockList(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.blockList.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.loadBlockList(),
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.block, size: 64, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            'No blocked accounts',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Accounts you block will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.outline.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadBlockList(),
            child: ListView.builder(
              itemCount: provider.blockList.length,
              itemBuilder: (context, index) {
                final block = provider.blockList[index];
                return _BlockedAccountTile(
                  block: block,
                  onUnblock: () => _showUnblockConfirmation(context, block, provider),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showUnblockConfirmation(BuildContext context, BlockModel block, BlockProvider provider) {
    final theme = Theme.of(context);
    final name = block.entityName ?? block.entityType;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unblock Account'),
        content: Text('Are you sure you want to unblock $name? You will start seeing their posts and reels again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await provider.unblockEntity(block.entityId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? '$name has been unblocked' : 'Failed to unblock $name',
                    ),
                  ),
                );
              }
            },
            child: Text('Unblock', style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

class _BlockedAccountTile extends StatelessWidget {
  final BlockModel block;
  final VoidCallback onUnblock;

  const _BlockedAccountTile({
    required this.block,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = block.entityName ?? 'Unknown';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: block.entityImage != null && block.entityImage!.isNotEmpty
            ? ClipOval(
                child: CustomNetworkImage(
                  imageUrl: block.entityImage!,
                  fit: BoxFit.cover,
                  width: 40,
                  height: 40,
                  errorWidget: Text(
                    initials,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            : Text(
                initials,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        block.entityType.isNotEmpty
            ? block.entityType[0].toUpperCase() + block.entityType.substring(1)
            : '',
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.outline,
        ),
      ),
      trailing: OutlinedButton(
        onPressed: onUnblock,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(color: theme.colorScheme.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text('Unblock'),
      ),
    );
  }
}
