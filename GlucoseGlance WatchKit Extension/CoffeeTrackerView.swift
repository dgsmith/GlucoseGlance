/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view where users can add drinks or view the current amount of caffeine they have drunk.
*/

import SwiftUI

// The Coffee Tracker app's main view.
struct CoffeeTrackerView: View {
    
    @EnvironmentObject var dexcomData: DexcomData
    
    // Lay out the view's body.
    var body: some View {
        VStack {
            
            HStack(alignment: .center) {
                Text(dexcomData.currentGlucoseString)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(colorForGlucoseLevel())
                Text(dexcomData.currentGlucoseTrendSymbolString)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(colorForGlucoseLevel())
                Text(dexcomData.currentGlucoseDeltaString)
                    .font(.callout)
                    .alignmentGuide(VerticalAlignment.center) { _ in 8 }
            }
            
            Text(dexcomData.currentGlucoseTimeDeltaString(atDate: Date()).long)
                .font(.footnote)
            
            Divider()
            
            // Display how much the user has drunk today,
            // using the equivalent number of 8 oz. cups of coffee.
            Text(dexcomData.currentGlucoseTimeString)
                .font(.body)
                .fontWeight(.bold)
            Text("Last Update")
                .font(.footnote)
            Spacer()
            
            // Display a button that lets the user record new drinks.
            Button(action: { self.dexcomData.loadNewDexcomData() }) {
                Image(systemName: "arrow.clockwise")
                Text("Refresh")
            }
        }
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
        CoffeeTrackerView()
            .environmentObject(DexcomData.shared)
    }
}
