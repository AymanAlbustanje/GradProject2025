// ignore_for_file: use_build_context_synchronously, deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/Logic/blocs/current_household_bloc.dart';
import 'package:gradproject2025/Logic/blocs/in_house_bloc.dart';
import 'package:gradproject2025/data/DataSources/in_house_service.dart';
import 'package:gradproject2025/api_constants.dart';
import '../widgets/in_house_items_widget.dart';
import '../widgets/item_search.dart';

class InHouseScreen extends StatefulWidget {
  const InHouseScreen({super.key});

  @override
  _InHouseScreenState createState() => _InHouseScreenState();
}

class _InHouseScreenState extends State<InHouseScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
            
            Expanded(child: InHouseItemsWidget()),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primaryColor,
          onPressed: () {
            final inHouseService = InHouseService(baseUrl: ApiConstants.baseUrl);
            showAddItemDialog(context, inHouseService);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}