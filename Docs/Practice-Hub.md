# Practice Hub

Practice Hub occupies the former live-monitoring tab (the third item). The existing second recording tab, its icon, navigation, and recording accessory remain independent.

The About tab has no knowledge-library entry. The hub uses an inset-grouped system List. Its two sections contain live pitch/spectrum destinations and the eight knowledge-library categories. Search queries the complete library and opens the matching article directly. It contains no introduction, hero card, suggested exercises, or duplicated recording flow.

The UI uses NavigationStack, NavigationLink, List, Section, searchable, Menu, and Picker. System navigation and controls provide Liquid Glass. Reading content and result suggestions use solid system backgrounds. Text follows Dynamic Type; navigation and separators are supplied by the platform.

## Spectrum

Spectrum is an additional, independent entry in Live Monitoring. The existing Live spectrum curve and Live fundamental frequency tools retain their destinations and layouts. Spectrum opens a scrolling spectrogram with time from left to right and a logarithmic 40–8,000 Hz frequency axis from bottom to top. Indigo, purple, orange, and yellow encode increasing signal strength over −90...0 dBFS.

The page owns its monitoring session and opts into cached FFT image columns; existing monitor pages do not rasterize these columns. It supports 5-, 10-, and 30-second windows, pause/resume, seeking, and replay through the existing transport. The most recent 60 seconds stay in memory and are cleared when leaving. The debug-only `-practice-spectrum-preview -monitor-preview-data` arguments open the independent page with a synthetic harmonic fixture.

Sources: [Apple HIG: Materials](https://developer.apple.com/design/human-interface-guidelines/materials), [Apple HIG: Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars), [Adopting Liquid Glass](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass).

## Result suggestions

“Practice guides” and “Suggestions” share one compact group. Each of the one or two rows contains a short action title and one brief explanation; tapping a row opens its supporting guide when one exists. The result retains a single complete-library entry.

The matcher checks recording quality and usable pitch/score data before choosing a voice exercise. Short, clipped, noisy, incomplete, or unreliable recordings receive capture corrections. Reliable recordings use the captured goal; undecided users do not inherit feminine scoring rules, masculine advice does not assume hormone use, and low naturalness is not treated as a medical diagnosis. Suggestions and linked articles are deduplicated and limited to two.

## Article web links

Every article exposes a public URL computed from its stable ID: `https://articles.pitchee.dev/{id.lowercased()}`. Paths have no `/articles` prefix, `.html` suffix, or trailing slash. For example, `RULE-CONTINUOUS-01` maps to `https://articles.pitchee.dev/rule-continuous-01`. Titles, content, and filenames are not inputs to URL generation. The Markdown builder still reads the ID from the filename prefix, so renaming source files must preserve that prefix.

The shared article reader includes an Open in Browser action and shares the URL with the article title as its preview. This applies to articles opened from recommendations, search, and category lists. The default reader continues to use bundled content, including offline. These are the planned production links; browser access requires the article website to be deployed.

## Verification

- Debug iOS Simulator build passed with Xcode 27.1.
- Latest matcher/library script passed under strict concurrency and warnings-as-errors, including the 49-article resource checks.
- Live spectrum: 27 checks passed; monitor timeline: 311 checks passed.
- Practice: 29 checks; historical-data migration; audio quality: 5 checks passed.
- Voice scoring: 10,745 checks across 1,530 reference cases passed.
- Final hub layout visually checked at normal text size/light appearance and accessibility-large/dark appearance on a dedicated iPhone 17 simulator.
- All 29 supported interface languages pass catalog validation and runtime checks, including practice labels, article counts, and reading times. See [Localization validation](Localization-Validation.md). The 49 article bodies remain in their original language for this release of the interface translations.

The debug-only `-practice-hub-preview` launch argument opens the third tab for isolated visual review without changing saved preferences. The normal launch behavior is unchanged.
