# Art pipeline: Google image generation for the sprites

Researched 2026-11-26 from Google's and Apple's own pages. Decided at GATE 2:
the game's sprites will be made with Google's image generation, and the game is
meant for an eventual App Store release.

How to read this file:

- Quoted text is verbatim from the linked page and is checked by script
  (`tools/citations/check_doc.py`).
- **Inference** marks Claude's conclusions. **Unverified** marks what no page
  read settles.
- Claude wrote the first version from the pages directly. An independent
  reviewer then read it against those pages and others, and found 15 problems
  and omissions. This version includes the corrections. The largest: Google
  says outright that transparent backgrounds are not supported; style
  references are documented only for the dearest model; and Apple's rules on
  disturbing content and on store imagery are wider than first reported.
- No image was generated and no API was called for this research. Nothing here
  has been tried.
- This is not legal advice. It reports what the documents say.
- Which Google product, model and account the earlier Gravewright project used
  is not known in this session. This file covers the Gemini API as Google
  documents it today.
- Not read, because the sites were not reachable: the base Google APIs Terms of
  Service (which the Gemini terms build on, and where licence, liability and
  indemnity clauses would be), Google's page on the SynthID watermark, and any
  copyright office guidance.

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
- Models are retired on short notice. "The shutdown dates listed in the table
  indicate the earliest possible dates on which a model might be retired".
  <https://aistudio.google.com/docs/deprecations>
- Size: "By default, the model matches the output image size to that of your
  input image, or otherwise generates 1:1 squares." Aspect ratio and size (1K,
  2K, 4K) can be set per request.
- Character consistency: "`gemini-nano-banana-2.1` and `gemini-3.1-flash-image`
  support character resemblance of up to 4 characters and the fidelity of up to
  10 objects in a single workflow." The guide's advice for a series: "For best
  results, include previously generated images in subsequent prompts to
  maintain consistency."
- **Style references are documented only for the dearest model.** In the page's
  table of reference-image roles, "Up to 3 images to be used as style
  references" is listed for `gemini-3-pro-image` and marked not applicable for
  `gemini-nano-banana-2.1`. **Unverified:** whether the cheaper model holds a
  style from reference images anyway.
- **Transparent backgrounds are not supported.** The other version of the same
  guide says: "Note: The model does not support generating a transparent
  background." Its advice for game-like assets: "To create stickers, icons, or
  assets, be explicit about the style and request a white background."
  <https://aistudio.google.com/docs/image-generation?generate-content=true>
  White clashes with pale bone, so a different background colour may be needed.
  **Unverified:** whether a colour other than white is honoured cleanly.
- The count of images per request is not reliable: "The model won't always
  follow the exact number of image outputs that the user explicitly asks for."
  Plan one frame per request.
- **Every image is watermarked:** "All generated images include a SynthID
  watermark".
- The guide has no advice on pixel art or sprite sheets in either version.
  **Unverified:** how well the models hold a pixel grid or a fixed palette.

## 2. Cost

Source: <https://aistudio.google.com/docs/pricing>

- Image output on these models is paid only. In the pricing tables for all five
  image models, the free tier column reads "Not available" for output.
- `gemini-nano-banana-2.1`: "Image output is priced at $30 per 1,000,000 tokens
  (Standard) and $15 per 1,000,000 tokens (Batch). Output images at 1K
  (1024x1024px) consume 1120 tokens and are equivalent to $0.0336 per image."
  The table gives $0.0504 for a 2K image and $0.113 for a 4K image, and half
  those prices through the Batch API. (The image guide gives a different token
  count for 4K than the pricing page; the pricing page is used here.)
- `gemini-3-pro-image`: "Image output is priced at $120 per 1,000,000 tokens.
  Output images from 1024x1024px (1K) and up to 2048x2048px (2K) consume 1120
  tokens and are equivalent to $0.134 per image."
- Batch is not for interactive work: "The target turnaround time is 24 hours,
  but in majority of cases, it is much quicker."
  <https://aistudio.google.com/docs/batch-api>

Estimate (inference; the quantities are guesses, the prices are Google's):
20 unit types × 8 images each, plus 30 terrain and effect images, is 190 kept
images. At 5 attempts per kept image that is 950 generations.

| Model and size | Per image | 950 images |
|---|---|---|
| `gemini-nano-banana-2.1`, 1K, batch | $0.0168 | $15.96 |
| `gemini-nano-banana-2.1`, 1K | $0.0336 | $31.92 |
| `gemini-nano-banana-2.1`, 2K | $0.0504 | $47.88 |
| `gemini-3-pro-image`, 1K to 2K | $0.134 | $127.30 |

Not counted, so the real figure is somewhat higher: input tokens for prompts
and reference images, and a second output charge for the model's text and
thinking, which cannot be switched off: "Note that thinking tokens are billed by
default for thinking models, as the thinking process always happens by default
whether you view the process or not."
<https://aistudio.google.com/docs/image-generation> Google does not document how
many such tokens an image takes, so the trial in section 5 records token usage
per request. If only the Pro model holds a style (section 1), the relevant row
is the last one.

How the money is controlled. Source: <https://aistudio.google.com/docs/billing>

- Paid use is prepaid: "Upgrading from the Free Tier to the Paid Tier means
  linking a billing account and prepaying to add a minimum of $5 (or equivalent
  in other currencies) of credits to your account." So the trial, which costs
  under a dollar, needs a $5 purchase. Credits lapse: "unused credits expire
  after 12 months and are non-refundable".
- When the balance runs out, everything on that account stops: "When your Prepay
  credit balance on the billing account hits $0, all API keys in all projects
  linked to that billing account will stop working simultaneously."
- A cap can be set: "You can set your own project-level spend caps in AI
  Studio."
- Google also has a spending rate limit ("Gemini API enforces spend-based rate
  limits to protect against unexpected charges."
  <https://aistudio.google.com/docs/rate-limits>), but at $10 per ten minutes for
  the first usage tier it would never bind on this project. It is not a budget.

## 3. Rights and obligations

Source for the terms: <https://aistudio.google.com/docs/terms> (the Gemini API
Additional Terms of Service, effective March 23, 2026). Using the API also
means accepting the base Google APIs Terms of Service, which were not read.

- **Ownership.** "Some of our Services allow you to generate original content.
  Google won't claim ownership over that content. You acknowledge that Google
  may generate the same or similar content for others and that we reserve all
  rights to do so."
- **Responsibility.** "You're responsible for your use of generated content, and
  for the use of that content by anyone you share it with." And: "Use discretion
  before relying on, publishing, or otherwise using content provided by the
  Services."
- **Who may use it.** "Use of Google AI Studio and Gemini API is for developers
  building with Google AI models for professional or business purposes, not for
  consumer use." and "You must be 18 years of age or older to use the APIs."
- **No app for minors may call the API.** "You also will not use the Services as
  part of a website, application, or other service (collectively, "API Clients")
  that is directed towards or is likely to be accessed by individuals under the
  age of 18." Inference: the game is fine only because it never calls the API;
  images are made during development. A game likely to be rated 13+ (section 4)
  must never ship a feature that generates images in the app.
- **Paid and unpaid use differ in privacy.** Paid: "When you use Paid Services,
  including, for example, the paid quota of the Gemini API, Google doesn't use
  your prompts (including associated system instructions, cached content, and
  files such as images, videos, or documents) or responses to improve our
  products". Unpaid: "human reviewers may read, annotate, and process your API
  input and output." Paid means the API with billing attached. If Gravewright's
  images were made in the AI Studio web page without billing, the unpaid terms
  applied to them.
- **Paid use is still logged and can be reviewed.** "Google retains the
  following data for fifty-five (55) days for the purposes of detecting and
  preventing violations of the Prohibited Use Policy". Repeated trouble can cost
  the account: "As a last resort, and for serious violations, we may permanently
  close your access to the Gemini API and other Google services."
  <https://aistudio.google.com/docs/usage-policies>
- **Safety filters may not be worked around.** "You may not attempt to bypass
  these protective measures".

Source for the policy quotations below, Google's Prohibited Use Policy:
<https://policies.google.com/terms/generative-ai/use-policy>

- It prohibits content that facilitates "Violence or the incitement of
  violence." Inference: stylised fantasy combat art is not incitement. The
  policy allows for art: "We may make exceptions to these policies based on
  educational, documentary, scientific, or artistic considerations, or where
  harms are outweighed by substantial benefits to the public."
- **Do not pass the art off as hand-made.** The policy prohibits
  "Misrepresenting the provenance of generated content by claiming it was
  created solely by a human, in order to deceive." It does not require a label.
  Inference: store text, credits and press material must not describe the
  sprites as hand-drawn.
- It also prohibits content that "Violates the rights of others, including
  privacy and intellectual property rights".

How the filters behave. Source: <https://aistudio.google.com/docs/safety-settings>

- There is no violence or gore setting to adjust, and the adjustable filters are
  already off: "Categories you don't set use the default threshold, which is Off
  for Gemini 2.5 and later models." What remains is the model's own judgement,
  which only a trial shows.
- A blocked request fails cleanly: "If a safety filter blocks the input or the
  model's response, the interaction fails with an HTTP 400 error. The blocked
  content isn't returned."
- Rule for this project (inference from the two points above and the logging):
  record every block, and change the art direction instead of rewording a
  blocked prompt to get the same picture.

Not settled by the pages read:

- **Unverified:** whether the law anywhere requires telling players the art is
  AI-generated. Neither Google's terms nor Apple's pages require a label. Apple
  is adding watermark detection to its own apps ("Support for SynthID
  watermarking to help identify whether an image was generated or modified with
  generative tools in Photos and Image Playground",
  <https://support.apple.com/en-us/149076>), so provenance may be discoverable
  whatever the store page says. Whether that reaches game sprites is unknown.
- **Unverified:** whether Adam can hold copyright in generated sprites. The
  terms say only that Google does not claim ownership. That is a question of
  law that these pages do not answer, and the answer may differ by country.
  Apple puts the rights question on the person submitting (section 4), so this
  matters for the release.
- **Unverified:** whether the SynthID watermark survives cropping, scaling down
  to sprite size and background removal. The terms and the policy do not
  mention watermarks. Inference: leave it alone, and never process images for
  the purpose of removing it.
- **Unverified:** whether Google indemnifies users for the output. The Gemini
  terms contain no indemnity; the base terms were not read.

## 4. Apple's rules

Source: <https://developer.apple.com/app-store/review/guidelines/> (last updated
October 16, 2026).

- The guidelines were searched for AI, generative, artificial intelligence,
  machine learning and synthetic. **No rule specific to AI-generated artwork in
  a game was found.** The matches concern apps that let users generate content
  and apps that share personal data with third-party AI; neither describes this
  game. Apple's age-rating definitions have no question about generated art
  either.
- **Rights are the submitter's responsibility** (5.2.1): "Don't use protected
  third-party material such as trademarks, copyrighted works, or patented ideas
  in your app without permission", and "Apps should be submitted by the person
  or legal entity that owns or has licensed the intellectual property and other
  relevant rights." Inference: prompts must not name other games, studios,
  artists or characters, and results that resemble a known character are
  discarded. The project already forbids borrowing from its reference games.
- **Objectionable content is a broad standard** (1.1): "Apps should not include
  content that is offensive, insensitive, upsetting, intended to disgust, in
  exceptionally poor taste, or just plain creepy." One listed example (1.1.2):
  "Realistic portrayals of people or animals being killed, maimed, tortured, or
  abused, or content that encourages violence." Inference: stylised undead are
  the normal fantasy case, but in a game centred on corpses the art must stay
  clear of anything a reviewer could call intended to disgust.
- **Store imagery must suit all ages** (2.3.8): "Metadata should be appropriate
  for all audiences, so make sure your app and in-app purchase icons,
  screenshots, and previews adhere to a 4+ age rating even if your app is rated
  higher." Apple's example: "if your app is a game that includes violence,
  select images that don't depict a gruesome death or a gun pointed at a
  specific character."
- **Screenshots must be real** (2.3.3): "Screenshots should show the app in use,
  and not merely the title art, login page, or splash screen." Inference from
  the last two rules together: the game needs real play states that are fit
  for a 4+ audience, so corpse markers should read as game pieces, and some
  screens should show none.

Age rating. Source:
<https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions>

- The categories that fit this game: "Cartoon or Fantasy Violence: Physical
  conflict or harm of an exaggerated or fantastical nature that can easily be
  distinguished from real life." and "Horror/Fear Themes: Content or storylines
  that evoke feelings of anxiety, dread, or terror."
- The one to stay out of: "Prolonged Graphic or Sadistic Realistic Violence:
  Prolonged detailed or realistic-looking depictions of physical conflict."
  That rating blocks release: "An Unrated app can't be published on the App
  Store."
- Inference: expect a 13+ rating. Realistic-looking gore is the one art choice
  that could stop the release. Some countries have their own rating tables,
  which were not read.

## 5. Proposed pipeline

All of this is inference from the facts above, to be tested with a small trial
before any real production.

1. **One paid project, key kept out of the repository.** Prepay the $5 minimum,
   leave automatic top-up off, and set a project spend cap. The API key lives
   in an environment variable on the machine that generates art. It is never
   committed, logged or pasted into chat.
2. **Style first.** Produce two or three style images and get Adam's approval.
   Google documents a style-reference role only for `gemini-3-pro-image`
   (section 1), so the trial must show whether the cheaper model can hold the
   style from references. If it cannot, the Pro model is the one to use.
3. **One character sheet per unit, one frame per request.** Generate the idle
   pose, approve it, then produce the other frames (attack, hit, death, corpse)
   by editing that image with the approved pose included as a reference, as the
   guide advises. Do one unit at a time.
4. **Plain background, removed locally.** The models cannot produce
   transparency. Ask for a flat background, white as Google suggests or a
   colour that does not occur in the sprite, remove it with a script on our
   side, then trim and scale to the tile size.
5. **Keep provenance.** For every kept image, store the prompt, the model id,
   the date and the untouched original. This supports the provenance rule and
   lets a later model be given the approved originals as references. A retired
   model cannot be re-run, so each unit's full set should be produced within one
   model's lifetime.
6. **Into Xcode.** Scaled sprites go into a sprite atlas in the asset catalog
   (RESEARCH.md 6.3).
7. **Pixel art or high resolution** is decided after the display measurements
   on the Mac (RESEARCH.md 6.1 and 6.2) and after the trial shows which the
   model does well. High-resolution art scaled down is the safer assumption.
8. **Art direction limits:** stylised, not realistic; nothing designed to
   disgust; corpse markers that read as game pieces (section 4).

The trial, before anything else: one unit (a Skeleton), four frames, at 1K, on
both `gemini-nano-banana-2.1` and `gemini-3-pro-image`, on a white background
and on a coloured one. That is a few dollars at most. It answers: does the
cheaper model hold a style, does a coloured background come out clean, does the
model accept undead and corpse subjects, how does it do with a pixel grid, and
what does an image really cost once thinking tokens are counted.

## 6. Art direction notes

**Reference shared by Adam, 2026-11-26.** A painted illustration of an armoured
dark lord: horned crown-helm with glowing eyes in a dark visor, heavy blackened
plate with skull motifs, a fur mantle, a torn crimson cloak and sash, a great
sword carried on the shoulder, and one gauntlet lit from within. It appears to
be character art from an existing game. The image is **not stored in this
repository** and must not be: it is someone else's artwork.

How it may be used, given the project's rules (original IP only) and section 4
(Apple 5.2.1, Google's policy on others' rights):

- As a mood reference only. It is never given to the image generator as a
  reference image, never named or described by its source in a prompt, and
  never traced.
- What to take from it, in general terms that many works share: a heavy,
  readable silhouette; dark metal against one strong accent colour; a single
  point of inner light; trophies and fur that say "warlord" before "wizard".
- What must be our own: the helm and crown shape, the emblem language (ours
  should come from this game's world, not generic skulls), the colour scheme,
  the weapon, and the proportions.
- It suits the Death Knight overlord path. The Lich King path needs its own
  look.
- It points toward high-resolution painted 2D and away from pixel art. At map
  size a unit is about 44 points across, so the silhouette and one accent
  matter far more than surface detail; the detail would live in portraits,
  menus and the store page.
- It is darker and more realistic than the current mock-ups. That is fine for
  a 13+ rating, but store imagery still has to suit all ages (section 4).

**Second reference, 2026-11-26.** Adam asked that the game also draw
inspiration from the anime *Overlord*, whose ruler is a robed skeletal sorcerer
in rich colour and gold. The same limits apply: mood only, nothing copied, the
screenshot is not stored, and neither the title nor any character is ever named
in a prompt. For art, it points to a robed, crowned-skull silhouette for the
**Lich King** path, as the armoured figure does for the Death Knight path. The
game-design ideas taken from it are in GDD section 15.

What Wikipedia says of that ruler's look is only that he is "skeletal"
(`RESEARCH.md` 7.6). The robes, gold and colour are Claude's recollection and
were not checked.

**Third reference, 2026-11-26.** Adam added *Solo Leveling*. Wikipedia does not
describe how that series looks, so nothing about its look is verified here. The
one art idea taken is general and would stand without the series: **everything
the player has raised shares one mark**, a single glow colour in the eyes or
joints.

- At map size (about 44 points a unit) it makes a large army read as one side
  at a glance, and makes a newly raised enemy visibly change sides.
- It suggests a way to make each undead from its living form: draw the living
  unit first, then produce the raised version from our own image, so the
  silhouette stays recognisable. Whether Google's models do this well is not
  known; it is a thing to try in the trial in section 5.
- The mark's colour and form must be our own. The same limits apply as above:
  mood only, no image stored, and the series is never named in a prompt.

**Fourth reference, 2026-11-26.** Adam sent the title screen of *Undead Horde*,
a game he owns. Unlike the two series, this one Claude could see. The same
limits apply: mood only, the image is not stored, and the game is never named
in a prompt. What the screen shows:

- A painted illustration, not pixel art: a horned necromancer in red above a
  crowd of armoured skeletons, in a ruined village.
- **One shared mark, seen first-hand.** Every undead has the same green glow in
  its eyes, and the necromancer's hands and weapons carry it too. This is the
  idea proposed above from memory of *Solo Leveling*; here it is visible, and
  it does make the crowd read as one side. A green glow for necromancy is a
  common convention, so our mark should be a different colour to stand apart.
- **The dead wear what they wore in life.** The skeletons keep the helmets,
  shields and armour of the soldiers they were. That matches this game's rule
  that a body rises as a form of what it was, and it helps the player read
  what a raised unit used to be.
- Two colours carry the picture: cold green-teal for the undead and the scene,
  and crimson for the leader, so the leader stands out from his own army.
- The tone is lighter than the armoured dark lord: the start button reads
  "Necromance!". That bears on the open question of humour (GDD 15.7).
- The picture sits in a wide frame with a black band above it. If this is a
  screenshot from the open inner display of the iPhone Duo, it shows how an
  older game that has not been updated for the fold appears there. Claude does
  not know which device it came from.

## 7. Questions for Adam

1. Which Google product and model did Gravewright use, and was it the API with
   billing or the AI Studio web page? If it used `gemini-2.5-flash-image`, that
   model is being retired.
2. Are you content for the game to be openly described as using AI-generated
   art? Google's policy forbids deceptively claiming the art is solely
   human-made; it does not require a label. Some players care either way.
3. Apple expects whoever submits the app to own or have licensed its art, and
   the copyright position of generated sprites is unsettled in this research.
   Before release that is worth asking someone qualified.
