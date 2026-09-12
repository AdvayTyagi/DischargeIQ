# DischargeIQ

DischargeIQ is a patient discharge education and teach-back system designed to help patients better understand their hospital discharge instructions.

Instead of only simplifying medical instructions, DischargeIQ uses the **teach-back method**: the patient is asked to explain important instructions in their own words, and the system evaluates whether they understood them correctly.

> **Important:** This project uses synthetic fictional patient data for development and demonstration. No real patient information should be used.

---

## Problem

Hospital discharge instructions are often difficult for patients to understand because they contain medical terminology, medication instructions, warnings, appointment information, and other important details.

Poor understanding of discharge instructions can contribute to medication errors, missed follow-ups, and avoidable complications.

DischargeIQ aims to make discharge education more understandable and interactive.

---

## How DischargeIQ Works

```text
Synthetic Patient Data
        |
        v
Flutter Mobile App
        |
        | Patient discharge information
        v
Node.js / Express Backend
        |
        v
Ollama + Llama 3.1 8B
        |
        +-----------------------------+
        |                             |
        v                             v
Simplified Instructions        Teach-Back Questions
                                      |
                                      v
                              Patient Answers
                                      |
                                      v
                              /grade-answer
                                      |
                                      v
                              Understanding Result