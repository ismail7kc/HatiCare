# HatiCare SMS-Based Flowchart - Patient Device Integration

---

## Overview

This flowchart shows the complete SMS-based patient journey where patients interact with the system directly from their mobile device via SMS (Twilio), while doctors, pharmacies, and clinics use the mobile app.

---

## Complete SMS-Based Patient Journey

### 1. Patient Initiates Consultation via SMS

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PATIENT DEVICE SMS FLOW                          │
└─────────────────────────────────────────────────────────────────────┘

PATIENT DEVICE
  │
  ▼
┌──────────────────────────────┐
│  PATIENT SENDS SMS           │
│  - Opens messaging app       │
│  - Enters doctor's number    │
│  - Types: "I have fever"    │
│  - Sends SMS                 │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  TWILIO SMS GATEWAY          │
│  - Receives inbound SMS      │
│  - Routes to HatiCare API    │
│  - Includes:                 │
│    • From number             │
│    • To number               │
│    • Message content         │
│    • Timestamp               │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  HATICARE API ENDPOINT       │
│  POST /api/v1/sms/inbound    │
│  - Parse SMS data            │
│  - Find patient by phone     │
│  - Find registered doctor    │
│  - Create consultation       │
│  - Generate case ID         │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  DATABASE UPDATE             │
│  - New consultation record   │
│  - Status: PENDING          │
│  - Case ID: ABC123          │
│  - Message stored           │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  NOTIFICATION SENT          │
│  - Push notification to     │
│    doctor's mobile app       │
│  - SMS backup to doctor     │
│  - Email notification       │
└──────────────────────────────┘
```

### 2. Doctor Receives & Responds via Mobile App

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DOCTOR APP NOTIFICATION FLOW                    │
└─────────────────────────────────────────────────────────────────────┘

DOCTOR MOBILE APP
  │
  ▼
┌──────────────────────────────┐
│  PUSH NOTIFICATION           │
│  - "New consultation"         │
│  - Patient: John Doe         │
│  - Case ID: ABC123          │
│  - Sound & vibration        │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  DOCTOR OPENS APP           │
│  - Sees pending badge       │
│  - Taps notification        │
│  - Views consultation       │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  CONSULTATION DETAIL        │
│  - Patient name             │
│  - Phone number            │
│  - Message: "I have fever"  │
│  - Medical history         │
│  - Previous consultations   │
│  - Accept/Reject buttons   │
└──────────────────────────────┘
  │
  ├─→ Doctor accepts
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  CONSULTATION ACCEPTED       │
  │   │  - Status: ACCEPTED          │
  │   │  - Chat opens                │
  │   │  - SMS sent to patient       │
  │   │  - "Dr. Smith accepted"     │
  │   └──────────────────────────────┘
  │   │
  │   ▼
  │   ┌──────────────────────────────┐
  │   │  DOCTOR-PATIENT CHAT         │
  │   │  - Doctor asks questions     │
  │   │  - Patient replies via SMS   │
  │   │  - Real-time messaging       │
  │   │  - Gather full info          │
  │   │  - Duration, severity, etc.  │
  │   └──────────────────────────────┘
  │
  └─→ Doctor rejects
      │
      ▼
      ┌──────────────────────────────┐
      │  REJECTION REASON            │
      │  - Select reason             │
      │  - SMS sent to patient       │
      │  - "Please contact other"    │
      │  - Status: REJECTED          │
      └──────────────────────────────┘
```

### 3. Doctor Creates Prescription

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DOCTOR PRESCRIPTION FLOW                         │
└─────────────────────────────────────────────────────────────────────┘

DOCTOR MOBILE APP
  │
  ▼
┌──────────────────────────────┐
│  WRITE PRESCRIPTION          │
│  - Tap "Write Prescription"   │
│  - Select medicine           │
│  - Set dosage, frequency     │
│  - Set duration, timing      │
│  - Add instructions          │
│  - Generate RX Code         │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  PRESCRIPTION CREATED        │
│  - RX Code: XYZ789           │
│  - Saved to database        │
│  - Status: PENDING          │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  SMS SENT TO PATIENT         │
│  Via Twilio:                 │
│  "Your RX Code: XYZ789"     │
│  "Medicine: Paracetamol"    │
│  "500mg, 3 times daily"     │
│  "For 7 days"               │
│  "Visit pharmacy with code"  │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  SMS SENT TO PHARMACY        │
│  Via Twilio:                 │
│  "New prescription XYZ789"   │
│  "For: John Doe"            │
│  "Medicine: Paracetamol"     │
│  "Check stock & update"      │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  PUSH NOTIFICATION           │
│  To pharmacy mobile app      │
│  - "New prescription"        │
│  - RX Code: XYZ789          │
│  - Patient: John Doe        │
└──────────────────────────────┘
```

### 4. Pharmacy Processes Prescription

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PHARMACY PROCESSING FLOW                         │
└─────────────────────────────────────────────────────────────────────┘

PHARMACY MOBILE APP
  │
  ▼
┌──────────────────────────────┐
│  RECEIVES NOTIFICATION       │
│  - Push notification         │
│  - SMS received              │
│  - Badge shows pending       │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  OPENS PRESCRIPTION          │
│  - Views RX Code: XYZ789     │
│  - Patient: John Doe        │
│  - Medicine: Paracetamol    │
│  - Dosage: 500mg            │
│  - Check stock button       │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  CHECKS MEDICINE STOCK       │
│  - Searches inventory        │
│  - Finds quantity: 50        │
│  - Status: FULLY AVAILABLE   │
│  - Updates prescription      │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  SMS SENT TO PATIENT         │
│  Via Twilio:                 │
│  "Your medicine is"          │
│  "FULLY AVAILABLE at"        │
│  "City Pharmacy, Main St"    │
│  "Hours: 8AM-8PM"           │
│  "Bring RX Code: XYZ789"    │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  PATIENT VISITS PHARMACY     │
│  - Shows RX Code: XYZ789     │
│  - Pharmacy verifies         │
│  - Dispenses medicine        │
│  - Updates status: DISPENSED  │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  SMS SENT TO PATIENT         │
│  Via Twilio:                 │
│  "Medicine dispensed"        │
│  "Follow instructions:       │
│  "Take with food, 3x daily"  │
│  "Thank you for visiting"    │
└──────────────────────────────┘
```

### 5. Optional: Lab Test Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    LAB TEST REQUEST FLOW                             │
└─────────────────────────────────────────────────────────────────────┘

DOCTOR MOBILE APP
  │
  ▼
┌──────────────────────────────┐
│  REQUESTS LAB TEST          │
│  - "Request Test" button    │
│  - Select test: TB Test     │
│  - Select clinic            │
│  - Add urgency notes        │
│  - Submit request           │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  SMS SENT TO PATIENT         │
│  Via Twilio:                 │
│  "Doctor ordered TB test"    │
│  "Please visit: City Lab"    │
│  "Address: 123 Health St"    │
│  "Hours: 9AM-5PM"           │
│  "Bring ID card"             │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  SMS SENT TO CLINIC          │
│  Via Twilio:                 │
│  "New test request"          │
│  "Patient: John Doe"        │
│  "Test: TB Test"             │
│  "From: Dr. Smith"           │
│  "Urgency: Normal"           │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  CLINIC MOBILE APP           │
│  - Receives notification     │
│  - Patient visits clinic     │
│  - Performs test             │
│  - Enters results            │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  SMS SENT TO DOCTOR          │
│  Via Twilio:                 │
│  "Test result ready"         │
│  "Patient: John Doe"        │
│  "Test: TB Test"             │
│  "Result: NEGATIVE"          │
│  "View in app"               │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  SMS SENT TO PATIENT         │
│  Via Twilio:                 │
│  "Your TB test result"       │
│  "Result: NEGATIVE"          │
│  "Dr. Smith will contact"    │
│  "No further action needed"  │
└──────────────────────────────┘
```

---

## SMS Message Templates

### From Patient Device → System
```
"I have fever and cough"
"My head hurts badly"
"I need medicine refill"
"What are your clinic hours?"
```

### From System → Patient Device
```
"Your RX Code: XYZ789
Medicine: Paracetamol 500mg
Take 3 times daily for 7 days
Visit City Pharmacy with this code"

"Your medicine is FULLY AVAILABLE at City Pharmacy, 123 Main St
Hours: 8AM-8PM
Bring RX Code: XYZ789"

"Medicine dispensed successfully.
Follow instructions: Take with food
Thank you for visiting City Pharmacy"

"Dr. Smith ordered TB test
Please visit City Lab, 456 Health St
Hours: 9AM-5PM
Bring ID card"

"Your TB test result: NEGATIVE
Dr. Smith will contact you
No further action needed"
```

### From System → Doctor (App/SMS)
```
"New consultation from patient
Case ID: ABC123
Patient: John Doe
Message: I have fever"

"Test result ready
Patient: John Doe
Test: TB Test
Result: NEGATIVE"
```

### From System → Pharmacy (App/SMS)
```
"New prescription XYZ789
Patient: John Doe
Medicine: Paracetamol 500mg
Please check stock & update status"
```

### From System → Clinic (App/SMS)
```
"New test request
Patient: John Doe
Test: TB Test
From: Dr. Smith
Urgency: Normal"
```

---

## Technical Integration Points

### 1. Twilio SMS Gateway
```
INBOUND SMS FLOW:
Patient Device → Twilio → HatiCare API → Database

OUTBOUND SMS FLOW:
Database → HatiCare API → Twilio → Patient Device

WEBHOOK ENDPOINTS:
POST /api/v1/sms/inbound - Receive patient SMS
POST /api/v1/sms/status - Delivery status updates
```

### 2. Mobile App Integrations
```
DOCTOR APP:
- Push notifications (Firebase)
- Real-time chat with patient
- Prescription creation
- Lab test requests

PHARMACY APP:
- Push notifications (Firebase)
- Prescription management
- Stock updates
- Medicine dispensing

CLINIC APP:
- Push notifications (Firebase)
- Test request management
- Result entry
- Patient management
```

### 3. Database Interactions
```
CONSULTATIONS:
- Create record from inbound SMS
- Update status (pending → accepted → completed)
- Store chat messages

PRESCRIPTIONS:
- Create with RX Code
- Update status (pending → sent_to_pharmacy → dispensed)
- Link to consultation

TEST RESULTS:
- Create from doctor request
- Update status (pending → completed)
- Link to consultation
```

---

## Error Handling & Edge Cases

### 1. SMS Delivery Failures
```
SMS FAILED TO SEND
  │
  ▼
┌──────────────────────────────┐
│  RETRY MECHANISM            │
│  - Retry 3 times            │
│  - Exponential backoff      │
│  - Log failure              │
│  - Alert admin              │
└──────────────────────────────┘
  │
  ├─→ Retry successful
  │   │
  │   ▼
  │   Message delivered
  │
  └─→ All retries failed
      │
      ▼
      ┌──────────────────────────────┐
      │  FALLBACK EMAIL              │
      │  - Send email notification   │
      │  - Mark as SMS failed       │
      │  - Manual follow-up needed   │
      │  - Alert admin              │
      └──────────────────────────────┘
```

### 2. Patient Not Registered
```
UNKNOWN PHONE NUMBER
  │
  ▼
┌──────────────────────────────┐
│  AUTO-REGISTRATION          │
│  - Create patient record     │
│  - Send welcome SMS         │
│  - Assign default doctor     │
│  - Continue consultation     │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  WELCOME SMS TO PATIENT     │
│  "Welcome to HatiCare!"      │
│  "We've registered you"      │
│  "Your doctor: Dr. Smith"    │
│  "Case ID: ABC123"          │
└──────────────────────────────┘
```

### 3. Doctor Not Available
```
DOCTOR OFFLINE/BUSY
  │
  ▼
┌──────────────────────────────┐
│  FIND BACKUP DOCTOR         │
│  - Check availability        │
│  - Assign to next doctor    │
│  - Notify patient           │
│  - Update consultation      │
└──────────────────────────────┘
  │
  ▼
┌──────────────────────────────┐
│  SMS TO PATIENT             │
│  "Dr. Smith is unavailable"  │
│  "Dr. Johnson will help"     │
│  "Your case ID: ABC123"      │
│  "Wait time: ~15 minutes"    │
└──────────────────────────────┘
```

---

## Key Benefits of SMS-Based Patient Flow

✅ **No App Required** - Patients use native SMS app
✅ **Universal Access** - Works on any mobile phone
✅ **No Internet Needed** - SMS works on 2G/3G networks
✅ **Familiar Interface** - Patients already know how to use SMS
✅ **Offline Support** - SMS queue works without internet
✅ **Low Cost** - No data charges for patients
✅ **High Reliability** - SMS delivery is very reliable
✅ **Instant Communication** - Real-time messaging
✅ **Record Keeping** - All SMS logged in system
✅ **Scalable** - Can handle thousands of SMS simultaneously

---

## Implementation Checklist

### Twilio Setup
- [ ] Configure Twilio phone number
- [ ] Set up inbound SMS webhook
- [ ] Configure SMS templates
- [ ] Set up delivery status webhooks
- [ ] Test SMS routing

### API Development
- [ ] Create `/api/v1/sms/inbound` endpoint
- [ ] Create `/api/v1/sms/outbound` endpoint
- [ ] Implement SMS parsing logic
- [ ] Add error handling and retries
- [ ] Set up logging and monitoring

### Mobile App Updates
- [ ] Add SMS notification handling
- [ ] Update doctor app for SMS patients
- [ ] Update pharmacy app for SMS notifications
- [ ] Add clinic app SMS integration
- [ ] Test end-to-end flows

### Database Updates
- [ ] Add SMS logging table
- [ ] Update consultation table for SMS source
- [ ] Add delivery status tracking
- [ ] Implement SMS queue for retries
- [ ] Set up analytics for SMS metrics

---

## Success Metrics

### SMS Performance
- SMS delivery rate: > 98%
- Average delivery time: < 30 seconds
- Failed SMS rate: < 2%
- Patient response rate: > 80%

### Clinical Outcomes
- Time to first response: < 15 minutes
- Consultation completion rate: > 90%
- Prescription fulfillment rate: > 95%
- Patient satisfaction: > 4.5/5

### Operational Metrics
- Cost per SMS consultation: < $0.50
- Doctor productivity: +30% with SMS triage
- Pharmacy efficiency: +25% faster processing
- Clinic utilization: +20% more appointments

---

## Security & Compliance

### SMS Security
- End-to-end encryption for sensitive data
- Phone number verification
- Rate limiting to prevent spam
- Audit trail for all SMS communications

### Compliance
- HIPAA compliance for PHI in SMS
- GDPR compliance for EU patients
- Consent management for SMS communications
- Data retention policies for SMS logs

### Privacy
- Phone number masking in logs
- Secure SMS template storage
- Patient opt-in/opt-out management
- Data encryption at rest and in transit
