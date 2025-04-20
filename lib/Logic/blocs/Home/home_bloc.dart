import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial(0)) {
    on<IncrementCounter>((event, emit) {
      final currentState = state as HomeInitial;
      emit(HomeInitial(currentState.counter + 1));
    });
  }
}