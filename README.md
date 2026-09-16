# DischargeIQ

DischargeIQ is a patient discharge education and teach-back system designed to help patients better understand their hospital discharge instructions.

Instead of only simplifying medical instructions, DischargeIQ uses the **teach-back method**: the patient is asked to explain important instructions in their own words, and the system evaluates whether they understood them correctly.

> **Important:** This project uses synthetic, fictional patient data for development and demonstration. No real patient information should be used.

---

## Problem

Hospital discharge instructions can be difficult for patients to understand because they often contain:

* Medical terminology
* Medication instructions
* Dosage and timing information
* Warnings and precautions
* Follow-up appointment information
* Lifestyle and recovery instructions

Poor understanding of discharge instructions can contribute to medication errors, missed follow-ups, and avoidable complications.

**DischargeIQ aims to make discharge education simpler, interactive, and focused on actual patient understanding.**

---

## How DischargeIQ Works

```text
Synthetic Patient Data
        |
        v
Flutter Mobile App
        |
        | Patient discharge information
        v
Node.js / Express Backend
        |
        | API Request
        v
Gemini API
        |
        +-----------------------------+
        |                             |
        v                             v
Simplified Instructions        Teach-Back Questions
                                      |
                                      v
                              Patient Answers
                                      |
                                      v
                              /grade-answer
                                      |
                                      v
                                Gemini API
                                      |
                                      v
                           Understanding Result
                                      |
                                      v
                              Flutter App
```

---

## Core Workflow

### 1. Patient Information

The application uses **synthetic fictional patient data** for development and demonstration.

The discharge information is entered or obtained through the Flutter mobile application.

### 2. Discharge Processing

The Flutter application sends the discharge information to the **Node.js/Express backend** through an API.

The backend validates the incoming data before processing it.

### 3. AI-Powered Simplification

The backend sends the discharge instructions to the **Gemini API**.

Gemini processes the medical information and generates:

* Patient-friendly discharge instructions
* Important instructions that need to be understood
* Teach-back questions based on those instructions

### 4. Teach-Back

Instead of simply asking the patient to read the instructions, DischargeIQ asks the patient to explain key instructions in their **own words**.

For example:

```text
Instruction:
"Take this medication twice daily after meals."

Teach-back question:
"How will you take this medication?"

Patient response:
"I will take it once at night."
```

### 5. Understanding Evaluation

The patient's response is sent to the backend through the `/grade-answer` endpoint.

The backend uses the **Gemini API** to evaluate the response against the intended instruction.

It identifies potential misunderstandings such as:

* Incorrect medication timing
* Incorrect dosage
* Missed precautions
* Incorrect follow-up information

The result is returned to the Flutter application as structured data.

### 6. Feedback

The Flutter application displays the understanding result and appropriate feedback so that misunderstandings can be identified and addressed.

---

## Technology Stack

### Frontend

* **Flutter**
* Dart
* Mobile UI
* OCR/document input

### Backend

* **Node.js**
* **Express.js**
* REST API
* Input validation
* Discharge processing
* Teach-back evaluation

### AI

* **Google Gemini API**
* Medical instruction simplification
* Teach-back question generation
* Patient response evaluation

---

## Backend Architecture

```text
Flutter App
     |
     | REST API
     v
Node.js / Express
     |
     +---- validator.js
     |
     +---- process-discharge.js
     |
     +---- grade-answer.js
     |
     +---- Gemini API
     |
     v
Structured JSON Response
     |
     v
Flutter App
```

### Backend Components

| Component              | Purpose                                          |
| ---------------------- | ------------------------------------------------ |
| `index.js`             | Starts the Express server and defines API routes |
| `validator.js`         | Validates incoming request data                  |
| `process-discharge.js` | Handles discharge instruction processing         |
| `grade-answer.js`      | Evaluates the patient's teach-back response      |
| `gemini.js`            | Handles communication with the Gemini API        |
| `CONTRACT.md`          | Documents the API request and response contract  |
| `package.json`         | Contains project dependencies and scripts        |

---

## API Flow

### Process Discharge

```text
POST /process-discharge
```

The endpoint receives discharge information and processes it using the Gemini API.

```text
Flutter
   |
   | Discharge information
   v
/process-discharge
   |
   v
Validation
   |
   v
Gemini API
   |
   +---- Simplified instructions
   |
   +---- Teach-back questions
   |
   v
Flutter
```

### Grade Teach-Back Answer

```text
POST /grade-answer
```

The endpoint receives the patient's answer and evaluates their understanding.

```text
Flutter
   |
   | Patient's answer
   v
/grade-answer
   |
   v
Gemini API
   |
   v
Understanding evaluation
   |
   v
Flutter
```

---

## Data Storage

The current hackathon prototype does **not require a persistent database**.

Synthetic patient information and discharge instructions are processed through the application workflow, and the backend returns the required results to the Flutter application.

This keeps the prototype lightweight while demonstrating the core functionality of the system.

---

## Key Innovation

Traditional discharge tools primarily focus on **simplifying medical language**.

DischargeIQ goes one step further:

```text
Complex Medical Instructions
            |
            v
     Simplification
            |
            v
     Teach-Back Question
            |
            v
     Patient's Response
            |
            v
  Understanding Evaluation
            |
            v
Identify Misunderstandings
```

The goal is not only to ask:

> **"Can the patient read this?"**

but also:

> **"Can the patient explain what they need to do?"**

---

## Privacy and Safety

This project is a **hackathon prototype** and uses only synthetic, fictional patient data for development and demonstration.

No real patient information should be entered into the application.

The system is intended to support discharge education and should **not replace healthcare professionals or clinical judgment**.

---

## Project Goal

DischargeIQ aims to make discharge education more understandable by combining:

**AI-powered simplification + teach-back + automated understanding evaluation**

This creates a more interactive approach to discharge education that focuses on whether the patient actually understands their instructions.
