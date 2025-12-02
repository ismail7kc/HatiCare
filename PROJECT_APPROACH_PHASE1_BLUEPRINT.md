# HatiCare Project Approach - Phase 1 Blueprint
## System Requirements Specification, Technical Architecture & Implementation Roadmap

---

## Executive Summary

HatiCare is an SMS/USSD-based digital triage and diagnostics system designed to provide accessible health assessment through basic mobile phones. This document transforms the 8-phase conceptual approach into an implementation-ready blueprint with detailed specifications, architecture, and technical decisions.

**Key Objectives:**
- Enable symptom assessment via SMS/USSD for offline-first accessibility
- Classify risk levels (RED/YELLOW/GREEN) using medical triage rules
- Connect patients to doctors, laboratories, and pharmacies
- Provide multi-country scalability with offline-first capability
- Ensure GDPR/HIPAA compliance and data security

---

## Part 1: System Requirements Specification (SRS)

### 1.1 Functional Requirements

#### FR1: Patient Triage via SMS/USSD
- **FR1.1** Patient initiates consultation by sending SMS with symptoms
- **FR1.2** System routes SMS to patient's registered doctor
- **FR1.3** Doctor receives notification and can communicate via SMS/app
- **FR1.4** Triage engine processes symptoms and generates risk classification
- **FR1.5** System generates unique case ID for tracking

#### FR2: Triage Engine & Risk Classification
- **FR2.1** JSON-based rule engine processes patient responses
- **FR2.2** Multi-factor scoring: age, pregnancy status, danger signs, symptom duration, severity
- **FR2.3** Outcome classification: RED (high risk), YELLOW (medium), GREEN (low)
- **FR2.4** Outcome codes map to diseases for tracking
- **FR2.5** Automated recommendations: self-care, clinic visit, emergency, lab test
- **FR2.6** Case summary stored in patient history

#### FR3: Doctor Consultation & Prescription
- **FR3.1** Doctor views triage results and patient history
- **FR3.2** Doctor communicates with patient via SMS/app
- **FR3.3** Doctor creates prescription with: medicine name, dosage, frequency, duration, timing, instructions
- **FR3.4** System generates unique RX Code for prescription tracking
- **FR3.5** Prescription sent to patient and pharmacy via SMS
- **FR3.6** Doctor can request lab tests if needed
- **FR3.7** Doctor can add clinical notes and recommendations

#### FR4: Pharmacy Stock Management
- **FR4.1** Pharmacy receives prescription notification via SMS
- **FR4.2** Pharmacy staff checks medicine availability
- **FR4.3** Pharmacy updates status: FULLY AVAILABLE, PARTIALLY AVAILABLE, OUT OF STOCK
- **FR4.4** Patient receives SMS with medicine availability
- **FR4.5** Pharmacy marks prescription as DISPENSED after patient pickup
- **FR4.6** Pharmacy maintains medicine inventory

#### FR5: Laboratory & Diagnostics
- **FR5.1** Lab registers and manages test services
- **FR5.2** Lab receives test requests from doctor
- **FR5.3** Lab accepts results via: API, CSV/Excel, SFTP, manual entry
- **FR5.4** Results standardized to: POSITIVE, NEGATIVE, INDETERMINATE
- **FR5.5** Automated patient result notification via SMS
- **FR5.6** Full workflow tracking: Pending → Completed
- **FR5.7** Results linked to patient history

#### FR6: Patient History & Records
- **FR6.1** Complete patient demographic data stored
- **FR6.2** Consultation history maintained
- **FR6.3** Prescription history accessible
- **FR6.4** Test result history tracked
- **FR6.5** Treatment linkage documented
- **FR6.6** Follow-up recommendations recorded

#### FR7: Analytics & M&E Dashboard
- **FR7.1** Track number of triage cases
- **FR7.2** Disease trends and heatmaps
- **FR7.3** Lab turnaround time metrics
- **FR7.4** Positive rates by disease
- **FR7.5** Treatment linkage rates
- **FR7.6** Epidemiological alerts for outbreaks
- **FR7.7** Role-based reporting (operations, partners, NGOs, ministries)

#### FR8: Security & Compliance
- **FR8.1** Role-Based Access Control (RBAC)
- **FR8.2** Patient consent and opt-in logging
- **FR8.3** Full audit trails for all transactions
- **FR8.4** Encrypted data handling (AES-256)
- **FR8.5** GDPR/HIPAA-aligned workflows
- **FR8.6** Backup and disaster recovery (daily backups, 30-day retention)

### 1.2 Non-Functional Requirements

#### NFR1: Performance
- SMS response time: < 5 seconds
- API response time: < 2 seconds (p95)
- Triage engine processing: < 1 second
- Support 10,000+ concurrent SMS sessions
- Database query optimization for 1M+ patient records

#### NFR2: Availability
- 99.5% uptime SLA
- Graceful degradation during outages
- Offline-first SMS capability
- Automatic failover for critical services

#### NFR3: Scalability
- Horizontal scaling for API servers
- Database sharding by geography/clinic
- Message queue for async processing
- CDN for static assets

#### NFR4: Security
- End-to-end encryption for sensitive data
- TLS 1.3 for all communications
- API rate limiting (1000 req/min per user)
- DDoS protection
- Regular security audits (quarterly)

#### NFR5: Accessibility
- Support basic SMS (2G networks)
- USSD support for feature phones
- Multi-language support (English, Swahili, French, Arabic, etc.)
- Offline-first for SMS-based patients

#### NFR6: Compliance
- GDPR: Data minimization, consent, right to deletion
- HIPAA: PHI encryption, access controls, audit logs
- Local regulations: Country-specific data residency
- Data retention: 7 years for medical records

---

## Part 2: Technical Architecture Blueprint

### 2.1 System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         HatiCare Architecture                        │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                          CLIENT LAYER                                │
├──────────────────────────────────────────────────────────────────────┤
│  Flutter Mobile App (iOS/Android)  │  Web Portal (React/Vue)        │
│  - Patient SMS Interface           │  - Doctor Dashboard            │
│  - Doctor Consultation             │  - Pharmacy Management         │
│  - Pharmacy Stock Mgmt             │  - Lab Results Entry           │
│  - Clinic Test Entry               │  - Analytics Dashboard         │
└──────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
┌──────────────────────────────────────────────────────────────────────┐
│                      API GATEWAY LAYER                               │
├──────────────────────────────────────────────────────────────────────┤
│  - Request routing & load balancing                                  │
│  - Authentication & authorization                                    │
│  - Rate limiting & DDoS protection                                   │
│  - Request/response logging                                          │
│  - API versioning (v1, v2, etc.)                                     │
└──────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│  SMS/USSD Gateway    │  │   REST API Server    │  │  WebSocket Server    │
│  - Inbound SMS       │  │  - Triage Engine     │  │  - Real-time Chat    │
│  - Outbound SMS      │  │  - Prescription Mgmt │  │  - Notifications     │
│  - USSD Sessions     │  │  - Lab Management    │  │  - Live Updates      │
│  - Message Queue     │  │  - Analytics         │  │                      │
└──────────────────────┘  └──────────────────────┘  └──────────────────────┘
        │                           │                           │
        └───────────────────────────┼───────────────────────────┘
                                    │
┌──────────────────────────────────────────────────────────────────────┐
│                    BUSINESS LOGIC LAYER                              │
├──────────────────────────────────────────────────────────────────────┤
│  - Triage Engine (Rule-based JSON)                                   │
│  - Consultation Manager                                              │
│  - Prescription Manager                                              │
│  - Lab Result Processor                                              │
│  - Patient History Manager                                           │
│  - Analytics Engine                                                  │
│  - Notification Manager                                              │
│  - RBAC & Authorization                                              │
└──────────────────────────────────────────────────────────────────────┘
                                    │
┌──────────────────────────────────────────────────────────────────────┐
│                      DATA ACCESS LAYER                               │
├──────────────────────────────────────────────────────────────────────┤
│  - User Repository                                                   │
│  - Patient Repository                                                │
│  - Doctor Repository                                                 │
│  - Consultation Repository                                           │
│  - Prescription Repository                                           │
│  - Lab Repository                                                    │
│  - Analytics Repository                                              │
│  - Cache Layer (Redis)                                               │
└──────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│  Primary Database    │  │  Cache (Redis)       │  │  Search Index        │
│  - PostgreSQL        │  │  - Session data      │  │  - Elasticsearch     │
│  - Sharded by geo    │  │  - Patient cache     │  │  - Patient search    │
│  - Replication       │  │  - Prescription      │  │  - Analytics         │
│  - Backup (daily)    │  │  - Analytics         │  │                      │
└──────────────────────┘  └──────────────────────┘  └──────────────────────┘
        │                           │                           │
        └───────────────────────────┼───────────────────────────┘
                                    │
┌──────────────────────────────────────────────────────────────────────┐
│                    EXTERNAL INTEGRATIONS                             │
├──────────────────────────────────────────────────────────────────────┤
│  - SMS Gateway (Twilio, AWS SNS, local provider)                     │
│  - USSD Gateway (local telecom provider)                             │
│  - Payment Gateway (Stripe, M-Pesa, local)                           │
│  - Email Service (SendGrid, AWS SES)                                 │
│  - File Storage (AWS S3, local storage)                              │
│  - Analytics (Google Analytics, Mixpanel)                            │
│  - Monitoring (Datadog, New Relic, ELK Stack)                        │
└──────────────────────────────────────────────────────────────────────┘
```

### 2.2 Technology Stack

#### Backend
- **Language:** Python 3.11+
- **Framework:** Django 4.2 + Django REST Framework
- **Database:** PostgreSQL 14+ (primary), Redis 7+ (cache)
- **Search:** Elasticsearch 8+
- **Message Queue:** Celery + RabbitMQ
- **API Documentation:** OpenAPI/Swagger (drf-spectacular)
- **Authentication:** JWT (djangorestframework-simplejwt)
- **Testing:** pytest, pytest-django, factory-boy
- **Deployment:** Docker, Kubernetes, Helm

#### Frontend (Mobile)
- **Framework:** Flutter 3.10+
- **State Management:** Provider, Riverpod
- **Local Storage:** SQLite, Hive
- **HTTP Client:** Dio
- **Testing:** Flutter test, integration_test

#### Frontend (Web)
- **Framework:** React 18+ or Vue 3+
- **State Management:** Redux/Vuex
- **UI Library:** Material-UI, Tailwind CSS
- **Charts:** Chart.js, D3.js
- **Testing:** Jest, React Testing Library

#### DevOps & Infrastructure
- **Containerization:** Docker
- **Orchestration:** Kubernetes
- **CI/CD:** GitHub Actions, GitLab CI
- **Monitoring:** Prometheus, Grafana, ELK Stack
- **Logging:** Logstash, Kibana
- **Cloud:** AWS, GCP, or Azure

### 2.3 Database Schema

#### Core Tables

```sql
-- Users (Base for all roles)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR(20) UNIQUE NOT NULL,
  email VARCHAR(100) UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('patient', 'doctor', 'pharmacy', 'clinic', 'admin') NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  is_verified BOOLEAN DEFAULT FALSE,
  verification_token VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login TIMESTAMP
);

-- Patients
CREATE TABLE patients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  phone VARCHAR(20) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  date_of_birth DATE,
  gender VARCHAR(10),
  address TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  country VARCHAR(100),
  emergency_contact VARCHAR(20),
  medical_history JSONB,
  allergies JSONB,
  current_medications JSONB,
  preferred_language VARCHAR(10) DEFAULT 'en',
  consent_given BOOLEAN DEFAULT FALSE,
  consent_date TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_patient_phone (phone),
  INDEX idx_patient_country (country)
);

-- Doctors
CREATE TABLE doctors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  email VARCHAR(100),
  specialization VARCHAR(100),
  license_number VARCHAR(100) UNIQUE NOT NULL,
  license_expiry DATE,
  clinic_affiliation VARCHAR(255),
  bio TEXT,
  profile_picture VARCHAR(255),
  is_verified BOOLEAN DEFAULT FALSE,
  verification_date TIMESTAMP,
  profile_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_doctor_license (license_number),
  INDEX idx_doctor_specialization (specialization)
);

-- Consultations
CREATE TABLE consultations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  case_id VARCHAR(20) UNIQUE NOT NULL,
  status ENUM('pending', 'accepted', 'in_progress', 'completed', 'closed') DEFAULT 'pending',
  chief_complaint TEXT NOT NULL,
  triage_result JSONB,
  risk_classification VARCHAR(10),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  INDEX idx_consultation_doctor (doctor_id),
  INDEX idx_consultation_patient (patient_id),
  INDEX idx_consultation_status (status),
  INDEX idx_consultation_case_id (case_id)
);

-- Consultation Messages
CREATE TABLE consultation_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  consultation_id UUID NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id),
  sender_role VARCHAR(20),
  message_text TEXT NOT NULL,
  message_type VARCHAR(20) DEFAULT 'text',
  attachment_url VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_message_consultation (consultation_id),
  INDEX idx_message_sender (sender_id)
);

-- Prescriptions
CREATE TABLE prescriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES doctors(id),
  consultation_id UUID NOT NULL REFERENCES consultations(id),
  patient_id UUID NOT NULL REFERENCES patients(id),
  rx_code VARCHAR(20) UNIQUE NOT NULL,
  medications JSONB NOT NULL,
  instructions TEXT,
  notes TEXT,
  timing VARCHAR(100),
  status ENUM('pending', 'sent_to_pharmacy', 'partially_dispensed', 'dispensed', 'expired') DEFAULT 'pending',
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  dispensed_at TIMESTAMP,
  INDEX idx_prescription_rx_code (rx_code),
  INDEX idx_prescription_patient (patient_id),
  INDEX idx_prescription_status (status)
);

-- Pharmacies
CREATE TABLE pharmacies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  email VARCHAR(100),
  address TEXT NOT NULL,
  city VARCHAR(100),
  state VARCHAR(100),
  country VARCHAR(100),
  license_number VARCHAR(100) UNIQUE NOT NULL,
  tax_id VARCHAR(100),
  profile_picture VARCHAR(255),
  is_verified BOOLEAN DEFAULT FALSE,
  profile_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_pharmacy_license (license_number),
  INDEX idx_pharmacy_country (country)
);

-- Pharmacy Medicines
CREATE TABLE pharmacy_medicines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pharmacy_id UUID NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
  medicine_name VARCHAR(255) NOT NULL,
  dosage VARCHAR(100),
  quantity_available INT NOT NULL DEFAULT 0,
  quantity_minimum INT DEFAULT 10,
  expiry_date DATE,
  price DECIMAL(10, 2),
  supplier VARCHAR(255),
  last_restocked TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_medicine_pharmacy (pharmacy_id),
  INDEX idx_medicine_name (medicine_name)
);

-- Prescription Status (Pharmacy View)
CREATE TABLE prescription_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
  pharmacy_id UUID NOT NULL REFERENCES pharmacies(id),
  status ENUM('pending', 'in_stock', 'partial_stock', 'out_of_stock', 'dispensed') DEFAULT 'pending',
  medicines_available JSONB,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(prescription_id, pharmacy_id),
  INDEX idx_status_pharmacy (pharmacy_id)
);

-- Clinics/Laboratories
CREATE TABLE clinics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  email VARCHAR(100),
  address TEXT NOT NULL,
  city VARCHAR(100),
  state VARCHAR(100),
  country VARCHAR(100),
  license_number VARCHAR(100) UNIQUE NOT NULL,
  profile_picture VARCHAR(255),
  is_verified BOOLEAN DEFAULT FALSE,
  profile_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_clinic_license (license_number),
  INDEX idx_clinic_country (country)
);

-- Test Results
CREATE TABLE test_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  consultation_id UUID REFERENCES consultations(id),
  patient_id UUID NOT NULL REFERENCES patients(id),
  patient_phone VARCHAR(20),
  patient_name VARCHAR(255),
  test_type VARCHAR(100) NOT NULL,
  result VARCHAR(100) NOT NULL,
  status ENUM('pending', 'completed', 'sent_to_doctor') DEFAULT 'pending',
  notes TEXT,
  test_date TIMESTAMP,
  requires_follow_up BOOLEAN DEFAULT FALSE,
  referral_recommendation TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_result_clinic (clinic_id),
  INDEX idx_result_patient (patient_id),
  INDEX idx_result_test_type (test_type),
  INDEX idx_result_status (status)
);

-- Triage Rules (JSON-based)
CREATE TABLE triage_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  disease_code VARCHAR(20) UNIQUE NOT NULL,
  disease_name VARCHAR(255) NOT NULL,
  symptoms JSONB NOT NULL,
  danger_signs JSONB,
  scoring_rules JSONB NOT NULL,
  outcome_mapping JSONB,
  recommendations JSONB,
  version INT DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_rule_disease (disease_code)
);

-- Audit Logs
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  action VARCHAR(255) NOT NULL,
  resource_type VARCHAR(100),
  resource_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audit_user (user_id),
  INDEX idx_audit_resource (resource_type, resource_id),
  INDEX idx_audit_created (created_at)
);

-- Analytics Events
CREATE TABLE analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(100) NOT NULL,
  user_id UUID REFERENCES users(id),
  user_role VARCHAR(20),
  metadata JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_event_type (event_type),
  INDEX idx_event_user (user_id),
  INDEX idx_event_created (created_at)
);
```

### 2.4 API Endpoints (OpenAPI/Swagger)

#### Authentication Endpoints
```
POST   /api/v1/auth/register/          - User registration
POST   /api/v1/auth/login/             - User login
POST   /api/v1/auth/logout/            - User logout
POST   /api/v1/auth/refresh-token/     - Refresh JWT token
POST   /api/v1/auth/verify-phone/      - Verify phone number
POST   /api/v1/auth/reset-password/    - Reset password
```

#### Patient Endpoints
```
GET    /api/v1/patients/me/            - Get current patient profile
PATCH  /api/v1/patients/me/            - Update patient profile
GET    /api/v1/patients/consultations/ - Get patient consultations
GET    /api/v1/patients/prescriptions/ - Get patient prescriptions
GET    /api/v1/patients/test-results/  - Get patient test results
POST   /api/v1/patients/send-sms/      - Send SMS to doctor
```

#### Doctor Endpoints
```
GET    /api/v1/doctors/me/             - Get doctor profile
PATCH  /api/v1/doctors/me/             - Update doctor profile
GET    /api/v1/doctors/consultations/  - Get doctor consultations
POST   /api/v1/doctors/consultations/{id}/accept/ - Accept consultation
POST   /api/v1/doctors/consultations/{id}/messages/ - Send message
GET    /api/v1/doctors/consultations/{id}/messages/ - Get messages
POST   /api/v1/doctors/prescriptions/  - Create prescription
GET    /api/v1/doctors/prescriptions/  - Get prescriptions
POST   /api/v1/doctors/test-requests/  - Request test from clinic
```

#### Pharmacy Endpoints
```
GET    /api/v1/pharmacies/me/          - Get pharmacy profile
PATCH  /api/v1/pharmacies/me/          - Update pharmacy profile
GET    /api/v1/pharmacies/prescriptions/ - Get prescriptions
PATCH  /api/v1/pharmacies/prescriptions/{rx_code}/ - Update prescription status
GET    /api/v1/pharmacies/medicines/   - Get medicine inventory
PATCH  /api/v1/pharmacies/medicines/{id}/ - Update medicine stock
```

#### Clinic Endpoints
```
GET    /api/v1/clinics/me/             - Get clinic profile
PATCH  /api/v1/clinics/me/             - Update clinic profile
POST   /api/v1/clinics/test-results/   - Submit test result
GET    /api/v1/clinics/test-results/   - Get test results
GET    /api/v1/clinics/patients/search/ - Search patient
POST   /api/v1/clinics/patients/       - Create patient
```

#### Triage Engine Endpoints
```
POST   /api/v1/triage/assess/          - Run triage assessment
GET    /api/v1/triage/rules/           - Get triage rules
POST   /api/v1/triage/rules/           - Create/update triage rule (admin)
```

#### Analytics Endpoints
```
GET    /api/v1/analytics/cases/        - Get case statistics
GET    /api/v1/analytics/diseases/     - Get disease trends
GET    /api/v1/analytics/lab-turnaround/ - Get lab turnaround time
GET    /api/v1/analytics/treatment-linkage/ - Get treatment linkage
GET    /api/v1/analytics/alerts/       - Get epidemiological alerts
```

#### SMS/USSD Endpoints
```
POST   /api/v1/sms/inbound/            - Receive inbound SMS
POST   /api/v1/sms/send/               - Send SMS (internal)
POST   /api/v1/ussd/session/           - Handle USSD session
```

---

## Part 3: SMS/USSD Workflow

### 3.1 SMS Flow Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                        SMS FLOW DIAGRAM                              │
└──────────────────────────────────────────────────────────────────────┘

PATIENT SENDS SMS
    │
    ▼
SMS GATEWAY (Twilio/AWS SNS/Local)
    │
    ▼
INBOUND SMS WEBHOOK
    │
    ├─→ Parse phone number & message
    ├─→ Find patient in database
    ├─→ Validate patient consent
    │
    ▼
ROUTE TO DOCTOR
    │
    ├─→ Find patient's registered doctor
    ├─→ Create consultation record
    ├─→ Send notification to doctor
    │
    ▼
DOCTOR RECEIVES NOTIFICATION
    │
    ├─→ App notification
    ├─→ SMS notification
    │
    ▼
DOCTOR REVIEWS & COMMUNICATES
    │
    ├─→ Reads patient message
    ├─→ Gathers more information via SMS/app
    ├─→ Decides: Direct prescription OR Lab test needed
    │
    ├─→ IF LAB TEST NEEDED:
    │   ├─→ Doctor requests test from clinic
    │   ├─→ Clinic receives SMS notification
    │   ├─→ Clinic enters test results
    │   ├─→ Results sent to doctor
    │   ├─→ Doctor reviews results
    │
    ▼
DOCTOR WRITES PRESCRIPTION
    │
    ├─→ Enters medicine details
    ├─→ Sets dosage, frequency, duration, timing
    ├─→ Generates RX Code
    │
    ▼
PRESCRIPTION SENT
    │
    ├─→ Patient SMS: "Your RX Code: [ABC123XYZ]"
    ├─→ Pharmacy SMS: "New prescription [ABC123XYZ]"
    │
    ▼
PHARMACY RECEIVES & CHECKS STOCK
    │
    ├─→ Pharmacy staff opens app
    ├─→ Views prescription details
    ├─→ Checks medicine availability
    ├─→ Updates status (Fully/Partially/Out of Stock)
    │
    ▼
PATIENT RECEIVES STOCK STATUS
    │
    ├─→ SMS: "Your medicine is FULLY AVAILABLE at [pharmacy]"
    │
    ▼
PATIENT VISITS PHARMACY
    │
    ├─→ Provides RX Code
    ├─→ Pharmacy verifies and dispenses
    ├─→ Updates status to DISPENSED
    │
    ▼
PATIENT RECEIVES CONFIRMATION
    │
    └─→ SMS: "Medicine dispensed. Follow doctor's instructions"
```

### 3.2 USSD Flow (Feature Phone Support)

```
PATIENT DIALS USSD CODE
    │
    ▼
USSD GATEWAY
    │
    ▼
MAIN MENU
    ├─→ 1. Report Symptoms
    ├─→ 2. Check Prescription
    ├─→ 3. Check Test Results
    ├─→ 4. Clinic Locator
    │
    ▼ (User selects 1)
SYMPTOM ENTRY
    │
    ├─→ "What symptoms do you have?"
    ├─→ User enters: "fever, cough"
    │
    ▼
TRIAGE QUESTIONS
    │
    ├─→ "How long have you had fever?"
    ├─→ User enters: "3 days"
    ├─→ "Severity (1-10)?"
    ├─→ User enters: "7"
    │
    ▼
RISK CLASSIFICATION
    │
    ├─→ System calculates: RED/YELLOW/GREEN
    ├─→ Displays recommendation
    ├─→ "You need to visit a doctor. Your case ID: [ABC123]"
    │
    ▼
ROUTE TO DOCTOR
    │
    └─→ Doctor receives SMS with case details
```

### 3.3 SMS Message Templates

#### Patient → System
```
"I have fever and cough"
"I'm experiencing headache and body pain"
"Check my prescription status"
"What's my test result?"
```

#### System → Patient
```
"Hi [Name], your case ID is [ABC123]. A doctor will contact you shortly."
"Your RX Code: [ABC123XYZ]
Medicine: Paracetamol 500mg
Dosage: 3 times daily for 7 days
Take with food. Visit pharmacy with this code."

"Your medicine is FULLY AVAILABLE at [Pharmacy Name], [Address]"
"Your test result: NEGATIVE. Please visit doctor for follow-up."
"Medicine dispensed successfully. Follow doctor's instructions."
```

#### Doctor → Patient
```
"Hi [Patient], I received your message. Can you tell me more about your symptoms?"
"How long have you had these symptoms?"
"Please visit clinic for TB test. Address: [clinic address]"
"Your prescription is ready. RX Code: [ABC123XYZ]"
```

#### Clinic → Patient
```
"Your test result is ready. Please visit clinic to collect."
"Your test result: POSITIVE. Please see doctor for treatment."
```

#### Pharmacy → Patient
```
"New prescription received: [medicine name]"
"Your medicine is OUT OF STOCK. Please check another pharmacy."
"Medicine dispensed. Thank you for visiting us."
```

---

## Part 4: Triage Ruleset Structure & Scoring Framework

### 4.1 JSON-Based Triage Rule Example

```json
{
  "disease_code": "TB",
  "disease_name": "Tuberculosis",
  "symptoms": [
    "persistent_cough",
    "chest_pain",
    "hemoptysis",
    "night_sweats",
    "weight_loss",
    "fever"
  ],
  "danger_signs": [
    "hemoptysis",
    "severe_chest_pain",
    "difficulty_breathing",
    "confusion"
  ],
  "scoring_rules": {
    "age_factor": {
      "0-5": 0.5,
      "6-18": 0.7,
      "19-65": 1.0,
      "65+": 1.2
    },
    "symptom_duration": {
      "0-7_days": 0.5,
      "8-14_days": 0.8,
      "15-30_days": 1.0,
      "30+_days": 1.5
    },
    "symptom_severity": {
      "mild": 0.5,
      "moderate": 1.0,
      "severe": 1.5
    },
    "danger_sign_multiplier": 2.0,
    "pregnancy_multiplier": 1.3
  },
  "outcome_mapping": {
    "score_0_3": {
      "classification": "GREEN",
      "recommendation": "Self-care, monitor symptoms",
      "action": "home_care"
    },
    "score_3_6": {
      "classification": "YELLOW",
      "recommendation": "Visit clinic for evaluation",
      "action": "clinic_visit"
    },
    "score_6_10": {
      "classification": "RED",
      "recommendation": "Urgent clinic visit or emergency",
      "action": "urgent_clinic"
    }
  },
  "recommendations": {
    "GREEN": [
      "Rest and stay hydrated",
      "Monitor temperature",
      "Avoid close contact with others",
      "Seek care if symptoms worsen"
    ],
    "YELLOW": [
      "Visit clinic within 24-48 hours",
      "Get TB test (chest X-ray or sputum test)",
      "Avoid close contact with others",
      "Take precautions if coughing"
    ],
    "RED": [
      "Visit clinic immediately or go to emergency",
      "Get urgent TB test",
      "Isolate from others",
      "Call ambulance if severe symptoms"
    ]
  }
}
```

### 4.2 Scoring Algorithm

```python
def calculate_triage_score(patient_data, triage_rule):
    """
    Calculate risk score based on patient data and triage rules
    
    Inputs:
    - patient_data: {age, symptoms, severity, duration, danger_signs, pregnancy}
    - triage_rule: JSON rule structure
    
    Output:
    - score (0-10), classification (RED/YELLOW/GREEN), recommendations
    """
    
    score = 0.0
    
    # 1. Age factor
    age = patient_data['age']
    age_factor = get_age_factor(age, triage_rule)
    score += age_factor
    
    # 2. Symptom duration factor
    duration = patient_data['symptom_duration_days']
    duration_factor = get_duration_factor(duration, triage_rule)
    score += duration_factor
    
    # 3. Symptom severity factor
    severity = patient_data['severity']  # mild, moderate, severe
    severity_factor = get_severity_factor(severity, triage_rule)
    score += severity_factor
    
    # 4. Danger signs multiplier
    if has_danger_signs(patient_data, triage_rule):
        score *= triage_rule['scoring_rules']['danger_sign_multiplier']
    
    # 5. Pregnancy multiplier
    if patient_data.get('is_pregnant', False):
        score *= triage_rule['scoring_rules']['pregnancy_multiplier']
    
    # 6. Normalize score to 0-10
    score = min(score, 10.0)
    
    # 7. Classify based on score
    classification = classify_score(score, triage_rule)
    
    # 8. Get recommendations
    recommendations = get_recommendations(classification, triage_rule)
    
    return {
        'score': round(score, 2),
        'classification': classification,
        'recommendations': recommendations,
        'disease_code': triage_rule['disease_code'],
        'disease_name': triage_rule['disease_name']
    }
```

### 4.3 Disease-Symptom Mapping

```json
{
  "diseases": [
    {
      "code": "TB",
      "name": "Tuberculosis",
      "symptoms": ["persistent_cough", "chest_pain", "hemoptysis", "night_sweats", "weight_loss", "fever"],
      "tests": ["chest_xray", "sputum_test", "mantoux_test"],
      "treatment": "Anti-TB drugs (RIPE regimen)"
    },
    {
      "code": "MALARIA",
      "name": "Malaria",
      "symptoms": ["fever", "chills", "headache", "muscle_pain", "nausea", "vomiting"],
      "tests": ["blood_smear", "rapid_test", "pcr"],
      "treatment": "Artemisinin-based combination therapy"
    },
    {
      "code": "HIV",
      "name": "HIV/AIDS",
      "symptoms": ["fever", "fatigue", "rash", "sore_throat", "swollen_lymph_nodes"],
      "tests": ["hiv_rapid_test", "hiv_elisa", "cd4_count"],
      "treatment": "Antiretroviral therapy (ART)"
    },
    {
      "code": "COVID19",
      "name": "COVID-19",
      "symptoms": ["fever", "cough", "fatigue", "loss_of_taste", "difficulty_breathing"],
      "tests": ["rapid_antigen", "pcr", "antibody_test"],
      "treatment": "Supportive care, vaccination"
    }
  ]
}
```

---

## Part 5: Implementation Roadmap

### Phase 1: Requirements & Technical Design (Weeks 1-4)
- ✅ Complete SRS document
- ✅ Finalize technical architecture
- ✅ Design database schema
- ✅ Create API specification (OpenAPI/Swagger)
- ✅ Define SMS/USSD workflows
- ✅ Create triage rule templates
- ✅ Security & compliance review

### Phase 2: Core Backend & Infrastructure (Weeks 5-12)
- [ ] Set up Django project with DRF
- [ ] Configure PostgreSQL, Redis, Elasticsearch
- [ ] Implement user authentication (JWT)
- [ ] Create patient, doctor, pharmacy, clinic models
- [ ] Set up SMS gateway integration (Twilio/AWS SNS)
- [ ] Implement RBAC system
- [ ] Set up CI/CD pipeline (GitHub Actions)
- [ ] Configure Docker & Kubernetes
- [ ] Set up monitoring (Prometheus, Grafana)
- [ ] Implement logging (ELK Stack)

### Phase 3: Triage Engine Development (Weeks 13-18)
- [ ] Implement JSON-based rule engine
- [ ] Create triage assessment API
- [ ] Build scoring algorithm
- [ ] Implement disease-symptom mapping
- [ ] Create triage result storage
- [ ] Build triage history tracking
- [ ] Implement outcome recommendations
- [ ] Add multi-language support

### Phase 4: SMS/USSD Workflow Engine (Weeks 19-24)
- [ ] Implement SMS inbound handler
- [ ] Create SMS outbound queue
- [ ] Build USSD session manager
- [ ] Implement step-based question flow
- [ ] Add session memory/state management
- [ ] Create message templates
- [ ] Implement retry/error handling
- [ ] Add SMS rate limiting

### Phase 5: Doctor & Teleconsultation Module (Weeks 25-30)
- [ ] Create doctor dashboard
- [ ] Implement consultation messaging
- [ ] Build prescription creation screen
- [ ] Implement RX Code generation
- [ ] Add test request feature
- [ ] Create clinical notes system
- [ ] Build case escalation workflow
- [ ] Implement doctor notifications

### Phase 6: Laboratory & Diagnostics Module (Weeks 31-36)
- [ ] Create lab registration system
- [ ] Build test result submission API
- [ ] Implement CSV/Excel import
- [ ] Add SFTP integration
- [ ] Create result standardization
- [ ] Build patient result notifications
- [ ] Implement workflow tracking
- [ ] Add result linking to patient history

### Phase 7: Monitoring, Analytics & M&E Dashboard (Weeks 37-42)
- [ ] Build analytics data pipeline
- [ ] Create KPI calculations
- [ ] Build disease trend analysis
- [ ] Implement heatmaps
- [ ] Create lab turnaround time tracking
- [ ] Build treatment linkage reports
- [ ] Implement epidemiological alerts
- [ ] Create role-based dashboards

### Phase 8: Security, Privacy & Compliance (Weeks 43-48)
- [ ] Implement data encryption (AES-256)
- [ ] Set up TLS/SSL
- [ ] Create audit logging system
- [ ] Implement consent management
- [ ] Add data retention policies
- [ ] Create backup/disaster recovery
- [ ] Conduct security audit
- [ ] Implement GDPR/HIPAA compliance

---

## Part 6: Current Implementation Status

### Completed (From Previous Phases)
✅ Flutter mobile app with authentication
✅ Pharmacy profile management
✅ Doctor consultation module (basic)
✅ Clinic/Lab module (basic)
✅ Phone number parsing for international numbers
✅ Profile completion enforcement
✅ Signup screen with validation

### In Progress
🔄 Backend API development
🔄 SMS integration
🔄 Triage engine

### Pending
⏳ USSD support
⏳ Analytics dashboard
⏳ Advanced security features
⏳ Multi-language support
⏳ Offline-first capability

---

## Part 7: Key Technical Decisions

### 1. Database Choice: PostgreSQL
- **Reason:** ACID compliance, JSONB support for flexible data, excellent for healthcare data
- **Sharding Strategy:** By geography/clinic for scalability
- **Replication:** Master-slave for high availability

### 2. Message Queue: Celery + RabbitMQ
- **Reason:** Async processing for SMS, email, notifications
- **Use Cases:** SMS sending, email notifications, analytics processing, report generation

### 3. Caching: Redis
- **Reason:** Fast session management, consultation state, patient cache
- **TTL:** 24 hours for patient data, 1 hour for session data

### 4. Search: Elasticsearch
- **Reason:** Fast patient search, disease trend analysis, analytics
- **Indexes:** Patient index, consultation index, analytics index

### 5. SMS Gateway: Twilio (Primary) + Local Provider (Fallback)
- **Reason:** Reliable, multi-country support, USSD capability
- **Fallback:** Local SMS provider for cost optimization

### 6. Authentication: JWT + OAuth2
- **Reason:** Stateless, scalable, supports mobile and web
- **Refresh Token:** 7 days, Access Token: 1 hour

### 7. API Versioning: URL-based (/api/v1/, /api/v2/)
- **Reason:** Clear separation, backward compatibility

### 8. Deployment: Kubernetes on AWS/GCP
- **Reason:** Auto-scaling, high availability, cost optimization
- **Monitoring:** Prometheus + Grafana

---

## Part 8: Security & Compliance Framework

### 8.1 Data Encryption
- **At Rest:** AES-256 for sensitive fields (medical history, test results)
- **In Transit:** TLS 1.3 for all API communications
- **Database:** PostgreSQL native encryption

### 8.2 Access Control
- **RBAC:** Patient, Doctor, Pharmacy, Clinic, Admin roles
- **API Permissions:** Role-based endpoint access
- **Audit Logging:** All actions logged with user, timestamp, IP

### 8.3 Patient Consent
- **Opt-in:** Explicit consent required before SMS
- **Consent Logging:** Timestamp, method, version of consent
- **Right to Deletion:** GDPR compliance for data removal

### 8.4 Compliance
- **GDPR:** Data minimization, consent, right to deletion, data portability
- **HIPAA:** PHI encryption, access controls, audit trails
- **Local Regulations:** Country-specific data residency (data stored in-country)

### 8.5 Backup & Disaster Recovery
- **Backup Frequency:** Daily incremental, weekly full
- **Retention:** 30 days for incremental, 1 year for full
- **Recovery Time Objective (RTO):** 4 hours
- **Recovery Point Objective (RPO):** 1 hour

---

## Part 9: Monitoring & Observability

### 9.1 Metrics to Track
- **API Response Time:** p50, p95, p99
- **SMS Delivery Rate:** % of SMS successfully delivered
- **Triage Engine Accuracy:** % of correct classifications
- **Database Query Time:** Slow query detection
- **Error Rate:** % of failed requests
- **User Engagement:** Active users, consultation completion rate

### 9.2 Logging Strategy
- **Application Logs:** Django logging to ELK Stack
- **API Logs:** Request/response logging with Chucker (mobile)
- **Database Logs:** Slow query logs
- **Audit Logs:** All user actions in database

### 9.3 Alerting
- **High Error Rate:** Alert if error rate > 5%
- **High Latency:** Alert if p95 response time > 5s
- **SMS Delivery Failure:** Alert if delivery rate < 95%
- **Database Connectivity:** Alert on connection failures

---

## Part 10: Success Metrics & KPIs

### Clinical Outcomes
- **Triage Accuracy:** % of correct risk classifications
- **Treatment Linkage:** % of patients who received treatment
- **Test Turnaround Time:** Average time from test request to result
- **Patient Satisfaction:** NPS score, feedback ratings

### Operational Metrics
- **System Uptime:** 99.5% target
- **API Response Time:** < 2 seconds (p95)
- **SMS Delivery Rate:** > 98%
- **Cost per Consultation:** Target reduction of 30%

### Adoption Metrics
- **Active Users:** Monthly active users by role
- **Consultation Volume:** Number of consultations per month
- **Geographic Coverage:** Number of countries/regions
- **User Retention:** % of users returning after 30 days

---

## Conclusion

This Phase 1 Blueprint provides a complete, implementation-ready specification for HatiCare. It bridges the conceptual 8-phase approach with detailed technical requirements, architecture, and roadmap.

**Next Steps:**
1. Review and approve this blueprint with stakeholders
2. Begin Phase 2: Backend infrastructure setup
3. Finalize API contracts with frontend teams
4. Set up development environment and CI/CD
5. Begin backend development with TDD approach

---

## Appendix: Glossary

- **RX Code:** Unique prescription identifier for tracking
- **Triage:** Process of assessing and prioritizing patient cases
- **RBAC:** Role-Based Access Control
- **HIPAA:** Health Insurance Portability and Accountability Act
- **GDPR:** General Data Protection Regulation
- **USSD:** Unstructured Supplementary Service Data (feature phone support)
- **SMS:** Short Message Service
- **API:** Application Programming Interface
- **JWT:** JSON Web Token
- **JSONB:** JSON Binary (PostgreSQL data type)
- **Celery:** Distributed task queue
- **RabbitMQ:** Message broker
- **Elasticsearch:** Search and analytics engine
- **ELK Stack:** Elasticsearch, Logstash, Kibana (logging solution)
- **TLS:** Transport Layer Security
- **AES:** Advanced Encryption Standard
- **RTO:** Recovery Time Objective
- **RPO:** Recovery Point Objective
- **NPS:** Net Promoter Score
- **KPI:** Key Performance Indicator
- **M&E:** Monitoring & Evaluation
