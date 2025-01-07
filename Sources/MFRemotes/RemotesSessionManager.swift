/*--------------------------------------------------------------------------*/
/*   /\/\/\__/\/\/\        MFRemotes                                        */
/*   \/\/\/..\/\/\/                                                         */
/*        |  |             Easy peer to peer connection framework           */
/*        (oo)                                                              */
/* MooseFactory Software                                                    */
/*--------------------------------------------------------------------------*/
//  RemotesSessionManager.swift
//  Created by Tristan Leblanc on 27/12/2024.

import Foundation
import Network
import Combine

public extension MFRemotes {
    
    /// Responsible of managing either
    ///
    /// - a remotes session server ( server property set )
    ///     - run a bonjour server
    ///     - manage connections with remotes,
    /// - a remote connection ( remote property set )
    ///     - run a bonjour server
    ///     - manage connections with remotes,
    
    class RemotesSessionManager {
        
        // TODO: move in interface
        var api: MFRemotesAPIProtocol
        var serviceInfo: ServiceInfo
        
        public init(serviceInfo: ServiceInfo, api: any MFRemotesAPIProtocol) {
            self.api = api
            self.serviceInfo = serviceInfo
        }
        
        public var isServer: Bool { return server != nil }
        public var isRemote: Bool { return remote != nil }
        
        // If set, this game instance acts as a remote controller
        public var remote: RemoteConnector?
        
        // If set, this game instance is running the remotes server
        public var server : MFRemotesServer?
        
        // MARK: Browse for available servers
        
        private lazy var networkBrowser: NetworkBrowser = {
            let networkBrowser = NetworkBrowser()
            return networkBrowser
        }()
        
        private var clientListener: AnyCancellable?
        
        @Published public var discoveredServers: [NWBrowser.Result]?
        
        // MARK: Remotes Session
        
        public func startRemotesSession() {
            stopRemoteSession()
            if server == nil {
                server = MFRemotesServer(serviceInfo: serviceInfo, api: api)
            }
            server?.start()
        }
        
        public func stopRemoteSession() {
            guard let remote = remote else { return }
            remote.shutDown()
        }
        
        public func discoverRemotes() {
            networkBrowser.start()
            
            clientListener = networkBrowser.$browseResults.sink(receiveValue: { [weak self] results in
                self?.discoveredServers = results
            })
        }
        
        public func stopDiscoverRemotes() {
            networkBrowser.stop()
            clientListener?.cancel()
        }
        
        // MARK: Remote
        
        // TODO: Server selector
        public func startRemote(api: MFRemotesAPIProtocol) {
            if let server = self.discoveredServers?.first  {
                let remote = RemoteConnector(item: server,
                                             api: api) { state in
                    print("Remote State Changed : \(state)")
                }
                self.remote = remote
            }
        }
    }
}
