# Infiniteer - Interactive Fiction Experience

A premium Flutter mobile app for adult interactive fiction with Netflix-style browsing interface.

## 🎯 Project Overview

Infiniteer is a choice-driven interactive fiction app featuring:
- **Netflix-style library interface** with genre-based horizontal scrolling
- **Premium adult/romance content** with 18+ age verification 
- **Token-based monetization** (25¢ per turn)
- **Streaming text animations** with sentence-by-sentence fade-in
- **Markdown-powered storytelling** with rich text formatting
- **Cross-platform support** (iOS/Android) with smooth 60fps+ animations

## 🏗️ Architecture

### Tech Stack
- **Flutter** - Cross-platform mobile framework
- **Hive** - Local encrypted state storage (75-150K JSON blobs)
- **markdown_widget** - Rich text rendering (flutter_markdown replacement)
- **in_app_purchase** - Token purchase system
- **HTTP** - API communication with .NET backend

### Key Components
- **Age Verification Screen** - 18+ compliance gate
- **Library Screen** - Netflix-style story browsing
- **Story Reader Screen** - Full-screen immersive reading experience
- **Streaming Text Widget** - Animated markdown rendering
- **State Management** - Encrypted story state persistence

## 🎨 Design Features

### Netflix-Style Interface
- Horizontal scrolling genre rows (50% viewport width for peek effect)
- Hero animations for smooth book cover transitions
- Smooth-as-silk scrolling with custom ScrollPhysics
- Dark theme with purple accent colors

### Reading Experience  
- Full-screen immersive text display
- Streaming text with sentence-by-sentence fade-in effects
- Markdown support: titles, blockquotes, bold, italics
- Choice buttons with token cost display
- Progress tracking and resume functionality

### Monetization
- Token packs: 4 ($0.99), 12 ($1.99), 25 ($2.99)
- ~85¢ profit per turn after API costs and app store fees
- Server-side encrypted state management

## 📱 Current Implementation

### ✅ Completed Features
- [x] Flutter project scaffolding with all dependencies
- [x] Netflix-style library UI with genre sections  
- [x] Age verification screen (18+ compliance)
- [x] Story models with adult content classification
- [x] Animated markdown text rendering
- [x] Hero animations for book covers
- [x] Local state management with Hive
- [x] Token counter UI
- [x] Choice-driven reading interface
- [x] VS Code development environment setup

### 📋 Ready for Integration
- API service layer structure (ready for .NET backend)
- In-app purchase framework setup
- Progress tracking system
- Story completion flow

### 🎯 Next Steps for Full Implementation
1. **API Integration** - Connect to existing .NET backend
2. **Token Purchases** - Implement in_app_purchase flows
3. **Content Pipeline** - Load 15 starter stories from API
4. **Testing** - Family/friends beta testing
5. **App Store** - Submission with 18+/17+ rating

## 🎪 Sample Stories Included

### Adult/Romance (50% target usage)
- "Kell's Co-ed Conundrum" - College romance flagship story
- "Midnight Desires" - City night mysterious romance

### Sci-Fi (25% target usage)  
- "Quantum Echo" - Reality-bending space thriller
- "Neural Interface" - Cyberspace consciousness dive

### Horror (15% target usage)
- "Whispers in the Dark" - Victorian mansion mystery

## 🚀 Getting Started

### Prerequisites
- Flutter 3.22.1+ 
- Dart 3.4.1+
- VS Code with Flutter extensions
- Android Studio (for Android development)
- Xcode (for iOS development)

### Installation
```bash
# Clone and navigate to project
cd FlutterApp

# Get dependencies  
flutter pub get

# Run on device/emulator
flutter run

# For web testing
flutter run -d chrome
```

### Development Setup
- VS Code configuration included (`.vscode/`)
- Flutter Inspector and Hot Reload enabled
- Debug/Profile/Release launch configs
- Smooth scrolling behavior configured
- Dark theme with purple branding

## 📊 Monetization Model

### Revenue Projections
- **Month 1**: 1,000 downloads, 10% conversion, 5,000 turns ($1,250 revenue)
- **Month 3**: 10,000 MAU, 50,000 turns/month ($12,500 revenue, $7,500 profit)

### API Cost Management
- **Budget**: $5K/month = 55,000 turns capacity
- **Primary**: Anthropic Direct (Tier 4, 500 RPM)
- **Backup**: Amazon Bedrock for redundancy
- **Strategy**: Volume monitoring, enterprise negotiations at scale

## 🛡️ Content & Compliance

### App Store Strategy
- **Apple**: 18+ rating (mature themes, NOT graphic content)
- **Google**: Mature 17+ rating  
- **Positioning**: "Premium Interactive Fiction Library"
- **Content**: R-rated text, adult themes, choice-driven narratives

### Security
- Server-side AES encryption for all game states
- Client never decrypts story data
- 18+ age verification on app launch
- Secure token validation through backend

## 🎭 UX Philosophy

*"Premium interactive fiction app that generates $10K+/month revenue while providing users with engaging, choice-driven adult content in a sophisticated, book-like mobile experience."*

The app prioritizes smooth animations, book-like reading experience, and premium feel over gamification elements. Every interaction should feel literary and sophisticated.