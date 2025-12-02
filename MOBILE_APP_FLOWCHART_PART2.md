# HatiCare Mobile App - Complete Flowchart & User Journeys (Part 2)

---

## Pharmacy Journey

### 1. Pharmacy Authentication & Profile Setup

```
┌─────────────────────────────────────────────────────────────────────┐
│           PHARMACY LOGIN & PROFILE SETUP FLOW                       │
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
  │                      PHARMACY HOME  COMPLETE PROFILE
  │                                      (Name, License,
  │                                       Address, Tax ID)
  │
  └─→ NO
      │
      ▼
┌──────────────────────────────┐
│  PHARMACY LOGIN SCREEN       │
│  - Phone number input        │
│  - OTP verification          │
│  - Password setup            │
└──────────────────────────────┘
      │
      ├─→ Existing pharmacy? ──YES──→ LOGIN
      │                               │
      │                               ▼
      │                       ┌──────────────────┐
      │                       │ VERIFY OTP       │
      │                       │ - Enter OTP      │
      │                       │ - Resend OTP     │
      │                       └──────────────────┘
      │                               │
      │                               ▼
      │                       PHARMACY HOME
      │
      └─→ NO
          │
          ▼
      ┌──────────────────────────────┐
      │  PHARMACY SIGNUP SCREEN      │
      │  - Pharmacy name             │
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
      │  COMPLETE PHARMACY PROFILE   │
      │  - Pharmacy name             │
      │  - License number            │
      │  - Address                   │
      │  - City/State/Country        │
      │  - Tax ID                    │
      │  - Phone number              │
      │  - Email                     │
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
      PHARMACY HOME
```

### 2. Pharmacy Home & Prescription Management

```
┌─────────────────────────────────────────────────────────────────────┐
│                  PHARMACY HOME SCREEN                               │
└─────────────────────────────────────────────────────────────────────┘

PHARMACY HOME
  │
  ├─→ [PENDING PRESCRIPTIONS] (Badge with count)
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  PRESCRIPTIONS LIST          │
  │   │  - RX Code                   │
  │   │  - Patient name              │
  │   │  - Medicine name             │
  │   │  - Date received             │
  │   │  - Status badge              │
  │   │  - Tap to open               │
  │   │  - Swipe to mark as received │
  │   └──────────────────────────────┘
  │   │
  │   ├─→ Tap prescription
  │   │   │
  │   │   ▼
  │   │   ┌──────────────────────────────┐
  │   │   │  PRESCRIPTION DETAIL         │
  │   │   │  - RX Code (copyable)        │
  │   │   │  - Patient name              │
  │   │   │  - Patient phone             │
  │   │   │  - Medicine name             │
  │   │   │  - Dosage                    │
  │   │   │  - Frequency                 │
  │   │   │  - Duration                  │
  │   │   │  - Instructions              │
  │   │   │  - Doctor notes              │
  │   │   │  - Doctor name               │
  │   │   │  - Check stock button        │
  │   │   │  - Update status button      │
  │   │   │  - Call patient button       │
  │   │   │  - Back button               │
  │   │   └──────────────────────────────┘
  │   │
  │   └─→ Update Stock Status
  │       │
  │       ▼
  │       ┌──────────────────────────────┐
  │       │  UPDATE STOCK STATUS         │
  │       │  - Status options:           │
  │       │    • Fully Available          │
  │       │    • Partially Available      │
  │       │    • Out of Stock             │
  │       │  - Select status             │
  │       │  - Add notes (optional)      │
  │       │  - Submit button             │
  │       │  - Cancel button             │
  │       └──────────────────────────────┘
  │       │
  │       ▼
  │       ┌──────────────────────────────┐
  │       │  STATUS UPDATED              │
  │       │  - "Status updated"          │
  │       │  - "SMS sent to patient"     │
  │       │  - Back to prescription btn  │
  │       └──────────────────────────────┘
  │
  ├─→ [DISPENSE MEDICINE]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  DISPENSE SCREEN             │
  │   │  - Enter RX Code             │
  │   │  - Scan barcode (optional)   │
  │   │  - Search button             │
  │   │  - Cancel button             │
  │   └──────────────────────────────┘
  │   │
  │   ├─→ RX Code found
  │   │   │
  │   │   ▼
  │   │   ┌──────────────────────────────┐
  │   │   │  VERIFY PRESCRIPTION         │
  │   │   │  - Patient name              │
  │   │   │  - Medicine name             │
  │   │   │  - Dosage                    │
  │   │   │  - Quantity                  │
  │   │   │  - Confirm dispense button   │
  │   │   │  - Cancel button             │
  │   │   └──────────────────────────────┘
  │   │   │
  │   │   ▼
  │   │   ┌──────────────────────────────┐
  │   │   │  MEDICINE DISPENSED          │
  │   │   │  - "Medicine dispensed"      │
  │   │   │  - "SMS sent to patient"     │
  │   │   │  - Print receipt button      │
  │   │   │  - Back button               │
  │   │   └──────────────────────────────┘
  │   │
  │   └─→ RX Code not found
  │       │
  │       ▼
  │       ┌──────────────────────────────┐
  │       │  ERROR SCREEN                │
  │       │  - "RX Code not found"       │
  │       │  - Try again button          │
  │       │  - Cancel button             │
  │       └──────────────────────────────┘
  │
  ├─→ [MANAGE INVENTORY]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  MEDICINES LIST              │
  │   │  - Medicine name             │
  │   │  - Dosage                    │
  │   │  - Quantity available        │
  │   │  - Expiry date               │
  │   │  - Price                     │
  │   │  - Tap to edit               │
  │   │  - Add medicine button       │
  │   │  - Search field              │
  │   └──────────────────────────────┘
  │   │
  │   ├─→ Tap medicine
  │   │   │
  │   │   ▼
  │   │   ┌──────────────────────────────┐
  │   │   │  EDIT MEDICINE               │
  │   │   │  - Medicine name             │
  │   │   │  - Dosage                    │
  │   │   │  - Quantity available        │
  │   │   │  - Minimum quantity          │
  │   │   │  - Expiry date               │
  │   │   │  - Price                     │
  │   │   │  - Supplier                  │
  │   │   │  - Save button               │
  │   │   │  - Delete button             │
  │   │   │  - Cancel button             │
  │   │   └──────────────────────────────┘
  │   │
  │   └─→ Add medicine
  │       │
  │       ▼
  │       ┌──────────────────────────────┐
  │       │  ADD NEW MEDICINE            │
  │       │  - Medicine name (search)    │
  │       │  - Dosage                    │
  │       │  - Quantity available        │
  │       │  - Minimum quantity          │
  │       │  - Expiry date               │
  │       │  - Price                     │
  │       │  - Supplier                  │
  │       │  - Save button               │
  │       │  - Cancel button             │
  │       └──────────────────────────────┘
  │
  ├─→ [PRESCRIPTION HISTORY]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  HISTORY LIST                │
  │   │  - RX Code                   │
  │   │  - Patient name              │
  │   │  - Date                      │
  │   │  - Status                    │
  │   │  - Tap to view details       │
  │   │  - Filter by date            │
  │   │  - Search by RX Code         │
  │   └──────────────────────────────┘
  │
  ├─→ [STATISTICS/DASHBOARD]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  PHARMACY DASHBOARD          │
  │   │  - Total prescriptions       │
  │   │  - Pending prescriptions     │
  │   │  - Dispensed today           │
  │   │  - Low stock medicines       │
  │   │  - Expiring soon             │
  │   │  - Charts & graphs           │
  │   └──────────────────────────────┘
  │
  └─→ [SETTINGS]
      │
      ▼
      ┌──────────────────────────────┐
      │  PHARMACY SETTINGS           │
      │  - Edit profile              │
      │  - Change password           │
      │  - Notification settings     │
      │  - Operating hours           │
      │  - Language preference       │
      │  - Help & support            │
      │  - About app                 │
      │  - Logout                    │
      └──────────────────────────────┘
```

---

## Clinic Journey

### 1. Clinic Authentication & Profile Setup

```
┌─────────────────────────────────────────────────────────────────────┐
│            CLINIC LOGIN & PROFILE SETUP FLOW                        │
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
  │                      CLINIC HOME    COMPLETE PROFILE
  │                                      (Name, License,
  │                                       Address)
  │
  └─→ NO
      │
      ▼
┌──────────────────────────────┐
│  CLINIC LOGIN SCREEN         │
│  - Phone number input        │
│  - OTP verification          │
│  - Password setup            │
└──────────────────────────────┘
      │
      ├─→ Existing clinic? ──YES──→ LOGIN
      │                             │
      │                             ▼
      │                     ┌──────────────────┐
      │                     │ VERIFY OTP       │
      │                     │ - Enter OTP      │
      │                     │ - Resend OTP     │
      │                     └──────────────────┘
      │                             │
      │                             ▼
      │                     CLINIC HOME
      │
      └─→ NO
          │
          ▼
      ┌──────────────────────────────┐
      │  CLINIC SIGNUP SCREEN        │
      │  - Clinic name               │
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
      │  COMPLETE CLINIC PROFILE     │
      │  - Clinic name               │
      │  - License number            │
      │  - License expiry date       │
      │  - Address                   │
      │  - City/State/Country        │
      │  - Phone number              │
      │  - Email                     │
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
      CLINIC HOME
```

### 2. Clinic Home & Test Management

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CLINIC HOME SCREEN                               │
└─────────────────────────────────────────────────────────────────────┘

CLINIC HOME
  │
  ├─→ [PENDING TEST REQUESTS] (Badge with count)
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  TEST REQUESTS LIST          │
  │   │  - Patient name              │
  │   │  - Test type                 │
  │   │  - Doctor name               │
  │   │  - Date requested            │
  │   │  - Urgency level             │
  │   │  - Tap to open               │
  │   │  - Swipe to mark as received │
  │   └──────────────────────────────┘
  │   │
  │   ├─→ Tap test request
  │   │   │
  │   │   ▼
  │   │   ┌──────────────────────────────┐
  │   │   │  TEST REQUEST DETAIL         │
  │   │   │  - Patient name              │
  │   │   │  - Patient phone             │
  │   │   │  - Test type                 │
  │   │   │  - Doctor name               │
  │   │   │  - Doctor phone              │
  │   │   │  - Date requested            │
  │   │   │  - Urgency level             │
  │   │   │  - Notes from doctor         │
  │   │   │  - Enter result button       │
  │   │   │  - Call patient button       │
  │   │   │  - Call doctor button        │
  │   │   │  - Back button               │
  │   │   └──────────────────────────────┘
  │   │
  │   └─→ Enter Result
  │       │
  │       ▼
  │       ┌──────────────────────────────┐
  │       │  ENTER TEST RESULT           │
  │       │  - Test type (pre-filled)    │
  │       │  - Patient name (pre-filled) │
  │       │  - Result dropdown:          │
  │       │    • Positive                │
  │       │    • Negative                │
  │       │    • Indeterminate           │
  │       │  - Test date                 │
  │       │  - Notes                     │
  │       │  - Requires follow-up?       │
  │       │  - Submit button             │
  │       │  - Cancel button             │
  │       └──────────────────────────────┘
  │       │
  │       ▼
  │       ┌──────────────────────────────┐
  │       │  RESULT SUBMITTED            │
  │       │  - "Result submitted"        │
  │       │  - "SMS sent to patient"     │
  │       │  - "SMS sent to doctor"      │
  │       │  - View result button        │
  │       │  - Back to requests btn      │
  │       └──────────────────────────────┘
  │
  ├─→ [SEARCH/CREATE PATIENT]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  PATIENT SEARCH              │
  │   │  - Enter phone number        │
  │   │  - Search button             │
  │   │  - Or create new patient     │
  │   └──────────────────────────────┘
  │   │
  │   ├─→ Patient found
  │   │   │
  │   │   ▼
  │   │   ┌──────────────────────────────┐
  │   │   │  PATIENT DETAIL              │
  │   │   │  - Name                      │
  │   │   │  - Phone                     │
  │   │   │  - DOB                       │
  │   │   │  - Gender                    │
  │   │   │  - Address                   │
  │   │   │  - Medical history           │
  │   │   │  - Allergies                 │
  │   │   │  - Previous test results     │
  │   │   │  - Enter new result button   │
  │   │   │  - Back button               │
  │   │   └──────────────────────────────┘
  │   │
  │   └─→ Patient not found
  │       │
  │       ▼
  │       ┌──────────────────────────────┐
  │       │  CREATE NEW PATIENT          │
  │       │  - Full name                 │
  │       │  - Phone number              │
  │       │  - Date of birth             │
  │       │  - Gender                    │
  │       │  - Address                   │
  │       │  - City/State/Country        │
  │       │  - Medical history           │
  │       │  - Allergies                 │
  │       │  - Create button             │
  │       │  - Cancel button             │
  │       └──────────────────────────────┘
  │       │
  │       ▼
  │       ┌──────────────────────────────┐
  │       │  PATIENT CREATED             │
  │       │  - "Patient created"         │
  │       │  - Enter test result button  │
  │       │  - Back button               │
  │       └──────────────────────────────┘
  │
  ├─→ [TEST RESULTS HISTORY]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  RESULTS LIST                │
  │   │  - Patient name              │
  │   │  - Test type                 │
  │   │  - Result                    │
  │   │  - Date                      │
  │   │  - Status                    │
  │   │  - Tap to view details       │
  │   │  - Filter by date            │
  │   │  - Search by patient         │
  │   └──────────────────────────────┘
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  RESULT DETAIL               │
  │   │  - Patient name              │
  │   │  - Test type                 │
  │   │  - Result                    │
  │   │  - Test date                 │
  │   │  - Submitted date            │
  │   │  - Doctor name               │
  │   │  - Notes                     │
  │   │  - Follow-up required?       │
  │   │  - Edit button               │
  │   │  - Delete button             │
  │   │  - Back button               │
  │   └──────────────────────────────┘
  │
  ├─→ [STATISTICS/DASHBOARD]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  CLINIC DASHBOARD            │
  │   │  - Total tests done          │
  │   │  - Pending tests             │
  │   │  - Completed today           │
  │   │  - Positive results          │
  │   │  - Negative results          │
  │   │  - Average turnaround time   │
  │   │  - Charts & graphs           │
  │   └──────────────────────────────┘
  │
  └─→ [SETTINGS]
      │
      ▼
      ┌──────────────────────────────┐
      │  CLINIC SETTINGS             │
      │  - Edit profile              │
      │  - Change password           │
      │  - Notification settings     │
      │  - Operating hours           │
      │  - Language preference       │
      │  - Help & support            │
      │  - About app                 │
      │  - Logout                    │
      └──────────────────────────────┘
```

---

## Common Flows

### 1. Authentication Flow (All Roles)

```
┌─────────────────────────────────────────────────────────────────────┐
│                  UNIVERSAL AUTH FLOW                                │
└─────────────────────────────────────────────────────────────────────┘

START
  │
  ▼
┌──────────────────────────────┐
│  SPLASH SCREEN               │
│  - App logo                  │
│  - Loading animation         │
│  - Check SharedPreferences   │
└──────────────────────────────┘
  │
  ├─→ Token exists & valid?
  │   │
  │   ├─→ YES
  │   │   │
  │   │   ▼
  │   │   Check profile_completed?
  │   │   │
  │   │   ├─→ YES → Navigate to HOME
  │   │   │
  │   │   └─→ NO → Navigate to PROFILE
  │   │
  │   └─→ NO
  │       │
  │       ▼
  │       Navigate to LOGIN
  │
  └─→ Error loading token
      │
      ▼
      Navigate to LOGIN
```

### 2. Profile Completion Flow (All Roles)

```
┌─────────────────────────────────────────────────────────────────────┐
│              PROFILE COMPLETION FLOW                                │
└─────────────────────────────────────────────────────────────────────┘

PROFILE INCOMPLETE
  │
  ▼
┌──────────────────────────────┐
│  STEP 1: BASIC INFO          │
│  - Name                      │
│  - Phone (pre-filled)        │
│  - Email                     │
│  - Password (if new user)    │
│  - Next button               │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  STEP 2: ROLE-SPECIFIC INFO  │
│  (Varies by role)            │
│  - License/ID                │
│  - Address                   │
│  - Specialization (doctor)   │
│  - Next button               │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  STEP 3: DOCUMENTS           │
│  - Upload profile picture    │
│  - Upload license document   │
│  - Upload additional docs    │
│  - Submit button             │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  VERIFICATION PENDING        │
│  - "Profile submitted"       │
│  - "Under review"            │
│  - "We'll notify you"        │
│  - Continue to app button    │
└──────────────────────────────┘
  │
  ▼
HOME SCREEN
```

### 3. Notification Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                  NOTIFICATION FLOW                                  │
└─────────────────────────────────────────────────────────────────────┘

NOTIFICATION RECEIVED
  │
  ├─→ App in foreground?
  │   │
  │   ├─→ YES
  │   │   │
  │   │   ▼
  │   │   ┌──────────────────────────────┐
  │   │   │  IN-APP NOTIFICATION         │
  │   │   │  - Toast/Snackbar            │
  │   │   │  - Sound alert               │
  │   │   │  - Vibration                 │
  │   │   │  - Auto-dismiss or tap       │
  │   │   └──────────────────────────────┘
  │   │
  │   └─→ NO
  │       │
  │       ▼
  │       ┌──────────────────────────────┐
  │       │  PUSH NOTIFICATION           │
  │       │  - Notification title        │
  │       │  - Notification body         │
  │       │  - Badge count               │
  │       │  - Sound                     │
  │       │  - Tap to open app           │
  │       └──────────────────────────────┘
  │
  └─→ Notification types:
      ├─→ New consultation (Doctor)
      ├─→ Prescription received (Pharmacy)
      ├─→ Test result ready (Clinic)
      ├─→ Message from doctor (Patient)
      ├─→ Stock status update (Patient)
      ├─→ Test request (Clinic)
      └─→ General alerts
```

### 4. Error Handling Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                  ERROR HANDLING FLOW                                │
└─────────────────────────────────────────────────────────────────────┘

ERROR OCCURS
  │
  ├─→ Network error?
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  NETWORK ERROR DIALOG        │
  │   │  - "No internet connection"  │
  │   │  - Retry button              │
  │   │  - Cancel button             │
  │   │  - Offline mode info         │
  │   └──────────────────────────────┘
  │
  ├─→ Server error (5xx)?
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  SERVER ERROR DIALOG         │
  │   │  - "Server error"            │
  │   │  - "Try again later"         │
  │   │  - Retry button              │
  │   │  - Contact support button    │
  │   │  - Cancel button             │
  │   └──────────────────────────────┘
  │
  ├─→ Client error (4xx)?
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  VALIDATION ERROR DIALOG     │
  │   │  - Error message             │
  │   │  - Suggestion                │
  │   │  - OK button                 │
  │   └──────────────────────────────┘
  │
  └─→ Timeout error?
      │
      ▼
      ┌──────────────────────────────┐
      │  TIMEOUT ERROR DIALOG        │
      │  - "Request timed out"       │
      │  - "Check connection"        │
      │  - Retry button              │
      │  - Cancel button             │
      └──────────────────────────────┘
```

### 5. Search & Filter Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                  SEARCH & FILTER FLOW                               │
└─────────────────────────────────────────────────────────────────────┘

LIST SCREEN
  │
  ├─→ [SEARCH]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  SEARCH INPUT                │
  │   │  - Search field              │
  │   │  - Clear button              │
  │   │  - Real-time search          │
  │   │  - Search results            │
  │   │  - Tap to select             │
  │   └──────────────────────────────┘
  │
  ├─→ [FILTER]
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  FILTER OPTIONS              │
  │   │  - Filter by date            │
  │   │  - Filter by status          │
  │   │  - Filter by type            │
  │   │  - Apply button              │
  │   │  - Reset button              │
  │   │  - Cancel button             │
  │   └──────────────────────────────┘
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  FILTERED LIST               │
  │   │  - Updated results           │
  │   │  - Item count                │
  │   │  - Tap to view details       │
  │   └──────────────────────────────┘
  │
  └─→ [SORT]
      │
      ▼
      ┌──────────────────────────────┐
      │  SORT OPTIONS                │
      │  - Sort by date (newest)     │
      │  - Sort by date (oldest)     │
      │  - Sort by name (A-Z)        │
      │  - Sort by name (Z-A)        │
      │  - Sort by status            │
      │  - Apply button              │
      └──────────────────────────────┘
```

### 6. Data Sync Flow (Offline Support)

```
┌─────────────────────────────────────────────────────────────────────┐
│                  DATA SYNC FLOW                                     │
└─────────────────────────────────────────────────────────────────────┘

APP STARTS
  │
  ▼
┌──────────────────────────────┐
│  CHECK INTERNET              │
│  - Connected?                │
└──────────────────────────────┘
  │
  ├─→ YES
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  SYNC DATA                   │
  │   │  - Fetch latest data         │
  │   │  - Update local cache        │
  │   │  - Sync pending actions      │
  │   │  - Show loading indicator    │
  │   └──────────────────────────────┘
  │   │
  │   ├─→ Sync successful
  │   │   │
  │   │   ▼
  │   │   ┌──────────────────────────────┐
  │   │   │  SHOW LATEST DATA            │
  │   │   │  - Display fresh data        │
  │   │   │  - Update UI                 │
  │   │   │  - Hide loading              │
  │   │   └──────────────────────────────┘
  │   │
  │   └─→ Sync failed
  │       │
  │       ▼
  │       ┌──────────────────────────────┐
  │       │  USE CACHED DATA             │
  │       │  - Show last known data      │
  │       │  - Show "Offline" badge      │
  │       │  - Show retry button         │
  │       └──────────────────────────────┘
  │
  └─→ NO
      │
      ▼
      ┌──────────────────────────────┐
      │  OFFLINE MODE                │
      │  - Load cached data          │
      │  - Show "Offline" badge      │
      │  - Queue pending actions     │
      │  - Show sync when online     │
      └──────────────────────────────┘
```

---

## Screen Hierarchy Summary

### Patient App Screens
- Splash Screen
- Login/Signup Screen
- OTP Verification
- Profile Completion (3 steps)
- Home Screen
- Send Symptom Message
- Consultations List
- Consultation Detail
- Prescriptions List
- Prescription Detail
- Test Results List
- Test Result Detail
- Pharmacy Locator
- Clinic Locator
- Health History
- Settings

### Doctor App Screens
- Splash Screen
- Login/Signup Screen
- OTP Verification
- Profile Completion (3 steps)
- Home Screen
- Pending Consultations
- Consultation Detail
- Consultation Chat
- Write Prescription (3 steps)
- Request Test
- Prescription History
- Test Results
- Test Result Detail
- Consultation History
- Dashboard
- Settings

### Pharmacy App Screens
- Splash Screen
- Login/Signup Screen
- OTP Verification
- Profile Completion (3 steps)
- Home Screen
- Pending Prescriptions
- Prescription Detail
- Dispense Medicine
- Manage Inventory
- Edit/Add Medicine
- Prescription History
- Dashboard
- Settings

### Clinic App Screens
- Splash Screen
- Login/Signup Screen
- OTP Verification
- Profile Completion (3 steps)
- Home Screen
- Pending Test Requests
- Test Request Detail
- Enter Test Result
- Patient Search/Create
- Test Results History
- Result Detail
- Dashboard
- Settings

---

## Key UI/UX Principles

✅ **Consistent Navigation** - Bottom tab bar for main sections
✅ **Clear Status Badges** - Visual indicators for pending/completed items
✅ **Real-time Updates** - Refresh buttons and auto-sync
✅ **Offline Support** - Cached data with sync indicators
✅ **Error Handling** - Clear error messages with retry options
✅ **Accessibility** - Large touch targets, readable fonts
✅ **Performance** - Lazy loading, pagination for lists
✅ **Security** - Session timeout, logout confirmation
✅ **Notifications** - Push and in-app notifications
✅ **Multi-language** - Language preference in settings
