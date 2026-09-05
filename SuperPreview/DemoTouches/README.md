# Demo touch visualization

Open any page's Debug panel and enable **Show Touch**. All panels share one setting,
saved across launches. The switch works without a debugger or a mirrored display.
Disable it in any panel to remove all indicators immediately.

`DemoTouchWindow` observes direct touches delivered to the app's main window and
forwards every event exactly once. A noninteractive, non-key overlay window renders
48pt circles above page content, sheets, and full-screen covers. Multiple fingers
are supported; indicators follow each finger without trails, then fade over 0.3s.
Scene deactivation clears active and fading indicators.

The implementation is enabled for Debug builds or builds explicitly compiled with
`DEMO_TOUCHES`. Normal Release builds hide the switch and use a standard UIWindow.
For an optimized presentation build, add `DEMO_TOUCHES` to that build's Swift active
compilation conditions. `-ShowTouches` optionally enables it at launch. UI tests and
SwiftUI previews always disable visualization without overwriting the saved choice.

Only touches dispatched to this app window are observable. Home Screen, Control
Center, other apps, system-owned keyboards, and other system windows are outside
this module's coverage. The overlay does not record touch coordinates or input.

This module does not implement mirroring. Its visible content can be included in
normal screen mirroring or recording; actual device and projection verification is
still required before a live presentation.
