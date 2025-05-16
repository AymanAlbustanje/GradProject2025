import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/Logic/blocs/to_buy_bloc.dart';
import 'package:gradproject2025/Logic/blocs/current_household_bloc.dart';
import 'package:gradproject2025/data/Models/item_model.dart';

class ToBuyScreen extends StatelessWidget {
  const ToBuyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ToBuyBloc, ToBuyState>(
      builder: (context, state) {
        if (state is ToBuyLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ToBuyLoaded) {
          final items = state.items;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Your shopping list is empty',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddToShoppingListDialog(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item to Buy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(31, 72, 118, 1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Shopping List',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        tooltip: 'Add Item',
                        onPressed: () {
                          _showAddToShoppingListDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildShoppingItem(context, item, isDarkMode);
                    },
                  ),
                ),
              ],
            );
          }
        } else if (state is ToBuyError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Failed to load shopping list',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  state.error,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red[400],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Get current household id
                    final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
                    if (currentHouseholdState is CurrentHouseholdSet) {
                      context.read<ToBuyBloc>().add(
                        LoadToBuyItems(householdId: currentHouseholdState.household.id.toString()),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        } else {
          return const Center(child: Text('No data available'));
        }
      },
    );
  }

  Widget _buildShoppingItem(BuildContext context, Item item, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          child: item.photoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    item.photoUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag, size: 24),
                  ),
                )
              : const Icon(Icons.shopping_bag, size: 24),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Added on ${_formatDate(DateTime.now())}',
          style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Mark as purchased',
              onPressed: () {
                _markItemAsPurchased(context, item);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove from list',
              onPressed: () {
                _removeItemFromList(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _markItemAsPurchased(BuildContext context, Item item) {
    if (item.id != null) {
      context.read<ToBuyBloc>().add(RemoveToBuyItem(itemId: item.id!));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} marked as purchased'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              context.read<ToBuyBloc>().add(AddToBuyItem(item: item));
            },
          ),
        ),
      );
    }
  }

  void _removeItemFromList(BuildContext context, Item item) {
    if (item.id != null) {
      context.read<ToBuyBloc>().add(RemoveToBuyItem(itemId: item.id!));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} removed from shopping list'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              context.read<ToBuyBloc>().add(AddToBuyItem(item: item));
            },
          ),
        ),
      );
    }
  }

  void _showAddToShoppingListDialog(BuildContext context) {
    // Implementation for adding items to shopping list
    // This could be implemented later
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add to Shopping List'),
          content: const Text('This feature will be implemented soon!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}