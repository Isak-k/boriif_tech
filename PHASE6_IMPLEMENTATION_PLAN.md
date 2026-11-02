# PHASE 6: Real-Time Publishing and External App Launch - Implementation Plan

## Overview
Complete the end-to-end publishing workflow with real-time updates, external link handling, view counting, and favorites persistence.

## Key Components to Build

### 1. Real-Time Services Enhancement
- **Enhanced PostService**: Add stream listeners for real-time updates
- **URL Validator Service**: Validate and safely handle Play Store URLs
- **View Count Service**: Implement trusted view counting with abuse prevention
- **Favorites Persistence Service**: Local persistence for favorites

### 2. URL Launcher and Link Handling
- Add `url_launcher` dependency
- Create `LinkLauncherService` for safe URL opening
- Validate Play Store URLs before launching
- Handle fallbacks and errors

### 3. Enhanced UI Components
- **Post Details Screen**: Add "Get it now" button with proper styling
- **Post Card Widget**: Show image, title, category, publication date
- **Link Action Handlers**: Safe opening with error dialogs

### 4. Real-Time Updates
- Use Firestore streams for automatic updates
- Remove manual refresh requirements
- Handle publication state changes (publish/unpublish/delete)
- Update UI when posts change

### 5. Favorites Persistence
- Local storage for anonymous users
- Cross-session persistence
- Handle deleted/unpublished posts gracefully

### 6. View Count Implementation
- Track meaningful post-detail views only
- Prevent abuse (repeated increments from rebuilds)
- Use debouncing for increment operations
- Provide user explanation

## Files to Create/Modify

### New Files
- `lib/services/url_launcher_service.dart` - URL validation and launching
- `lib/services/view_count_service.dart` - View count management
- `lib/services/favorites_service.dart` - Local favorites persistence
- `lib/widgets/get_it_now_button_widget.dart` - Reusable button component
- `lib/widgets/post_link_handler_widget.dart` - Link handling logic
- `PHASE6_COMPLETE.md` - Implementation summary

### Modified Files
- `pubspec.yaml` - Add url_launcher dependency
- `lib/services/post_service.dart` - Add stream listeners, view count logic
- `lib/providers/post_provider.dart` - Add real-time listening, favorites sync
- `lib/features/post_details/screens/post_details_screen.dart` - Add Get it now button, real-time updates
- `lib/models/post_model.dart` - Add lastViewedAt field for debouncing

## Implementation Steps

1. Add url_launcher dependency to pubspec.yaml
2. Create URL launcher service with validation
3. Create view count service with abuse prevention
4. Create favorites persistence service
5. Enhance PostService with real-time streams
6. Create reusable Get it now button widget
7. Update post details screen with external link handling
8. Update post provider with real-time listening
9. Test full workflow end-to-end
10. Document in PHASE6_COMPLETE.md

## Acceptance Criteria
- [ ] Admin publishes app → appears automatically in feed
- [ ] Edit to post → feed and details update automatically
- [ ] Unpublish post → disappears from public screens
- [ ] Delete post → disappears from public screens
- [ ] Get it now button visible and functional
- [ ] Play Store URLs validate and open correctly
- [ ] View counts increment correctly without abuse
- [ ] Favorites persist across app restarts
- [ ] Deleted/unpublished posts handled in favorites
- [ ] Error handling for invalid URLs
- [ ] Works on emulator and physical device
