require("dotenv").config();

const express = require("express");
const cors = require("cors");

const {
  generateValidJson
} = require("./gemini");

const {
  validateProcessDischargeResponse,
  validateGradeAnswerResponse
} = require("./validator");

const {
  buildProcessDischargePrompt
} = require("./prompts/process-discharge");

const {
  buildGradeAnswerPrompt
} = require("./prompts/grade-answer");

const app = express();

app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;

// --------------------------------------------------
// GET /health
// --------------------------------------------------

app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    service: "DischargeIQ server"
  });
});

// --------------------------------------------------
// Helpers
// --------------------------------------------------

function requireString(body, field) {
  if (
    typeof body[field] !== "string" ||
    body[field].trim() === ""
  ) {
    return `${field} is required and must be a non-empty string.`;
  }

  return null;
}

function normalizeText(text) {
  return text
    .toLowerCase()
    .replace(/[^\w\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function removeFillerWords(text) {
  const fillerWords = new Set([
    "a",
    "an",
    "and",
    "are",
    "as",
    "at",
    "be",
    "by",
    "for",
    "from",
    "how",
    "i",
    "in",
    "is",
    "it",
    "me",
    "my",
    "of",
    "on",
    "or",
    "should",
    "that",
    "the",
    "this",
    "to",
    "was",
    "what",
    "when",
    "where",
    "with",
    "you",
    "your"
  ]);

  return normalizeText(text)
    .split(" ")
    .filter(
      (word) =>
        word.length > 0 &&
        !fillerWords.has(word)
    );
}

// --------------------------------------------------
// FAST LOCAL GRADING
// --------------------------------------------------
//
// This grader is intentionally conservative.
//
// If an answer is clearly represented in the
// original discharge instructions, it can be
// accepted immediately.
//
// If the answer is ambiguous or potentially wrong,
// return null so Gemini can grade it and provide
// the correctAnswer when necessary.
//

function fastGradeAnswer(
  dischargeText,
  question,
  patientAnswer
) {
  const answerWords =
    removeFillerWords(patientAnswer);

  const dischargeWords =
    removeFillerWords(dischargeText);

  if (answerWords.length === 0) {
    return null;
  }

  // Very short answers are too ambiguous
  // to grade locally.
  if (answerWords.length === 1) {
    const importantSingleWords = new Set([
      "morning",
      "evening",
      "night",
      "weekly",
      "daily",
      "twice",
      "three",
      "four",
      "doctor",
      "rest",
      "fluids",
      "water"
    ]);

    if (!importantSingleWords.has(answerWords[0])) {
      return null;
    }
  }

  // Check whether the answer's important words
  // occur in the original discharge instructions.
  const allWordsPresent = answerWords.every(
    (word) => dischargeWords.includes(word)
  );

  if (!allWordsPresent) {
    return null;
  }

  // Make sure the answer contains a meaningful
  // action/concept rather than just a common word.
  const actionWords = new Set([
    "take",
    "call",
    "contact",
    "check",
    "monitor",
    "drink",
    "rest",
    "weigh",
    "seek",
    "return",
    "follow",
    "schedule",
    "limit",
    "finish",
    "record",
    "stand",
    "medicine",
    "doctor",
    "morning",
    "evening",
    "night",
    "daily",
    "twice",
    "three",
    "four",
    "weekly"
  ]);

  const containsMeaningfulWord =
    answerWords.some((word) =>
      actionWords.has(word)
    );

  if (!containsMeaningfulWord) {
    return null;
  }

  // The local grader only returns a positive result.
  // Potentially incorrect or ambiguous answers go
  // to Gemini for proper grading.
  return {
    patientId: null,
    correct: true,
    score: 1,
    feedback: "Correct."
  };
}

// --------------------------------------------------
// POST /process-discharge
// --------------------------------------------------

app.post("/process-discharge", async (req, res) => {
  try {
    const {
      patientId,
      preferredLanguage,
      dischargeText
    } = req.body;

    // Validate patient ID.
    const patientIdError =
      requireString(req.body, "patientId");

    if (patientIdError) {
      return res.status(400).json({
        error: patientIdError
      });
    }

    // Validate preferred language.
    const languageError =
      requireString(
        req.body,
        "preferredLanguage"
      );

    if (languageError) {
      return res.status(400).json({
        error: languageError
      });
    }

    // Validate discharge text.
    const dischargeTextError =
      requireString(
        req.body,
        "dischargeText"
      );

    if (dischargeTextError) {
      return res.status(400).json({
        error: dischargeTextError
      });
    }

    console.log(
      `Processing discharge for patient ${patientId}`
    );

    const prompt =
      buildProcessDischargePrompt(
        patientId,
        preferredLanguage,
        dischargeText
      );

    const result =
      await generateValidJson(
        prompt,
        validateProcessDischargeResponse,
        3
      );

    // Make sure Gemini returned the same
    // patient ID that was requested.
    if (result.patientId !== patientId) {
      return res.status(500).json({
        error:
          "Gemini returned an incorrect patient ID."
      });
    }

    // Make sure Gemini returned the requested
    // preferred language.
    if (
      result.preferredLanguage !==
      preferredLanguage
    ) {
      return res.status(500).json({
        error:
          "Gemini returned an incorrect preferred language."
      });
    }

    return res.json(result);

  } catch (error) {
    console.error(
      "Error processing discharge:",
      error
    );

    return res.status(500).json({
      error:
        "Failed to process discharge instructions."
    });
  }
});

// --------------------------------------------------
// POST /grade-answer
// --------------------------------------------------

app.post("/grade-answer", async (req, res) => {
  try {
    const {
      patientId,
      preferredLanguage,
      dischargeText,
      question,
      patientAnswer
    } = req.body;

    // Validate patient ID.
    const patientIdError =
      requireString(req.body, "patientId");

    if (patientIdError) {
      return res.status(400).json({
        error: patientIdError
      });
    }

    // Validate preferred language.
    const languageError =
      requireString(
        req.body,
        "preferredLanguage"
      );

    if (languageError) {
      return res.status(400).json({
        error: languageError
      });
    }

    // Validate original discharge text.
    const dischargeTextError =
      requireString(
        req.body,
        "dischargeText"
      );

    if (dischargeTextError) {
      return res.status(400).json({
        error: dischargeTextError
      });
    }

    // Validate question.
    const questionError =
      requireString(req.body, "question");

    if (questionError) {
      return res.status(400).json({
        error: questionError
      });
    }

    // Validate patient answer.
    const answerError =
      requireString(
        req.body,
        "patientAnswer"
      );

    if (answerError) {
      return res.status(400).json({
        error: answerError
      });
    }

    console.log(
      `Grading teach-back answer for patient ${patientId}`
    );

    // ------------------------------------------------
    // FAST LOCAL CHECK
    // ------------------------------------------------

    const fastResult =
      fastGradeAnswer(
        dischargeText,
        question,
        patientAnswer
      );

    if (fastResult) {
      console.log(
        "Fast local grading: answer accepted."
      );

      return res.json({
        patientId,
        correct: true,
        score: 1,
        feedback: "Correct."
      });
    }

    // ------------------------------------------------
    // LLM GRADING
    // ------------------------------------------------

    console.log(
      "Answer requires LLM grading."
    );

    const prompt =
      buildGradeAnswerPrompt(
        patientId,
        preferredLanguage,
        dischargeText,
        question,
        patientAnswer
      );

    const result =
      await generateValidJson(
        prompt,
        validateGradeAnswerResponse,
        3
      );

    // Make sure Gemini returned the same
    // patient ID that was requested.
    if (result.patientId !== patientId) {
      return res.status(500).json({
        error:
          "Gemini returned an incorrect patient ID."
      });
    }

    // ------------------------------------------------
    // NORMALIZE CORRECT ANSWERS
    // ------------------------------------------------
    //
    // The app only needs correctAnswer when the
    // patient's answer is incorrect.
    //

    if (result.correct === true) {
      return res.json({
        patientId,
        correct: true,
        score: 1,
        feedback: result.feedback,
        ...(result.correctAnswer
          ? {
              correctAnswer:
                result.correctAnswer
            }
          : {})
      });
    }

    // ------------------------------------------------
    // INCORRECT ANSWER
    // ------------------------------------------------
    //
    // The validator guarantees that an incorrect
    // Gemini response contains correctAnswer.
    //

    return res.json({
      patientId,
      correct: false,
      score: 0,
      feedback: result.feedback,
      correctAnswer: result.correctAnswer
    });

  } catch (error) {
    console.error(
      "Error grading answer:",
      error
    );

    return res.status(500).json({
      error:
        "Failed to grade teach-back answer."
    });
  }
});

// --------------------------------------------------
// START SERVER
// --------------------------------------------------

app.listen(
  PORT,
  "0.0.0.0",
  () => {
    console.log(
      `DischargeIQ server running on port ${PORT}`
    );
  }
);