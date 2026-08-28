import SwiftUI

struct AboutView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: - Header

                HStack {
                    Spacer()

                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Close")
                    }
                }

                VStack(spacing: 12) {

                    Image("hydrogen resonator")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 180, maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(radius: 8)

                    Text("QRTL Hydrogen Resonator")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text("Quark Twister Resonating Lattice")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                // MARK: - Overview

                informationCard(
                    title: "Overview",
                    icon: "atom",
                    content: """
                    QRTL Hydrogen Resonator models a three-laser infrared resonator based on the Quark Twister Resonating Lattice (QRTL) theory.

                    The system begins with electrical power, converts that energy into coherent infrared laser light, establishes a phase-aligned optical field, builds resonance inside an optical cavity, and applies the resulting standing-wave field to water.

                    Within the QRTL framework, the resonating electromagnetic field interacts with molecular energy shells. When the modeled QRTL resonance conditions are established, energy is transferred through the QRTL resonance mechanism, allowing the hydrogen and oxygen components of water to be released and collected.

                    The application connects the physical stages of the system with measurable operating quantities including laser power, wavelength, cavity resonance, circulating power, resonator conditions, hydrogen production, energy consumption, operating cost, and production economics.
                    """
                )

                // MARK: - QRTL Framework

                sectionHeader(
                    title: "QRTL Resonator Framework",
                    subtitle: "From electrical energy to molecular separation"
                )

                pipelineSection(
                    number: "01",
                    title: "Electrical Power",
                    analogy: "Electrical power is the energy source that drives the resonator system.",
                    explanation: """
                    The system begins with electrical energy supplied to the laser assemblies and associated operating components. Electrical input establishes the energy budget for the complete resonator system.

                    The model tracks electrical consumption so that the energy required to operate the resonator can be compared directly with the modeled hydrogen production rate and operating economics.
                    """
                )

                pipelineSection(
                    number: "02",
                    title: "2.94 μm Infrared Laser Field",
                    analogy: "The lasers establish the precise infrared field used by the resonator.",
                    explanation: """
                    The resonator uses 2.94 μm Er:YAG infrared laser radiation. The wavelength establishes the frequency of the electromagnetic field interacting with the water molecules.

                    The three-laser configuration establishes the coherent optical field required by the QRTL resonator. The laser system therefore serves as the controlled source of the electromagnetic energy entering the cavity.
                    """,
                    math: """
                    λ = 2.94 μm

                    The corresponding optical frequency is determined from:

                    f = c / λ

                    where c is the speed of light and λ is the laser wavelength.
                    """
                )

                pipelineSection(
                    number: "03",
                    title: "Phase-Coherent Laser Operation",
                    analogy: "The three laser fields operate together as one coordinated wave system.",
                    explanation: """
                    The three laser sources are phase synchronized so that their electromagnetic fields maintain a controlled phase relationship.

                    Coherent fields reinforce one another when their phases are aligned. The resulting field establishes the spatial and temporal structure required for the resonator's standing-wave configuration.

                    Phase coherence is therefore a primary operating condition of the QRTL resonator rather than an optional enhancement.
                    """,
                    math: """
                    For coherent fields, the electric-field contributions combine according to their relative phase.

                    E_total = E₁ + E₂ + E₃

                    Maximum constructive reinforcement occurs when the fields maintain the required phase relationship.
                    """
                )

                pipelineSection(
                    number: "04",
                    title: "Optical Cavity Resonance",
                    analogy: "The cavity repeatedly returns the light through the interaction region so the field builds coherently.",
                    explanation: """
                    The optical cavity confines the laser radiation between reflective surfaces. Each pass through the cavity adds to the existing electromagnetic field when the cavity is operated at resonance.

                    Resonance establishes circulating optical power greater than the externally supplied single-pass laser power. The cavity therefore concentrates the available optical energy within the interaction region.

                    Cavity finesse and detuning determine how efficiently the resonator maintains the circulating field.
                    """,
                    math: """
                    Resonance occurs when the cavity length satisfies the standing-wave condition:

                    L = nλ / 2

                    where L is the cavity length, λ is the laser wavelength, and n is an integer.

                    The circulating field is governed by the cavity buildup and resonance response.
                    """
                )

                pipelineSection(
                    number: "05",
                    title: "QRTL Standing-Wave Field",
                    analogy: "Opposing waves establish fixed regions of high and low field intensity throughout the resonator.",
                    explanation: """
                    Reflected laser radiation traveling in opposite directions forms a standing-wave field inside the optical cavity.

                    The standing wave contains nodes and antinodes. Nodes represent locations of minimum field amplitude, while antinodes represent locations of maximum field amplitude.

                    The QRTL model uses this structured electromagnetic field as the interaction environment for the molecular energy shells of the water system.
                    """,
                    math: """
                    A standing wave can be represented as the superposition of oppositely traveling waves:

                    E(x,t) = 2E₀ cos(kx) cos(ωt)

                    where k is the wave number and ω is the angular frequency.

                    The resulting field contains fixed nodes and antinodes.
                    """
                )

                pipelineSection(
                    number: "06",
                    title: "QRTL Energy-Shell Interaction",
                    analogy: "The resonating field transfers energy into the molecular structure through the QRTL mechanism.",
                    explanation: """
                    Within QRTL theory, the electromagnetic standing wave interacts with the energy shells associated with the water molecule.

                    The resonator establishes a concentrated and phase-coherent energy field. The QRTL mechanism describes the transfer of this resonant energy through the molecular energy-shell structure.

                    When the required QRTL resonance conditions are established, the molecular structure undergoes the modeled QRTL transition that releases the hydrogen and oxygen components of water.

                    The QRTL model therefore connects the optical resonance field directly to molecular separation through its energy-shell mechanism.
                    """,
                    math: """
                    The QRTL transition is governed by the modeled relationship between:

                    • Resonant electromagnetic energy
                    • Field intensity
                    • Phase coherence
                    • Molecular energy-shell structure
                    • QRTL resonance conditions

                    These quantities determine the modeled transition rate within the QRTL framework.
                    """
                )

                pipelineSection(
                    number: "07",
                    title: "Hydrogen and Oxygen Collection",
                    analogy: "The separated gases leave the interaction region and enter the collection stage.",
                    explanation: """
                    The output stage represents the collection of the hydrogen and oxygen produced through the QRTL molecular-separation process.

                    Hydrogen production is tracked as a mass flow rate. The model can therefore express production in units such as grams per hour or kilograms per hour.

                    The separation stage provides the connection between the molecular QRTL mechanism and the measurable production output of the system.
                    """
                )

                pipelineSection(
                    number: "08",
                    title: "Energy and Production Accounting",
                    analogy: "Every unit of electrical input is compared with the amount of hydrogen produced.",
                    explanation: """
                    The application maintains an energy and production accounting layer around the resonator.

                    Electrical consumption is converted into operating cost using the configured electricity price. Hydrogen production is converted into production value using the configured selling price.

                    This produces a direct relationship between electrical energy input, hydrogen output, operating expense, revenue, and modeled profitability.
                    """
                )

                // MARK: - QRTL Equations

                sectionHeader(
                    title: "QRTL Model Equations",
                    subtitle: "The mathematical relationships used by the resonator"
                )

                equationCard(
                    title: "Laser Wavelength",
                    icon: "wave.3.right",
                    explanation: """
                    The resonator operates at a defined infrared wavelength of 2.94 μm. The wavelength establishes the electromagnetic frequency used throughout the optical system.
                    """,
                    equation: """
                    λ = 2.94 × 10⁻⁶ m

                    f = c / λ
                    """
                )

                equationCard(
                    title: "Phase Coherence",
                    icon: "arrow.triangle.2.circlepath",
                    explanation: """
                    The three laser fields are maintained in a controlled phase relationship. Coherent fields combine according to their relative phase, establishing the required resonant field structure.
                    """,
                    equation: """
                    E_total = E₁ + E₂ + E₃

                    Constructive reinforcement occurs when the relative phases are aligned.
                    """
                )

                equationCard(
                    title: "Cavity Resonance",
                    icon: "rectangle.inset.filled",
                    explanation: """
                    The optical cavity reinforces the laser field when its optical length satisfies the standing-wave resonance condition.
                    """,
                    equation: """
                    L = nλ / 2
                    """
                )

                equationCard(
                    title: "Standing-Wave Structure",
                    icon: "waveform.path.ecg",
                    explanation: """
                    The resonator creates a stationary spatial pattern of electromagnetic field intensity. The antinodes provide the regions of maximum field amplitude used by the QRTL interaction model.
                    """,
                    equation: """
                    E(x,t) = 2E₀ cos(kx) cos(ωt)
                    """
                )

                equationCard(
                    title: "QRTL Resonance Condition",
                    icon: "atom",
                    explanation: """
                    The QRTL model evaluates the resonator state using the optical field, cavity condition, phase coherence, and molecular energy-shell interaction.

                    The modeled hydrogen-production response is determined from the QRTL resonance state established by these operating parameters.
                    """
                )

                equationCard(
                    title: "Production Rate",
                    icon: "drop.fill",
                    explanation: """
                    Hydrogen production is expressed as a mass flow rate. The production result provides the primary output used by the energy and economic accounting system.
                    """,
                    equation: """
                    Production rate = mass of hydrogen / unit time

                    Common output units:

                    g/hr
                    kg/hr
                    kg/day
                    """
                )

                // MARK: - Economics

                sectionHeader(
                    title: "Energy & Economics",
                    subtitle: "Connecting resonator operation to production cost"
                )

                informationCard(
                    title: "Operating Economics",
                    icon: "chart.line.uptrend.xyaxis",
                    content: """
                    The economic model relates three primary quantities:

                    1. Electrical energy consumed by the resonator.
                    2. Hydrogen produced by the QRTL process.
                    3. Revenue generated from hydrogen production.

                    Electricity cost is calculated from electrical consumption and the configured price per kilowatt-hour.

                    Production revenue is calculated from hydrogen output and the configured selling price per kilogram.

                    The resulting operating margin provides a direct measure of the relationship between energy consumption and hydrogen production.
                    """
                )

                // MARK: - Model Structure

                sectionHeader(
                    title: "System Structure",
                    subtitle: "The complete QRTL resonator sequence"
                )

                systemFlowCard()

                // MARK: - Footer

                Divider()
                    .padding(.top, 8)

                VStack(spacing: 5) {
                    Text("QRTL Hydrogen Resonator")
                        .font(.headline)

                    Text("Quark Twister Resonating Lattice")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Version \(appVersion) • Build \(appBuild)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text("Developed by David Nishimoto")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)

                    Text("© 2026")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.06),
                    Color.teal.opacity(0.04),
                    Color.yellow.opacity(0.025)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Section Header

    private func sectionHeader(
        title: String,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.weight(.bold))

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Information Card

    @ViewBuilder
    private func informationCard(
        title: String,
        icon: String,
        content: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            Label(title, systemImage: icon)
                .font(.headline.weight(.bold))

            Text(content)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    Color.primary.opacity(0.07),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Pipeline Section

    @ViewBuilder
    private func pipelineSection(
        number: String,
        title: String,
        analogy: String,
        explanation: String,
        math: String? = nil
    ) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top, spacing: 12) {

                Text(number)
                    .font(.caption.weight(.bold))
                    .frame(width: 34, height: 34)
                    .background(
                        Color.accentColor.opacity(0.12),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.bold))

                    Text(analogy)
                        .font(.callout.italic())
                        .foregroundStyle(.secondary)
                }
            }

            Text(explanation)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if let math {
                equationBox(math)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    Color.primary.opacity(0.06),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Equation Card

    @ViewBuilder
    private func equationCard(
        title: String,
        icon: String,
        explanation: String,
        equation: String? = nil
    ) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            Label(title, systemImage: icon)
                .font(.headline.weight(.bold))

            Text(explanation)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            if let equation {
                equationBox(equation)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    Color.primary.opacity(0.06),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Equation Box

    @ViewBuilder
    private func equationBox(
        _ text: String
    ) -> some View {

        VStack(alignment: .leading, spacing: 6) {

            Text("MODEL RELATIONSHIP")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)

            Text(text)
                .font(.system(
                    .callout,
                    design: .monospaced
                ))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.primary.opacity(0.045),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }

    // MARK: - System Flow

    @ViewBuilder
    private func systemFlowCard() -> some View {

        VStack(spacing: 0) {

            flowItem(
                icon: "bolt.fill",
                title: "Electrical Power",
                description: "Electrical energy supplies the resonator."
            )

            flowConnector()

            flowItem(
                icon: "laser.burst",
                title: "Three 2.94 μm Lasers",
                description: "Coherent infrared fields establish the optical input."
            )

            flowConnector()

            flowItem(
                icon: "arrow.triangle.2.circlepath",
                title: "Phase Synchronization",
                description: "The laser fields operate with a controlled phase relationship."
            )

            flowConnector()

            flowItem(
                icon: "rectangle.inset.filled",
                title: "Optical Cavity",
                description: "The cavity builds circulating optical power."
            )

            flowConnector()

            flowItem(
                icon: "waveform.path.ecg",
                title: "Standing-Wave Field",
                description: "Opposing waves establish the resonant field structure."
            )

            flowConnector()

            flowItem(
                icon: "atom",
                title: "QRTL Interaction",
                description: "The resonant field interacts with molecular energy shells."
            )

            flowConnector()

            flowItem(
                icon: "drop.fill",
                title: "Hydrogen Production",
                description: "The QRTL transition produces the modeled hydrogen output."
            )

            flowConnector()

            flowItem(
                icon: "chart.line.uptrend.xyaxis",
                title: "Energy & Economics",
                description: "Energy consumption, production cost, revenue, and margin are calculated."
            )
        }
        .padding(18)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    Color.primary.opacity(0.06),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Flow Item

    @ViewBuilder
    private func flowItem(
        icon: String,
        title: String,
        description: String
    ) -> some View {

        HStack(alignment: .top, spacing: 14) {

            Image(systemName: icon)
                .font(.headline)
                .frame(width: 36, height: 36)
                .background(
                    Color.accentColor.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: 10)
                )

            VStack(alignment: .leading, spacing: 3) {

                Text(title)
                    .font(.subheadline.weight(.bold))

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Flow Connector

    @ViewBuilder
    private func flowConnector() -> some View {

        HStack {
            Rectangle()
                .fill(Color.primary.opacity(0.10))
                .frame(width: 1, height: 18)
                .padding(.leading, 18)

            Spacer()
        }
    }

    // MARK: - Version

    private var appVersion: String {
        Bundle.main.infoDictionary?[
            "CFBundleShortVersionString"
        ] as? String ?? "1.0"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?[
            "CFBundleVersion"
        ] as? String ?? "1"
    }
}

#Preview {
    AboutView()
}
