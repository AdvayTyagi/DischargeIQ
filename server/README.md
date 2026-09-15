cat > server/README.md <<'EOF'
# DischargeIQ Server

This folder contains the backend for DischargeIQ.

The backend uses Node.js, Express, and Google Gemini.

## Architecture

```text
Flutter Mobile App
        |
        v
   Node.js / Express
        |
        v
    Google Gemini
        |
        v
     Gemini API