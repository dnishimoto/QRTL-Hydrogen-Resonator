//
//  ContentView.swift
//  QRTL Hydrogen Resonator
//
//  Created by David Nishimoto on 8/24/26.
//

import SwiftUI
import CoreData

// MARK: - Physical Constants
let speedOfLight: Double = 299_792_458 // m/s
let faradayConstant: Double = 96485.3329 // C/mol
let avogadroNumber: Double = 6.02214076e23 // 1/mol
let waterSplittingEnergy: Double = 237_000 // J/mol (approximate Gibbs free energy for water splitting)
let waterMolarMass: Double = 18.01528 // g/mol

// MARK: - Hydrogen Resonator Simulator Struct
struct HydrogenResonatorSimulator {
    // Inputs
    var laserWavelengthNm: Double     // nm
    var laserPowerW: Double            // W
    var cavityLengthCm: Double         // cm
    var waterPathMm: Double            // mm
    var operationTimeMin: Double       // minutes
    
    // Computed properties
    var laserWavelengthM: Double {
        laserWavelengthNm * 1e-9
    }
    
    var cavityLengthM: Double {
        cavityLengthCm * 1e-2
    }
    
    var waterPathM: Double {
        waterPathMm * 1e-3
    }
    
    var operationTimeS: Double {
        operationTimeMin * 60
    }
    
    // Calculate laser frequency (Hz)
    var laserFrequencyHz: Double {
        speedOfLight / laserWavelengthM
    }
    
    // Assume absorption fraction based on water path length (simplified Beer-Lambert)
    // Using an arbitrary absorption coefficient (m^-1) for demonstration
    // For pure water in visible range, absorption coefficient is very small,
    // but we assume a hypothetical value for the sake of calculation.
    let absorptionCoefficient: Double = 0.1 // per meter
    
    var absorptionFraction: Double {
        1 - exp(-absorptionCoefficient * waterPathM)
    }
    
    // Absorbed power in Watts
    var absorbedPowerW: Double {
        laserPowerW * absorptionFraction
    }
    
    // Total energy input to system (J)
    var inputEnergyJ: Double {
        laserPowerW * operationTimeS
    }
    
    // Total absorbed energy (J)
    var absorbedEnergyJ: Double {
        absorbedPowerW * operationTimeS
    }
    
    // Calculate moles of H2 produced based on absorbed energy and water splitting energy
    // 2H2O + energy -> 2H2 + O2 means 2 moles H2O produce 2 moles H2
    // Using Gibbs free energy requirement per mole water split, determine moles of H2 produced
    // For simplicity, assume 100% conversion efficiency of absorbed energy to splitting
    // In reality, efficiency is much lower; we'll calculate theoretical efficiency below.
    var molesWaterSplitted: Double {
        absorbedEnergyJ / waterSplittingEnergy
    }
    
    var molesH2Produced: Double {
        molesWaterSplitted // 1 mol H2O produces 1 mol H2 (actually 2 mol H2 per 2 mol H2O)
    }
    
    var molesO2Produced: Double {
        molesWaterSplitted / 2.0
    }
    
    // Convert moles gas to volume (liters) at STP
    // 1 mole gas = 22.414 L
    let molarVolumeLiters: Double = 22.414
    
    var hydrogenVolumeL: Double {
        molesH2Produced * molarVolumeLiters
    }
    
    var oxygenVolumeL: Double {
        molesO2Produced * molarVolumeLiters
    }
    
    // Output energy stored in chemical bonds (J)
    var outputEnergyJ: Double {
        molesWaterSplitted * waterSplittingEnergy
    }
    
    // Efficiency (output energy / input energy)
    var efficiency: Double {
        guard inputEnergyJ > 0 else { return 0 }
        return outputEnergyJ / inputEnergyJ
    }
}

// MARK: - ContentView with Simulator UI and Mode Selection
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    // Simulator input state variables
    @State private var laserWavelengthNm: Double = 532 // green laser default nm
    @State private var laserPowerW: Double = 1.0       // 1 Watt default
    @State private var cavityLengthCm: Double = 10.0   // 10 cm default
    @State private var waterPathMm: Double = 1.0       // 1 mm default
    @State private var operationTimeMin: Double = 5.0  // 5 minutes default
    
    // Simulation mode state variable: "Optical Resonator" or "Electrolysis"
    @State private var simulationMode: String = "Optical Resonator"
    
    // Computed results
    @State private var simulationResult: HydrogenResonatorSimulator? = nil
    
    let simulationModes = ["Optical Resonator", "Electrolysis"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                
                // MARK: - Mode Selection Picker
                Picker("Simulation Mode", selection: $simulationMode) {
                    ForEach(simulationModes, id: \.self) { mode in
                        Text(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // MARK: - 3D Visualization of the Resonator Setup with Mode
                Resonator3DView(simulationResult: $simulationResult, simulationMode: $simulationMode)
                    .frame(height: 260)
                    .padding(.horizontal)
                
                // MARK: - Hydrogen Resonator Simulator/Input Section
                Section(simulationMode == "Optical Resonator" ? "Optical Resonator Simulator" : "Electrolysis Simulator") {
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            HStack {
                                Text("Laser Wavelength (nm):")
                                Spacer()
                                TextField("", value: $laserWavelengthNm, formatter: NumberFormatter.decimal)
                                    .frame(width: 80)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)
                                    .disabled(simulationMode == "Electrolysis") // Disable laser input in Electrolysis mode
                                    .opacity(simulationMode == "Electrolysis" ? 0.5 : 1.0)
                            }
                            Slider(value: $laserWavelengthNm, in: 400...700, step: 1)
                                .disabled(simulationMode == "Electrolysis")
                                .opacity(simulationMode == "Electrolysis" ? 0.5 : 1.0)
                        }
                        
                        Group {
                            HStack {
                                Text("Laser Power (W):")
                                Spacer()
                                TextField("", value: $laserPowerW, formatter: NumberFormatter.decimal)
                                    .frame(width: 80)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)
                                    .disabled(simulationMode == "Electrolysis")
                                    .opacity(simulationMode == "Electrolysis" ? 0.5 : 1.0)
                            }
                            Slider(value: $laserPowerW, in: 0.1...10, step: 0.1)
                                .disabled(simulationMode == "Electrolysis")
                                .opacity(simulationMode == "Electrolysis" ? 0.5 : 1.0)
                        }
                        
                        Group {
                            HStack {
                                Text("Cavity Length (cm):")
                                Spacer()
                                TextField("", value: $cavityLengthCm, formatter: NumberFormatter.decimal)
                                    .frame(width: 80)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)
                                    .disabled(simulationMode == "Electrolysis")
                                    .opacity(simulationMode == "Electrolysis" ? 0.5 : 1.0)
                            }
                            Slider(value: $cavityLengthCm, in: 1...100, step: 1)
                                .disabled(simulationMode == "Electrolysis")
                                .opacity(simulationMode == "Electrolysis" ? 0.5 : 1.0)
                        }
                        
                        Group {
                            HStack {
                                Text("Water Path (mm):")
                                Spacer()
                                TextField("", value: $waterPathMm, formatter: NumberFormatter.decimal)
                                    .frame(width: 80)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)
                            }
                            Slider(value: $waterPathMm, in: 0.1...10, step: 0.1)
                        }
                        
                        Group {
                            HStack {
                                Text("Operation Time (min):")
                                Spacer()
                                Stepper(value: $operationTimeMin, in: 1...120, step: 1) {
                                    Text("\(Int(operationTimeMin)) min")
                                }
                            }
                        }
                        
                        Button("Compute Results") {
                            simulationResult = HydrogenResonatorSimulator(
                                laserWavelengthNm: laserWavelengthNm,
                                laserPowerW: laserPowerW,
                                cavityLengthCm: cavityLengthCm,
                                waterPathMm: waterPathMm,
                                operationTimeMin: operationTimeMin
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .padding([.horizontal, .top])
                
                // MARK: - Simulation Results Display
                if let result = simulationResult {
                    Section("Simulation Results") {
                        VStack(alignment: .leading, spacing: 8) {
                            Group {
                                Text("Laser Frequency: \(result.laserFrequencyHz.formatted(.number.precision(.fractionLength(2)))) Hz")
                                    .opacity(simulationMode == "Optical Resonator" ? 1 : 0.5)
                                Text("Absorbed Power: \(result.absorbedPowerW.formatted(.number.precision(.fractionLength(3)))) W")
                                
                                // Only show gas output and efficiency for Electrolysis mode
                                if simulationMode == "Electrolysis" {
                                    Text("Estimated H₂ Gas Output: \(result.hydrogenVolumeL.formatted(.number.precision(.fractionLength(3)))) L")
                                    Text("Estimated O₂ Gas Output: \(result.oxygenVolumeL.formatted(.number.precision(.fractionLength(3)))) L")
                                    Text("Input Energy: \(result.inputEnergyJ.formatted(.number.precision(.fractionLength(1)))) J")
                                    Text("Output Energy (Chemical): \(result.outputEnergyJ.formatted(.number.precision(.fractionLength(1)))) J")
                                    Text("Efficiency: \((result.efficiency * 100).formatted(.number.precision(.fractionLength(2)))) %")
                                } else {
                                    // For Optical Resonator mode, note that no net hydrogen/oxygen is produced
                                    Text("No net H₂/O₂ production in Optical Resonator mode.")
                                        .italic()
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding([.horizontal, .bottom])
                    }
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // MARK: - Original List and Navigation
                List {
                    ForEach(items) { item in
                        NavigationLink {
                            Text("Item at \(item.timestamp!, formatter: itemFormatter)")
                        } label: {
                            Text(item.timestamp!, formatter: itemFormatter)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: addItem) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
                Text("Select an item")
            }
            .navigationTitle("QRTL Hydrogen Resonator")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - NumberFormatter Extension for Decimal Input
extension NumberFormatter {
    static var decimal: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }
}

// MARK: - Date Formatter for List Items
private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

// MARK: - Resonator3DView: 3D Visualization and Overlay for Hydrogen Resonator (Dual Mode)
// This view visually represents two distinct modes:
// 1. Optical Resonator Mode: Shows laser, resonator cavity, water cell, and heat effects.
//    Explains that absorbed energy becomes heat with no water splitting.
// 2. Electrolysis Mode: Shows an electrolysis cell with membrane, electrodes, and gas collection.
//    Displays gas production and power/current overlays relevant to electrolysis.
struct Resonator3DView: View {
    // Binding to the simulation result so the view updates dynamically
    @Binding var simulationResult: HydrogenResonatorSimulator?
    
    // Simulation mode binding to switch visualizations
    @Binding var simulationMode: String
    
    // Animation state for gas bubbles and heat effects
    @State private var bubbleAnimation: Bool = false
    @State private var heatAnimation: Bool = false
    
    // Constants for drawing sizes
    private let laserBeamWidth: CGFloat = 10
    private let cavityWidth: CGFloat = 160
    private let cavityHeight: CGFloat = 100
    private let mirrorThickness: CGFloat = 8
    private let waterCellDiameter: CGFloat = 60
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background gradient to simulate lab environment lighting
                LinearGradient(colors: [Color.black.opacity(0.8), Color.gray.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .cornerRadius(12)
                
                if simulationMode == "Optical Resonator" {
                    opticalResonatorView(geo: geo)
                } else if simulationMode == "Electrolysis" {
                    electrolysisCellView(geo: geo)
                }
            }
            .onAppear {
                bubbleAnimation = true
                heatAnimation = true
            }
            .onDisappear {
                bubbleAnimation = false
                heatAnimation = false
            }
        }
    }
    
    // MARK: - Optical Resonator Mode Visualization
    @ViewBuilder
    private func opticalResonatorView(geo: GeometryProxy) -> some View {
        ZStack {
            // MARK: - Cavity mirrors (front and back) as reflective planes
            // Approximated by thin rounded rectangles with gradient to simulate reflection
            Group {
                // Left mirror with label "Mirror 1"
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.6), Color.gray.opacity(0.3), Color.white.opacity(0.6)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: mirrorThickness, height: cavityHeight)
                    .shadow(color: .white.opacity(0.3), radius: 4)
                    .offset(x: -cavityWidth / 2)
                    .overlay(
                        Text("Mirror 1")
                            .font(.caption2.monospaced())
                            .foregroundColor(.white.opacity(0.8))
                            .rotationEffect(.degrees(-90))
                            .offset(x: -mirrorThickness/2 - 12, y: 0)
                    )
                
                // Right mirror with label "Mirror 2"
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.6), Color.gray.opacity(0.3), Color.white.opacity(0.6)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: mirrorThickness, height: cavityHeight)
                    .shadow(color: .white.opacity(0.3), radius: 4)
                    .offset(x: cavityWidth / 2)
                    .overlay(
                        Text("Mirror 2")
                            .font(.caption2.monospaced())
                            .foregroundColor(.white.opacity(0.8))
                            .rotationEffect(.degrees(90))
                            .offset(x: mirrorThickness/2 + 12, y: 0)
                    )
            }
            
            // MARK: - Water cell as translucent blue cylinder (approximated by ellipse with gradient)
            ZStack {
                Ellipse()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: waterCellDiameter, height: cavityHeight * 0.8)
                    .overlay(
                        Ellipse()
                            .stroke(Color.blue.opacity(0.7), lineWidth: 2)
                    )
                    .shadow(color: Color.blue.opacity(0.4), radius: 4)
                    .overlay(
                        Text("Water Cell")
                            .font(.caption2.monospaced())
                            .foregroundColor(Color.blue.opacity(0.8))
                            .offset(y: cavityHeight * 0.4)
                    )
            }
            
            // MARK: - Laser beam as a colored beam (green to red gradient based on wavelength)
            // Approximate color wavelength between 400 nm (violet) to 700 nm (red)
            let wavelength = simulationResult?.laserWavelengthNm ?? 532
            let laserColor = wavelengthToRGB(wavelength: wavelength)
            let beamOpacity = simulationResult != nil ? 0.7 : 0.0
            
            RoundedRectangle(cornerRadius: laserBeamWidth / 2)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [laserColor.opacity(beamOpacity), laserColor.opacity(beamOpacity / 2)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: cavityWidth + mirrorThickness * 2, height: laserBeamWidth)
                .offset(y: 0)
                .shadow(color: laserColor.opacity(beamOpacity), radius: 8, x: 0, y: 0)
                .blendMode(.screen)
                .overlay(
                    Text("Laser Beam")
                        .font(.caption2.monospaced())
                        .foregroundColor(laserColor.opacity(0.9))
                        .offset(y: -laserBeamWidth * 2)
                )
            
            // MARK: - Laser Driver and Optics (simplified rectangles and labels)
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                .frame(width: 50, height: 30)
                .position(x: geo.size.width/2 - (cavityWidth/2 + 60), y: geo.size.height/2)
                .overlay(
                    Text("Laser Driver")
                        .font(.caption2.monospaced())
                        .foregroundColor(.white.opacity(0.85))
                )
            
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                .frame(width: 40, height: 40)
                .position(x: geo.size.width/2 - (cavityWidth/2 + 15), y: geo.size.height/2)
                .overlay(
                    Text("Optics")
                        .font(.caption2.monospaced())
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                )
            
            // MARK: - Animated heat effect inside water cell to represent absorbed IR energy turning to heat
            if let result = simulationResult {
                let absorbedPower = result.absorbedPowerW
                if absorbedPower > 0 {
                    // Pulsating warm water color overlay
                    Ellipse()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(0.1 + (heatAnimation ? 0.3 : 0.1)),
                                    Color.orange.opacity(0.05),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 5,
                                endRadius: waterCellDiameter
                            )
                        )
                        .frame(width: waterCellDiameter, height: cavityHeight * 0.8)
                        .shadow(color: Color.red.opacity(0.4), radius: 10)
                        .animation(
                            Animation.easeInOut(duration: 2).repeatForever(autoreverses: true),
                            value: heatAnimation
                        )
                    
                    // Small heat bubbles rising inside the water cell
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(Color.red.opacity(0.25))
                            .frame(width: 6, height: 6)
                            .position(
                                x: geo.size.width/2 + CGFloat.random(in: -waterCellDiameter/4...waterCellDiameter/4),
                                y: geo.size.height/2 + (heatAnimation ? -CGFloat(index * 20) : CGFloat(index * 20))
                            )
                            .animation(
                                Animation.easeInOut(duration: Double(index + 1))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.3),
                                value: heatAnimation
                            )
                    }
                }
            }
            
            // MARK: - Warning Overlay: No net hydrogen/oxygen production notice
            VStack(alignment: .leading, spacing: 6) {
                Text("⚠️ No net hydrogen/oxygen production")
                    .font(.headline.monospaced())
                    .foregroundColor(.yellow)
                Text("Absorbed energy rapidly becomes heat — no water splitting occurs.")
                    .font(.caption.monospaced())
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(10)
            .background(Color.black.opacity(0.75))
            .cornerRadius(10)
            .frame(maxWidth: 320)
            .position(x: geo.size.width / 2, y: geo.size.height - 50)
            
            // MARK: - Educational Annotations for Optical Resonator Mode
            VStack(alignment: .leading, spacing: 6) {
                Text("Optical Resonator Mode")
                    .font(.title3.monospaced().bold())
                    .foregroundColor(.white)
                Text("""
                • Laser light is confined between mirrors to increase interaction with water.
                • Water absorbs infrared energy, which converts to thermal energy.
                • No chemical water splitting occurs under these conditions.
                • Energy dissipation is primarily as heat; hydrogen/oxygen not produced.
                • Safety: Avoid overheating, handle lasers with care.
                """)
                    .font(.caption.monospaced())
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(12)
            .background(Color.black.opacity(0.6))
            .cornerRadius(12)
            .frame(maxWidth: 320)
            .position(x: geo.size.width / 2, y: 40)
        }
    }
    
    // MARK: - Electrolysis Mode Visualization
    @ViewBuilder
    private func electrolysisCellView(geo: GeometryProxy) -> some View {
        ZStack {
            // MARK: - Electrolysis cell body
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.8), Color.black.opacity(0.85)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: cavityWidth * 1.3, height: cavityHeight * 1.1)
                .shadow(color: .black.opacity(0.9), radius: 10)
            
            // MARK: - Membrane in center
            Rectangle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 6, height: cavityHeight * 0.9)
                .position(x: geo.size.width/2, y: geo.size.height/2)
                .overlay(
                    Text("Membrane")
                        .font(.caption2.monospaced())
                        .foregroundColor(.white.opacity(0.85))
                        .rotationEffect(.degrees(-90))
                        .offset(y: -cavityHeight * 0.55)
                )
            
            // MARK: - Electrodes (Anode and Cathode)
            let electrodeWidth: CGFloat = 20
            let electrodeHeight: CGFloat = cavityHeight * 0.9
            
            Rectangle()
                .fill(Color.red.opacity(0.6))
                .frame(width: electrodeWidth, height: electrodeHeight)
                .position(x: geo.size.width/2 - (cavityWidth * 1.3)/2 + electrodeWidth/2 + 10, y: geo.size.height/2)
                .overlay(
                    Text("Anode (+)")
                        .font(.caption2.monospaced())
                        .foregroundColor(.white.opacity(0.85))
                        .rotationEffect(.degrees(-90))
                        .offset(y: -electrodeHeight / 2 - 12)
                )
            
            Rectangle()
                .fill(Color.blue.opacity(0.6))
                .frame(width: electrodeWidth, height: electrodeHeight)
                .position(x: geo.size.width/2 + (cavityWidth * 1.3)/2 - electrodeWidth/2 - 10, y: geo.size.height/2)
                .overlay(
                    Text("Cathode (-)")
                        .font(.caption2.monospaced())
                        .foregroundColor(.white.opacity(0.85))
                        .rotationEffect(.degrees(-90))
                        .offset(y: -electrodeHeight / 2 - 12)
                )
            
            // MARK: - Gas collection chambers (H2 and O2)
            let gasChamberWidth: CGFloat = 50
            let gasChamberHeight: CGFloat = cavityHeight * 0.6
            
            // Hydrogen gas chamber (left)
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.8), lineWidth: 2)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.15)))
                .frame(width: gasChamberWidth, height: gasChamberHeight)
                .position(x: geo.size.width/2 - (cavityWidth * 1.3)/2 - gasChamberWidth/2 - 10, y: geo.size.height/2 + 10)
                .overlay(
                    VStack(spacing: 4) {
                        Text("H₂ Gas")
                            .font(.caption2.monospaced().bold())
                            .foregroundColor(.green.opacity(0.85))
                        if let result = simulationResult {
                            Text("\(result.hydrogenVolumeL.formatted(.number.precision(.fractionLength(3)))) L")
                                .font(.caption2.monospaced())
                                .foregroundColor(.green.opacity(0.85))
                        }
                    }
                    .padding(4)
                )
            
            // Oxygen gas chamber (right)
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.8), lineWidth: 2)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.15)))
                .frame(width: gasChamberWidth, height: gasChamberHeight)
                .position(x: geo.size.width/2 + (cavityWidth * 1.3)/2 + gasChamberWidth/2 + 10, y: geo.size.height/2 + 10)
                .overlay(
                    VStack(spacing: 4) {
                        Text("O₂ Gas")
                            .font(.caption2.monospaced().bold())
                            .foregroundColor(.blue.opacity(0.85))
                        if let result = simulationResult {
                            Text("\(result.oxygenVolumeL.formatted(.number.precision(.fractionLength(3)))) L")
                                .font(.caption2.monospaced())
                                .foregroundColor(.blue.opacity(0.85))
                        }
                    }
                    .padding(4)
                )
            
            // MARK: - Electrolysis Current and Power Overlay (bottom right)
            if let result = simulationResult {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Input Power: \((result.laserPowerW).formatted(.number.precision(.fractionLength(3)))) W")
                        .foregroundColor(.white.opacity(0.85))
                        .font(.caption2.monospaced())
                    
                    // Calculate input current for electrolysis approximation (assume 3.3 V laser voltage for demonstration)
                    let laserVoltage = 3.3
                    let inputCurrent = result.laserPowerW / laserVoltage
                    Text("Input Current: \(inputCurrent.formatted(.number.precision(.fractionLength(3)))) A")
                        .foregroundColor(.white.opacity(0.85))
                        .font(.caption2.monospaced())
                    
                    // Estimated output current if hydrogen converted back with fuel cell (1.23 V, 70% eff)
                    let hydrogenEnergyPerSecond = result.outputEnergyJ / result.operationTimeS
                    let fuelCellVoltage = 1.23
                    let fuelCellEfficiency = 0.7
                    let outputPower = hydrogenEnergyPerSecond * fuelCellEfficiency // Watts
                    let outputCurrent = outputPower / fuelCellVoltage
                    Text("Estimated Output Current: \(outputCurrent.formatted(.number.precision(.fractionLength(3)))) A")
                        .foregroundColor(.yellow.opacity(0.85))
                        .font(.caption2.monospaced())
                }
                .padding(8)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
                .frame(maxWidth: 220)
                .position(x: geo.size.width - 120, y: geo.size.height - 50)
            }
            
            // MARK: - Animated gas bubbles rising inside gas chambers
            if let result = simulationResult {
                // Operation time protected against zero
                let operationTimeMin = result.operationTimeMin > 0 ? result.operationTimeMin : 1
                let hydrogenRate = result.hydrogenVolumeL / operationTimeMin
                let oxygenRate = result.oxygenVolumeL / operationTimeMin
                
                // Bubble count and max radius based on gas generation rates
                let bubbleCountH2 = min(max(Int(hydrogenRate / 0.5), 1), 12)
                let bubbleCountO2 = min(max(Int(oxygenRate / 0.5), 1), 8)
                let maxBubbleRadius: CGFloat = 8
                
                // Hydrogen bubbles in left gas chamber
                ForEach(0..<bubbleCountH2, id: \.self) { index in
                    Circle()
                        .fill(Color.green.opacity(0.6))
                        .frame(width: bubbleRadius(index: index, count: bubbleCountH2, maxRadius: maxBubbleRadius),
                               height: bubbleRadius(index: index, count: bubbleCountH2, maxRadius: maxBubbleRadius))
                        .position(x: geo.size.width/2 - (cavityWidth * 1.3)/2 - 10,
                                  y: geo.size.height/2 + 30 + (bubbleAnimation ? -CGFloat(index * 20) - 20 : CGFloat(index * 20) + 40))
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 1.5...3.0))
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                            value: bubbleAnimation
                        )
                }
                
                // Oxygen bubbles in right gas chamber
                ForEach(0..<bubbleCountO2, id: \.self) { index in
                    Circle()
                        .fill(Color.blue.opacity(0.4))
                        .frame(width: bubbleRadius(index: index, count: bubbleCountO2, maxRadius: maxBubbleRadius * 0.7),
                               height: bubbleRadius(index: index, count: bubbleCountO2, maxRadius: maxBubbleRadius * 0.7))
                        .position(x: geo.size.width/2 + (cavityWidth * 1.3)/2 + 10,
                                  y: geo.size.height/2 + 30 + (bubbleAnimation ? -CGFloat(index * 25) - 30 : CGFloat(index * 25) + 50))
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 1.7...3.5))
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                            value: bubbleAnimation
                        )
                }
            }
            
            // MARK: - Educational Annotations for Electrolysis Mode
            VStack(alignment: .leading, spacing: 6) {
                Text("Electrolysis Mode")
                    .font(.title3.monospaced().bold())
                    .foregroundColor(.white)
                Text("""
                • Electrical energy splits water into hydrogen (H₂) and oxygen (O₂) gases.
                • Anode (+) oxidizes water producing O₂, Cathode (-) reduces protons producing H₂.
                • Ion-conducting membrane separates gases to prevent recombination.
                • Gas bubbles collected in chambers represent produced gases.
                • Safety: Handle gases carefully, ensure proper ventilation and electrical safety.
                """)
                    .font(.caption.monospaced())
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(12)
            .background(Color.black.opacity(0.6))
            .cornerRadius(12)
            .frame(maxWidth: 320)
            .position(x: geo.size.width / 2, y: 40)
        }
    }
    
    // Calculate bubble radius for index to create variety, smaller bubbles for higher index
    private func bubbleRadius(index: Int, count: Int, maxRadius: CGFloat) -> CGFloat {
        let base = maxRadius * (1 - CGFloat(index) / CGFloat(count + 1))
        return max(3, base)
    }
    
    // Convert wavelength in nm to approximate RGB Color
    // Algorithm adapted from common wavelength to RGB conversions
    private func wavelengthToRGB(wavelength: Double) -> Color {
        let wl = max(380, min(wavelength, 780))
        var r: Double = 0
        var g: Double = 0
        var b: Double = 0

        if wl >= 380 && wl < 440 {
            r = -(wl - 440) / (440 - 380)
            g = 0
            b = 1
        } else if wl >= 440 && wl < 490 {
            r = 0
            g = (wl - 440) / (490 - 440)
            b = 1
        } else if wl >= 490 && wl < 510 {
            r = 0
            g = 1
            b = -(wl - 510) / (510 - 490)
        } else if wl >= 510 && wl < 580 {
            r = (wl - 510) / (580 - 510)
            g = 1
            b = 0
        } else if wl >= 580 && wl < 645 {
            r = 1
            g = -(wl - 645) / (645 - 580)
            b = 0
        } else if wl >= 645 && wl <= 780 {
            r = 1
            g = 0
            b = 0
        }

        // Intensity correction
        var factor: Double = 0
        if wl >= 380 && wl < 420 {
            factor = 0.3 + 0.7 * (wl - 380) / (420 - 380)
        } else if wl >= 420 && wl < 701 {
            factor = 1.0
        } else if wl >= 701 && wl <= 780 {
            factor = 0.3 + 0.7 * (780 - wl) / (780 - 700)
        }

        // Apply factor and gamma correction
        let gamma = 0.8
        func adjust(_ color: Double) -> Double {
            let c = color * factor
            return pow(c, gamma)
        }

        return Color(
            red: adjust(r),
            green: adjust(g),
            blue: adjust(b)
        )
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
