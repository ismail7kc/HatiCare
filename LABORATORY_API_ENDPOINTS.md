# Laboratory API Endpoints - Implementation Summary

## Overview
Separated the API endpoints for Laboratory Home Screen and Laboratory Inventory Screen to fetch different data sets.

## API Endpoints

### 1. Laboratory Home Screen
- **Endpoint**: `prescriptions/laboratory/list/`
- **Purpose**: Fetch NEW test requests/prescriptions
- **Provider Method**: `fetchNewRequests()` (also accessible via `fetchPrescriptions()`)
- **Data Storage**: `_newRequests` list
- **Loading State**: `_newRequestsLoading`
- **Getters**: 
  - `newRequests` - Direct access
  - `prescriptions` - Backward compatibility (points to `_newRequests`)
  - `prescriptionsLoading` - Points to `_newRequestsLoading`

### 2. Laboratory Inventory Screen
- **Endpoint**: `prescriptions/laboratory/assigned/`
- **Purpose**: Fetch ASSIGNED test requests/prescriptions
- **Provider Method**: `fetchAssignedPrescriptions()`
- **Data Storage**: `_assignedRequests` list
- **Loading State**: `_assignedRequestsLoading`
- **Getters**:
  - `assignedRequests` - Direct access
  - `assignedRequestsLoading` - Loading state

### 3. Laboratory History Screen
- **Endpoint**: `prescriptions/laboratory/history/`
- **Purpose**: Fetch completed/historical test requests
- **Provider Method**: `fetchHistory()`
- **Data Storage**: `_completedTestRequests` list
- **Getter**: `completedTestRequests`

### 4. Accept Prescription
- **Endpoint**: `prescriptions/laboratory/{status_id}/accept/`
- **Method**: PATCH
- **Purpose**: Accept a prescription/test request
- **Provider Method**: `acceptPrescription(String statusId)`
- **Request Body**: 
  ```json
  {
    "accept": true
  }
  ```
- **Behavior**: After successful acceptance, refreshes both `_newRequests` and `_assignedRequests` lists

## Changes Made

### LaboratoryUserProvider (`laboratory_user_provider.dart`)

#### State Variables Added
```dart
// Separate lists for different screens
List<dynamic> _newRequests = []; // For Laboratory Home Screen (list endpoint)
List<dynamic> _assignedRequests = []; // For Laboratory Inventory Screen (assigned endpoint)

// Separate loading states
bool _newRequestsLoading = false;
bool _assignedRequestsLoading = false;
```

#### New Methods

1. **`fetchNewRequests()`**
   - Calls `prescriptions/laboratory/list/`
   - Populates `_newRequests`
   - Used by Laboratory Home Screen

2. **`fetchAssignedPrescriptions()`** (Updated)
   - Calls `prescriptions/laboratory/assigned/`
   - Populates `_assignedRequests`
   - Used by Laboratory Inventory Screen

#### Backward Compatibility
- `fetchTestRequests()` → calls `fetchNewRequests()`
- `fetchPrescriptions()` → calls `fetchNewRequests()`
- `prescriptions` getter → points to `_newRequests`
- `prescriptionsLoading` getter → points to `_newRequestsLoading`

### Laboratory Home Screen (`laboratory_home_screen.dart`)

#### Changes
- **initState**: Calls `provider.fetchPrescriptions()` (which internally calls `fetchNewRequests()`)
- **_onRefresh**: Calls `provider.fetchPrescriptions()`
- **Data Access**: Uses `laboratoryProvider.prescriptions` (points to `_newRequests`)
- **Loading State**: Uses `laboratoryProvider.prescriptionsLoading` (points to `_newRequestsLoading`)

### Laboratory Inventory Screen (`laboratory_inventory_screen.dart`)

#### Changes
- **_loadInventory**: Calls `provider.fetchAssignedPrescriptions()`
- **_onRefresh**: Calls `_loadInventory()` (which calls `fetchAssignedPrescriptions()`)
- **Data Access**: Uses `laboratoryProvider.assignedRequests`
- **Loading State**: Uses `laboratoryProvider.assignedRequestsLoading`

## Data Flow

### Laboratory Home Screen Flow
```
User Opens Home Screen
    ↓
initState() called
    ↓
fetchPrescriptions() → fetchNewRequests()
    ↓
API Call: prescriptions/laboratory/list/
    ↓
Data stored in _newRequests
    ↓
UI displays via prescriptions getter
```

### Laboratory Inventory Screen Flow
```
User Opens Inventory Screen
    ↓
_loadInventory() called
    ↓
fetchAssignedPrescriptions()
    ↓
API Call: prescriptions/laboratory/assigned/
    ↓
Data stored in _assignedRequests
    ↓
UI displays via assignedRequests getter
```

## Benefits

1. **Separation of Concerns**: Each screen has its own data source and endpoint
2. **Independent Data Management**: Changes to one screen's data don't affect the other
3. **Backward Compatibility**: Existing code using `prescriptions` still works
4. **Clear API Structure**: Easy to understand which endpoint serves which screen
5. **Scalability**: Easy to add more endpoints and data sources in the future

## Testing Checklist

- [ ] Laboratory Home Screen loads data from `/list/` endpoint
- [ ] Laboratory Inventory Screen loads data from `/assigned/` endpoint
- [ ] Pull-to-refresh works on both screens
- [ ] Loading states display correctly
- [ ] Empty states display when no data is available
- [ ] Error handling works for both endpoints
- [ ] Backward compatibility maintained for existing code
