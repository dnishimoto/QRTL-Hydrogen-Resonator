//
//  ContentView.swift
//  QRTL-Hydrogen-Resonator
//
//  3-LASER QRTL HYDROGEN RESONATOR SIMULATION
//
//  PIPELINE
//  ============================================================================
//
//  ELECTRICAL POWER
//       |
//       v
//  THREE Er:YAG LASERS
//       |
//       |  λ = 2.94 µm
//       |  f = c / λ
//       |  ω = 2πf
//       v
//  PHOTON / ELECTROMAGNETIC WAVE MODEL
//       |
//       |  wavelength uniformity
//       |  frequency uniformity
//       |  phase control
//       |  coherence
//       v
//  THREE-LASER PHASE SYNCHRONIZATION
//       |
//       |  Δφ₁₂ ≈ 0
//       |  Δφ₂₃ ≈ 0
//       |  Δφ₁₃ ≈ 0
//       v
//  BEAM UNIFORMITY
//       |
//       |  coherent field superposition
//       v
//  HIGH-REFLECTIVITY OPTICAL CAVITY
//       |
//       |  cavity resonance
//       |  standing-wave formation
//       |  antinodes / nodes
//       v
//  THREE-LASER STANDING WAVE IN UNISON
//       |
//       |  field intensity
//       |  resonance enhancement
//       v
//  QRTL INTERACTION REGION
//       |
//       |  QRTL HYPOTHESIS:
//       |  resonating standing waves cause energy shells
//       |  to dissipate
//       v
//  ENERGY-SHELL DISSIPATION
//       |
//       v
//  H₂ + O₂ RELEASE FROM WATER
//       |
//       v
//  HYDROGEN PRODUCTION
//       |
//       |  g/hr
//       |  kg produced
//       v
//  ELECTRICAL ENERGY ACCOUNTING
//       |
//       |  3 × laser electrical power
//       |  kWh consumed
//       |  electricity price
//       v
//  ECONOMICS
//       |
//       |  electricity cost
//       |  other operating cost
//       |  total cost
//       |  hydrogen revenue
//       |  profit
//       |  cost/kg H₂
//       |  profit/kg H₂
//       v
//  SCALE ANALYSIS
//       |
//       |  one laser
//       |  three lasers
//       |  synchronized optical scaling
//       v
//  ============================================================================
//
//  IMPORTANT MODELING NOTE
//  ============================================================================
//
//  This simulation represents the QRTL mechanism as a TESTABLE HYPOTHESIS.
//  The laser's modeled role is to establish a coherent 2.94 µm standing-wave
//  field. The model does not treat the laser itself as the chemical source
//  of hydrogen.
//
//  The proposed QRTL sequence is:
//
//      2.94 µm coherent photons
//              ↓
//      cavity resonance
//              ↓
//      standing-wave field
//              ↓
//      energy-shell dissipation
//              ↓
//      H₂ / O₂ release
//
//  Three lasers are represented as synchronized coherent sources so that
//  optical intensity and cavity-field uniformity can be examined as the
//  system is scaled.
//
//  ============================================================================

import SwiftUI
import SceneKit
import Combine

// MARK: - Physical Constants

enum QRTLConstants {

    /// Speed of light in vacuum.
    static let speedOfLight: Double = 299_792_458.0

    /// Target Er:YAG wavelength.
    static let wavelengthMeters: Double = 2.94e-6

    /// Target infrared wavelength in micrometers.
    static let wavelengthMicrometers: Double = 2.94

    /// Three synchronized laser sources.
    static let laserCount: Int = 3

    /// Hydrogen selling price.
    static let defaultHydrogenPricePerKg: Double = 26.0

    /// Electricity price.
    static let electricityPricePerKWh: Double = 0.184
}

// MARK: - Laser State

struct QRTLLaserState {

    let wavelengthMeters: Double
    let frequencyHz: Double
    let angularFrequencyRadS: Double

    var phaseRad: Double
    var powerW: Double
    var enabled: Bool

    init(
        phaseRad: Double = 0,
        powerW: Double = 20.0,
        enabled: Bool = true
    ) {

        self.wavelengthMeters =
            QRTLConstants.wavelengthMeters

        self.frequencyHz =
            QRTLConstants.speedOfLight /
            QRTLConstants.wavelengthMeters

        self.angularFrequencyRadS =
            2.0 * Double.pi * frequencyHz

        self.phaseRad = phaseRad
        self.powerW = powerW
        self.enabled = enabled
    }
}

// MARK: - Master Monitor

final class MasterMonitor: ObservableObject {

    // ========================================================================
    // MARK: Operator Controls
    // ========================================================================

    @Published var laserPowerW: Double = 40.0 {
        didSet { recompute() }
    }

    @Published var cavityFinesse: Double = 220.0 {
        didSet { recompute() }
    }

    @Published var otherOperatingCostPerKg: Double = 6.0 {
        didSet { recompute() }
    }

    @Published var ca40Present: Bool = true {
        didSet { recompute() }
    }

    @Published var laserOn: Bool = true {
        didSet { recompute() }
    }

    @Published var laser2PhaseOffset: Double = 0.0 {
        didSet { recompute() }
    }

    @Published var laser3PhaseOffset: Double = 0.0 {
        didSet { recompute() }
    }

    @Published var sellPricePerKg: Double =
        QRTLConstants.defaultHydrogenPricePerKg {
        didSet { recompute() }
    }

    @Published var detuning: Double = 0.0 {
        didSet { recompute() }
    }

    // ========================================================================
    // MARK: QRTL Hypothesis Controls
    // ========================================================================

    /// Enables the hypothesized QRTL shell-resonance pathway.
    @Published var qrtlEnabled: Bool = true {
        didSet { recompute() }
    }

    /// Fraction of the modeled resonant field coupled into existing QRTL shells.
    /// This is a hypothesis parameter, not an established material constant.
    @Published var shellCouplingEfficiency: Double = 0.12 {
        didSet { recompute() }
    }

    /// Modeled persistence of coherent shell amplitude before it relaxes.
    @Published var shellCoherenceLifetimeS: Double = 4.0 {
        didSet { recompute() }
    }

    /// Dimensionless amplitude at which the proposed bonded-state transition begins.
    @Published var shellInstabilityThreshold: Double = 1.0 {
        didSet { recompute() }
    }

    /// Converts amplitude beyond threshold into a modeled H₂ release rate.
    @Published var shellTransitionGainGPerHr: Double = 0.085 {
        didSet { recompute() }
    }

    // ========================================================================
    // MARK: Laser / Optical Outputs
    // ========================================================================

    @Published private(set) var wavelengthMicrometers: Double = 2.94
    @Published private(set) var frequencyTHz: Double = 0
    @Published private(set) var angularFrequencyRadS: Double = 0

    @Published private(set) var totalLaserPowerW: Double = 0
    @Published private(set) var circulatingPowerW: Double = 0
    @Published private(set) var buildupFactor: Double = 0

    @Published private(set) var phaseCoherence: Double = 1.0
    @Published private(set) var beamUniformity: Double = 1.0
    @Published private(set) var standingWaveStrength: Double = 0
    @Published private(set) var resonanceFactor: Double = 0

    // ========================================================================
    // MARK: QRTL State / Outputs
    // ========================================================================

    /// Dimensionless modeled state of the resonantly driven, pre-existing shell.
    @Published private(set) var shellResonantAmplitude: Double = 0

    /// How close the modeled shell is to its instability threshold.
    @Published private(set) var shellThresholdFraction: Double = 0

    /// Modelled rate attributed to the QRTL resonant-shell transition.
    @Published private(set) var resonantShellTransitionRateGPerHr: Double = 0

    @Published private(set) var chamberTemperatureC: Double = 22.0
    @Published private(set) var hydrogenRateGPerHr: Double = 0
    @Published private(set) var oxygenRateGPerHr: Double = 0

    @Published private(set) var isNonlinearRegime: Bool = false
    @Published private(set) var visualFieldIntensity: Double = 0

    // ========================================================================
    // MARK: Production / Economics
    // ========================================================================

    @Published private(set) var hydrogenProducedKg: Double = 0
    @Published private(set) var oxygenProducedKg: Double = 0

    @Published private(set) var electricityConsumedKWh: Double = 0
    @Published private(set) var electricityCost: Double = 0

    @Published private(set) var revenue: Double = 0
    @Published private(set) var otherOperatingCost: Double = 0
    @Published private(set) var totalOperatingCost: Double = 0
    @Published private(set) var profit: Double = 0

    @Published private(set) var electricityCostPerKg: Double = 0
    @Published private(set) var totalCostPerKg: Double = 0
    @Published private(set) var revenuePerKg: Double = 0
    @Published private(set) var profitPerKg: Double = 0

    // ========================================================================
    // MARK: Run State
    // ========================================================================

    private var elapsedHours: Double = 0

    /// Accumulates fractional seconds even while recalculating from sliders.
    private var lastTickDate = Date()

    private var timer: AnyCancellable?

    // ========================================================================
    // MARK: Initialization
    // ========================================================================

    init() {
        recompute()

        timer =
            Timer.publish(
                every: 1.0,
                on: .main,
                in: .common
            )
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    // ========================================================================
    // MARK: Timer
    // ========================================================================

    private func tick() {
        let now = Date()

        let deltaTimeS =
            max(
                0,
                now.timeIntervalSince(lastTickDate)
            )

        lastTickDate = now

        guard laserOn else {
            recompute()
            return
        }

        elapsedHours += deltaTimeS / 3600.0

        updateShellResonance(
            deltaTimeS: deltaTimeS
        )

        recompute()
    }

    // ========================================================================
    // MARK: QRTL Shell State
    // ========================================================================

    private func updateShellResonance(
        deltaTimeS: Double
    ) {
        guard deltaTimeS > 0 else {
            return
        }

        let coherentDrive =
            laserOn &&
            qrtlEnabled &&
            ca40Present
            ? circulatingPowerW *
              resonanceFactor *
              phaseCoherence *
              beamUniformity *
              shellCouplingEfficiency
            : 0

        let normalizedDrive =
            coherentDrive / 1000.0

        let safeLifetimeS =
            max(
                shellCoherenceLifetimeS,
                0.001
            )

        let relaxationRate =
            shellResonantAmplitude /
            safeLifetimeS

        let amplitudeChange =
            (
                normalizedDrive -
                relaxationRate
            ) * deltaTimeS

        shellResonantAmplitude =
            max(
                0,
                shellResonantAmplitude +
                amplitudeChange
            )
    }

    // ========================================================================
    // MARK: Main Optical / QRTL / Economic Pipeline
    // ========================================================================

    private func recompute() {

        // --------------------------------------------------------------------
        // 1. Laser wavelength and frequency
        // --------------------------------------------------------------------

        let wavelength =
            QRTLConstants.wavelengthMeters

        let frequency =
            QRTLConstants.speedOfLight /
            wavelength

        let angularFrequency =
            2.0 *
            Double.pi *
            frequency

        wavelengthMicrometers =
            wavelength * 1.0e6

        frequencyTHz =
            frequency / 1.0e12

        angularFrequencyRadS =
            angularFrequency

        // --------------------------------------------------------------------
        // 2. Three synchronized laser sources
        // --------------------------------------------------------------------

        let laser1 =
            QRTLLaserState(
                phaseRad: 0,
                powerW: laserPowerW,
                enabled: laserOn
            )

        let laser2 =
            QRTLLaserState(
                phaseRad: laser2PhaseOffset,
                powerW: laserPowerW,
                enabled: laserOn
            )

        let laser3 =
            QRTLLaserState(
                phaseRad: laser3PhaseOffset,
                powerW: laserPowerW,
                enabled: laserOn
            )

        let lasers = [
            laser1,
            laser2,
            laser3
        ]

        totalLaserPowerW =
            lasers
            .filter { $0.enabled }
            .reduce(0) {
                $0 + $1.powerW
            }

        // --------------------------------------------------------------------
        // 3. Pairwise phase relationship
        // --------------------------------------------------------------------

        let phaseError12 =
            abs(
                normalizePhase(
                    laser2PhaseOffset
                )
            )

        let phaseError13 =
            abs(
                normalizePhase(
                    laser3PhaseOffset
                )
            )

        let phaseError23 =
            abs(
                normalizePhase(
                    laser3PhaseOffset -
                    laser2PhaseOffset
                )
            )

        let averagePhaseError =
            (
                phaseError12 +
                phaseError13 +
                phaseError23
            ) / 3.0

        phaseCoherence =
            max(
                0,
                cos(
                    averagePhaseError
                )
            )

        beamUniformity =
            max(
                0,
                min(
                    1,
                    1.0 -
                    averagePhaseError /
                    Double.pi
                )
            )

        // --------------------------------------------------------------------
        // 4. Cavity response
        // --------------------------------------------------------------------

        let resonanceWidth =
            max(
                0.0001,
                1.0 / cavityFinesse
            )

        resonanceFactor =
            1.0 /
            (
                1.0 +
                pow(
                    detuning /
                    resonanceWidth,
                    2.0
                )
            )

        buildupFactor =
            laserOn
            ? 1.0 +
              cavityFinesse *
              resonanceFactor
            : 0

        circulatingPowerW =
            totalLaserPowerW *
            buildupFactor *
            phaseCoherence *
            beamUniformity

        standingWaveStrength =
            laserOn
            ? resonanceFactor *
              phaseCoherence *
              beamUniformity
            : 0

        // --------------------------------------------------------------------
        // 5. QRTL shell threshold behavior
        // --------------------------------------------------------------------

        let safeThreshold =
            max(
                shellInstabilityThreshold,
                0.0001
            )

        shellThresholdFraction =
            min(
                shellResonantAmplitude /
                safeThreshold,
                2.0
            )

        let shellTransitionActive =
            qrtlEnabled &&
            ca40Present &&
            laserOn &&
            resonanceFactor > 0.90 &&
            phaseCoherence > 0.90 &&
            shellResonantAmplitude >=
            safeThreshold

        isNonlinearRegime =
            shellTransitionActive

        if shellTransitionActive {

            let excessAmplitude =
                (
                    shellResonantAmplitude -
                    safeThreshold
                ) / safeThreshold

            resonantShellTransitionRateGPerHr =
                shellTransitionGainGPerHr *
                pow(
                    max(
                        0,
                        excessAmplitude
                    ),
                    2.15
                )

        } else {

            resonantShellTransitionRateGPerHr =
                0
        }

        // --------------------------------------------------------------------
        // 6. Thermal response and modeled gas output
        // --------------------------------------------------------------------

        chamberTemperatureC =
            22.0 +
            min(
                circulatingPowerW *
                0.15,
                60.0
            )

        // Keep this only if you intentionally want a non-QRTL baseline.
        // Set it to zero when testing a pure threshold-only QRTL thesis.
        let baselineRateGPerHr =
            circulatingPowerW *
            0.002

        hydrogenRateGPerHr =
            baselineRateGPerHr +
            resonantShellTransitionRateGPerHr

        oxygenRateGPerHr =
            hydrogenRateGPerHr *
            8.0

        visualFieldIntensity =
            min(
                max(
                    standingWaveStrength *
                    circulatingPowerW /
                    1200.0,
                    0
                ),
                1.0
            )

        // --------------------------------------------------------------------
        // 7. Production and economics
        // --------------------------------------------------------------------

        hydrogenProducedKg =
            hydrogenRateGPerHr *
            elapsedHours /
            1000.0

        oxygenProducedKg =
            oxygenRateGPerHr *
            elapsedHours /
            1000.0

        electricityConsumedKWh =
            totalLaserPowerW *
            elapsedHours /
            1000.0

        electricityCost =
            electricityConsumedKWh *
            QRTLConstants.electricityPricePerKWh

        revenue =
            hydrogenProducedKg *
            sellPricePerKg

        otherOperatingCost =
            hydrogenProducedKg *
            otherOperatingCostPerKg

        totalOperatingCost =
            electricityCost +
            otherOperatingCost

        profit =
            revenue -
            totalOperatingCost

        if hydrogenProducedKg > 0.000001 {

            electricityCostPerKg =
                electricityCost /
                hydrogenProducedKg

            totalCostPerKg =
                totalOperatingCost /
                hydrogenProducedKg

            revenuePerKg =
                revenue /
                hydrogenProducedKg

            profitPerKg =
                profit /
                hydrogenProducedKg

        } else {

            electricityCostPerKg = 0
            totalCostPerKg = 0
            revenuePerKg = 0
            profitPerKg = 0
        }
    }

    // ========================================================================
    // MARK: Phase Normalization
    // ========================================================================

    private func normalizePhase(
        _ phase: Double
    ) -> Double {

        var value = phase

        while value > Double.pi {
            value -= 2.0 * Double.pi
        }

        while value < -Double.pi {
            value += 2.0 * Double.pi
        }

        return value
    }

    // ========================================================================
    // MARK: Reset
    // ========================================================================

    func resetRun() {
        elapsedHours = 0
        shellResonantAmplitude = 0
        shellThresholdFraction = 0
        resonantShellTransitionRateGPerHr = 0
        isNonlinearRegime = false
        lastTickDate = Date()

        recompute()
    }
}

// MARK: - ContentView

struct ContentView: View {

    @StateObject private var monitor =
        MasterMonitor()

    @State private var sheetDetent:
        PresentationDetent = .height(64)

    var body: some View {

        ZStack(alignment: .top) {

            QRTLSceneView(
                monitor: monitor
            )
            .ignoresSafeArea()

            topReadoutStrip
        }
        .sheet(
            isPresented: .constant(true)
        ) {

            controlSheet
                .presentationDetents(
                    [
                        .height(64),
                        .fraction(0.45),
                        .large
                    ],
                    selection: $sheetDetent
                )
                .presentationDragIndicator(
                    .visible
                )
                .presentationBackgroundInteraction(
                    .enabled
                )
                .interactiveDismissDisabled()
        }
    }

    // ========================================================================
    // MARK: Top Readout
    // ========================================================================

    private var topReadoutStrip: some View {

        HStack(spacing: 12) {

            readout(
                "λ",
                String(
                    format: "%.2f µm",
                    monitor.wavelengthMicrometers
                )
            )

            readout(
                "H₂",
                String(
                    format: "%.6f kg",
                    monitor.hydrogenProducedKg
                )
            )

            readout(
                "Electricity",
                String(
                    format: "$%.4f",
                    monitor.electricityCost
                )
            )

            readout(
                "Profit",
                String(
                    format: "$%.2f/kg",
                    monitor.profitPerKg
                )
            )
            .foregroundStyle(
                monitor.profitPerKg >= 0
                ? .green
                : .red
            )

            Spacer()

            if monitor.isNonlinearRegime {

                Label(
                    "QRTL Standing Wave",
                    systemImage: "waveform.path.ecg"
                )
                .font(
                    .caption.bold()
                )
                .foregroundStyle(
                    .yellow
                )
            }
        }
        .padding(
            .horizontal,
            16
        )
        .padding(
            .vertical,
            10
        )
        .background(
            .ultraThinMaterial,
            in: Capsule()
        )
        .padding(
            .horizontal
        )
        .padding(
            .top,
            8
        )
    }

    private func readout(
        _ label: String,
        _ value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 1
        ) {

            Text(label)
                .font(
                    .caption2
                )
                .foregroundStyle(
                    .secondary
                )

            Text(value)
                .font(
                    .system(
                        .caption,
                        design: .monospaced
                    )
                )
                .bold()
        }
    }

    // ========================================================================
    // MARK: Control Sheet
    // ========================================================================

    private var controlSheet: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                HStack {

                    VStack(
                        alignment: .leading,
                        spacing: 2
                    ) {

                        Text(
                            "QRTL Hydrogen Resonator"
                        )
                        .font(
                            .headline
                        )

                        Text(
                            monitor.isNonlinearRegime
                            ? "Three-laser coherent standing-wave regime"
                            : "Baseline / non-resonant regime"
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            monitor.isNonlinearRegime
                            ? .yellow
                            : .secondary
                        )
                    }

                    Spacer()

                    Button(
                        "Reset Run"
                    ) {

                        monitor.resetRun()
                    }
                    .buttonStyle(
                        .bordered
                    )
                }

                physicsReadoutGrid

                Divider()

                Text(
                    "Three-Laser Optical Controls"
                )
                .font(
                    .subheadline.bold()
                )

                VStack(
                    spacing: 14
                ) {

                    sliderRow(
                        "Power / Laser",
                        value: $monitor.laserPowerW,
                        range: 0...50,
                        format: {
                            String(
                                format: "%.0f W",
                                $0
                            )
                        }
                    )

                    sliderRow(
                        "Cavity Detuning",
                        value: $monitor.detuning,
                        range: -1...1,
                        format: {
                            String(
                                format: "%.3f",
                                $0
                            )
                        }
                    )

                    sliderRow(
                        "Cavity Finesse",
                        value: $monitor.cavityFinesse,
                        range: 20...300,
                        format: {
                            String(
                                format: "%.0f",
                                $0
                            )
                        }
                    )

                    sliderRow(
                        "Laser 2 Phase",
                        value: $monitor.laser2PhaseOffset,
                        range: -Double.pi...Double.pi,
                        format: {
                            String(
                                format: "%.3f rad",
                                $0
                            )
                        }
                    )

                    sliderRow(
                        "Laser 3 Phase",
                        value: $monitor.laser3PhaseOffset,
                        range: -Double.pi...Double.pi,
                        format: {
                            String(
                                format: "%.3f rad",
                                $0
                            )
                        }
                    )

                    HStack(
                        spacing: 20
                    ) {

                        Toggle(
                            "Lasers On",
                            isOn: $monitor.laserOn
                        )

                        Toggle(
                            "Ca-40 Loaded",
                            isOn: $monitor.ca40Present
                        )
                    }
                    .toggleStyle(
                        .switch
                    )
                }

                Divider()

                Text(
                    "Hydrogen Economics"
                )
                .font(
                    .subheadline.bold()
                )

                VStack(
                    spacing: 14
                ) {

                    sliderRow(
                        "H₂ Sell Price",
                        value: $monitor.sellPricePerKg,
                        range: 5...50,
                        format: {
                            String(
                                format: "$%.0f/kg",
                                $0
                            )
                        }
                    )

                    sliderRow(
                        "Other Operating Cost",
                        value: $monitor.otherOperatingCostPerKg,
                        range: 0...25,
                        format: {
                            String(
                                format: "$%.0f/kg",
                                $0
                            )
                        }
                    )
                }

                economicsGrid
            }
            .padding()
        }
    }

    // ========================================================================
    // MARK: Physics Grid
    // ========================================================================

    private var physicsReadoutGrid: some View {

        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 10
        ) {

            readoutTile(
                "Wavelength",
                String(
                    format: "%.2f µm",
                    monitor.wavelengthMicrometers
                )
            )

            readoutTile(
                "Frequency",
                String(
                    format: "%.3f THz",
                    monitor.frequencyTHz
                )
            )

            readoutTile(
                "Lasers",
                "3"
            )

            readoutTile(
                "Total Laser Power",
                String(
                    format: "%.0f W",
                    monitor.totalLaserPowerW
                )
            )

            readoutTile(
                "Cavity Buildup",
                String(
                    format: "×%.1f",
                    monitor.buildupFactor
                )
            )

            readoutTile(
                "Resonance",
                String(
                    format: "%.1f%%",
                    monitor.resonanceFactor * 100
                )
            )

            readoutTile(
                "Phase Coherence",
                String(
                    format: "%.1f%%",
                    monitor.phaseCoherence * 100
                )
            )

            readoutTile(
                "Beam Uniformity",
                String(
                    format: "%.1f%%",
                    monitor.beamUniformity * 100
                )
            )

            readoutTile(
                "Standing Wave",
                String(
                    format: "%.1f%%",
                    monitor.standingWaveStrength * 100
                )
            )
        }
    }

    // ========================================================================
    // MARK: Economics Grid
    // ========================================================================

    private var economicsGrid: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text(
                "Production & Profit"
            )
            .font(
                .subheadline.bold()
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 10
            ) {

                readoutTile(
                    "H₂ Rate",
                    String(
                        format: "%.3f g/hr",
                        monitor.hydrogenRateGPerHr
                    )
                )

                readoutTile(
                    "H₂ Produced",
                    String(
                        format: "%.6f kg",
                        monitor.hydrogenProducedKg
                    )
                )

                readoutTile(
                    "Electricity",
                    String(
                        format: "%.5f kWh",
                        monitor.electricityConsumedKWh
                    )
                )

                readoutTile(
                    "Electricity Cost",
                    String(
                        format: "$%.4f",
                        monitor.electricityCost
                    )
                )

                readoutTile(
                    "Electricity / kg",
                    String(
                        format: "$%.2f/kg",
                        monitor.electricityCostPerKg
                    )
                )

                readoutTile(
                    "Revenue",
                    String(
                        format: "$%.4f",
                        monitor.revenue
                    )
                )

                readoutTile(
                    "Total Cost",
                    String(
                        format: "$%.4f",
                        monitor.totalOperatingCost
                    )
                )

                readoutTile(
                    "Total Cost / kg",
                    String(
                        format: "$%.2f/kg",
                        monitor.totalCostPerKg
                    )
                )

                readoutTile(
                    "Profit",
                    String(
                        format: "$%.4f",
                        monitor.profit
                    )
                )

                readoutTile(
                    "Profit / kg H₂",
                    String(
                        format: "$%.2f/kg",
                        monitor.profitPerKg
                    )
                )
            }
        }
    }

    // ========================================================================
    // MARK: Readout Tile
    // ========================================================================

    private func readoutTile(
        _ label: String,
        _ value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 2
        ) {

            Text(label)
                .font(
                    .caption2
                )
                .foregroundStyle(
                    .secondary
                )

            Text(value)
                .font(
                    .system(
                        .footnote,
                        design: .monospaced
                    )
                )
                .bold()
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(8)
        .background(
            .thinMaterial,
            in: RoundedRectangle(
                cornerRadius: 8
            )
        )
    }

    // ========================================================================
    // MARK: Slider
    // ========================================================================

    private func sliderRow(
        _ label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        format: @escaping (Double) -> String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            HStack {

                Text(label)
                    .font(
                        .subheadline
                    )

                Spacer()

                Text(
                    format(
                        value.wrappedValue
                    )
                )
                .font(
                    .caption.monospaced()
                )
                .foregroundStyle(
                    .secondary
                )
            }

            Slider(
                value: value,
                in: range
            )
        }
    }
}

// MARK: - SceneKit Wrapper

struct QRTLSceneView: UIViewRepresentable {

    @ObservedObject var monitor:
        MasterMonitor

    func makeCoordinator()
        -> Coordinator {

        Coordinator(
            monitor: monitor
        )
    }

    func makeUIView(
        context: Context
    ) -> SCNView {

        let scnView = SCNView()

        let scene =
            QRTLSceneBuilder.buildScene()

        scnView.scene =
            scene

        scnView.allowsCameraControl =
            true

        scnView.autoenablesDefaultLighting =
            false

        scnView.backgroundColor =
            UIColor(
                white: 0.04,
                alpha: 1.0
            )

        scnView.delegate =
            context.coordinator

        scnView.isPlaying =
            true

        context.coordinator.attachNodes(
            from: scene
        )

        return scnView
    }

    func updateUIView(
        _ uiView: SCNView,
        context: Context
    ) {

        context.coordinator.monitor =
            monitor
    }

    // ========================================================================
    // MARK: Scene Coordinator
    // ========================================================================

    final class Coordinator:
        NSObject,
        SCNSceneRendererDelegate {

        var monitor:
            MasterMonitor

        var standingWaveNode:
            SCNNode?

        var waveSegmentNodes:
            [SCNNode] = []

        var laserBeamNodes:
            [SCNNode] = []

        var chamberGlowNode:
            SCNNode?

        var bubbleSystem:
            SCNParticleSystem?

        private var startTime:
            TimeInterval = 0

        init(
            monitor: MasterMonitor
        ) {

            self.monitor =
                monitor
        }

        func attachNodes(
            from scene: SCNScene
        ) {

            standingWaveNode =
                scene.rootNode.childNode(
                    withName: "standingWave",
                    recursively: true
                )

            waveSegmentNodes =
                standingWaveNode?
                    .childNodes ?? []

            laserBeamNodes =
                (1...3).compactMap {

                    scene.rootNode.childNode(
                        withName:
                            "laserBeam\($0)",
                        recursively: true
                    )
                }

            chamberGlowNode =
                scene.rootNode.childNode(
                    withName: "chamberGlow",
                    recursively: true
                )

            if let chamber =
                scene.rootNode.childNode(
                    withName:
                        "bubbleEmitter",
                    recursively: true
                ) {

                bubbleSystem =
                    chamber.particleSystems?.first
            }
        }

        func renderer(
            _ renderer: SCNSceneRenderer,
            updateAtTime time: TimeInterval
        ) {

            if startTime == 0 {

                startTime =
                    time
            }

            let t =
                time - startTime

            let intensity =
                monitor.visualFieldIntensity

            let coherence =
                monitor.phaseCoherence

            let nonlinear =
                monitor.isNonlinearRegime

            let phase2 =
                monitor.laser2PhaseOffset

            let phase3 =
                monitor.laser3PhaseOffset

            DispatchQueue.main.async {
                [weak self] in

                guard let self =
                    self
                else {
                    return
                }

                // ============================================================
                // THREE-LASER BEAMS
                // ============================================================

                for (index, beam)
                    in self.laserBeamNodes.enumerated() {

                    let phaseOffset: Double

                    switch index {

                    case 1:
                        phaseOffset =
                            phase2

                    case 2:
                        phaseOffset =
                            phase3

                    default:
                        phaseOffset =
                            0
                    }

                    let pulse =
                        0.4 +
                        0.6 *
                        abs(
                            sin(
                                t * 8.0 +
                                phaseOffset
                            )
                        )

                    beam
                        .geometry?
                        .firstMaterial?
                        .emission
                        .intensity =
                        CGFloat(
                            intensity *
                            pulse *
                            2.0
                        )

                    beam.opacity =
                        self.monitor.laserOn
                        ? CGFloat(
                            0.3 +
                            0.7 *
                            intensity
                        )
                        : 0.05
                }

                // ============================================================
                // STANDING WAVE
                // ============================================================

                for (i, node)
                    in self.waveSegmentNodes
                        .enumerated() {

                    let x =
                        Double(i) /
                        Double(
                            max(
                                1,
                                self.waveSegmentNodes.count - 1
                            )
                        )

                    let phase =
                        x *
                        4.0 *
                        Double.pi

                    let y =
                        sin(
                            t * 6.0 +
                            phase
                        ) *
                        (
                            0.05 +
                            0.35 *
                            intensity *
                            coherence
                        )

                    node.position.y =
                        Float(y)

                    let scale =
                        Float(
                            0.3 +
                            0.9 *
                            intensity *
                            coherence
                        )

                    node.scale =
                        SCNVector3(
                            scale,
                            scale,
                            scale
                        )
                }

                // ============================================================
                // HYDROGEN / OXYGEN BUBBLES
                // ============================================================

                if let bubbles =
                    self.bubbleSystem {

                    let rate =
                        Float(
                            self.monitor
                                .hydrogenRateGPerHr
                        )

                    bubbles.birthRate =
                        CGFloat(
                            min(
                                max(
                                    rate * 400.0,
                                    0
                                ),
                                4000
                            )
                        )

                    bubbles.particleColor =
                        nonlinear
                        ? UIColor.systemYellow
                        : UIColor.systemTeal
                }

                // ============================================================
                // CHAMBER GLOW
                // ============================================================

                if let glow =
                    self.chamberGlowNode {

                    glow.light?.intensity =
                        nonlinear
                        ? CGFloat(
                            1200 +
                            400 *
                            sin(
                                t * 4.0
                            )
                        )
                        : 150

                    glow.light?.color =
                        nonlinear
                        ? UIColor.yellow
                        : UIColor.cyan
                }
            }
        }
    }
}

// MARK: - Scene Builder

enum QRTLSceneBuilder {

    static func buildScene()
        -> SCNScene {

        let scene =
            SCNScene()

        let root =
            scene.rootNode

        addLighting(
            to: root
        )

        addCamera(
            to: root
        )

        addGroundPlatform(
            to: root
        )

        // ====================================================================
        // PIPELINE LAYOUT
        // ====================================================================

        addPowerMeter(
            to: root,
            at: SCNVector3(
                -10,
                0.5,
                0
            )
        )

        addLaserModule(
            to: root,
            at: SCNVector3(
                -7,
                0.5,
                0
            )
        )

        addBeamConditioning(
            to: root,
            at: SCNVector3(
                -4.8,
                0.5,
                0
            )
        )

        addThreeLaserBeams(
            to: root
        )

        addOpticalCavity(
            to: root,
            at: SCNVector3(
                -1.0,
                0.5,
                0
            )
        )

        addInteractionChamber(
            to: root,
            at: SCNVector3(
                2.5,
                0.5,
                0
            )
        )

        addGasSeparation(
            to: root,
            at: SCNVector3(
                5.8,
                0.5,
                0
            )
        )

        addConnectingRail(
            to: root,
            fromX: -10.5,
            toX: 7.2,
            y: 0.05
        )

        addLabel(
            to: root,
            text: "QRTL 3-Laser Hydrogen Resonator",
            at: SCNVector3(
                -3.2,
                3.2,
                0
            )
        )

        return scene
    }

    // ========================================================================
    // MARK: Lighting
    // ========================================================================

    private static func addLighting(
        to root: SCNNode
    ) {

        let ambient =
            SCNNode()

        ambient.light =
            SCNLight()

        ambient.light?.type =
            .ambient

        ambient.light?.intensity =
            250

        ambient.light?.color =
            UIColor(
                white: 0.6,
                alpha: 1.0
            )

        root.addChildNode(
            ambient
        )

        let key =
            SCNNode()

        key.light =
            SCNLight()

        key.light?.type =
            .directional

        key.light?.intensity =
            800

        key.position =
            SCNVector3(
                0,
                10,
                8
            )

        key.eulerAngles =
            SCNVector3(
                -Float.pi / 3,
                0,
                0
            )

        root.addChildNode(
            key
        )
    }

    // ========================================================================
    // MARK: Camera
    // ========================================================================

    private static func addCamera(
        to root: SCNNode
    ) {

        let cameraNode =
            SCNNode()

        cameraNode.camera =
            SCNCamera()

        cameraNode.camera?.zFar =
            100

        cameraNode.position =
            SCNVector3(
                -2,
                5,
                14
            )

        cameraNode.eulerAngles =
            SCNVector3(
                -0.3,
                0,
                0
            )

        root.addChildNode(
            cameraNode
        )
    }

    // ========================================================================
    // MARK: Ground
    // ========================================================================

    private static func addGroundPlatform(
        to root: SCNNode
    ) {

        let floor =
            SCNFloor()

        floor.reflectivity =
            0.05

        let material =
            SCNMaterial()

        material.diffuse.contents =
            UIColor(
                white: 0.08,
                alpha: 1.0
            )

        floor.materials =
            [material]

        let node =
            SCNNode(
                geometry: floor
            )

        root.addChildNode(
            node
        )
    }

    // ========================================================================
    // MARK: Labels
    // ========================================================================

    private static func addLabel(
        to root: SCNNode,
        text: String,
        at position: SCNVector3
    ) {

        let textGeo =
            SCNText(
                string: text,
                extrusionDepth: 0.2
            )

        textGeo.font =
            UIFont.boldSystemFont(
                ofSize: 6
            )

        textGeo.firstMaterial?
            .diffuse.contents =
            UIColor.white

        let node =
            SCNNode(
                geometry: textGeo
            )

        node.scale =
            SCNVector3(
                0.05,
                0.05,
                0.05
            )

        node.position =
            position

        root.addChildNode(
            node
        )
    }

    // ========================================================================
    // MARK: Rail
    // ========================================================================

    private static func addConnectingRail(
        to root: SCNNode,
        fromX: Float,
        toX: Float,
        y: Float
    ) {

        let length =
            CGFloat(
                toX - fromX
            )

        let rail =
            SCNBox(
                width: length,
                height: 0.05,
                length: 0.15,
                chamferRadius: 0.02
            )

        rail.firstMaterial?
            .diffuse.contents =
            UIColor.darkGray

        let node =
            SCNNode(
                geometry: rail
            )

        node.position =
            SCNVector3(
                (fromX + toX) / 2,
                y,
                0
            )

        root.addChildNode(
            node
        )
    }

    // ========================================================================
    // MARK: Power Meter
    // ========================================================================

    private static func addPowerMeter(
        to root: SCNNode,
        at position: SCNVector3
    ) {

        let body =
            SCNBox(
                width: 1.2,
                height: 1.6,
                length: 0.8,
                chamferRadius: 0.05
            )

        body.firstMaterial?
            .diffuse.contents =
            UIColor(
                white: 0.2,
                alpha: 1.0
            )

        let node =
            SCNNode(
                geometry: body
            )

        node.position =
            position

        root.addChildNode(
            node
        )

        addLabel(
            to: root,
            text: "Power Meter",
            at: SCNVector3(
                position.x - 0.7,
                position.y + 1.2,
                position.z
            )
        )
    }

    // ========================================================================
    // MARK: Laser Module
    // ========================================================================

    private static func addLaserModule(
        to root: SCNNode,
        at position: SCNVector3
    ) {

        let housing =
            SCNBox(
                width: 1.8,
                height: 1.0,
                length: 1.0,
                chamferRadius: 0.08
            )

        housing.firstMaterial?
            .diffuse.contents =
            UIColor(
                red: 0.15,
                green: 0.15,
                blue: 0.2,
                alpha: 1
            )

        let node =
            SCNNode(
                geometry: housing
            )

        node.position =
            position

        root.addChildNode(
            node
        )

        addLabel(
            to: root,
            text: "Er:YAG 2.94 µm",
            at: SCNVector3(
                position.x - 0.9,
                position.y + 1.0,
                position.z
            )
        )
    }

    // ========================================================================
    // MARK: Beam Conditioning
    // ========================================================================

    private static func addBeamConditioning(
        to root: SCNNode,
        at position: SCNVector3
    ) {

        for (i, radius) in
            [0.22, 0.16].enumerated() {

            let lens =
                SCNCylinder(
                    radius: radius,
                    height: 0.04
                )

            lens.firstMaterial?
                .diffuse.contents =
                UIColor.cyan
                    .withAlphaComponent(
                        0.5
                    )

            lens.firstMaterial?
                .transparency =
                0.6

            let node =
                SCNNode(
                    geometry: lens
                )

            node.eulerAngles =
                SCNVector3(
                    0,
                    0,
                    Float.pi / 2
                )

            node.position =
                SCNVector3(
                    position.x +
                    Float(i) * 0.5,
                    position.y,
                    position.z
                )

            root.addChildNode(
                node
            )
        }

        addLabel(
            to: root,
            text: "Beam Conditioning",
            at: SCNVector3(
                position.x - 0.9,
                position.y + 0.8,
                position.z
            )
        )
    }

    // ========================================================================
    // MARK: Three Laser Beams
    // ========================================================================

    private static func addThreeLaserBeams(
        to root: SCNNode
    ) {

        let beamStarts: [SCNVector3] = [

            SCNVector3(
                -4.0,
                0.58,
                -0.12
            ),

            SCNVector3(
                -4.0,
                0.50,
                0
            ),

            SCNVector3(
                -4.0,
                0.42,
                0.12
            )
        ]

        let beamEnds: [SCNVector3] = [

            SCNVector3(
                -1.9,
                0.58,
                -0.12
            ),

            SCNVector3(
                -1.9,
                0.50,
                0
            ),

            SCNVector3(
                -1.9,
                0.42,
                0.12
            )
        ]

        for i in 0..<3 {

            let start =
                beamStarts[i]

            let end =
                beamEnds[i]

            let length =
                CGFloat(
                    end.x -
                    start.x
                )

            let beam =
                SCNCylinder(
                    radius: 0.025,
                    height: length
                )

            beam.firstMaterial?
                .diffuse.contents =
                UIColor.red

            beam.firstMaterial?
                .emission.contents =
                UIColor.red

            let node =
                SCNNode(
                    geometry: beam
                )

            node.name =
                "laserBeam\(i + 1)"

            node.eulerAngles =
                SCNVector3(
                    0,
                    0,
                    Float.pi / 2
                )

            node.position =
                SCNVector3(
                    (start.x + end.x) / 2,
                    (start.y + end.y) / 2,
                    (start.z + end.z) / 2
                )

            root.addChildNode(
                node
            )
        }

        addLabel(
            to: root,
            text: "3 Coherent Laser Beams",
            at: SCNVector3(
                -3.8,
                1.4,
                0
            )
        )
    }

    // ========================================================================
    // MARK: Optical Cavity
    // ========================================================================

    private static func addOpticalCavity(
        to root: SCNNode,
        at position: SCNVector3
    ) {

        for dx: Float in
            [-0.9, 0.9] {

            let mirror =
                SCNCylinder(
                    radius: 0.4,
                    height: 0.06
                )

            mirror.firstMaterial?
                .diffuse.contents =
                UIColor(
                    white: 0.85,
                    alpha: 1
                )

            mirror.firstMaterial?
                .metalness.contents =
                1.0

            mirror.firstMaterial?
                .roughness.contents =
                0.05

            let node =
                SCNNode(
                    geometry: mirror
                )

            node.eulerAngles =
                SCNVector3(
                    0,
                    0,
                    Float.pi / 2
                )

            node.position =
                SCNVector3(
                    position.x + dx,
                    position.y,
                    position.z
                )

            root.addChildNode(
                node
            )
        }

        let tube =
            SCNTube(
                innerRadius: 0.42,
                outerRadius: 0.45,
                height: 1.8
            )

        tube.firstMaterial?
            .diffuse.contents =
            UIColor.white
                .withAlphaComponent(
                    0.15
                )

        tube.firstMaterial?
            .transparency =
            0.3

        let tubeNode =
            SCNNode(
                geometry: tube
            )

        tubeNode.eulerAngles =
            SCNVector3(
                0,
                0,
                Float.pi / 2
            )

        tubeNode.position =
            position

        root.addChildNode(
            tubeNode
        )

        // ================================================================
        // Standing-wave visualization
        // ================================================================

        let waveParent =
            SCNNode()

        waveParent.name =
            "standingWave"

        waveParent.position =
            position

        let segments =
            32

        for i in 0..<segments {

            let sphere =
                SCNSphere(
                    radius: 0.05
                )

            sphere.firstMaterial?
                .diffuse.contents =
                UIColor.orange

            sphere.firstMaterial?
                .emission.contents =
                UIColor.orange

            let node =
                SCNNode(
                    geometry: sphere
                )

            let xPos =
                -0.8 +
                (
                    Float(i) /
                    Float(
                        segments - 1
                    )
                ) *
                1.6

            node.position =
                SCNVector3(
                    xPos,
                    0,
                    0
                )

            waveParent.addChildNode(
                node
            )
        }

        root.addChildNode(
            waveParent
        )

        addLabel(
            to: root,
            text: "Resonant Standing Wave",
            at: SCNVector3(
                position.x - 1.1,
                position.y + 1.0,
                position.z
            )
        )
    }

    // ========================================================================
    // MARK: Interaction Chamber
    // ========================================================================

    private static func addInteractionChamber(
        to root: SCNNode,
        at position: SCNVector3
    ) {

        let tank =
            SCNBox(
                width: 1.4,
                height: 1.4,
                length: 1.4,
                chamferRadius: 0.05
            )

        tank.firstMaterial?
            .diffuse.contents =
            UIColor.white
                .withAlphaComponent(
                    0.12
                )

        tank.firstMaterial?
            .transparency =
            0.35

        let tankNode =
            SCNNode(
                geometry: tank
            )

        tankNode.position =
            position

        root.addChildNode(
            tankNode
        )

        let water =
            SCNBox(
                width: 1.3,
                height: 1.0,
                length: 1.3,
                chamferRadius: 0.03
            )

        water.firstMaterial?
            .diffuse.contents =
            UIColor.systemBlue
                .withAlphaComponent(
                    0.5
                )

        water.firstMaterial?
            .transparency =
            0.6

        let waterNode =
            SCNNode(
                geometry: water
            )

        waterNode.name =
            "bubbleEmitter"

        waterNode.position =
            SCNVector3(
                0,
                -0.2,
                0
            )

        tankNode.addChildNode(
            waterNode
        )

        // Ca-40 representation.
        let pellet =
            SCNSphere(
                radius: 0.12
            )

        pellet.firstMaterial?
            .diffuse.contents =
            UIColor.lightGray

        pellet.firstMaterial?
            .metalness.contents =
            0.6

        let pelletNode =
            SCNNode(
                geometry: pellet
            )

        pelletNode.position =
            SCNVector3(
                0,
                -0.2,
                0
            )

        waterNode.addChildNode(
            pelletNode
        )

        // ================================================================
        // Bubble system
        // ================================================================

        let bubbles =
            SCNParticleSystem()

        bubbles.birthRate =
            0

        bubbles.particleLifeSpan =
            1.2

        bubbles.particleSize =
            0.03

        bubbles.particleColor =
            UIColor.systemTeal

        bubbles.emitterShape =
            water

        bubbles.birthDirection =
            .constant

        bubbles.particleVelocity =
            0.4

        bubbles.particleVelocityVariation =
            0.15

        bubbles.acceleration =
            SCNVector3(
                0,
                0.6,
                0
            )

        bubbles.blendMode =
            .additive

        waterNode.addParticleSystem(
            bubbles
        )

        // ================================================================
        // Chamber glow
        // ================================================================

        let glow =
            SCNNode()

        glow.light =
            SCNLight()

        glow.light?.type =
            .omni

        glow.light?.intensity =
            150

        glow.light?.color =
            UIColor.cyan

        glow.name =
            "chamberGlow"

        glow.position =
            position

        root.addChildNode(
            glow
        )

        addLabel(
            to: root,
            text: "QRTL Interaction Chamber",
            at: SCNVector3(
                position.x - 1.1,
                position.y + 1.1,
                position.z
            )
        )

        addLabel(
            to: root,
            text: "H₂O + Ca-40",
            at: SCNVector3(
                position.x - 0.6,
                position.y - 1.0,
                position.z
            )
        )
    }

    // ========================================================================
    // MARK: Gas Separation
    // ========================================================================

    private static func addGasSeparation(
        to root: SCNNode,
        at position: SCNVector3
    ) {

        let h2Tube =
            SCNCylinder(
                radius: 0.25,
                height: 1.6
            )

        h2Tube.firstMaterial?
            .diffuse.contents =
            UIColor.yellow
                .withAlphaComponent(
                    0.3
                )

        h2Tube.firstMaterial?
            .transparency =
            0.5

        let h2Node =
            SCNNode(
                geometry: h2Tube
            )

        h2Node.position =
            SCNVector3(
                position.x,
                position.y + 0.4,
                position.z - 0.4
            )

        root.addChildNode(
            h2Node
        )

        let o2Tube =
            SCNCylinder(
                radius: 0.25,
                height: 1.6
            )

        o2Tube.firstMaterial?
            .diffuse.contents =
            UIColor.systemBlue
                .withAlphaComponent(
                    0.3
                )

        o2Tube.firstMaterial?
            .transparency =
            0.5

        let o2Node =
            SCNNode(
                geometry: o2Tube
            )

        o2Node.position =
            SCNVector3(
                position.x,
                position.y + 0.4,
                position.z + 0.4
            )

        root.addChildNode(
            o2Node
        )

        addLabel(
            to: root,
            text: "H₂ Collection",
            at: SCNVector3(
                position.x - 0.7,
                position.y + 1.4,
                position.z - 0.4
            )
        )

        addLabel(
            to: root,
            text: "O₂ Collection",
            at: SCNVector3(
                position.x - 0.7,
                position.y + 1.4,
                position.z + 0.4
            )
        )
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

