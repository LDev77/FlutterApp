\# Infiniteer MVP Design Kickoff Document



\## Project Overview



\*\*Infiniteer\*\* is a premium interactive fiction experience (IFE) mobile app featuring R-rated content with a Netflix-style browsing interface. Users purchase tokens to make choices in branching narrative stories, with a focus on adult/romance content alongside sci-fi and horror genres.



\### Key Value Propositions

\- Premium interactive fiction library with smooth, book-like UX

\- Text-based adult content that engages imagination 

\- Cross-platform Flutter app with token-based monetization

\- 18+/17+ rated content that stays within app store guidelines



\## Current Status (What We Have)



✅ \*\*Complete IFE Framework\*\* - Working interactive fiction engine  

✅ \*\*Functional API\*\* - Handles turn-based gameplay with state management  

✅ \*\*Web-based Testing System\*\* - POC working with family member validation  

✅ \*\*Content Pipeline\*\* - 15 starter stories ready to deploy  

✅ \*\*State Management\*\* - <150K per story (75K average), locally stored + API sync



\## API Provider Strategy



\### Anthropic Direct (Primary)

\- \*\*Current Status\*\*: Tier 4 (highest automatic tier)

\- \*\*Rate Limits\*\*: 500+ requests per minute  

\- \*\*Pricing\*\*: $3.00/$15.00 per million tokens (input/output)

\- \*\*Advantages\*\*: Better limits, direct relationship for enterprise negotiations

\- \*\*Monthly Budget\*\*: $5K = ~55,000 turns capacity



\### Amazon Bedrock (Backup)

\- \*\*Rate Limits\*\*: More restrictive (50 RPM for Claude 3.5 Sonnet vs 500 RPM direct)

\- \*\*Pricing\*\*: Similar standard rates, but latency-optimized Haiku available

\- \*\*Haiku Reality Check\*\*: Fails for complex IFE - interactive fiction requires Sonnet-level reasoning

\- \*\*Use Case\*\*: Backup/redundancy, potential future enterprise negotiations



\## Technical Architecture



\### Flutter Stack

\- \*\*Storage\*\*: Hive for local key-value state persistence (stores encrypted state blobs only)

\- \*\*Text Rendering\*\*: flutter\_markdown with custom streaming/fade-in animations

\- \*\*Payments\*\*: in\_app\_purchase package for cross-platform token purchases

\- \*\*HTTP\*\*: Standard http package for API communication with existing backend

\- \*\*Animations\*\*: Built-in Hero animations for smooth book cover transitions



\### App Store Strategy

\- \*\*Apple\*\*: 18+ rating (mature themes, sexual content - NOT graphic sexual content)

\- \*\*Google\*\*: Mature 17+ rating (equivalent to R-rated content)

\- \*\*Content Positioning\*\*: "Premium Interactive Fiction Library" 



\## Development Tools



\### Flutter Development Environment

\- \*\*IDE\*\*: VS Code (recommended by Flutter team)

&nbsp; - Flutter extension (by Dart Code team)

&nbsp; - Dart extension (by Dart Code team)

&nbsp; - Flutter Tree extension for widget visualization

\- \*\*Backend\*\*: Visual Studio 2022 for .NET API development

\- \*\*Rationale\*\*: VS Code provides first-class Flutter support with built-in Flutter Inspector, seamless Hot Reload, and device management



\### Backend Development

\- \*\*.NET 8.0+\*\* API with existing PlayController architecture

\- \*\*State Encryption\*\*: Built-in System.Security.Cryptography.Aes (server-side only)

\- \*\*Key Management\*\*: Environment variables or Azure Key Vault for production



\### State Management Architecture

```

Local Storage (Hive):

├── story\_1\_encrypted\_state (opaque encrypted blob)

├── story\_2\_encrypted\_state (opaque encrypted blob)  

├── user\_tokens (int)

└── story\_progress (metadata)



API Communication:

\- POST encrypted state blob on each user choice (client never decrypts)

\- Server decrypts, processes turn, encrypts new state

\- Receive next story segment + new encrypted state blob

\- Token validation/deduction



Encryption: Server-side only using .NET 8.0 System.Security.Cryptography.Aes

```



\## UI/UX Design Concept



\### Netflix-Style Library Interface

\*\*Main Screen\*\*: Horizontal scrolling rows by genre

\- Each "book" covers 50% screen width for peek-through effect

\- Vertical scrolling between genre rows

\- Smooth-as-silk scrolling with custom ScrollPhysics



\*\*Story Selection Flow\*\*:

1\. User taps paperback cover → \*\*Hero animation\*\* to full screen (GPU-accelerated)

2\. Cover art + marketing copy displayed with smooth transitions

3\. User can read free intro or continue existing progress

4\. Horizontal swipe navigation between story "pages"

5\. \*\*Flutter's animation system\*\* provides 60fps+ native-feeling transitions



\### Reading Experience

\- Full-screen immersive text display

\- Streaming text with sentence-by-sentence fade-in

\- Markdown support: titles, blockquotes, bold, italics, emojis

\- Choice options appear at decision points

\- Token cost displayed before choices



\## Content Strategy



\### Target Genres \& Market Reality

\- \*\*Adult/Romance (50% of usage)\*\*: "Kell's Co-ed Conundrum" as flagship

\- \*\*Sci-Fi (25%)\*\*: Variety and legitimacy 

\- \*\*Horror (15%)\*\*: Seasonal/mood-based content

\- \*\*Other (10%)\*\*: Experimental genres



\### Content Guidelines

\- \*\*R-rated text content\*\* - mature themes, sexual situations, adult language

\- \*\*No explicit sexual descriptions\*\* - stays under "graphic sexual content" threshold

\- \*\*18+ characters only\*\* - college/adult settings

\- \*\*Choice-driven narratives\*\* - user agency paramount



\## Monetization Model



\### Token Economics

\- \*\*Price Point\*\*: ~25¢ per turn (via token packs)

\- \*\*Token Packs\*\*: 

&nbsp; - 4 tokens for $0.99 (24.75¢/turn)

&nbsp; - 12 tokens for $1.99 (16.6¢/turn) 

&nbsp; - 25 tokens for $2.99 (12¢/turn)



\### Revenue Split Analysis

```

Per Turn Economics:

\- User Payment: $0.25

\- App Store Fee (30%): $0.075  

\- Claude API Cost: ~$0.09 (Sonnet required - Haiku fails for complex IFE)

\- Net Profit: ~$0.085 per turn

```



\*\*API Strategy\*\*: 

\- \*\*Primary\*\*: Anthropic Direct (currently Tier 4 - highest automatic tier)

\- \*\*Backup\*\*: Amazon Bedrock (more restrictive limits, similar pricing)

\- \*\*Budget\*\*: $5K/month = ~55,000 turns capacity

\- \*\*Volume Strategy\*\*: Launch with current economics, negotiate enterprise discounts at scale



\## App Store Compliance



\### Content Rating Strategy

\- \*\*Apple\*\*: 18+ with "Sexual Content or Nudity" (NOT "Graphic Sexual Content")

\- \*\*Google\*\*: "Mature 17+" rating

\- \*\*Marketing Copy\*\*: Focus on "interactive fiction," "mature themes," "choice-driven stories"



\### Age Verification

\- Simple 18+ confirmation gate on app launch

\- No complex ID verification required (just checkbox/date picker)

\- Leverage existing app store age verification systems



\## Development Roadmap



\### Phase 1: Flutter MVP (Weeks 1-2)

\- \[ ] Story library grid with genre rows

\- \[ ] Paperback cover UI with Hero animations (smooth zoom transitions)

\- \[ ] Hive local storage for encrypted state blobs (no client-side decryption)

\- \[ ] HTTP client integration with existing .NET API

\- \[ ] Simple token counter and choice gating

\- \[ ] Basic Flutter Inspector setup for UI debugging



\### Phase 2: Polish \& Monetization (Weeks 3-4)

\- \[ ] Token purchase flow with in\_app\_purchase

\- \[ ] Streaming text with markdown rendering

\- \[ ] Smooth scrolling optimization

\- \[ ] Age gate and app store compliance features

\- \[ ] Story progress tracking and resume functionality



\### Phase 3: Launch Prep (Week 5)

\- \[ ] App store screenshots and descriptions

\- \[ ] 18+/17+ rating questionnaire completion

\- \[ ] Beta testing with expanded family/friends

\- \[ ] Performance optimization and testing

\- \[ ] App store submission



\### Phase 4: Post-Launch (Ongoing)

\- \[ ] User analytics and behavior tracking

\- \[ ] A/B testing for token pricing

\- \[ ] Additional story content generation

\- \[ ] API cost optimization and bulk discounts

\- \[ ] Marketing and user acquisition



\## Success Metrics



\### Launch Targets (Month 1)

\- 1,000+ app downloads

\- 10%+ token purchase conversion rate

\- 5,000+ total turns played (well within $5K API budget)

\- 4.0+ app store rating



\### Growth Targets (Month 3)

\- 10,000+ monthly active users

\- 50,000+ turns per month (hitting API budget capacity)

\- $12,500+ monthly revenue ($5K API costs = $7,500+ profit)

\- Proven content-market fit for expansion

\- Enterprise API negotiation threshold reached



\## Risk Mitigation



\### Technical Risks

\- \*\*App store rejection\*\*: R-rated positioning, proper age rating

\- \*\*Performance\*\*: Flutter's GPU-accelerated animations provide smooth 60fps+ transitions out of the box

\- \*\*State security\*\*: Server-side encryption keeps game state completely opaque to clients

\- \*\*API costs\*\*: Volume monitoring, caching strategies



\### Business Risks

\- \*\*Content policy changes\*\*: Multiple genre strategy, legitimate library positioning

\- \*\*Market validation\*\*: Family testing, iterative content development

\- \*\*Competition\*\*: Premium UX differentiation, first-mover advantage in text-based adult IFE



\## Next Steps



1\. \*\*Week 1\*\*: Begin Flutter app skeleton with library UI

2\. \*\*Ongoing\*\*: Content refinement and additional story development

3\. \*\*Week 2\*\*: API integration and token system implementation

4\. \*\*Week 3\*\*: App store compliance and submission preparation



---



\*\*Success Vision\*\*: Premium interactive fiction app that generates $10K+/month revenue while providing users with engaging, choice-driven adult content in a sophisticated, book-like mobile experience.

