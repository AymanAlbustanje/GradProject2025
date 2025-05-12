import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gradproject2025/data/Models/item_model.dart';
import 'package:gradproject2025/data/DataSources/items_service.dart';

// Events
abstract class ItemEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadItems extends ItemEvent {}

class AddItem extends ItemEvent {
  final Item item;

  AddItem({required this.item});

  @override
  List<Object?> get props => [item];
}

class UpdateItem extends ItemEvent {
  final Item item;

  UpdateItem({required this.item});

  @override
  List<Object?> get props => [item];
}

class DeleteItem extends ItemEvent {
  final String itemId;

  DeleteItem({required this.itemId});

  @override
  List<Object?> get props => [itemId];
}

// States
abstract class ItemState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ItemInitial extends ItemState {}

class ItemLoading extends ItemState {}

class ItemLoaded extends ItemState {
  final List<Item> items;

  ItemLoaded({required this.items});

  @override
  List<Object?> get props => [items];
}

class ItemError extends ItemState {
  final String error;

  ItemError({required this.error});

  @override
  List<Object?> get props => [error];
}

// Bloc
class ItemBloc extends Bloc<ItemEvent, ItemState> {
  final itemsService = ItemsService(baseUrl: 'http://192.168.1.100:3000');

  ItemBloc() : super(ItemInitial()) {
    on<LoadItems>((event, emit) async {
      emit(ItemLoading());
      try {
        // Actually fetch items from database
        final items = await itemsService.getItems();
        emit(ItemLoaded(items: items));
      } catch (e) {
        emit(ItemError(error: e.toString()));
      }
    });

    on<AddItem>((event, emit) {
      if (state is ItemLoaded) {
        final currentState = state as ItemLoaded;
        final updatedItems = List<Item>.from(currentState.items)..add(event.item);
        emit(ItemLoaded(items: updatedItems));
      }
    });

    on<UpdateItem>((event, emit) {
      if (state is ItemLoaded) {
        final currentState = state as ItemLoaded;
        final updatedItems = currentState.items.map((item) {
          return item.id == event.item.id ? event.item : item;
        }).toList();
        
        emit(ItemLoaded(items: updatedItems));
      }
    });

    on<DeleteItem>((event, emit) {
      if (state is ItemLoaded) {
        final currentState = state as ItemLoaded;
        final updatedItems = currentState.items.where((item) => item.id != event.itemId).toList();
        
        emit(ItemLoaded(items: updatedItems));
      }
    });
  }
}