# Google Play Store Testing Setup Guide

**URGENT: 14-Day Testing Period Required**

This guide will help you set up the mandatory 14-day testing period for Google Play Store submission with in-app purchases.

## Overview

- **Testing Requirement**: 12-20 testers for 14 continuous days (varies by account type)
- **Products**: 4 token packs already configured in code
- **Revenue Model**: Consumable in-app purchases (Infiniteerium tokens)

## Phase 1: Google Play Console Setup (Day 1)

### 1. Create In-App Products

In Google Play Console → Your App → Monetization → Products:

**Create these 4 products exactly as specified:**

| Product ID | Name | Type | Price | Description |
|------------|------|------|-------|-------------|
| `tokens_starter_10` | Starter Token Pack | Consumable | $2.99 | Perfect for trying new stories - 10 tokens |
| `tokens_popular_25` | Popular Token Pack | Consumable | $6.99 | Most popular choice - 25 tokens |
| `tokens_power_50` | Power Token Pack | Consumable | $12.99 | Great value for avid readers - 50 tokens |
| `tokens_ultimate_100` | Ultimate Token Pack | Consumable | $24.99 | Maximum value for power users - 100 tokens |

**Important**: Product IDs must match exactly or purchases will fail.

### 2. Upload APK to Internal Testing Track

1. Build release APK: `flutter build apk --release`
2. Go to Play Console → Release → Testing → Internal testing
3. Upload APK
4. Complete store listing (use existing descriptions from app)

### 3. Set Up License Testing (For Development)

1. Play Console → Setup → License testing
2. Add your Gmail accounts as license testers
3. These accounts can test purchases without being charged

## Phase 2: Recruit Testers (Days 1-2)

### Tester Requirements
- Must have Gmail accounts
- Must install and actively use the app
- Must remain opted-in for the full 14 days
- Target: 15-20 testers (buffer above minimum 12)

### How to Add Testers
1. Play Console → Testing → Internal testing → Testers tab
2. Create email list or Google Group
3. Add tester emails
4. Send them the opt-in link

### Tester Instructions Email Template
```
Subject: Help Test Infiniteer App - Interactive Fiction Reading Experience

Hi [Name],

I need your help testing our new interactive fiction app called Infiniteer before we launch on Google Play Store.

What you need to do:
1. Click this link to opt-in: [INTERNAL_TEST_LINK]
2. Download and install the app
3. Create an account and try reading a story
4. Test the token purchase system (you won't be charged)
5. Use the app at least once every few days for 2 weeks

Requirements:
- Use the app for 14 continuous days (Google requirement)
- Don't opt-out during the testing period
- Report any bugs you find

Thanks for helping make Infiniteer amazing!
```

## Phase 3: Monitor Testing Period (Days 1-14)

### Daily Checklist
- [ ] Check tester retention in Play Console
- [ ] Monitor crash reports
- [ ] Review tester feedback
- [ ] Ensure 12+ testers remain active

### Warning Signs
- Testers dropping out (need backups)
- App crashes affecting retention
- Purchase flow errors

## Phase 4: Technical Testing Focus

### In-App Purchase Testing
The app is configured to work with these test scenarios:

1. **License Testers**: Use your added license tester accounts
   - Purchases won't be charged
   - Full purchase flow testing

2. **Test Cards**: Play Console provides test payment methods
   - Test successful purchases
   - Test failed purchases
   - Test cancellations

### Backend Integration Testing
- Server validation at: `https://infiniteer.azurewebsites.net/api/purchase/validate`
- API expects this format:
```json
{
  "userId": "user-uuid",
  "platform": "android",
  "platformId": "purchase-token",
  "transactionId": "transaction-id",
  "sku": "tokens_starter_10"
}
```

## Phase 5: Production Submission (Day 15+)

### Pre-Submission Checklist
- [ ] 14 days completed with 12+ active testers
- [ ] All critical bugs fixed
- [ ] Store listing complete
- [ ] Privacy policy published
- [ ] Content rating completed
- [ ] All in-app products published

### Submission Process
1. Create production release
2. Upload signed APK
3. Complete review questionnaire
4. Submit for review (can take 1-7 days)

## Common Issues & Solutions

### "Products Not Found" Error
- Ensure products are published in Play Console
- Check product IDs match exactly
- Products must be in same developer account

### "Testing Requirements Not Met"
- Check tester count in Play Console
- Verify continuous 14-day period
- Some testers may have opted out

### Purchase Validation Failures
- Check backend server is running
- Verify API endpoint matches in `TokenPurchaseService`
- Test with license tester accounts first

## Testing Commands

```bash
# Build release APK
flutter build apk --release

# Build App Bundle (recommended for production)
flutter build appbundle --release

# Debug build for development
flutter run --debug
```

## Emergency Contacts

If issues arise during testing:
- Check app logs: `flutter logs`
- Monitor server logs at Azure
- Contact testers immediately if critical bugs found

## Timeline Summary

| Day | Tasks |
|-----|--------|
| 1 | Set up Play Console, upload APK, recruit testers |
| 2-14 | Monitor testing, fix critical issues, maintain tester engagement |
| 15+ | Submit for production review |

**Start immediately to meet launch deadlines!**