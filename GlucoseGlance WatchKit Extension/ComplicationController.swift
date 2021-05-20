/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A controller that configures and updates the complications.
*/

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // The Coffee Tracker app's data model
    lazy var data = DexcomData.shared
    
    // MARK: - Timeline Configuration
    
    // Define how far into the future the app can provide data.
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Indicate that the app can provide timeline entries for the next 2 hours.
        handler(Date().addingTimeInterval(2.0 * 60.0 * 60.0))
    }
    
    // Define whether the complication is visible when the watch is unlocked.
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // This is potentially sensitive data. Hide it on the lock screen.
        handler(.showOnLockScreen)
    }
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptor = CLKComplicationDescriptor(identifier: "Glucose_Glance_Glucose_Level",
                                                   displayName: "Glucose Glance",
                                                   supportedFamilies: CLKComplicationFamily.allCases)
        handler([descriptor])
    }
    
    // MARK: - Timeline Population
    
    // Return the current timeline entry.
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        handler(createTimelineEntry(forComplication: complication, date: Date()))
    }
    
    // Return future timeline entries.
    func getTimelineEntries(for complication: CLKComplication,
                            after date: Date,
                            limit: Int,
                            withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        
        let oneMinute = 1.0 * 60.0
        let twoHours = 2.0 * 60.0 * 60.0
        
        // Create an array to hold the timeline entries.
        var entries = [CLKComplicationTimelineEntry]()
        
        // Calculate the start and end dates.
        var current = date.addingTimeInterval(oneMinute)
        let endDate = date.addingTimeInterval(twoHours)
        
        // Create a timeline entry for every five minutes from the starting time.
        // Stop once you reach the limit or the end date.
        while (current.compare(endDate) == .orderedAscending) && (entries.count < limit) {
            entries.append(createTimelineEntry(forComplication: complication, date: current))
            current = current.addingTimeInterval(oneMinute)
        }
        
        handler(entries)
    }
    
    // MARK: - Placeholder Templates
    
    // Return a localized template with generic information.
    // The system displays the placeholder in the complication selector.
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // Calculate the date 25 hours from now.
        // Since it's more than 24 hours in the future,
        // Our template will always show zero cups and zero mg caffeine.
        let future = Date().addingTimeInterval(25.0 * 60.0 * 60.0)
        let template = createTemplate(forComplication: complication, date: future)
        handler(template)
    }
    
    //    We don't need to implement this method because our privacy behavior is hideOnLockScreen.
    //    Always-On Time automatically hides complications that would be hidden when the device is locked.
//    func getAlwaysOnTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
//
//    }
    // MARK: - Private Methods
    
    // Return a timeline entry for the specified complication and date.
    private func createTimelineEntry(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTimelineEntry {
        
        // Get the correct template based on the complication.
        let template = createTemplate(forComplication: complication, date: date)
        
        // Use the template and date to create a timeline entry.
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }
    
    // Select the correct template based on the complication's family.
    private func createTemplate(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTemplate {
        switch complication.family {
        case .modularSmall:
            return createModularSmallTemplate(forDate: date)
        case .modularLarge:
            return createModularLargeTemplate(forDate: date)
        case .utilitarianSmallFlat, .utilitarianSmall:
            return createUtilitarianSmallFlatTemplate(forDate: date)
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(forDate: date)
        case .circularSmall:
            return createCircularSmallTemplate(forDate: date)
        case .extraLarge:
            return createExtraLargeTemplate(forDate: date)
        case .graphicCorner:
            return createGraphicCornerTemplate(forDate: date)
        case .graphicCircular:
            return createGraphicCircleTemplate(forDate: date)
        case .graphicRectangular:
            return createGraphicRectangularTemplate(forDate: date)
        case .graphicBezel:
            return createGraphicBezelTemplate(forDate: date)
        case .graphicExtraLarge:
            if #available(watchOSApplicationExtension 7.0, *) {
                return createGraphicExtraLargeTemplate(forDate: date)
            } else {
                fatalError("Graphic Extra Large template is only available on watchOS 7.")
            }
        @unknown default:
            fatalError("*** Unknown Complication Family ***")
        }
    }
    
    // Return a modular small template.
    private func createModularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let glucoseProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseString)")
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseTrendSymbolString)")
        let combinedGlucoseProvider = CLKTextProvider(
            format: "%@ %@",
            glucoseProvider, glucoseTrendProvider)
        combinedGlucoseProvider.tintColor = data.color(forGlucose: data.currentGlucose.glucose)
        
        let timeDeltaProvider = CLKSimpleTextProvider(
            text: "\(data.currentGlucoseTimeDeltaString(atDate: date).long)",
            shortText: "\(data.currentGlucoseTimeDeltaString(atDate: date).short)")
        
        // Create the template using the providers.
        return CLKComplicationTemplateModularSmallStackText(line1TextProvider: combinedGlucoseProvider,
                                                            line2TextProvider: timeDeltaProvider)
    }
    
    // Return a modular large template.
    private func createModularLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let tintColor = data.color(forGlucose: data.currentGlucose.glucose)
        
        let glucoseProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseString)")
        glucoseProvider.tintColor = tintColor
        
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseTrendSymbolString)")
        glucoseTrendProvider.tintColor = tintColor
        
        let glucoseDeltaProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseDeltaString)")
        let combinedGlucoseProvider = CLKTextProvider(
            format: "%@ %@ %@",
            glucoseProvider, glucoseTrendProvider, glucoseDeltaProvider)
        
        let timeDeltaProvider = CLKSimpleTextProvider(
            text: "\(data.currentGlucoseTimeDeltaString(atDate: date).long)",
            shortText: "\(data.currentGlucoseTimeDeltaString(atDate: date).short)")
        let timeProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseTimeString)")
        
        return CLKComplicationTemplateModularLargeStandardBody(
            headerTextProvider: combinedGlucoseProvider,
            body1TextProvider: timeProvider,
            body2TextProvider: timeDeltaProvider)
    }
        
    // Return a utilitarian small flat template.
    private func createUtilitarianSmallFlatTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let glucoseProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseString)")
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseTrendSymbolString)")
        let glucoseDeltaProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseDeltaString)")
        let combinedGlucoseProvider = CLKTextProvider(
            format: "%@ %@ %@",
            glucoseProvider, glucoseTrendProvider, glucoseDeltaProvider)
        
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: combinedGlucoseProvider)
    }
    
    // Return a utilitarian large template.
    private func createUtilitarianLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let glucoseProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseString)")
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseTrendSymbolString)")
        let timeDeltaProvider = CLKSimpleTextProvider(
            text: "\(data.currentGlucoseTimeDeltaString(atDate: date).long)",
            shortText: "\(data.currentGlucoseTimeDeltaString(atDate: date).short)")
        
        let combinedProvider = CLKTextProvider(
            format: "%@ %@ %@",
            glucoseProvider, glucoseTrendProvider, timeDeltaProvider)
        
        return CLKComplicationTemplateUtilitarianLargeFlat(textProvider: combinedProvider)        
    }
    
    // Return a circular small template.
    private func createCircularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let glucoseProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseString)")
        glucoseProvider.tintColor = data.color(forGlucose: data.currentGlucose.glucose)
        
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseTrendSymbolString)")
        
        return CLKComplicationTemplateCircularSmallStackText(line1TextProvider: glucoseTrendProvider, line2TextProvider: glucoseProvider)
    }
    
    // Return an extra large template.
    private func createExtraLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let glucoseProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseString)")
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseTrendSymbolString)")
        let glucoseDeltaProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseDeltaString)")
        let combinedGlucoseProvider = CLKTextProvider(
            format: "%@ %@ %@",
            glucoseProvider, glucoseTrendProvider, glucoseDeltaProvider)
        
        let timeDeltaProvider = CLKSimpleTextProvider(
            text: "\(data.currentGlucoseTimeDeltaString(atDate: date).long)",
            shortText: "\(data.currentGlucoseTimeDeltaString(atDate: date).short)")
        
        return CLKComplicationTemplateExtraLargeStackText(
            line1TextProvider: combinedGlucoseProvider,
            line2TextProvider: timeDeltaProvider)
    }
    
    // Return a graphic template that fills the corner of the watch face.
    private func createGraphicCornerTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let tintColor = data.color(forGlucose: data.currentGlucose.glucose)
        
        let glucoseProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseString)")
        glucoseProvider.tintColor = tintColor
        
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseTrendSymbolString)")
        glucoseTrendProvider.tintColor = tintColor
        
        let glucoseDeltaProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseDeltaString)")
        let combinedGlucoseProvider = CLKTextProvider(
            format: "%@ %@ %@",
            glucoseProvider, glucoseTrendProvider, glucoseDeltaProvider)
        
        let timeProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseTimeString)")
        let timeDeltaProvider = CLKSimpleTextProvider(
            text: "\(data.currentGlucoseTimeDeltaString(atDate: date).long)",
            shortText: "\(data.currentGlucoseTimeDeltaString(atDate: date).short)")
        let combinedTimeProfider = CLKTextProvider(format: "%@, %@", timeProvider, timeDeltaProvider)
        
        return CLKComplicationTemplateGraphicCornerStackText(
            innerTextProvider: combinedTimeProfider,
            outerTextProvider: combinedGlucoseProvider)
    }
    
    // Return a graphic circle template.
    private func createGraphicCircleTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let glucoseProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseString)")
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseTrendSymbolString)")
                
        let percentage = Float(data.currentGlucoseTimeDeltaValue(atDate: date) / 15.0)
        let clamped = min(max(percentage, 0.0), 1.0)
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 7.0 / 15.0, 12.0 / 15.0] as [NSNumber],
                                                   fillFraction: clamped)
                
        return CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText(
            gaugeProvider: gaugeProvider,
            bottomTextProvider: glucoseTrendProvider,
            centerTextProvider: glucoseProvider)
    }
    
    // Return a large rectangular graphic template.
    private func createGraphicRectangularTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let tintColor = data.color(forGlucose: data.currentGlucose.glucose)
        
        let glucoseProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseString)")
        glucoseProvider.tintColor = tintColor
        
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseTrendSymbolString)")
        glucoseTrendProvider.tintColor = tintColor
        
        let glucoseDeltaProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseDeltaString)")
        let combinedGlucoseProvider = CLKTextProvider(format: "%@ %@ %@", glucoseProvider, glucoseTrendProvider, glucoseDeltaProvider)
        
        let timeDeltaProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseTimeDeltaString(atDate: date).long)", shortText: "\(data.currentGlucoseTimeDeltaString(atDate: date).short)")
        let timeProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseTimeString)")
        
        return CLKComplicationTemplateGraphicRectangularStandardBody(
            headerTextProvider: combinedGlucoseProvider,
            body1TextProvider: timeProvider,
            body2TextProvider: timeDeltaProvider)
    }
    
    // Return a circular template with text that wraps around the top of the watch's bezel.
    private func createGraphicBezelTemplate(forDate date: Date) -> CLKComplicationTemplate {
        
        let glucoseProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseString)")
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseTrendSymbolString)")
        
        let glucoseDeltaProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseDeltaString)")
        let combinedGlucoseProvider = CLKTextProvider(format: "%@ %@", glucoseProvider, glucoseDeltaProvider)
                
        let circle = CLKComplicationTemplateGraphicCircularStackText(
            line1TextProvider: glucoseTrendProvider,
            line2TextProvider: combinedGlucoseProvider)
        
        let timeDeltaProvider = CLKSimpleTextProvider(
            text: "\(data.currentGlucoseTimeDeltaString(atDate: date).long)",
            shortText: "\(data.currentGlucoseTimeDeltaString(atDate: date).short)")
        let timeProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseTimeString)")
        let combinedTimeProvider = CLKTextProvider(format: "%@, %@", timeProvider, timeDeltaProvider)
                
        // Create the bezel template using the circle template and the text provider.
        return CLKComplicationTemplateGraphicBezelCircularText(
            circularTemplate: circle,
            textProvider: combinedTimeProvider)
    }
    
    // Returns an extra large graphic template.
    private func createGraphicExtraLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let glucoseProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseString)")
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(data.currentGlucoseTrendSymbolString)")
                
        let percentage = Float(data.currentGlucoseTimeDeltaValue(atDate: date) / 15.0)
        let clamped = min(max(percentage, 0.0), 1.0)
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 7.0 / 15.0, 12.0 / 15.0] as [NSNumber],
                                                   fillFraction: clamped)
        
        return CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeSimpleText(
            gaugeProvider: gaugeProvider,
            bottomTextProvider: glucoseTrendProvider,
            centerTextProvider: glucoseProvider)
    }
}
