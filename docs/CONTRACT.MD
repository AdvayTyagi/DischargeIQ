# DischargeIQ API Contract

This document defines the interface between the Flutter app and the
DischargeIQ Node.js backend.

All patient data used for development/demo purposes is synthetic.

---

# 1. Process Discharge

## Endpoint

POST `/process-discharge`

## Purpose

Takes a patient's original discharge instructions and returns:

- simplified patient-friendly instructions
- teach-back questions

## Request

```json
{
  "patientId": "P001",
  "dischargeText": "Take amoxicillin 500 mg by mouth three times a day for 7 days. Drink plenty of fluids and rest. Check your temperature twice a day. Call your doctor if your fever reaches 102°F (38.9°C) or higher, or if your breathing gets worse. Schedule a follow-up appointment with your primary care doctor for September 17, 2026."
}