// Create a SwiftUI AboutView for the QRTL Hydrogen Resonator app.
// The view should provide a title, descriptive text about the app's purpose and technology, version/build info, and a credit section.
// It should use modern SwiftUI design, include a dismiss button if presented modally, and have a subtle hydrogen/laser-themed accent.

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                        .foregroundStyle(.secondary)
                }
                .padding(4)
            }
            .padding(.top)

            Image("hydrogen resonator")
                .font(.system(size: 48))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.blue, .teal, .yellow)
                .padding(.bottom, 4)

            Text("QRTL Hydrogen Resonator")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text("This app is a physics-based simulation of a three-laser QRTL hydrogen resonator. It explores the hypothetical quantum resonance tunneling leading to hydrogen/oxygen production from water, with a focus on coherent laser fields, cavity resonance, and shell-driven transitions. Economics and efficiency are highlighted throughout.")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.bottom)

            Text("Simulation Pipeline (In Simple Words)")
                .font(.title3.bold())
                .padding(.top)

            VStack(spacing: 12) {
                // Electricity Power
                pipelineCard(title: "1. Electricity Powers Lasers", text: "Think of electricity as fuel for three special flashlights (lasers).")
                // Lasers emit specific light
                pipelineCard(title: "2. Lasers Create Special Light", text: "These lasers shine a very exact color of light chosen for its effects on water.")
                // Phase-synchronization
                pipelineCard(title: "3. Lasers Work in Unison", text: "Imagine the flashlights blinking perfectly together, their beams lining up so their waves reinforce each other.")
                // Cavity resonance
                pipelineCard(title: "4. Cavity Makes the Waves Stronger", text: "The light bounces between mirrors, making the waves even taller and stronger—like pushing a swing at just the right time.")
                // Standing wave and shell model
                pipelineCard(title: "5. Special Standing Wave", text: "Inside, waves stand still in patterns, building up energy in certain spots, similar to the vibrations on a plucked guitar string.")
                // QRTL effect
                pipelineCard(title: "6. Energy Shells and Release", text: "If the waves are just right, they can \"shake loose\" hydrogen and oxygen from the water—this is the QRTL hypothesis.")
                // Gas collection and economics
                pipelineCard(title: "7. Gases Collected, Economics Tracked", text: "Hydrogen and oxygen are collected, and the app tracks costs, energy, and potential profits.")
            }

            Text("Equations Explained Simply")
                .font(.title3.bold())
                .padding(.top)

            VStack(spacing: 12) {
                pipelineCard(title: "Wave Alignment (Phase Coherence)", text: "The more perfectly the laser waves line up, the more powerful their combined effect. Think of teamwork—everyone pulling at once.")
                pipelineCard(title: "Cavity Amplification (Resonance Factor)", text: "If the frequency matches the cavity, the waves grow strong. It's like children timing their pushes to make a swing soar.")
                pipelineCard(title: "Shell Threshold (QRTL Effect)", text: "If the energy in the system crosses a certain threshold, extra hydrogen and oxygen are produced. Below this, just a tiny background trickle happens.")
                pipelineCard(title: "Baseline and Nonlinear Regimes", text: "Baseline: Minimal reaction (like simmering). Nonlinear regime: Full reaction (like boiling) when all conditions are just right.")
                pipelineCard(title: "Economics", text: "The app adds up how much gas is made, how much energy is spent, and how much money is earned or lost.")
            }

            Divider()
                .padding(.vertical, 8)

            VStack(spacing: 6) {
                Text("Version \(appVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Build \(appBuild)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 8)

            VStack(spacing: 4) {
                Text("Developed by David Nishimoto")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("© 2026")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.06), Color.teal.opacity(0.05), Color.yellow.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .frame(maxWidth: 500)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    @ViewBuilder
    private func pipelineCard(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(text).font(.footnote)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    AboutView()
}
