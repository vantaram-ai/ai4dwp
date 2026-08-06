# T-1005 - Teams audio dead on three machines in the same meeting room

## Triage Summary
Summary: Teams audio is non-functional on three machines in the same meeting room. Impact: multiple users/devices, moderate to high, meeting disruption risk; escalate priority if active business meetings are affected. Known facts: issue is with Teams audio, three machines are affected, all are in one meeting room. Missing info: microphone vs speaker vs both, Teams-only vs system-wide audio failure, shared room peripheral/dock in use, when issue started exactly, any recent Teams/Windows/room hardware change. Likely category: shared meeting-room audio peripheral path issue (device/cable/dock) or room-specific configuration issue. First step: validate Windows input/output device detection and audio test on all three machines, then compare against Teams device selection in the same room setup.

## End-User Communication
Hi - we've raised and triaged the audio issue in your meeting room and we're actively working on it now. At the moment, three machines in that room are affected, and we are checking both the room equipment and the device settings to restore service as quickly as possible. Your data and access are safe. For now, please use an alternate room or a different device for urgent calls if available. We'll share another update as soon as we confirm the fix.

## Known-Error Record
Symptom: Teams audio is dead on three machines in the same meeting room.
Cause: to confirm (suspected shared room audio path/peripheral or room-specific configuration issue).
Scope: Three confirmed machines in one meeting room; wider impact beyond this room is to confirm.
Workaround: Use an alternate meeting room or device for urgent calls; local IT can test temporary direct audio-device connection per machine.
Permanent fix: to confirm after RCA (likely correction/replacement of shared room audio path or configuration, then validation on all room machines).

## RCA
Incident: T-1005 Teams audio dead on three machines in the same meeting room.
Verified observations: Teams audio failure is reported; three machines are affected; all affected machines are in one meeting room.
Most likely fault domain: Shared meeting-room setup rather than isolated single-device failure (to confirm).
Working root cause statement: A room-level audio path/configuration issue is preventing Teams audio on multiple machines in the same room (to confirm).
Evidence required to confirm: Windows playback/recording test results on all three machines, Teams device-selection state, shared peripheral/dock/cabling check, and same-machine test in a different room.
Corrective action plan: confirm fault domain, remediate failing room component/configuration, re-test Teams audio on all three machines, then monitor for recurrence.
