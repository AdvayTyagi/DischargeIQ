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
        error: "Unable to process discharge instructions"
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
        error: "Unable to process discharge instructions"
      });
    }

    // Return only validated data
    return res.status(200).json(result);

  } catch (error) {
    console.error(
      "Process discharge error:",
      error.message
    );

    return res.status(500).json({
      error: "Unable to process discharge instructions"
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

    // Build LLM prompt
    const prompt = buildGradeAnswerPrompt(
      patientId,
      preferredLanguage,
      dischargeText,
      question,
      patientAnswer
    );

    // Ask Ollama for validated JSON
    const result = await generateValidJson(
      prompt,
      validateGradeAnswerResponse,
      3
    );

    // Make sure the model returned the correct patient
    if (result.patientId !== patientId) {
      console.error(
        "LLM returned incorrect patientId."
      );

      return res.status(500).json({
        error: "Unable to grade answer"
      });
    }

    // Return only validated data
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