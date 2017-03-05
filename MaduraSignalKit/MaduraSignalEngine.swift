//
//  MaduraSignal.swift
//  MaduraSignalKit
//
//  Created by qiscus on 1/15/17.
//  Copyright © 2017 qiscus. All rights reserved.
//

import Foundation

public class MaduraSignalEngine{
    private(set) public var signalCommand: SignalEngineCommand?
    
    public init(userId:String, signalResponse: SignalEngineResponse, config: SignalEngineConfig) {
        print("madura signal engine initialized \(userId)")
        self.signalCommand = MqttSignalEngine(signalEngineResponse: signalResponse,clientId: userId,config: config)
    }
    
    deinit {
        self.signalCommand = nil
    }
}
