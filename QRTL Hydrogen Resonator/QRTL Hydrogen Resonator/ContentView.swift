//
//  ContentView.swift
//  QRTL-Hydrogen-Resonator
//
//  3D simulation of the proposed QRTL experimental pipeline:
//  Power Meter -> Er:YAG 2.94 µm Laser -> Beam Conditioning ->
//  High-Reflectivity Optical Cavity (standing wave) -> Interaction
//  Chamber (water + Ca-40) -> Gas Separation (H2 / O2) -> Economics.
//
//  The QRTL coupling itself is treated as a testable hypothesis, not
//  an established mechanism: the model only produces a nonlinear
//  hydrogen response when (a) the cavity is on resonance and
//  (b) Ca-40 is present in the chamber. Every other condition
//  (off resonance, no Ca-40, laser off) yields the ordinary
//  linear/near-zero baseline, mirroring the control structure in
//  the spec.
//

import SwiftUI
import SceneKit
import Combine

// MARK: - MasterMonitor

/// Central ObservableObject driving both the SceneKit scene and the
/// SwiftUI HUD. All simulated quantities live here so the 3D view and
/// the readouts panel stay in sync.
final class MasterMonitor: ObservableObject {

    // MARK: Operator controls

    /// Laser output power in watts (electrical-to-optical, simplified).
    @Published var laserPowerW: Double = 20.0 {
        didSet { recompute() }
    }

    /// Cavity detuning, -1...1, where 0.0 is perfect resonance.
    @Published var detuning: Double = 0.0 {
        didSet { recompute() }
    }

    /// Whether the Ca-40 sample is loaded in the interaction chamber.
    @Published var ca40Present: Bool = true {
        didSet { recompute() }
    }

    /// Whether the laser is energized at all (master control run).
    @Published var laserOn: Bool = true {
        didSet { recompute() }
    }

    /// Effective cavity finesse (mirror quality). Higher = sharper,
    /// taller resonance buildup.
    @Published var cavityFinesse: Double = 180.0 {
        didSet { recompute() }
    }

    /// Non-electric operating cost assumption, $/kg H2 (purification,
    /// compression, maintenance, depreciation, etc).
    @Published var otherOperatingCostPerKg: Double = 10.0 {
        didSet { recompute() }
    }

    /// Assumed hydrogen selling price, $/kg.
    @Published var sellPricePerKg: Double = 26.0 {
        didSet { recompute() }
    }

    /// Electricity price, $/kWh.
    let electricityPricePerKWh: Double = 0.184

    // MARK: Derived / measured quantities (read-only outputs)

    @Published private(set) var circulatingPowerW: Double = 0
    @Published private(set) var buildupFactor: Double = 0
    @Published private(set) var chamberTemperatureC: Double = 22.0
    @Published private(set) var hydrogenRateGPerHr: Double = 0
    @Published private(set) var wattHoursConsumed: Double = 0
    @Published private(set) var kWhPerKgH2: Double = 0
    @Published private(set) var electricityCostPerKg: Double = 0
    @Published private(set) var totalCostPerKg: Double = 0
    @Published private(set) var profitPerKg: Double = 0
    @Published private(set) var isNonlinearRegime: Bool = false

    /// 0...1 visual intensity used to drive the standing-wave nodes
    /// and bubble emission rate in the SceneKit scene.
    @Published private(set) var visualFieldIntensity: Double = 0

    private var elapsedHours: Double = 0
    private var timer: AnyCancellable?

    init() {
        recompute()
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        elapsedHours += 1.0 / 3600.0
        wattHoursConsumed += (laserOn ? laserPowerW : 0) * (1.0 / 3600.0)
        recompute()
    }

    /// Recomputes every derived quantity from the current controls.
    /// This encodes the spec's hypothesis-testing structure: a
    /// Lorentzian cavity buildup around resonance, and a hydrogen
    /// response that only turns nonlinear when the field is strong,
    /// on resonance, AND Ca-40 is present. Every other combination
    /// falls back to a small linear/thermal baseline.
    private func recompute() {
        // Lorentzian-style cavity buildup peaking at detuning == 0.
        let x = 2.0 * cavityFinesse * detuning / .pi
        buildupFactor = laserOn ? cavityFinesse / (1.0 + x * x) : 0
        circulatingPowerW = laserPowerW * buildupFactor

        // Simple absorption heating model (2.94 µm is strongly
        // absorbed by water) -- rises with circulating power.
        chamberTemperatureC = 22.0 + min(circulatingPowerW * 0.15, 60.0)

        // Baseline (ordinary IR heating / thermal chemistry) response:
        // small and strictly linear in circulating power.
        let baselineRateGPerHr = circulatingPowerW * 0.002

        // Proposed QRTL nonlinear channel: only active near resonance
        // AND with Ca-40 present, and only above a threshold field.
        let onResonance = abs(detuning) < 0.08
        let threshold = 400.0 // watts, circulating
        var qrtlRateGPerHr = 0.0
        isNonlinearRegime = false
        if ca40Present && onResonance && circulatingPowerW > threshold {
            let excess = (circulatingPowerW - threshold) / threshold
            qrtlRateGPerHr = 0.02 * pow(excess, 2.2) // nonlinear term
            isNonlinearRegime = true
        }

        hydrogenRateGPerHr = baselineRateGPerHr + qrtlRateGPerHr
        visualFieldIntensity = min(circulatingPowerW / 1200.0, 1.0)

        // Economics
        let gramsSoFar = hydrogenRateGPerHr * elapsedHours
        if gramsSoFar > 0.0001 {
            let kgSoFar = gramsSoFar / 1000.0
            kWhPerKgH2 = (wattHoursConsumed / 1000.0) / kgSoFar
        } else {
            kWhPerKgH2 = 0
        }
        electricityCostPerKg = kWhPerKgH2 * electricityPricePerKWh
        totalCostPerKg = electricityCostPerKg + otherOperatingCostPerKg
        profitPerKg = sellPricePerKg - totalCostPerKg
    }

    func resetRun() {
        elapsedHours = 0
        wattHoursConsumed = 0
        recompute()
    }
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var monitor = MasterMonitor()
    @State private var sheetDetent: PresentationDetent = .height(64)

    var body: some View {
        ZStack(alignment: .top) {
            QRTLSceneView(monitor: monitor)
                .ignoresSafeArea()

            topReadoutStrip
        }
        // Half-sheet / slide-up control panel. Starts as a small
        // peeking bar the user can drag up to .medium or .large,
        // matching a native iOS bottom-sheet interaction.
        .sheet(isPresented: .constant(true)) {
            controlSheet
                .presentationDetents(
                    [.height(64), .fraction(0.4), .large],
                    selection: $sheetDetent
                )
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled()
        }
    }

    // MARK: Top strip — always-visible at-a-glance status

    private var topReadoutStrip: some View {
        HStack(spacing: 14) {
            readout("Laser", String(format: "%.0f W", monitor.laserPowerW))
            readout("H₂ Rate", String(format: "%.3f g/hr", monitor.hydrogenRateGPerHr))
            readout("Profit", String(format: "$%.2f/kg", monitor.profitPerKg))
                .foregroundStyle(monitor.profitPerKg >= 0 ? .green : .red)
            Spacer()
            if monitor.isNonlinearRegime {
                Label("Nonlinear", systemImage: "bolt.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func readout(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.system(.caption, design: .monospaced)).bold()
        }
    }

    // MARK: Slide-up half-sheet content

    private var controlSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Grabber-adjacent header stays visible even at the
                // smallest (.height(64)) detent.
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("QRTL Hydrogen Resonator")
                            .font(.headline)
                        Text(monitor.isNonlinearRegime
                             ? "⚡ Nonlinear QRTL regime (resonant + Ca-40)"
                             : "Baseline linear / thermal regime")
                            .font(.caption)
                            .foregroundStyle(monitor.isNonlinearRegime ? .yellow : .secondary)
                    }
                    Spacer()
                    Button("Reset Run") { monitor.resetRun() }
                        .buttonStyle(.bordered)
                }

                readoutGrid

                Divider()

                Text("Controls")
                    .font(.subheadline.bold())

                VStack(spacing: 14) {
                    sliderRow("Laser Power", value: $monitor.laserPowerW, range: 0...50,
                              format: { "\(Int($0)) W" })
                    sliderRow("Detuning", value: $monitor.detuning, range: -1...1,
                              format: { String(format: "%.2f", $0) })
                    sliderRow("Cavity Finesse", value: $monitor.cavityFinesse, range: 20...300,
                              format: { "\(Int($0))" })
                    sliderRow("Sell Price", value: $monitor.sellPricePerKg, range: 5...50,
                              format: { String(format: "$%.0f/kg", $0) })
                    sliderRow("Other Op. Cost", value: $monitor.otherOperatingCostPerKg, range: 0...25,
                              format: { String(format: "$%.0f/kg", $0) })

                    HStack(spacing: 20) {
                        Toggle("Laser On", isOn: $monitor.laserOn)
                        Toggle("Ca-40 Loaded", isOn: $monitor.ca40Present)
                    }
                    .toggleStyle(.switch)
                }
            }
            .padding()
        }
    }

    private var readoutGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            readoutTile("Circulating", String(format: "%.0f W", monitor.circulatingPowerW))
            readoutTile("Buildup", String(format: "×%.1f", monitor.buildupFactor))
            readoutTile("Chamber T", String(format: "%.1f°C", monitor.chamberTemperatureC))
            readoutTile("Energy Use", String(format: "%.1f kWh/kg", monitor.kWhPerKgH2))
            readoutTile("Elec. Cost", String(format: "$%.2f/kg", monitor.electricityCostPerKg))
            readoutTile("Total Cost", String(format: "$%.2f/kg", monitor.totalCostPerKg))
        }
    }

    private func readoutTile(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.system(.footnote, design: .monospaced)).bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func sliderRow(
        _ label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        format: @escaping (Double) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text(format(value.wrappedValue))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }
}

// MARK: - SceneKit wrapper

struct QRTLSceneView: UIViewRepresentable {
    @ObservedObject var monitor: MasterMonitor

    func makeCoordinator() -> Coordinator {
        Coordinator(monitor: monitor)
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        let scene = QRTLSceneBuilder.buildScene()
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        scnView.backgroundColor = UIColor(white: 0.04, alpha: 1.0)
        scnView.delegate = context.coordinator
        scnView.isPlaying = true
        context.coordinator.attachNodes(from: scene)
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.monitor = monitor
    }

    final class Coordinator: NSObject, SCNSceneRendererDelegate {
        var monitor: MasterMonitor
        weak var standingWaveNode: SCNNode?
        var waveSegmentNodes: [SCNNode] = []
        var beamNode: SCNNode?
        var bubbleSystem: SCNParticleSystem?
        var chamberGlowNode: SCNNode?
        private var startTime: TimeInterval = 0

        init(monitor: MasterMonitor) {
            self.monitor = monitor
        }

        func attachNodes(from scene: SCNScene) {
            standingWaveNode = scene.rootNode.childNode(withName: "standingWave", recursively: true)
            waveSegmentNodes = standingWaveNode?.childNodes ?? []
            beamNode = scene.rootNode.childNode(withName: "laserBeam", recursively: true)
            chamberGlowNode = scene.rootNode.childNode(withName: "chamberGlow", recursively: true)
            if let chamber = scene.rootNode.childNode(withName: "bubbleEmitter", recursively: true) {
                bubbleSystem = chamber.particleSystems?.first
            }
        }

        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            if startTime == 0 { startTime = time }
            let t = time - startTime
            let intensity = monitor.visualFieldIntensity
            let nonlinear = monitor.isNonlinearRegime

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                // Animate the standing wave amplitude with the field.
                for (i, node) in self.waveSegmentNodes.enumerated() {
                    let phase = Double(i) * 0.5
                    let amplitude = 0.05 + 0.35 * intensity
                    let y = sin(t * 6.0 + phase) * amplitude
                    node.position.y = Float(y)
                    let scale = Float(0.3 + 0.9 * intensity)
                    node.scale = SCNVector3(scale, scale, scale)
                }

                // Pulse the laser beam emissive strength with power.
                if let beam = self.beamNode {
                    let pulse = 0.4 + 0.6 * abs(sin(t * 8.0))
                    beam.geometry?.firstMaterial?.emission.intensity = CGFloat(intensity * pulse * 2.0)
                    beam.opacity = monitor.laserOn ? CGFloat(0.3 + 0.7 * intensity) : 0.05
                }

                // Drive bubble production from hydrogen rate.
                if let bubbles = self.bubbleSystem {
                    let rate = Float(monitor.hydrogenRateGPerHr)
                    bubbles.birthRate = CGFloat(min(max(rate * 400.0, 0), 4000))
                    bubbles.particleColor = nonlinear
                        ? UIColor.systemYellow
                        : UIColor.systemTeal
                }

                // Chamber glow flags the nonlinear QRTL regime.
                if let glow = self.chamberGlowNode {
                    glow.light?.intensity = nonlinear ? CGFloat(1200 + 400 * sin(t * 4)) : 150
                    glow.light?.color = nonlinear ? UIColor.yellow : UIColor.cyan
                }
            }
        }
    }
}

// MARK: - Scene construction

enum QRTLSceneBuilder {

    static func buildScene() -> SCNScene {
        let scene = SCNScene()
        let root = scene.rootNode

        addLighting(to: root)
        addCamera(to: root)
        addGroundPlatform(to: root)

        // Layout along the X axis, matching the pipeline order.
        addPowerMeter(to: root, at: SCNVector3(-9, 0.5, 0))
        addLaserModule(to: root, at: SCNVector3(-6.5, 0.5, 0))
        addBeamConditioning(to: root, at: SCNVector3(-4.5, 0.5, 0))
        addLaserBeam(to: root, from: SCNVector3(-4.0, 0.5, 0), to: SCNVector3(-2.2, 0.5, 0))
        addOpticalCavity(to: root, at: SCNVector3(-1.0, 0.5, 0))
        addInteractionChamber(to: root, at: SCNVector3(2.0, 0.5, 0))
        addGasSeparation(to: root, at: SCNVector3(5.0, 0.5, 0))
        addConnectingRail(to: root, fromX: -9.5, toX: 6.5, y: 0.05)
        addLabel(to: root, text: "QRTL Hydrogen Resonator", at: SCNVector3(-2, 3.2, 0))

        return scene
    }

    // MARK: Environment

    private static func addLighting(to root: SCNNode) {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 250
        ambient.light?.color = UIColor(white: 0.6, alpha: 1.0)
        root.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 800
        key.position = SCNVector3(0, 10, 8)
        key.eulerAngles = SCNVector3(-Float.pi / 3, 0, 0)
        root.addChildNode(key)
    }

    private static func addCamera(to root: SCNNode) {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 100
        cameraNode.position = SCNVector3(-2, 5, 12)
        cameraNode.eulerAngles = SCNVector3(-0.3, 0, 0)
        root.addChildNode(cameraNode)
    }

    private static func addGroundPlatform(to root: SCNNode) {
        let floor = SCNFloor()
        floor.reflectivity = 0.05
        let floorMat = SCNMaterial()
        floorMat.diffuse.contents = UIColor(white: 0.08, alpha: 1.0)
        floor.materials = [floorMat]
        let floorNode = SCNNode(geometry: floor)
        root.addChildNode(floorNode)
    }

    private static func addLabel(to root: SCNNode, text: String, at position: SCNVector3) {
        let textGeo = SCNText(string: text, extrusionDepth: 0.2)
        textGeo.font = UIFont.boldSystemFont(ofSize: 6)
        textGeo.firstMaterial?.diffuse.contents = UIColor.white
        let node = SCNNode(geometry: textGeo)
        node.scale = SCNVector3(0.05, 0.05, 0.05)
        node.position = position
        root.addChildNode(node)
    }

    private static func addConnectingRail(to root: SCNNode, fromX: Float, toX: Float, y: Float) {
        let length = CGFloat(toX - fromX)
        let rail = SCNBox(width: length, height: 0.05, length: 0.15, chamferRadius: 0.02)
        rail.firstMaterial?.diffuse.contents = UIColor.darkGray
        let node = SCNNode(geometry: rail)
        node.position = SCNVector3((fromX + toX) / 2, y, 0)
        root.addChildNode(node)
    }

    // MARK: Stage 1 — Power meter

    private static func addPowerMeter(to root: SCNNode, at position: SCNVector3) {
        let body = SCNBox(width: 1.2, height: 1.6, length: 0.8, chamferRadius: 0.05)
        body.firstMaterial?.diffuse.contents = UIColor(white: 0.2, alpha: 1.0)
        let node = SCNNode(geometry: body)
        node.position = position

        let dial = SCNCylinder(radius: 0.35, height: 0.05)
        dial.firstMaterial?.diffuse.contents = UIColor.black
        dial.firstMaterial?.emission.contents = UIColor.green
        let dialNode = SCNNode(geometry: dial)
        dialNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        dialNode.position = SCNVector3(0, 0.3, 0.45)
        node.addChildNode(dialNode)

        root.addChildNode(node)
        addLabel(to: root, text: "Power Meter", at: SCNVector3(position.x - 0.7, position.y + 1.2, position.z))
    }

    // MARK: Stage 2 — Laser + driver/cooling

    private static func addLaserModule(to root: SCNNode, at position: SCNVector3) {
        let housing = SCNBox(width: 1.8, height: 1.0, length: 1.0, chamferRadius: 0.08)
        housing.firstMaterial?.diffuse.contents = UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1)
        let node = SCNNode(geometry: housing)
        node.position = position

        // Cooling fins
        for i in 0..<4 {
            let fin = SCNBox(width: 0.05, height: 0.9, length: 0.9, chamferRadius: 0)
            fin.firstMaterial?.diffuse.contents = UIColor.lightGray
            let finNode = SCNNode(geometry: fin)
            finNode.position = SCNVector3(-0.9 + Float(i) * 0.06, 0, 0)
            node.addChildNode(finNode)
        }

        // Emission aperture
        let aperture = SCNCylinder(radius: 0.08, height: 0.05)
        aperture.firstMaterial?.diffuse.contents = UIColor.red
        aperture.firstMaterial?.emission.contents = UIColor.red
        let apertureNode = SCNNode(geometry: aperture)
        apertureNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        apertureNode.position = SCNVector3(0.95, 0, 0)
        node.addChildNode(apertureNode)

        root.addChildNode(node)
        addLabel(to: root, text: "Er:YAG 2.94µm", at: SCNVector3(position.x - 0.9, position.y + 1.0, position.z))
    }

    // MARK: Stage 3 — Beam conditioning optics

    private static func addBeamConditioning(to root: SCNNode, at position: SCNVector3) {
        for (i, r) in [0.22, 0.16].enumerated() {
            let lens = SCNCylinder(radius: r, height: 0.04)
            lens.firstMaterial?.diffuse.contents = UIColor.cyan.withAlphaComponent(0.5)
            lens.firstMaterial?.transparency = 0.6
            let node = SCNNode(geometry: lens)
            node.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            node.position = SCNVector3(position.x + Float(i) * 0.5, position.y, position.z)
            root.addChildNode(node)
        }
    }

    private static func addLaserBeam(to root: SCNNode, from: SCNVector3, to: SCNVector3) {
        let length = CGFloat(to.x - from.x)
        let beam = SCNCylinder(radius: 0.03, height: length)
        beam.firstMaterial?.diffuse.contents = UIColor.red
        beam.firstMaterial?.emission.contents = UIColor.red
        let node = SCNNode(geometry: beam)
        node.name = "laserBeam"
        node.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        node.position = SCNVector3((from.x + to.x) / 2, from.y, from.z)
        root.addChildNode(node)
    }

    // MARK: Stage 4 — High-reflectivity optical cavity + standing wave

    private static func addOpticalCavity(to root: SCNNode, at position: SCNVector3) {
        // Two facing mirrors
        for dx: Float in [-0.9, 0.9] {
            let mirror = SCNCylinder(radius: 0.4, height: 0.06)
            mirror.firstMaterial?.diffuse.contents = UIColor(white: 0.85, alpha: 1)
            mirror.firstMaterial?.metalness.contents = 1.0
            mirror.firstMaterial?.roughness.contents = 0.05
            let node = SCNNode(geometry: mirror)
            node.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            node.position = SCNVector3(position.x + dx, position.y, position.z)
            root.addChildNode(node)
        }

        // Glass tube enclosing the cavity
        let tube = SCNTube(innerRadius: 0.42, outerRadius: 0.45, height: 1.8)
        tube.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.15)
        tube.firstMaterial?.transparency = 0.3
        let tubeNode = SCNNode(geometry: tube)
        tubeNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        tubeNode.position = position
        root.addChildNode(tubeNode)

        // Standing wave: a chain of small spheres whose Y offset is
        // animated in the Coordinator to trace a sine profile.
        let waveParent = SCNNode()
        waveParent.name = "standingWave"
        waveParent.position = position
        let segments = 16
        for i in 0..<segments {
            let sphere = SCNSphere(radius: 0.05)
            sphere.firstMaterial?.diffuse.contents = UIColor.orange
            sphere.firstMaterial?.emission.contents = UIColor.orange
            let node = SCNNode(geometry: sphere)
            let xPos = -0.8 + (Float(i) / Float(segments - 1)) * 1.6
            node.position = SCNVector3(xPos, 0, 0)
            waveParent.addChildNode(node)
        }
        root.addChildNode(waveParent)

        addLabel(to: root, text: "Optical Cavity", at: SCNVector3(position.x - 0.9, position.y + 1.0, position.z))
    }

    // MARK: Stage 5 — Interaction chamber (water + Ca-40)

    private static func addInteractionChamber(to root: SCNNode, at position: SCNVector3) {
        let tank = SCNBox(width: 1.4, height: 1.4, length: 1.4, chamferRadius: 0.05)
        tank.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.12)
        tank.firstMaterial?.transparency = 0.35
        let tankNode = SCNNode(geometry: tank)
        tankNode.position = position
        root.addChildNode(tankNode)

        // Water fill
        let water = SCNBox(width: 1.3, height: 1.0, length: 1.3, chamferRadius: 0.03)
        water.firstMaterial?.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.5)
        water.firstMaterial?.transparency = 0.6
        let waterNode = SCNNode(geometry: water)
        waterNode.name = "bubbleEmitter"
        waterNode.position = SCNVector3(position.x, position.y - 0.2, position.z)
        tankNode.addChildNode(waterNode)

        // Ca-40 pellet
        let pellet = SCNSphere(radius: 0.12)
        pellet.firstMaterial?.diffuse.contents = UIColor.lightGray
        pellet.firstMaterial?.metalness.contents = 0.6
        let pelletNode = SCNNode(geometry: pellet)
        pelletNode.position = SCNVector3(0, -0.2, 0)
        waterNode.addChildNode(pelletNode)

        // Bubble particle system representing H2/O2 evolution
        let bubbles = SCNParticleSystem()
        bubbles.birthRate = 0
        bubbles.particleLifeSpan = 1.2
        bubbles.particleSize = 0.03
        bubbles.particleColor = UIColor.systemTeal
        bubbles.emitterShape = water
        bubbles.birthDirection = .constant
        bubbles.particleVelocity = 0.4
        bubbles.particleVelocityVariation = 0.15
        bubbles.acceleration = SCNVector3(0, 0.6, 0)
        bubbles.blendMode = .additive
        waterNode.addParticleSystem(bubbles)

        // Glow light flags the nonlinear QRTL regime
        let glow = SCNNode()
        glow.light = SCNLight()
        glow.light?.type = .omni
        glow.light?.intensity = 150
        glow.light?.color = UIColor.cyan
        glow.name = "chamberGlow"
        glow.position = SCNVector3(position.x, position.y, position.z)
        root.addChildNode(glow)

        addLabel(to: root, text: "Interaction Chamber (H₂O + Ca-40)", at: SCNVector3(position.x - 1.1, position.y + 1.1, position.z))
    }

    // MARK: Stage 6 — Gas separation / collection

    private static func addGasSeparation(to root: SCNNode, at position: SCNVector3) {
        let h2Tube = SCNCylinder(radius: 0.25, height: 1.6)
        h2Tube.firstMaterial?.diffuse.contents = UIColor.yellow.withAlphaComponent(0.3)
        h2Tube.firstMaterial?.transparency = 0.5
        let h2Node = SCNNode(geometry: h2Tube)
        h2Node.position = SCNVector3(position.x, position.y + 0.4, position.z - 0.4)
        root.addChildNode(h2Node)

        let o2Tube = SCNCylinder(radius: 0.25, height: 1.6)
        o2Tube.firstMaterial?.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.3)
        o2Tube.firstMaterial?.transparency = 0.5
        let o2Node = SCNNode(geometry: o2Tube)
        o2Node.position = SCNVector3(position.x, position.y + 0.4, position.z + 0.4)
        root.addChildNode(o2Node)

        addLabel(to: root, text: "H₂ / O₂ Separation", at: SCNVector3(position.x - 0.9, position.y + 1.4, position.z))
    }
}

#Preview {
    ContentView()
}

