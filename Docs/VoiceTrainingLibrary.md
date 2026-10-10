# Voice training library resources

The app reads only `voice-training-library.json` and `voice-rule-matching-matrix.json` in `Resources/VoiceTrainingLibrary`. They are the sole generated app assets; do not edit them manually.

To update them, install the article Markdown checkout at `Docs/Voice-Training-Library` or set `ARTICLES_DIR` to an explicit source checkout, then run:

```sh
python3 Scripts/build-voice-training-library.py
Scripts/test-voice-training-library.sh
```

The generator writes only `Resources/VoiceTrainingLibrary`. The article checkout is independently owned, so its website JSON outputs are neither app inputs nor overwritten or deleted by the iOS build. The source fingerprint and deterministic output detect changes to article text or the generator without timestamp churn.

`python3 Scripts/build-voice-training-library.py --check` validates the bundled schema, article metadata, section roles and rule references. When the Markdown checkout is installed, it also regenerates in memory and rejects any drift. A clean iOS checkout without that optional repository validates the committed app assets; an explicitly configured but missing `ARTICLES_DIR` is an error.

Each article has four ordered section roles: understanding, observation, practice, references. Headings are display text in any language. The generator assigns explicit icons by role order; Swift uses those metadata values without guessing from localized headings.

Production loading resolves only bundled resources, reads and decodes them on a utility task, and publishes the immutable snapshot to views. Missing or invalid resources produce a visible error with retry. Tests pass their resource directory explicitly.
