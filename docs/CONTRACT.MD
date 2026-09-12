# DischargeIQ API Contract

## Version

1.0.0

## Purpose

This document defines the API contract between the DischargeIQ Flutter
application and the Node.js/Express backend.

The backend is responsible for:

1. Processing original hospital discharge instructions.
2. Simplifying instructions into patient-friendly language.
3. Translating instructions into the patient's preferred language.
4. Generating teach-back questions.
5. Grading patient teach-back answers.
6. Returning only validated JSON to the Flutter application.

All development and demonstration patient data must be synthetic.

---

# 1. System Architecture

The application follows this flow:

```text
Synthetic Patient Dataset
        |
        v
     Flutter
        |
        | POST /process-discharge
        v
 Node.js / Express
        |
        v
 Ollama
        |
        v
  Llama 3.1 8B
        |
        v
Validated JSON
        |
        v
     Flutter
        |
        | Patient answers teach-back question
        |
        | POST /grade-answer
        v
 Node.js / Express
        |
        v
 Ollama
        |
        v
  Llama 3.1 8B
        |
        v
Grade + feedback
        |
        v
     Flutter