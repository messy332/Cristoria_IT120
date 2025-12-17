import 'package:flutter/material.dart';

class CoffeeCupGalleryPage extends StatelessWidget {
  const CoffeeCupGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cupVarieties = [
      'Turkish Coffee Cup',
      'Japanese Matcha Chawan',
      'Vietnam Egg Coffee Cup',
      'Espresso Demitasse Cup',
      'Double-Walled Insulated Mug',
      'Reusable Stainless Steel Travel Cup',
      'Cappuccino Cup(Italian Style)',
      'Latte Glass(Irish Coffee Style)',
      'Yixing Clay Coffee Cup',
      'Ceramic Pour-Over Coffee Mug',
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Coffee Cup Varieties',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cupVarieties.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6F4E37),
                      const Color(0xFFA67B5B),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              title: Text(
                cupVarieties[index],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.brown.shade400,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CoffeeCupDetailPage(
                      cupName: cupVarieties[index],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class CoffeeCupDetailPage extends StatelessWidget {
  final String cupName;

  const CoffeeCupDetailPage({
    super.key,
    required this.cupName,
  });

  @override
  Widget build(BuildContext context) {
    final cupInfo = _getCupInfo(cupName);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          cupName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.brown.shade50,
                      Colors.orange.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    _getImagePath(cupName),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.coffee,
                          size: 80,
                          color: Colors.brown.shade400,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              cupName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6F4E37),
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoSection('Origin', cupInfo['origin']!),
            const SizedBox(height: 16),
            _buildInfoSection('Description', cupInfo['description']!),
            const SizedBox(height: 16),
            _buildInfoSection('Typical Use', cupInfo['use']!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F4E37).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    title == 'Origin'
                        ? Icons.public
                        : title == 'Description'
                            ? Icons.description
                            : Icons.coffee_maker,
                    color: const Color(0xFF6F4E37),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6F4E37),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getImagePath(String cupName) {
    final imageMap = {
      'Turkish Coffee Cup': 'assets/cups/turkish_coffee.png',
      'Japanese Matcha Chawan': 'assets/cups/japanese_matcha.png',
      'Vietnam Egg Coffee Cup': 'assets/cups/vietnam_egg.png',
      'Espresso Demitasse Cup': 'assets/cups/espresso_demitasse.png',
      'Double-Walled Insulated Mug': 'assets/cups/double_walled.png',
      'Reusable Stainless Steel Travel Cup': 'assets/cups/stainless_travel.png',
      'Cappuccino Cup(Italian Style)': 'assets/cups/cappucino.png',
      'Latte Glass(Irish Coffee Style)': 'assets/cups/latte_glass.png',
      'Yixing Clay Coffee Cup': 'assets/cups/yixing_clay.png',
      'Ceramic Pour-Over Coffee Mug': 'assets/cups/ceramic_pourover.png',
    };
    return imageMap[cupName] ?? 'assets/coffee.png';
  }

  Map<String, String> _getCupInfo(String cupName) {
    final cupData = {
      'Turkish Coffee Cup': {
        'origin': 'Turkey',
        'description': 'Small, handleless cup traditionally used for serving Turkish coffee. Often ornately decorated with traditional patterns.',
        'use': 'Serving strong, unfiltered Turkish coffee with grounds settled at the bottom.',
      },
      'Japanese Matcha Chawan': {
        'origin': 'Japan',
        'description': 'Wide, bowl-shaped ceramic cup used in traditional Japanese tea ceremonies. Features a rustic, handcrafted aesthetic.',
        'use': 'Preparing and drinking matcha tea in traditional tea ceremonies.',
      },
      'Vietnam Egg Coffee Cup': {
        'origin': 'Vietnam',
        'description': 'Small glass cup designed to showcase the layers of Vietnamese egg coffee, with its creamy egg foam topping.',
        'use': 'Serving Vietnamese egg coffee (cà phê trứng) to display its distinctive layers.',
      },
      'Espresso Demitasse Cup': {
        'origin': 'Italy',
        'description': 'Small, thick-walled porcelain cup (2-3 oz) designed to retain heat and concentrate the espresso aroma.',
        'use': 'Serving single or double shots of espresso.',
      },
      'Double-Walled Insulated Mug': {
        'origin': 'Modern/International',
        'description': 'Contemporary design with double-wall glass or stainless steel construction that keeps beverages hot while the exterior stays cool.',
        'use': 'Keeping coffee hot for extended periods while preventing burns.',
      },
      'Reusable Stainless Steel Travel Cup': {
        'origin': 'Modern/International',
        'description': 'Durable, insulated travel mug with secure lid, designed for on-the-go coffee consumption.',
        'use': 'Portable coffee drinking, commuting, and reducing single-use cup waste.',
      },
      'Cappuccino Cup(Italian Style)': {
        'origin': 'Italy',
        'description': 'Wide-brimmed porcelain cup (5-6 oz) with a saucer, designed to showcase latte art and accommodate foam.',
        'use': 'Serving cappuccinos with the perfect ratio of espresso, steamed milk, and foam.',
      },
      'Latte Glass(Irish Coffee Style)': {
        'origin': 'Ireland/International',
        'description': 'Tall, clear glass with a handle, allowing the layers of coffee and milk to be visible.',
        'use': 'Serving lattes, Irish coffee, and other layered coffee drinks.',
      },
      'Yixing Clay Coffee Cup': {
        'origin': 'China',
        'description': 'Unglazed clay cup from Yixing, known for its porous nature that absorbs flavors over time, enhancing the drinking experience.',
        'use': 'Serving coffee or tea, with the clay developing a unique patina and flavor profile.',
      },
      'Ceramic Pour-Over Coffee Mug': {
        'origin': 'Modern/International',
        'description': 'Large ceramic mug designed for pour-over coffee brewing, often with a wide opening for optimal extraction.',
        'use': 'Brewing and drinking pour-over coffee directly in the same vessel.',
      },
    };

    return cupData[cupName] ?? {
      'origin': 'Unknown',
      'description': 'Information not available for this coffee cup variety.',
      'use': 'General coffee drinking.',
    };
  }
}
