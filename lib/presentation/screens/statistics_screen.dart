// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/Logic/blocs/current_household_bloc.dart';
import 'package:gradproject2025/Logic/blocs/statistics_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math' as math;

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  // Define base accent colors - these might need slight adjustments for dark mode if they clash
  static const Color baseMediumBlue = Color(0xFF0078D4);
  static const Color baseLightBlue = Color(0xFF4CA6E5);
  static const Color baseDarkBlue = Color(0xFF005B9F);
  static const Color baseVeryDarkBlue = Color(0xFF004275);

  static const Color baseBarColorCoral = Color(0xFFFF8A80);
  static const Color baseBarColorYellow = Color(0xFFFFE082);
  static const Color baseBarColorPurpleAccent = Color(0xFF7C4DFF);
  static const Color baseBarColorBlue = Color(0xFF40C4FF);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final currentHouseholdState = context.watch<CurrentHouseholdBloc>().state;
    if (currentHouseholdState is CurrentHouseholdSet && currentHouseholdState.household.id != null) {
      final householdId = currentHouseholdState.household.id.toString();
      final statisticsBloc = context.read<StatisticsBloc>();
      if (statisticsBloc.state is StatisticsInitial ||
          (statisticsBloc.state is StatisticsLoaded && (statisticsBloc.state as StatisticsLoaded).householdIdForData != householdId) ||
          statisticsBloc.state is StatisticsError) {
        statisticsBloc.add(LoadStatistics(householdId: householdId));
      }
    } else {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: Text('Statistics', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0.5,
          iconTheme: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_work_outlined, size: 60, color: theme.hintColor),
              const SizedBox(height: 16),
              Text('Please select a household to view statistics.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: theme.hintColor)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      // appBar: AppBar(
      //   title: Text('Statistics', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
      //   backgroundColor: theme.colorScheme.surface,
      //   elevation: 0.5,
      //   iconTheme: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
      // ),
      body: BlocBuilder<StatisticsBloc, StatisticsState>(
        builder: (context, state) {
          if (state is StatisticsLoading || state is StatisticsInitial) {
            return _buildLoadingShimmer(context, isDarkMode);
          } else if (state is StatisticsLoaded) {
            return _buildStatisticsContent(context, state, isDarkMode);
          } else if (state is StatisticsError) {
            return _buildErrorState(context, state.message, isDarkMode);
          }
          return Center(child: Text('Select a household to see statistics.', style: TextStyle(color: theme.hintColor)));
        },
      ),
    );
  }

  Widget _buildLoadingShimmer(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(height: 20, width: 150, color: theme.cardColor, margin: const EdgeInsets.only(bottom: 8)),
          Container(height: 1, color: theme.dividerColor, margin: const EdgeInsets.only(bottom: 16)),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: List.generate(3, (index) => Container(
                    height: 60, width: double.infinity, color: theme.cardColor, margin: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [Container(width: 40, height: 40, color: theme.splashColor), const SizedBox(width: 10), Expanded(child: Container(height: 20, color: theme.splashColor))]),
                  )),
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: theme.cardColor)),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 20, width: 150, color: theme.cardColor, margin: const EdgeInsets.only(bottom: 8)),
          Container(height: 1, color: theme.dividerColor, margin: const EdgeInsets.only(bottom: 16)),
          Container(height: 200, width: double.infinity, color: theme.cardColor),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message, bool isDarkMode) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 70),
            const SizedBox(height: 20),
            Text('Oops! Something Went Wrong', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onErrorContainer)),
            const SizedBox(height: 10),
            Text(message, style: TextStyle(fontSize: 16, color: theme.hintColor), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              onPressed: () {
                final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
                if (currentHouseholdState is CurrentHouseholdSet && currentHouseholdState.household.id != null) {
                  context.read<StatisticsBloc>().add(LoadStatistics(householdId: currentHouseholdState.household.id.toString()));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: baseMediumBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDottedDivider(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: List.generate(
          MediaQuery.of(context).size.width ~/ 5,
          (index) => Expanded(
            child: Container(
              height: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsContent(BuildContext context, StatisticsLoaded state, bool isDarkMode) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '₪', decimalDigits: 0);

    String topCostItemName = "N/A";
    double topCostItemValue = 0;
    if (state.topExpensiveItems.isNotEmpty) {
      topCostItemName = state.topExpensiveItems.first['item_name'] ?? "N/A";
      topCostItemValue = _parseNum(state.topExpensiveItems.first['total_purchase_price']);
    }
    
    bool noMonthlyData = state.totalMoneySpent == 0 && state.topExpensiveItems.isEmpty;
    bool noQuantityData = state.topPurchasedItems.isEmpty;
    bool noCostData = state.topExpensiveItems.isEmpty;

    Color iconBgColor = isDarkMode 
    ? baseMediumBlue.withOpacity(0.2) 
    : baseMediumBlue.withOpacity(0.1);
    Color iconFgColor = baseMediumBlue;

    return RefreshIndicator(
      onRefresh: () async {
        final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
        if (currentHouseholdState is CurrentHouseholdSet && currentHouseholdState.household.id != null) {
          context.read<StatisticsBloc>().add(LoadStatistics(householdId: currentHouseholdState.household.id.toString()));
        }
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          Text('Cost Statistics', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          _buildDottedDivider(context),
          const SizedBox(height: 12),
          if (noMonthlyData)
            _buildEmptySectionPlaceholder(context,"No monthly cost data available yet.")
          else
            Container(
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? baseMediumBlue.withOpacity(0.08) 
                    : baseMediumBlue.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.attach_money, color: iconFgColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Money Spent',
                              style: TextStyle(
                                fontSize: 13, 
                                color: theme.hintColor,
                                fontWeight: FontWeight.w500
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(state.totalMoneySpent),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onBackground,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 1,
                    color: theme.dividerColor.withOpacity(0.3),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.star, color: iconFgColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mostly Spent On',
                                style: TextStyle(
                                  fontSize: 13, 
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$topCostItemName ${currencyFormat.format(topCostItemValue)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onBackground,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 30),
          Text('Stock Statistics', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          _buildDottedDivider(context),
          const SizedBox(height: 16),
          Text('Top Frequent Items', style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 16),
          if (noQuantityData)
            _buildEmptySectionPlaceholder(context, "No item purchase quantity data available yet.")
          else
            _buildTopItemsBarChart(context, state.topPurchasedItems, isDarkMode),
          
          // New section for Top Costing Items
          const SizedBox(height: 30),
          Text('Top Costing Items', style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 16),
          if (noCostData)
            _buildEmptySectionPlaceholder(context, "No cost data available yet.")
          else
            _buildTopCostingItemsBarChart(context, state.topExpensiveItems, isDarkMode, currencyFormat),
        ],
      ),
    );
  }
  
  Widget _buildTopCostingItemsBarChart(BuildContext context, List<Map<String, dynamic>> items, bool isDarkMode, NumberFormat currencyFormat) {
    final theme = Theme.of(context);
    final chartItems = items.take(4).toList();
    // Use different colors from the purchase quantity chart to visually distinguish them
    final List<Color> barColors = [
        Colors.teal[300]!, 
        Colors.amber[400]!, 
        Colors.indigo[300]!,
        Colors.deepOrange[300]!
    ].map((c) => isDarkMode ? c.withOpacity(0.85) : c).toList(); 
    
    final List<String> itemLetters = ['a', 'b', 'c', 'd'];

    if (chartItems.isEmpty) {
      return SizedBox(height: 250, child: Center(child: Text("No cost data available yet.", style: TextStyle(color: theme.hintColor))));
    }

    double maxYValue = 0;
    if (chartItems.isNotEmpty) {
      maxYValue = chartItems.map((e) => _parseNum(e['total_purchase_price'])).reduce(math.max);
    }
    if (maxYValue == 0) maxYValue = 10;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxYValue * 1.35,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 25,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= chartItems.length) return const SizedBox.shrink();
                      // Display the purchase price instead of letter
                      final val = _parseNum(chartItems[index]['total_purchase_price']);
                      return Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Text(
                          currencyFormat.format(val), // Use currency format for cost values
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
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
                      color: barColors[index % barColors.length],
                      width: 28,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildCostingItemsLegend(context, chartItems, barColors, itemLetters, theme),
      ],
    );
  }

  Widget _buildCostingItemsLegend(BuildContext context, List<Map<String, dynamic>> items, List<Color> colors, List<String> letters, ThemeData theme) {
    return Wrap(
      spacing: 20.0,
      runSpacing: 10.0,
      alignment: WrapAlignment.start,
      children: items.asMap().entries.map((entry) {
        final int index = entry.key;
        final item = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(item['item_name'] ?? 'N/A', style: TextStyle(fontSize: 13, color: theme.colorScheme.onBackground)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEmptySectionPlaceholder(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30.0),
      alignment: Alignment.center,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15, color: theme.hintColor),
      ),
    );
  }

  Widget _buildCostRowItem({
    required IconData icon,
    required String title,
    required String value,
    required Color iconBgColor,
    required Color iconFgColor,
    required ThemeData theme,
    bool isMonetaryValue = true,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconFgColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12.5, color: theme.hintColor)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMonetaryValue ? 18 : 15,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopItemsBarChart(BuildContext context, List<Map<String, dynamic>> items, bool isDarkMode) {
    final theme = Theme.of(context);
    final chartItems = items.take(4).toList();
    final List<Color> barColors = [
        baseBarColorCoral, baseBarColorYellow, baseBarColorPurpleAccent, baseBarColorBlue
    ].map((c) => isDarkMode ? c.withOpacity(0.85) : c).toList(); // Slightly adjust for dark mode
    
    final List<String> itemLetters = ['a', 'b', 'c', 'd'];

    if (chartItems.isEmpty) {
      return SizedBox(height: 250, child: Center(child: Text("No item purchase data yet.", style: TextStyle(color: theme.hintColor))));
    }

    double maxYValue = 0;
    if (chartItems.isNotEmpty) {
      maxYValue = chartItems.map((e) => _parseNum(e['purchase_counter'])).reduce(math.max);
    }
    if (maxYValue == 0) maxYValue = 10;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxYValue * 1.35,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 25,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= chartItems.length) return const SizedBox.shrink();
                      // Display the purchase counter value instead of letter
                      final val = _parseNum(chartItems[index]['purchase_counter']).toInt();
                      return Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Text(
                          val.toString(),
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
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
                      color: barColors[index % barColors.length],
                      width: 28,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildBarChartLegend(context, chartItems, barColors, itemLetters, theme),
      ],
    );
  }

  Widget _buildBarChartLegend(BuildContext context, List<Map<String, dynamic>> items, List<Color> colors, List<String> letters, ThemeData theme) {
    return Wrap(
      spacing: 20.0,
      runSpacing: 10.0,
      alignment: WrapAlignment.start,
      children: items.asMap().entries.map((entry) {
        final int index = entry.key;
        final item = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(item['item_name'] ?? 'N/A', style: TextStyle(fontSize: 13, color: theme.colorScheme.onBackground)),
          ],
        );
      }).toList(),
    );
  }

  double _parseNum(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}