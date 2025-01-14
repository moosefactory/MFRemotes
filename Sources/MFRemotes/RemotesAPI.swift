//   /\/\__/\/\      MFRemotes
//   \/\/..\/\/      Peer to peer connection framework
//      (oo)
//  MooseFactory
//    Software       ©2024 - Tristan Leblanc
//  --------------------------------------------------
//  MFRemotesAPIProtocol.swift
//  Created by Tristan Leblanc on 30/08/2024.

import Foundation

/// RemotesAPI Protocol

public protocol MFRemotesAPIProtocol {
    
    func prepareRemoteConfigurationData() -> Data?
    
    var dataHandler: ((Data) -> Void) { get }
}
