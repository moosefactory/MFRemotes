/*--------------------------------------------------------------------------*/
/*   /\/\/\__/\/\/\        MFRemotes                                        */
/*   \/\/\/..\/\/\/                                                         */
/*        |  |             Easy peer to peer connection framework           */
/*        (oo)                                                              */
/* MooseFactory Software                                                    */
/*--------------------------------------------------------------------------*/
//  RemoteInterface.swift
//  Created by Tristan Leblanc on 27/12/2024.

import Foundation
import Network

/// RemoteInterface is responsible of managing a valid connection to a device.
/// It keeps track of the last error

public class RemoteInterface: Identifiable {
    
    public let uuid = UUID()
    
    public init(connection: NWConnection) {
        self.connection = connection
    }
    
    /// The connection to the RemotesServer
    var connection: NWConnection
    
    var lastError: Error? = nil
    
    func send(data: Data) {
        send(data: data, to: connection)
    }
    
    private func send(data: Data, to connection: NWConnection) {
        
        if connection.state != .ready {
            connection.start(queue: DispatchQueue.global())
        }
        
        connection.send(content: data, isComplete: true, completion: .contentProcessed({ error in
            if let error = error {
                DispatchQueue.main.async {
                    self.lastError = error
                }
                return
            }
        }))
    }
}
