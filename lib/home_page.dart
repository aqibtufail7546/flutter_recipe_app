import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_food_recipe_api/recipe_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> featuredRecipes = [];
  List<Map<String, dynamic>> recipes = [];
  bool isLoading = true;
  String currentCategory = 'Chicken';
  List<Map<String, dynamic>> categories = [
    {'name': 'Chicken', 'icon': Icons.restaurant, 'selected': true},
    {'name': 'Beef', 'icon': Icons.set_meal, 'selected': false},
    {'name': 'Seafood', 'icon': Icons.water, 'selected': false},
    {'name': 'Vegetarian', 'icon': Icons.eco, 'selected': false},
    {'name': 'Dessert', 'icon': Icons.cake, 'selected': false},
  ];

  @override
  void initState() {
    super.initState();
    fetchRecipes(currentCategory);
  }

  Future<void> fetchRecipes(String category) async {
    setState(() {
      isLoading = true;
      currentCategory = category;

      // Update selected category
      for (var c in categories) {
        c['selected'] = c['name'] == category;
      }
    });

    final url =
        'https://www.themealdb.com/api/json/v1/1/filter.php?c=$category';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final mealsData = data['meals'];

        if (mealsData != null) {
          final List<Map<String, dynamic>> formattedMeals = [];
          final List<Map<String, dynamic>> featuredMeals = [];

          final featuredCount = mealsData.length > 5 ? 5 : mealsData.length;

          for (int i = 0; i < mealsData.length; i++) {
            var meal = mealsData[i];
            final mealDetails = await fetchMealDetails(meal['idMeal']);

            final formattedMeal = {
              'id': meal['idMeal'],
              'title': meal['strMeal'],
              'image': meal['strMealThumb'],
              'readyInMinutes': mealDetails['readyInMinutes'] ?? 30,
              'difficulty': mealDetails['strArea'] == 'American' ||
                      mealDetails['strArea'] == 'British'
                  ? 'Easy lvl'
                  : 'High lvl',
              'type': mealDetails['strCategory'] ?? category,
              'calories': 180 + (i * 20) % 120,
              'rating': 4.0 + (i * 0.2) % 1.0,
              'area': mealDetails['strArea'] ?? 'International',
              'instructions': mealDetails['strInstructions'] ??
                  'No instructions available.',
              'ingredients': mealDetails['ingredients'] ?? [],
              'measures': mealDetails['measures'] ?? [],
            };

            formattedMeals.add(formattedMeal);

            if (i < featuredCount) {
              featuredMeals.add(formattedMeal);
            }
          }

          setState(() {
            featuredRecipes = featuredMeals;
            recipes = formattedMeals;
            isLoading = false;
          });
        } else {
          setState(() {
            featuredRecipes = [];
            recipes = [];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          featuredRecipes = [];
          recipes = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        featuredRecipes = [];
        recipes = [];
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> fetchMealDetails(String mealId) async {
    try {
      final detailUrl =
          'https://www.themealdb.com/api/json/v1/1/lookup.php?i=$mealId';
      final detailResponse = await http.get(Uri.parse(detailUrl));

      if (detailResponse.statusCode == 200) {
        final detailData = jsonDecode(detailResponse.body);
        final mealDetail = detailData['meals']?[0];

        if (mealDetail != null) {
          List<String> ingredients = [];
          List<String> measures = [];

          for (int i = 1; i <= 20; i++) {
            final ingredient = mealDetail['strIngredient$i'];
            final measure = mealDetail['strMeasure$i'];

            if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
              ingredients.add(ingredient);
              measures.add(measure ?? '');
            }
          }

          return {
            'strArea': mealDetail['strArea'],
            'strCategory': mealDetail['strCategory'],
            'strInstructions': mealDetail['strInstructions'],
            'readyInMinutes':
                _estimateCookingTime(mealDetail['strInstructions'] ?? ''),
            'ingredients': ingredients,
            'measures': measures,
          };
        }
      }
    } catch (e) {}

    return {
      'strArea': 'International',
      'strCategory': currentCategory,
      'strInstructions': 'Instructions not available.',
      'readyInMinutes': 30,
      'ingredients': <String>[],
      'measures': <String>[],
    };
  }

  int _estimateCookingTime(String instructions) {
    final length = instructions.length;

    if (length < 300) return 15;
    if (length < 600) return 25;
    if (length < 1000) return 35;
    if (length < 1500) return 45;
    return 60;
  }

  void searchRecipes(String query) async {
    if (query.isEmpty) {
      fetchRecipes(currentCategory);
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = 'https://www.themealdb.com/api/json/v1/1/search.php?s=$query';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final mealsData = data['meals'];

        if (mealsData != null) {
          final List<Map<String, dynamic>> searchResults = [];

          for (var meal in mealsData) {
            final mealDetails = await fetchMealDetails(meal['idMeal']);

            searchResults.add({
              'id': meal['idMeal'],
              'title': meal['strMeal'],
              'image': meal['strMealThumb'],
              'readyInMinutes': mealDetails['readyInMinutes'] ?? 30,
              'difficulty': mealDetails['strArea'] == 'American' ||
                      mealDetails['strArea'] == 'British'
                  ? 'Easy lvl'
                  : 'High lvl',
              'type': mealDetails['strCategory'] ?? currentCategory,
              'calories': 180,
              'rating': 4.5,
              'area': mealDetails['strArea'] ?? 'International',
              'instructions': mealDetails['strInstructions'] ??
                  'No instructions available.',
              'ingredients': mealDetails['ingredients'] ?? [],
              'measures': mealDetails['measures'] ?? [],
            });
          }

          setState(() {
            recipes = searchResults;
            featuredRecipes = searchResults.take(3).toList();
            isLoading = false;
          });
        } else {
          setState(() {
            recipes = [];
            featuredRecipes = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SafeArea(
              child: SingleChildScrollView(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF85C50),
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildSearchBar(),
                      _buildFeaturedRecipe(),
                      _buildCategories(),
                      _buildRecipeGrid(),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu, color: Color(0xFFF85C50)),
              ),
              const SizedBox(width: 16),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                        text: 'Delicious ',
                        style: TextStyle(color: Colors.white)),
                    TextSpan(
                        text: 'Recipes', style: TextStyle(color: Colors.amber)),
                  ],
                ),
              ),
            ],
          ),
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.notifications_none, color: Colors.amber),
              ),
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final searchController = TextEditingController();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search Recipe...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
              onSubmitted: (value) {
                searchRecipes(value);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(15),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF85C50),
              borderRadius: BorderRadius.circular(50),
            ),
            child: GestureDetector(
              onTap: () {
                searchRecipes(searchController.text);
              },
              child: const Icon(Icons.tune, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedRecipe() {
    if (featuredRecipes.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No featured recipes available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: featuredRecipes.length,
            controller: PageController(viewportFraction: 0.9),
            itemBuilder: (context, index) {
              final recipe = featuredRecipes[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeDetailPage(recipe: recipe),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: NetworkImage(recipe['image']),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.6),
                        BlendMode.darken,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${recipe['area']} Special',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe['title'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.timer,
                                        color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${recipe['readyInMinutes']} Min',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.restaurant_menu,
                                          color: Colors.white, size: 12),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      recipe['difficulty'].toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            featuredRecipes.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: index == 0 ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    index == 0 ? const Color(0xFFF85C50) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category['selected'] == true;

              return GestureDetector(
                onTap: () {
                  if (!isSelected) {
                    fetchRecipes(category['name'] as String);
                  }
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF85C50)
                              : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category['icon'] as IconData,
                          color: isSelected ? Colors.white : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeGrid() {
    if (recipes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            'No recipes found',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currentCategory Recipes',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'See All',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: recipes.length > 16 ? 16 : recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailPage(recipe: recipe),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          recipe['image'],
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey[300],
                              child: const Icon(Icons.restaurant),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      recipe['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star,
                          color: i < (recipe['rating'] as double).floor()
                              ? Colors.amber
                              : Colors.grey.shade300,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${recipe['readyInMinutes']} Min',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Container(
                          height: 16,
                          width: 1,
                          color: Colors.grey.shade300,
                        ),
                        Text(
                          recipe['difficulty'].toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                recipe['difficulty'].toString().contains('High')
                                    ? Colors.red
                                    : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', true),
          _buildNavItem(Icons.article_outlined, 'Recipes', false),
          _buildNavItem(Icons.favorite_border, 'Favorites', false),
          _buildNavItem(Icons.person_outline, 'Profile', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF85C50) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFFF85C50) : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
      ],
    );
  }
}
