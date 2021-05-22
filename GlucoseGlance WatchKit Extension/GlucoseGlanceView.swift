/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view where users can view current glucose levels and when they were last updated as well as try to refresh the data.
*/

import SwiftUI

// The Glucose Glance app's main view.
struct GlucoseGlanceView: View {
    
    @EnvironmentObject var dexcomData: DexcomData
    
    // Lay out the view's body.
    var body: some View {
        VStack() {
            HStack() {
                Spacer()
                Text(dexcomData.currentGlucoseString)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(colorForGlucoseLevel())
                Spacer().overlay(
                    HStack {
                        Text(dexcomData.currentGlucoseTrendSymbolString)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(colorForGlucoseLevel())
                        Text(dexcomData.currentGlucoseDeltaString)
                            .font(.callout)
                    }
                )
            }
            Text(dexcomData.currentGlucose.timestamp, style: .time)
                        
            Divider()
            Spacer()
                        
            Text("Last Update")
                .font(.headline)
            Text(dexcomData.currentGlucose.timestamp, style: .relative)
                .font(.footnote)
        }
        .frame(
              minWidth: 0,
              maxWidth: .infinity,
              minHeight: 0,
              maxHeight: .infinity,
              alignment: .topLeading
            )
    }
    
    // MARK: - Private Methods
    private func colorForGlucoseLevel() -> Color {
        let currentGlucose = dexcomData.currentGlucose.glucose
        return Color(dexcomData.color(forGlucose: currentGlucose))
    }
}

// Configure a preview of the coffee tracker view.
struct CoffeeTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        GlucoseGlanceView()
            .environmentObject(DexcomData.shared)
    }
}
