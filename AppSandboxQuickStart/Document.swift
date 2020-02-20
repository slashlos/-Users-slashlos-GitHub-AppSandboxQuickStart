//
//  Document.swift
//  AppSandboxQuickStart
//
//  Created by Carlos D. Santiago on 2/8/20.
//  Copyright © 2020 Carlos D. Santiago. All rights reserved.
//

import Cocoa

class Document: NSDocument {
	var appDelegate : AppDelegate {
		get {
			return (NSApp.delegate as! AppDelegate)
		}
	}

	convenience init(_ url: URL) throws {
	    self.init()
		
		// Add your subclass-specific initialization here.
		fileURL = url
	}

	override class var autosavesInPlace: Bool {
		return true
	}

	override func makeWindowControllers() {
		// Returns the Storyboard that contains your Document window.
		let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
		let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
		let isSandboxed = appDelegate.isSandboxed()

		if let url = fileURL, let window = windowController.window, let cvc : ViewController = window.contentViewController as? ViewController {
			if url.isFileURL {
				var baseURL = url
				
				if appDelegate.isSandboxed() != appDelegate.storeBookmark(url: url) {
					Swift.print("Yoink, unable to sandbox file \(url)")
				}
				if isSandboxed, url.hasHTMLContent() {
					baseURL = appDelegate.authenticateBaseURL(url)
				}
				cvc.webView.loadFileURL(url, allowingReadAccessTo: baseURL)
			}
			else
			{
				cvc.webView.load(URLRequest.init(url: url))
			}
			cvc.representedObject = url
		}
		self.addWindowController(windowController)
		appDelegate.dc.addDocument(self)
	}

	override func data(ofType typeName: String) throws -> Data {
		// Insert code here to write your document to data of the specified type, throwing an error in case of failure.
		// Alternatively, you could remove this method and override fileWrapper(ofType:), write(to:ofType:), or write(to:ofType:for:originalContentsURL:) instead.
		throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
	}
	override func write(to url: URL, ofType typeName: String) throws {
		throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
	}

	override func read(from data: Data, ofType typeName: String) throws {
		// Insert code here to read your document from the given data of the specified type, throwing an error in case of failure.
		// Alternatively, you could remove this method and override read(from:ofType:) instead.
		// If you do, you should also override isEntireFileLoaded to return false if the contents are lazily loaded.
		throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
	}
	
	override func read(from url: URL, ofType typeName: String) throws {
		switch typeName {
		case "AnyType":
			fileURL = url
			break
		default:
			throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		}
	}

	convenience init(contentsOf url: URL, ofType typeName: String) throws {
		switch typeName {
		case "AnyType":
			try self.init(url)
			break
		default:
			throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		}
	}
}

