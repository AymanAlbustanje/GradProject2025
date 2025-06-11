import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gradproject2025/data/Models/household_model.dart';
import 'package:gradproject2025/data/DataSources/household_service.dart';
import 'package:gradproject2025/api_constants.dart';
import 'package:gradproject2025/Logic/blocs/current_household_bloc.dart';

// Events
abstract class HouseholdEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadHouseholds extends HouseholdEvent {}

class CreateHousehold extends HouseholdEvent {
  final String name;
  final CurrentHouseholdBloc currentHouseholdBloc;

  CreateHousehold({required this.name, required this.currentHouseholdBloc});

  @override
  List<Object?> get props => [name, currentHouseholdBloc];
}

class JoinHousehold extends HouseholdEvent {
  final String inviteCode;
  final CurrentHouseholdBloc currentHouseholdBloc;

  JoinHousehold({required this.inviteCode, required this.currentHouseholdBloc});

  @override
  List<Object?> get props => [inviteCode, currentHouseholdBloc];
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
  final bool joinSuccess;
  final bool shouldNavigateBack;

  HouseholdLoaded({required this.myHouseholds, this.joinSuccess = false, this.shouldNavigateBack = false});

  @override
  List<Object?> get props => [myHouseholds, joinSuccess, shouldNavigateBack];
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
      emit(HouseholdLoading());
      try {
        // Create the household
        await householdService.createHousehold(event.name);

        // Get updated list of households
        final myHouseholds = await householdService.getMyHouseholds();

        // Find the newly created household (assume it's the one with matching name)
        Household? newHousehold;
        for (var household in myHouseholds) {
          if (household.name == event.name) {
            newHousehold = household;
            break;
          }
        }

        // Set this as the current household
        if (newHousehold != null) {
          event.currentHouseholdBloc.add(SetCurrentHousehold(household: newHousehold));
        }

        // Emit success state with flag to navigate back
        emit(HouseholdLoaded(myHouseholds: myHouseholds, shouldNavigateBack: true));
      } catch (e) {
        emit(HouseholdError(error: "Failed to create household: ${e.toString()}"));
      }
    });

    on<JoinHousehold>((event, emit) async {
      emit(HouseholdLoading());
      try {
        // Join the household
        await householdService.joinHousehold(event.inviteCode);

        // Get updated list of households
        final myHouseholds = await householdService.getMyHouseholds();

        // Find the newly joined household (the one with the matching invite code)
        Household? joinedHousehold;
        for (var household in myHouseholds) {
          if (household.inviteCode == event.inviteCode) {
            joinedHousehold = household;
            break;
          }
        }

        // Set this as the current household
        if (joinedHousehold != null) {
          event.currentHouseholdBloc.add(SetCurrentHousehold(household: joinedHousehold));
        }

        // Emit success state with flags for join success and navigation
        emit(HouseholdLoaded(myHouseholds: myHouseholds, joinSuccess: true, shouldNavigateBack: true));
      } catch (e) {
        emit(HouseholdError(error: "Failed to join household: ${e.toString()}"));
      }
    });
  }
}
