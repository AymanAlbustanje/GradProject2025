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

class LoadTopPurchasedItems extends StatisticsEvent {
  final String householdId;
  const LoadTopPurchasedItems({required this.householdId});
  
  @override
  List<Object?> get props => [householdId];
}

class LoadLeastPurchasedItems extends StatisticsEvent {
  final String householdId;
  const LoadLeastPurchasedItems({required this.householdId});
  
  @override
  List<Object?> get props => [householdId];
}

class LoadTopExpensiveItems extends StatisticsEvent {
  final String householdId;
  const LoadTopExpensiveItems({required this.householdId});
  
  @override
  List<Object?> get props => [householdId];
}

class LoadLeastExpensiveItems extends StatisticsEvent {
  final String householdId;
  const LoadLeastExpensiveItems({required this.householdId});
  
  @override
  List<Object?> get props => [householdId];
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
  final double totalMoneySpent;
  final String? householdIdForData;
  final bool isShowingTopPurchased;
  final bool isShowingTopExpensive;

  const StatisticsLoaded({
    required this.topPurchasedItems,
    required this.topExpensiveItems,
    required this.totalMoneySpent,
    this.householdIdForData,
    this.isShowingTopPurchased = true,
    this.isShowingTopExpensive = true,
  });

  @override
  List<Object?> get props => [
    topPurchasedItems, 
    topExpensiveItems, 
    totalMoneySpent, 
    householdIdForData,
    isShowingTopPurchased,
    isShowingTopExpensive,
  ];
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
    on<LoadTopPurchasedItems>((event, emit) async {
  if (state is StatisticsLoaded) {
    final currentState = state as StatisticsLoaded;
    emit(StatisticsLoading());
    
    try {
      final items = await statisticsService.getTopPurchasedItems(event.householdId);
      
      emit(StatisticsLoaded(
        topPurchasedItems: items,
        topExpensiveItems: currentState.topExpensiveItems,
        totalMoneySpent: currentState.totalMoneySpent,
        householdIdForData: event.householdId,
        isShowingTopPurchased: true,
        isShowingTopExpensive: currentState.isShowingTopExpensive,
      ));
    } catch (e) {
      emit(StatisticsError(message: 'Failed to load top purchased items: ${e.toString()}'));
    }
  }
});

on<LoadLeastPurchasedItems>((event, emit) async {
  if (state is StatisticsLoaded) {
    final currentState = state as StatisticsLoaded;
    emit(StatisticsLoading());
    
    try {
      final items = await statisticsService.getBottomPurchasedItems(event.householdId);
      
      emit(StatisticsLoaded(
        topPurchasedItems: items,
        topExpensiveItems: currentState.topExpensiveItems,
        totalMoneySpent: currentState.totalMoneySpent,
        householdIdForData: event.householdId,
        isShowingTopPurchased: false,
        isShowingTopExpensive: currentState.isShowingTopExpensive,
      ));
    } catch (e) {
      emit(StatisticsError(message: 'Failed to load least purchased items: ${e.toString()}'));
    }
  }
});
on<LoadTopExpensiveItems>((event, emit) async {
  if (state is StatisticsLoaded) {
    final currentState = state as StatisticsLoaded;
    emit(StatisticsLoading());
    
    try {
      final items = await statisticsService.getTopExpensiveItems(event.householdId);
      
      emit(StatisticsLoaded(
        topPurchasedItems: currentState.topPurchasedItems,
        topExpensiveItems: items,
        totalMoneySpent: currentState.totalMoneySpent,
        householdIdForData: event.householdId,
        isShowingTopPurchased: currentState.isShowingTopPurchased,
        isShowingTopExpensive: true,
      ));
    } catch (e) {
      emit(StatisticsError(message: 'Failed to load top expensive items: ${e.toString()}'));
    }
  }
});

on<LoadLeastExpensiveItems>((event, emit) async {
  if (state is StatisticsLoaded) {
    final currentState = state as StatisticsLoaded;
    emit(StatisticsLoading());
    
    try {
      final items = await statisticsService.getBottomExpensiveItems(event.householdId);
      
      emit(StatisticsLoaded(
        topPurchasedItems: currentState.topPurchasedItems,
        topExpensiveItems: items,
        totalMoneySpent: currentState.totalMoneySpent,
        householdIdForData: event.householdId,
        isShowingTopPurchased: currentState.isShowingTopPurchased,
        isShowingTopExpensive: false,
      ));
    } catch (e) {
      emit(StatisticsError(message: 'Failed to load least expensive items: ${e.toString()}'));
    }
  }
});
  }
}