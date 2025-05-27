import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gradproject2025/data/DataSources/statistics_service.dart';
import 'package:gradproject2025/api_constants.dart';

// Events
abstract class StatisticsEvent extends Equatable {
  const StatisticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadStatistics extends StatisticsEvent {
  final String householdId;

  const LoadStatistics({required this.householdId});

  @override
  List<Object?> get props => [householdId];
}

// States
abstract class StatisticsState extends Equatable {
  const StatisticsState();

  @override
  List<Object?> get props => [];
}

class StatisticsInitial extends StatisticsState {}

class StatisticsLoading extends StatisticsState {}

class StatisticsLoaded extends StatisticsState {
  final List<Map<String, dynamic>> topPurchasedItems;
  final List<Map<String, dynamic>> topExpensiveItems;
  final double totalMoneySpent; // Added
  final String? householdIdForData;

  const StatisticsLoaded({
    required this.topPurchasedItems,
    required this.topExpensiveItems,
    required this.totalMoneySpent, // Added
    this.householdIdForData, 
  });

  @override
  List<Object?> get props => [topPurchasedItems, topExpensiveItems, totalMoneySpent, householdIdForData]; // Added totalMoneySpent
}

class StatisticsError extends StatisticsState {
  final String message;

  const StatisticsError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final statisticsService = StatisticsService(baseUrl: ApiConstants.baseUrl);

  StatisticsBloc() : super(StatisticsInitial()) {
    on<LoadStatistics>((event, emit) async {
      emit(StatisticsLoading());
      
      try {
        final topPurchasedItems = await statisticsService.getTopPurchasedItems(event.householdId);
        final topExpensiveItems = await statisticsService.getTopExpensiveItems(event.householdId);
        final totalMoneySpent = await statisticsService.getTotalMoneySpent(event.householdId); // Added
        
        emit(StatisticsLoaded(
          topPurchasedItems: topPurchasedItems,
          topExpensiveItems: topExpensiveItems,
          totalMoneySpent: totalMoneySpent, // Added
          householdIdForData: event.householdId, 
        ));
      } catch (e) {
        emit(StatisticsError(message: 'Failed to load statistics: ${e.toString()}'));
      }
    });
  }
}