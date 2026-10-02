# MedBuddy: Alarm Lifecycle & Expected Behavior Analysis

This document outlines the expected, production-ready behavior of the local alarm system within the application. It details how the system reacts to modifications (**Edit**, **Delete**, and **Expired**) across two primary user roles: **Self** (the primary account holder) and **Dependent** (managed profiles or separate dependent logins).

---

## 1. Architectural Overview

MedBuddy uses a **Hybrid Alarm Architecture**:
1. **Source of Truth (Backend):** The backend API holds the master schedule for all medicine reminders.
2. **Execution Engine (Native OS):** The Flutter frontend uses a native bridge (`MethodChannel` -> `AlarmManager` on Android / `UNUserNotificationCenter` on iOS) to schedule exact, offline-capable local alarms.
3. **Local Registry:** A local database (`MedicineAlarmRegistry`) tracks which alarms are currently registered on the physical device. It maps each alarm to an `ownerUid` (User ID), allowing the app to isolate alarms belonging to the Caregiver (Self) from those belonging to the Dependent.

---

## 2. Behavior on "Edit" (Time/Dose Changes)

When an existing medication schedule is modified.

### Self (Primary User)
* **Trigger:** The user updates the reminder time or dosage in the app.
* **Backend:** Updates the schedule for the given `reminder_id`.
* **Device Behavior:** The app immediately triggers a sync (`scheduleAlarmsFromAPI`). The native OS looks up the existing alarm by its unique request code (derived from `reminder_id` and `dose_time`), **cancels the old alarm**, and **schedules a new alarm** with the updated timestamp and payload. 
* **Result:** Seamless transition. The old time will not ring.

### Dependent 
* **Caregiver's Device:** Behaves exactly like the "Self" scenario. If the caregiver is set up to receive the dependent's alarms, the old alarm is cancelled locally and the new one is scheduled.
* **Dependent's Device (Logged in separately):** The edit is recognized either via a background Silent Push Notification (FCM) or upon the dependent's next app launch. The local `syncMedicineAlarms` function detects the timestamp mismatch, cancels the outdated native alarm, and schedules the updated one.

---

## 3. Behavior on "Delete"

When a medication reminder is permanently removed.

### Self (Primary User)
* **Trigger:** User deletes a reminder.
* **Backend:** Deletes the record from the database.
* **Device Behavior:** The app instantly invokes `cancelReminderAlarms(reminderId)`. This purges the alarm from the local `MedicineAlarmRegistry` and issues a `cancelPendingDoseAlarm` command to the OS. 
* **Result:** The alarm is immediately and permanently destroyed on the device.

### Dependent
* **Caregiver's Device:** Instantly purged from the caregiver's device registry.
* **Dependent's Device:** Upon the next API sync, the app compares the active reminders from the server against its local `MedicineAlarmRegistry`. Because the deleted `reminder_id` is missing from the server's list, it is flagged as an "orphaned" alarm. The app then natively cancels it so it doesn't ghost-ring.

---

## 4. Behavior on "Expired"

There are two contexts of expiration in MedBuddy: **Course Expiration** (the medicine end-date is reached or inventory is empty) and **Subscription Expiration** (the user's premium plan expires).

### A. Course / Inventory Expiration
* **Self & Dependent:** 
  The backend stops returning this reminder in the active daily payload for future dates. Because the native alarms are typically scheduled on a rolling basis (or rely on the API for future days), the absence of the reminder in the API response prevents any future alarms from being registered. Existing scheduled alarms past the expiry date are dropped during the background sync cycle.

### B. Subscription Plan Expiration (Premium Expired)
* **Self (Primary User):** 
  When the app detects that the subscription has transitioned to an `expired` or `inactive` state, it invokes a strict policy enforcement function (`applyMedicineAlarmPlanPolicy(allowed: false)`). This function traverses the entire local `MedicineAlarmRegistry` and **forcibly cancels all pending native alarms**.
* **Dependent:** 
  Because dependents inherit the subscription status of the parent/caregiver account, the same policy enforcement applies. The backend flags the dependent's access as restricted, and the dependent's app will aggressively cancel all pending native alarms on their physical device until the parent's subscription is renewed.
* **Result:** Alarms completely stop ringing across all linked devices until the account returns to a valid subscription tier.

---

## Technical Summary for QA & Testing

To validate these behaviors in a production or staging environment, ensure QA testers verify the following:
1. **No Ghost Alarms:** Editing a reminder from 2:00 PM to 4:00 PM must not result in an alarm ringing at 2:00 PM.
2. **Device Isolation:** Deleting a dependent's reminder on the Caregiver's phone must eventually silence the alarm on the Dependent's physical phone after a sync.
3. **Subscription Gate:** Forcing a subscription expiry in the database must immediately mute upcoming scheduled alarms upon the next app launch or API validation check.
