import '../models/turn_data.dart';

class SampleData {
  static StoryPlaythrough createTestStoryPlaythrough() {
    final now = DateTime.now();
    
    final turns = [
      // Turn 1 - Short page
      TurnData(
        narrativeMarkdown: '''# Test Story - Turn 1

**This is the first page** of our test story.

*Welcome to the interactive fiction experience!*

You find yourself standing at the entrance of a mysterious library. The ancient wooden doors creak slightly in the wind, and you can smell the musty scent of old books mixed with something else... something magical.

> "Every story begins with a single choice."

What will you do?''',
        userInput: '[Story Beginning]',
        availableOptions: ['Enter the library', 'Walk around the building', 'Knock on the door'],
        encryptedGameState: 'encrypted_state_turn_1_3kb_blob',
        timestamp: now.subtract(const Duration(minutes: 20)),
        turnNumber: 1,
      ),
      
      // Turn 2 - Medium page
      TurnData(
        narrativeMarkdown: '''# Test Story - Turn 2

**You decided to enter the library.**

The heavy wooden door opens with a prolonged creak that echoes through the vast interior. Before you stretches an enormous hall filled with towering bookshelves that seem to reach up into shadows beyond sight.

*The air hums with an otherworldly energy.*

As you step inside, you notice:

- **Floating books** drift lazily between the shelves
- **Glowing orbs** provide soft illumination 
- **Whispered conversations** echo from unseen corners

A figure emerges from behind a nearby shelf - an elderly librarian with knowing eyes and a warm smile.

> "Welcome, traveler. I've been expecting you."

She gestures to three different sections of the library.''',
        userInput: 'I enter the library cautiously, looking around in wonder.',
        availableOptions: ['Ask about the floating books', 'Head to the history section', 'Follow the whispers'],
        encryptedGameState: 'encrypted_state_turn_2_3kb_blob',
        timestamp: now.subtract(const Duration(minutes: 18)),
        turnNumber: 2,
      ),
      
      // Turn 3 - Long page (longer than typical screen)
      TurnData(
        narrativeMarkdown: '''# Test Story - Turn 3: The History Section

**You make your way toward the history section.**

The librarian nods approvingly as you choose your path. "Ah, a seeker of knowledge and truth. The history section holds many secrets."

*As you walk deeper into the library, the very architecture seems to shift and change around you.*

The shelves here are different - older, made of a dark wood that seems to absorb light rather than reflect it. The books themselves appear ancient, their leather bindings cracked with age, and some seem to **glow faintly** with inner light.

You notice several particularly interesting volumes:

## The Chronicle of Lost Worlds
*A massive tome bound in scales that shimmer with iridescent colors*

This book seems to be writing itself - you can see words appearing on pages as they flutter in an unfelt breeze. The text describes civilizations that never existed in our world, technologies beyond imagination, and heroes whose names echo through dimensions.

## The Mirror of What Was
*A book with pages that look like liquid silver*

When you look at this book, instead of text, you see moving images - like looking into memories that aren't your own. You catch glimpses of ancient battles, forgotten love stories, and moments of triumph and tragedy that shaped the world in ways no history book could capture.

## The Whisper Codex
*A slim volume that seems to vibrate with contained energy*

This book doesn't just contain words - it contains actual whispers, trapped between its pages. When you lean close, you can hear voices from the past sharing secrets, warnings, and prophecies. Some whispers are in languages you don't recognize, others speak directly to your soul.

The librarian appears beside you, her footsteps making no sound on the ancient wooden floors.

> "These are not mere books, dear traveler. They are gateways - windows into truths that exist beyond the boundaries of normal reality. But choose carefully, for once you open one of these volumes, you cannot unknow what you learn."

*The air around you seems to thicken with anticipation.*

You feel a strange pull toward all three books, but you can only choose one. Your choice here will determine not just what you learn, but who you become in this mystical place.

The floating orbs of light seem to pulse in rhythm with your heartbeat, and you swear you can hear the very library itself holding its breath, waiting for your decision.

What will you choose?''',
        userInput: 'I head toward the history section, drawn by the promise of ancient knowledge.',
        availableOptions: ['Open The Chronicle of Lost Worlds', 'Look into The Mirror of What Was', 'Listen to The Whisper Codex'],
        encryptedGameState: 'encrypted_state_turn_3_3kb_blob',
        timestamp: now.subtract(const Duration(minutes: 15)),
        turnNumber: 3,
      ),
      
      // Turn 4 - Medium page
      TurnData(
        narrativeMarkdown: '''# Test Story - Turn 4: The Mirror of What Was

**You choose to look into The Mirror of What Was.**

As your fingers touch the liquid silver pages, the world around you dissolves into a cascade of memories and visions.

*You are no longer in the library - you are experiencing history itself.*

The images flow through your consciousness:

- **Ancient civilizations** rising and falling like waves
- **Heroes and villains** whose choices echo through time
- **Love stories** that transcend the boundaries of life and death
- **Moments of decision** that changed the course of everything

You see yourself in these visions - not as you are now, but as you were in countless other lives, other possibilities. You witness your own heroic deeds and terrible mistakes across the span of eternity.

> "Time is not a river," whispers a voice that might be your own, "but an ocean where all moments exist simultaneously."

When the visions finally fade, you find yourself back in the library, but something has changed. You can now see the *true* nature of things - the threads of possibility that connect all choices, all outcomes.

The librarian smiles at you with ancient wisdom in her eyes.''',
        userInput: 'I reach out and touch the Mirror of What Was, despite the warning.',
        availableOptions: ['Ask the librarian about what you saw', 'Explore more of the library', 'Try to return to your own world'],
        encryptedGameState: 'encrypted_state_turn_4_3kb_blob',
        timestamp: now.subtract(const Duration(minutes: 10)),
        turnNumber: 4,
      ),
      
      // Turn 5 - Short page (current turn)
      TurnData(
        narrativeMarkdown: '''# Test Story - Turn 5: The Revelation

**You ask the librarian about your visions.**

She nods knowingly, her eyes twinkling with starlight. "You have seen the truth that lies beneath all stories, all lives, all choices. You now understand that every decision creates ripples across infinite possibilities."

*The library around you begins to shimmer and shift.*

"This is where all stories begin and end," she explains. "You are both the reader and the character, the author and the audience. The question now is..."

> "What story will you choose to write next?"

*The adventure continues...*''',
        userInput: 'I ask the librarian to explain what I saw in the mirror.',
        availableOptions: ['Write a new story', 'Return to the beginning', 'Step into another book'],
        encryptedGameState: 'encrypted_state_turn_5_3kb_blob',
        timestamp: now.subtract(const Duration(minutes: 5)),
        turnNumber: 5,
      ),
    ];
    
    return StoryPlaythrough(
      storyId: 'Test Story',
      turnHistory: turns,
      currentTurnIndex: 4, // 0-based index, so 4 means turn 5
      lastTurnDate: now.subtract(const Duration(minutes: 5)),
      numberOfTurns: 5,
      endingDescription: null, // Story not yet complete
    );
  }
}