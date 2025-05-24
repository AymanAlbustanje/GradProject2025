// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/Logic/blocs/current_household_bloc.dart';
import 'package:gradproject2025/Logic/blocs/in_house_bloc.dart';
// Fix import path - use just ONE, consistent with your project structure
import '../Widgets/item_search.dart';
import '../Widgets/in_house_items_widget.dart';

class InHouseScreen extends StatefulWidget {
  const InHouseScreen({super.key});

  @override
  _InHouseScreenState createState() => _InHouseScreenState();
}

class _InHouseScreenState extends State<InHouseScreen> {
  final GlobalKey<InHouseItemsWidgetState> _inHouseItemsKey = GlobalKey<InHouseItemsWidgetState>();
  final GlobalKey<ItemSearchWidgetState> _itemSearchWidgetKey = GlobalKey<ItemSearchWidgetState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
      if (currentHouseholdState is CurrentHouseholdSet) {
        if (currentHouseholdState.household.id != null) {
          context.read<InHouseBloc>().add(
                LoadHouseholdItems(householdId: currentHouseholdState.household.id.toString()),
              );
        }
      }
    });
  }

  void _triggerAddItemForm() {
    _inHouseItemsKey.currentState?.displayCreateAndAddItemForm(
      "", 
      onBarcodeFoundExistingItems: (List<Map<String, dynamic>> items) {
        if (items.isNotEmpty) {
          _itemSearchWidgetKey.currentState?.showAddToHouseholdFormPublic(items[0]);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No existing items found for the scanned barcode.')),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return BlocListener<CurrentHouseholdBloc, CurrentHouseholdState>(
      listener: (context, state) {
        if (state is CurrentHouseholdSet) {
          if (state.household.id != null) {
            context.read<InHouseBloc>().add(LoadHouseholdItems(householdId: state.household.id.toString()));
          }
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            ItemSearchWidget(key: _itemSearchWidgetKey),
            Expanded(
              child: InHouseItemsWidget(key: _inHouseItemsKey),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primaryColor,
          onPressed: _triggerAddItemForm,
          tooltip: 'Add New Item',
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}