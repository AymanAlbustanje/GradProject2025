import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gradproject2025/data/Models/household_model.dart';
import 'package:gradproject2025/data/DataSources/household_service.dart';
import 'package:gradproject2025/api_constants.dart';

// Events
abstract class HouseholdEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadHouseholds extends HouseholdEvent {}

class CreateHousehold extends HouseholdEvent {
  final String name;

  CreateHousehold({required this.name});

  @override
  List<Object?> get props => [name];
}

class JoinHousehold extends HouseholdEvent {
  final String inviteCode;

  JoinHousehold({required this.inviteCode});

  @override
  List<Object?> get props => [inviteCode];
}

// States
abstract class HouseholdState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HouseholdInitial extends HouseholdState {}

class HouseholdLoading extends HouseholdState {}

class HouseholdLoaded extends HouseholdState {
  final List<Household> myHouseholds;

  HouseholdLoaded({required this.myHouseholds});

  @override
  List<Object?> get props => [myHouseholds];
}

class HouseholdError extends HouseholdState {
  final String error;

  HouseholdError({required this.error});

  @override
  List<Object?> get props => [error];
}

// Bloc
class HouseholdBloc extends Bloc<HouseholdEvent, HouseholdState> {
  final householdService = HouseholdService(baseUrl: ApiConstants.baseUrl);

  HouseholdBloc() : super(HouseholdInitial()) {
    on<LoadHouseholds>((event, emit) async {
      emit(HouseholdLoading());
      try {
        final myHouseholds = await householdService.getMyHouseholds();
        emit(HouseholdLoaded(myHouseholds: myHouseholds));
      } catch (e) {
        emit(HouseholdError(error: e.toString()));
      }
    });

    on<CreateHousehold>((event, emit) async {
      // Emit loading state to indicate an operation is in progress
      emit(HouseholdLoading()); 
      try {
        await householdService.createHousehold(event.name);
        // After successful creation, dispatch LoadHouseholds to refresh the list.
        // This will fetch all households again, including the new one.
        add(LoadHouseholds());
      } catch (e) {
        // If creation failed, emit an error state.
        // You might want to include the previous state if you want to show old data + error.
        emit(HouseholdError(error: "Failed to create household: ${e.toString()}"));
      }
    });

    on<JoinHousehold>((event, emit) async {
      // Emit loading state
      emit(HouseholdLoading());
      try {
        await householdService.joinHousehold(event.inviteCode);
        // Refresh the list of households
        add(LoadHouseholds());
      } catch (e) {
        emit(HouseholdError(error: "Failed to join household: ${e.toString()}"));
      }
    });
  }
}