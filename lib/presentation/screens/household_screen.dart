import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Logic/blocs/household_bloc.dart';

class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController inviteCodeController = TextEditingController();

    return BlocProvider(
      create: (context) => HouseholdBloc()..add(LoadHouseholds()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Households')),
        body: BlocBuilder<HouseholdBloc, HouseholdState>(
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
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Enhanced Open Household Button
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        // Navigate to household details
                                        if (kDebugMode) {
                                          print('Opening household: ${household.name}');
                                        }
                                        // Navigator.push(context, MaterialPageRoute(builder: (_) =>
                                        //   HouseholdDetailScreen(household: household)));
                                      },
                                      icon: const Icon(Icons.visibility, size: 18),
                                      label: const Text(
                                        'OPEN',
                                        style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF0078D4),
                                        backgroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        side: const BorderSide(color: Color(0xFF0078D4), width: 1.5),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                        elevation: 0,
                                        shadowColor: Colors.black12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Enhanced Copy Code Button
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        // Directly copy the code to clipboard
                                        Clipboard.setData(ClipboardData(text: household.inviteCode));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Invite code for "${household.name}" copied!'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.copy, size: 18),
                                      label: const Text(
                                        'COPY CODE',
                                        style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0078D4),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                        elevation: 2,
                                        shadowColor: Colors.black26,
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
                                backgroundColor: const Color(0xFF0078D4), // Blue background color
                                foregroundColor: Colors.white, // White text color
                              ),
                              onPressed: () {
                                final inviteCode = inviteCodeController.text.trim();
                                if (inviteCode.isNotEmpty) {
                                  context.read<HouseholdBloc>().add(JoinHousehold(inviteCode: inviteCode));
                                  inviteCodeController.clear();
                                } else {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(const SnackBar(content: Text('Please enter an invitation code.')));
                                }
                              },
                              icon: const Icon(Icons.login),
                              label: const Text('JOIN HOUSEHOLD'),
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
