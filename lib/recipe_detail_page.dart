import 'dart:ui';

import 'package:flutter/material.dart';

class RecipeDetailPage extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailPage({Key? key, required this.recipe}) : super(key: key);

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage>
    with SingleTickerProviderStateMixin {
  int personCount = 2;
  late TabController _tabController;

  // Modified values for better positioning
  double initialChildSize = 0.6; // Increased from 0.5 to move sheet upward
  double minChildSize =
      0.5; // Increased from 0.35 to prevent going too far down
  double maxChildSize = 0.95;

  // Controller to manage the DraggableScrollableSheet's position
  DraggableScrollableController dragController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    dragController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(widget.recipe['image']),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.2),
                  BlendMode.darken,
                ),
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back, color: Color(0xFFF85C50)),
                ),
              ),
            ),
          ),

          // Recipe Title and Info on image
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.recipe['type'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.recipe['area'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.recipe['title'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.recipe['readyInMinutes']} Min',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.whatshot, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.recipe['calories']} Cal',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star,
                          color: i < (widget.recipe['rating'] as double).floor()
                              ? Colors.amber
                              : Colors.grey.shade300,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Draggable recipe details panel with controller
          DraggableScrollableSheet(
            initialChildSize: initialChildSize,
            minChildSize: minChildSize,
            maxChildSize: maxChildSize,
            controller: dragController,
            snap: true,
            snapSizes: [initialChildSize],
            builder: (context, scrollController) {
              return AnimatedBuilder(
                animation: scrollController,
                builder: (context, child) {
                  final percentage = (scrollController.hasClients)
                      ? ((scrollController.position.viewportDimension /
                                  MediaQuery.of(context).size.height) -
                              minChildSize) /
                          (maxChildSize - minChildSize)
                      : 0.0;

                  // Smoothly interpolate corner radius based on scroll position
                  final cornerRadius =
                      30.0 * (1.0 - percentage.clamp(0.0, 1.0));

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(cornerRadius),
                        topRight: Radius.circular(cornerRadius),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Column(
                  children: [
                    // Drag handle
                    GestureDetector(
                      onTap: () {
                        // Reset to initial position when tapping the drag handle
                        dragController.animateTo(
                          initialChildSize,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 16),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Serving selector
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Serving',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              _buildServingButton(Icons.remove, () {
                                if (personCount > 1) {
                                  setState(() {
                                    personCount--;
                                  });
                                }
                              }),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF85C50),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$personCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildServingButton(Icons.add, () {
                                if (personCount < 10) {
                                  setState(() {
                                    personCount++;
                                  });
                                }
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tab bar
                    TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFFF85C50),
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: 'Ingredients'),
                        Tab(text: 'Steps'),
                        Tab(text: 'Nutrition'),
                      ],
                    ),

                    // Tab content with proper padding at the bottom
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Ingredients Tab with bottom padding
                          _buildIngredientsTab(scrollController),

                          // Steps Tab with bottom padding
                          _buildStepsTab(scrollController),

                          // Nutrition Tab with bottom padding
                          _buildNutritionTab(scrollController),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Bottom button for favorite
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildServingButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFFF85C50)),
      ),
    );
  }

  Widget _buildIngredientsTab(ScrollController scrollController) {
    final ingredients = widget.recipe['ingredients'] as List<dynamic>;
    final measures = widget.recipe['measures'] as List<dynamic>;

    if (ingredients.isEmpty) {
      return const Center(
        child: Text('No ingredients available for this recipe.'),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
          16, 16, 16, 80), // Add bottom padding to avoid cutoff
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = ingredients[index];
        final measure = measures[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant, color: Color(0xFFF85C50)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      measure,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: true,
                activeColor: const Color(0xFFF85C50),
                onChanged: (value) {},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepsTab(ScrollController scrollController) {
    final instructions = widget.recipe['instructions'] as String;
    final steps = instructions
        .split('\r\n')
        .where((step) => step.trim().isNotEmpty)
        .toList();

    if (steps.isEmpty) {
      return const Center(
        child: Text('No instructions available for this recipe.'),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
          16, 16, 16, 80), // Add bottom padding to avoid cutoff
      itemCount: steps.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFF85C50),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  steps[index],
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNutritionTab(ScrollController scrollController) {
    // Placeholder nutrition data
    final nutritionData = [
      {
        'name': 'Calories',
        'value': '${widget.recipe['calories']} cal',
        'percent': 0.8
      },
      {
        'name': 'Protein',
        'value': '${(widget.recipe['calories'] / 10).round()} g',
        'percent': 0.6
      },
      {
        'name': 'Carbs',
        'value': '${(widget.recipe['calories'] / 8).round()} g',
        'percent': 0.75
      },
      {
        'name': 'Fat',
        'value': '${(widget.recipe['calories'] / 30).round()} g',
        'percent': 0.4
      },
      {
        'name': 'Fiber',
        'value': '${(widget.recipe['calories'] / 50).round()} g',
        'percent': 0.3
      },
    ];

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
          16, 16, 16, 80), // Add bottom padding to avoid cutoff
      itemCount: nutritionData.length,
      itemBuilder: (context, index) {
        final item = nutritionData[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['name'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    item['value'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFFF85C50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: item['percent'] as double,
                  backgroundColor: Colors.grey.shade200,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFFF85C50)),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomButton() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Recipe added to favorites!'),
                backgroundColor: Color(0xFFF85C50),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF85C50),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Add to Favorites',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
