\# Infiniteer Technical Implementation Guide



\## Flutter Package Dependencies



\### Required Dependencies (pubspec.yaml)

```yaml

dependencies:

&nbsp; flutter:

&nbsp;   sdk: flutter

&nbsp; 

&nbsp; # State Storage

&nbsp; hive: ^2.2.3

&nbsp; hive\_flutter: ^1.1.0

&nbsp; 

&nbsp; # Text Rendering \& Markdown

&nbsp; flutter\_markdown: ^0.6.18

&nbsp; markdown\_widget: ^2.2.0  # Alternative for more control

&nbsp; 

&nbsp; # In-App Purchases

&nbsp; in\_app\_purchase: ^3.1.11

&nbsp; 

&nbsp; # HTTP Communication

&nbsp; http: ^1.1.0

&nbsp; 

&nbsp; # Local Storage

&nbsp; shared\_preferences: ^2.2.2

&nbsp; path\_provider: ^2.1.1

&nbsp; 

&nbsp; # Animations (built-in, but useful for custom effects)

&nbsp; animated\_text\_kit: ^4.2.2



dev\_dependencies:

&nbsp; flutter\_test:

&nbsp;   sdk: flutter

&nbsp; hive\_generator: ^2.0.1

&nbsp; build\_runner: ^2.4.7

```



\## Core Storage Implementation



\### Hive Setup for IFE State Management

```dart

import 'package:hive\_flutter/hive\_flutter.dart';



class IFEStateManager {

&nbsp; static const String \_stateBoxName = 'ife\_states';

&nbsp; static const String \_tokenBoxName = 'user\_tokens';

&nbsp; 

&nbsp; static Future<void> initialize() async {

&nbsp;   await Hive.initFlutter();

&nbsp;   await Hive.openBox(\_stateBoxName);

&nbsp;   await Hive.openBox(\_tokenBoxName);

&nbsp; }

&nbsp; 

&nbsp; // Store IFE state (75-150K JSON blobs)

&nbsp; static Future<void> saveStoryState(String storyId, String stateJson) async {

&nbsp;   final box = Hive.box(\_stateBoxName);

&nbsp;   await box.put('story\_${storyId}\_state', stateJson);

&nbsp; }

&nbsp; 

&nbsp; // Retrieve IFE state

&nbsp; static String? getStoryState(String storyId) {

&nbsp;   final box = Hive.box(\_stateBoxName);

&nbsp;   return box.get('story\_${storyId}\_state');

&nbsp; }

&nbsp; 

&nbsp; // Token management

&nbsp; static Future<void> saveTokens(int tokens) async {

&nbsp;   final box = Hive.box(\_tokenBoxName);

&nbsp;   await box.put('user\_tokens', tokens);

&nbsp; }

&nbsp; 

&nbsp; static int getTokens() {

&nbsp;   final box = Hive.box(\_tokenBoxName);

&nbsp;   return box.get('user\_tokens', defaultValue: 0);

&nbsp; }

&nbsp; 

&nbsp; // Story progress metadata

&nbsp; static Future<void> saveStoryProgress(String storyId, Map<String, dynamic> progress) async {

&nbsp;   final box = Hive.box(\_stateBoxName);

&nbsp;   await box.put('story\_${storyId}\_progress', progress);

&nbsp; }

}

```



\## Netflix-Style Library Interface



\### Main Library Screen with Smooth Scrolling

```dart

import 'package:flutter/material.dart';



class LibraryScreen extends StatelessWidget {

&nbsp; @override

&nbsp; Widget build(BuildContext context) {

&nbsp;   return Scaffold(

&nbsp;     backgroundColor: Colors.black,

&nbsp;     body: CustomScrollView(

&nbsp;       physics: const BouncingScrollPhysics(), // iOS-style smooth scrolling

&nbsp;       slivers: \[

&nbsp;         // App bar

&nbsp;         SliverAppBar(

&nbsp;           title: Text('Infiniteer', style: TextStyle(color: Colors.white)),

&nbsp;           backgroundColor: Colors.black,

&nbsp;           floating: true,

&nbsp;         ),

&nbsp;         

&nbsp;         // Genre rows

&nbsp;         SliverList(

&nbsp;           delegate: SliverChildListDelegate(\[

&nbsp;             \_buildGenreSection("Adult/Romance", \_adultStories),

&nbsp;             \_buildGenreSection("Sci-Fi", \_scifiStories),

&nbsp;             \_buildGenreSection("Horror", \_horrorStories),

&nbsp;           ]),

&nbsp;         ),

&nbsp;       ],

&nbsp;     ),

&nbsp;   );

&nbsp; }



&nbsp; Widget \_buildGenreSection(String genre, List<Story> stories) {

&nbsp;   return Column(

&nbsp;     crossAxisAlignment: CrossAxisAlignment.start,

&nbsp;     children: \[

&nbsp;       // Genre title

&nbsp;       Padding(

&nbsp;         padding: EdgeInsets.all(16.0),

&nbsp;         child: Text(

&nbsp;           genre,

&nbsp;           style: TextStyle(

&nbsp;             color: Colors.white,

&nbsp;             fontSize: 24,

&nbsp;             fontWeight: FontWeight.bold,

&nbsp;           ),

&nbsp;         ),

&nbsp;       ),

&nbsp;       

&nbsp;       // Horizontal story row

&nbsp;       Container(

&nbsp;         height: 280, // Paperback height

&nbsp;         child: PageView.builder(

&nbsp;           controller: PageController(viewportFraction: 0.5), // 50% width peek

&nbsp;           physics: ClampingScrollPhysics(), // Smooth snapping

&nbsp;           itemCount: stories.length,

&nbsp;           itemBuilder: (context, index) => \_buildBookCover(stories\[index]),

&nbsp;         ),

&nbsp;       ),

&nbsp;       

&nbsp;       SizedBox(height: 20),

&nbsp;     ],

&nbsp;   );

&nbsp; }



&nbsp; Widget \_buildBookCover(Story story) {

&nbsp;   return GestureDetector(

&nbsp;     onTap: () => \_openStory(story),

&nbsp;     child: Container(

&nbsp;       margin: EdgeInsets.symmetric(horizontal: 8.0),

&nbsp;       child: Hero(

&nbsp;         tag: "book\_${story.id}",

&nbsp;         child: Material(

&nbsp;           elevation: 8.0,

&nbsp;           borderRadius: BorderRadius.circular(8.0),

&nbsp;           child: ClipRRect(

&nbsp;             borderRadius: BorderRadius.circular(8.0),

&nbsp;             child: Stack(

&nbsp;               fit: StackFit.expand,

&nbsp;               children: \[

&nbsp;                 // Cover image

&nbsp;                 Image.network(

&nbsp;                   story.coverUrl,

&nbsp;                   fit: BoxFit.cover,

&nbsp;                 ),

&nbsp;                 

&nbsp;                 // Gradient overlay for title

&nbsp;                 Positioned(

&nbsp;                   bottom: 0,

&nbsp;                   left: 0,

&nbsp;                   right: 0,

&nbsp;                   child: Container(

&nbsp;                     decoration: BoxDecoration(

&nbsp;                       gradient: LinearGradient(

&nbsp;                         begin: Alignment.bottomCenter,

&nbsp;                         end: Alignment.topCenter,

&nbsp;                         colors: \[Colors.black.withOpacity(0.8), Colors.transparent],

&nbsp;                       ),

&nbsp;                     ),

&nbsp;                     padding: EdgeInsets.all(12.0),

&nbsp;                     child: Text(

&nbsp;                       story.title,

&nbsp;                       style: TextStyle(

&nbsp;                         color: Colors.white,

&nbsp;                         fontSize: 16,

&nbsp;                         fontWeight: FontWeight.bold,

&nbsp;                       ),

&nbsp;                       maxLines: 2,

&nbsp;                       overflow: TextOverflow.ellipsis,

&nbsp;                     ),

&nbsp;                   ),

&nbsp;                 ),

&nbsp;               ],

&nbsp;             ),

&nbsp;           ),

&nbsp;         ),

&nbsp;       ),

&nbsp;     ),

&nbsp;   );

&nbsp; }

&nbsp; 

&nbsp; void \_openStory(Story story) {

&nbsp;   Navigator.push(

&nbsp;     context,

&nbsp;     PageRouteBuilder(

&nbsp;       pageBuilder: (context, animation, secondaryAnimation) => 

&nbsp;           StoryReaderScreen(story: story),

&nbsp;       transitionsBuilder: (context, animation, secondaryAnimation, child) {

&nbsp;         return FadeTransition(opacity: animation, child: child);

&nbsp;       },

&nbsp;     ),

&nbsp;   );

&nbsp; }

}



// Custom scroll behavior for smooth scrolling

class SilkyScrollBehavior extends ScrollBehavior {

&nbsp; @override

&nbsp; ScrollPhysics getScrollPhysics(BuildContext context) {

&nbsp;   return BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

&nbsp; }

&nbsp; 

&nbsp; @override

&nbsp; Widget buildOverscrollIndicator(context, child, details) {

&nbsp;   return child; // Remove Android glow effect

&nbsp; }

}

```



\## Streaming Text with Markdown Support



\### Interactive Story Text Display

```dart

import 'package:flutter/material.dart';

import 'package:flutter\_markdown/flutter\_markdown.dart';



class StreamingStoryText extends StatefulWidget {

&nbsp; final String fullText;

&nbsp; final Duration animationDuration;

&nbsp; 

&nbsp; const StreamingStoryText({

&nbsp;   Key? key,

&nbsp;   required this.fullText,

&nbsp;   this.animationDuration = const Duration(milliseconds: 500),

&nbsp; }) : super(key: key);



&nbsp; @override

&nbsp; \_StreamingStoryTextState createState() => \_StreamingStoryTextState();

}



class \_StreamingStoryTextState extends State<StreamingStoryText> 

&nbsp;   with TickerProviderStateMixin {

&nbsp; 

&nbsp; List<String> \_sentences = \[];

&nbsp; List<AnimationController> \_controllers = \[];

&nbsp; List<Animation<double>> \_animations = \[];

&nbsp; 

&nbsp; @override

&nbsp; void initState() {

&nbsp;   super.initState();

&nbsp;   \_processSentences();

&nbsp;   \_setupAnimations();

&nbsp;   \_startStreaming();

&nbsp; }

&nbsp; 

&nbsp; void \_processSentences() {

&nbsp;   // Split text into sentences for streaming

&nbsp;   \_sentences = widget.fullText

&nbsp;       .split(RegExp(r'(?<=\[.!?])\\s+'))

&nbsp;       .where((s) => s.trim().isNotEmpty)

&nbsp;       .toList();

&nbsp; }

&nbsp; 

&nbsp; void \_setupAnimations() {

&nbsp;   for (int i = 0; i < \_sentences.length; i++) {

&nbsp;     final controller = AnimationController(

&nbsp;       duration: widget.animationDuration,

&nbsp;       vsync: this,

&nbsp;     );

&nbsp;     final animation = Tween<double>(

&nbsp;       begin: 0.0,

&nbsp;       end: 1.0,

&nbsp;     ).animate(CurvedAnimation(

&nbsp;       parent: controller,

&nbsp;       curve: Curves.easeIn,

&nbsp;     ));

&nbsp;     

&nbsp;     \_controllers.add(controller);

&nbsp;     \_animations.add(animation);

&nbsp;   }

&nbsp; }

&nbsp; 

&nbsp; void \_startStreaming() {

&nbsp;   for (int i = 0; i < \_controllers.length; i++) {

&nbsp;     Future.delayed(Duration(milliseconds: i \* 800), () {

&nbsp;       if (mounted) {

&nbsp;         \_controllers\[i].forward();

&nbsp;       }

&nbsp;     });

&nbsp;   }

&nbsp; }

&nbsp; 

&nbsp; @override

&nbsp; Widget build(BuildContext context) {

&nbsp;   return Column(

&nbsp;     crossAxisAlignment: CrossAxisAlignment.start,

&nbsp;     children: \_sentences.asMap().entries.map((entry) {

&nbsp;       int index = entry.key;

&nbsp;       String sentence = entry.value;

&nbsp;       

&nbsp;       return FadeTransition(

&nbsp;         opacity: \_animations\[index],

&nbsp;         child: SlideTransition(

&nbsp;           position: Tween<Offset>(

&nbsp;             begin: Offset(0, 0.3),

&nbsp;             end: Offset.zero,

&nbsp;           ).animate(\_animations\[index]),

&nbsp;           child: Container(

&nbsp;             margin: EdgeInsets.only(bottom: 8.0),

&nbsp;             child: MarkdownBody(

&nbsp;               data: sentence,

&nbsp;               styleSheet: MarkdownStyleSheet(

&nbsp;                 // Novel-style formatting

&nbsp;                 p: TextStyle(

&nbsp;                   fontSize: 18,

&nbsp;                   height: 1.6,

&nbsp;                   color: Colors.white.withOpacity(0.9),

&nbsp;                 ),

&nbsp;                 h1: TextStyle(

&nbsp;                   fontSize: 28,

&nbsp;                   fontWeight: FontWeight.bold,

&nbsp;                   color: Colors.white,

&nbsp;                   height: 1.4,

&nbsp;                 ),

&nbsp;                 h2: TextStyle(

&nbsp;                   fontSize: 24,

&nbsp;                   fontWeight: FontWeight.w600,

&nbsp;                   color: Colors.white,

&nbsp;                   height: 1.4,

&nbsp;                 ),

&nbsp;                 blockquote: TextStyle(

&nbsp;                   fontSize: 18,

&nbsp;                   fontStyle: FontStyle.italic,

&nbsp;                   color: Colors.white.withOpacity(0.8),

&nbsp;                 ),

&nbsp;                 blockquoteDecoration: BoxDecoration(

&nbsp;                   border: Border(

&nbsp;                     left: BorderSide(

&nbsp;                       color: Colors.purple.withOpacity(0.6),

&nbsp;                       width: 4,

&nbsp;                     ),

&nbsp;                   ),

&nbsp;                 ),

&nbsp;                 strong: TextStyle(

&nbsp;                   fontWeight: FontWeight.bold,

&nbsp;                   color: Colors.white,

&nbsp;                 ),

&nbsp;                 em: TextStyle(

&nbsp;                   fontStyle: FontStyle.italic,

&nbsp;                   color: Colors.white,

&nbsp;                 ),

&nbsp;               ),

&nbsp;             ),

&nbsp;           ),

&nbsp;         ),

&nbsp;       );

&nbsp;     }).toList(),

&nbsp;   );

&nbsp; }

&nbsp; 

&nbsp; @override

&nbsp; void dispose() {

&nbsp;   for (final controller in \_controllers) {

&nbsp;     controller.dispose();

&nbsp;   }

&nbsp;   super.dispose();

&nbsp; }

}

```



\## Story Reader Screen with Page Navigation



\### Full-Screen Reading Experience

```dart

class StoryReaderScreen extends StatefulWidget {

&nbsp; final Story story;

&nbsp; 

&nbsp; const StoryReaderScreen({Key? key, required this.story}) : super(key: key);

&nbsp; 

&nbsp; @override

&nbsp; \_StoryReaderScreenState createState() => \_StoryReaderScreenState();

}



class \_StoryReaderScreenState extends State<StoryReaderScreen> {

&nbsp; PageController \_pageController = PageController();

&nbsp; int \_currentPage = 0;

&nbsp; String? \_currentState;

&nbsp; 

&nbsp; @override

&nbsp; void initState() {

&nbsp;   super.initState();

&nbsp;   \_loadStoryState();

&nbsp; }

&nbsp; 

&nbsp; void \_loadStoryState() {

&nbsp;   \_currentState = IFEStateManager.getStoryState(widget.story.id);

&nbsp;   // If no saved state, this is a new story

&nbsp; }

&nbsp; 

&nbsp; @override

&nbsp; Widget build(BuildContext context) {

&nbsp;   return Scaffold(

&nbsp;     backgroundColor: Colors.black,

&nbsp;     body: PageView.builder(

&nbsp;       controller: \_pageController,

&nbsp;       physics: ClampingScrollPhysics(),

&nbsp;       onPageChanged: (page) => setState(() => \_currentPage = page),

&nbsp;       itemBuilder: (context, index) {

&nbsp;         if (index == 0) {

&nbsp;           return \_buildCoverPage();

&nbsp;         } else if (index == 1) {

&nbsp;           return \_buildStoryIntroPage();

&nbsp;         } else {

&nbsp;           return \_buildStoryPage(index - 2);

&nbsp;         }

&nbsp;       },

&nbsp;     ),

&nbsp;   );

&nbsp; }

&nbsp; 

&nbsp; Widget \_buildCoverPage() {

&nbsp;   return Hero(

&nbsp;     tag: "book\_${widget.story.id}",

&nbsp;     child: Stack(

&nbsp;       fit: StackFit.expand,

&nbsp;       children: \[

&nbsp;         // Full-screen cover

&nbsp;         Image.network(

&nbsp;           widget.story.coverUrl,

&nbsp;           fit: BoxFit.cover,

&nbsp;         ),

&nbsp;         

&nbsp;         // Gradient overlay

&nbsp;         Container(

&nbsp;           decoration: BoxDecoration(

&nbsp;             gradient: LinearGradient(

&nbsp;               begin: Alignment.topCenter,

&nbsp;               end: Alignment.bottomCenter,

&nbsp;               colors: \[

&nbsp;                 Colors.transparent,

&nbsp;                 Colors.black.withOpacity(0.7),

&nbsp;                 Colors.black.withOpacity(0.9),

&nbsp;               ],

&nbsp;             ),

&nbsp;           ),

&nbsp;         ),

&nbsp;         

&nbsp;         // Story info

&nbsp;         Positioned(

&nbsp;           bottom: 100,

&nbsp;           left: 20,

&nbsp;           right: 20,

&nbsp;           child: Column(

&nbsp;             crossAxisAlignment: CrossAxisAlignment.start,

&nbsp;             children: \[

&nbsp;               Text(

&nbsp;                 widget.story.title,

&nbsp;                 style: TextStyle(

&nbsp;                   color: Colors.white,

&nbsp;                   fontSize: 32,

&nbsp;                   fontWeight: FontWeight.bold,

&nbsp;                 ),

&nbsp;               ),

&nbsp;               SizedBox(height: 12),

&nbsp;               Text(

&nbsp;                 widget.story.description,

&nbsp;                 style: TextStyle(

&nbsp;                   color: Colors.white.withOpacity(0.9),

&nbsp;                   fontSize: 16,

&nbsp;                   height: 1.5,

&nbsp;                 ),

&nbsp;                 maxLines: 4,

&nbsp;                 overflow: TextOverflow.ellipsis,

&nbsp;               ),

&nbsp;               SizedBox(height: 20),

&nbsp;               Text(

&nbsp;                 "Swipe right to begin →",

&nbsp;                 style: TextStyle(

&nbsp;                   color: Colors.white.withOpacity(0.7),

&nbsp;                   fontSize: 14,

&nbsp;                 ),

&nbsp;               ),

&nbsp;             ],

&nbsp;           ),

&nbsp;         ),

&nbsp;         

&nbsp;         // Close button

&nbsp;         Positioned(

&nbsp;           top: 50,

&nbsp;           right: 20,

&nbsp;           child: IconButton(

&nbsp;             icon: Icon(Icons.close, color: Colors.white, size: 30),

&nbsp;             onPressed: () => Navigator.pop(context),

&nbsp;           ),

&nbsp;         ),

&nbsp;       ],

&nbsp;     ),

&nbsp;   );

&nbsp; }

&nbsp; 

&nbsp; Widget \_buildStoryIntroPage() {

&nbsp;   return Container(

&nbsp;     padding: EdgeInsets.all(20),

&nbsp;     child: Column(

&nbsp;       children: \[

&nbsp;         Expanded(

&nbsp;           child: SingleChildScrollView(

&nbsp;             child: StreamingStoryText(

&nbsp;               fullText: widget.story.introText,

&nbsp;             ),

&nbsp;           ),

&nbsp;         ),

&nbsp;         

&nbsp;         // Choice buttons or continue button

&nbsp;         \_buildChoiceButtons(),

&nbsp;       ],

&nbsp;     ),

&nbsp;   );

&nbsp; }

&nbsp; 

&nbsp; Widget \_buildStoryPage(int pageIndex) {

&nbsp;   // This would load the actual story content based on current state

&nbsp;   return Container(

&nbsp;     padding: EdgeInsets.all(20),

&nbsp;     child: Column(

&nbsp;       children: \[

&nbsp;         Expanded(

&nbsp;           child: SingleChildScrollView(

&nbsp;             child: StreamingStoryText(

&nbsp;               fullText: "Story content for page $pageIndex...",

&nbsp;             ),

&nbsp;           ),

&nbsp;         ),

&nbsp;         

&nbsp;         \_buildChoiceButtons(),

&nbsp;       ],

&nbsp;     ),

&nbsp;   );

&nbsp; }

&nbsp; 

&nbsp; Widget \_buildChoiceButtons() {

&nbsp;   return Container(

&nbsp;     padding: EdgeInsets.symmetric(vertical: 20),

&nbsp;     child: Column(

&nbsp;       children: \[

&nbsp;         // Example choice buttons

&nbsp;         \_buildChoiceButton("Choice 1: Take the risk", 1),

&nbsp;         SizedBox(height: 12),

&nbsp;         \_buildChoiceButton("Choice 2: Play it safe", 1),

&nbsp;         SizedBox(height: 12),

&nbsp;         \_buildChoiceButton("Choice 3: Ask for help", 1),

&nbsp;       ],

&nbsp;     ),

&nbsp;   );

&nbsp; }

&nbsp; 

&nbsp; Widget \_buildChoiceButton(String text, int tokenCost) {

&nbsp;   bool hasTokens = IFEStateManager.getTokens() >= tokenCost;

&nbsp;   

&nbsp;   return SizedBox(

&nbsp;     width: double.infinity,

&nbsp;     child: ElevatedButton(

&nbsp;       onPressed: hasTokens ? () => \_makeChoice(text, tokenCost) : null,

&nbsp;       style: ElevatedButton.styleFrom(

&nbsp;         backgroundColor: hasTokens ? Colors.purple : Colors.grey,

&nbsp;         padding: EdgeInsets.symmetric(vertical: 16),

&nbsp;         shape: RoundedRectangleBorder(

&nbsp;           borderRadius: BorderRadius.circular(8),

&nbsp;         ),

&nbsp;       ),

&nbsp;       child: Row(

&nbsp;         mainAxisAlignment: MainAxisAlignment.spaceBetween,

&nbsp;         children: \[

&nbsp;           Expanded(

&nbsp;             child: Text(

&nbsp;               text,

&nbsp;               style: TextStyle(

&nbsp;                 color: Colors.white,

&nbsp;                 fontSize: 16,

&nbsp;               ),

&nbsp;             ),

&nbsp;           ),

&nbsp;           Container(

&nbsp;             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),

&nbsp;             decoration: BoxDecoration(

&nbsp;               color: Colors.black26,

&nbsp;               borderRadius: BorderRadius.circular(4),

&nbsp;             ),

&nbsp;             child: Text(

&nbsp;               "$tokenCost 🪙",

&nbsp;               style: TextStyle(

&nbsp;                 color: Colors.white,

&nbsp;                 fontSize: 14,

&nbsp;               ),

&nbsp;             ),

&nbsp;           ),

&nbsp;         ],

&nbsp;       ),

&nbsp;     ),

&nbsp;   );

&nbsp; }

&nbsp; 

&nbsp; Future<void> \_makeChoice(String choice, int tokenCost) async {

&nbsp;   // Deduct tokens

&nbsp;   int currentTokens = IFEStateManager.getTokens();

&nbsp;   await IFEStateManager.saveTokens(currentTokens - tokenCost);

&nbsp;   

&nbsp;   // Call API with choice and current state

&nbsp;   await \_processStoryChoice(choice);

&nbsp;   

&nbsp;   // Move to next page

&nbsp;   \_pageController.nextPage(

&nbsp;     duration: Duration(milliseconds: 300),

&nbsp;     curve: Curves.easeInOut,

&nbsp;   );

&nbsp; }

&nbsp; 

&nbsp; Future<void> \_processStoryChoice(String choice) async {

&nbsp;   // API call to your existing backend

&nbsp;   // This would POST the choice and current state, get back new story content

&nbsp; }

}

```



\## In-App Purchase Implementation



\### Token Purchase System

```dart

import 'package:in\_app\_purchase/in\_app\_purchase.dart';



class TokenPurchaseService {

&nbsp; static const String \_tokenPack4 = 'tokens\_4\_pack';   // $0.99

&nbsp; static const String \_tokenPack12 = 'tokens\_12\_pack'; // $1.99

&nbsp; static const String \_tokenPack25 = 'tokens\_25\_pack'; // $2.99

&nbsp; 

&nbsp; static const Set<String> \_productIds = {

&nbsp;   \_tokenPack4,

&nbsp;   \_tokenPack12,

&nbsp;   \_tokenPack25,

&nbsp; };

&nbsp; 

&nbsp; final InAppPurchase \_inAppPurchase = InAppPurchase.instance;

&nbsp; List<ProductDetails> \_products = \[];

&nbsp; 

&nbsp; Future<void> initialize() async {

&nbsp;   final bool available = await \_inAppPurchase.isAvailable();

&nbsp;   if (!available) return;

&nbsp;   

&nbsp;   // Load products

&nbsp;   final ProductDetailsResponse response = 

&nbsp;       await \_inAppPurchase.queryProductDetails(\_productIds);

&nbsp;   

&nbsp;   if (response.notFoundIDs.isNotEmpty) {

&nbsp;     print('Products not found: ${response.notFoundIDs}');

&nbsp;   }

&nbsp;   

&nbsp;   \_products = response.productDetails;

&nbsp;   

&nbsp;   // Listen to purchase updates

&nbsp;   \_inAppPurchase.purchaseStream.listen(\_handlePurchaseUpdate);

&nbsp; }

&nbsp; 

&nbsp; Future<void> buyTokenPack(String productId) async {

&nbsp;   final ProductDetails productDetails = \_products

&nbsp;       .firstWhere((product) => product.id == productId);

&nbsp;   

&nbsp;   final PurchaseParam purchaseParam = PurchaseParam(

&nbsp;     productDetails: productDetails,

&nbsp;   );

&nbsp;   

&nbsp;   await \_inAppPurchase.buyConsumable(purchaseParam: purchaseParam);

&nbsp; }

&nbsp; 

&nbsp; void \_handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {

&nbsp;   for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {

&nbsp;     if (purchaseDetails.status == PurchaseStatus.purchased) {

&nbsp;       \_deliverTokens(purchaseDetails);

&nbsp;     } else if (purchaseDetails.status == PurchaseStatus.error) {

&nbsp;       \_handlePurchaseError(purchaseDetails);

&nbsp;     }

&nbsp;     

&nbsp;     if (purchaseDetails.pendingCompletePurchase) {

&nbsp;       \_inAppPurchase.completePurchase(purchaseDetails);

&nbsp;     }

&nbsp;   }

&nbsp; }

&nbsp; 

&nbsp; Future<void> \_deliverTokens(PurchaseDetails purchaseDetails) async {

&nbsp;   int tokensToAdd = 0;

&nbsp;   

&nbsp;   switch (purchaseDetails.productID) {

&nbsp;     case \_tokenPack4:

&nbsp;       tokensToAdd = 4;

&nbsp;       break;

&nbsp;     case \_tokenPack12:

&nbsp;       tokensToAdd = 12;

&nbsp;       break;

&nbsp;     case \_tokenPack25:

&nbsp;       tokensToAdd = 25;

&nbsp;       break;

&nbsp;   }

&nbsp;   

&nbsp;   // Add tokens to user's account

&nbsp;   int currentTokens = IFEStateManager.getTokens();

&nbsp;   await IFEStateManager.saveTokens(currentTokens + tokensToAdd);

&nbsp;   

&nbsp;   print('Delivered $tokensToAdd tokens to user');

&nbsp; }

&nbsp; 

&nbsp; void \_handlePurchaseError(PurchaseDetails purchaseDetails) {

&nbsp;   print('Purchase error: ${purchaseDetails.error}');

&nbsp; }

&nbsp; 

&nbsp; List<ProductDetails> get availableProducts => \_products;

}

```



\## API Communication Layer



\### HTTP Client for Backend Communication

```dart

import 'dart:convert';

import 'package:http/http.dart' as http;



class IFEApiService {

&nbsp; static const String baseUrl = 'https://your-api-domain.com/api';

&nbsp; 

&nbsp; // Start a new story

&nbsp; static Future<Map<String, dynamic>> startStory(String storyId) async {

&nbsp;   final response = await http.get(

&nbsp;     Uri.parse('$baseUrl/play/$storyId'),

&nbsp;     headers: {'Content-Type': 'application/json'},

&nbsp;   );

&nbsp;   

&nbsp;   if (response.statusCode == 200) {

&nbsp;     return json.decode(response.body);

&nbsp;   } else {

&nbsp;     throw Exception('Failed to start story: ${response.statusCode}');

&nbsp;   }

&nbsp; }

&nbsp; 

&nbsp; // Make a story choice

&nbsp; static Future<Map<String, dynamic>> makeChoice({

&nbsp;   required String storyId,

&nbsp;   required String input,

&nbsp;   required String storedState,

&nbsp;   String? displayedNarrative,

&nbsp;   List<String>? options,

&nbsp; }) async {

&nbsp;   final response = await http.post(

&nbsp;     Uri.parse('$baseUrl/play'),

&nbsp;     headers: {'Content-Type': 'application/json'},

&nbsp;     body: json.encode({

&nbsp;       'storyId': storyId,

&nbsp;       'input': input,

&nbsp;       'storedState': storedState,

&nbsp;       'displayedNarrative': displayedNarrative,

&nbsp;       'options': options,

&nbsp;     }),

&nbsp;   );

&nbsp;   

&nbsp;   if (response.statusCode == 200) {

&nbsp;     return json.decode(response.body);

&nbsp;   } else {

&nbsp;     throw Exception('Failed to process choice: ${response.statusCode}');

&nbsp;   }

&nbsp; }

&nbsp; 

&nbsp; // Validate token usage

&nbsp; static Future<bool> validateToken(String userId, int tokenCost) async {

&nbsp;   // This would call your backend to validate and deduct tokens

&nbsp;   // Return true if successful, false if insufficient tokens

&nbsp;   return true; // Placeholder

&nbsp; }

}

```



\## Main App Setup



\### App Initialization

```dart

import 'package:flutter/material.dart';



void main() async {

&nbsp; WidgetsFlutterBinding.ensureInitialized();

&nbsp; 

&nbsp; // Initialize storage

&nbsp; await IFEStateManager.initialize();

&nbsp; 

&nbsp; // Initialize purchases

&nbsp; final purchaseService = TokenPurchaseService();

&nbsp; await purchaseService.initialize();

&nbsp; 

&nbsp; runApp(InfiniteerApp());

}



class InfiniteerApp extends StatelessWidget {

&nbsp; @override

&nbsp; Widget build(BuildContext context) {

&nbsp;   return MaterialApp(

&nbsp;     title: 'Infiniteer',

&nbsp;     theme: ThemeData.dark(),

&nbsp;     scrollBehavior: SilkyScrollBehavior(),

&nbsp;     home: \_buildAgeGate(),

&nbsp;   );

&nbsp; }

&nbsp; 

&nbsp; Widget \_buildAgeGate() {

&nbsp;   // Simple 18+ confirmation

&nbsp;   return AgeVerificationScreen();

&nbsp; }

}



class AgeVerificationScreen extends StatelessWidget {

&nbsp; @override

&nbsp; Widget build(BuildContext context) {

&nbsp;   return Scaffold(

&nbsp;     backgroundColor: Colors.black,

&nbsp;     body: Center(

&nbsp;       child: Column(

&nbsp;         mainAxisAlignment: MainAxisAlignment.center,

&nbsp;         children: \[

&nbsp;           Text(

&nbsp;             'Age Verification',

&nbsp;             style: TextStyle(

&nbsp;               color: Colors.white,

&nbsp;               fontSize: 28,

&nbsp;               fontWeight: FontWeight.bold,

&nbsp;             ),

&nbsp;           ),

&nbsp;           SizedBox(height: 20),

&nbsp;           Text(

&nbsp;             'This app contains mature content.\\nAre you 18 years or older?',

&nbsp;             textAlign: TextAlign.center,

&nbsp;             style: TextStyle(

&nbsp;               color: Colors.white.withOpacity(0.8),

&nbsp;               fontSize: 16,

&nbsp;             ),

&nbsp;           ),

&nbsp;           SizedBox(height: 40),

&nbsp;           Row(

&nbsp;             mainAxisAlignment: MainAxisAlignment.spaceEvenly,

&nbsp;             children: \[

&nbsp;               ElevatedButton(

&nbsp;                 onPressed: () => Navigator.pushReplacement(

&nbsp;                   context,

&nbsp;                   MaterialPageRoute(builder: (\_) => LibraryScreen()),

&nbsp;                 ),

&nbsp;                 style: ElevatedButton.styleFrom(

&nbsp;                   backgroundColor: Colors.green,

&nbsp;                   padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),

&nbsp;                 ),

&nbsp;                 child: Text('Yes, I am 18+'),

&nbsp;               ),

&nbsp;               ElevatedButton(

&nbsp;                 onPressed: () => \_exitApp(),

&nbsp;                 style: ElevatedButton.styleFrom(

&nbsp;                   backgroundColor: Colors.red,

&nbsp;                   padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),

&nbsp;                 ),

&nbsp;                 child: Text('No'),

&nbsp;               ),

&nbsp;             ],

&nbsp;           ),

&nbsp;         ],

&nbsp;       ),

&nbsp;     ),

&nbsp;   );

&nbsp; }

&nbsp; 

&nbsp; void \_exitApp() {

&nbsp;   // Exit the app

&nbsp;   SystemNavigator.pop();

&nbsp; }

}

```



\## Performance Optimization Tips



\### Memory Management and Smooth Scrolling

```dart

class OptimizedImageWidget extends StatelessWidget {

&nbsp; final String imageUrl;

&nbsp; final BoxFit fit;

&nbsp; 

&nbsp; const OptimizedImageWidget({

&nbsp;   Key? key,

&nbsp;   required this.imageUrl,

&nbsp;   this.fit = BoxFit.cover,

&nbsp; }) : super(key: key);

&nbsp; 

&nbsp; @override

&nbsp; Widget build(BuildContext context) {

&nbsp;   return Image.network(

&nbsp;     imageUrl,

&nbsp;     fit: fit,

&nbsp;     frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {

&nbsp;       if (wasSynchronouslyLoaded) return child;

&nbsp;       return AnimatedOpacity(

&nbsp;         opacity: frame == null ? 0 : 1,

&nbsp;         duration: Duration(milliseconds: 300),

&nbsp;         curve: Curves.easeOut,

&nbsp;         child: child,

&nbsp;       );

&nbsp;     },

&nbsp;     loadingBuilder: (context, child, loadingProgress) {

&nbsp;       if (loadingProgress == null) return child;

&nbsp;       return Container(

&nbsp;         color: Colors.grey\[900],

&nbsp;         child: Center(

&nbsp;           child: CircularProgressIndicator(

&nbsp;             value: loadingProgress.expectedTotalBytes != null

&nbsp;                 ? loadingProgress.cumulativeBytesLoaded /

&nbsp;                     loadingProgress.expectedTotalBytes!

&nbsp;                 : null,

&nbsp;           ),

&nbsp;         ),

&nbsp;       );

&nbsp;     },

&nbsp;     errorBuilder: (context, error, stackTrace) {

&nbsp;       return Container(

&nbsp;         color: Colors.grey\[900],

&nbsp;         child: Icon(

&nbsp;           Icons.error,

&nbsp;           color: Colors.white54,

&nbsp;         ),

&nbsp;       );

&nbsp;     },

&nbsp;   );

&nbsp; }

}

```



This technical implementation guide provides all the code structures needed to build your Netflix-style interactive fiction app with smooth animations, proper state management, and monetization systems.

