const { GoogleGenAI } = require("@google/genai");

const client = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY
});

const GEMINI_MODEL =
  process.env.GEMINI_MODEL || "gemini-3.5-flash-lite";

// --------------------------------------------------
// Call Gemini
// --------------------------------------------------

async function callGemini(prompt) {
  const response = await client.models.generateContent({
    model: GEMINI_MODEL,
    contents: prompt,
    config: {
      responseMimeType: "application/json"
    }
  });

  return response.text;
}

// --------------------------------------------------
// Generate and validate JSON
// --------------------------------------------------

async function generateValidJson(
  prompt,
  validator,
  maxAttempts = 3
) {
  let currentPrompt = prompt;

  for (
    let attempt = 1;
    attempt <= maxAttempts;
    attempt++
  ) {
    console.log(
      `Gemini attempt ${attempt}/${maxAttempts}`
    );

    try {
      const rawResponse =
        await callGemini(currentPrompt);

      let parsedResponse;

      try {
        parsedResponse = JSON.parse(rawResponse);
      } catch (error) {
        console.log(
          "Gemini returned invalid JSON."
        );

        parsedResponse = null;
      }

      if (
        parsedResponse &&
        validator(parsedResponse)
      ) {
        console.log(
          "Gemini response passed validation."
        );

        return parsedResponse;
      }

      console.log(
        "Gemini response failed validation."
      );

      currentPrompt = `
Your previous response did not follow the required JSON structure.

Return ONLY valid JSON.

Do not include:
- Markdown
- Code fences
- Explanations outside JSON
- Extra fields

Follow the required JSON structure exactly.

Original task:

${prompt}
`;
    } catch (error) {
      console.error(
        `Gemini attempt ${attempt} failed:`,
        error.message
      );

      if (attempt === maxAttempts) {
        throw error;
      }
    }
  }

  throw new Error(
    "Gemini failed to produce valid JSON after 3 attempts."
  );
}

module.exports = {
  callGemini,
  generateValidJson
};