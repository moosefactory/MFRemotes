/*--------------------------------------------------------------------------*/
/*   /\/\/\__/\/\/\        MFRemotes                                        */
/*   \/\/\/..\/\/\/                                                         */
/*        |  |             Easy peer to peer connection framework           */
/*        (oo)                                                              */
/* MooseFactory Software                                                    */
/*--------------------------------------------------------------------------*/

import Network

// Exposed types

public typealias MFRemotesServer = MFRemotes.MFRemotesServer
public typealias MFRemotesSessionServerBrowserResult = NWBrowser.Result
public typealias MFRemotesServiceInfo = MFRemotes.ServiceInfo
public typealias RemotesSessionManager = MFRemotes.RemotesSessionManager

// Library Core

public class MFRemotes {
    
    public static let version = "1.0"
    public static let name = "MFRemotes"
    
    public struct ServiceInfo {
        public init(name: String, type: String, version: String) {
            self.name = name
            self.type = type
            self.version = version
        }
        
        let name: String
        let type: String
        let version: String
    }
}
