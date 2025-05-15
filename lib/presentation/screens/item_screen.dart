// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/api_constants.dart';
import 'package:gradproject2025/data/Models/item_model.dart';
import '../../Logic/blocs/item_bloc.dart';
import '../../data/DataSources/items_service.dart';

class ItemScreen extends StatelessWidget {
  const ItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final itemsService = ItemsService(baseUrl: ApiConstants.baseUrl);
    
    // Load items when the screen is built
    context.read<ItemBloc>().add(LoadItems());

    return Scaffold(
      body: BlocBuilder<ItemBloc, ItemState>(
        builder: (context, state) {
          if (state is ItemLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ItemLoaded) {
            final items = state.items;
            return items.isEmpty
                ? const Center(child: Text('No items added yet!', style: TextStyle(fontSize: 18)))
                : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(items[index].name),
                      leading:
                          items[index].photoUrl != null
                              ? Image.network(items[index].photoUrl!, width: 50, height: 50, fit: BoxFit.cover)
                              : const Icon(Icons.inventory),
                    );
                  },
                );
          } else if (state is ItemError) {
            return Center(child: Text(state.error, style: const TextStyle(color: Colors.red, fontSize: 18)));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddItemDialog(context, itemsService);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddItemDialog(BuildContext parentContext, ItemsService itemsService) {
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController itemPhotoController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: parentContext,
    builder: (context) {
      return AlertDialog(
        title: Text('Add New Item', style: Theme.of(context).textTheme.titleLarge),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: itemNameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: itemPhotoController,
                decoration: InputDecoration(
                  labelText: 'Photo URL (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final uri = Uri.tryParse(value);
                    if (uri == null || !uri.isAbsolute) {
                      return 'Please enter a valid URL';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
          ElevatedButton(
            onPressed: () async { // Make this async
              if (formKey.currentState!.validate()) {
                final itemName = itemNameController.text.trim();
                final itemPhoto = itemPhotoController.text.trim().isEmpty
                    ? null
                    : itemPhotoController.text.trim();

                // First, save to the database
                final success = await itemsService.addItem(itemName, itemPhoto);

                if (success) {
                  // If saving to DB was successful, update the local state
                  final newItem = Item(name: itemName, photoUrl: itemPhoto);
                  parentContext.read<ItemBloc>().add(AddItem(item: newItem));

                  // Close the dialog and show a success message
                  Navigator.pop(context);
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(content: Text('Item added successfully!')),
                  );
                } else {
                  // Show error message if database save failed
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to save item to database.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
}
}