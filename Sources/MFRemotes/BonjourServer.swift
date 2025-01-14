//   /\/\__/\/\      MFRemotes
//   \/\/..\/\/      Peer to peer connection framework
//      (oo)
//  MooseFactory
//    Software       ©2024 - Tristan Leblanc
//  --------------------------------------------------

//  BonjourServer.swift
//  Created by Tristan Leblanc on 29/08/2024.

import Foundation
import Network
import Combine

public extension MFRemotes {
    
    /// BonjourServer
    ///
    /// The BonjourServer object is responsible of running a peer to peer bonjour session.
    ///
    /// Once started, it monitors the connections to multiple peers.
    ///
    /// - The 'connectionAdded' block is called when a new device connects to the network
    /// - The 'didReceiveData' block is called when data are receved from a device
    ///
    /// Properties:
    ///
    /// Objects:
    /// - listener : The object responsible of monitoring the session state
    ///
    /// Assignable callbacks to customize behavior
    /// - connectionAdded : called when a new connection is added to the pool
    /// - didReceiveData : called when data are received from a connection
    
    class BonjourServer {
        
        // Service info
        
        let serviceInfo: ServiceInfo
        
        // The endpoint name ( host name )
        // set when server is started and service registered
        public private(set) var name: String?
        
        /// The listener is notified whenever a connection receive a status change, or data
        var listener: NWListener? = nil
        
        /// The list of connections
        ///
        /// Connections are private to the server
        private var connections = [NWConnection]()
        
        // MARK: - Callback closures
        
        public var connectionAdded: ((NWConnection)->Void)
        public var didReceiveData: (Data, NWConnection)->Void
        public var didCancel: ((Error?, NWConnection)->Void)
        
        // MARK: - Initialise
        
        
        /// Initialise a bonjour server with useful hooks:
        /// - connectionAdded
        /// - didReceiveData
        /// - didCancel
        public init(serviceInfo: ServiceInfo,
                    didReceiveData: @escaping (Data, NWConnection)->Void,
                    connectionAdded: @escaping ((NWConnection)->Void),
                    didCancel: @escaping ((Error?, NWConnection)->Void)) {
            self.didReceiveData = didReceiveData
            self.didCancel = didCancel
            self.connectionAdded = connectionAdded
            self.serviceInfo = serviceInfo
        }
        
        // MARK: - Server Start/Stop
        
        /// Starts the bonjour server
        ///
        /// The listener is created and set to the 'listener' property.
        /// The function starts and returns the newly created listener.
        
        @discardableResult
        public func start(_ ready: @escaping ()->Void) throws -> NWListener {
            let tcpOptions = NWProtocolTCP.Options()
            tcpOptions.enableKeepalive = true
            tcpOptions.keepaliveIdle = 2
            
            let parameters = NWParameters(tls: nil, tcp: tcpOptions)
            parameters.includePeerToPeer = true
            
            let listener = try NWListener(using: parameters)
            
            listener.service = NWListener.Service(name: serviceInfo.name, type: serviceInfo.type)
            
            let server = self
            listener.stateUpdateHandler = { newState in
                switch newState {
                case.ready:
                    server.startReceivingMessages()
                    break
                default:
                    break
                }
            }
            
            listener.newConnectionHandler = { connection in
                if connection.endpoint.interface?.name == self.name {
                    return
                }
                self.connections.append(connection)
                self.startReceivingMessages(from: connection)
                
                self.connectionAdded(connection)
            }
            
            listener.service = .init(type: "_ssh._tcp")
            
            listener.serviceRegistrationUpdateHandler = { change in
                switch change {
                case .add(let endpoint):
                    print("serviceRegistrationUpdateHandler Added \(endpoint)")
                    self.name = String(endpoint.debugDescription.split(separator: ".").first ?? ".")
                    ready()
                case .remove(let endpoint):
                    if  self.name == endpoint.interface?.name {
                        self.name = nil
                    }
                    print("serviceRegistrationUpdateHandler Removed \(endpoint)")
                @unknown default:
                    break
                }
            }
            
            self.listener = listener
            self.listener?.start(queue: .main)
            
            return listener
        }
        
        /// Stop the server
        
        public func stop() {
            listener?.stateUpdateHandler = nil
            listener?.cancel()
            listener = nil
        }
        
        // MARK: - Listen to messages
        
        /// Starts to receive message from all connections
        
        func startReceivingMessages() {
            connections.forEach { connection in
                self.startReceivingMessages(from: connection)
            }
        }
        
        /// Starts to receive message from a specific connection
        ///
        /// This function is called as soon as a new connection is etablished
        
        func startReceivingMessages(from connection: NWConnection) {
            if connection.state != .ready {
                connection.start(queue: DispatchQueue.global())
            }
            
            connection.receive(minimumIncompleteLength: 1,
                               maximumLength: 10000) { data, contentContext , isComplete, error in
                
                switch connection.state {
                case .ready:
                    break
                default:
                    return
                }
                if let error = error {
                    connection.cancel()
                    self.didCancel(error, connection)
                    return
                }
                if let data = data {
                    self.didReceiveData(data, connection)
                }
                
                // Start listening for the next message
                self.startReceivingMessages(from: connection)
            }
        }
        
        private func send(data: Data, to connection: NWConnection) {
            
            if connection.state != .ready {
                connection.start(queue: DispatchQueue.global())
            }
            
            connection.send(content: data, isComplete: true, completion: .contentProcessed({ error in
                if error != nil {
                    return
                }
            }))
        }
    }
    
}
