//
//  DataType.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 18/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Data types that can be associated with tracked events (described in `EventType`).
///
/// - projectToken
/// - customerId
/// - properties
/// - timestamp
/// - eventType
enum DataType: Equatable {

    /// The token of the project that the tracking should be uploaded to.
    case projectToken(String)

    /// Identifier of your customer, can be anything from an email to UUIDs.
    case customerIds([String: JSONValue])

    /// Custom properties that you would like to add to the tracking event,
    /// these can include any relevant information for you.
    case properties([String: JSONValue])

    /// Timestamp of the tracked event in UNIX epoch time, if value is `nil` current date is used.
    case timestamp(Double?)

    /// For some tracked events you can also provide an event type
    case eventType(String)

    /// If nil, it will delete the existing push notification token if any.
    case pushNotificationToken(String?)
}

extension Array where Iterator.Element == DataType {
    var eventTypes: [String] {
        return compactMap { if case .eventType(let eventType) = $0 { return eventType } else { return nil } }
    }

    var latestTimestamp: Double? {
        return compactMap {
            if case .timestamp(let timestamp) = $0 { return timestamp } else { return nil }
        }.sorted().last
    }

    var properties: [String: Any?] {
        var properties: [String: Any?] = [:]
        forEach {
            if case .properties(let props) = $0 {
                props.forEach { properties.updateValue($0.value.rawValue, forKey: $0.key) }
            }
        }
        return properties
    }
}
