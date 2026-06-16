# Method note: avoiding AI-generated tells in academic prose (authentic single-author voice)

Source: Perplexity (scholar+web), retrieved 2026-06-08, for revising new prose in the BS_project NCDVI manuscript. Complements the project's strict style memory (no em/en dashes; flowing first-person-plural paragraphs; preserve idiosyncratic phrasing).

## Signals detectors (GPTZero, Turnitin, Copyleaks) key on
- Low sentence-length variance / low "burstiness": metronomic 18-22-word sentences. Humans vary widely.
- Uniformly low perplexity: over-polished, statistically "easy" text.
- Formulaic transitions repeated: however, therefore, thus, furthermore, moreover.
- Predictable paragraph architecture: topic sentence + two parallel supports + tidy conclusion, repeated.
- Generic boilerplate and uniform lexical palette (low type-token ratio).
- The setup-and-contrast cliche: "X demonstrates how Y. Furthermore, the data indicates Z." is a classic AI fingerprint.

Caveat: detectors are biased against non-native English writers and routinely false-flag well-edited human text. The aim is authentic authorial voice, not gaming a score.

## Revision techniques (actionable)
1. Vary sentence length deliberately: within each ~200-word window include at least one short sentence (under ~12 words) and one long one (over ~25 words). Audit rhythm every 4-6 sentences.
2. Vary sentence openings: start some sentences with a subordinate clause, participial phrase, or noun phrase rather than always subject-verb.
3. Diversify/reduce connectors: cap repeated connectors (about one per 100 words); avoid the banned AI transitions entirely.
4. Break uniform paragraph structure: insert an inline qualification, a counterpoint, or a brief methodological aside; occasionally state a limitation before the conclusion.
5. Ground each claim in specific, traceable evidence (exact numbers, named comparisons) rather than general phrasing; this raises perplexity and reads as author-specific.
6. Calibrate hedging to the evidence: "suggests", "is consistent with", "may", paired with explicit conditions and limitations.
7. Preserve the existing draft's idiosyncrasies (its "Hence,", non-Oxford commas, occasional run-ons) so inserted prose matches the surrounding human voice and the diff does not look polished.
8. Read aloud; replace passages that sound machine-smooth with the author's slightly-imperfect phrasing.

## Example transform
- AI-like: "This method demonstrates how results align with prior studies. Furthermore, the data indicates consistency across trials, which supports the hypothesis."
- Human voice: "The method aligns with prior findings, though it raises new questions about X. The trials are consistent, yet the data also shows an exception under Y, which points to the Z mechanism."

## Sources
- Preserving Authorial Voice in Academic Texts in the Age of AI (AWEJ 2025) https://awej.org/wp-content/uploads/2025/09/14.pdf
- Distinguishing academic science writing from humans or ChatGPT with >99% accuracy (PMC10328544) https://pmc.ncbi.nlm.nih.gov/articles/PMC10328544/
- GPT detectors are biased against non-native English writers (PMC10382961) https://pmc.ncbi.nlm.nih.gov/articles/PMC10382961/
- Unmasking AI-Generated Texts Using Linguistic and Stylistic Features (TheSAI v16n3) https://thesai.org/Downloads/Volume16No3/Paper_21-Unmasking_AI_Generated_Texts.pdf
- What Makes AI Writing Detectable (burstiness/perplexity/token repetition overview) https://www.stealthgpt.ai/blog/what-makes-ai-writing-detectable
