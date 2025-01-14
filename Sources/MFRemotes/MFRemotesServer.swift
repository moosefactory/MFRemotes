//   /\/\__/\/\      MFRemotes
//   \/\/..\/\/      Peer to peer connection framework
//      (oo)
//  MooseFactory
//    Software       ©2024 - Tristan Leblanc
//  --------------------------------------------------
//  MFRemoteServer.swift
//  Created by Tristan Leblanc on 27/12/2024.

import Foundation
import Network
import Combine

public extension MFRemotes {
    
    /// MFSessionServer is responsible of running a peer to peer session.
    ///
    /// It keeps track of the running status, the session name
    
    class MFRemotesServer {
        
        @Published public var sessionHostName: String?
        @Published public var running:Bool = false
        
        @Published public private(set) var remoteInterfaces: [RemoteInterface] = []
        
        var serviceInfo: ServiceInfo
        
        // TODO: move in interface
        
        var api: MFRemotesAPIProtocol
        
        private var bonjourServer: BonjourServer?
        
        public init(serviceInfo: ServiceInfo, api: any MFRemotesAPIProtocol) {
            self.serviceInfo = serviceInfo
            self.api = api
        }
        
        private func newServer() -> BonjourServer {
            BonjourServer(serviceInfo: serviceInfo) { [weak self] data, connection in
                DispatchQueue.main.async {
                    self?.received(data: data)
                }
            } connectionAdded: { [weak self] connection in
                self?.remoteDidConnect(connection)
            } didCancel: { [weak self] error,connection in
                self?.remoteDidCancel(connection, error: error)
            }
        }
        
        @discardableResult
        func makeRemoteInterface(with connection: NWConnection) -> RemoteInterface {
            let interface = RemoteInterface(connection: connection)
            remoteInterfaces.append(interface)
            return interface
        }
        
        /// Start the bonjour server
        ///
        /// The server handle connections request, and starts listening to clients connections
        
        public func start() {
            if bonjourServer == nil {
                bonjourServer = newServer()
            }
            guard let server = bonjourServer else {
                handleError()
                return
            }
            do {
                try server.start() {
                    self.sessionHostName = server.name ?? "?"
                    self.running = true
                }
            }
            catch {
                handleError(error)
            }
        }
        
        func handleError(_ error: Error? = nil) {
            print(error?.localizedDescription ?? "Server instance not set")
        }
        
        func stop() {
            bonjourServer?.stop()
            running = false
        }
        
        private func remoteDidConnect(_ connection: NWConnection) {
            makeRemoteInterface(with: connection)
        }
        
        private func remoteDidCancel(_ connection: NWConnection, error: Error?) {
            remoteInterfaces.removeAll { remote in
                remote.connection === connection
            }
        }
        
        @MainActor func received(data: Data) {
            api.dataHandler(data)
        }
    }
}
