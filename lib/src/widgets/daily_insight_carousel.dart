import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/insight.dart';
import '../state/aura_scope.dart';
import '../services/insight_service.dart';
import '../state/aura_controller.dart';
import '../services/translation_service.dart';

class DailyInsightCarousel extends StatefulWidget {
  const DailyInsightCarousel({super.key});

  @override
  State<DailyInsightCarousel> createState() => _DailyInsightCarouselState();
}

class _DailyInsightCarouselState extends State<DailyInsightCarousel> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AuraScope.of(context);
    final insights = InsightService.generateInsights(controller, controller.languageCode);

    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: insights.length,
            itemBuilder: (context, index) {
              return _buildInsightCard(context, insights[index]);
            },
          ),
        ),
        if (insights.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                insights.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  height: 6,
                  width: _currentPage == index ? 16 : 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInsightCard(BuildContext context, DailyInsight insight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            insight.color.withOpacity(isDark ? 0.4 : 0.2),
            insight.color.withOpacity(isDark ? 0.1 : 0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: insight.color.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.1 : 0.4),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: insight.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    insight.icon,
                    color: insight.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        insight.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        insight.message,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
