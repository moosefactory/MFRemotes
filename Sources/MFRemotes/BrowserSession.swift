//   /\/\__/\/\      MFRemotes
//   \/\/..\/\/      Peer to peer connection framework
//      (oo)
//  MooseFactory
//    Software       ©2024 - Tristan Leblanc
//  --------------------------------------------------
//  NetworkBrowser
//  Created by Tristan Leblanc on 29/08/2024.

import Foundation
import Network
import Combine

/// NetworkBrowser object is responsible of sniffing the bonjour servers around
///
public class BrowserSession {

    // The underlying NWBrowser instance
    var networkBrowser: NWBrowser? = nil
    
    @Published public var browseResults = [NWBrowser.Result]()

    // The browse results
    // An array of NWBrowser.Result, consisting of endpoints and some associated data
    @Published public var state = [NWBrowser.Result]()
    
    public init() {}
    
    /// MARK: - Start/Stop
    
    /// Start the browsing session
    
    @discardableResult
    public func start() -> NWBrowser {
        let descriptor = NWBrowser.Descriptor.bonjour(type: "_ssh._tcp", domain: "local.")
        let browser = NWBrowser(for: descriptor, using: .tcp)
        
        browser.stateUpdateHandler = { newState in
            print("Browser stateUpdateHandler \(newState)")
        }
        
        browser.browseResultsChangedHandler = { updated, changes in
            for change in changes {
                switch change {
                case .added(let result):
                    if !self.browseResults.contains(result) {
                        self.browseResults.append(result)
                    }
                case .removed(let result):
                    if let index = self.browseResults.firstIndex(of: result) {
                        self.browseResults.remove(at: index)
                    }
                case .changed(old: let old, new: let new, flags: _):
                    let results = self.browseResults.map {
                        $0 == old ? new : $0
                    }
                    self.browseResults = results
                case .identical:
                    break
                @unknown default:
                    break
                }
            }
        }
        browser.start(queue: .main)
        return browser
    }
    
    /// Stop the browsing session
    ///
    /// Once connected, the browser can be stopped
    
    public func stop() {
        guard let networkBrowser = networkBrowser else { return }
        networkBrowser.stateUpdateHandler = nil
        networkBrowser.cancel()
    }
}
