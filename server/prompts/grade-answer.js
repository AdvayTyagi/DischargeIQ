function buildGradeAnswerPrompt(
  patientId,
  preferredLanguage,
  dischargeText,
  question,
  patientAnswer
) {
  return `
You are grading a hospital discharge teach-back answer.

Your job is to determine whether the patient's answer demonstrates understanding of the ORIGINAL discharge instructions.

IMPORTANT RULES:

1. Use ONLY the original discharge instructions as the source of truth.
2. Grade the patient's meaning, not exact wording.
3. Accept reasonable paraphrases.
4. Accept minor grammar mistakes.
5. Accept differences such as "your doctor", "our doctor", or "the doctor" when the intended meaning is clearly the same.
6. Do NOT require the patient to repeat the exact wording from the instructions.
7. If the patient gives the correct action but uses different wording, mark the answer correct.
8. If the patient gives an incorrect dose, frequency, duration, date, threshold, warning, or action, mark it incorrect.
9. If the patient answer is incomplete in a way that changes the meaning, mark it incorrect.
10. If the patient says "I don't know", "I don't remember", or gives no meaningful answer, mark it incorrect.
11. Do NOT use information that is not present in the original discharge instructions.
12. Do NOT provide medical advice beyond the original instructions.
13. Return ONLY valid JSON.
14. Do NOT use Markdown.
15. Do NOT use code fences.
16. Do NOT include any fields other than the required fields.
17. Always provide the correct answer using ONLY the original discharge instructions and the teach-back question.
18. The correctAnswer must directly answer the teach-back question.
19. Do not invent information that is not present in the original discharge instructions.

PATIENT ID:
${patientId}

PATIENT'S PREFERRED LANGUAGE:
${preferredLanguage}

ORIGINAL DISCHARGE INSTRUCTIONS:
${dischargeText}

TEACH-BACK QUESTION:
${question}

PATIENT'S ANSWER:
${patientAnswer}

Return JSON in EXACTLY this structure:

{
  "patientId": "${patientId}",
  "correct": true,
  "score": 1,
  "feedback": "Correct.",
  "correctAnswer": "The correct answer from the original discharge instructions."
}

If the answer is incorrect, return:

{
  "patientId": "${patientId}",
  "correct": false,
  "score": 0,
  "feedback": "Brief explanation of what was incorrect.",
  "correctAnswer": "The correct answer from the original discharge instructions."
}
`;
}

module.exports = { buildGradeAnswerPrompt };