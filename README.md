# GlucoseGlance
View glucose readings from Dexcom right on your Apple Watch (complications + app support from Dexcom Share)

**This app only communicates from Dexcom Share, NOT from your Dexcom transmitter or app.**

# Setup
This project uses a Cartfile, so firstly make sure you have Carthage installed and run the following,
```sh
./Scripts/carthage.sh update --use-xcframeworks
```

Next, before building in Xcode, see the `GlucoseGlance WatchKit Extension/GGOptions.swift` file to input your Dexcom Share username and password as well as modifying any other default parameters, only username and password are required.
```swift
public struct GGOptions {
    // MARK: Setup Options
    // Enter your Dexcom information
    public static let username: String = "YOUR_USERNAME_HERE"
    public static let password: String = "YOUR_PASSWORD_HERE"
    
    public static let dexcomServer: KnownShareServers = .US
    
    // ...
}
```

Lastly, build the app through Xcode!

# Caveats
Complications on the Apple Watch face aren't allowed to update as much as you will probably want (~5 minutes), they, at max, can update once every 15 minutes. If you notice the complication is out of date, tapping on the complication and loading the app will allow the app to quickly update its data.

# TODOs
* Add some more options for the complications, I mostly just made them up
* Make options able to be set during normal operation of the app, not before building
* Code cleanup
  * I copied a lot of this from an [Apple example](https://developer.apple.com/documentation/clockkit/creating_and_updating_a_complication_s_timeline) which was really helpful, but not the same application as Glucose measurements (originally was a "Coffee Tracker App" :shrug:
