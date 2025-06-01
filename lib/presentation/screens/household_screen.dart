import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Logic/blocs/household_bloc.dart';
import '../../Logic/blocs/current_household_bloc.dart';
// Ensure Household model is imported

class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController inviteCodeController = TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary; // Use theme's primary color
    final cardColor = Theme.of(context).cardColor;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return BlocProvider(
      create: (context) => HouseholdBloc()..add(LoadHouseholds()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Households',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
        ),
        body: BlocConsumer<HouseholdBloc, HouseholdState>(
          listener: (context, state) {
            if (state is HouseholdError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error), backgroundColor: Colors.redAccent),
              );
            } else if (state is HouseholdLoaded && state.joinSuccess == true) { // Explicitly check for true
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Successfully joined household!'), backgroundColor: Colors.green),
              );
              // Optionally clear the flag after showing snackbar
              // context.read<HouseholdBloc>().add(ResetJoinSuccessFlag()); // You'd need to add this event/state
            }
          },
          builder: (context, state) {
            if (state is HouseholdLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is HouseholdLoaded) {
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Text(
                    'My Households',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  if (state.myHouseholds.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'You are not part of any households yet.',
                          style: TextStyle(fontSize: 16, color: subtitleColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ...state.myHouseholds.map(
                      (household) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        color: cardColor,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                household.name,
                                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                              ),
                              subtitle: Text(
                                'Invite Code: ${household.inviteCode ?? "N/A"}',
                                style: TextStyle(color: subtitleColor, fontSize: 12),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        if (kDebugMode) {
                                          print('Opening household: ${household.name}');
                                        }
                                        context.read<CurrentHouseholdBloc>().add(
                                              SetCurrentHousehold(household: household),
                                            );
                                        Navigator.pop(context);
                                      },
                                      icon: const Icon(Icons.visibility_outlined, size: 18),
                                      label: const Text('Enter'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: primaryColor,
                                        side: BorderSide(color: primaryColor.withOpacity(0.5)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: household.inviteCode != null ? () {
                                        Clipboard.setData(
                                          ClipboardData(text: household.inviteCode!),
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Invite code for "${household.name}" copied!'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      } : null, // Disable if no invite code
                                      icon: const Icon(Icons.copy_outlined, size: 18),
                                      label: const Text('Copy Code'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    color: cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.group_add_outlined, size: 22, color: primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Join a Household',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Enter an invitation code shared with you to join another household.',
                            style: TextStyle(color: subtitleColor, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: inviteCodeController,
                            decoration: InputDecoration(
                              labelText: 'Invitation Code',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              hintText: 'Enter code',
                              prefixIcon: Icon(Icons.vpn_key_outlined, color: primaryColor.withOpacity(0.7)),
                              filled: true,
                              fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: state is HouseholdLoading // Check specific loading for join if available
                                  ? null
                                  : () {
                                      final inviteCode = inviteCodeController.text.trim();
                                      if (inviteCode.isNotEmpty) {
                                        context.read<HouseholdBloc>().add(JoinHousehold(inviteCode: inviteCode));
                                        // inviteCodeController.clear(); // Clear only on success or if desired
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please enter an invitation code')),
                                        );
                                      }
                                    },
                              icon: state is HouseholdLoading // Check specific loading for join
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.login_outlined),
                              label: Text(state is HouseholdLoading ? 'Joining...' : 'Join Household'),
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
                      Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading households',
                        style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.error,
                        style: TextStyle(fontSize: 14, color: subtitleColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => context.read<HouseholdBloc>().add(LoadHouseholds()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.refresh_outlined),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            // Fallback for any other unhandled state (e.g., initial)
            return const Center(child: Text('Loading households...'));
          },
        ),
      ),
    );
  }
}