// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/Logic/blocs/current_household_bloc.dart';
import 'package:gradproject2025/Logic/blocs/statistics_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentHouseholdState = context.watch<CurrentHouseholdBloc>().state;
    if (currentHouseholdState is CurrentHouseholdSet && currentHouseholdState.household.id != null) {
      final statisticsBloc = context.read<StatisticsBloc>();
      if (statisticsBloc.state is StatisticsInitial ||
          (statisticsBloc.state is StatisticsError) ||
          (statisticsBloc.state is StatisticsLoaded && ((statisticsBloc.state as StatisticsLoaded).topPurchasedItems.isEmpty && (statisticsBloc.state as StatisticsLoaded).topExpensiveItems.isEmpty)) ||
          (statisticsBloc.state is StatisticsLoaded && (statisticsBloc.state as StatisticsLoaded).householdIdForData != currentHouseholdState.household.id.toString())) {
        statisticsBloc.add(LoadStatistics(householdId: currentHouseholdState.household.id.toString()));
      }
    }

    return Scaffold(
      body: BlocBuilder<StatisticsBloc, StatisticsState>(
        builder: (context, state) {
          if (state is StatisticsLoading) {
            return _buildLoadingShimmer(context);
          } else if (state is StatisticsLoaded) {
            if (state.topPurchasedItems.isEmpty && state.topExpensiveItems.isEmpty) {
              return _buildEmptyStateAllData(context, "No statistics data available for this household yet. Start adding items and purchases!");
            }
            return _buildStatisticsContent(context, state);
          } else if (state is StatisticsError) {
            return _buildErrorState(context, state.message);
          }
          if (currentHouseholdState is! CurrentHouseholdSet || currentHouseholdState.household.id == null) {
            return _buildEmptyStateAllData(context, "Please select a household to view statistics.");
          }
          return _buildLoadingShimmer(context);
        },
      ),
    );
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(), // Disable scrolling for shimmer
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 30,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            _buildShimmerStatCard(),
            const SizedBox(height: 24),
            _buildShimmerStatCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerStatCard() {
    return Container(
      width: double.infinity,
      height: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 20, width: 250, color: Colors.white, margin: const EdgeInsets.only(bottom: 8)),
                Container(height: 16, width: 180, color: Colors.white),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 80, color: isDarkMode ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () {
                final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
                if (currentHouseholdState is CurrentHouseholdSet && currentHouseholdState.household.id != null) {
                  context.read<StatisticsBloc>().add(LoadStatistics(householdId: currentHouseholdState.household.id.toString()));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateAllData(BuildContext context, String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights_rounded, size: 80, color: isDarkMode ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No Statistics Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            if (message.contains("select a household"))
              ElevatedButton(
                child: const Text('Select Household'),
                onPressed: () {
                  // Implement navigation or dialog to select household
                },
              )
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsContent(BuildContext context, StatisticsLoaded state) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return RefreshIndicator(
      onRefresh: () async {
        final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
        if (currentHouseholdState is CurrentHouseholdSet && currentHouseholdState.household.id != null) {
          context.read<StatisticsBloc>().add(LoadStatistics(householdId: currentHouseholdState.household.id.toString()));
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, left: 4.0),
              child: Text(
                'Household Statistics',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
              ),
            ),
            if (state.topPurchasedItems.isNotEmpty)
              _buildStatCard(
                context: context,
                title: 'Most Frequently Purchased',
                subtitle: 'Top 5 by purchase count',
                height: 350,
                isDarkMode: isDarkMode,
                child: _buildPurchaseCountChart(context, state.topPurchasedItems, isDarkMode),
              )
            else
              _buildEmptyStatCard(
                context: context,
                title: 'Most Frequently Purchased',
                message: 'Not enough purchase data yet.',
                isDarkMode: isDarkMode,
              ),
            const SizedBox(height: 24),
            if (state.topExpensiveItems.isNotEmpty)
              _buildStatCard(
                context: context,
                title: 'Top Expenses',
                subtitle: 'Top 5 by total purchase value',
                height: 350,
                isDarkMode: isDarkMode,
                child: _buildExpensesChart(context, state.topExpensiveItems, isDarkMode),
              )
            else
              _buildEmptyStatCard(
                context: context,
                title: 'Top Expenses',
                message: 'Not enough expense data yet.',
                isDarkMode: isDarkMode,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required double height,
    required bool isDarkMode,
    required Widget child,
  }) {
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final shadowColor = isDarkMode ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.2);

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 12.0, left: 8.0, right: 16.0),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStatCard({
    required BuildContext context,
    required String title,
    required String message,
    required bool isDarkMode,
  }) {
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final shadowColor = isDarkMode ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.2);

    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
          ),
          const SizedBox(height: 16),
          Icon(
            Icons.data_usage_rounded,
            size: 48,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseCountChart(BuildContext context, List<Map<String, dynamic>> items, bool isDarkMode) {
    final List<Color> barColors = [
      Colors.blue.shade400, Colors.blue.shade300, Colors.blue.shade200,
      Colors.lightBlue.shade200, Colors.lightBlue.shade100,
    ];
    final chartItems = items.take(5).toList();
    final primaryColor = Theme.of(context).colorScheme.primary;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (chartItems.isNotEmpty ? chartItems.map((e) => _parseNum(e['purchase_counter'])).reduce((a, b) => a > b ? a : b) * 1.2 : 10).toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            // tooltipBgColor: isDarkMode ? Colors.grey[700] : Colors.blueGrey[50], // Use getTooltipColor instead
            getTooltipColor: (BarChartGroupData group) { // Alternative for background color
              return isDarkMode ? Colors.grey[700]! : Colors.blueGrey[50]!;
            },
            // tooltipRoundedRadius: 8, // If this parameter is not defined in your fl_chart version,
                                     // the default radius will be used. For custom radius,
                                     // you might need to build a custom tooltip widget via getTooltipItem.
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String itemName = chartItems[group.x.toInt()]['item_name'] ?? '';
              return BarTooltipItem(
                '$itemName\n',
                TextStyle(color: isDarkMode ? Colors.white : primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                children: <TextSpan>[
                  TextSpan(
                    text: rod.toY.toInt().toString(),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : primaryColor.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
// ... existing titlesData code ...
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: (chartItems.isNotEmpty ? chartItems.map((e) => _parseNum(e['purchase_counter'])).reduce((a, b) => a > b ? a : b) / 4 : 2).toDouble().clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                if (value == 0 && meta.max == 0) return const SizedBox();
                if (value == meta.max && meta.max == 0) return const SizedBox();
                if (meta.appliedInterval == 0) { 
                     if (value != 0 && value != meta.max) return const SizedBox();
                } else if (value % meta.appliedInterval != 0 && value != meta.max) {
                     return const SizedBox();
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 10),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= chartItems.length) return const SizedBox();
                String itemName = chartItems[value.toInt()]['item_name'] ?? 'N/A';
                return SideTitleWidget( 
                  meta: meta,
                  space: 8.0,
                  child: Text(
                    itemName.length > 8 ? '${itemName.substring(0, 6)}...' : itemName,
                    style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700], fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
// ... existing gridData, borderData, barGroups code ...
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (chartItems.isNotEmpty ? chartItems.map((e) => _parseNum(e['purchase_counter'])).reduce((a, b) => a > b ? a : b) / 4 : 2).toDouble().clamp(1, double.infinity),
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: chartItems.asMap().entries.map((entry) {
          final int index = entry.key;
          final item = entry.value;
          final double val = _parseNum(item['purchase_counter']);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                width: 18,
                color: barColors[index % barColors.length],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpensesChart(BuildContext context, List<Map<String, dynamic>> items, bool isDarkMode) {
    final List<Color> barColors = [
      Colors.green.shade400, Colors.green.shade300, Colors.green.shade200,
      Colors.lightGreen.shade200, Colors.lightGreen.shade100,
    ];
    final chartItems = items.take(5).toList();
    final primaryColor = Theme.of(context).colorScheme.primary;
    final maxValue = chartItems.isNotEmpty ? chartItems.map((e) => _parseNum(e['total_purchase_price'])).reduce((a, b) => a > b ? a : b) * 1.2 : 100;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue.toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            // tooltipBgColor: isDarkMode ? Colors.grey[700] : Colors.green[50], // Use getTooltipColor instead
            getTooltipColor: (BarChartGroupData group) { // Alternative for background color
              return isDarkMode ? Colors.grey[700]! : Colors.green[50]!;
            },
            // tooltipRoundedRadius: 8, // If this parameter is not defined, comment it out or remove.
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String itemName = chartItems[group.x.toInt()]['item_name'] ?? '';
              return BarTooltipItem(
                '$itemName\n',
                TextStyle(color: isDarkMode ? Colors.white : Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 14),
                children: <TextSpan>[
                  TextSpan(
                    text: '\$${rod.toY.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
// ... existing titlesData code ...
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: (maxValue / 4).toDouble().clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                if (value == 0 && meta.max == 0) return const SizedBox();
                if (value == meta.max && meta.max == 0) return const SizedBox();
                 if (meta.appliedInterval == 0) { 
                     if (value != 0 && value != meta.max) return const SizedBox();
                } else if (value % meta.appliedInterval != 0 && value != meta.max) {
                     return const SizedBox();
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    '\$${value.toInt()}',
                    style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 10),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= chartItems.length) return const SizedBox();
                String itemName = chartItems[value.toInt()]['item_name'] ?? 'N/A';
                return SideTitleWidget( 
                  meta: meta,
                  space: 8.0,
                  child: Text(
                    itemName.length > 8 ? '${itemName.substring(0, 6)}...' : itemName,
                    style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700], fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
// ... existing gridData, borderData, barGroups code ...
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxValue / 4).toDouble().clamp(1, double.infinity),
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: chartItems.asMap().entries.map((entry) {
          final int index = entry.key;
          final item = entry.value;
          final double val = _parseNum(item['total_purchase_price']);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                width: 18,
                color: barColors[index % barColors.length],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  double _parseNum(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}