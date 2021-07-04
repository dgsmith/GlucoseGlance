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
    
    @ObservedObject private var options = GGOptions.shared
    
    @State private var showingOptionsSheet = false
    
    @State private var isUpdating: Bool = false
    
    // Lay out the view's body.
    var body: some View {
        VStack {
            ZStack {
                VStack(alignment: .leading) {
                    HStack() {
                        Text(dataModel.currentReadingValueString)
                            .font(.largeTitle.bold())
                            .foregroundColor(colorForGlucoseLevel())
                            .accessibilityIdentifier("currentReadingValueString")
                        Text(dataModel.currentReadingTrendSymbolString)
                            .font(.title.bold())
                            .foregroundColor(colorForGlucoseLevel())
                            .accessibilityIdentifier("currentReadingTrendSymbolString")
                        Text(dataModel.currentReadingDeltaString)
                            .font(.callout)
                            .accessibilityIdentifier("currentReadingDeltaString")
                    }
                    HStack() {
                        Text(dataModel.currentReading.timestamp, style: .time)
                            .bold()
                            .foregroundColor(options.theme.highlight)
                            .accessibilityIdentifier("currentReading.timestamp")
                    }
                                    
                    Divider()
            
                    if dataModel.lastDexcomError != nil {
                        Text("Error:").font(.footnote)
                        Text(dataModel.lastDexcomError!).font(.system(size: 12))
                        
                    } else {
                        Spacer()
                        Spacer()
                                    
                        Text("Last Update")
                            .font(.subheadline)
                        if dataModel.isCurrentReadingTooOld {
                            Text("OLD")
                                .font(.footnote.bold())
                                .foregroundColor(options.theme.aboveRange)
                                .accessibilityIdentifier("isCurrentReadingTooOld")
                        } else {
                            Text(dataModel.currentReading.timestamp, style: .relative)
                                .font(.footnote)
                                .foregroundColor(options.theme.highlight)
                                .accessibilityIdentifier("isCurrentReadingTooOld")
                        }
                    }

                    Spacer()
                    Spacer()
                }
                    .padding(.leading, 8)
            
                GeometryReader { geo in
                    Button {
                        Task {
                            isUpdating = true
                            _ = await dataModel.checkForNewReadings()
                            isUpdating = false
                        }
                    } label: {
                        Text("\(Image(systemName: "arrow.clockwise.circle"))")
                            .font(.title)
                            .opacity(isUpdating ? 0 : 1)
                            .overlay {
                                if isUpdating {
                                    ProgressView()
                                }
                            }
                    }
                        .foregroundColor(options.theme.main)
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("checkForNewReadings")
                        .disabled(isUpdating)
                        .position(x: geo.size.width - 24,
                                  y: geo.size.height + 4)
                    
                    Button {
                        showingOptionsSheet.toggle()
                    } label: {
                        Text("\(Image(systemName: "ellipsis.circle"))")
                            .font(.title)
                    }
                        .foregroundColor(options.theme.main)
                        .buttonStyle(.plain)
                        
                        .position(x: 24,
                                  y: geo.size.height + 4)
                        .sheet(isPresented: $showingOptionsSheet) {
                            OptionsSheetView()
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button("Done") { showingOptionsSheet.toggle() }
                                    }
                                }
                        }

                }
            }
        }
//        .background(Color.gray)
    }
    
    // MARK: - Private Methods
    private func colorForGlucoseLevel() -> Color {
        let currentGlucose = dataModel.currentReading.value
        return Color(dataModel.color(forGlucose: currentGlucose))
    }
}

struct OptionsSheetView: View {
    
    @ObservedObject private var options = GGOptions.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    Text("\(Image(systemName: "paintpalette.fill"))")
                        .foregroundColor(options.theme.main)
                    Text("Themes")
                }
                Divider()
                ForEach(0..<options.themes.count) { index in
                    Button {
                        options.theme = options.themes[index]
                    } label: {
                        ThemeView(theme: options.themes[index],
                                  isSelected: options.theme == options.themes[index])
                            .padding()
                            .background(.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
}

struct ThemeView: View {
    
    var theme: ColorTheme
    
    var isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(theme.name)
                    .bold()
                    .padding()
                if isSelected {
                    Spacer()
                    Text("\(Image(systemName: "checkmark"))")
                        .padding()
                }
            }
            Divider()
            HStack {
                Spacer()
                ForEach(0..<theme.colors.count) { index in
                    theme.colors[index]
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
                .padding()
        }
    }
    
}

// Configure a preview of the glucose readings view.
struct GlucoseReadingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
//            GlucoseReadingsView()
//                .environmentObject(DexcomData.shared)
//                .previewDevice("Apple Watch Series 6 - 44mm")
//            GlucoseReadingsView()
//                .environmentObject(DexcomData.shared)
//                .previewDevice("Apple Watch Series 6 - 40mm")
            
            OptionsSheetView()
                .previewDevice("Apple Watch Series 6 - 40mm")
            
            ThemeView(theme: ColorThemePlain(), isSelected: true)
                .previewLayout(.fixed(width: 150, height: 61.5))
        }
    }
}
