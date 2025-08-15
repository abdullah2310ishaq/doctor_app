# 🏥 **FEEDBACK SYSTEM TEST GUIDE**

## **Step 1: Doctor Side Setup**
1. Login as Doctor
2. Go to Home Tab → Click "Create Sample Data" (red button)
3. Go to Feedback Tab → You should see "John Doe" in patient dropdown
4. Select "John Doe" from dropdown

## **Step 2: Patient Side Setup**
1. Login as Patient (use same account as John Doe created in sample data)
2. Go to Home Tab → You should see all buttons: Diet Plans, Prescriptions, Exercises, etc.

## **Step 3: Test Diet Plan Feedback**
**Patient Side:**
1. Click "Diet Plans"
2. Click "Log Meal" on any meal
3. Select if you ate as prescribed or not
4. Click "Save"
5. Should see: "Meal log saved and feedback sent to doctor!"

**Doctor Side:**
1. Go to Feedback Tab
2. Select "John Doe" from dropdown
3. Click "Meals" tab
4. Should see the meal feedback

## **Step 4: Test Prescription Feedback**
**Patient Side:**
1. Click "Prescriptions"
2. Click "Log Medicine" on any medication
3. Select if you took it or not
4. Click "Save"
5. Should see: "Medicine log saved and feedback sent to doctor!"

**Doctor Side:**
1. Go to Feedback Tab
2. Select "John Doe" from dropdown
3. Click "Medications" tab
4. Should see the medication feedback

## **Step 5: Test Exercise Feedback**
**Patient Side:**
1. Click "Exercises"
2. Click "Send Feedback" button
3. Should see: "Feedback sent to doctor!"

**Doctor Side:**
1. Go to Feedback Tab
2. Select "John Doe" from dropdown
3. Click "Exercise" tab
4. Should see the exercise feedback

## **Step 6: Test Weekly Feedback**
**Patient Side:**
1. Go to Home Tab
2. Look for "Weekly Health Assessment" card
3. Click "Take Assessment" button
4. Fill out the form and submit
5. Should see success message

**Doctor Side:**
1. Go to Feedback Tab
2. Select "John Doe" from dropdown
3. Click "Weekly" tab
4. Should see the weekly feedback

## **🎯 Expected Results:**
- ✅ All feedback should appear on doctor side
- ✅ Debug info should show correct Patient ID and Doctor ID
- ✅ No "Invalid data" errors
- ✅ Timestamps should be current

## **🚨 Troubleshooting:**
If feedback doesn't appear:
1. Check debug info shows correct Patient ID
2. Check debug info shows correct Doctor ID
3. Verify patient has `assignedDoctorId` set to doctor's UID
4. Check Firestore console for data in collections:
   - `diet_plan_feedback`
   - `prescription_feedback` 
   - `exercise_feedback`
   - `weekly_feedback`

## **📊 Firestore Collections Structure:**
```
diet_plan_feedback/
├── {documentId}
    ├── patientId: "patient_uid"
    ├── doctorId: "doctor_uid"
    ├── feedback: "feedback_text"
    ├── timestamp: "2024-01-01T..."
    └── status: "pending"

prescription_feedback/
├── {documentId}
    ├── patientId: "patient_uid" 
    ├── doctorId: "doctor_uid"
    ├── medicationName: "medicine_name"
    ├── taken: true/false
    ├── timestamp: "2024-01-01T..."
    └── status: "pending"

exercise_feedback/
├── {documentId}
    ├── patientId: "patient_uid"
    ├── doctorId: "doctor_uid"
    ├── totalCompleted: number
    ├── timestamp: "2024-01-01T..."
    └── status: "pending"

weekly_feedback/
├── {documentId}
    ├── patientId: "patient_uid"
    ├── doctorId: "doctor_uid"
    ├── feedback: "assessment_data"
    ├── timestamp: "2024-01-01T..."
    └── status: "pending"
``` 