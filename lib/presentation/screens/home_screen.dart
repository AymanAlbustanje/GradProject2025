import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Logic/blocs/Home/home_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                final counter = (state as HomeInitial).counter;
                return Text('$counter', style: Theme.of(context).textTheme.headlineMedium);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<HomeBloc>().add(IncrementCounter());
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}