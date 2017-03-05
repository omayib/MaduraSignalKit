//
//  SignalEngineConfig.swift
//  MaduraSignalKit
//
//  Created by qiscus on 1/26/17.
//  Copyright © 2017 qiscus. All rights reserved.
//

import Foundation
public class SignalEngineConfig{
    var mqttHost: String =  "mqtt.qiscus.com"
    var port: Int = 1883
    
    public init(mqttHost: String, port: Int) {
        self.mqttHost = mqttHost
        self.port = port
    }
}
