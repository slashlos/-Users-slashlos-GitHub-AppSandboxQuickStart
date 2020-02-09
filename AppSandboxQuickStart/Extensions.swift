//
//  Extensions.swift
//  AppSandboxQuickStart
//
//  Created by Carlos D. Santiago on 2/8/20.
//  Copyright © 2020 Carlos D. Santiago. All rights reserved.
//

import AppKit
import Foundation

class DocumentController : NSDocumentController {
    override func makeDocument(for urlOrNil: URL?, withContentsOf contentsURL: URL, ofType typeName: String) throws -> Document {
        var doc: Document
        do {
			doc = try Document.init(contentsOf: contentsURL, ofType: typeName)
            doc.showWindows()
        } catch let error {
            NSApp.presentError(error)
			doc = try Document.init(type: contentsURL.absoluteString)
        }
        
        return doc
    }

    override func makeDocument(withContentsOf url: URL, ofType typeName: String) throws -> Document {
        var doc: Document
        do {
            doc = try self.makeDocument(for: url, withContentsOf: url, ofType: typeName)
        } catch let error {
            NSApp.presentError(error)
            doc = Document.init()
        }
        return doc
    }
}

extension NSURL {
    
    func compare(_ other: URL ) -> ComparisonResult {
        return (self.absoluteString?.compare(other.absoluteString))!
    }
	
//  https://stackoverflow.com/a/44908669/564870
    func resolvedFinderAlias() -> URL? {
        if (self.fileReferenceURL() != nil) { // item exists
            do {
                // Get information about the file alias.
                // If the file is not an alias files, an exception is thrown
                // and execution continues in the catch clause.
                let data = try NSURL.bookmarkData(withContentsOf: self as URL)
                // NSURLPathKey contains the target path.
                let rv = NSURL.resourceValues(forKeys: [ URLResourceKey.pathKey ], fromBookmarkData: data)
                var urlString = rv![URLResourceKey.pathKey] as! String
                if !urlString.hasPrefix("file://") { urlString = "file://" + urlString }
                return URL(string: urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!)!
            } catch {
                // We know that the input path exists, but treating it as an alias
                // file failed, so we assume it's not an alias file so return nil.
                return nil
            }
        }
        return nil
    }
}
