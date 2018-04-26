#!/usr/bin/swift

import Foundation

@discardableResult
func shell(_ args: String...) -> (output: String?, error: String?, exitCode: Int32) {
    var output : String?
    var error : String?

    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args

    let outpipe = Pipe()
    task.standardOutput = outpipe
    let errpipe = Pipe()
    task.standardError = errpipe

    task.launch()

    let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
    if let txt = String(data: outdata, encoding: .utf8), !txt.isEmpty {
        output = txt
    }

    let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
    if let txt = String(data: errdata, encoding: .utf8), !txt.isEmpty {
        error = txt
    }

    task.waitUntilExit()
    let status = task.terminationStatus

    return (output, error, status)
}

func swiftlintAutocorrect() {
    let (output, _, _) = shell("swiftlint", "autocorrect")
    
    if let output = output {
        print(output)
    }
    print(".")
}

let (output, _, _) = shell("swiftlint", "--quiet")
if let output = output, !output.isEmpty {
    print(output)
    print("Swiftlint failed")
    print("\nRunning swiftlint autocorrect...")
    swiftlintAutocorrect()
    exit(1)
} else {
    print("Swiftlint succeeded")
    exit(0)
}
