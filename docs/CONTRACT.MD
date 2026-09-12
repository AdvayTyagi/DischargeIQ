# DischargeIQ API Contract

<<<<<<< HEAD
This is the real, exact set of rules for talking to the backend.
It was written by reading `server/index.js` and `server/validator.js`
directly — not guessed. If the backend code ever changes, this file
needs to be updated to match.

The backend runs at `http://localhost:3000` on your computer
(port comes from `PORT` in `.env`, but 3000 is the default).

---

## 1. Checking the discharge text — `POST /process-discharge`

### What you send
=======
## Version
1.0.0

## Status
Confirmed against the current Node.js/Express backend implementation.

## Purpose

This document is the single source of truth for Flutter ↔ Node.js API integration.

The backend:
1. Processes original hospital discharge instructions.
2. Simplifies/translates them into the patient's preferred language.
3. Generates teach-back questions.
4. Grades patient teach-back answers.
5. Validates the LLM output before returning it to Flutter.

All development/demo patient data must be synthetic.

---

# 1. Base URL and server

## Development

The server listens on:

```text
http://localhost:${PORT}
```

where `PORT` is read from `server/.env`. If `PORT` is not defined, the backend defaults to:

```text
3000
```

Therefore, when `PORT` is not set:

```text
http://localhost:3000
```

For Android Emulator, `localhost` points to the emulator itself. When the Node.js server is running on the development computer, Flutter Android Emulator should normally use:

```text
http://10.0.2.2:<PORT>
```

For a physical device, use the development computer's LAN IP and ensure the phone and computer are on the same network.

## Protocol

HTTP. The current backend does not configure HTTPS itself.

## Authentication

None. The current routes do not use authentication middleware, API keys, bearer tokens, sessions, or cookies.

## CORS

CORS is enabled with the default `cors()` configuration.

## Required headers

For JSON requests:

```http
Content-Type: application/json
```

No authentication header is required.

---

# 2. POST /process-discharge

## Endpoint

```http
POST /process-discharge
```

Development example:

```text
http://localhost:3000/process-discharge
```

or, for Android Emulator with the default port:

```text
http://10.0.2.2:3000/process-discharge
```

## Processing model

Synchronous.

Flutter sends the request and waits for the HTTP response. There is:
- no job ID,
- no asynchronous status response,
- no polling endpoint.

The server waits for Ollama to generate and validate the result before returning the response.

---

# 3. Request JSON

## Exact schema
>>>>>>> e5e41e5c486f13ddb482259e01a571ef229779d1

```json
{
  "patientId": "P001",
<<<<<<< HEAD
  "preferredLanguage": "en",
  "dischargeText": "Take amoxicillin 500 mg by mouth three times a day for 7 days..."
}
```

All three fields are required. They all must be plain text (strings),
and none of them can be empty. If you leave one out, or send an empty
string, the server will reject the request right away with an error
message telling you which field was the problem.

### What you get back
=======
  "preferredLanguage": "English",
  "dischargeText": "Take amoxicillin 500 mg three times a day for 7 days. Follow up with your doctor on January 15, 2026."
}
```

## Fields

| Field | Type | Required | Limits | Meaning |
|---|---|---|---|---|
| `patientId` | string | Yes | No explicit application-level length limit | Synthetic patient identifier |
| `preferredLanguage` | string | Yes | No explicit application-level length limit | Language requested for the patient-facing instructions |
| `dischargeText` | string | Yes | No explicit application-level text-length limit | Original hospital discharge instructions |

For all three fields:
- The field must exist.
- The value must be a string.
- The string must not be empty after trimming whitespace.

There are no other request fields required by the current route.

## Request size

`express.json()` is enabled without an explicit `limit` option. Express's default JSON body-parser limit is 100 KB.

So the practical maximum JSON request body is approximately:

```text
100 KB
```

This is a transport/body-parser limit, not a separate character limit on `dischargeText`.

The backend does **not** currently define a separate maximum character count for:
- `patientId`
- `preferredLanguage`
- `dischargeText`

---

# 4. Successful /process-discharge response

## HTTP status

```http
200 OK
```

## Exact JSON structure
>>>>>>> e5e41e5c486f13ddb482259e01a571ef229779d1

```json
{
  "patientId": "P001",
<<<<<<< HEAD
  "preferredLanguage": "en",
  "simplifiedInstructions": [
    "Take your antibiotic three times a day for 7 days.",
    "Drink fluids and rest.",
    "Check your temperature twice a day."
  ],
  "teachBackQuestions": [
    { "id": "q1", "question": "How many times a day should you take your antibiotic?" },
    { "id": "q2", "question": "What should you do if your fever goes above 102°F?" }
=======
  "preferredLanguage": "English",
  "simplifiedInstructions": [
    "Take amoxicillin 500 mg three times a day for 7 days.",
    "Follow up with your doctor on January 15, 2026."
  ],
  "teachBackQuestions": [
    {
      "id": "Q1",
      "question": "How many times a day should you take amoxicillin?"
    },
    {
      "id": "Q2",
      "question": "How long should you take amoxicillin?"
    }
>>>>>>> e5e41e5c486f13ddb482259e01a571ef229779d1
  ]
}
```

<<<<<<< HEAD
Rules about this response:
- `patientId` will always match what you sent in.
- `preferredLanguage` will always match what you sent in.
- `simplifiedInstructions` is a list of short sentences. It will never be empty.
- `teachBackQuestions` is a list of questions, each with an `id` and a `question` string. It will never be empty — there's always at least one question.

### What can go wrong

- If you're missing a field or sent an empty one → you get an error immediately, no processing happens.
- If the AI's answer doesn't actually match the important facts in the original text (like drug doses, dates, or how many times a day) → the server blocks it and returns an error. This is a safety check the backend already does for you. **You don't need to build this yourself — just know that sometimes this call will fail on purpose, and the app should show a normal "something went wrong, try again" message when that happens, not crash.**

---

## 2. Checking a teach-back answer — `POST /grade-answer`

Important: this is called **once per question**, not once for the whole
set. If a patient has 2 teach-back questions, you call this endpoint
2 separate times, once for each answer.

### What you send
=======
## Response fields

| Field | Type | Required | Possible values / constraints | Meaning |
|---|---|---|---|---|
| `patientId` | string | Yes | Must equal the request's `patientId` | Patient identifier |
| `preferredLanguage` | string | Yes | Must equal the request's `preferredLanguage` | Language used/requested for the patient-facing output |
| `simplifiedInstructions` | array of strings | Yes | Must contain at least 1 non-empty string | Simplified patient-friendly discharge instructions |
| `teachBackQuestions` | array of objects | Yes | Must contain at least 1 object | Questions used to check patient understanding |
| `teachBackQuestions[].id` | string | Yes | Non-null string | Unique/question identifier generated by the LLM; the validator only requires it to be a string |
| `teachBackQuestions[].question` | string | Yes | Non-empty string | Teach-back question |

The current validator rejects:
- a non-object response,
- missing/wrong-type `patientId`,
- missing/wrong-type `preferredLanguage`,
- an empty/non-array `simplifiedInstructions`,
- non-string or empty instructions,
- an empty/non-array `teachBackQuestions`,
- malformed question objects,
- missing/wrong-type question IDs,
- empty question text.

The backend returns only the validated JSON object to Flutter; Flutter does not need to parse Ollama's raw response format.

---

# 5. Clinical-safety validation

After Ollama produces a structurally valid response, the backend performs an additional clinical-fact check.

It checks important patterns found in the original discharge text, including:
- medication quantities such as `mg`, `g`, `mcg`, and `ml`,
- frequencies such as once/twice/three/four times a day,
- durations such as `for N days`,
- numeric dates such as `1/15/2026`,
- written dates such as `January 15, 2026`.

Each matched value must also appear in the simplified instructions.

If this check fails:

```http
500 Internal Server Error
```

```json
{
  "error": "Unable to safely process discharge instructions"
}
```

---

# 6. Error contract for /process-discharge

## 400 Bad Request — missing field

The backend returns:

```json
{
  "error": "Missing required field: <fieldName>"
}
```

Examples:

```json
{
  "error": "Missing required field: patientId"
}
```

```json
{
  "error": "Missing required field: preferredLanguage"
}
```

```json
{
  "error": "Missing required field: dischargeText"
}
```

## 400 Bad Request — wrong type

The backend returns:

```json
{
  "error": "<fieldName> must be a string"
}
```

Example:

```json
{
  "error": "patientId must be a string"
}
```

## 400 Bad Request — empty string

The backend returns:

```json
{
  "error": "<fieldName> cannot be empty"
}
```

Example:

```json
{
  "error": "dischargeText cannot be empty"
}
```

## 400 Bad Request — malformed JSON

Because Express JSON parsing is enabled, malformed JSON can be rejected by Express before the route handler runs.

The exact Express-generated error body is not explicitly defined by this application code. Flutter should treat a non-contract 400 response as a generic bad-request failure rather than depending on an Express internal error message.

## 413 Payload Too Large

The JSON parser can reject a request exceeding its default 100 KB body limit.

The exact Express-generated error body is not explicitly defined by this application code.

## 500 Internal Server Error — clinical validation failure

```json
{
  "error": "Unable to safely process discharge instructions"
}
```

## 500 Internal Server Error — incorrect patient ID returned by LLM

```json
{
  "error": "Unable to process discharge instructions"
}
```

## 500 Internal Server Error — incorrect preferred language returned by LLM

```json
{
  "error": "Unable to process discharge instructions"
}
```

## 500 Internal Server Error — Ollama/processing failure

```json
{
  "error": "Unable to process discharge instructions"
}
```

This includes failures after the LLM processing ultimately cannot produce a valid response.

## Other HTTP statuses

The application does not explicitly define other application-level status codes for `/process-discharge`.

---

# 7. Teach-back contract

Teach-back answers are **not** submitted to `/process-discharge`.

They use the separate endpoint:

```http
POST /grade-answer
```

The Flutter flow is:

```text
POST /process-discharge
        ↓
receive simplifiedInstructions + teachBackQuestions
        ↓
show instructions/questions to patient
        ↓
patient answers a question
        ↓
POST /grade-answer
        ↓
receive correct/incorrect + score + feedback
```

---

# 8. POST /grade-answer

## Request JSON
>>>>>>> e5e41e5c486f13ddb482259e01a571ef229779d1

```json
{
  "patientId": "P001",
<<<<<<< HEAD
  "preferredLanguage": "en",
  "dischargeText": "Take amoxicillin 500 mg by mouth three times a day for 7 days...",
  "question": "How many times a day should you take your antibiotic?",
=======
  "preferredLanguage": "English",
  "dischargeText": "Take amoxicillin 500 mg three times a day for 7 days.",
  "question": "How many times a day should you take amoxicillin?",
>>>>>>> e5e41e5c486f13ddb482259e01a571ef229779d1
  "patientAnswer": "Three times a day"
}
```

<<<<<<< HEAD
All five fields are required, all must be plain text, none can be empty.

Notice `dischargeText` shows up again here — yes, you have to send the
full original text again every single time you grade an answer, not
just the question and answer. This is easy to forget.

### What you get back
=======
## Fields

| Field | Type | Required | Limits | Meaning |
|---|---|---|---|---|
| `patientId` | string | Yes | No explicit application-level length limit | Synthetic patient identifier |
| `preferredLanguage` | string | Yes | No explicit application-level length limit | Patient's preferred language |
| `dischargeText` | string | Yes | No explicit application-level text-length limit | Original discharge instructions used as the grading source of truth |
| `question` | string | Yes | No explicit application-level length limit | Teach-back question being graded |
| `patientAnswer` | string | Yes | No explicit application-level length limit | Patient's answer |

All five fields must exist, be strings, and not be empty after trimming.

The same approximately 100 KB JSON body-parser limit applies.

---

# 9. Successful /grade-answer response

## HTTP status

```http
200 OK
```

## Exact JSON structure
>>>>>>> e5e41e5c486f13ddb482259e01a571ef229779d1

```json
{
  "patientId": "P001",
  "correct": true,
  "score": 1,
<<<<<<< HEAD
  "feedback": "That's right! Taking it three times a day helps keep the medicine working."
}
```

Rules about this response:
- `correct` is either `true` or `false` — nothing in between.
- `score` is either `0` or `1` — also nothing in between. There is no "partial credit" and no "amber/warning" state from the backend itself. If the app wants a three-color (green/amber/red) result, that has to be built on the app side by combining multiple question scores — the backend will not hand you an "amber" answer.
- `feedback` is always a short sentence explaining the grade.

---

## 3. What NOT to assume

- Don't assume there's a "must-not-miss points" list anywhere in the response. It doesn't exist. The closest thing is the list of `teachBackQuestions` — treat each question as one "point" to check.
- Don't assume grading gives you three levels. It's strictly right/wrong (`true`/`false`, `0`/`1`).
- Don't skip sending `dischargeText` on the grade-answer call just because you already sent it once on process-discharge — the server has no memory between calls and needs it fresh every time.
- Don't hardcode `http://localhost:3000` everywhere in the app — put it in one place, because it'll need to change (`10.0.2.2` for an Android emulator, or your computer's real network address for a physical phone).
=======
  "feedback": "Correct."
}
```

Incorrect example:

```json
{
  "patientId": "P001",
  "correct": false,
  "score": 0,
  "feedback": "The instructions say to take amoxicillin 3 times a day."
}
```

## Response fields

| Field | Type | Required | Possible values | Meaning |
|---|---|---|---|---|
| `patientId` | string | Yes | Must equal request `patientId` | Patient identifier |
| `correct` | boolean | Yes | `true` or `false` | Whether the answer demonstrates understanding |
| `score` | number | Yes | `0` or `1` | Binary teach-back score |
| `feedback` | string | Yes | Non-empty string | Short, patient-friendly feedback |

The validator requires `score` to be exactly numeric `0` or numeric `1`.

The grading prompt requires:
- correct answer → `correct: true`, `score: 1`
- incorrect/incomplete answer → `correct: false`, `score: 0`

---

# 10. /grade-answer errors

## 400 Bad Request

Missing field:

```json
{
  "error": "Missing required field: <fieldName>"
}
```

Wrong type:

```json
{
  "error": "<fieldName> must be a string"
}
```

Empty value:

```json
{
  "error": "<fieldName> cannot be empty"
}
```

The same rules apply to:
- `patientId`
- `preferredLanguage`
- `dischargeText`
- `question`
- `patientAnswer`

## 500 Internal Server Error — incorrect patient ID from LLM

```json
{
  "error": "Unable to grade answer"
}
```

## 500 Internal Server Error — Ollama/processing failure

```json
{
  "error": "Unable to grade answer"
}
```

## 413 Payload Too Large

The request can be rejected by Express if the JSON body exceeds the default approximately 100 KB limit. The exact Express-generated body is not explicitly defined by application code.

---

# 11. Ollama integration

Flutter does **not** call Ollama directly.

The architecture is:

```text
Flutter
   |
   | HTTP JSON
   v
Node.js / Express
   |
   | internal HTTP
   v
Ollama
   |
   v
Llama 3.1 8B
```

The Node.js backend calls Ollama's:

```text
/api/generate
```

using:
- `POST`
- `Content-Type: application/json`
- `stream: false`
- `format: "json"`
- temperature `0.1`

The configured model defaults to:

```text
llama3.1:8b
```

The Ollama URL defaults to:

```text
http://localhost:11434
```

The Node.js layer parses the Ollama `response`, validates it, retries up to 3 attempts when the generated JSON fails validation, performs additional safety checks for `/process-discharge`, and then returns the stable application JSON contract.

Therefore:

**Flutter must depend only on the DischargeIQ API response schemas in this document, not on Ollama's raw response structure.**

---

# 12. Retry behavior

The backend allows up to **3 Ollama generation attempts** for each request.

A response must:
1. be valid JSON,
2. pass the relevant validator,
3. for `/process-discharge`, pass the clinical-fact validation,
4. preserve the request's `patientId`,
5. for `/process-discharge`, preserve `preferredLanguage`.

If processing still fails, the route returns HTTP 500.

---

# 13. Timeouts / expected processing time

The current backend does **not** explicitly configure an HTTP timeout for the Ollama `fetch()` call.

Therefore, this implementation does not provide a contractual fixed maximum processing time.

Because `/process-discharge` and `/grade-answer` are synchronous and may invoke Ollama up to 3 times, Flutter should use a timeout comfortably longer than a normal single LLM generation. A client timeout of around **60 seconds** is a reasonable integration starting point, but this is a client recommendation rather than a backend-enforced timeout.

If the project later adds an explicit server/Ollama timeout, this section must be updated.

---

# 14. Rate limits

There is currently **no application-level rate limiting** implemented.

Flutter should not assume a rate-limit response such as HTTP 429 exists in the current backend contract.

---

# 15. Health check

The server also exposes:

```http
GET /health
```

Success:

```http
200 OK
```

```json
{
  "status": "ok",
  "service": "DischargeIQ server"
}
```

This endpoint requires no authentication.

---

# 16. Flutter integration summary

### Process discharge

```http
POST /process-discharge
Content-Type: application/json
```

```json
{
  "patientId": "P001",
  "preferredLanguage": "English",
  "dischargeText": "Original discharge instructions..."
}
```

Expected success:

```json
{
  "patientId": "P001",
  "preferredLanguage": "English",
  "simplifiedInstructions": [
    "..."
  ],
  "teachBackQuestions": [
    {
      "id": "Q1",
      "question": "..."
    }
  ]
}
```

### Grade teach-back

```http
POST /grade-answer
Content-Type: application/json
```

```json
{
  "patientId": "P001",
  "preferredLanguage": "English",
  "dischargeText": "Original discharge instructions...",
  "question": "How many times a day should you take the medicine?",
  "patientAnswer": "Three times a day"
}
```

Expected success:

```json
{
  "patientId": "P001",
  "correct": true,
  "score": 1,
  "feedback": "Correct."
}
```

---

# 17. Important implementation notes

1. There is currently no authentication.
2. There is currently no database lookup performed by these routes.
3. The routes accept the patient/discharge data directly in JSON.
4. Teach-back is a separate `/grade-answer` request.
5. The original `dischargeText` must be sent again when grading because the grading prompt compares the answer against the original discharge instructions.
6. Flutter should not call Ollama directly.
7. Flutter should not depend on raw Ollama JSON.
8. The backend is synchronous.
9. There is no job/status polling endpoint.
10. No application-level rate limit is currently implemented.
11. No explicit per-field character limit is currently implemented.
12. The main request-body limit is the Express JSON parser's default approximately 100 KB.
>>>>>>> e5e41e5c486f13ddb482259e01a571ef229779d1
