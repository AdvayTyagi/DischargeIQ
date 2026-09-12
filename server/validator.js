function parseJsonResponse(response) {
  try {
    return JSON.parse(response);
  } catch (error) {
    return null;
  }
}

function validateProcessDischargeResponse(data) {
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    return false;
  }

  if (typeof data.patientId !== "string") {
    return false;
  }

  if (typeof data.preferredLanguage !== "string") {
    return false;
  }

  if (!Array.isArray(data.simplifiedInstructions)) {
    return false;
  }

  if (data.simplifiedInstructions.length === 0) {
    return false;
  }

  for (const instruction of data.simplifiedInstructions) {
    if (typeof instruction !== "string" || instruction.trim() === "") {
      return false;
    }
  }

  if (!Array.isArray(data.teachBackQuestions)) {
    return false;
  }

  if (data.teachBackQuestions.length === 0) {
    return false;
  }

  for (const question of data.teachBackQuestions) {
    if (!question || typeof question !== "object") {
      return false;
    }

    if (typeof question.id !== "string") {
      return false;
    }

    if (typeof question.question !== "string") {
      return false;
    }

    if (question.question.trim() === "") {
      return false;
    }
  }

  return true;
}

function validateGradeAnswerResponse(data) {
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    return false;
  }

  if (typeof data.patientId !== "string") {
    return false;
  }

  if (typeof data.correct !== "boolean") {
    return false;
  }

  if (typeof data.score !== "number") {
    return false;
  }

  if (data.score !== 0 && data.score !== 1) {
    return false;
  }

  if (typeof data.feedback !== "string") {
    return false;
  }

  if (data.feedback.trim() === "") {
    return false;
  }

  return true;
}

module.exports = {
  parseJsonResponse,
  validateProcessDischargeResponse,
  validateGradeAnswerResponse,
  validateClinicalFacts
};

function validateClinicalFacts(originalText, simplifiedInstructions) {
  const simplifiedText = simplifiedInstructions.join(" ").toLowerCase();
  const original = originalText.toLowerCase();

  const importantPatterns = [
    /\b\d+(?:\.\d+)?\s*mg\b/g,
    /\b\d+(?:\.\d+)?\s*g\b/g,
    /\b\d+(?:\.\d+)?\s*mcg\b/g,
    /\b\d+(?:\.\d+)?\s*ml\b/g,
    /\b\d+\s*(?:times|time)\s*(?:a|per)\s*day\b/g,
    /\bonce\s+(?:a|per)\s*day\b/g,
    /\btwice\s+(?:a|per)\s*day\b/g,
    /\bthree\s+times\s+(?:a|per)\s*day\b/g,
    /\bfour\s+times\s+(?:a|per)\s*day\b/g,
    /\bfor\s+\d+\s+days?\b/g,
    /\b\d{1,2}\/\d{1,2}\/\d{2,4}\b/g,
    /\b(?:january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2},?\s+\d{4}\b/gi
  ];

  for (const pattern of importantPatterns) {
    const matches = original.match(pattern) || [];

    for (const match of matches) {
      if (!simplifiedText.includes(match.toLowerCase())) {
        return false;
      }
    }
  }

  return true;
}