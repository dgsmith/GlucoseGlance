/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view where users can view current glucose levels, when they were last updated, as well as try to
refresh the data.
*/

import SwiftUI

// The Glucose Glance app's main view.
struct GlucoseReadingsView: View {
    
    @EnvironmentObject var dataModel: DexcomData
    
    // Lay out the view's body.
    var body: some View {
        VStack() {
            HStack() {
                Spacer()
                Text(dataModel.currentReadingValueString)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(colorForGlucoseLevel())
                Spacer().overlay(
                    HStack {
                        Text(dataModel.currentReadingTrendSymbolString)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(colorForGlucoseLevel())
                        Text(dataModel.currentReadingDeltaString)
                            .font(.callout)
                    }
                )
            }
            Text(dataModel.currentReading.timestamp, style: .time)
                        
            Divider()
            Spacer()
                        
            Text("Last Update")
                .font(.headline)
            Text(dataModel.currentReading.timestamp, style: .relative)
                .font(.footnote)
                        
            HStack {
                Spacer()
                Spacer()
                Button {
                    async {
                        await dataModel.checkForNewReadings()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.title)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 5)
            .padding(.bottom, 5)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - Private Methods
    private func colorForGlucoseLevel() -> Color {
        let currentGlucose = dataModel.currentReading.value
        return Color(dataModel.color(forGlucose: currentGlucose))
    }
}

// Configure a preview of the glucose readings view.
struct CoffeeTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        GlucoseReadingsView()
            .environmentObject(DexcomData.shared)
    }
}
