import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gradproject2025/data/DataSources/verification_service.dart';

abstract class VerificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class VerifyEmail extends VerificationEvent {
  final String email;
  final String code;

  VerifyEmail({required this.email, required this.code});

  @override
  List<Object?> get props => [email, code];
}

class ResendCode extends VerificationEvent {
  final String email;

  ResendCode({required this.email});

  @override
  List<Object?> get props => [email];
}

abstract class VerificationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VerificationInitial extends VerificationState {}

class VerificationLoading extends VerificationState {}

class VerificationSuccess extends VerificationState {}

class VerificationFailure extends VerificationState {
  final String error;

  VerificationFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

class ResendCodeLoading extends VerificationState {}

class ResendCodeSuccess extends VerificationState {}

class ResendCodeFailure extends VerificationState {
  final String error;

  ResendCodeFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final VerificationService verificationService;

  VerificationBloc({required this.verificationService}) : super(VerificationInitial()) {
    on<VerifyEmail>((event, emit) async {
      emit(VerificationLoading());
      try {
        await verificationService.verifyEmail(event.email, event.code);
        emit(VerificationSuccess());
      } catch (e) {
        emit(VerificationFailure(error: e.toString()));
      }
    });

    on<ResendCode>((event, emit) async {
      emit(ResendCodeLoading());
      try {
        await verificationService.resendCode(event.email);
        emit(ResendCodeSuccess());
      } catch (e) {
        emit(ResendCodeFailure(error: e.toString()));
      }
    });
  }
}