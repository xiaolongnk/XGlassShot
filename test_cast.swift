import AppKit
import CoreGraphics

let screen = NSScreen.main!
let description = screen.deviceDescription
let key = NSDeviceDescriptionKey("NSScreenNumber")

if let number = description[key] as? NSNumber {
    print("Found NSNumber: \(number)")
    
    if let id = number as? UInt32 {
        print("Direct cast to UInt32 SUCCESS: \(id)")
    } else {
        print("Direct cast to UInt32 FAILED")
    }
    
    let idValue = number.uint32Value
    print("Value via .uint32Value: \(idValue)")
} else {
    print("Could not find NSNumber for screen")
}
