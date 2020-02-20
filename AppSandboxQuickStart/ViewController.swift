//
//  ViewController.swift
//  AppSandboxQuickStart
//
//  Created by Carlos D. Santiago on 2/8/20.
//  Copyright © 2020 Carlos D. Santiago. All rights reserved.
//

import Cocoa
import WebKit

class MyWebView : WKWebView {
	var appDelegate : AppDelegate {
		get {
			return (NSApp.delegate as! AppDelegate)
		}
	}
	
    var acceptableTypes: Set<NSPasteboard.PasteboardType> { return [.URL, .fileURL, .html, .pdf, .png, .rtf, .rtfd, .tiff] }
    var filteringOptions = [NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes:NSImage.imageTypes]
	
	// MARK: Drag and Drop - Before Release
	func shouldAllowDrag(_ info: NSDraggingInfo) -> Bool {
		let pboard = info.draggingPasteboard
		let items = pboard.pasteboardItems!
		var canAccept = false
		
		let readableClasses = [NSURL.self, NSString.self, NSAttributedString.self, NSPasteboardItem.self]
		
		if pboard.canReadObject(forClasses: readableClasses, options: nil) {
			canAccept = true
		}
		else
		{
			for item in items {
				Swift.print("item: \(item)")
			}
		}
		Swift.print("web shouldAllowDrag -> \(canAccept) \(items.count) item(s)")
		return canAccept
	}
	
	override func draggingEntered(_ info: NSDraggingInfo) -> NSDragOperation {
		let pboard = info.draggingPasteboard
		let items = pboard.pasteboardItems!
		let allow = shouldAllowDrag(info)
		
		let dragOperation = allow ? .copy : NSDragOperation()
		Swift.print("web draggingEntered -> \(dragOperation) \(items.count) item(s)")
		return dragOperation
	}
	
	override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
		let allow = shouldAllowDrag(sender)
		sender.animatesToDestination = true
		Swift.print("web prepareForDragOperation -> \(allow)")
		return allow
	}
	
	override func draggingExited(_ sender: NSDraggingInfo?) {
		Swift.print("web draggingExited")
	}
	
	var lastDragSequence : Int = 0
	override func draggingUpdated(_ info: NSDraggingInfo) -> NSDragOperation {
		let sequence = info.draggingSequenceNumber
		if sequence != lastDragSequence {
			Swift.print("web draggingUpdated -> .copy")
			lastDragSequence = sequence
		}
		return .copy
	}
	
	// MARK: Drag and Drop - After Release
	override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
		let isSandboxed = appDelegate.isSandboxed()
        let pboard = sender.draggingPasteboard
        let items = pboard.pasteboardItems
		let window = self.window
        var handled = 0

        for item in items! {
            if handled == items!.count { break }

			for type in pboard.types! {
				Swift.print("web type: \(type)")

				switch type {
					
				case .URL, .fileURL:

					if let urlString = item.string(forType: type), let url = URL.init(string: urlString) {
						
						if url.isFileURL {
							handled += (appDelegate.openURLInNewWindow(url, attachTo: window) ? 1 : 0)
						}
						else
						{
							if url.isFileURL {
								var baseURL = url

								if isSandboxed != appDelegate.storeBookmark(url: url) {
									Swift.print("Yoink, unable to sandbox file \(url)")
									continue
								}
							
								if isSandboxed, url.hasHTMLContent() {
									baseURL = appDelegate.authenticateBaseURL(url)
								}

								///webView.load(URLRequest.init(url: url))
								loadFileURL(url, allowingReadAccessTo: baseURL)
							}
							else
							{
								load(URLRequest.init(url: url))
							}

							if let cvc : ViewController = window?.contentViewController as? ViewController {
								cvc.representedObject = url
							}
							handled += 1
						}
					}
					break
					
				default:
					Swift.print("unkn: \(type)")

					if let data = item.data(forType: type) {
						Swift.print("data: \(data.count) bytes")
					}
				}
				if handled == items?.count { break }
			}
		}
				
		Swift.print("web performDragOperation -> \(handled == items?.count ? "true" : "false")")
		return handled == items?.count
	}
}

class ViewController: NSViewController {
	var appDelegate : AppDelegate {
		get {
			return (NSApp.delegate as! AppDelegate)
		}
	}
	@IBOutlet weak var webView: MyWebView!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		if let appleURL = URL.init(string: "http://www.apple.com") {
			self.webView.load(URLRequest.init(url: appleURL))
		}
		
        //  Intercept drags
        webView.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0)})
        webView.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
		webView.registerForDraggedTypes(Array(self.webView.acceptableTypes))
	}

	override var representedObject: Any? {
		didSet {
			// Update the view, if already loaded.
			self.view.window?.windowController?.synchronizeWindowTitleWithDocumentName()
		}
	}
	
	// MARK:- Navigation Delegate
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(error)
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleError(error)
    }
    fileprivate func handleError(_ error: Error) {
        let message = error.localizedDescription
        Swift.print("didFail?: \((error as NSError).code): \(message)")
        if (error as NSError).code >= 400 {
            NSApp.presentError(error)
        }
        else
        if (error as NSError).code < 0 {
            if let info = error._userInfo as? [String: Any] {
                if let url = info["NSErrorFailingURLKey"] as? URL {
                    appDelegate.userAlertMessage(message, info: url.absoluteString)
                }
                else
                if let urlString = info["NSErrorFailingURLStringKey"] as? String {
                    appDelegate.userAlertMessage(message, info: urlString)
                }
            }
        }
    }

}

