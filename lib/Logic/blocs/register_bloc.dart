import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gradproject2025/data/DataSources/register_service.dart';

abstract class RegisterEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class RegisterSubmitted extends RegisterEvent {
  final String name;
  final String email;
  final String password;

  RegisterSubmitted({required this.name, required this.email, required this.password});

  @override
  List<Object?> get props => [name, email, password];
}

abstract class RegisterState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {
  final String email;

  RegisterSuccess({required this.email});

  @override
  List<Object?> get props => [email];
}

class RegisterFailure extends RegisterState {
  final String error;

  RegisterFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final RegisterService registerService;

  RegisterBloc({required this.registerService}) : super(RegisterInitial()) {
    on<RegisterSubmitted>((event, emit) async {
      emit(RegisterLoading());
      try {
        await registerService.register(event.name, event.email, event.password);
        emit(RegisterSuccess(email: event.email));
      } catch (e) {
        emit(RegisterFailure(error: e.toString()));
      }
    });
  }
}