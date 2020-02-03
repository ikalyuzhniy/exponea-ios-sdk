//
//  CrashManager.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 15/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

final class CrashManager {
    // we need to give NSSetUncaughtExceptionHandler a closure that doesn't trap context
    // let's just keep reference to current crash manager, so we can still easily create new ones in tests
    static var current: CrashManager?

    let storage: TelemetryStorage
    let upload: TelemetryUpload
    let launchDate: Date

    init(storage: TelemetryStorage, upload: TelemetryUpload, launchDate: Date) {
        self.storage = storage
        self.upload = upload
        self.launchDate = launchDate
    }

    var oldHandler: NSUncaughtExceptionHandler?

    func start() {
        uploadCrashLogs()
        oldHandler = NSGetUncaughtExceptionHandler()
        CrashManager.current = self
        NSSetUncaughtExceptionHandler({ CrashManager.current?.uncaughtExceptionHandler($0) })
    }

    func uncaughtExceptionHandler(_ exception: NSException) {
        self.oldHandler?(exception)
        Exponea.logger.log(.error, message: "Handling uncaught exception")
        if TelemetryUtility.isSDKRelated(stackTrace: exception.callStackSymbols) {
            storage.saveCrashLog(
                CrashLog(exception: exception, fatal: true, launchDate: launchDate)
            )
        }
    }

    func caughtExceptionHandler(_ exception: NSException) {
        let crashLog = CrashLog(exception: exception, fatal: false, launchDate: launchDate)
        upload.upload(crashLog: crashLog) { result in
            if !result {
                Exponea.logger.log(.error, message: "Uploading crash log failed")
            }
        }
    }

    func caughtErrorHandler(_ error: Error, stackTrace: [String]) {
        let crashLog = CrashLog(error: error, stackTrace: stackTrace, fatal: false, launchDate: launchDate)
        upload.upload(crashLog: crashLog) { result in
            if !result {
                Exponea.logger.log(.error, message: "Uploading crash log failed")
            }
        }
    }

    func uploadCrashLogs() {
        storage.getAllCrashLogs().forEach { crashLog in
            upload.upload(crashLog: crashLog) { result in
                if result {
                    Exponea.logger.log(.verbose, message: "Successfully uploaded crash log")
                    self.storage.deleteCrashLog(crashLog)
                } else {
                    Exponea.logger.log(.error, message: "Uploading crash log failed")
                }
            }
        }
    }
}