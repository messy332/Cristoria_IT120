import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget { // Changed from StatelessWidget - StatefulWidget to allow dynamic UI updates
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0; // Track selected BottomNavigationBar tab
  PageController _pageController = PageController(); // Controls main image slider

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update selected tab dynamically
    });
  }

  @override
  void dispose() {
    _pageController.dispose(); // Release memory used by PageController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = 'Agri-Cooperative';

    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hide debug banner
      title: title,
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.montserrat(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), // Custom AppBar font
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: const Color.fromARGB(255, 26, 88, 28), // AppBar color
        ),
        body: SingleChildScrollView( // Enable vertical scrolling for entire content
          child: Column(
            children: [
              // Main image slider
              Container(
                height: 250, // Fixed slider height
                child: Stack(
                  children: [
                    PageView(
                      controller: _pageController, // Allows swipe and programmatic control
                      children: [
                        buildImage('https://www.pvamu.edu/cahs/wp-content/uploads/sites/27/steven-weeks-DUPFowqI6oI-unsplash-1-scaled.jpg',), // Slider images
                        buildImage('https://tse3.mm.bing.net/th/id/OIP.sqR2e-cqDG04-7pHuh9EbQHaFj?rs=1&pid=ImgDetMain&o=7&rm=3'),
                        buildImage('https://socialstudieshelp.com/wp-content/uploads/2023/09/Agriculture-scaled.jpeg'),
                        buildImage('https://thumbs.dreamstime.com/b/farmers-working-rice-field-alappuzha-india-march-unidentified-beauty-asia-157502390.jpg'),
                      ],
                    ),
                    // Left arrow button for previous image
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_left, size: 70, color: Colors.white70),
                        onPressed: () => _pageController.previousPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut), // Navigate to previous image
                      ),
                    ),
                    // Right arrow button for next image
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(Icons.arrow_right, size: 70, color: Colors.white70),
                        onPressed: () => _pageController.nextPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut), // Navigate to next image
                      ),
                    ),
                  ],
                ),
              ),

              // About Us section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("About Us",
                        style: GoogleFonts.montserrat(
                            fontSize: 24, fontWeight: FontWeight.w900)), // Section title
                    SizedBox(height: 8),
                    Text(
                      "We are a farmer-led cooperative that promotes sustainable agriculture, supports local farmers, and strengthens community food security.",
                      style: GoogleFonts.montserrat(
                          fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[800]), // Section content
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Farmer image slider row 1
              Container(
                height: 100, // Fixed row height
                child: ListView(
                  scrollDirection: Axis.horizontal, // Horizontal scrolling
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    buildFarmerImage('https://tse1.mm.bing.net/th/id/OIP.yettwqxaNAQfz-J0DiKimwHaEK?rs=1&pid=ImgDetMain&o=7&rm=3'), // Farmer images
                    buildFarmerImage('https://tse3.mm.bing.net/th/id/OIP.pz7JS_OvD5wH40tGHiuz4wHaE8?w=2560&h=1707&rs=1&pid=ImgDetMain&o=7&rm=3'),
                    buildFarmerImage('https://tse4.mm.bing.net/th/id/OIP.oC6-52HxuhcNHYUUdM9wRwHaE6?rs=1&pid=ImgDetMain&o=7&rm=3'),
                    buildFarmerImage('https://tse2.mm.bing.net/th/id/OIP.ZfxC2lARKFifIJqNsBf7jgHaE8?rs=1&pid=ImgDetMain&o=7&rm=3'),
                  ],
                ),
              ),

              SizedBox(height: 25),

              // Farmer image slider row 2
              Container(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal, // Horizontal scrolling
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    buildFarmerImage('https://th.bing.com/th/id/R.248856c2db56fcece45896c146e2a6e4?rik=DP9%2bs7wxnRf9Vw&riu=http%3a%2f%2fwww.lostiempos.com%2fsites%2fdefault%2ffiles%2fmedia_imagen%2f2016%2f5%2f9%2fagricultura_ganadera_y_pesca_1375726562.jpg&ehk=yBfWZ9uMOO%2fCm66LCOoAagcrwLWwSEjoU4Oy2W5mvOM%3d&risl=&pid=ImgRaw&r=0'),
                    buildFarmerImage('https://tse1.mm.bing.net/th/id/OIP.pXMjTy3bBlKx1uxGhq8DDgHaEQ?w=1000&h=575&rs=1&pid=ImgDetMain&o=7&rm=3'),
                    buildFarmerImage('https://static01.nyt.com/images/2023/12/26/multimedia/00Philippines-Legacy-01-bhzv/00Philippines-Legacy-01-bhzv-threeByTwoMediumAt2X.jpg?quality=100&auto=webp'),
                    buildFarmerImage('https://pearlpay.com/wp-content/uploads/2020/03/Helping-Farmers-in-the-PH.jpg'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom navigation bar
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color.fromARGB(255, 26, 88, 28), // Nav background color
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Terms'),
            BottomNavigationBarItem(icon: Icon(Icons.contact_mail), label: 'Contact'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
          currentIndex: _selectedIndex, // Active tab index
          selectedItemColor: const Color.fromARGB(255, 130, 99, 4), // Active tab color
          unselectedItemColor: const Color.fromARGB(255, 66, 65, 65), // Inactive tab color
          unselectedLabelStyle: const TextStyle(fontSize: 12), // Inactive label font
          onTap: _onItemTapped, // Update tab when tapped
        ),
      ),
    );
  }

  // Helper method: main slider image
  Widget buildImage(String url) => Container(
        width: double.infinity,
        decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)), // Full-width image
      );

  // Helper method: farmer slider image
  Widget buildFarmerImage(String url) => Container(
        width: 150,
        margin: EdgeInsets.only(right: 16), // Space between images
        child: ClipRRect(borderRadius: BorderRadius.circular(0), child: Image.network(url, fit: BoxFit.cover)), // Rounded image
      );
}
