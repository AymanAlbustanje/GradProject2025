import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gradproject2025/data/Models/household_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Events
abstract class CurrentHouseholdEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SetCurrentHousehold extends CurrentHouseholdEvent {
  final Household household;
  
  SetCurrentHousehold({required this.household});
  
  @override
  List<Object?> get props => [household];
}

class ClearCurrentHousehold extends CurrentHouseholdEvent {}

class LoadCurrentHousehold extends CurrentHouseholdEvent {}

// States
abstract class CurrentHouseholdState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CurrentHouseholdInitial extends CurrentHouseholdState {}

class CurrentHouseholdLoading extends CurrentHouseholdState {}

class CurrentHouseholdSet extends CurrentHouseholdState {
  final Household household;
  
  CurrentHouseholdSet({required this.household});
  
  @override
  List<Object?> get props => [household];
}

class CurrentHouseholdNotSet extends CurrentHouseholdState {}

// Bloc
class CurrentHouseholdBloc extends Bloc<CurrentHouseholdEvent, CurrentHouseholdState> {
  CurrentHouseholdBloc() : super(CurrentHouseholdInitial()) {
    // KEEP ONLY ONE handler for SetCurrentHousehold
    on<SetCurrentHousehold>((event, emit) async {
      emit(CurrentHouseholdLoading());
      try {
        final prefs = await SharedPreferences.getInstance();
        // Use the household's toJson method
        await prefs.setString('currentHousehold', json.encode(event.household.toJson()));
        emit(CurrentHouseholdSet(household: event.household));
      } catch (e) {
        if (kDebugMode) {
          print('Error setting current household: $e');
        }
        emit(CurrentHouseholdNotSet());
      }
    });
    
    on<ClearCurrentHousehold>((event, emit) async {
      emit(CurrentHouseholdLoading());
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('currentHousehold');
        emit(CurrentHouseholdNotSet());
      } catch (e) {
        // Keep the current state
      }
    });
    
    on<LoadCurrentHousehold>((event, emit) async {
  emit(CurrentHouseholdLoading());
  try {
    final prefs = await SharedPreferences.getInstance();
    final householdJson = prefs.getString('currentHousehold');
    
    if (householdJson != null && householdJson.isNotEmpty) {
      if (kDebugMode) {
        print('Loading household from JSON: $householdJson');
      }
      
      final Map<String, dynamic> householdMap = json.decode(householdJson);
      
      // Keep the ID in its original form without type conversion
      final household = Household(
        id: householdMap['id'], // Keep as-is (could be int or String)
        name: householdMap['name'],
        inviteCode: householdMap['inviteCode'] ?? householdMap['invite_code'],
        createdAt: householdMap['created_at'] != null ? 
            DateTime.parse(householdMap['created_at']) : null,
      );
      
      if (kDebugMode) {
        print('Loaded household: ID=${household.id} (${household.id.runtimeType}), Name=${household.name}');
      }
      
      emit(CurrentHouseholdSet(household: household));
    } else {
      emit(CurrentHouseholdNotSet());
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error loading current household: $e');
      print('Stack trace: ${StackTrace.current}');
    }
    emit(CurrentHouseholdNotSet());
  }
});
  }
}