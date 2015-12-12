//
//  LongPollingRequest.swift
//  LongPollingRequest
//
//  Created by Le Tai on 12/8/15.
//  Copyright © 2015 levantAJ. All rights reserved.
//

import Alamofire

public typealias LongPollingCallback = (data: AnyObject?, error: NSError?, index: Int, next: (()->Void))->Void

public class LongPollingRequest {
    
    var offset = 0
    var isPolling = false
    var queueURLStrings = [String]()
    var queueParameters = [[String: AnyObject]?]()
    var queueCallback = [LongPollingCallback]()
    var requests = [Request]()
    var manager: Manager!
    var implementation: ((urlString: String, params: [String:AnyObject]?, callback: LongPollingCallback, index:Int) -> Request)!
    
    public var timeoutIntervalForRequest = NSTimeInterval(30)
    public var httpMaximumConnectionsPerHost = 100
    
    public init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        configuration.timeoutIntervalForRequest = timeoutIntervalForRequest
        configuration.HTTPMaximumConnectionsPerHost = httpMaximumConnectionsPerHost
        manager = Manager(configuration: configuration)
        implementation = { (urlString: String, params:[String:AnyObject]?, callback: LongPollingCallback, index:Int) -> Request in
            return self.manager.request(.POST, urlString + "?offset=\(self.offset)", parameters: params)
                .responseJSON { (_, _, result) in
                    switch result {
                    case .Success(let json):
                        callback(data: json, error: nil, index: index, next: { () -> Void in
                            if self.isPolling {
                                self.requests[index] = self.implementation(urlString: urlString, params: params, callback: callback, index: index)
                            }
                        })
                    case .Failure(_, let error as NSError):
                        callback(data: nil, error: error, index: index, next: { () -> Void in
                            if self.isPolling {
                                self.requests[index] = self.implementation(urlString: urlString, params: params, callback: callback, index: index)
                            }
                        })
                    default:
                        return
                    }
            }
        }
    }
    
    public func poll(urlString: String, params: [String: AnyObject]?, callback: LongPollingCallback) {
        queueURLStrings.append(urlString)
        queueParameters.append(params)
        queueCallback.append(callback)
        if isPolling {
            requests.append(implementation(urlString: urlString, params: params, callback: callback, index: queueURLStrings.count))
        }
    }
    
    public func start() {
        if !isPolling {
            isPolling = true
            for (index, url) in queueURLStrings.enumerate() {
                requests.append(implementation(urlString: url, params: queueParameters[index], callback: queueCallback[index], index: index))
            }
        }
    }
    
    public func stop() {
        for request in requests {
            request.cancel()
        }
        requests = []
        isPolling = false
    }
    
    public func clear() {
        queueURLStrings = []
        queueParameters = []
        queueCallback = []
    }

}
