# Art pipeline: Google image generation for the sprites

Researched 2026-11-26 from Google's and Apple's own pages. Decided at GATE 2:
the game's sprites will be made with Google's image generation, and the game is
meant for an eventual App Store release.

How to read this file:

- Quoted text is verbatim from the linked page and is checked by script
  (`tools/citations/check_doc.py`).
- **Inference** marks Claude's conclusions. **Unverified** marks what no page
  read settles.
- Claude read these pages directly. The planned research and verification
  agents did not run, because the account's usage limit was reached, so no
  second reader has checked the reasoning here.
- No image was generated and no API was called for this research. Nothing here
  has been tried.
- This is not legal advice. It reports what the documents say.
- Which Google product, model and account the earlier Gravewright project used
  is not known in this session. This file covers the Gemini API as Google
  documents it today.

## 1. The models available today

Source for this section: <https://aistudio.google.com/docs/image-generation>

- Google's older image model family is gone: "Imagen models are shut down. Use
  Nano Banana for image generation." <https://aistudio.google.com/docs/imagen>
- The current family is called Nano Banana. The page lists five models. The one
  Google recommends for new work is `gemini-nano-banana-2.1`, described as
  "serving as the primary high-efficiency workhorse model for image generation
  and conversational editing", with output "across 1K, 2K, and 4K resolutions".
  Of the previous model it says: "Recommended for all new projects to use Nano
  Banana 2.1."
- `gemini-3-pro-image` is "The premium choice for complex visual tasks".
- `gemini-3.1-flash-lite-image` is the cheapest and fastest, but "Not optimized
  for multiple reference inputs or multi-turn sequential editing", which are the
  two things a consistent sprite set needs most (inference).
- `gemini-2.5-flash-image` is the oldest. The pricing page warns that it "is
  deprecated and will be shut down on March 15, 2027".
  <https://aistudio.google.com/docs/pricing> If Gravewright used it, the sprite
  work should move to a current model.
- Size: "By default, the model matches the output image size to that of your
  input image, or otherwise generates 1:1 squares." Aspect ratio and size (1K,
  2K, 4K) can be set per request.
- Consistency: "`gemini-nano-banana-2.1` and `gemini-3.1-flash-image` support
  character resemblance of up to 4 characters and the fidelity of up to 10
  objects in a single workflow." The page also describes mixing up to 14
  reference images and editing an image over several turns.
- **Every image is watermarked:** "All generated images include a SynthID
  watermark".

What the page does not say (searched for the words transparent, alpha, sprite
and pixel art; none appear):

- **Unverified:** whether any model can produce a transparent background. Plan
  for opaque images and remove the background ourselves.
- **Unverified:** how well the models hold a pixel-art grid, a fixed palette, or
  a sprite sheet layout. This needs a small trial.
- **Unverified:** whether the safety filters block dark-fantasy subjects such as
  corpses and undead. See section 3.

## 2. Cost

Source: <https://aistudio.google.com/docs/pricing>

- Image output on these models is paid only. In the pricing table for
  `gemini-nano-banana-2.1`, the free tier column reads "Not available" for
  output.
- `gemini-nano-banana-2.1`: "Image output is priced at $30 per 1,000,000 tokens
  (Standard) and $15 per 1,000,000 tokens (Batch). Output images at 1K
  (1024x1024px) consume 1120 tokens and are equivalent to $0.0336 per image."
  The table gives $0.0504 for a 2K image and $0.113 for a 4K image, and half
  those prices through the Batch API.
- `gemini-3-pro-image`: "Image output is priced at $120 per 1,000,000 tokens.
  Output images from 1024x1024px (1K) and up to 2048x2048px (2K) consume 1120
  tokens and are equivalent to $0.134 per image."
- Spending is throttled by Google: "Gemini API enforces spend-based rate limits
  to protect against unexpected charges." The table on that page gives $10 per
  10 minutes at usage tier 1. <https://aistudio.google.com/docs/rate-limits>

Estimate (inference; the quantities are guesses, the prices are Google's):
20 unit types × 8 images each, plus 30 terrain and effect images, is 190 kept
images. At 5 attempts per kept image that is 950 generations.

| Model and size | Per image | 950 images |
|---|---|---|
| `gemini-nano-banana-2.1`, 1K, batch | $0.0168 | $15.96 |
| `gemini-nano-banana-2.1`, 1K | $0.0336 | $31.92 |
| `gemini-nano-banana-2.1`, 2K | $0.0504 | $47.88 |
| `gemini-3-pro-image`, 1K to 2K | $0.134 | $127.30 |

Input tokens for prompts and reference images add a little to each request and
are not counted here. The art for the whole game is likely to cost tens of
dollars, not hundreds, unless many more attempts are needed.

## 3. Rights and obligations

Source for the terms: <https://aistudio.google.com/docs/terms> (the Gemini API
Additional Terms of Service).

- **Ownership.** "Some of our Services allow you to generate original content.
  Google won't claim ownership over that content. You acknowledge that Google
  may generate the same or similar content for others and that we reserve all
  rights to do so."
- **Responsibility.** "You're responsible for your use of generated content, and
  for the use of that content by anyone you share it with."
- **Who may use it.** "Use of Google AI Studio and Gemini API is for developers
  building with Google AI models for professional or business purposes, not for
  consumer use." and "You must be 18 years of age or older to use the APIs."
- **Paid and unpaid use differ in privacy.** Paid: "When you use Paid Services,
  including, for example, the paid quota of the Gemini API, Google doesn't use
  your prompts (including associated system instructions, cached content, and
  files such as images, videos, or documents) or responses to improve our
  products". Unpaid: "human reviewers may read, annotate, and process your API
  input and output." Image output is paid anyway (section 2).
- **Safety filters may not be worked around.** "You may not attempt to bypass
  these protective measures".
- The terms restrict offering an app that calls the API to users in Europe on
  unpaid service. Inference: this does not apply, because the game itself never
  calls the API; images are made during development.

Source for the policy quotations below, Google's Prohibited Use Policy:
<https://policies.google.com/terms/generative-ai/use-policy>

- It prohibits content that facilitates "Violence or the incitement of
  violence." Inference: stylised fantasy combat art is not incitement, but
  where the filters draw the line for corpses and undead is unverified until
  tried. The policy allows for art: "We may make exceptions to these policies
  based on educational, documentary, scientific, or artistic considerations, or
  where harms are outweighed by substantial benefits to the public."
- **Do not pass the art off as hand-made.** The policy prohibits
  "Misrepresenting the provenance of generated content by claiming it was
  created solely by a human, in order to deceive." Inference: store text,
  credits and press material must not describe the sprites as hand-drawn.

Not settled by the pages read:

- **Unverified:** whether the terms require telling players the art is
  AI-generated. No such requirement was found; the rule found is against
  claiming the opposite.
- **Unverified:** whether Adam can hold copyright in generated sprites. The
  terms say only that Google does not claim ownership. That is a question of
  law that these pages do not answer, and the answer may differ by country.
  The United States Copyright Office's guidance would be the primary source; it
  was not reachable from this session.
- **Unverified:** whether the SynthID watermark survives cropping, scaling down
  to sprite size and background removal, and what Google's terms say about
  removing it. The page describing SynthID was not reachable. Inference: treat
  the watermark as something to leave alone, and never process images for the
  purpose of removing it.
- **Unverified:** whether Google indemnifies users for the output. Nothing on
  the pages read says so.

## 4. Apple's rules

Source: <https://developer.apple.com/app-store/review/guidelines/>

- The guidelines were searched for AI, generative, artificial intelligence,
  machine learning and synthetic. **No rule specific to AI-generated artwork in
  a game was found.** The matches concern apps that let users generate content
  and apps that share personal data with third-party AI; neither describes this
  game.
- The ordinary rules apply to generated art as to any art. Intellectual
  property (5.2.1): "Don't use protected third-party material such as
  trademarks, copyrighted works, or patented ideas in your app without
  permission". Inference: prompts must not name other games, studios, artists
  or characters, and results that resemble a known character must be
  discarded. The project already forbids borrowing from its reference games.
- Violence (1.1.2) is limited to "Realistic portrayals of people or animals
  being killed, maimed, tortured, or abused, or content that encourages
  violence." Inference: stylised sprite combat is the normal case for a
  fantasy game; realistic gore should be avoided in the art direction.
- Store imagery has a stricter rule (2.3.8): "if your app is a game that
  includes violence, select images that don't depict a gruesome death or a gun
  pointed at a specific character." Inference: because corpses are the centre
  of this game, the icon and screenshots need care. Corpse markers should read
  as game pieces, not gore.
- Screenshots must be real (2.3.3): "Screenshots should show the app in use, and
  not merely the title art, login page, or splash screen." Generated key art
  cannot stand in for screenshots.
- **Unverified:** whether App Store Connect's age-rating questions or product
  page ask about AI-generated content. Those pages were not read.

## 5. Proposed pipeline

All of this is inference from the facts above, to be tested with a small trial
before any real production.

1. **One paid project, key kept out of the repository.** The API key lives in
   an environment variable on the machine that generates art. It is never
   committed, logged or pasted into chat.
2. **Style first.** Produce two or three style reference images and get Adam's
   approval. Every later request includes them, so units share one look.
3. **One character sheet per unit.** Generate the idle pose, approve it, then
   produce the other frames (attack, hit, death, corpse) by editing that image
   with the approved pose as a reference. Stay within the documented limit of
   four characters per workflow by doing one unit at a time.
4. **Plain background, removed locally.** Ask for a flat background colour that
   does not occur in the sprite. Remove it with a script on our side, then trim
   and scale to the tile size. Do not rely on the model for transparency.
5. **Keep provenance.** For every kept image, store the prompt, the model id,
   the date and the untouched original in the repository (or in storage the
   repository points to). This supports the provenance rule and makes
   regeneration possible when a model is retired.
6. **Into Xcode.** Scaled sprites go into a sprite atlas in the asset catalog
   (RESEARCH.md 6.3).
7. **Pixel art or high resolution** is decided after the display measurements
   on the Mac (RESEARCH.md 6.1 and 6.2) and after the trial shows which the
   model does well. High-resolution art scaled down is the safer assumption.

The trial, before anything else: one unit (a Skeleton), four frames, at 1K,
with `gemini-nano-banana-2.1`. At $0.0336 an image, twenty attempts cost about
67 cents. It answers the three open questions in section 1.

## 6. Questions for Adam

1. Which Google product and model did Gravewright use, and is the account on
   paid billing? If it used `gemini-2.5-flash-image`, that model is deprecated.
2. Are you content for the game to be openly described as using AI-generated
   art? Google's policy forbids claiming otherwise, and some players care.
3. The copyright position of generated sprites is unsettled in this research.
   If that matters for the release, it is worth asking someone qualified.
