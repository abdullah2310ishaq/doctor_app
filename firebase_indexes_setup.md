# Firebase Indexes Setup Guide

## 🔥 Required Composite Indexes

You need to create these indexes in Firebase Console to avoid query errors:

### **Step 1: Go to Firebase Console**
1. Visit https://console.firebase.google.com
2. Select your project: `fir-chat-app-821a5`
3. Go to **Firestore Database** → **Indexes** tab
4. Click **Create Index**

### **Step 2: Create These Indexes**

#### **Index 1: Prescriptions Collection**
```
Collection ID: prescriptions
Fields:
  - patientId (Ascending)
  - date (Descending)
```

#### **Index 2: Diet Plans Collection**
```
Collection ID: diet_plans
Fields:
  - patientId (Ascending)  
  - startDate (Descending)
```

#### **Index 3: Exercise Recommendations Collection**
```
Collection ID: exercise_recommendations
Fields:
  - patientId (Ascending)
  - createdAt (Descending)
```

#### **Index 4: Prescription Feedback Collection**
```
Collection ID: prescription_feedback
Fields:
  - doctorId (Ascending)
  - status (Ascending)
  - timestamp (Descending)
```

#### **Index 5: Diet Plan Feedback Collection**
```
Collection ID: diet_plan_feedback
Fields:
  - doctorId (Ascending)
  - timestamp (Descending)
```

#### **Index 6: Notifications Collection**
```
Collection ID: notifications
Fields:
  - patientId (Ascending)
  - createdAt (Descending)
```

#### **Index 7: Appointments Collection**
```
Collection ID: appointments
Fields:
  - patientId (Ascending)
  - appointmentTime (Ascending)
```

#### **Index 8: Doctor Prescriptions**
```
Collection ID: prescriptions
Fields:
  - doctorId (Ascending)
  - date (Descending)
```

### **Step 3: Alternative Quick Setup**

If you want to trigger index creation automatically:
1. Run the app and try to use the features
2. Firebase will show index URLs in the console errors
3. Click those URLs to create indexes automatically

### **⚠️ Index Creation Time**
- Small indexes: 1-2 minutes
- Large indexes: 5-10 minutes
- Don't worry if it takes time!

### **✅ How to Verify Indexes Work**
1. After indexes are created, restart your app
2. Try loading prescriptions and diet plans
3. No more "requires an index" errors!

---

## 🚀 **Next: Enhanced Features Implementation**

After indexes are created, we'll implement:
- ⏰ Smart meal timing reminders
- 💊 Enhanced medicine tracking
- 🏃‍♂️ Exercise videos & weekly tracking  
- 📋 Weekly feedback forms
- 🔔 Comprehensive notification system 