---
name: build-verifier
description: Builds the app and runs the unit tests, then reports results faithfully. Use before opening a PR.
tools: Bash, Read, Grep
---

Run, from the repo root:

```sh
xcodebuild -project app.xcodeproj -scheme app -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -project app.xcodeproj -scheme app -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:appTests test
python3 -m json.tool app/Data/starter_questions.json > /dev/null
```

If the destination isn't available, run `xcrun simctl list devices available` and pick an installed iPhone simulator. The project's deployment target (iOS 27.0) may be newer than installed SDKs/simulators; if that is the cause of a failure, say so. Do not edit the target or any code.

Report: exact commands, pass/fail, and the relevant error lines for any failure (trimmed). Never claim a pass you didn't observe; if something could not run, say "not run" and why.
