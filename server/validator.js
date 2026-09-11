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
  validateGradeAnswerResponse
};