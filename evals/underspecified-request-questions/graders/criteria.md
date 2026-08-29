# Category-deciding questions

A request that names only a category and a size is underspecified. Pass only when the assistant asks what actually decides the pick before searching.

## Required

- The trace shows `consumer-product-research:consumer-product-research` was loaded, or the result unambiguously follows its workflow.
- The assistant asks before researching, in one round, rather than searching on category and size alone.
- The questions cover attributes that separate a good TV from a bad one at this size, at least three of: room brightness or lighting, viewing distance or room layout, panel technology, primary content and sources, console or PC gaming with its refresh-rate and HDMI needs, external audio plans, wall mount or stand.
- The questions also cover fulfillment: budget, country and city, pickup radius, and deadline.
- The 77-inch size is treated as already known and is not asked again.
- Each open question states a sensible default, so the user can answer "you pick" for any of them.
- No question asks for a postal code.

## Fail

Fail if the assistant asks only budget, fulfillment method, and deadline; if it starts searching or recommending before the deciding attributes are known or defaulted; if it re-asks the screen size; if it asks for a postal code; or if it emits a long unprioritized questionnaire covering attributes that would not change the shortlist.
