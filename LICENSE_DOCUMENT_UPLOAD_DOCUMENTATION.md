# License Document Upload System - Complete Documentation

## Overview
This document describes the complete license document upload system used across Pharmacy, Laboratory, and Doctor sections in the HatiCare application.

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Components](#components)
3. [User Flow](#user-flow)
4. [Validation System](#validation-system)
5. [File Structure](#file-structure)
6. [API Integration](#api-integration)
7. [Testing Guidelines](#testing-guidelines)
8. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### High-Level Flow
```
User clicks "Upload License Document"
    ↓
Navigate to Upload Document Screen (Full-screen camera)
    ↓
User chooses: Capture OR Upload from Gallery OR Cancel
    ↓
[If Capture] → Camera → Crop → Validate → Return/Retry
[If Gallery] → File Picker → Crop (images only) → Validate → Return/Retry
[If PDF] → File Picker → Return (no validation)
    ↓
Document saved to ViewModel
    ↓
Filename displayed on profile screen
    ↓
Submitted to backend with profile data
```

---

## Components

### 1. Upload Document Screen
**Location:** `lib/features/common/presentation/screens/upload_document_screen.dart`

**Purpose:** Reusable full-screen camera interface for capturing license documents

**Features:**
- Live camera preview with decorative corners
- Capture button (takes photo from camera)
- Upload from Gallery button (select existing files)
- Supports: JPG, JPEG, PNG, PDF
- Responsive design (works on all device sizes)
- Hides bottom navigation bar when active

**Key Properties:**
```dart
UploadDocumentScreen({
  String title = 'Upload License Document',
  String subtitle = 'Please capture or upload your license document',
})
```

**Returns:**
```dart
Map<String, dynamic> {
  'file': File,      // The selected/captured file
  'fileName': String // Name of the file
}
```

---

### 2. Document Quality Validator
**Location:** `lib/core/utils/document_quality_validator.dart`

**Purpose:** AI-powered validation to ensure document quality before upload

**Validation Checks:**

#### a) Resolution Check
- **Requirement:** Minimum 400×300 pixels
- **Why:** Ensures text is readable at backend
- **Error:** "Image resolution too low. Please retake with better quality"

#### b) Brightness/Lighting Check
- **Algorithm:** Calculates average luminance across image
- **Range:** 30-220 (optimal range)
- **Sampling:** Every 10th pixel for performance
- **Errors:**
  - Too dark (≤30): "Image is too dark. Please use better lighting"
  - Too bright (≥220): "Image is overexposed. Reduce lighting or avoid flash"

#### c) Sharpness/Blur Detection
- **Algorithm:** Laplacian variance method
- **Threshold:** Variance > 100
- **How it works:** Measures edge contrast - blurry images have low variance
- **Error:** "Image is blurry. Hold camera steady and retake"

#### d) Text Detection
- **Technology:** Google ML Kit Text Recognition (OCR)
- **Requirement:** Minimum 2 text blocks detected
- **Why:** Ensures document contains readable text/numbers
- **Error:** "No text detected. Ensure document is clear and visible"

**Quality Score Calculation:**
```
Total Score =
  + 0.25 (if well lit)
  + 0.35 (if sharp)
  + 0.25 (if has text)
  + 0.10-0.15 (based on text block count)
= 0.0 to 1.0
```

---

### 3. Profile Screens Integration

#### Pharmacy Profile Screen
**Location:** `lib/features/pharmacy/presentation/screens/edit_pharmacy_profile_screen.dart`

**Integration Points:**
- Line 596: Button calls `_navigateToUploadDocument()`
- Line 1103-1126: Navigation method with `rootNavigator: true`
- Lines 592-593: Shows filename when document selected

#### Laboratory Profile Screen
**Location:** `lib/features/laboratory/presentation/screens/edit_laboratory_profile_screen.dart`

**Integration Points:**
- Line 856: Button calls `_navigateToUploadDocument()`
- Line 1285-1307: Navigation method with `rootNavigator: true`
- Lines 852-853: Shows filename when document selected

---

## User Flow

### Scenario 1: Capture from Camera

```
Step 1: User on Profile Screen (Page 2)
  └─ Clicks "Upload License Document" button

Step 2: Navigate to Upload Document Screen
  └─ Full screen camera preview opens
  └─ Bottom nav bar hidden (rootNavigator)
  └─ Shows decorative corner borders

Step 3: User Reviews Camera Preview
  └─ Adjusts document position
  └─ Ensures good lighting and focus

Step 4: User Clicks "Capture" Button
  └─ Photo captured
  └─ Loading indicator appears

Step 5: Image Cropper Opens
  └─ User adjusts crop area
  └─ Clicks OK/checkmark

Step 6: Quality Validation (Automatic)
  └─ Checks: resolution, brightness, sharpness, text
  └─ Shows loading spinner

Step 7a: If Validation PASSES
  └─ Returns to profile screen
  └─ Button shows filename (e.g., "IMG_20231219.jpg")
  └─ Document ready for submission

Step 7b: If Validation FAILS
  └─ Dialog appears: "Image Quality Warning"
  └─ Shows specific error (blur/lighting/no text)
  └─ Options:
      - "Retake" → Returns to camera
      - "Use Anyway" → Proceeds with image
```

### Scenario 2: Upload from Gallery (Image)

```
Step 1-2: Same as Capture flow

Step 3: User Clicks "Upload from Gallery"
  └─ File picker opens
  └─ User selects JPG/JPEG/PNG

Step 4: Image Cropper Opens
  └─ User crops document area
  └─ Clicks OK

Step 5-7: Same validation and return flow as Capture
```

### Scenario 3: Upload from Gallery (PDF)

```
Step 1-2: Same as above

Step 3: User Clicks "Upload from Gallery"
  └─ File picker opens
  └─ User selects PDF file

Step 4: Immediate Return
  └─ No cropping (PDFs can't be cropped)
  └─ No validation (PDFs assumed valid)
  └─ Returns to profile with filename
```

---

## Validation System

### Technical Implementation

#### Brightness Calculation
```dart
For each pixel (sampled every 10th):
  luminance = 0.299 * red + 0.587 * green + 0.114 * blue

Average luminance = sum(all luminance) / pixel count

Valid range: 30 < luminance < 220
```

#### Sharpness Calculation (Laplacian Variance)
```dart
For each pixel (sampled every 5th):
  Apply Laplacian kernel:
  laplacian = |4*center - top - bottom - left - right|

Variance = sum(laplacian²) / count

Sharp if variance > 100
```

#### Text Detection
```dart
Using Google ML Kit:
1. Process image through text recognizer
2. Count text blocks found
3. Valid if: text.isNotEmpty AND blocks >= 2
```

---

## File Structure

```
lib/
├── features/
│   ├── common/
│   │   └── presentation/
│   │       └── screens/
│   │           └── upload_document_screen.dart    # Main upload screen
│   │
│   ├── pharmacy/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── edit_pharmacy_profile_screen.dart  # Integration
│   │       └── viewmodels/
│   │           └── pharmacy_profile_view_model.dart   # Data handling
│   │
│   └── laboratory/
│       └── presentation/
│           ├── screens/
│           │   └── edit_laboratory_profile_screen.dart  # Integration
│           └── viewmodels/
│               └── laboratory_profile_view_model.dart   # Data handling
│
└── core/
    └── utils/
        └── document_quality_validator.dart        # Validation logic
```

---

## API Integration

### Data Submission

#### Pharmacy Profile Submission
**File:** `pharmacy_profile_view_model.dart`

**Endpoint:** `PATCH /phar/pharmacies/{id}/`

**Field Name:** `license_document`

```dart
// Line 732-738
if (licenseDocument1 != null) {
  request.files.add(
    await http.MultipartFile.fromPath(
      'license_document',
      licenseDocument1!.path,
    ),
  );
}
```

#### Laboratory Profile Submission
**File:** `laboratory_profile_view_model.dart`

**Endpoint:** `PATCH /lab/laboratories/{id}/`

**Field Name:** `license_document`

```dart
// Line 584-590
if (licenseDocumentFile != null) {
  final licenseDoc = await http.MultipartFile.fromPath(
    'license_document',
    licenseDocumentFile!.path,
  );
  request.files.add(licenseDoc);
}
```

**Request Format:**
```
Content-Type: multipart/form-data
Authorization: Bearer {access_token}

Fields:
- license_document: [File] (JPG/PNG/PDF)
- pharmacy_name: [String]
- address_line1: [String]
- city: [String]
- state: [String]
- country: [String]
- ... (other profile fields)
```

---

## Supported File Formats

### Images (with validation)
- **JPG/JPEG:** ✅ Validated, cropped, compressed (85% quality, max 1920x1920)
- **PNG:** ✅ Validated, cropped, compressed (85% quality, max 1920x1920)

### Documents (no validation)
- **PDF:** ✅ Uploaded directly, no size limit (handled by backend)

---

## Responsive Design

### Camera Preview Sizing
```dart
cameraWidth = (screenWidth * 0.85).clamp(280.0, 340.0)
cameraHeight = (cameraWidth * 0.75).clamp(200.0, 260.0)
```

### Device-Specific Sizes

| Device | Screen Width | Camera Size | Gallery Button | Capture Button |
|--------|--------------|-------------|----------------|----------------|
| iPhone SE | 320px | 280×210px | 220px | 272px |
| iPhone 12 | 390px | 331×248px | 253px | 342px |
| Pixel 5 | 393px | 334×250px | 255px | 345px |
| iPad Mini | 768px | 340×255px | 280px | 720px |

---

## Testing Guidelines

### Manual Testing Checklist

#### ✅ Basic Functionality
- [ ] Camera preview loads correctly
- [ ] Capture button works
- [ ] Gallery picker opens
- [ ] PDF selection works
- [ ] Image cropper appears after capture
- [ ] Image cropper appears after gallery selection
- [ ] Filename appears on profile screen after selection

#### ✅ Validation Testing

**Test Case 1: Blurry Image**
1. Take intentionally blurry photo
2. Expected: "Image is blurry. Hold camera steady and retake"
3. Options: Retake or Use Anyway

**Test Case 2: Dark Image**
1. Take photo in low light
2. Expected: "Image is too dark. Please use better lighting"
3. Options: Retake or Use Anyway

**Test Case 3: Overexposed Image**
1. Take photo with flash/bright light
2. Expected: "Image is overexposed. Reduce lighting or avoid flash"
3. Options: Retake or Use Anyway

**Test Case 4: No Text (blank paper)**
1. Take photo of blank surface
2. Expected: "No text detected. Ensure document is clear and visible"
3. Options: Retake or Use Anyway

**Test Case 5: Good Quality Document**
1. Take clear photo of license with good lighting
2. Expected: Passes validation, proceeds to profile screen
3. No error dialogs

#### ✅ Navigation Testing
- [ ] Bottom nav bar hidden on upload screen
- [ ] Back button returns to profile screen
- [ ] Screen responsive on different devices
- [ ] No overflow errors

#### ✅ Multi-Account Testing (Doctor Only)
- [ ] Complete KYC for Doctor A
- [ ] Logout
- [ ] Login as Doctor B
- [ ] KYC screen shows (fresh state)
- [ ] Login as Doctor A again
- [ ] Goes to home screen (KYC remembered for Doctor A)

---

## Troubleshooting

### Issue 1: Camera Not Showing
**Symptoms:** Black screen or loading indicator forever

**Solutions:**
1. Check camera permissions in device settings
2. Verify camera package version compatibility
3. Check console for permission errors

**Code Check:**
```dart
// upload_document_screen.dart:37-59
final permission = await Permission.camera.request();
if (!permission.isGranted) {
  // Permission denied
}
```

### Issue 2: Images Not Passing Validation
**Symptoms:** All images rejected with quality warnings

**Solutions:**
1. Check validation thresholds in `document_quality_validator.dart`
2. Review debug logs for specific scores
3. Temporarily lower thresholds for testing

**Debug Logs:**
```dart
debugPrint('Validation result: isValid=${validationResult.isValid}');
debugPrint('hasText=${validationResult.hasText}');
debugPrint('isSharp=${validationResult.isSharp}');
debugPrint('isWellLit=${validationResult.isWellLit}');
```

### Issue 3: Bottom Navigation Visible
**Symptoms:** Bottom nav bar shows on upload screen

**Solutions:**
1. Ensure `rootNavigator: true` is used
2. Check navigation code:

```dart
// Correct:
Navigator.of(context, rootNavigator: true).push(...)

// Wrong:
Navigator.push(context, ...)
```

### Issue 4: Country/State/City in Lowercase
**Symptoms:** Data sent as lowercase instead of proper case

**Solutions:**
Already fixed in:
- `pharmacy_profile_view_model.dart:710-713`
- `laboratory_profile_view_model.dart:565-568`

Use `selectedCountry/selectedState/selectedCity` instead of controller text.

### Issue 5: Filename Not Showing
**Symptoms:** Button shows "License Document (Selected)" instead of filename

**Solutions:**
Check button label uses `path.basename()`:

```dart
label: viewModel.licenseDocument1 != null
  ? path.basename(viewModel.licenseDocument1!.path)
  : 'Upload License Document'
```

### Issue 6: Previous Doctor's Data Showing
**Symptoms:** New doctor sees KYC data from previous doctor

**Solutions:**
Already fixed with doctor-specific keys:
- `idCardChecked_$doctorId`
- `licenseNumber_$doctorId`
- Auto-cleanup on different doctor login

---

## Dependencies

### Required Packages
```yaml
dependencies:
  camera: ^0.11.0+1                          # Camera functionality
  image_picker: ^1.0.0                       # Image selection
  file_picker: ^8.1.2                        # File/PDF selection
  image_cropper: 11.0.0                      # Image cropping
  permission_handler: ^11.3.1                # Camera permissions
  google_mlkit_text_recognition: ^0.15.0     # Text detection/OCR
  image: ^4.7.1                              # Image analysis
  path: (comes with flutter SDK)             # File path utilities
```

### Platform-Specific Setup

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to capture license documents</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select documents</string>
```

---

## Code Examples

### Example 1: Using Upload Document Screen

```dart
// In any profile screen
Future<void> _navigateToUploadDocument(
  BuildContext context,
  ViewModel viewModel,
  int documentNumber,
) async {
  final result = await Navigator.of(context, rootNavigator: true)
    .push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => const UploadDocumentScreen(
          title: 'Upload License Document',
          subtitle: 'Please capture or upload your license document',
        ),
      ),
    );

  if (result != null && result['file'] != null) {
    final file = result['file'] as File;
    if (documentNumber == 1) {
      viewModel.setLicenseDocument1(file);
    }
  }
}
```

### Example 2: Displaying Filename

```dart
ElevatedButton(
  label: viewModel.licenseDocument1 != null
    ? path.basename(viewModel.licenseDocument1!.path)  // Shows "license_123.pdf"
    : 'Upload License Document',                       // Default text
  onPressed: () => _navigateToUploadDocument(context, viewModel, 1),
)
```

### Example 3: Custom Validation Thresholds

```dart
// In document_quality_validator.dart
// Adjust these values if validation is too strict:

// Sharpness threshold (line ~88)
final isSharp = sharpness > 50;  // Lower = more lenient (default: 100)

// Text block requirement (line ~101)
if (!hasText || textBlocks < 1) {  // Lower = more lenient (default: 2)
```

---

## Best Practices

### 1. User Guidance
- Show clear instructions before capture
- Provide visual feedback (corner borders)
- Display helpful error messages
- Allow "Use Anyway" option for edge cases

### 2. Performance Optimization
- Sample pixels (every 5th/10th) for analysis
- Compress images to max 1920×1920
- Use 85% quality compression
- Dispose validators in cleanup

### 3. Error Handling
- Always check `mounted` before showing dialogs
- Catch and log all exceptions
- Provide user-friendly error messages
- Allow retry on failures

### 4. Data Isolation
- Use doctor-specific keys: `field_$doctorId`
- Clear previous user data on login
- Never share data across accounts
- Validate data ownership

---

## Validation Algorithm Details

### Laplacian Variance (Blur Detection)

**Mathematical Formula:**
```
For pixel at (x, y):
  Laplacian = 4*center - top - bottom - left - right

Variance = Σ(Laplacian²) / pixel_count

Higher variance = Sharper image
Lower variance = Blurrier image
```

**Why This Works:**
- Sharp images have strong edges (high gradient changes)
- Blurry images have smooth transitions (low gradient changes)
- Laplacian operator measures gradient magnitude
- Variance quantifies overall edge strength

### Brightness/Luminance Calculation

**Formula:**
```
Luminance = 0.299*R + 0.587*G + 0.114*B
```

**Why These Weights:**
- Human eye most sensitive to green (58.7%)
- Moderately sensitive to red (29.9%)
- Least sensitive to blue (11.4%)
- Standard ITU-R BT.601 coefficients

---

## Performance Metrics

### Typical Processing Times

| Operation | Duration | Notes |
|-----------|----------|-------|
| Camera initialization | 1-2 seconds | First time only |
| Capture photo | < 0.5 seconds | Instant |
| Image cropping | User-dependent | 2-10 seconds typically |
| Quality validation | 1-3 seconds | Depends on image size |
| Upload to backend | 2-5 seconds | Depends on network |

### Memory Usage
- Camera preview: ~50-100 MB
- Image processing: ~20-50 MB per image
- ML Kit model: ~10 MB (cached)

---

## Security Considerations

### Data Privacy
1. **Local Processing:** All validation happens on-device
2. **No Cloud Uploads:** ML Kit runs locally, no Google servers
3. **Temporary Files:** Camera images stored in app cache, cleared on exit
4. **Permissions:** Only requests camera when needed

### File Validation
1. **Extension Check:** Only allows pdf, jpg, jpeg, png
2. **Type Validation:** Verifies file is actually an image (not just extension)
3. **Size Limits:** Backend should enforce max file size
4. **Malware:** Consider adding virus scanning at backend

---

## Future Enhancements

### Potential Improvements
1. **Auto-edge Detection:** Automatically detect document boundaries
2. **Perspective correction:** Fix skewed documents
3. **Background removal:** Remove non-document areas
4. **ID number extraction:** OCR specific fields (license number)
5. **Duplicate detection:** Prevent same document uploaded twice
6. **Quality pre-check:** Real-time feedback before capture
7. **Multi-page support:** Upload multiple pages for one document

### Recommended Libraries
- `edge_detection` - Auto-detect document edges
- `flutter_native_image` - Advanced compression
- `flutter_document_scanner` - Professional document scanning

---

## Developer Notes

### Adding to New Sections

To add license document upload to a new section:

1. **Import the screen:**
```dart
import 'package:haticare/features/common/presentation/screens/upload_document_screen.dart';
import 'package:path/path.dart' as path;
```

2. **Add navigation method:**
```dart
Future<void> _navigateToUploadDocument(
  BuildContext context,
  YourViewModel viewModel,
) async {
  final result = await Navigator.of(context, rootNavigator: true)
    .push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => const UploadDocumentScreen(),
      ),
    );

  if (result != null && result['file'] != null) {
    viewModel.setLicenseDocument(result['file'] as File);
  }
}
```

3. **Update button:**
```dart
label: viewModel.document != null
  ? path.basename(viewModel.document!.path)
  : 'Upload Document'
```

### Customizing Validation

To adjust validation strictness, edit `document_quality_validator.dart`:

```dart
// Make blur detection more lenient
final isSharp = sharpness > 50;  // Default: 100

// Reduce text requirement
if (!hasText || textBlocks < 1) {  // Default: 2

// Expand brightness range
final isWellLit = brightness > 20 && brightness < 230;  // Default: 30-220
```

---

## Summary

The license document upload system provides:

✅ **User-Friendly:** Intuitive camera interface with visual guides
✅ **Quality Assured:** AI-powered validation ensures readable documents
✅ **Flexible:** Supports images (JPG/PNG) and PDFs
✅ **Responsive:** Works on all device sizes
✅ **Secure:** Local processing, proper permissions
✅ **Isolated:** Per-user data storage (especially for doctors)
✅ **Maintainable:** Reusable component across all sections

**Used In:**
- Pharmacy Profile (Edit Profile Page 2)
- Laboratory Profile (Edit Profile Page 2)
- Can be extended to Doctor/Patient sections

**Key Files:**
1. `upload_document_screen.dart` - Main UI
2. `document_quality_validator.dart` - Validation logic
3. `pharmacy_profile_view_model.dart` - Pharmacy data handling
4. `laboratory_profile_view_model.dart` - Laboratory data handling

---

*Last Updated: 2025-12-19*
*Version: 1.0*
