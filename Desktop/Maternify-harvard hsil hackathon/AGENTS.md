# Demo build rules

## Project goal
This project is a presentation-grade Flutter demo for a maternal health app.

The top priority is that the Android emulator demo feels real, interactive, polished, and reliable during a live presentation.

## Engineering priorities
- Prioritize demo realism over backend completeness.
- Prefer local mocks, seeded data, fake API delays, and simulated AI outputs when they improve demo quality.
- Keep architecture clean enough that real services can replace mocks later.
- Do not leave dead buttons, placeholder content, broken navigation, or empty screens.
- Every visible feature should have meaningful interaction feedback.

## UX expectations
- Use believable data and labels.
- Add loading, success, empty, and error states.
- Maintain consistency across screens.
- Make charts, alerts, chat, vitals, and navigation feel alive.

## Development rules
- Inspect the repo before making large changes.
- Propose the highest-impact demo improvements first.
- Prefer small, testable changes over broad speculative rewrites.
- Run formatting and analysis checks after edits.