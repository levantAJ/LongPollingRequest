//
//  LongPollingRequest.swift
//  LongPollingRequest
//
//  Created by Le Tai on 12/8/15.
//  Copyright © 2015 levantAJ. All rights reserved.
//

import Alamofire

public typealias LongPollingCallback = (data: AnyObject, error: NSError?, index: Int, next: (()->Void))->Void

public class LongPollingRequest {
    
    var offset = 0
    var isPolling = false
    var queueURL = [String]()
    var queueParameters = [[String: AnyObject]?]()
    var queueCallback = [LongPollingCallback]()
    var requests = [Request]()
    var mgr: Manager!
    var implementation: ((url: String, params: [String:AnyObject]?, callback: LongPollingCallback, index:Int) -> Request)!
    
    init() {
        let cfg = NSURLSessionConfiguration.defaultSessionConfiguration()
        cfg.HTTPCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        cfg.timeoutIntervalForRequest = 30
        cfg.HTTPMaximumConnectionsPerHost = 100
        mgr = Manager(configuration: cfg)
        implementation = { (url:String, params:[String:AnyObject]?, callback: LongPollingCallback, index:Int) -> Request in
            return self.mgr.request(.POST, url + "?offset=\(self.offset)", parameters: params)
                .responseJSON { (_, _, result) in
                    switch result {
                    case .Success(let json):
                        callback(data: json as! NSDictionary, error: nil, index: index, next: { () -> Void in
                            if self.isPolling {
                                self.requests[index] = self.implementation(url: url , params: params, callback: callback, index: index)
                            }
                        })
                    case .Failure(_, let error as NSError):
                        callback(data: NSDictionary(), error: error, index: index, next: { () -> Void in
                            if self.isPolling {
                                self.requests[index] = self.implementation(url: url , params: params, callback: callback, index: index)
                            }
                        })
                    default:
                        return
                    }
            }
        }
    }
    
    func poll(url:String, params:[String: AnyObject]?, callback: LongPollingCallback) {
        queueURL.append(url)
        queueParameters.append(params)
        queueCallback.append(callback)
        if isPolling {
            requests.append(implementation(url: url, params: params, callback: callback, index: queueURL.count))
        }
    }
    
    func start() {
        if !isPolling {
            isPolling = true
            for (index,url) in queueURL.enumerate() {
                requests.append(implementation(url: url, params: queueParameters[index], callback: queueCallback[index], index: index))
            }
        }
    }
    
    func stop() {
        for request in requests {
            request.cancel()
        }
        requests = []
        isPolling = false
    }
    
    func clear() {
        queueURL = []
        queueParameters = []
        queueCallback = []
    }

}
