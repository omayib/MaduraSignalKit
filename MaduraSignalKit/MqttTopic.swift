//
//  MqttTopic.swift
//  MaduraSignalKit
//
//  Created by qiscus on 1/18/17.
//  Copyright © 2017 qiscus. All rights reserved.
//

import Foundation
enum MqttTopic:String{
    //for user's topic only
    case invitation = "/%@/invitation"
    case bussy = "/%@/bussy"
    case ready = "/%@/ready"
    case end = "/%@/end"
    //for call session
    case dial = "call/%@/dial"
    case wait = "call/%@/wait"
    case cancel = "call/%@/cancel"
    case join = "call/%@/join"
    case leave = "call/%@/leave"
    case reject = "call/%@/reject"
    case accept = "call/%@/accept"
    case hangup = "call/%@/hangup"
    case presence = "call/%@/presence"
    case complete = "call/%@/complete"
    case pingpong = "call/%@/pingpong"
}

