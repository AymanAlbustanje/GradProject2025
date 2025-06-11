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
        await householdService.createHousehold(event.name);

        final myHouseholds = await householdService.getMyHouseholds();

        Household? newHousehold;
        for (var household in myHouseholds) {
          if (household.name == event.name) {
            newHousehold = household;
            break;
          }
        }

        if (newHousehold != null) {
          event.currentHouseholdBloc.add(SetCurrentHousehold(household: newHousehold));
        }

        emit(HouseholdLoaded(myHouseholds: myHouseholds, shouldNavigateBack: true));
      } catch (e) {
        emit(HouseholdError(error: "Failed to create household: ${e.toString()}"));
      }
    });

    on<JoinHousehold>((event, emit) async {
      emit(HouseholdLoading());
      try {
        await householdService.joinHousehold(event.inviteCode);

        final myHouseholds = await householdService.getMyHouseholds();

        Household? joinedHousehold;
        for (var household in myHouseholds) {
          if (household.inviteCode == event.inviteCode) {
            joinedHousehold = household;
            break;
          }
        }

        if (joinedHousehold != null) {
          event.currentHouseholdBloc.add(SetCurrentHousehold(household: joinedHousehold));
        }

        emit(HouseholdLoaded(myHouseholds: myHouseholds, joinSuccess: true, shouldNavigateBack: true));
      } catch (e) {
        emit(HouseholdError(error: "Failed to join household: ${e.toString()}"));
      }
    });
  }
}
