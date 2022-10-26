//
//  FileInfo.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 10/26/22.
//

import Foundation

/// A struct holding basic information about the file.
/// Equality can be used as a cheap way to check for mutation.
public struct FileInfo: Hashable, Equatable {
    var created: Date
    var modified: Date
    var size: Int
    
    /// Modified time on file, as Unix Timestamp Integer (rounded to the nearest second)
    /// We were previously getting what appeared to be rounding precision errors
    /// when serializing datetimes as ISO strings using .
    ///
    /// Additionally, file timestamps precision is limited to:
    /// 1 second for EXT3
    /// 1 microsecond for UFS
    /// 1 nanosecond for EXT4
    ///
    /// To-the-nearest-second precision is fine for the purpose of comparing changes, and
    /// handwaves away these issues.
    ///
    /// 2021-07-26 Gordon Brander
    var modifiedTimestampNearestSecond: Int {
        Int(modified.timeIntervalSince1970)
    }
    
    /// Created time on file, as Unix Timestamp Integer (rounded to the nearest second)
    var createdTimestampNearestSecond: Int {
        Int(created.timeIntervalSince1970)
    }
}
