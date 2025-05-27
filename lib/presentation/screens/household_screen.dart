import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Logic/blocs/household_bloc.dart';
import '../../Logic/blocs/current_household_bloc.dart';

class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController inviteCodeController = TextEditingController();

    return BlocProvider(
      create: (context) => HouseholdBloc()..add(LoadHouseholds()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Households')),
        body: BlocConsumer<HouseholdBloc, HouseholdState>(
          listener: (context, state) {
            if (state is HouseholdError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error), backgroundColor: Colors.red));
            } else if (state is HouseholdLoaded && state.joinSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Successfully joined household!'), backgroundColor: Colors.green),
              );
            }
          },
          builder: (context, state) {
            if (state is HouseholdLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is HouseholdLoaded) {
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Text('My Households', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (state.myHouseholds.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: Text('You are not part of any households yet.')),
                    )
                  else
                    ...state.myHouseholds.map(
                      (household) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(household.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'Invite Code: ${household.inviteCode}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        if (kDebugMode) {
                                          print('Opening household: ${household.name}');
                                        }
                                        // Set as current household
                                        context.read<CurrentHouseholdBloc>().add(
                                          SetCurrentHousehold(household: household),
                                        );
                                        // Return to main screen
                                        Navigator.pop(context);
                                      },
                                      icon: const Icon(Icons.visibility, size: 18),
                                      label: const Text('Enter'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF0078D4),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: household.inviteCode ?? 'No invite code available'),
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Invite code for "${household.name}" copied!'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.copy, size: 18),
                                      label: const Text('COPY CODE'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0078D4),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.group_add, size: 22),
                              SizedBox(width: 8),
                              Text('Join a Household', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Enter an invitation code shared with you to join another household.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: inviteCodeController,
                            decoration: InputDecoration(
                              labelText: 'Invitation Code',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              hintText: 'Enter code from another household',
                              prefixIcon: const Icon(Icons.key),
                              filled: true,
                              fillColor:
                                  Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                backgroundColor: const Color(0xFF0078D4),
                                foregroundColor: Colors.white,
                              ),
                              onPressed:
                                  state is HouseholdLoading
                                      ? null
                                      : () {
                                        final inviteCode = inviteCodeController.text.trim();
                                        if (inviteCode.isNotEmpty) {
                                          context.read<HouseholdBloc>().add(JoinHousehold(inviteCode: inviteCode));
                                          inviteCodeController.clear();
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Please enter an invitation code')),
                                          );
                                        }
                                      },
                              icon:
                                  state is HouseholdLoading
                                      ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                      : const Icon(Icons.login),
                              label: Text(state is HouseholdLoading ? 'JOINING...' : 'JOIN HOUSEHOLD'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else if (state is HouseholdError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error loading households: ${state.error}', textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => context.read<HouseholdBloc>().add(LoadHouseholds()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return const Center(child: Text('Loading households...'));
            }
          },
        ),
      ),
    );
  }
}
