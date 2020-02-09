# AppSandboxQuickStart
A Swift5 start to Apple's Sandbox support supporting documents

This skeleton document implementation I used to test WKWebView, and its current limitations re: local html resource loading.

Currently, WkWebView `file://` based URL loads rely on request loads, due to current issues with `loadFileURL(_ url URL:, allowingReadAccessTo: readAccessURL: URL)`.

It features an app delegate stub which will restore, and creates sandbox bookmarks, and save, open or drag-n-drop file URLs accessed.

Initially, starth with Sandbox OFF, then stop, clean, and toggle to ON and compare differences.

Hopefully this work can get you jump started.
