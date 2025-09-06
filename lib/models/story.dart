class Story {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final String genre;
  final String introText;
  final bool isAdult;
  final int estimatedTurns;

  const Story({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.genre,
    required this.introText,
    this.isAdult = false,
    this.estimatedTurns = 20,
  });
}

// Sample story data for development
class SampleStories {
  static const List<Story> adultRomance = [
    Story(
      id: 'kells_conundrum',
      title: "Kell's Co-ed Conundrum",
      description: 'Navigate complex relationships and steamy encounters in this college romance adventure.',
      coverUrl: 'https://picsum.photos/300/450?random=1',
      genre: 'Adult/Romance',
      introText: '''# Chapter 1: New Beginnings

**The crisp autumn air** fills your lungs as you step onto the university campus for the first time. 

*This is it,* you think to yourself. *The start of everything.*

As you walk across the quad, your eyes catch sight of someone who will change everything...''',
      isAdult: true,
      estimatedTurns: 25,
    ),
    Story(
      id: 'midnight_desires',
      title: 'Midnight Desires',
      description: 'A mysterious romance that unfolds in the shadows of the city night.',
      coverUrl: 'https://picsum.photos/300/450?random=2',
      genre: 'Adult/Romance',
      introText: '''# Prologue: The City After Dark

The neon lights of the city cast an **ethereal glow** on the rain-slicked streets.

> "Some encounters are destined to happen."

You pull your coat tighter and step into the night, unaware that your life is about to change forever...''',
      isAdult: true,
      estimatedTurns: 30,
    ),
  ];

  static const List<Story> sciFi = [
    Story(
      id: 'quantum_echo',
      title: 'Quantum Echo',
      description: 'Reality bends and time fractures in this mind-bending sci-fi thriller.',
      coverUrl: 'https://picsum.photos/300/450?random=3',
      genre: 'Sci-Fi',
      introText: '''# Log Entry 001: Anomaly Detected

**WARNING: Temporal distortion detected in Sector 7.**

The ship's AI speaks with its usual calm demeanor, but you can sense something is different. 

*The stars outside your viewport are... wrong.*

You've seen enough space to know when something defies the laws of physics...''',
      estimatedTurns: 22,
    ),
    Story(
      id: 'neural_interface',
      title: 'Neural Interface',
      description: 'Dive deep into cyberspace where digital consciousness meets human emotion.',
      coverUrl: 'https://picsum.photos/300/450?random=4',
      genre: 'Sci-Fi',
      introText: '''# Chapter 1: First Contact

The **neural interface** hums to life against your temple.

> "Ready for immersion, user?"

This is your first dive into the *Collective* - the shared digital consciousness that connects all of humanity.

But as the world dissolves around you, you realize something is watching from the shadows of cyberspace...''',
      estimatedTurns: 28,
    ),
  ];

  static const List<Story> horror = [
    Story(
      id: 'whispers_dark',
      title: 'Whispers in the Dark',
      description: 'Ancient secrets stir in an abandoned mansion where reality grows thin.',
      coverUrl: 'https://picsum.photos/300/450?random=5',
      genre: 'Horror',
      introText: '''# Entry 1: The Inheritance

The letter arrived on a **storm-darkened Tuesday**.

*"You have inherited the Blackwood Estate..."*

As you stand before the imposing Victorian mansion, its windows like dead eyes staring back at you, you wonder if some inheritances are better left unclaimed.

> The wind whispers secrets through the twisted oaks.

But the financial troubles that brought you here leave little choice...''',
      estimatedTurns: 24,
    ),
  ];

  static List<Story> getAllStories() {
    return [...adultRomance, ...sciFi, ...horror];
  }

  static List<Story> getStoriesByGenre(String genre) {
    return getAllStories().where((story) => story.genre == genre).toList();
  }
}