//
//  AppDelegate.swift
//  AppSandboxQuickStart
//
//  Created by Carlos D. Santiago on 2/8/20.
//  Copyright © 2020 Carlos D. Santiago. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var dc : NSDocumentController {
        get {
            return NSDocumentController.shared
        }
    }
	var homeURL : URL {
		get {
			return URL.init(string: "http://www.apple.com")!
		}
	}
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
        //  Load sandbox bookmark url when necessary
        if self.isSandboxed() != self.loadBookmarks() {
			Swift.print("Yoink, unable to load bookmarks")
        }
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
        //  Save sandbox bookmark urls when necessary
        if isSandboxed() != saveBookmarks() {
            Swift.print("Yoink, unable to save booksmarks")
        }
		
		_ = DocumentController.shared
	}
	
    func userAlertMessage(_ message: String, info: String?) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        if info != nil {
            alert.informativeText = info!
        }
        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window, completionHandler: { response in
                return
            })
        }
        else
        {
            alert.runModal()
            return
        }
    }

    // MARK: Application Events
    dynamic var disableDocumentReOpening = false

    func openURLInNewWindow(_ newURL: URL, attachTo parentWindow: NSWindow? = nil) -> Bool {
		if newURL.isFileURL, isSandboxed() != storeBookmark(url: newURL) {
			Swift.print("Yoink, unable to sandbox \(newURL)")
			return false
		}
		
		do {
			let doc = try Document.init(newURL)
			
			guard let wc = doc.windowControllers.first else { return false }
			
			guard let window = wc.window, let cvc = window.contentViewController,
				let webView = (cvc as? ViewController)?.webView else { return false }

			if false && newURL.isFileURL {
				let baseURL = newURL.deletingPathExtension()
				if isSandboxed() != storeBookmark(url: baseURL) {
					Swift.print("Yoink, unable to sandbox \(baseURL)")
					return false
				}

				webView.loadFileURL(newURL, allowingReadAccessTo: baseURL)
			}
			else
			{
				webView.load(URLRequest.init(url: newURL))
			}
			if let parent = parentWindow {
				parent.addTabbedWindow(window, ordered: .above)
			}
			doc.showWindows()
			
			return true
			
        } catch let error {
            NSApp.presentError(error)
			return false
        }
    }
	
    func application(_ application: NSApplication, open urls: [URL]) {
        
        for url in urls {
            
            if !openURLInNewWindow( url) {
                print("Yoink unable to open \(url)")
            }
        }
    }

	// MARK:- Sandbox Support
	var bookmarks = [URL: Data]()

	func isSandboxed() -> Bool {
		let bundleURL = Bundle.main.bundleURL
		var staticCode:SecStaticCode?
		var isSandboxed:Bool = false
		let kSecCSDefaultFlags:SecCSFlags = SecCSFlags(rawValue: SecCSFlags.RawValue(0))
		
		if SecStaticCodeCreateWithPath(bundleURL as CFURL, kSecCSDefaultFlags, &staticCode) == errSecSuccess {
			if SecStaticCodeCheckValidityWithErrors(staticCode!, SecCSFlags(rawValue: kSecCSBasicValidateOnly), nil, nil) == errSecSuccess {
				let appSandbox = "entitlement[\"com.apple.security.app-sandbox\"] exists"
				var sandboxRequirement:SecRequirement?
				
				if SecRequirementCreateWithString(appSandbox as CFString, kSecCSDefaultFlags, &sandboxRequirement) == errSecSuccess {
					let codeCheckResult:OSStatus  = SecStaticCodeCheckValidityWithErrors(staticCode!, SecCSFlags(rawValue: kSecCSBasicValidateOnly), sandboxRequirement, nil)
					if (codeCheckResult == errSecSuccess) {
						isSandboxed = true
					}
				}
			}
		}
		return isSandboxed
	}
	
	func bookmarkPath() -> String?
	{
		if var documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
			documentsPathURL = documentsPathURL.appendingPathComponent("Bookmarks.dict")
			return documentsPathURL.path
		}
		else
		{
			return nil
		}
	}
	
	func loadBookmarks() -> Bool
	{
		//  Ignore loading unless configured
		guard isSandboxed() else { return false }

		let fm = FileManager.default
		
		guard let path = bookmarkPath(), fm.fileExists(atPath: path) else {
			return saveBookmarks()
		}
		
		var restored = 0
		bookmarks = NSKeyedUnarchiver.unarchiveObject(withFile: path) as! [URL: Data]
		var iterator = bookmarks.makeIterator()

		while let bookmark = iterator.next()
		{
			//  stale bookmarks get dropped
			if !fetchBookmark(bookmark) {
				bookmarks.removeValue(forKey: bookmark.key)
			}
			else
			{
				restored += 1
			}
		}
		return restored == bookmarks.count
	}
	
	func saveBookmarks() -> Bool
	{
		//  Ignore saving unless configured
		guard isSandboxed() else
		{
			return false
		}

		if let path = bookmarkPath() {
			return NSKeyedArchiver.archiveRootObject(bookmarks, toFile: path)
		}
		else
		{
			return false
		}
	}
	
	func storeBookmark(url: URL, options: URL.BookmarkCreationOptions = [.withSecurityScope,.securityScopeAllowOnlyReadAccess]) -> Bool
	{
		guard isSandboxed() else { return false }
		
		//  Peek to see if we've seen this key before
		if let data = bookmarks[url] {
			if self.fetchBookmark((key: url, value: data)) {
                Swift.print ("= \(url.absoluteString)")
				return true
			}
		}
		do
		{
			let data = try url.bookmarkData(options: options, includingResourceValuesForKeys: nil, relativeTo: nil)
			bookmarks[url] = data
			return self.fetchBookmark((key: url, value: data))
		}
		catch let error
		{
			NSApp.presentError(error)
			Swift.print ("Error storing bookmark: \(url)")
			return false
		}
	}
	
	func findBookmark(_ url: URL) -> Data? {
		if let data = bookmarks[url] {
			if self.fetchBookmark((key: url, value: data)) {
				return data
			}
		}
		return nil
	}

	func fetchBookmark(_ bookmark: (key: URL, value: Data)) -> Bool
	{
		let restoredUrl: URL?
		var isStale = true
		
		do
		{
			restoredUrl = try URL.init(resolvingBookmarkData: bookmark.value, options: URL.BookmarkResolutionOptions.withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
		}
		catch let error
		{
			Swift.print("! \(bookmark.key) \n\(error.localizedDescription)")
			return false
		}
		
		guard let url = restoredUrl else {
			Swift.print ("? \(bookmark.key)")
			return false
		}
		
		if isStale {
			Swift.print ("≠ \(bookmark.key)")
			return false
		}
		
		let fetch = url.startAccessingSecurityScopedResource()
        Swift.print ("\(fetch ? "+" : "-") \(bookmark.key)")
		return fetch
	}
}

