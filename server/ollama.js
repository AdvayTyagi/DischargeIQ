const OLLAMA_URL =
  process.env.OLLAMA_URL || "http://localhost:11434";

const OLLAMA_MODEL =
  process.env.OLLAMA_MODEL || "llama3.1:8b";

async function callOllama(prompt) {
  const response = await fetch(
    `${OLLAMA_URL}/api/generate`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        prompt: prompt,
        stream: false,
        format: "json",
        options: {
          temperature: 0.1
        }
      })
    }
  );

  if (!response.ok) {
    const errorText = await response.text();

    throw new Error(
      `Ollama request failed: ${response.status} ${errorText}`
    );
  }

  const data = await response.json();

  return data.response;
}


async function generateValidJson(
  prompt,
  validator,
  maxAttempts = 3
) {
  let currentPrompt = prompt;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    console.log(
      `LLM attempt ${attempt}/${maxAttempts}`
    );

    try {
      const rawResponse = await callOllama(
        currentPrompt
      );

      let parsedResponse;

      try {
        parsedResponse = JSON.parse(rawResponse);
      } catch (error) {
        console.log("LLM returned invalid JSON.");
        parsedResponse = null;
      }

      if (
        parsedResponse &&
        validator(parsedResponse)
      ) {
        console.log("LLM response passed validation.");

        return parsedResponse;
      }

      console.log(
        "LLM response failed validation."
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
        `LLM attempt ${attempt} failed:`,
        error.message
      );

      if (attempt === maxAttempts) {
        throw error;
      }
    }
  }

  throw new Error(
    "Model failed to produce valid JSON after 3 attempts."
  );
}


module.exports = {
  callOllama,
  generateValidJson
};