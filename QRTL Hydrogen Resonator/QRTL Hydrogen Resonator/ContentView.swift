
//
//  ContentView.swift
//  QRTL-Hydrogen-Resonator
//
//  ================================================================
//  QRTL HYDROGEN RESONATOR — SIMULATION PIPELINE
//  ================================================================
//
//  PURPOSE
//  -------
//  The simulation models the proposed QRTL experimental sequence:
//
//  ELECTRICAL POWER
//        |
//        v
//  PRECISION POWER MEASUREMENT
//        |
//        v
//  THREE Er:YAG LASERS
//        |
//        |  λ = 2.94 µm
//        |  f = c / λ
//        |  ω = 2πf
//        |  k = 2π / λ
//        v
//  LASER PHOTON / ELECTROMAGNETIC FIELDS
//        |
//        |  amplitude
//        |  phase
//        |  wavelength
//        |  polarization
//        |  propagation direction
//        v
//  THREE-LASER COHERENT FIELD COMBINATION
//        |
//        |  E_total = E1 + E2 + E3
//        v
//  BEAM CONDITIONING / MODE MATCHING
//        |
//        |  spatial beam envelope
//        |  phase alignment
//        |  polarization alignment
//        v
//  HIGH-REFLECTIVITY OPTICAL CAVITY
//        |
//        |  forward wave
//        |  reflected wave
//        v
//  COUNTER-PROPAGATING INTERFERENCE
//        |
//        v
//  2.94 µm STANDING WAVE
//        |
//        |  node spacing = λ / 2 = 1.47 µm
//        v
//  STANDING-WAVE ENERGY DENSITY
//        |
//        |  electromagnetic field energy
//        |  spatial uniformity
//        |  coherence
//        v
//  INTERACTION CHAMBER
//        |
//        |  H₂O
//        |  Ca-40
//        v
//  PROPOSED QRTL ENERGY-SHELL INTERACTION
//        |
//        |  QRTL hypothesis:
//        |  resonant standing-wave field interacts with
//        |  the modeled energy-shell structure.
//        v
//  PROPOSED ENERGY-SHELL DISSIPATION
//        |
//        v
//  H₂ + O₂ RELEASE
//        |
//        v
//  GAS SEPARATION / COLLECTION
//        |
//        v
//  H₂ PRODUCTION RATE
//        |
//        v
//  ENERGY / ECONOMIC ANALYSIS
//
//  IMPORTANT MODELING RULE
//  -----------------------
//  The laser does NOT directly generate hydrogen in this model.
//
//  The laser's primary job is to establish a coherent 2.94 µm
//  electromagnetic field and form a resonant standing wave.
//
//  Hydrogen/oxygen production is downstream of the proposed QRTL
//  energy-shell interaction and is therefore represented as a
//  hypothesis-dependent model quantity.
//
//  THREE-LASER SCALING
//  -------------------
//  The three lasers are modeled as individual coherent field sources:
//
//      E1(x,t) = A1(x) cos(kx - ωt + φ1)
//      E2(x,t) = A2(x) cos(kx - ωt + φ2)
//      E3(x,t) = A3(x) cos(kx - ωt + φ3)
//
//  The combined optical field is:
//
//      E_total = E1 + E2 + E3
//
//  Optical intensity is proportional to:
//
//      I ∝ |E_total|²
//
//  Therefore three lasers are NOT represented simply as:
//
//      power × 3
//
//  Their amplitude, phase, coherence and interference are explicitly
//  represented.
//
//  STANDING-WAVE MODEL
//  -------------------
//  The cavity combines a forward and reflected field:
//
//      E_forward   = A cos(kx - ωt + φ)
//      E_reflected = rA cos(kx + ωt + φr)
//
//  For phase-aligned counter-propagating waves the result approaches
//  a standing-wave spatial structure:
//
//      E_SW(x) ∝ cos(kx + φ)
//
//  For λ = 2.94 µm:
//
//      λ       = 2.94 µm
//      λ / 2   = 1.47 µm
//
//  The simulation therefore resolves the standing-wave structure
//  using the actual optical wavelength rather than a generic sine
//  animation.
//
//  UNIFORMITY
//  ----------
//  The three-laser field is evaluated over the interaction region.
//  The simulation calculates field statistics so that uniformity is
//  measured rather than assumed.
//
//  A useful normalized uniformity metric is:
//
//      uniformity = 1 - σ(I) / mean(I)
//
//  where σ(I) is the spatial standard deviation of intensity.
//
//  A value approaching 1 represents a more spatially uniform field.
//
//  QRTL HYPOTHESIS
//  ---------------
//  The downstream QRTL mechanism remains explicitly identified as a
//  proposed hypothesis. The optical simulation establishes the
//  conditions being proposed for the experiment; it does not claim
//  that shell dissipation or electrolysis enhancement has been
//  experimentally established.
//
//  ================================================================
//

import SwiftUI
import SceneKit
import Combine

// MARK: - Optical Constants

enum QRTLOptics {

    /// Er:YAG wavelength.
    static let wavelengthMeters: Double = 2.94e-6

    /// Speed of light in vacuum.
    static let speedOfLight: Double = 299_792_458.0

    /// Optical frequency.
    static var frequencyHz: Double {
        speedOfLight / wavelengthMeters
    }

    /// Angular frequency.
    static var angularFrequency: Double {
        2.0 * Double.pi * frequencyHz
    }

    /// Vacuum wave number.
    static var waveNumber: Double {
        2.0 * Double.pi / wavelengthMeters
    }

    /// Standing-wave node-to-node spacing.
    static var halfWavelengthMeters: Double {
        wavelengthMeters / 2.0
    }

    /// Photon energy.
    static var photonEnergyJ: Double {
        let h = 6.62607015e-34
        return h * frequencyHz
    }
}

// MARK: - Laser Field

struct QRTLLaserField {

    let opticalPowerW: Double
    let phaseRadians: Double
    let amplitudeScale: Double

    /// All three lasers are required to operate at 2.94 µm.
    let wavelengthMeters: Double = QRTLOptics.wavelengthMeters

    /// Electric-field-like normalized amplitude.
    ///
    /// The simulation uses a normalized field amplitude because the
    /// actual cavity geometry and beam cross-sectional area determine
    /// the physical SI electric-field amplitude.
    var amplitude: Double {
        sqrt(max(opticalPowerW, 0.0)) * amplitudeScale
    }

    /// Forward-propagating coherent field.
    func forwardField(
        positionMeters: Double,
        time: Double
    ) -> Double {

        let phase =
            QRTLOptics.waveNumber * positionMeters
            - QRTLOptics.angularFrequency * time
            + phaseRadians

        return amplitude * cos(phase)
    }

    /// Reflected/counter-propagating field.
    func reflectedField(
        positionMeters: Double,
        time: Double,
        reflectivity: Double
    ) -> Double {

        let reflectionAmplitude =
            sqrt(max(reflectivity, 0.0))

        let phase =
            QRTLOptics.waveNumber * positionMeters
            + QRTLOptics.angularFrequency * time
            + phaseRadians

        return amplitude * reflectionAmplitude * cos(phase)
    }
}

// MARK: - Standing Wave Sample

struct QRTLStandingWaveSample {
    let positionMeters: Double
    let field: Double
    let intensity: Double
}

// MARK: - Optical Field Model

struct QRTLThreeLaserFieldModel {

    let lasers: [QRTLLaserField]

    /// Effective cavity reflectivity.
    let mirrorReflectivity: Double

    /// Spatial envelope.
    let beamUniformity: Double

    func combinedForwardField(
        positionMeters: Double,
        time: Double
    ) -> Double {

        let envelope = max(0.0, min(1.0, beamUniformity))

        return lasers.reduce(0.0) { result, laser in
            result + laser.forwardField(
                positionMeters: positionMeters,
                time: time
            ) * envelope
        }
    }

    func combinedReflectedField(
        positionMeters: Double,
        time: Double
    ) -> Double {

        let envelope = max(0.0, min(1.0, beamUniformity))

        return lasers.reduce(0.0) { result, laser in
            result + laser.reflectedField(
                positionMeters: positionMeters,
                time: time,
                reflectivity: mirrorReflectivity
            ) * envelope
        }
    }

    func standingWaveField(
        positionMeters: Double,
        time: Double
    ) -> Double {

        combinedForwardField(
            positionMeters: positionMeters,
            time: time
        )
        +
        combinedReflectedField(
            positionMeters: positionMeters,
            time: time
        )
    }

    func intensity(
        positionMeters: Double,
        time: Double
    ) -> Double {

        let field = standingWaveField(
            positionMeters: positionMeters,
            time: time
        )

        return field * field
    }

    /// Samples the standing wave across the interaction region.
    func samples(
        lengthMeters: Double,
        count: Int,
        time: Double
    ) -> [QRTLStandingWaveSample] {

        guard count > 1 else {
            return []
        }

        return (0..<count).map { index in

            let fraction =
                Double(index) / Double(count - 1)

            let position =
                fraction * lengthMeters

            let field =
                standingWaveField(
                    positionMeters: position,
                    time: time
                )

            return QRTLStandingWaveSample(
                positionMeters: position,
                field: field,
                intensity: field * field
            )
        }
    }

    /// Calculates normalized spatial intensity uniformity.
    func uniformity(
        lengthMeters: Double,
        count: Int,
        time: Double
    ) -> Double {

        let values = samples(
            lengthMeters: lengthMeters,
            count: count,
            time: time
        ).map(\.intensity)

        guard !values.isEmpty else {
            return 0
        }

        let mean =
            values.reduce(0.0, +) / Double(values.count)

        guard mean > 0 else {
            return 0
        }

        let variance =
            values.reduce(0.0) {
                $0 + pow($1 - mean, 2)
            } / Double(values.count)

        let standardDeviation = sqrt(variance)

        return max(
            0.0,
            min(
                1.0,
                1.0 - standardDeviation / mean
            )
        )
    }
}

// MARK: - Master Monitor

final class MasterMonitor: ObservableObject {

    // MARK: Laser Controls

    @Published var laserPowerW: Double = 20.0 {
        didSet { recompute() }
    }

    @Published var laser2PowerW: Double = 20.0 {
        didSet { recompute() }
    }

    @Published var laser3PowerW: Double = 20.0 {
        didSet { recompute() }
    }

    @Published var phase2Radians: Double = 0.0 {
        didSet { recompute() }
    }

    @Published var phase3Radians: Double = 0.0 {
        didSet { recompute() }
    }

    /// Cavity detuning expressed as a normalized control.
    @Published var detuning: Double = 0.0 {
        didSet { recompute() }
    }

    @Published var ca40Present: Bool = true {
        didSet { recompute() }
    }

    @Published var laserOn: Bool = true {
        didSet { recompute() }
    }

    @Published var cavityFinesse: Double = 180.0 {
        didSet { recompute() }
    }

    @Published var otherOperatingCostPerKg: Double = 10.0 {
        didSet { recompute() }
    }

    @Published var sellPricePerKg: Double = 26.0 {
        didSet { recompute() }
    }

    let electricityPricePerKWh: Double = 0.184

    // MARK: Optical Outputs

    @Published private(set) var opticalFrequencyTHz: Double = 0
    @Published private(set) var photonEnergyJ: Double = 0
    @Published private(set) var totalLaserPowerW: Double = 0
    @Published private(set) var circulatingPowerW: Double = 0
    @Published private(set) var buildupFactor: Double = 0

    @Published private(set) var standingWaveIntensity: Double = 0
    @Published private(set) var standingWaveUniformity: Double = 0
    @Published private(set) var phaseCoherence: Double = 0

    @Published private(set) var chamberTemperatureC: Double = 22.0

    // MARK: Proposed QRTL Outputs

    @Published private(set) var shellDissipationIndex: Double = 0
    @Published private(set) var hydrogenRateGPerHr: Double = 0
    @Published private(set) var oxygenRateGPerHr: Double = 0
    @Published private(set) var isNonlinearRegime: Bool = false

    // MARK: Economics

    @Published private(set) var wattHoursConsumed: Double = 0
    @Published private(set) var kWhPerKgH2: Double = 0
    @Published private(set) var electricityCostPerKg: Double = 0
    @Published private(set) var totalCostPerKg: Double = 0
    @Published private(set) var profitPerKg: Double = 0

    // MARK: Visualization

    @Published private(set) var visualFieldIntensity: Double = 0

    private var elapsedHours: Double = 0
    private var timer: AnyCancellable?

    // Interaction-region length represented in the optical model.
    let interactionLengthMeters: Double = 30.0e-6

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

    // MARK: Laser Field

    private var opticalField: QRTLThreeLaserFieldModel {

        let activeMultiplier = laserOn ? 1.0 : 0.0

        let lasers = [

            QRTLLaserField(
                opticalPowerW: laserPowerW * activeMultiplier,
                phaseRadians: 0.0,
                amplitudeScale: 1.0
            ),

            QRTLLaserField(
                opticalPowerW: laser2PowerW * activeMultiplier,
                phaseRadians: phase2Radians,
                amplitudeScale: 1.0
            ),

            QRTLLaserField(
                opticalPowerW: laser3PowerW * activeMultiplier,
                phaseRadians: phase3Radians,
                amplitudeScale: 1.0
            )
        ]

        let reflectivity =
            cavityReflectivity()

        return QRTLThreeLaserFieldModel(
            lasers: lasers,
            mirrorReflectivity: reflectivity,
            beamUniformity: 1.0
        )
    }

    private func cavityReflectivity() -> Double {

        let finesse =
            max(cavityFinesse, 1.0)

        // Approximate high-reflectivity cavity relation.
        let r =
            1.0
            - Double.pi / finesse

        return max(
            0.0,
            min(0.999999, r * r)
        )
    }

    private func cavityBuildUp() -> Double {

        let x =
            2.0 * cavityFinesse * detuning / Double.pi

        return
            laserOn
            ? cavityFinesse / (1.0 + x * x)
            : 0.0
    }

    // MARK: Recompute

    private func recompute() {

        opticalFrequencyTHz =
            QRTLOptics.frequencyHz / 1.0e12

        photonEnergyJ =
            QRTLOptics.photonEnergyJ

        totalLaserPowerW =
            laserPowerW
            + laser2PowerW
            + laser3PowerW

        buildupFactor =
            cavityBuildUp()

        circulatingPowerW =
            totalLaserPowerW * buildupFactor

        // Sample the actual optical standing-wave field.
        let model = opticalField

        let centerPosition =
            interactionLengthMeters / 2.0

        standingWaveIntensity =
            model.intensity(
                positionMeters: centerPosition,
                time: 0
            )

        standingWaveUniformity =
            model.uniformity(
                lengthMeters: interactionLengthMeters,
                count: 256,
                time: 0
            )

        // Phase coherence is highest when all three sources
        // approach the same phase.
        let phaseError =
            abs(phase2Radians)
            + abs(phase3Radians)

        phaseCoherence =
            max(
                0.0,
                min(
                    1.0,
                    cos(phaseError / 2.0)
                )
            )

        // Normalize optical field for visualization.
        visualFieldIntensity =
            max(
                0.0,
                min(
                    1.0,
                    circulatingPowerW / 3600.0
                )
            )

        // Simple absorption/heating visualization.
        chamberTemperatureC =
            22.0
            + min(
                circulatingPowerW * 0.05,
                60.0
            )

        // --------------------------------------------------------
        // PROPOSED QRTL INTERACTION
        // --------------------------------------------------------
        //
        // This is deliberately separated from the optical model.
        // The optical simulation establishes the resonant field.
        //
        // The following represents the proposed QRTL hypothesis:
        // sufficiently strong coherent standing-wave energy can
        // produce an energy-shell dissipation channel when the
        // interaction conditions are satisfied.
        //

        let resonant =
            abs(detuning) < 0.08

        let strongField =
            circulatingPowerW > 400.0

        let coherent =
            phaseCoherence > 0.90

        if ca40Present && resonant && strongField && coherent {

            let excess =
                (circulatingPowerW - 400.0) / 400.0

            let opticalFactor =
                max(0.0, excess)

            shellDissipationIndex =
                min(
                    1.0,
                    pow(opticalFactor, 1.5)
                    * phaseCoherence
                    * max(
                        0.0,
                        standingWaveUniformity
                    )
                )

            isNonlinearRegime =
                shellDissipationIndex > 0.01

        } else {

            shellDissipationIndex = 0
            isNonlinearRegime = false
        }

        // Proposed shell-dissipation-to-gas-release mapping.
        //
        // This is a model hypothesis, not an experimentally
        // established conversion law.

        let baselineRate =
            circulatingPowerW * 0.002

        let qrtlRate =
            0.02
            * pow(
                max(shellDissipationIndex, 0.0),
                1.2
            )

        hydrogenRateGPerHr =
            baselineRate + qrtlRate

        // Stoichiometric mass ratio for water splitting:
        //
        // 2H₂O -> 2H₂ + O₂
        //
        // Oxygen mass is approximately 8 times hydrogen mass.

        oxygenRateGPerHr =
            hydrogenRateGPerHr * 8.0

        // MARK: Economics

        let gramsSoFar =
            hydrogenRateGPerHr * elapsedHours

        if gramsSoFar > 0.0001 {

            let kgSoFar =
                gramsSoFar / 1000.0

            kWhPerKgH2 =
                (wattHoursConsumed / 1000.0)
                / kgSoFar

        } else {

            kWhPerKgH2 = 0
        }

        electricityCostPerKg =
            kWhPerKgH2
            * electricityPricePerKWh

        totalCostPerKg =
            electricityCostPerKg
            + otherOperatingCostPerKg

        profitPerKg =
            sellPricePerKg
            - totalCostPerKg
    }

    // MARK: Timer

    private func tick() {

        elapsedHours +=
            1.0 / 3600.0

        if laserOn {

            wattHoursConsumed +=
                totalLaserPowerW
                * (1.0 / 3600.0)
        }

        recompute()
    }

    func resetRun() {

        elapsedHours = 0
        wattHoursConsumed = 0

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
                        .fraction(0.4),
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

    // MARK: Top Readout

    private var topReadoutStrip: some View {

        HStack(spacing: 12) {

            readout(
                "λ",
                "2.94 µm"
            )

            readout(
                "Lasers",
                "3"
            )

            readout(
                "Field",
                String(
                    format: "%.0f W",
                    monitor.circulatingPowerW
                )
            )

            readout(
                "Uniformity",
                String(
                    format: "%.0f%%",
                    monitor.standingWaveUniformity * 100.0
                )
            )

            Spacer()

            if monitor.isNonlinearRegime {

                Label(
                    "QRTL",
                    systemImage: "bolt.fill"
                )
                .font(.caption.bold())
                .foregroundStyle(.yellow)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            .ultraThinMaterial,
            in: Capsule()
        )
        .padding(.horizontal)
        .padding(.top, 8)
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
                .font(.caption2)
                .foregroundStyle(.secondary)

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

    // MARK: Control Sheet

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
                        .font(.headline)

                        Text(
                            monitor.isNonlinearRegime
                            ? "Resonant standing-wave / proposed QRTL regime"
                            : "Optical standing-wave system"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            monitor.isNonlinearRegime
                            ? .yellow
                            : .secondary
                        )
                    }

                    Spacer()

                    Button("Reset Run") {

                        monitor.resetRun()

                    }
                    .buttonStyle(.bordered)
                }

                opticalReadoutGrid

                Divider()

                Text("Three-Laser Controls")
                    .font(.subheadline.bold())

                VStack(spacing: 14) {

                    sliderRow(
                        "Laser 1 Power",
                        value: $monitor.laserPowerW,
                        range: 0...50,
                        format: {
                            "\(Int($0)) W"
                        }
                    )

                    sliderRow(
                        "Laser 2 Power",
                        value: $monitor.laser2PowerW,
                        range: 0...50,
                        format: {
                            "\(Int($0)) W"
                        }
                    )

                    sliderRow(
                        "Laser 3 Power",
                        value: $monitor.laser3PowerW,
                        range: 0...50,
                        format: {
                            "\(Int($0)) W"
                        }
                    )

                    sliderRow(
                        "Laser 2 Phase",
                        value: $monitor.phase2Radians,
                        range: -Double.pi...Double.pi,
                        format: {
                            String(
                                format: "%.2f rad",
                                $0
                            )
                        }
                    )

                    sliderRow(
                        "Laser 3 Phase",
                        value: $monitor.phase3Radians,
                        range: -Double.pi...Double.pi,
                        format: {
                            String(
                                format: "%.2f rad",
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
                            "\(Int($0))"
                        }
                    )

                    HStack(spacing: 20) {

                        Toggle(
                            "Laser On",
                            isOn: $monitor.laserOn
                        )

                        Toggle(
                            "Ca-40",
                            isOn: $monitor.ca40Present
                        )
                    }
                    .toggleStyle(.switch)
                }

                Divider()

                Text("Economics")
                    .font(.subheadline.bold())

                sliderRow(
                    "Sell Price",
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
                    "Other Op. Cost",
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
            .padding()
        }
    }

    // MARK: Readout Grid

    private var opticalReadoutGrid: some View {

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
                "2.94 µm"
            )

            readoutTile(
                "Frequency",
                String(
                    format: "%.3f THz",
                    monitor.opticalFrequencyTHz
                )
            )

            readoutTile(
                "Photon Energy",
                String(
                    format: "%.3e J",
                    monitor.photonEnergyJ
                )
            )

            readoutTile(
                "Circulating",
                String(
                    format: "%.0f W",
                    monitor.circulatingPowerW
                )
            )

            readoutTile(
                "Uniformity",
                String(
                    format: "%.1f%%",
                    monitor.standingWaveUniformity * 100
                )
            )

            readoutTile(
                "Coherence",
                String(
                    format: "%.1f%%",
                    monitor.phaseCoherence * 100
                )
            )

            readoutTile(
                "Shell Dissipation",
                String(
                    format: "%.3f",
                    monitor.shellDissipationIndex
                )
            )

            readoutTile(
                "H₂",
                String(
                    format: "%.3f g/hr",
                    monitor.hydrogenRateGPerHr
                )
            )

            readoutTile(
                "O₂",
                String(
                    format: "%.3f g/hr",
                    monitor.oxygenRateGPerHr
                )
            )

            readoutTile(
                "Energy",
                String(
                    format: "%.1f kWh/kg",
                    monitor.kWhPerKgH2
                )
            )

            readoutTile(
                "Total Cost",
                String(
                    format: "$%.2f/kg",
                    monitor.totalCostPerKg
                )
            )

            readoutTile(
                "Profit",
                String(
                    format: "$%.2f/kg",
                    monitor.profitPerKg
                )
            )
        }
    }

    private func readoutTile(
        _ label: String,
        _ value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 2
        ) {

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

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
                    .font(.subheadline)

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

// MARK: - SceneKit View

struct QRTLSceneView: UIViewRepresentable {

    @ObservedObject var monitor:
        MasterMonitor

    func makeCoordinator() -> Coordinator {

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

        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        scnView.backgroundColor =
            UIColor(
                white: 0.04,
                alpha: 1.0
            )

        scnView.delegate =
            context.coordinator

        scnView.isPlaying = true

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

    final class Coordinator:
        NSObject,
        SCNSceneRendererDelegate {

        var monitor:
            MasterMonitor

        weak var standingWaveNode:
            SCNNode?

        var waveSegmentNodes:
            [SCNNode] = []

        var laserNodes:
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

            self.monitor = monitor
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
                standingWaveNode?.childNodes ?? []

            laserNodes = [

                scene.rootNode.childNode(
                    withName: "laserBeam1",
                    recursively: true
                ),

                scene.rootNode.childNode(
                    withName: "laserBeam2",
                    recursively: true
                ),

                scene.rootNode.childNode(
                    withName: "laserBeam3",
                    recursively: true
                )
            ]
            .compactMap { $0 }

            chamberGlowNode =
                scene.rootNode.childNode(
                    withName: "chamberGlow",
                    recursively: true
                )

            if let chamber =
                scene.rootNode.childNode(
                    withName: "bubbleEmitter",
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
                startTime = time
            }

            let t =
                time - startTime

            let monitor =
                self.monitor

            let intensity =
                monitor.visualFieldIntensity

            let nonlinear =
                monitor.isNonlinearRegime

            let phase2 =
                monitor.phase2Radians

            let phase3 =
                monitor.phase3Radians

            DispatchQueue.main.async {

                // ------------------------------------------------
                // THREE COHERENT LASER BEAMS
                // ------------------------------------------------

                let powers = [
                    monitor.laserPowerW,
                    monitor.laser2PowerW,
                    monitor.laser3PowerW
                ]

                let phases = [
                    0.0,
                    phase2,
                    phase3
                ]

                for i in 0..<self.laserNodes.count {

                    let node =
                        self.laserNodes[i]

                    let normalizedPower =
                        min(
                            1.0,
                            max(
                                0.0,
                                powers[i] / 50.0
                            )
                        )

                    let phase =
                        phases[i]

                    let coherence =
                        0.5
                        + 0.5
                        * cos(phase)

                    let pulse =
                        0.75
                        + 0.25
                        * sin(
                            t
                            * 8.0
                            + Double(i)
                        )

                    node.opacity =
                        monitor.laserOn
                        ? CGFloat(
                            0.2
                            + 0.8
                            * normalizedPower
                        )
                        : 0.02

                    node.geometry?
                        .firstMaterial?
                        .emission
                        .intensity =
                        CGFloat(
                            normalizedPower
                            * pulse
                            * (0.5 + coherence)
                            * 3.0
                        )
                }

                // ------------------------------------------------
                // PHYSICAL STANDING-WAVE VISUALIZATION
                // ------------------------------------------------

                for (i, node)
                    in self.waveSegmentNodes.enumerated() {

                    let fraction =
                        Double(i)
                        / Double(
                            max(
                                self.waveSegmentNodes.count - 1,
                                1
                            )
                        )

                    let spatialPhase =
                        2.0
                        * Double.pi
                        * fraction
                        * 12.0

                    let temporalPhase =
                        QRTLOptics.angularFrequency
                        .truncatingRemainder(
                            dividingBy:
                                2.0
                                * Double.pi
                        )
                        * t

                    let wave =
                        sin(
                            spatialPhase
                            + temporalPhase
                        )

                    let amplitude =
                        0.08
                        + 0.42
                        * intensity

                    node.position.y =
                        Float(
                            wave
                            * amplitude
                        )

                    let scale =
                        Float(
                            0.25
                            + 1.2
                            * intensity
                        )

                    node.scale =
                        SCNVector3(
                            scale,
                            scale,
                            scale
                        )
                }

                // ------------------------------------------------
                // CHAMBER
                // ------------------------------------------------

                if let glow =
                    self.chamberGlowNode {

                    glow.light?.intensity =
                        nonlinear
                        ? CGFloat(
                            1000
                            + 600
                            * sin(t * 4.0)
                        )
                        : CGFloat(
                            150
                        )

                    glow.light?.color =
                        nonlinear
                        ? UIColor.yellow
                        : UIColor.cyan
                }

                if let bubbles =
                    self.bubbleSystem {

                    let rate =
                        Float(
                            monitor.hydrogenRateGPerHr
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
                        ? UIColor.yellow
                        : UIColor.systemTeal
                }
            }
        }
    }
}

// MARK: - Scene Builder

enum QRTLSceneBuilder {

    static func buildScene() -> SCNScene {

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

        addPowerMeter(
            to: root,
            at: SCNVector3(
                -9,
                0.5,
                0
            )
        )

        addLaserModule(
            to: root,
            at: SCNVector3(
                -6.5,
                0.5,
                0
            ),
            name: "Laser 1"
        )

        addLaserModule(
            to: root,
            at: SCNVector3(
                -6.5,
                1.8,
                0
            ),
            name: "Laser 2"
        )

        addLaserModule(
            to: root,
            at: SCNVector3(
                -6.5,
                -0.8,
                0
            ),
            name: "Laser 3"
        )

        addBeamConditioning(
            to: root,
            at: SCNVector3(
                -4.5,
                0.5,
                0
            )
        )

        addLaserBeam(
            to: root,
            from: SCNVector3(
                -4.0,
                0.5,
                0
            ),
            to: SCNVector3(
                -2.2,
                0.5,
                0
            ),
            name: "laserBeam1"
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
                2.0,
                0.5,
                0
            )
        )

        addGasSeparation(
            to: root,
            at: SCNVector3(
                5.0,
                0.5,
                0
            )
        )

        addConnectingRail(
            to: root,
            fromX: -9.5,
            toX: 6.5,
            y: 0.05
        )

        addLabel(
            to: root,
            text: "QRTL Hydrogen Resonator",
            at: SCNVector3(
                -2,
                3.2,
                0
            )
        )

        return scene
    }

    // MARK: Environment

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
                alpha: 1
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
                12
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
                alpha: 1
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

    // MARK: Power Meter

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
                alpha: 1
            )

        let node =
            SCNNode(
                geometry: body
            )

        node.position =
            position

        let dial =
            SCNCylinder(
                radius: 0.35,
                height: 0.05
            )

        dial.firstMaterial?
            .diffuse.contents =
            UIColor.black

        dial.firstMaterial?
            .emission.contents =
            UIColor.green

        let dialNode =
            SCNNode(
                geometry: dial
            )

        dialNode.eulerAngles =
            SCNVector3(
                Float.pi / 2,
                0,
                0
            )

        dialNode.position =
            SCNVector3(
                0,
                0.3,
                0.45
            )

        node.addChildNode(
            dialNode
        )

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

    // MARK: Laser

    private static func addLaserModule(
        to root: SCNNode,
        at position: SCNVector3,
        name: String
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

        for i in 0..<4 {

            let fin =
                SCNBox(
                    width: 0.05,
                    height: 0.9,
                    length: 0.9,
                    chamferRadius: 0
                )

            fin.firstMaterial?
                .diffuse.contents =
                UIColor.lightGray

            let finNode =
                SCNNode(
                    geometry: fin
                )

            finNode.position =
                SCNVector3(
                    -0.9
                    + Float(i) * 0.06,
                    0,
                    0
                )

            node.addChildNode(
                finNode
            )
        }

        let aperture =
            SCNCylinder(
                radius: 0.08,
                height: 0.05
            )

        aperture.firstMaterial?
            .diffuse.contents =
            UIColor.red

        aperture.firstMaterial?
            .emission.contents =
            UIColor.red

        let apertureNode =
            SCNNode(
                geometry: aperture
            )

        apertureNode.eulerAngles =
            SCNVector3(
                0,
                0,
                Float.pi / 2
            )

        apertureNode.position =
            SCNVector3(
                0.95,
                0,
                0
            )

        node.addChildNode(
            apertureNode
        )

        root.addChildNode(
            node
        )

        addLabel(
            to: root,
            text: name + " — 2.94 µm",
            at: SCNVector3(
                position.x - 0.9,
                position.y + 1.0,
                position.z
            )
        )
    }

    // MARK: Beam Conditioning

    private static func addBeamConditioning(
        to root: SCNNode,
        at position: SCNVector3
    ) {

        for (i, r)
            in [0.22, 0.16].enumerated() {

            let lens =
                SCNCylinder(
                    radius: r,
                    height: 0.04
                )

            lens.firstMaterial?
                .diffuse.contents =
                UIColor.cyan
                    .withAlphaComponent(0.5)

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
                    position.x
                    + Float(i) * 0.5,
                    position.y,
                    position.z
                )

            root.addChildNode(
                node
            )
        }
    }

    private static func addLaserBeam(
        to root: SCNNode,
        from: SCNVector3,
        to: SCNVector3,
        name: String
    ) {

        let length =
            CGFloat(
                to.x - from.x
            )

        let beam =
            SCNCylinder(
                radius: 0.03,
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
            name

        node.eulerAngles =
            SCNVector3(
                0,
                0,
                Float.pi / 2
            )

        node.position =
            SCNVector3(
                (from.x + to.x) / 2,
                from.y,
                from.z
            )

        root.addChildNode(
            node
        )
    }

    // MARK: Optical Cavity

    private static func addOpticalCavity(
        to root: SCNNode,
        at position: SCNVector3
    ) {

        for dx: Float
            in [-0.9, 0.9] {

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
                .withAlphaComponent(0.15)

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

        // --------------------------------------------------------
        // Standing-wave visualization.
        //
        // The real wavelength is 2.94 µm. SceneKit cannot render
        // a literal 2.94 µm structure at this scene scale, so the
        // node spacing is a visual representation of the calculated
        // standing-wave phase rather than a claim about physical
        // SceneKit scale.
        // --------------------------------------------------------

        let waveParent =
            SCNNode()

        waveParent.name =
            "standingWave"

        waveParent.position =
            position

        let segments =
            64

        for i in 0..<segments {

            let sphere =
                SCNSphere(
                    radius: 0.035
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
                -0.8
                + (
                    Float(i)
                    / Float(segments - 1)
                )
                * 1.6

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
            text: "2.94 µm Resonant Standing Wave",
            at: SCNVector3(
                position.x - 1.3,
                position.y + 1.0,
                position.z
            )
        )
    }

    // MARK: Interaction Chamber

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
                .withAlphaComponent(0.12)

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
                .withAlphaComponent(0.5)

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
                position.x,
                position.y - 0.2,
                position.z
            )

        tankNode.addChildNode(
            waterNode
        )

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
            text: "Interaction Chamber (H₂O + Ca-40)",
            at: SCNVector3(
                position.x - 1.1,
                position.y + 1.1,
                position.z
            )
        )
    }

    // MARK: Gas Separation

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
                .withAlphaComponent(0.3)

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
                .withAlphaComponent(0.3)

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
            text: "H₂ / O₂ Separation",
            at: SCNVector3(
                position.x - 0.9,
                position.y + 1.4,
                position.z
            )
        )
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

