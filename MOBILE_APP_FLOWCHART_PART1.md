# HatiCare Mobile App - Complete Flowchart & User Journeys (Part 1)

---

## Table of Contents
1. [App Navigation Structure](#app-navigation-structure)
2. [Patient Journey](#patient-journey)
3. [Doctor Journey](#doctor-journey)

---

## App Navigation Structure

### Main App Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    HATICARE MOBILE APP                              │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      SPLASH SCREEN                                  │
│  - Check user logged in?                                            │
│  - Check profile completed?                                         │
│  - Load cached data                                                 │
└─────────────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┼─────────────┐
                │             │             │
         ┌──────▼──────┐ ┌───▼────┐ ┌─────▼──────┐
         │ NOT LOGGED  │ │PROFILE │ │   LOGGED   │
         │   IN        │ │INCOMPLETE│ IN & READY │
         └──────┬──────┘ └───┬────┘ └─────┬──────┘
                │            │            │
         ┌──────▼──────┐ ┌───▼────┐ ┌─────▼──────────────┐
         │ LOGIN/SIGNUP│ │COMPLETE│ │ ROLE-BASED HOME   │
         │   SCREEN    │ │PROFILE │ │ - Patient Home    │
         │             │ │SCREEN  │ │ - Doctor Home     │
         │             │ │        │ │ - Pharmacy Home   │
         │             │ │        │ │ - Clinic Home     │
         └─────────────┘ └────────┘ └───────────────────┘
```

---

## Patient Journey

### 1. Patient Authentication Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                  PATIENT LOGIN/SIGNUP FLOW                          │
└─────────────────────────────────────────────────────────────────────┘

START
  │
  ▼
┌──────────────────────────────┐
│  SPLASH SCREEN               │
│  - Load app                  │
│  - Check login status        │
└──────────────────────────────┘
  │
  ├─→ User logged in? ──YES──→ Check profile complete?
  │                                    │
  │                            ┌───────┴────────┐
  │                            │                │
  │                        YES │                │ NO
  │                            │                │
  │                            ▼                ▼
  │                      PATIENT HOME    COMPLETE PROFILE
  │                                      (Phone, Name, DOB,
  │                                       Gender, Address)
  │
  └─→ NO
      │
      ▼
┌──────────────────────────────┐
│  LOGIN/SIGNUP SCREEN         │
│  - Phone number input        │
│  - OTP verification          │
│  - Password setup            │
└──────────────────────────────┘
      │
      ├─→ Existing user? ──YES──→ LOGIN
      │                             │
      │                             ▼
      │                      ┌──────────────────┐
      │                      │ VERIFY OTP       │
      │                      │ - Enter OTP      │
      │                      │ - Resend OTP     │
      │                      └──────────────────┘
      │                             │
      │                             ▼
      │                      PATIENT HOME
      │
      └─→ NO
          │
          ▼
      ┌──────────────────────────────┐
      │  SIGNUP SCREEN               │
      │  - Phone number              │
      │  - Email (optional)          │
      │  - Password                  │
      │  - Confirm password          │
      │  - Terms & conditions        │
      │  - Consent checkbox          │
      └──────────────────────────────┘
          │
          ▼
      ┌──────────────────────────────┐
      │  VERIFY OTP                  │
      │  - Enter 6-digit OTP         │
      │  - Resend option             │
      │  - Timer (5 min)             │
      └──────────────────────────────┘
          │
          ▼
      ┌──────────────────────────────┐
      │  COMPLETE PATIENT PROFILE    │
      │  - Full name                 │
      │  - Date of birth             │
      │  - Gender                    │
      │  - Address                   │
      │  - City/State/Country        │
      │  - Emergency contact         │
      │  - Medical history (optional)│
      │  - Allergies (optional)      │
      └──────────────────────────────┘
          │
          ▼
      ┌──────────────────────────────┐
      │  SELECT DOCTOR               │
      │  - Search by name/phone      │
      │  - View doctor list          │
      │  - Select preferred doctor   │
      └──────────────────────────────┘
          │
          ▼
      PATIENT HOME
```

### 2. Patient Home Screen Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PATIENT HOME SCREEN                              │
└─────────────────────────────────────────────────────────────────────┘

PATIENT HOME
  │
  ├─→ [SEND SMS TO DOCTOR]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  SEND SYMPTOM MESSAGE        │
  │   │  - Text input field          │
  │   │  - Suggested symptoms        │
  │   │  - Send button               │
  │   │  - Cancel button             │
  │   └──────────────────────────────┘
  │   │
  │   ├─→ Message sent successfully
  │   │   │
  │   │   ▼
  │   │   ┌──────────────────────────────┐
  │   │   │  SUCCESS SCREEN              │
  │   │   │  - "Message sent to doctor"  │
  │   │   │  - Case ID: [ABC123]         │
  │   │   │  - "Doctor will contact you" │
  │   │   │  - OK button                 │
  │   │   └──────────────────────────────┘
  │   │
  │   └─→ Message failed
  │       │
  │       ▼
  │       ┌──────────────────────────────┐
  │       │  ERROR SCREEN                │
  │       │  - "Failed to send message"  │
  │       │  - Retry button              │
  │       │  - Cancel button             │
  │       └──────────────────────────────┘
  │
  ├─→ [VIEW CONSULTATIONS]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  CONSULTATIONS LIST          │
  │   │  - Pending consultations     │
  │   │  - Active consultations      │
  │   │  - Completed consultations   │
  │   │  - Tap to view details       │
  │   └──────────────────────────────┘
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  CONSULTATION DETAIL         │
  │   │  - Doctor name               │
  │   │  - Consultation status       │
  │   │  - Message history           │
  │   │  - Send message button       │
  │   │  - View prescription button  │
  │   │  - View test results button  │
  │   └──────────────────────────────┘
  │
  ├─→ [VIEW PRESCRIPTIONS]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  PRESCRIPTIONS LIST          │
  │   │  - Active prescriptions      │
  │   │  - Completed prescriptions   │
  │   │  - Expired prescriptions     │
  │   │  - Tap to view details       │
  │   └──────────────────────────────┘
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  PRESCRIPTION DETAIL         │
  │   │  - RX Code (copyable)        │
  │   │  - Medicine name             │
  │   │  - Dosage                    │
  │   │  - Frequency                 │
  │   │  - Duration                  │
  │   │  - Instructions              │
  │   │  - Timing (morning/evening)  │
  │   │  - Doctor notes              │
  │   │  - Pharmacy status           │
  │   │  - Copy RX Code button       │
  │   │  - Share button              │
  │   └──────────────────────────────┘
  │
  ├─→ [VIEW TEST RESULTS]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  TEST RESULTS LIST           │
  │   │  - Pending tests             │
  │   │  - Completed tests           │
  │   │  - Test type                 │
  │   │  - Test date                 │
  │   │  - Tap to view details       │
  │   └──────────────────────────────┘
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  TEST RESULT DETAIL          │
  │   │  - Test type                 │
  │   │  - Result (Positive/Negative)│
  │   │  - Test date                 │
  │   │  - Clinic name               │
  │   │  - Notes                     │
  │   │  - Follow-up required?       │
  │   │  - Doctor recommendation     │
  │   │  - Share button              │
  │   └──────────────────────────────┘
  │
  ├─→ [FIND PHARMACY]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  PHARMACY LOCATOR            │
  │   │  - Map view                  │
  │   │  - List view                 │
  │   │  - Search by name            │
  │   │  - Filter by distance        │
  │   │  - Tap to view details       │
  │   └──────────────────────────────┘
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  PHARMACY DETAIL             │
  │   │  - Pharmacy name             │
  │   │  - Address                   │
  │   │  - Phone number              │
  │   │  - Distance                  │
  │   │  - Hours of operation        │
  │   │  - Call button               │
  │   │  - Directions button         │
  │   │  - Website button            │
  │   └──────────────────────────────┘
  │
  ├─→ [FIND CLINIC]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  CLINIC LOCATOR              │
  │   │  - Map view                  │
  │   │  - List view                 │
  │   │  - Search by name            │
  │   │  - Filter by distance        │
  │   │  - Tap to view details       │
  │   └──────────────────────────────┘
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  CLINIC DETAIL               │
  │   │  - Clinic name               │
  │   │  - Address                   │
  │   │  - Phone number              │
  │   │  - Distance                  │
  │   │  - Hours of operation        │
  │   │  - Tests offered             │
  │   │  - Call button               │
  │   │  - Directions button         │
  │   │  - Website button            │
  │   └──────────────────────────────┘
  │
  ├─→ [HEALTH HISTORY]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  HEALTH HISTORY              │
  │   │  - All consultations         │
  │   │  - All prescriptions         │
  │   │  - All test results          │
  │   │  - Timeline view             │
  │   │  - Filter by date            │
  │   │  - Export option             │
  │   └──────────────────────────────┘
  │
  └─→ [SETTINGS]
      │
      ▼
      ┌──────────────────────────────┐
      │  SETTINGS SCREEN             │
      │  - Edit profile              │
      │  - Change password           │
      │  - Notification settings     │
      │  - Language preference       │
      │  - Privacy settings          │
      │  - Help & support            │
      │  - About app                 │
      │  - Logout                    │
      └──────────────────────────────┘
```

### 3. Patient Consultation Flow (Detailed)

```
┌─────────────────────────────────────────────────────────────────────┐
│            PATIENT CONSULTATION MESSAGING FLOW                      │
└─────────────────────────────────────────────────────────────────────┘

CONSULTATION DETAIL SCREEN
  │
  ├─→ Status: PENDING
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  WAITING FOR DOCTOR          │
  │   │  - "Doctor will contact you" │
  │   │  - Refresh button            │
  │   │  - Back button               │
  │   │  - Show case ID              │
  │   └──────────────────────────────┘
  │
  ├─→ Status: ACCEPTED
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  ACTIVE CONSULTATION         │
  │   │  - Doctor name               │
  │   │  - Message history           │
  │   │  - Input field for reply     │
  │   │  - Send button               │
  │   │  - Attach file button        │
  │   │  - Call doctor button        │
  │   └──────────────────────────────┘
  │   │
  │   ├─→ Patient sends message
  │   │   │
  │   │   ▼
  │   │   ┌──────────────────────────────┐
  │   │   │  MESSAGE SENT                │
  │   │   │  - Show in chat bubble       │
  │   │   │  - Timestamp                 │
  │   │   │  - Delivery status           │
  │   │   └──────────────────────────────┘
  │   │
  │   ├─→ Doctor sends message
  │   │   │
  │   │   ▼
  │   │   ┌──────────────────────────────┐
  │   │   │  DOCTOR MESSAGE RECEIVED     │
  │   │   │  - Show in chat bubble       │
  │   │   │  - Timestamp                 │
  │   │   │  - Notification              │
  │   │   │  - Sound alert               │
  │   │   └──────────────────────────────┘
  │   │
  │   └─→ Doctor creates prescription
  │       │
  │       ▼
  │       ┌──────────────────────────────┐
  │       │  PRESCRIPTION NOTIFICATION   │
  │       │  - "Prescription ready"      │
  │       │  - View prescription button  │
  │       │  - RX Code: [ABC123XYZ]      │
  │       │  - Notification sound        │
  │       └──────────────────────────────┘
  │
  └─→ Status: COMPLETED
      │
      ▼
      ┌──────────────────────────────┐
      │  CONSULTATION COMPLETED      │
      │  - Doctor name               │
      │  - Final notes               │
      │  - Prescription (if any)     │
      │  - Test results (if any)     │
      │  - Follow-up date            │
      │  - Rate consultation button  │
      │  - Back button               │
      └──────────────────────────────┘
```

---

## Doctor Journey

### 1. Doctor Authentication & Profile Setup

```
┌─────────────────────────────────────────────────────────────────────┐
│              DOCTOR LOGIN & PROFILE SETUP FLOW                      │
└─────────────────────────────────────────────────────────────────────┘

START
  │
  ▼
┌──────────────────────────────┐
│  SPLASH SCREEN               │
│  - Check login status        │
│  - Check profile complete    │
└──────────────────────────────┘
  │
  ├─→ User logged in? ──YES──→ Check profile complete?
  │                                    │
  │                            ┌───────┴────────┐
  │                            │                │
  │                        YES │                │ NO
  │                            │                │
  │                            ▼                ▼
  │                      DOCTOR HOME    COMPLETE PROFILE
  │                                      (Name, License,
  │                                       Specialization,
  │                                       Clinic, Bio)
  │
  └─→ NO
      │
      ▼
┌──────────────────────────────┐
│  DOCTOR LOGIN SCREEN         │
│  - Phone number input        │
│  - OTP verification          │
│  - Password setup            │
└──────────────────────────────┘
      │
      ├─→ Existing doctor? ──YES──→ LOGIN
      │                              │
      │                              ▼
      │                      ┌──────────────────┐
      │                      │ VERIFY OTP       │
      │                      │ - Enter OTP      │
      │                      │ - Resend OTP     │
      │                      └──────────────────┘
      │                              │
      │                              ▼
      │                      DOCTOR HOME
      │
      └─→ NO
          │
          ▼
      ┌──────────────────────────────┐
      │  DOCTOR SIGNUP SCREEN        │
      │  - Phone number              │
      │  - Email                     │
      │  - Password                  │
      │  - Confirm password          │
      │  - Terms & conditions        │
      └──────────────────────────────┘
          │
          ▼
      ┌──────────────────────────────┐
      │  VERIFY OTP                  │
      │  - Enter 6-digit OTP         │
      │  - Resend option             │
      │  - Timer (5 min)             │
      └──────────────────────────────┘
          │
          ▼
      ┌──────────────────────────────┐
      │  COMPLETE DOCTOR PROFILE     │
      │  - Full name                 │
      │  - License number            │
      │  - License expiry date       │
      │  - Specialization            │
      │  - Clinic affiliation        │
      │  - Bio/About                 │
      │  - Profile picture           │
      │  - Upload license document   │
      └──────────────────────────────┘
          │
          ▼
      ┌──────────────────────────────┐
      │  VERIFY CREDENTIALS          │
      │  - License verification      │
      │  - Document review           │
      │  - Pending approval          │
      │  - "We'll notify you"        │
      └──────────────────────────────┘
          │
          ▼
      DOCTOR HOME
```

### 2. Doctor Home Screen & Dashboard

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DOCTOR HOME SCREEN                               │
└─────────────────────────────────────────────────────────────────────┘

DOCTOR HOME
  │
  ├─→ [PENDING CONSULTATIONS] (Badge with count)
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  CONSULTATIONS LIST          │
  │   │  - Patient name              │
  │   │  - Chief complaint           │
  │   │  - Time received             │
  │   │  - Status badge              │
  │   │  - Tap to open               │
  │   │  - Swipe to accept/reject    │
  │   └──────────────────────────────┘
  │   │
  │   ├─→ Tap consultation
  │   │   │
  │   │   ▼
  │   │   ┌──────────────────────────────┐
  │   │   │  CONSULTATION DETAIL         │
  │   │   │  - Patient name              │
  │   │   │  - Phone number              │
  │   │   │  - Chief complaint           │
  │   │   │  - Medical history           │
  │   │   │  - Allergies                 │
  │   │   │  - Current medications       │
  │   │   │  - Accept button             │
  │   │   │  - Reject button             │
  │   │   │  - Back button               │
  │   │   └──────────────────────────────┘
  │   │
  │   ├─→ Accept consultation
  │   │   │
  │   │   ▼
  │   │   ┌──────────────────────────────┐
  │   │   │  CONSULTATION ACCEPTED       │
  │   │   │  - Status changed to ACCEPTED│
  │   │   │  - Send message button       │
  │   │   │  - Call patient button       │
  │   │   │  - View history button       │
  │   │   └──────────────────────────────┘
  │   │
  │   └─→ Reject consultation
  │       │
  │       ▼
  │       ┌──────────────────────────────┐
  │       │  REJECTION REASON            │
  │       │  - Select reason dropdown    │
  │       │  - Add notes (optional)      │
  │       │  - Confirm button            │
  │       │  - Cancel button             │
  │       └──────────────────────────────┘
  │
  ├─→ [ACTIVE CONSULTATIONS]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  ACTIVE CONSULTATIONS LIST   │
  │   │  - Patient name              │
  │   │  - Last message              │
  │   │  - Time of last message      │
  │   │  - Unread badge (if any)     │
  │   │  - Tap to open               │
  │   └──────────────────────────────┘
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  ACTIVE CONSULTATION CHAT    │
  │   │  - Message history           │
  │   │  - Patient messages          │
  │   │  - Doctor messages           │
  │   │  - Timestamps                │
  │   │  - Input field               │
  │   │  - Send button               │
  │   │  - Attach file button        │
  │   │  - Call button               │
  │   │  - Write prescription button │
  │   │  - Request test button       │
  │   │  - Add notes button          │
  │   │  - Complete consultation btn │
  │   └──────────────────────────────┘
  │
  ├─→ [WRITE PRESCRIPTION]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  NEW PRESCRIPTION SCREEN     │
  │   │  - Select patient           │
  │   │  - Search patient by name   │
  │   │  - Recent patients list     │
  │   │  - Next button              │
  │   └──────────────────────────────┘
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  PRESCRIPTION DETAILS        │
  │   │  - Medicine name (search)    │
  │   │  - Dosage input              │
  │   │  - Frequency dropdown        │
  │   │  - Duration input            │
  │   │  - Timing (morning/evening)  │
  │   │  - Instructions              │
  │   │  - Add more medicines button │
  │   │  - Next button               │
  │   └──────────────────────────────┘
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  PRESCRIPTION REVIEW         │
  │   │  - All medicines listed      │
  │   │  - Edit button for each      │
  │   │  - Doctor notes              │
  │   │  - Generate RX Code          │
  │   │  - Preview SMS               │
  │   │  - Submit button             │
  │   │  - Cancel button             │
  │   └──────────────────────────────┘
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  PRESCRIPTION SENT           │
  │   │  - "RX Code: [ABC123XYZ]"    │
  │   │  - "SMS sent to patient"     │
  │   │  - "SMS sent to pharmacy"    │
  │   │  - View prescription button  │
  │   │  - Back to consultation btn  │
  │   └──────────────────────────────┘
  │
  ├─→ [REQUEST TEST]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  REQUEST TEST SCREEN         │
  │   │  - Select patient            │
  │   │  - Test type dropdown        │
  │   │  - Select clinic             │
  │   │  - Urgency level             │
  │   │  - Notes                     │
  │   │  - Submit button             │
  │   └──────────────────────────────┘
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  TEST REQUEST SENT           │
  │   │  - "Request sent to clinic"  │
  │   │  - "SMS sent to clinic"      │
  │   │  - "SMS sent to patient"     │
  │   │  - Back button               │
  │   └──────────────────────────────┘
  │
  ├─→ [PRESCRIPTION HISTORY]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  PRESCRIPTIONS LIST          │
  │   │  - Patient name              │
  │   │  - RX Code                   │
  │   │  - Date created              │
  │   │  - Status                    │
  │   │  - Tap to view details       │
  │   │  - Filter by status          │
  │   │  - Search by patient         │
  │   └──────────────────────────────┘
  │
  ├─→ [TEST RESULTS]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  TEST RESULTS LIST           │
  │   │  - Patient name              │
  │   │  - Test type                 │
  │   │  - Result (Positive/Negative)│
  │   │  - Date received             │
  │   │  - Tap to view details       │
  │   │  - Filter by status          │
  │   │  - Badge for new results     │
  │   └──────────────────────────────┘
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  TEST RESULT DETAIL          │
  │   │  - Patient name              │
  │   │  - Test type                 │
  │   │  - Result                    │
  │   │  - Clinic name               │
  │   │  - Test date                 │
  │   │  - Notes from clinic         │
  │   │  - Follow-up required?       │
  │   │  - Send message to patient   │
  │   │  - Create prescription btn   │
  │   │  - Back button               │
  │   └──────────────────────────────┘
  │
  ├─→ [CONSULTATION HISTORY]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  CONSULTATION HISTORY        │
  │   │  - Patient name              │
  │   │  - Date of consultation      │
  │   │  - Status                    │
  │   │  - Chief complaint           │
  │   │  - Tap to view details       │
  │   │  - Filter by date            │
  │   │  - Search by patient         │
  │   └──────────────────────────────┘
  │
  ├─→ [STATISTICS/DASHBOARD]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  DOCTOR DASHBOARD            │
  │   │  - Total consultations       │
  │   │  - Pending consultations     │
  │   │  - Completed today           │
  │   │  - Total prescriptions       │
  │   │  - Average response time     │
  │   │  - Patient satisfaction      │
  │   │  - Charts & graphs           │
  │   └──────────────────────────────┘
  │
  └─→ [SETTINGS]
      │
      ▼
      ┌──────────────────────────────┐
      │  DOCTOR SETTINGS             │
      │  - Edit profile              │
      │  - Change password           │
      │  - Notification settings     │
      │  - Availability hours        │
      │  - Language preference       │
      │  - Help & support            │
      │  - About app                 │
      │  - Logout                    │
      └──────────────────────────────┘
```

---

**Continue to MOBILE_APP_FLOWCHART_PART2.md for Pharmacy, Clinic, and Common Flows**
