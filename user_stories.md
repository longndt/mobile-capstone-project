# User Stories - Educational Mobile App

## Overview
This document contains **9 user stories** for an educational mobile app. The stories cover authentication, core navigation screens, data persistence, external API integration, settings, and notifications.

---

## 1) Registration Screen
**As a** new learner,  
**I want** to create an account using email/phone and password,  
**so that** I can save my progress and access the app across devices.

**Acceptance criteria (optional):**
- User can enter name, email/phone, and password.
- Input validation is shown for invalid formats.
- User receives success/error feedback after registration.

---

## 2) Login Screen
**As a** returning learner,  
**I want** to log in securely,  
**so that** I can continue my courses and learning progress.

**Acceptance criteria (optional):**
- User can log in with registered credentials.
- Incorrect credentials show a clear error message.
- Session is persisted until logout (unless token expires).

---

## 3) Home Screen - Course Overview
**As a** learner,  
**I want** a home screen that shows my enrolled courses and progress,  
**so that** I can quickly resume learning.

**Acceptance criteria (optional):**
- Home screen displays course cards (title, thumbnail, progress).
- User can tap a course to open details.
- Recently viewed lessons are visible.

---

## 4) Home Screen - Search and Recommendations
**As a** learner,  
**I want** to search for courses and see recommended content on the home screen,  
**so that** I can discover relevant lessons easily.

**Acceptance criteria (optional):**
- Search bar supports keyword search.
- Recommended courses are displayed based on activity/interests.
- Empty state is shown when no results are found.

---

## 5) Detail Screen - Course/Lesson Information
**As a** learner,  
**I want** a detail screen for each course/lesson with description, syllabus, and content preview,  
**so that** I can understand what I will learn before starting.

**Acceptance criteria (optional):**
- Detail screen shows title, description, instructor, and lesson list.
- User can start/resume a lesson from the detail screen.
- Locked/unavailable content is clearly indicated.

---

## 6) Integrate Persistent Data (Local/Database Storage)
**As a** learner,  
**I want** my progress, preferences, and recent activity to be stored persistently,  
**so that** I do not lose data after closing or reopening the app.

**Acceptance criteria (optional):**
- Learning progress is saved after lesson completion.
- App restores progress when reopened.
- User settings persist across sessions.

---

## 7) Integrate External API (Course and Content Data)
**As a** learner,  
**I want** the app to load course content and updates from an external API,  
**so that** I can access up-to-date lessons, quizzes, and metadata.

**Acceptance criteria (optional):**
- App fetches course list and detail data from API.
- Loading/error states are handled gracefully.
- Parsed API data is displayed correctly on home/detail screens.

---

## 8) Implement Settings Screen
**As a** learner,  
**I want** a settings screen to manage language, theme, and account preferences,  
**so that** I can personalize my learning experience.

**Acceptance criteria (optional):**
- User can change theme (light/dark).
- User can select app language.
- User can manage account options (logout, profile settings).

---

## 9) Implement Notifications
**As a** learner,  
**I want** to receive notifications for study reminders, new lessons, and deadlines,  
**so that** I stay consistent and do not miss important learning activities.

**Acceptance criteria (optional):**
- User can enable/disable notifications.
- App sends reminder notifications based on schedule.
- Notifications open the relevant course/lesson when tapped.

---
