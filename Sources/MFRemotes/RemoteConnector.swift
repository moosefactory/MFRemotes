/*--------------------------------------------------------------------------*/
/*   /\/\/\__/\/\/\        MFRemotes                                        */
/*   \/\/\/..\/\/\/                                                         */
/*        |  |             Easy peer to peer connection framework           */
/*        (oo)                                                              */
/* MooseFactory Software                                                    */
/*--------------------------------------------------------------------------*/
//  RemoteConnector.swift
//  Created by Tristan Leblanc on 29/08/2024.

import Foundation
import Network

public class RemoteConnector {
    
    var name: String = "Remote"
    
    /// Called whenever data are sent
    var stateChanged: ((State)->Void)?
    
    var api: MFRemotesAPIProtocol
    
    public  var calibrating: Bool = false
    
    public struct State {
        enum Sequence {
            case waiting
            case ready
            case cancelled
        }
        var isSendingData: Bool = false
        var sequence: Sequence = .waiting
        var error: Error? = nil
    }
    
    public var state = State() { didSet {
        stateChanged?(state)
    }}

    // connection to the remote is set on init
    // and is etablished with the server selected in the network browser
    private var connection: NWConnection
    
    // MARK: - Initializer
    
    /// Inits a RemoteConnector instance from a Network Browser result
    public init(item: NWBrowser.Result,
                api: MFRemotesAPIProtocol,
                stateChanged: @escaping (State)->Void) {
        
        let connection = NWConnection(to: item.endpoint,
                                      using: Network.NWParameters.tcp)
        self.connection = connection
        self.api = api
        connection.parameters.includePeerToPeer = true
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .waiting(let error):
                self.state.sequence = .waiting
                self.state.error = error
            case .failed(let error):
                self.state.sequence = .cancelled
                self.state.error = error
            case .ready:
                self.state.sequence = .ready
                self.state.error = nil

                self.startReceiving()
            default:
                print("Connection state updated: \(state)")
            }
        }
        
        connection.start(queue: .main)
        
    }

    public func shutDown() {
        
    }
    
    /// Sends data to the connection

    public func send(_ data: Data) {
        state.isSendingData = true
        let completion: NWConnection.SendCompletion = .contentProcessed { [weak self] error in
            self?.state.isSendingData = false
        }
        connection.send(content: data, completion: completion)
    }
    
    /// Starts listening to data on connection
    ///
    /// Listening to server is used to configure remote, set up an initial state,
    /// send visual feedbacks
    
    public func startReceiving() {
        connection.receiveMessage { content, contentContext, isComplete, error in
            self.didReceiveMessage(from: self.connection, content, contentContext, isComplete, error)
            if error == error {
                return
            }
            self.startReceiving()
        }
    }
    
    /// Called when data has been received from connection
    
    func didReceiveMessage(from connection: NWConnection,
                           _ content: Data?,
                           _ contentContext: NWConnection.ContentContext?,
                           _ isComplete: Bool,
                            _ error: Error?) {
        if let error = error {
            dump(error)
            return
        }
        
        guard let content else {
            print("isFinal", contentContext?.isFinal == true)
            print("isComplete", isComplete)
            return
        }
        let data = content
        api.dataHandler(data)
    }

}
