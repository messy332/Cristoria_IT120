import 'package:flutter/material.dart';

class CoffeeCupInfo {
  final String name;
  final String description;
  final String imagePath;
  final List<String> characteristics;
  final String origin;

  CoffeeCupInfo({
    required this.name,
    required this.description,
    required this.imagePath,
    required this.characteristics,
    required this.origin,
  });
}

class CoffeeCupDatabase {
  static final List<CoffeeCupInfo> coffeeCups = [
    CoffeeCupInfo(
      name: '0 Turkish Coff...',
      description: 'Traditional Turkish coffee cups are small, delicate porcelain cups designed to serve strong, unfiltered Turkish coffee. These elegant cups typically hold 2-3 ounces and are often ornately decorated with intricate patterns and gold trim.',
      imagePath: 'assets/cups/turkish_coffee.png',
      characteristics: [
        'Small size (2-3 oz capacity)',
        'Porcelain or ceramic material',
        'Ornate decorative patterns',
        'Often includes matching saucer',
        'No handle or small decorative handle',
      ],
      origin: 'Turkey, Ottoman Empire',
    ),
    CoffeeCupInfo(
      name: '1 Japanese Mat...',
      description: 'Japanese Matcha cups (chawan) are wide, bowl-shaped vessels traditionally used in Japanese tea ceremonies. These handcrafted cups are designed to allow proper whisking of matcha powder and appreciation of the tea\'s color and aroma.',
      imagePath: 'assets/cups/matcha_cup.png',
      characteristics: [
        'Wide bowl shape',
        'Ceramic or stoneware',
        'Rustic, handcrafted appearance',
        'Thick walls for heat retention',
        'Often features natural glazes',
      ],
      origin: 'Japan',
    ),
    CoffeeCupInfo(
      name: '2 Vietnam Egg ...',
      description: 'Vietnamese Egg Coffee cups are small glass cups specifically designed to showcase the layered appearance of this unique coffee drink. The transparent glass allows you to see the rich egg cream floating on top of strong Vietnamese coffee.',
      imagePath: 'assets/cups/vietnam_egg.png',
      characteristics: [
        'Clear glass construction',
        'Small to medium size',
        'Heat-resistant glass',
        'Shows layered coffee presentation',
        'Often served with small spoon',
      ],
      origin: 'Vietnam, Hanoi',
    ),
    CoffeeCupInfo(
      name: '3 Espresso Dem...',
      description: 'Espresso Demitasse cups are small, thick-walled cups designed to maintain the temperature and crema of espresso shots. These professional-grade cups typically hold 2-3 ounces and are essential for proper espresso service.',
      imagePath: 'assets/cups/espresso_demitasse.png',
      characteristics: [
        'Small capacity (2-3 oz)',
        'Thick ceramic walls',
        'Narrow opening preserves crema',
        'Professional coffee shop standard',
        'Often white or colored porcelain',
      ],
      origin: 'Italy',
    ),
    CoffeeCupInfo(
      name: '4 Double-Walle...',
      description: 'Double-walled glass cups feature two layers of glass with an air gap between them, providing excellent insulation. These modern cups keep beverages hot while remaining cool to touch, and showcase the beautiful colors of your coffee.',
      imagePath: 'assets/cups/double_walled.png',
      characteristics: [
        'Two layers of glass',
        'Excellent heat insulation',
        'Cool exterior surface',
        'Transparent design',
        'Modern aesthetic',
      ],
      origin: 'Modern design',
    ),
    CoffeeCupInfo(
      name: '5 Reusable Sta...',
      description: 'Reusable stainless steel cups are eco-friendly, durable travel mugs designed for on-the-go coffee consumption. These cups feature excellent insulation, leak-proof lids, and are built to last for years while reducing single-use cup waste.',
      imagePath: 'assets/cups/stainless_steel.png',
      characteristics: [
        'Stainless steel construction',
        'Vacuum insulation',
        'Leak-proof lid',
        'Eco-friendly and reusable',
        'Keeps drinks hot for hours',
      ],
      origin: 'Modern sustainable design',
    ),
    CoffeeCupInfo(
      name: '6 Cappucino Cu...',
      description: 'Cappuccino cups are wide, bowl-shaped cups designed to accommodate the perfect ratio of espresso, steamed milk, and foam. The wide opening allows for latte art and proper foam distribution, typically holding 5-6 ounces.',
      imagePath: 'assets/cups/cappuccino.png',
      characteristics: [
        'Wide bowl shape',
        'Medium size (5-6 oz)',
        'Thick ceramic walls',
        'Perfect for latte art',
        'Often includes matching saucer',
      ],
      origin: 'Italy',
    ),
    CoffeeCupInfo(
      name: '7 Latte Glass(...',
      description: 'Latte glasses are tall, transparent glasses designed to showcase the beautiful layers of a latte. These heat-resistant glasses typically hold 8-12 ounces and feature a handle for comfortable holding while displaying the coffee\'s aesthetic appeal.',
      imagePath: 'assets/cups/latte_glass.png',
      characteristics: [
        'Tall transparent glass',
        'Heat-resistant material',
        'Shows layered presentation',
        'Handle for comfort',
        'Large capacity (8-12 oz)',
      ],
      origin: 'European café culture',
    ),
    CoffeeCupInfo(
      name: '8 Yixing Clay ...',
      description: 'Yixing clay cups are traditional Chinese teaware made from special purple clay found in Yixing, China. These unglazed cups are prized for their ability to absorb tea flavors over time, enhancing the drinking experience with each use.',
      imagePath: 'assets/cups/yixing_clay.png',
      characteristics: [
        'Unglazed purple clay',
        'Porous material',
        'Absorbs beverage flavors',
        'Handcrafted artisan pieces',
        'Improves with age and use',
      ],
      origin: 'Yixing, China',
    ),
    CoffeeCupInfo(
      name: '9 Ceramic Pour...',
      description: 'Ceramic pour-over cups are specially designed vessels that sit atop coffee servers during the pour-over brewing process. These cups feature a conical shape with ridges and a large opening at the bottom for optimal coffee extraction.',
      imagePath: 'assets/cups/ceramic_pourover.png',
      characteristics: [
        'Conical dripper shape',
        'Ceramic construction',
        'Internal ridges for flow',
        'Large bottom opening',
        'Used for brewing, not drinking',
      ],
      origin: 'Japan (Hario V60 style)',
    ),
  ];

  static CoffeeCupInfo? getCupByName(String name) {
    try {
      return coffeeCups.firstWhere(
        (cup) => cup.name.toLowerCase().contains(name.toLowerCase()) ||
                 name.toLowerCase().contains(cup.name.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }
}

class CoffeeCupDetailPage extends StatelessWidget {
  final String cupName;

  const CoffeeCupDetailPage({super.key, required this.cupName});

  @override
  Widget build(BuildContext context) {
    final cupInfo = CoffeeCupDatabase.getCupByName(cupName);

    if (cupInfo == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cup Information'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Text('Cup information not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(cupInfo.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cup Image
            Container(
              height: 300,
              color: Colors.grey.shade100,
              child: Image.asset(
                cupInfo.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.brown.shade50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.coffee,
                          size: 100,
                          color: Colors.brown.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Image Coming Soon',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.brown.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Cup Information
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Origin Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.brown.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cupInfo.origin,
                          style: TextStyle(
                            color: Colors.brown.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cup Name
                  Text(
                    cupInfo.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade800,
                        ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    cupInfo.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Characteristics Section
                  Text(
                    'Key Characteristics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade800,
                        ),
                  ),

                  const SizedBox(height: 12),

                  // Characteristics List
                  ...cupInfo.characteristics.map((characteristic) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.brown.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              characteristic,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Use the scanner to identify this cup variety in real images!',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 14,
                            ),
                          ),
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
    );
  }
}

class CoffeeCupGalleryPage extends StatelessWidget {
  const CoffeeCupGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('☕ Coffee Cup Varieties'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: CoffeeCupDatabase.coffeeCups.length,
        itemBuilder: (context, index) {
          final cup = CoffeeCupDatabase.coffeeCups[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CoffeeCupDetailPage(cupName: cup.name),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Cup Icon/Image
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.brown.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.coffee,
                        size: 40,
                        color: Colors.brown,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Cup Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cup.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cup.origin,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cup.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}