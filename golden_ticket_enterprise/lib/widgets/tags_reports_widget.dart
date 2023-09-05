import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/entities/ticket.dart';
import 'package:intl/intl.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';

class TagsTab extends StatefulWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final DataManager dataManager;
  final Function(DateTime) onFromDateChanged;
  final Function(DateTime) onToDateChanged;
  final VoidCallback onRefresh;
  final double scrollPosition;
  final double visibleRange;
  final Function(double) onScrollChanged;
  final List tickets;
  final List<LineColor> lineColor;

  const TagsTab({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.dataManager,
    required this.lineColor,
    required this.onFromDateChanged,
    required this.onToDateChanged,
    required this.onRefresh,
    required this.scrollPosition,
    required this.visibleRange,
    required this.onScrollChanged,
    required this.tickets,
  });

  @override
  State<TagsTab> createState() => _TagsTabState();
}

class _TagsTabState extends State<TagsTab> {
  String? selectedMainTag = "All";
  List<String> listedTags = [];

  @override
  void initState(){
    super.initState();
  }
  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required Function(DateTime)? onPick,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2022, 1, 1),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPick!(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 8),
            Text(
              "$label: ${DateFormat('MMMM d, yyyy').format(date)}",
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }


  LineChartBarData _buildLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: color,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
      barWidth: 3,
    );
  }

  List<FlSpot> _filterSpots(List<FlSpot> spots) {
    return spots.where((spot) {
      return spot.x >= widget.scrollPosition &&
          spot.x < widget.scrollPosition + widget.visibleRange;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTickets = widget.tickets.where((t) {

      final created = t.createdAt;
      final tagMatch = selectedMainTag == 'All' || t.mainTag?.tagName == selectedMainTag;


      return created != null && tagMatch &&
          !created.isBefore(widget.fromDate) &&
          !created.isAfter(widget.toDate);
    });

    listedTags = [];
    filteredTickets.forEach((t) {
      if(!listedTags.contains(t.mainTag?.tagName)){
        listedTags.add(t.mainTag?.tagName ?? 'Not assigned');
      }
    });
    final Map<String, Map<String, int>> monthlyReports = {};

    DateTime current = DateTime(widget.fromDate.year, widget.fromDate.month);
    final end = DateTime(widget.toDate.year, widget.toDate.month);
    final dateFormatter =
    DateFormat(widget.fromDate.year != widget.toDate.year ? 'MMM yyyy' : 'MMM');

    while (!current.isAfter(end)) {
      final monthName = dateFormatter.format(current);
      monthlyReports[monthName] = {
        if(selectedMainTag != 'All')
          for (var tag in listedTags)
            tag: 0
        else
          for (var tag in widget.dataManager.mainTags)
            tag.tagName: 0,
        if(selectedMainTag == 'All') 'Not assigned': 0,
      };
      current = DateTime(current.year, current.month + 1);
      if (current.month > 12) current = DateTime(current.year + 1, 1);
    }

    for (Ticket ticket in filteredTickets) {
      final created = ticket.createdAt;
      final month = dateFormatter.format(created);
      String mainTag = ticket.mainTag != null ?  ticket.mainTag!.tagName : 'Not assigned';
      if (monthlyReports.containsKey(month)) {
        monthlyReports[month]![mainTag] =
            monthlyReports[month]![mainTag]! + 1;
      }
    }

    List<String> sortedMonths = monthlyReports.keys.toList();
    sortedMonths.sort((a, b) {
      final aDate = DateTime.parse(dateFormatter.parse(a).toString());
      final bDate = DateTime.parse(dateFormatter.parse(b).toString());
      return aDate.compareTo(bDate);
    });

    Map<String, List<FlSpot>> tagSpots = {
      if(selectedMainTag != 'All')
        for (var tag in listedTags)
          tag: []
      else
        for (var tag in widget.dataManager.mainTags)
          tag.tagName: [],
      if(selectedMainTag == 'All') 'Not assigned': [],
    };
    for (int i = 0; i < sortedMonths.length; i++) {
      final month = sortedMonths[i];
      monthlyReports[month]!.forEach((item, quantity) {
        tagSpots[item]!.add(FlSpot(i.toDouble(), quantity.toDouble()));
      });

      // tagSpots['Low']!.add(FlSpot(i.toDouble(), low.toDouble()));
      // tagSpots['Medium']!.add(FlSpot(i.toDouble(), medium.toDouble()));
      // tagSpots['High']!.add(FlSpot(i.toDouble(), high.toDouble()));
    }
    double minY = 0;
    double maxY = 0;
    if (filteredTickets.isNotEmpty){
      minY = monthlyReports.values.expand((e) => e.values).reduce((a, b) => a < b ? a : b) - 1;
      maxY = monthlyReports.values.expand((e) => e.values).reduce((a, b) => a > b ? a : b) + 3;
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 600;
              final content = [
                Flexible(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: DropdownButtonFormField<String>(
                      value: selectedMainTag,
                      hint: Text("Main Tag"),
                      items: ["All", ...widget.dataManager.mainTags.map((tag) => tag.tagName)].map((tag) {
                        return DropdownMenuItem(
                          value: tag,
                          child: Text(tag),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedMainTag = value;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: _buildDateButton(
                      label: "From",
                      date: widget.fromDate,
                      onPick: widget.onFromDateChanged,
                    ),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: _buildDateButton(
                      label: "To",
                      date: widget.toDate,
                      onPick: widget.onToDateChanged,
                    ),
                  ),
                ),
              ];

              return isMobile
                  ? IntrinsicHeight( // Ensures proper sizing vertically
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: content,
                ),
              )
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: content,
              );
            },
          ),
          if (filteredTickets.isEmpty)
           Center(
              child: Text('No data available for the selected date range.')
           )
          else const SizedBox(height: 20),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minY: minY,
                      maxY: maxY,
                      lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              getTooltipItems: (List<LineBarSpot> touchedSpots){
                                return touchedSpots.map((spot) {
                                  LineColor lineData = widget.lineColor.firstWhere((line) => line.color == spot.bar.color);
                                  return LineTooltipItem('${lineData.name}: ${spot.y.toInt()}', TextStyle(color: lineData.color));
                                }).toList();
                              }
                          )
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                              getTitlesWidget: (value, _) {
                                final index = value.toInt();

                                // Edge case: prevent label if too close to end
                                if (index < 0 || index >= sortedMonths.length) return const SizedBox.shrink();

                                if ((value - index).abs() > 0.05) return const SizedBox.shrink(); // Fractional = ignore

                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    sortedMonths[index],
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      lineBarsData: [
                        for(var spot in tagSpots.keys)
                          _buildLine(_filterSpots(tagSpots[spot]!), widget.lineColor.firstWhere((line) => line.name == spot).color),
                      ],
                      borderData: FlBorderData(show: true),
                      gridData: FlGridData(show: true),
                    ),
                  ),
                ),
                if (sortedMonths.length > widget.visibleRange)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Slider(
                      value: widget.scrollPosition,
                      min: 0,
                      max: (sortedMonths.length - widget.visibleRange).toDouble(),
                      divisions: (sortedMonths.length - widget.visibleRange).toInt(),
                      label: 'Scroll',
                      thumbColor: kPrimary,
                      activeColor: kPrimary,
                      inactiveColor: kPrimaryContainer,
                      onChanged: widget.onScrollChanged,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
