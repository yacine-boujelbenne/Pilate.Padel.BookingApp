# Rive Marketplace — selected motion plan

User requested [Rive Marketplace](https://rive.app/marketplace/) as an additional source. This extends the existing design proposal; payment improvements remain last and the original mint/sage palette remains the foundation.

## Placement and shortlist

| Moment | Candidate | Intended use |
|---|---|---|
| Reservation confirmed | [Success Check — guidorosso](https://rive.app/marketplace/1029-2009-success-check/) | Play once after the existing booking operation succeeds. Keep confirmation text and navigation usable immediately; simplify particles if needed for the restrained brand |
| Loading → success/error | [Spinner / Loading — benjad](https://rive.app/marketplace/13255-25054-spinner-or-loading/) | Candidate for a bounded submission state. Drive it from real controller state rather than a timer; never report success before the operation succeeds |
| Notifications / waitlist feedback | [Bell Notification — antonz](https://rive.app/marketplace/1215-27227-bell-notification/) | One brief acknowledgment when enabling a supported notification preference or joining a waitlist. It does not mean a remote notification has been delivered |

These listings label their assets **CC BY**. Status: source metadata reviewed and candidates shortlisted; files have not been downloaded, visually previewed in motion, recolored, or tested in Flutter. Final selection requires the downloadable file, specific license/version, creator attribution, available artboards/state machines, palette adaptability and runtime compatibility to be checked. Do not assume every Marketplace item has the same terms or that a preview proves a free export is available.

Empty states can use a suitable restrained Marketplace illustration if one is found; no extra mascot or looping decoration is required. Native skeletons, date selection, buttons, sheets and route transitions remain Flutter-native.

## Cost and licensing

The [official Flutter runtime](https://github.com/rive-app/rive-flutter) is MIT licensed. Runtime licensing is separate from Marketplace asset licensing and the editor/export service.

The current [Rive pricing page](https://rive.app/pricing) says free exports include a Rive splash screen and paid plans remove it. Check the actual selected download/export path and behavior before committing it to the app. Do not purchase an asset/subscription or remove required branding. If a candidate cannot meet the existing free-use constraint, choose a suitable free downloadable asset or retain the native fallback and document the limitation.

Record selected creator, listing URL, license/version, modifications and required attribution with the shipped assets. Bundle approved `.riv` files locally rather than depending on a Marketplace preview URL at runtime. Use legitimate asset customization; do not modify binary exports to bypass branding or export restrictions.

## Flutter implementation requirements

- Choose one compatible stable runtime version against the existing Flutter SDK/lockfile after the environment is runnable; no broad dependency upgrade.
- Follow the [Flutter runtime documentation](https://rive.app/docs/runtimes/flutter/flutter) for bundled loading, renderer compatibility, loading/error handling and resource disposal. Validate assets against the selected runtime rather than blindly copying the newest API examples.
- Centralize a small shared animation wrapper only when integrating actual assets. It should accept meaningful UI state, avoid restarting on Provider rebuilds, and include static/native loading and failure fallbacks.
- Match original sage `#7A9082`, primary sage-dark `#5A6E62`, mint `#EBF3EE` and charcoal `#2C3A33` where the selected asset supports safe recoloring. Use a different candidate if its fixed colors clash and free customization/export is unavailable.
- Under reduced motion, use a static meaningful frame/icon plus the same status text. Exclude decorative animation from screen-reader traversal; announce the real state through Flutter semantics.
- Stop playback offscreen and dispose controllers/loaders appropriately. Profile representative Android/iOS/web targets; avoid animated bells or individual Rive instances in every scrolling list row.
- Never let animation delay confirmation, obscure a control, capture a required gesture, invent a delivery state, or change booking/payment behavior.

This is a planning artifact. No animation package, paid service, Rive CLI, asset, or application change has been installed or activated.
