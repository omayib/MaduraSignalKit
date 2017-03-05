//
//  SignalEvent.swift
//  MaduraSignalKit
//
//  Created by qiscus on 1/18/17.
//  Copyright © 2017 qiscus. All rights reserved.
//

import Foundation

public enum CallEvent{
    case dial
    case wait
    case cancel
    case join
    case leave
    case reject
    case accept
    case hangup
    case presence
    case complete
    case ping
    case pong
}
public enum UserEvent{
    case invite
    case bussy
    case ready
}
