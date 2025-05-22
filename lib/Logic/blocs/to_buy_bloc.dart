import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gradproject2025/data/Models/item_model.dart';
import 'package:gradproject2025/data/DataSources/to_buy_service.dart';
import 'package:gradproject2025/api_constants.dart';

// Events
abstract class ToBuyEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadToBuyItems extends ToBuyEvent {
  final String householdId;

  LoadToBuyItems({required this.householdId});

  @override
  List<Object?> get props => [householdId];
}

class AddToBuyItem extends ToBuyEvent {
  final Item item;

  AddToBuyItem({required this.item});

  @override
  List<Object?> get props => [item];
}

class RemoveToBuyItem extends ToBuyEvent {
  final String itemId;

  RemoveToBuyItem({required this.itemId});

  @override
  List<Object?> get props => [itemId];
}

// States
abstract class ToBuyState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ToBuyInitial extends ToBuyState {}

class ToBuyLoading extends ToBuyState {}

class ToBuyLoaded extends ToBuyState {
  final List<Item> items;

  ToBuyLoaded({required this.items});

  @override
  List<Object?> get props => [items];
}

class ToBuyError extends ToBuyState {
  final String error;

  ToBuyError({required this.error});

  @override
  List<Object?> get props => [error];
}

// Bloc
class ToBuyBloc extends Bloc<ToBuyEvent, ToBuyState> {
  final toBuyService = ToBuyService(baseUrl: ApiConstants.baseUrl);

  ToBuyBloc() : super(ToBuyInitial()) {
    on<LoadToBuyItems>((event, emit) async {
      emit(ToBuyLoading());
      try {
        final items = await toBuyService.getToBuyItems(event.householdId);
        emit(ToBuyLoaded(items: items));
      } catch (e) {
        emit(ToBuyError(error: e.toString()));
      }
    });

    on<AddToBuyItem>((event, emit) {
      if (state is ToBuyLoaded) {
        final currentState = state as ToBuyLoaded;
        final updatedItems = List<Item>.from(currentState.items)..add(event.item);
        emit(ToBuyLoaded(items: updatedItems));
      }
    });

    on<RemoveToBuyItem>((event, emit) {
      if (state is ToBuyLoaded) {
        final currentState = state as ToBuyLoaded;
        final updatedItems = currentState.items.where((item) => item.id != event.itemId).toList();
        emit(ToBuyLoaded(items: updatedItems));
      }
    });
  }
}
