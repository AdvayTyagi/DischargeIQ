# DischargeIQ API Contract

This is the real, exact set of rules for talking to the backend.
It was written by reading `server/index.js` and `server/validator.js`
directly — not guessed. If the backend code ever changes, this file
needs to be updated to match.

The backend runs at `http://localhost:3000` on your computer
(port comes from `PORT` in `.env`, but 3000 is the default).

---

## 1. Checking the discharge text — `POST /process-discharge`

### What you send

```json
{
  "patientId": "P001",
  "preferredLanguage": "en",
  "dischargeText": "Take amoxicillin 500 mg by mouth three times a day for 7 days..."
}
```

All three fields are required. They all must be plain text (strings),
and none of them can be empty. If you leave one out, or send an empty
string, the server will reject the request right away with an error
message telling you which field was the problem.

### What you get back

```json
{
  "patientId": "P001",
  "preferredLanguage": "en",
  "simplifiedInstructions": [
    "Take your antibiotic three times a day for 7 days.",
    "Drink fluids and rest.",
    "Check your temperature twice a day."
  ],
  "teachBackQuestions": [
    { "id": "q1", "question": "How many times a day should you take your antibiotic?" },
    { "id": "q2", "question": "What should you do if your fever goes above 102°F?" }
  ]
}
```

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

```json
{
  "patientId": "P001",
  "preferredLanguage": "en",
  "dischargeText": "Take amoxicillin 500 mg by mouth three times a day for 7 days...",
  "question": "How many times a day should you take your antibiotic?",
  "patientAnswer": "Three times a day"
}
```

All five fields are required, all must be plain text, none can be empty.

Notice `dischargeText` shows up again here — yes, you have to send the
full original text again every single time you grade an answer, not
just the question and answer. This is easy to forget.

### What you get back

```json
{
  "patientId": "P001",
  "correct": true,
  "score": 1,
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