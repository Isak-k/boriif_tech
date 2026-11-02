# PHASE 5 Testing Checklist

## Pre-Testing Requirements

### ✓ Environment Setup
- [ ] Flutter SDK installed (^3.12.1)
- [ ] Firebase project configured
- [ ] Admin user account created in `admins` collection
- [ ] At least one category created
- [ ] Firebase Storage configured
- [ ] Security rules deployed (if needed)

### ✓ Device/Emulator
- [ ] Android emulator/device ready
- [ ] iOS simulator/device ready (if testing iOS)
- [ ] Device has sufficient storage for testing
- [ ] Camera/gallery access enabled

### ✓ Test Data
- [ ] Test admin account exists
- [ ] Test categories exist (2-3)
- [ ] Optional: Some existing posts in database

---

## Feature Testing

### 1. Admin Dashboard Tests ✓

#### Dashboard Loading
- [ ] Dashboard loads without errors
- [ ] Statistics cards display
- [ ] Recent posts load (if any exist)
- [ ] Quick action buttons visible
- [ ] Sign out button visible

#### Statistics Display
- [ ] Total Posts shows correct count
- [ ] Published Posts shows correct count
- [ ] Total Views shows aggregated count
- [ ] Categories shows correct count
- [ ] Statistics update in real-time (create post and return)
- [ ] Numbers format correctly (1K, 1M for large numbers)

#### Recent Posts Feed
- [ ] Shows up to 5 recent posts
- [ ] Thumbnails display correctly
- [ ] Titles display correctly
- [ ] Short descriptions display
- [ ] Type badges show (app/article/job)
- [ ] Status badges show (published/draft)
- [ ] View count displays
- [ ] Empty state shows when no posts exist

#### Loading States
- [ ] Loading indicators show while data loads
- [ ] Skeleton loaders display appropriately
- [ ] Content appears after loading
- [ ] No crashes during loading

#### Error Handling
- [ ] Network errors handled gracefully
- [ ] Error messages display
- [ ] Retry functionality works
- [ ] No infinite loading states

---

### 2. Post Management Screen Tests ✓

#### Page Loading
- [ ] Post management page loads
- [ ] Post list displays all posts
- [ ] New posts appear in list
- [ ] Drafts and published mix in list
- [ ] Empty state shows when no posts

#### Search Functionality
- [ ] Search field accepts input
- [ ] Typing filters posts
- [ ] Partial title matches work
- [ ] Description search works
- [ ] Clear search shows all posts
- [ ] Search results update in real-time

#### Status Filter
- [ ] "All" shows all posts
- [ ] "Published" shows only published posts
- [ ] "Draft" shows only draft posts
- [ ] Filter persists when switching
- [ ] Empty state shows when no results

#### Type Filter
- [ ] "All" shows all types
- [ ] "app" shows only app posts
- [ ] "article" shows only article posts
- [ ] "job" shows only job posts
- [ ] Filters combine (status + type)
- [ ] Empty state shows when no results

#### Post List Display
- [ ] Post cards show thumbnail
- [ ] Post cards show title
- [ ] Post cards show badges
- [ ] Post cards show metadata (date, views)
- [ ] Multiple posts display in scrollable list

#### Inline Actions
- [ ] Edit button works (opens edit screen)
- [ ] Publish button works (for drafts)
- [ ] Unpublish button works (for published)
- [ ] Delete button works (with confirmation)
- [ ] Menu opens/closes properly
- [ ] Multiple posts can have actions performed

#### Create Button
- [ ] FAB visible
- [ ] FAB clickable
- [ ] Navigates to create post screen

#### Error Handling
- [ ] Handles no results gracefully
- [ ] Shows loading states
- [ ] Shows error messages
- [ ] Retry on failure

---

### 3. Create/Edit Post Screen Tests ✓

#### Form Fields Validation

##### Title Field
- [ ] Accepts text input
- [ ] Shows validation error if empty
- [ ] Shows validation error if < 3 chars
- [ ] Accepts valid titles
- [ ] Pre-fills with existing title (edit mode)

##### Short Description
- [ ] Accepts text input
- [ ] Shows validation error if empty
- [ ] Shows validation error if < 10 chars
- [ ] Shows validation error with special chars
- [ ] Accepts valid descriptions
- [ ] Pre-fills in edit mode

##### Full Description
- [ ] Accepts multi-line text
- [ ] Shows validation error if empty
- [ ] Shows validation error if < 20 chars
- [ ] Accepts long descriptions
- [ ] Pre-fills in edit mode

##### Post Type Selector
- [ ] Shows all three options (app, article, job)
- [ ] Can select app
- [ ] Can select article
- [ ] Can select job
- [ ] Pre-fills with existing type (edit mode)
- [ ] Selection persists

##### Category Dropdown
- [ ] Shows all categories
- [ ] Can select category
- [ ] Shows error if not selected
- [ ] Pre-fills with existing category (edit mode)
- [ ] Categories load dynamically

##### Play Store URL (App Only)
- [ ] Shows for app posts only
- [ ] Hidden for article/job posts
- [ ] Required for app posts
- [ ] Optional validation (basic URL)
- [ ] Persists in edit mode

##### External URL (Article/Job)
- [ ] Shows for article/job posts only
- [ ] Hidden for app posts
- [ ] Optional for article/job
- [ ] Basic URL validation
- [ ] Persists in edit mode

##### Status Toggle
- [ ] Shows Draft/Publish options
- [ ] Can toggle between them
- [ ] Default is Draft
- [ ] Pre-fills with existing status (edit mode)

#### Image Upload

##### Image Picker
- [ ] Can tap image area
- [ ] Opens gallery on tap
- [ ] Can select image
- [ ] Shows preview of selected image
- [ ] Can remove image (X button)

##### Upload Process
- [ ] Shows loading indicator while uploading
- [ ] Shows upload progress
- [ ] Completes without errors
- [ ] Shows success feedback
- [ ] URL saved to form

##### Image Validation
- [ ] Accepts various formats (jpg, png, gif)
- [ ] Shows error for invalid files
- [ ] Shows error for oversized files (if limit set)
- [ ] Validates before upload

##### App Posts
- [ ] Image required for app posts
- [ ] Error shown if no image selected
- [ ] Can't publish app without image

#### Form Submission

##### Create New Post
- [ ] Can fill all required fields
- [ ] Can submit form
- [ ] Draft posts created successfully
- [ ] Published posts created successfully
- [ ] Success message shown
- [ ] Returns to management screen
- [ ] New post appears in list

##### Edit Existing Post
- [ ] Opens with existing data pre-filled
- [ ] Can modify title
- [ ] Can modify description
- [ ] Can change image
- [ ] Can change status
- [ ] Can change category
- [ ] Preserves creation timestamp
- [ ] Updates published_at on first publish only
- [ ] Success message shown
- [ ] Returns to management screen
- [ ] Changes appear in list

##### Validation Errors
- [ ] Shows error if title empty
- [ ] Shows error if description empty
- [ ] Shows error if category not selected
- [ ] Shows error if app without Play Store URL
- [ ] Shows error if app without image
- [ ] Multiple errors show
- [ ] Prevents submission with errors

#### Error Handling
- [ ] Handles network errors
- [ ] Handles image upload failures
- [ ] Shows meaningful error messages
- [ ] Allows retry on failure

---

### 4. Category Management Tests ✓

#### Category List
- [ ] Displays all categories
- [ ] Shows category names
- [ ] Shows category IDs
- [ ] Empty state when no categories
- [ ] Scrollable if many categories

#### Create Category
- [ ] Create button visible
- [ ] Opens create dialog
- [ ] Can enter category name
- [ ] Shows validation error if empty
- [ ] Creates category successfully
- [ ] Success message shown
- [ ] Category appears in list
- [ ] Dialog closes after creation

#### Edit Category
- [ ] Edit button in menu
- [ ] Opens edit dialog
- [ ] Pre-fills with current name
- [ ] Can change name
- [ ] Saves changes successfully
- [ ] Success message shown
- [ ] List updates
- [ ] Dialog closes after edit

#### Delete Category

##### Without Associated Posts
- [ ] Delete button in menu
- [ ] Opens delete dialog
- [ ] Shows confirmation message
- [ ] Can confirm delete
- [ ] Category deleted successfully
- [ ] Success message shown
- [ ] Category removed from list

##### With Associated Posts
- [ ] Delete button in menu
- [ ] Opens delete dialog
- [ ] Shows error message
- [ ] Shows number of associated posts
- [ ] Delete button disabled
- [ ] Can cancel dialog
- [ ] Category remains in list

#### Error Handling
- [ ] Shows errors clearly
- [ ] Handles network failures
- [ ] Retry functionality works
- [ ] No crashes on operations

---

### 5. Authorization & Security Tests ✓

#### Admin Access
- [ ] Admin can access dashboard
- [ ] Admin can create posts
- [ ] Admin can edit posts
- [ ] Admin can delete posts
- [ ] Admin can manage categories

#### Non-Admin Access (if applicable)
- [ ] Non-admin cannot access admin dashboard
- [ ] Non-admin cannot create posts
- [ ] Non-admin cannot edit posts
- [ ] Non-admin cannot delete posts
- [ ] Appropriate error shown

#### Permission Checks
- [ ] All operations verify admin status
- [ ] No bypassing security checks
- [ ] Error messages on permission denial

---

### 6. Publishing Workflow Tests ✓

#### Draft to Published
- [ ] Create post as draft
- [ ] Post shows Draft badge
- [ ] Post not visible in public feed
- [ ] Can open post in management
- [ ] Can publish from menu
- [ ] Status changes to Published
- [ ] Badge changes to Published
- [ ] publishedAt timestamp set

#### Published to Draft
- [ ] Publish post initially
- [ ] Post shows Published badge
- [ ] Can unpublish from menu
- [ ] Status changes to Draft
- [ ] Badge changes to Draft
- [ ] Post still has publishedAt (not cleared)
- [ ] Creation timestamp unchanged

#### Edit Published Post
- [ ] Can edit published post
- [ ] Changes appear after edit
- [ ] Publication timestamp unchanged
- [ ] Update timestamp changed
- [ ] Post remains published

---

### 7. Real-Time Updates Tests ✓

#### Statistics Updates
- [ ] Create post in management
- [ ] Return to dashboard
- [ ] Total posts incremented
- [ ] Published count updated (if published)
- [ ] Recent posts shows new post
- [ ] View count updates

#### Post List Updates
- [ ] Create post from dashboard
- [ ] Post appears in management list immediately
- [ ] Edit post in management
- [ ] Changes appear immediately
- [ ] Delete post
- [ ] Post removed immediately

#### Category Updates
- [ ] Create category
- [ ] Available in post form immediately
- [ ] Delete category
- [ ] Removed from options
- [ ] Edit category name
- [ ] Updated in list

---

### 8. Data Persistence Tests ✓

#### Image Storage
- [ ] Image uploaded to Firebase Storage
- [ ] Image URL saved to post
- [ ] Image accessible via URL
- [ ] Image persists after close/reopen
- [ ] Storage path correct (posts/{id}/...)

#### Post Data
- [ ] All post fields saved correctly
- [ ] Timestamps correct
- [ ] Publish status persists
- [ ] Category reference correct
- [ ] Changes persist after close/reopen

#### Timestamps
- [ ] createdAt set on creation
- [ ] createdAt unchanged on edit
- [ ] updatedAt changed on edit
- [ ] publishedAt set on first publish
- [ ] publishedAt unchanged on edit

---

### 9. Navigation & UI Tests ✓

#### Screen Navigation
- [ ] Can navigate from dashboard to post management
- [ ] Can navigate back
- [ ] Can navigate to create post screen
- [ ] Can navigate back from create
- [ ] Can navigate to category management
- [ ] Can navigate back from categories
- [ ] All transitions smooth

#### UI Responsiveness
- [ ] Layouts work on small screens
- [ ] Layouts work on large screens
- [ ] Text readable on all sizes
- [ ] Buttons accessible on all sizes
- [ ] Images scale appropriately
- [ ] No overlap of elements

#### Loading States
- [ ] Loading indicators show
- [ ] Content appears when ready
- [ ] No visual glitches
- [ ] Smooth transitions

---

### 10. Error Scenarios Tests ✓

#### Network Errors
- [ ] Handles offline gracefully
- [ ] Error message shown
- [ ] Retry option available
- [ ] No crashes

#### Data Errors
- [ ] Handles missing images
- [ ] Handles invalid URLs
- [ ] Handles missing categories
- [ ] Handles corrupted timestamps
- [ ] Error messages helpful

#### Edge Cases
- [ ] Very long titles handled
- [ ] Very long descriptions handled
- [ ] Special characters in descriptions
- [ ] Unicode characters handled
- [ ] Empty images folder
- [ ] No categories exist

---

## Integration Testing

### Cross-Feature Tests ✓

#### Create → Manage → Edit → Publish → Delete
- [ ] Create new post
- [ ] Appears in management
- [ ] Can edit successfully
- [ ] Can publish
- [ ] Shows in recent/dashboard
- [ ] Can unpublish
- [ ] Can delete
- [ ] Removed from everywhere

#### Category → Post Relationship
- [ ] Create category
- [ ] Create post with category
- [ ] Edit post category
- [ ] Delete category with posts (fails correctly)
- [ ] Reassign posts
- [ ] Delete category (succeeds)

#### Image → Post Relationship
- [ ] Upload image
- [ ] Image in post
- [ ] Edit and change image
- [ ] Old image handled
- [ ] Delete post with image
- [ ] Check storage cleanup

---

## Performance Testing

### Load Testing ✓
- [ ] Dashboard loads in <2 seconds
- [ ] Post list loads in <2 seconds
- [ ] Create form opens in <1 second
- [ ] Submit form completes in <5 seconds
- [ ] Image upload completes (depends on size)
- [ ] Statistics refresh completes in <3 seconds

### Memory Testing ✓
- [ ] No memory leaks on navigation
- [ ] No memory leaks on submit
- [ ] No memory leaks on delete
- [ ] Long list performance acceptable

### Battery Testing ✓
- [ ] Real-time updates don't drain battery
- [ ] Image uploads don't use excessive bandwidth
- [ ] Reasonable background activity

---

## Device Testing

### Android Testing ✓
- [ ] Test on Android 8+ emulator
- [ ] Test on Android 12+ emulator
- [ ] Test on physical Android device (if available)
- [ ] Verify permissions work
- [ ] Gallery access works
- [ ] Image upload works

### iOS Testing ✓
- [ ] Test on iOS simulator
- [ ] Test on physical iOS device (if available)
- [ ] Verify permissions work
- [ ] Photo library access works
- [ ] Image upload works

---

## Compliance Testing

### Security ✓
- [ ] No sensitive data exposed in logs
- [ ] Admin check on all operations
- [ ] URLs safe to display
- [ ] No SQL injection vectors

### Accessibility ✓
- [ ] Text sizes readable
- [ ] Colors have sufficient contrast
- [ ] Buttons large enough to tap
- [ ] Labels clear and descriptive
- [ ] No flashing elements

### Data Validation ✓
- [ ] All inputs validated
- [ ] No empty submissions
- [ ] No invalid data stored
- [ ] Validation messages helpful

---

## Sign-Off

### Test Execution
- [ ] All tests executed
- [ ] All tests passed
- [ ] Issues documented
- [ ] Issues resolved or tracked

### Quality Gate
- [ ] No critical issues
- [ ] No unresolved bugs
- [ ] Performance acceptable
- [ ] Security verified
- [ ] UX acceptable

### Approval
- [ ] QA Lead Sign-off: _______________
- [ ] Tech Lead Sign-off: _______________
- [ ] Product Owner Sign-off: _______________

### Date Completed: _______________

---

## Known Issues (if any)

Issue #1:
- Description: 
- Severity: 
- Workaround: 
- Status: 

Issue #2:
- Description: 
- Severity: 
- Workaround: 
- Status: 

---

## Test Report Summary

**Total Test Cases**: 100+
**Passed**: ____
**Failed**: ____
**Skipped**: ____
**Success Rate**: _____%

**Overall Status**: 
- [ ] PASS - Ready for deployment
- [ ] PASS WITH ISSUES - Deploy with caution
- [ ] FAIL - Do not deploy

---

## Notes

Use this space for additional notes, observations, or recommendations:

________________________________________________________________________

________________________________________________________________________

________________________________________________________________________

---

**Testing Completed By**: _______________
**Date**: _______________
**Phone/Contact**: _______________

---

End of Testing Checklist
