# DischargeIQ Local LLM Server

This folder contains the local LLM backend for DischargeIQ.

The backend uses Node.js, Express, Ollama, and Llama 3.1 8B.

## Architecture

Flutter App
    |
    | HTTP JSON
    v
Node.js / Express
    |
    v
Ollama
    |
    v
Llama 3.1 8B

## Requirements

- Node.js
- Ollama
- Llama 3.1 8B

## Install dependencies

From the `server` directory:

```bash
npm install