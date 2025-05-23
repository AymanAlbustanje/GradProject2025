// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/Logic/blocs/current_household_bloc.dart';
import 'package:gradproject2025/Logic/blocs/in_house_bloc.dart';
// Remove the conflicting import
// import 'package:gradproject2025/presentation/Widgets/in_house_items_widget.dart' show InHouseItemsWidgetState;
import '../widgets/in_house_items_widget.dart'; // Keep this import
import '../widgets/item_search.dart';

class InHouseScreen extends StatefulWidget {
  const InHouseScreen({super.key});

  @override
  _InHouseScreenState createState() => _InHouseScreenState();
}

class _InHouseScreenState extends State<InHouseScreen> {
  final GlobalKey<InHouseItemsWidgetState> _inHouseItemsKey = GlobalKey<InHouseItemsWidgetState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure context is still mounted before accessing it.
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

  // Method to show the "Create and Add Item" form using the GlobalKey
  void _triggerAddItemForm() {
    _inHouseItemsKey.currentState?.displayCreateAndAddItemForm("");
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
            const ItemSearchWidget(),
            Expanded(
              child: InHouseItemsWidget(key: _inHouseItemsKey),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primaryColor,
          onPressed: () {
            _triggerAddItemForm();
          },
          tooltip: 'Add New Item',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}