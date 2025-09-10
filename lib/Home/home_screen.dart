import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String quote = "";
  String author = "";
  bool _isFavorite = false;
  late Box favBox;

  // Animation controller
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  int _currentIndex = 0; // bottom nav index

  @override
  void initState() {
    super.initState();
    favBox = Hive.box("favorites");

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    getRandomQuote();
  }

  Future<void> getRandomQuote() async {
    setState(() {
      quote = "";
      author = "";
    });
    _controller.reset();

    final response =
    await http.get(Uri.parse("https://zenquotes.io/api/random"));
    var data = jsonDecode(response.body.toString());

    if (response.statusCode == 200) {
      setState(() {
        quote = data[0]["q"];
        author = data[0]["a"];
        _isFavorite = favBox.values.any(
              (item) => item["q"] == quote && item["a"] == author,
        );
      });
      _controller.forward();
    }
  }

  void _toggleFavorite() {
    if (quote.isEmpty) return;

    setState(() {
      _isFavorite = !_isFavorite;
      if (_isFavorite) {
        favBox.add({"q": quote, "a": author});
      } else {
        final keyToRemove = favBox.keys.firstWhere(
              (key) {
            final item = favBox.get(key);
            return item["q"] == quote && item["a"] == author;
          },
          orElse: () => null,
        );
        if (keyToRemove != null) favBox.delete(keyToRemove);
      }
    });
  }

  void _shareQuote() {
    if (quote.isNotEmpty) {
      Share.share('“$quote” - $author');
    }
  }

  Widget _buildHome() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _fadeAnim,
            child: Container(
              height: 380,
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        quote.isEmpty ? "Fetching inspiration..." : "“$quote”",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        author.isEmpty ? "" : "- $author",
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _toggleFavorite,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            key: ValueKey(_isFavorite),
                            color: _isFavorite ? Colors.red : Colors.white70,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: _shareQuote,
                        icon: const Icon(Icons.share,
                            color: Colors.white70, size: 26),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () async {
              await getRandomQuote();
            },
            child: Container(
              width: 180,
              padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "Inspire Me",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFavorites() {
    final favBox = Hive.box("favorites");

    return ValueListenableBuilder(
      valueListenable: favBox.listenable(),
      builder: (context, Box box, _) {
        if (box.isEmpty) {
          return const Center(
              child: Text("No favorites yet!",
                  style: TextStyle(fontSize: 18, color: Colors.white70)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: box.length,
          itemBuilder: (context, index) {
            final fav = box.getAt(index) as Map;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                color: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text("“${fav["q"]}”",
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white)),
                  subtitle: Text("- ${fav["a"]}",
                      style:
                      const TextStyle(color: Colors.white70, fontSize: 14)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => box.deleteAt(index),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [_buildHome(), _buildFavorites()];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/bg.jpg", fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.3)
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          screens[_currentIndex],
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.black87,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.white70,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.format_quote), label: "Quotes"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorites"),
        ],
      ),
    );
  }
}
