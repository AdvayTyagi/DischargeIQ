require("dotenv").config();

const express = require("express");
const cors = require("cors");

const {
  generateValidJson
} = require("./ollama");

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

const PORT = process.env.PORT || 3000;

// --------------------------------------------------
// Middleware
// --------------------------------------------------

app.use(cors());
app.use(express.json());

// --------------------------------------------------
// Health Check
// --------------------------------------------------

app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    service: "DischargeIQ server"
  });
});

// --------------------------------------------------
// Helper: Validate Required String
// --------------------------------------------------

function requireString(body, fieldName) {
  if (!(fieldName in body)) {
    return `Missing required field: ${fieldName}`;
  }

  if (typeof body[fieldName] !== "string") {
    return `${fieldName} must be a string`;
  }

  if (body[fieldName].trim() === "") {
    return `${fieldName} cannot be empty`;
  }

  return null;
}

// --------------------------------------------------
// Helper: Normalize text for fast grading
// --------------------------------------------------

function normalizeText(text) {
  return text
    .toLowerCase()
    .replace(/[^\w\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

// --------------------------------------------------
// Helper: Remove common filler words
// --------------------------------------------------

function removeFillerWords(text) {
  const fillerWords = new Set([
    "i",
    "me",
    "my",
    "we",
    "our",
    "you",
    "your",
    "the",
    "a",
    "an",
    "to",
    "do",
    "should",
    "need",
    "have",
    "has",
    "that",
    "if",
    "then"
  ]);

  return normalizeText(text)
    .split(" ")
    .filter((word) => !fillerWords.has(word));
}

// --------------------------------------------------
// Helper: Check whether answer clearly appears
// in the discharge instructions
// --------------------------------------------------

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

  // If the answer is clearly represented in the
  // discharge instructions, accept it immediately.
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

    // Validate request

    const patientIdError =
      requireString(req.body, "patientId");

    if (patientIdError) {
      return res.status(400).json({
        error: patientIdError
      });
    }

    const languageError =
      requireString(req.body, "preferredLanguage");

    if (languageError) {
      return res.status(400).json({
        error: languageError
      });
    }

    const dischargeTextError =
      requireString(req.body, "dischargeText");

    if (dischargeTextError) {
      return res.status(400).json({
        error: dischargeTextError
      });
    }

    console.log(
      `Processing discharge for patient ${patientId}`
    );

    // Build LLM prompt

    const prompt = buildProcessDischargePrompt(
      patientId,
      preferredLanguage,
      dischargeText
    );

    // Ask Ollama for validated JSON

    const result = await generateValidJson(
      prompt,
      validateProcessDischargeResponse,
      3
    );

    // Make sure the model did not change identifiers

    if (result.patientId !== patientId) {
      console.error(
        "LLM returned incorrect patientId."
      );

      return res.status(500).json({
        error:
          "Unable to process discharge instructions"
      });
    }

    if (
      result.preferredLanguage !==
      preferredLanguage
    ) {
      console.error(
        "LLM returned incorrect preferredLanguage."
      );

      return res.status(500).json({
        error:
          "Unable to process discharge instructions"
      });
    }

    // Return validated data

    return res.status(200).json(result);

  } catch (error) {
    console.error(
      "Process discharge error:",
      error.message
    );

    return res.status(500).json({
      error:
        "Unable to process discharge instructions"
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

    // Validate request

    const patientIdError =
      requireString(req.body, "patientId");

    if (patientIdError) {
      return res.status(400).json({
        error: patientIdError
      });
    }

    const languageError =
      requireString(req.body, "preferredLanguage");

    if (languageError) {
      return res.status(400).json({
        error: languageError
      });
    }

    const dischargeTextError =
      requireString(req.body, "dischargeText");

    if (dischargeTextError) {
      return res.status(400).json({
        error: dischargeTextError
      });
    }

    const questionError =
      requireString(req.body, "question");

    if (questionError) {
      return res.status(400).json({
        error: questionError
      });
    }

    const patientAnswerError =
      requireString(req.body, "patientAnswer");

    if (patientAnswerError) {
      return res.status(400).json({
        error: patientAnswerError
      });
    }

    console.log(
      `Grading teach-back answer for patient ${patientId}`
    );

    // --------------------------------------------------
    // FAST LOCAL CHECK
    // --------------------------------------------------

    const fastResult = fastGradeAnswer(
      dischargeText,
      question,
      patientAnswer
    );

    if (fastResult) {
      console.log(
        "Fast local grading: answer accepted."
      );

      return res.status(200).json({
        patientId,
        correct: fastResult.correct,
        score: fastResult.score,
        feedback: fastResult.feedback
      });
    }

    console.log(
      "Answer requires LLM grading."
    );

    // --------------------------------------------------
    // LLM GRADING
    // --------------------------------------------------

    const prompt = buildGradeAnswerPrompt(
      patientId,
      preferredLanguage,
      dischargeText,
      question,
      patientAnswer
    );

    const result = await generateValidJson(
      prompt,
      validateGradeAnswerResponse,
      3
    );

    // Make sure the model returned
    // the correct patient

    if (result.patientId !== patientId) {
      console.error(
        "LLM returned incorrect patientId."
      );

      return res.status(500).json({
        error: "Unable to grade answer"
      });
    }

    // Return validated result

    return res.status(200).json(result);

  } catch (error) {
    console.error(
      "Grade answer error:",
      error.message
    );

    return res.status(500).json({
      error: "Unable to grade answer"
    });
  }
});

// --------------------------------------------------
// Start Server
// --------------------------------------------------

app.listen(PORT, () => {
  console.log(
    `DischargeIQ server running on http://localhost:${PORT}`
  );
});