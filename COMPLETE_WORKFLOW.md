# HatiCare Complete Workflow - Clinic, Doctor & Pharmacy Integration

## System Overview

HatiCare is a healthcare ecosystem connecting **Patients**, **Clinics/Labs**, **Doctors**, and **Pharmacies** through SMS-based communication and a mobile app.

---

## Complete End-to-End Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    COMPLETE PATIENT JOURNEY                         │
└─────────────────────────────────────────────────────────────────────┘

1. PATIENT SENDS SMS TO DOCTOR
   └─→ Patient: "I have fever and cough"
   └─→ SMS received by system
   └─→ System identifies doctor based on patient's registered doctor

2. DOCTOR RECEIVES & COMMUNICATES
   └─→ Doctor receives SMS notification
   └─→ Doctor opens app → Views patient message
   └─→ Doctor accepts consultation request
   └─→ Doctor communicates with patient via SMS/app
   └─→ Doctor gathers full information:
       ├─ Symptoms duration
       ├─ Severity level
       ├─ Medical history
       └─ Current medications
   └─→ Doctor decides if test is needed or direct prescription

3. DOCTOR WRITES PRESCRIPTION
   └─→ Doctor enters prescription in app:
       ├─ Medicine name
       ├─ Dosage (e.g., 500mg)
       ├─ Frequency (e.g., 3 times daily)
       ├─ Duration (e.g., 7 days)
       ├─ Instructions (e.g., take with food)
       └─ Timing (when to take medicine)
   └─→ System generates RX CODE (unique prescription ID)

4. PRESCRIPTION SENT TO PATIENT & PHARMACY
   └─→ Patient receives SMS: "Your RX Code: [ABC123XYZ]"
       "Medicine: Paracetamol 500mg, 3 times daily for 7 days"
   └─→ Pharmacy receives SMS: "New prescription [ABC123XYZ] for patient [name]"

5. PHARMACY CHECKS STOCK & UPDATES STATUS
   └─→ Pharmacy staff opens app
   └─→ Views prescription details
   └─→ Checks medicine availability:
       ├─ FULLY AVAILABLE → Updates status to "In Stock"
       ├─ PARTIALLY AVAILABLE → Updates status to "Partial Stock"
       └─ NOT AVAILABLE → Updates status to "Out of Stock"
   └─→ System sends SMS to patient: 
       "Your medicine [name] is FULLY AVAILABLE at [pharmacy name]"

6. PATIENT RECEIVES MEDICINE
   └─→ Patient visits pharmacy with RX Code
   └─→ Pharmacy staff verifies RX Code
   └─→ Dispenses medicine with instructions
   └─→ Updates status to "DISPENSED"
   └─→ System sends SMS to patient: "Medicine dispensed. Follow doctor's instructions"

7. OPTIONAL: CLINIC/LAB FOR TESTS (if doctor requests)
   └─→ If doctor needs test results:
       ├─ Doctor sends SMS to patient: "Visit clinic for [test_type]"
       ├─ Patient visits clinic
       ├─ Clinic staff enters test results
       ├─ System sends SMS to doctor: "Test result: [POSITIVE/NEGATIVE]"
       └─→ Doctor reviews and may adjust prescription

8. FOLLOW-UP (OPTIONAL)
   └─→ Doctor can follow up with patient via SMS
   └─→ Patient can report improvement/side effects
   └─→ Doctor can adjust prescription if needed
```

---

## Detailed Role Breakdown

### 1. DOCTOR ROLE (PRIMARY)

**What Doctor Does:**
- Register as doctor in system
- Complete doctor profile
- Receive patient SMS queries
- Communicate with patient to gather information
- Decide if test is needed
- Write prescription with:
  - Medicine name
  - Dosage (e.g., 500mg)
  - Frequency (e.g., 3 times daily)
  - Duration (e.g., 7 days)
  - Instructions (e.g., take with food)
  - Timing (when to take)
- Generate RX Code
- Send prescription to pharmacy
- Optional: Request tests from clinic
- Follow up with patient

**Key Screens:**
- `DoctorHomeScreen` - Dashboard with pending consultations
- `ConsultationDetailScreen` - View patient messages
- `WritePrescriptionScreen` - Create prescription with timing
- `ConsultationHistoryScreen` - View all consultations

---

### 2. CLINIC/LABORATORY ROLE (OPTIONAL)

**What Clinic Staff Does:**
- Register clinic/lab in system
- Complete clinic profile (name, license, address)
- Receive test requests from doctor (via SMS)
- Enter test results in app
- Send results to doctor via SMS
- Track test history

**Key Screens:**
- `ClinicHomeScreen` - Dashboard with stats
- `EnterTestResultScreen` - Submit test results
- `TestResultHistoryScreen` - View all results
- `PatientSearchScreen` - Search/create patients

**Database Fields:**
```
Clinic:
  - id, name, phone, email
  - address, city, state, country
  - licenseNumber, profilePicture
  - profileCompleted (boolean)

TestResult:
  - id, clinicId, patientId
  - patientName, patientPhone
  - testType (TB, Malaria, HIV, etc.)
  - result (Positive, Negative, Inconclusive)
  - status (pending, completed, sent)
  - testDate, notes
  - requiresFollowUp

Patient:
  - id, name, phone, email
  - dateOfBirth, gender, address
  - testResultIds (list of test IDs)
```

**API Endpoints:**
```
POST   /api/clinic/test-results/              - Submit test result
GET    /api/clinic/{clinicId}/test-results/   - Get test history
GET    /api/clinic/patients/search/           - Search patient
POST   /api/clinic/patients/                  - Create patient
GET    /api/clinic/{clinicId}/                - Get clinic profile
PATCH  /api/clinic/{clinicId}/                - Update clinic profile
```

**SMS Triggers:**
- After test result submitted → Patient SMS: "Your test result: [result]"
- After test result submitted → Doctor SMS: "New test result for patient [name]"

---

### 2. DOCTOR ROLE (PRIMARY)

**What Doctor Does:**
- Register as doctor in system
- Complete doctor profile
- Receive patient SMS queries
- Communicate with patient to gather information:
  - Symptoms duration
  - Severity level
  - Medical history
  - Current medications
- Decide if test is needed
- Write prescription with:
  - Medicine name
  - Dosage (e.g., 500mg)
  - Frequency (e.g., 3 times daily)
  - Duration (e.g., 7 days)
  - Instructions (e.g., take with food)
  - Timing (when to take)
- Generate RX Code
- Send prescription to pharmacy
- Optional: Request tests from clinic
- Follow up with patient

**Key Screens:**
- `DoctorHomeScreen` - Dashboard with pending consultations
- `ConsultationDetailScreen` - View patient messages
- `WritePrescriptionScreen` - Create prescription with timing
- `ConsultationHistoryScreen` - View all consultations

**Database Fields:**
```
Doctor:
  - id, name, phone, email
  - specialization, licenseNumber
  - profileCompleted (boolean)

Prescription:
  - id, doctorId, patientId
  - rxCode (unique identifier)
  - medications (list of medicines with dosage, frequency, duration)
  - instructions, notes
  - timing (when to take - morning/afternoon/evening)
  - createdAt, expiresAt
  - status (pending, sent_to_pharmacy, dispensed)

Consultation:
  - id, doctorId, patientId
  - status (pending, accepted, completed)
  - messages (communication history)
  - createdAt, updatedAt
```

**API Endpoints:**
```
POST   /api/doctor/consultations/             - Create consultation
GET    /api/doctor/{doctorId}/consultations/  - Get consultations
POST   /api/doctor/prescriptions/             - Create prescription
GET    /api/doctor/{doctorId}/prescriptions/  - Get prescriptions
PATCH  /api/doctor/{doctorId}/                - Update doctor profile
POST   /api/doctor/test-requests/             - Request test from clinic
```

**SMS Triggers:**
- Patient sends SMS → Doctor SMS: "New consultation from patient [name]"
- Prescription created → Patient SMS: "Your RX Code: [ABC123XYZ]\nMedicine: Paracetamol 500mg, 3 times daily for 7 days"
- Prescription created → Pharmacy SMS: "New prescription [ABC123XYZ] for patient [name]"
- Test requested → Clinic SMS: "Test request for patient [name]: [test_type]"

---

### 3. PHARMACY ROLE

**What Pharmacy Staff Does:**
- Register pharmacy in system
- Complete pharmacy profile
- Receive prescription notifications via SMS
- View prescription details in app
- Check medicine stock
- Update medicine availability status
- Dispense medicine to patient
- Track prescription history

**Key Screens:**
- `PharmacyHomeScreen` - Dashboard with pending prescriptions
- `PrescriptionDetailScreen` - View prescription details
- `UpdateStockScreen` - Update medicine availability
- `PrescriptionHistoryScreen` - View all prescriptions
- `EditPharmacyProfileScreen` - Manage pharmacy profile

**Database Fields:**
```
Pharmacy:
  - id, name, phone, email
  - address, city, state, country
  - licenseNumber, profilePicture
  - profileCompleted (boolean)

PrescriptionStatus:
  - id, prescriptionId, pharmacyId
  - status (pending, in_stock, partial_stock, out_of_stock, dispensed)
  - medicines (list with availability)
  - updatedAt

Medicine:
  - id, name, dosage
  - quantity, expiryDate
  - price
```

**API Endpoints:**
```
GET    /api/pharmacy/{pharmacyId}/prescriptions/  - Get prescriptions
PATCH  /api/pharmacy/prescriptions/{rxCode}/      - Update status
GET    /api/pharmacy/{pharmacyId}/medicines/      - Get stock
PATCH  /api/pharmacy/{pharmacyId}/                - Update pharmacy profile
```

**SMS Triggers:**
- Prescription received → Pharmacy SMS: "New prescription [ABC123XYZ]"
- Stock updated to FULLY AVAILABLE → Patient SMS: "Your medicine is FULLY AVAILABLE at [pharmacy]"
- Stock updated to PARTIAL → Patient SMS: "Your medicine is PARTIALLY AVAILABLE at [pharmacy]"
- Medicine dispensed → Patient SMS: "Medicine dispensed. Follow doctor's instructions"

---

### 4. PATIENT ROLE

**What Patient Does:**
- Send SMS with health issue
- Receive test appointment notification
- Visit clinic for test
- Receive test results via SMS
- Receive RX Code from doctor
- Visit pharmacy with RX Code
- Receive medicine
- Optional: Follow-up tests

**Patient Interactions:**
- SMS-based (for offline patients)
- Mobile app (optional, for online patients)

**Patient Receives:**
- SMS: "Your test is ready. Visit clinic at [address]"
- SMS: "Your test result: [POSITIVE/NEGATIVE]"
- SMS: "Your RX Code: [ABC123XYZ]"
- SMS: "Your medicine is FULLY AVAILABLE at [pharmacy name]"
- SMS: "Medicine dispensed. Follow doctor's instructions"

---

## Data Flow Diagram

```
┌──────────────┐
│   PATIENT    │
│  (SMS-based) │
└──────┬───────┘
       │
       │ "I have fever"
       ▼
┌──────────────────┐
│    DOCTOR        │
│  - Receives SMS  │
│  - Communicates  │
│  - Gathers info  │
│  - Writes Rx     │
│  - Generates code│
└──────┬───────────┘
       │
       │ RX Code + Prescription
       ▼
┌──────────────────┐
│   PHARMACY       │
│  - Receives SMS  │
│  - Checks stock  │
│  - Updates status│
│  - Dispenses med │
└──────┬───────────┘
       │
       │ SMS Confirmation
       ▼
┌──────────────┐
│   PATIENT    │
│  Gets Medicine
└──────────────┘

Optional Path (if tests needed):
┌──────────────┐
│    DOCTOR    │
│ Requests test│
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│  CLINIC/LAB      │
│  - Receives SMS  │
│  - Enters result │
│  - Sends SMS     │
└──────┬───────────┘
       │
       │ Test Result
       ▼
┌──────────────┐
│    DOCTOR    │
│ Reviews test │
│ Adjusts Rx   │
└──────────────┘
```

---

## Database Schema Overview

```sql
-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY,
  phone VARCHAR(20) UNIQUE,
  email VARCHAR(100),
  role ENUM('patient', 'doctor', 'pharmacy', 'clinic'),
  auth_token VARCHAR(255),
  created_at TIMESTAMP
);

-- Clinic
CREATE TABLE clinics (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  name VARCHAR(255),
  phone VARCHAR(20),
  email VARCHAR(100),
  address TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  country VARCHAR(100),
  license_number VARCHAR(100),
  profile_picture VARCHAR(255),
  profile_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP
);

-- Test Results
CREATE TABLE test_results (
  id UUID PRIMARY KEY,
  clinic_id UUID REFERENCES clinics(id),
  patient_phone VARCHAR(20),
  patient_name VARCHAR(255),
  test_type VARCHAR(100),
  result VARCHAR(100),
  status VARCHAR(50),
  notes TEXT,
  test_date TIMESTAMP,
  created_at TIMESTAMP
);

-- Doctor
CREATE TABLE doctors (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  name VARCHAR(255),
  phone VARCHAR(20),
  email VARCHAR(100),
  specialization VARCHAR(100),
  license_number VARCHAR(100),
  profile_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP
);

-- Consultations
CREATE TABLE consultations (
  id UUID PRIMARY KEY,
  doctor_id UUID REFERENCES doctors(id),
  patient_phone VARCHAR(20),
  test_result_id UUID REFERENCES test_results(id),
  status VARCHAR(50),
  created_at TIMESTAMP
);

-- Prescriptions
CREATE TABLE prescriptions (
  id UUID PRIMARY KEY,
  doctor_id UUID REFERENCES doctors(id),
  consultation_id UUID REFERENCES consultations(id),
  rx_code VARCHAR(20) UNIQUE,
  patient_phone VARCHAR(20),
  medications JSON,
  instructions TEXT,
  status VARCHAR(50),
  created_at TIMESTAMP
);

-- Pharmacy
CREATE TABLE pharmacies (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  name VARCHAR(255),
  phone VARCHAR(20),
  email VARCHAR(100),
  address TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  country VARCHAR(100),
  license_number VARCHAR(100),
  profile_picture VARCHAR(255),
  profile_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP
);

-- Prescription Status (Pharmacy View)
CREATE TABLE prescription_status (
  id UUID PRIMARY KEY,
  prescription_id UUID REFERENCES prescriptions(id),
  pharmacy_id UUID REFERENCES pharmacies(id),
  status VARCHAR(50),
  medicines JSON,
  updated_at TIMESTAMP
);
```

---

## SMS Message Templates

### From Patient
```
"I have fever and cough"
"I'm experiencing [symptoms]"
```

### From Doctor
```
"Hi [patient_name], I received your message. Can you tell me more about your symptoms?"
"Your RX Code: [ABC123XYZ]\nMedicine: Paracetamol 500mg, 3 times daily for 7 days\nTake with food. Visit pharmacy with this code."
"Please visit clinic for [test_type] test. Clinic address: [address]"
"Follow-up test required. Visit clinic for [test_type]"
```

### From Clinic
```
"Test request received from Dr. [doctor_name] for patient [patient_name]: [test_type]"
"Test result: [POSITIVE/NEGATIVE] for patient [patient_name]. Sending to doctor."
```

### From Pharmacy
```
"Your medicine [medicine_name] is FULLY AVAILABLE at [pharmacy_name], [address]"
"Your medicine [medicine_name] is PARTIALLY AVAILABLE at [pharmacy_name]"
"Your medicine [medicine_name] is OUT OF STOCK at [pharmacy_name]"
"Medicine dispensed successfully. Follow doctor's instructions: [dosage & timing]"
```

---

## Implementation Checklist

### Phase 1: Doctor Module Enhancement
- [ ] Update doctor module to receive patient SMS queries
- [ ] Add consultation messaging screen
- [ ] Add prescription creation screen with timing fields
- [ ] Implement RX Code generation
- [ ] Add SMS notification for prescriptions to patient & pharmacy
- [ ] Update doctor home screen to show pending consultations
- [ ] Add optional test request feature

### Phase 2: Pharmacy Integration
- [ ] Update pharmacy module to receive prescriptions via SMS
- [ ] Add prescription detail screen
- [ ] Implement stock status update (Fully/Partially/Out of Stock)
- [ ] Add SMS notifications for stock status to patient
- [ ] Update pharmacy home screen to show pending prescriptions
- [ ] Add medicine dispensing confirmation

### Phase 3: Clinic Module (Optional)
- [ ] Add `clinic` to UserRole enum
- [ ] Create clinic entities (Clinic, TestResult)
- [ ] Create clinic repository & data source
- [ ] Create clinic ViewModel
- [ ] Create clinic screens (Home, EnterResult, History)
- [ ] Implement clinic profile completion flow
- [ ] Add clinic routes to main.dart
- [ ] Implement SMS notifications for test results to doctor

### Phase 4: SMS Integration
- [ ] Set up SMS gateway (Twilio/AWS SNS)
- [ ] Implement SMS receiving endpoint for patient queries
- [ ] Implement SMS sending from doctor (consultation + prescription)
- [ ] Implement SMS sending from pharmacy (stock status)
- [ ] Implement SMS sending from clinic (test results)
- [ ] Add SMS routing based on patient's registered doctor

### Phase 5: Offline Support
- [ ] Implement local caching for offline access
- [ ] Add SMS-based prescription retrieval for patients
- [ ] Implement sync when online

---

## Key Features Summary

✅ **Direct Doctor Consultation** - Patient sends SMS directly to doctor
✅ **Doctor Communication** - Doctor gathers full patient information via SMS/app
✅ **Prescription Writing** - Doctor creates prescription with dosage, frequency, duration, timing
✅ **RX Code System** - Unique prescription tracking and verification
✅ **Pharmacy Integration** - Stock management and medicine dispensing
✅ **SMS Notifications** - Real-time updates for all stakeholders
✅ **Optional Clinic Module** - Doctor can request tests if needed
✅ **Offline Support** - SMS-based access for patients without internet
✅ **Profile Completion** - Mandatory profile setup for all roles
✅ **History Tracking** - Complete audit trail of all transactions

---

## Next Steps

1. **Backend API Development** - Implement all endpoints
2. **SMS Gateway Integration** - Set up Twilio or AWS SNS
3. **Doctor Module Enhancement** - Add consultation messaging & prescription
4. **Pharmacy Module Updates** - Add prescription receiving & stock management
5. **SMS Routing** - Route patient SMS to registered doctor
6. **Clinic Module** (Optional) - Add test request feature
7. **Testing & QA** - End-to-end workflow testing
8. **Deployment** - Roll out to production
