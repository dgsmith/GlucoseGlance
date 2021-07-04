/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A controller that configures and updates the complications.
*/

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // The app's data model
    lazy var dataModel = DexcomData.shared
    
    // MARK: - Timeline Configuration
        
    // Define whether the complication is visible when the watch is unlocked.
    func getPrivacyBehavior(for complication: CLKComplication,
                            withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptor = CLKComplicationDescriptor(identifier: "Glucose_Glance_Glucose_Level",
                                                   displayName: "Glucose Glance Readings",
                                                   supportedFamilies: CLKComplicationFamily.allCases)
        handler([descriptor])
    }
    
    // MARK: - Timeline Population
    
    // Return the current timeline entry.
    func getCurrentTimelineEntry(for complication: CLKComplication,
                                 withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Get the correct template based on the complication.
        let template = createTemplate(forComplication: complication, withData: dataModel)
        
        handler(CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template))
    }
        
    // MARK: - Placeholder Templates
    
    // Return a localized template with generic information.
    // The system displays the placeholder in the complication selector.
    func getLocalizableSampleTemplate(for complication: CLKComplication,
                                      withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        handler(createTemplate(forComplication: complication, withData: ExampleDexcomData(timestamp: Date())))
    }
        
    // MARK: - Private Methods
    
    // Return a timeline entry for the specified complication and date.
    private func createTimelineEntry(forComplication complication: CLKComplication) -> CLKComplicationTimelineEntry {
        
        // Get the correct template based on the complication.
        let template = createTemplate(forComplication: complication, withData: dataModel)
        
        // Use the template and date to create a timeline entry.
        return CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
    }
    
    // Select the correct template based on the complication's family.
    private func createTemplate(forComplication complication: CLKComplication, withData data: DexcomDataModelInterface) -> CLKComplicationTemplate {
        switch complication.family {
        case .modularSmall:
            return createModularSmallTemplate(data)
            
        case .modularLarge:
            return createModularLargeTemplate(data)
            
        case .utilitarianSmallFlat, .utilitarianSmall:
            return createUtilitarianSmallFlatTemplate(data)
            
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(data)

        case .circularSmall:
            return createCircularSmallTemplate(data)

        case .extraLarge:
            return createExtraLargeTemplate(data)

        case .graphicCorner:
            return createGraphicCornerTemplate(data)

        case .graphicCircular:
            return createGraphicCircleTemplate(data)

        case .graphicRectangular:
            return createGraphicRectangularTemplate(data)

        case .graphicBezel:
            return createGraphicBezelTemplate(data)

        case .graphicExtraLarge:
            return createGraphicExtraLargeTemplate(data)

        @unknown default:
            fatalError("*** Unknown Complication Family ***")
        }
    }
    
    // Return a modular small template.
    private func createModularSmallTemplate(_ dataModel: DexcomDataModelInterface) -> CLKComplicationTemplate {
        // Create the data providers.
        let glucoseProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingValueString)")
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingTrendSymbolString)")
        let combinedGlucoseProvider = CLKTextProvider(
            format: "%@ %@",
            glucoseProvider, glucoseTrendProvider)
        combinedGlucoseProvider.tintColor = dataModel.color(forGlucose: dataModel.currentReading.value)
        
        let timeDeltaProvider: CLKTextProvider
        if dataModel.isCurrentReadingTooOld {
            timeDeltaProvider = CLKSimpleTextProvider(text: "OLD")
            timeDeltaProvider.tintColor = UIColor(GGOptions.shared.theme.belowRange)
        } else {
            timeDeltaProvider = CLKRelativeDateTextProvider(
                date: dataModel.currentReading.timestamp,
                style: .natural,
                units: .second)
        }
                
        // Create the template using the providers.
        return CLKComplicationTemplateModularSmallStackText(line1TextProvider: combinedGlucoseProvider,
                                                            line2TextProvider: timeDeltaProvider)
    }
    
    // Return a modular large template.
    private func createModularLargeTemplate(_ dataModel: DexcomDataModelInterface) -> CLKComplicationTemplate {
        let tintColor = dataModel.color(forGlucose: dataModel.currentReading.value)
        
        let glucoseProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingValueString)")
        glucoseProvider.tintColor = tintColor
        
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingTrendSymbolString)")
        glucoseTrendProvider.tintColor = tintColor
        
        let glucoseDeltaProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingDeltaString)")
        let combinedGlucoseProvider = CLKTextProvider(
            format: "%@ %@ %@",
            glucoseProvider, glucoseTrendProvider, glucoseDeltaProvider)
        
        let timeDeltaProvider: CLKTextProvider
        if dataModel.isCurrentReadingTooOld {
            timeDeltaProvider = CLKSimpleTextProvider(text: "OLD")
            timeDeltaProvider.tintColor = UIColor(GGOptions.shared.theme.belowRange)
        } else {
            timeDeltaProvider = CLKRelativeDateTextProvider(
                date: dataModel.currentReading.timestamp,
                style: .natural,
                units: .second)
        }
        
        let timeProvider = CLKTimeTextProvider(date: dataModel.currentReading.timestamp)
        
        return CLKComplicationTemplateModularLargeStandardBody(
            headerTextProvider: combinedGlucoseProvider,
            body1TextProvider: timeProvider,
            body2TextProvider: timeDeltaProvider)
    }
        
    // Return a utilitarian small flat template.
    private func createUtilitarianSmallFlatTemplate(_ dataModel: DexcomDataModelInterface) -> CLKComplicationTemplate {
        let glucoseProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingValueString)")
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingTrendSymbolString)")
        let glucoseDeltaProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingDeltaString)")
        let combinedGlucoseProvider = CLKTextProvider(
            format: "%@ %@ %@",
            glucoseProvider, glucoseTrendProvider, glucoseDeltaProvider)
        
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: combinedGlucoseProvider)
    }
    
    // Return a utilitarian large template.
    private func createUtilitarianLargeTemplate(_ dataModel: DexcomDataModelInterface) -> CLKComplicationTemplate {
        let glucoseProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingValueString)")
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingTrendSymbolString)")
        let glucoseDeltaProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingDeltaString)")
        
        let timeDeltaProvider: CLKTextProvider
        if dataModel.isCurrentReadingTooOld {
            timeDeltaProvider = CLKSimpleTextProvider(text: "OLD")
            timeDeltaProvider.tintColor = UIColor(GGOptions.shared.theme.belowRange)
        } else {
            timeDeltaProvider = CLKRelativeDateTextProvider(
                date: dataModel.currentReading.timestamp,
                style: .natural,
                units: .second)
        }
        
        let combinedProvider = CLKTextProvider(
            format: "%@%@ %@, %@",
            glucoseProvider, glucoseTrendProvider, glucoseDeltaProvider, timeDeltaProvider)
        
        return CLKComplicationTemplateUtilitarianLargeFlat(textProvider: combinedProvider)        
    }
    
    // Return a circular small template.
    private func createCircularSmallTemplate(_ dataModel: DexcomDataModelInterface) -> CLKComplicationTemplate {
        let glucoseProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingValueString)")
        glucoseProvider.tintColor = dataModel.color(forGlucose: dataModel.currentReading.value)
        
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingTrendSymbolString)")
        
        return CLKComplicationTemplateCircularSmallStackText(
            line1TextProvider: glucoseTrendProvider,
            line2TextProvider: glucoseProvider)
    }
    
    // Return an extra large template.
    private func createExtraLargeTemplate(_ dataModel: DexcomDataModelInterface) -> CLKComplicationTemplate {
        let glucoseProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingValueString)")
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingTrendSymbolString)")
        let glucoseDeltaProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingDeltaString)")
        let combinedGlucoseProvider = CLKTextProvider(
            format: "%@ %@ %@",
            glucoseProvider, glucoseTrendProvider, glucoseDeltaProvider)
        
        let timeDeltaProvider: CLKTextProvider
        if dataModel.isCurrentReadingTooOld {
            timeDeltaProvider = CLKSimpleTextProvider(text: "OLD")
        } else {
            timeDeltaProvider = CLKRelativeDateTextProvider(
                date: dataModel.currentReading.timestamp,
                style: .natural,
                units: .second)
        }
        
        
        return CLKComplicationTemplateExtraLargeStackText(
            line1TextProvider: combinedGlucoseProvider,
            line2TextProvider: timeDeltaProvider)
    }
    
    // Return a graphic template that fills the corner of the watch face.
    private func createGraphicCornerTemplate(_ dataModel: DexcomDataModelInterface) -> CLKComplicationTemplate {
        let tintColor = dataModel.color(forGlucose: dataModel.currentReading.value)
        
        let glucoseProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingValueString)")
        glucoseProvider.tintColor = tintColor
        
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingTrendSymbolString)")
        glucoseTrendProvider.tintColor = tintColor
        
        let glucoseDeltaProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingDeltaString)")
        let combinedGlucoseProvider = CLKTextProvider(
            format: "%@ %@ %@",
            glucoseProvider, glucoseTrendProvider, glucoseDeltaProvider)
        
        let timeProvider = CLKTimeTextProvider(date: dataModel.currentReading.timestamp)
        
        let timeDeltaProvider: CLKTextProvider
        if dataModel.isCurrentReadingTooOld {
            timeDeltaProvider = CLKSimpleTextProvider(text: "OLD")
            timeDeltaProvider.tintColor = UIColor(GGOptions.shared.theme.belowRange)
        } else {
            timeDeltaProvider = CLKRelativeDateTextProvider(
                date: dataModel.currentReading.timestamp,
                style: .natural,
                units: .second)
        }
        
        let combinedTimeProfider = CLKTextProvider(format: "%@, %@", timeProvider, timeDeltaProvider)
        
        return CLKComplicationTemplateGraphicCornerStackText(
            innerTextProvider: combinedTimeProfider,
            outerTextProvider: combinedGlucoseProvider)
    }
    
    // Return a graphic circle template.
    private func createGraphicCircleTemplate(_ dataModel: DexcomDataModelInterface) -> CLKComplicationTemplate {
        let glucoseProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingValueString)")
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingTrendSymbolString)")
        
        let gaugeProvider = CLKTimeIntervalGaugeProvider(
            style: .fill,
            gaugeColors: nil,
            gaugeColorLocations: nil,
            start: dataModel.currentReading.timestamp,
            end: dataModel.currentReading.timestamp.addingTimeInterval(GGOptions.shared.readingOldnessInterval))
                                
        return CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText(
            gaugeProvider: gaugeProvider,
            bottomTextProvider: glucoseTrendProvider,
            centerTextProvider: glucoseProvider)
    }
    
    // Return a large rectangular graphic template.
    private func createGraphicRectangularTemplate(_ dataModel: DexcomDataModelInterface) -> CLKComplicationTemplate {
        let tintColor = dataModel.color(forGlucose: dataModel.currentReading.value)
        
        let glucoseProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingValueString)")
        glucoseProvider.tintColor = tintColor
        
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingTrendSymbolString)")
        glucoseTrendProvider.tintColor = tintColor
        
        let glucoseDeltaProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingDeltaString)")
        let combinedGlucoseProvider = CLKTextProvider(format: "%@ %@ %@", glucoseProvider, glucoseTrendProvider, glucoseDeltaProvider)
        
        let timeProvider = CLKTimeTextProvider(date: dataModel.currentReading.timestamp)
        
        let timeDeltaProvider: CLKTextProvider
        if dataModel.isCurrentReadingTooOld {
            timeDeltaProvider = CLKSimpleTextProvider(text: "OLD")
            timeDeltaProvider.tintColor = UIColor(GGOptions.shared.theme.belowRange)
        } else {
            timeDeltaProvider = CLKRelativeDateTextProvider(
                date: dataModel.currentReading.timestamp,
                style: .natural,
                units: .second)
        }
        
        return CLKComplicationTemplateGraphicRectangularStandardBody(
            headerTextProvider: combinedGlucoseProvider,
            body1TextProvider: timeProvider,
            body2TextProvider: timeDeltaProvider)
    }
    
    // Return a circular template with text that wraps around the top of the watch's bezel.
    private func createGraphicBezelTemplate(_ dataModel: DexcomDataModelInterface) -> CLKComplicationTemplate {
        
        let glucoseProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingValueString)")
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingTrendSymbolString)")
        
        let glucoseDeltaProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingDeltaString)")
        let combinedGlucoseProvider = CLKTextProvider(format: "%@ %@", glucoseProvider, glucoseDeltaProvider)
                
        let circle = CLKComplicationTemplateGraphicCircularStackText(
            line1TextProvider: glucoseTrendProvider,
            line2TextProvider: combinedGlucoseProvider)
        
        let timeDeltaProvider: CLKTextProvider
        if dataModel.isCurrentReadingTooOld {
            timeDeltaProvider = CLKSimpleTextProvider(text: "OLD")
            timeDeltaProvider.tintColor = UIColor(GGOptions.shared.theme.belowRange)
        } else {
            timeDeltaProvider = CLKRelativeDateTextProvider(
                date: dataModel.currentReading.timestamp,
                style: .natural,
                units: .second)
        }
        
        let timeProvider = CLKTimeTextProvider(date: dataModel.currentReading.timestamp)
        
        let combinedTimeProvider = CLKTextProvider(format: "%@, %@", timeProvider, timeDeltaProvider)
                
        // Create the bezel template using the circle template and the text provider.
        return CLKComplicationTemplateGraphicBezelCircularText(
            circularTemplate: circle,
            textProvider: combinedTimeProvider)
    }
    
    // Returns an extra large graphic template.
    private func createGraphicExtraLargeTemplate(_ dataModel: DexcomDataModelInterface) -> CLKComplicationTemplate {
        let glucoseProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingValueString)")
        let glucoseTrendProvider = CLKSimpleTextProvider(text: "\(dataModel.currentReadingTrendSymbolString)")
                
        let gaugeProvider = CLKTimeIntervalGaugeProvider(
            style: .fill,
            gaugeColors: nil,
            gaugeColorLocations: nil,
            start: dataModel.currentReading.timestamp,
            end: dataModel.currentReading.timestamp.addingTimeInterval(GGOptions.shared.readingOldnessInterval))
        
        return CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeSimpleText(
            gaugeProvider: gaugeProvider,
            bottomTextProvider: glucoseTrendProvider,
            centerTextProvider: glucoseProvider)
    }
}
