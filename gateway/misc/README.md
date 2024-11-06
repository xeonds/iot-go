## automation structure

Architecture:
- Trigger sources: time, device status, device data, etc
- Actions: control device, send notification

When run `RunAutomation()`, a channel will be created to listen to trigger sources. And itself will also send some trigger sources (like time.tick) to the channel.

And then, when a trigger source is received, it will be processed by the automation engine. If the trigger event matchs any of the automation rules, the corresponding action will be executed by the automation engine.
