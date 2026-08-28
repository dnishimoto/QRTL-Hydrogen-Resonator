import Testing
@testable import QRTL_Hydrogen_Resonator

@Suite("QRTL Hydrogen Resonator Model")
struct QRTLHydrogenResonatorTests {
    private var monitor: MasterMonitor!
    
    mutating func setUp() {
        monitor = MasterMonitor()
        monitor.resetRun()
        monitor.laserOn = true
        monitor.qrtlEnabled = true
        monitor.ca40Present = true
        monitor.laserPowerW = 40.0
        monitor.cavityFinesse = 220.0
        monitor.detuning = 0.0
        monitor.laser2PhaseOffset = 0.0
        monitor.laser3PhaseOffset = 0.0
        monitor.shellCouplingEfficiency = 0.12
        monitor.shellCoherenceLifetimeS = 4.0
        monitor.shellInstabilityThreshold = 1.0
        monitor.shellTransitionGainGPerHr = 0.085
    }

    // MARK: Constants / Laser Properties
    @Test("Wavelength is Er:YAG target")
    func testWavelengthIsErYAGTarget() async throws {
        #expect(monitor.wavelengthMicrometers == 2.94, "Wavelength should be 2.94μm")
    }

    @Test("Frequency matches c/λ")
    func testFrequencyMatchesSpeedOfLightOverWavelength() async throws {
        let expected = (QRTLConstants.speedOfLight / QRTLConstants.wavelengthMeters) / 1.0e12
        #expect(abs(monitor.frequencyTHz - expected) < 0.000_001)
    }

    @Test("Three lasers produce expected total power")
    func testThreeLasersProduceExpectedTotalPower() async throws {
        #expect(abs(monitor.totalLaserPowerW - 120.0) < 0.000_001)
    }

    @Test("Laser off sets total power to zero")
    func testLaserOffSetsTotalPowerToZero() async throws {
        monitor.laserOn = false
        #expect(abs(monitor.totalLaserPowerW - 0.0) < 0.000_001)
    }

    // MARK: Phase and Coherence
    @Test("Perfect phase alignment produces full coherence")
    func testPerfectPhaseAlignmentProducesFullCoherence() async throws {
        monitor.laser2PhaseOffset = 0.0
        monitor.laser3PhaseOffset = 0.0
        #expect(abs(monitor.phaseCoherence - 1.0) < 0.000_001)
        #expect(abs(monitor.beamUniformity - 1.0) < 0.000_001)
    }

    @Test("Phase mismatch reduces coherence")
    func testPhaseMismatchReducesCoherence() async throws {
        let aligned = monitor.phaseCoherence
        monitor.laser2PhaseOffset = .pi / 2.0
        monitor.laser3PhaseOffset = -.pi / 2.0
        #expect(monitor.phaseCoherence < aligned)
        #expect(monitor.beamUniformity < 1.0)
    }

    @Test("Phase difference between laser 2 and 3 matters")
    func testPhaseDifferenceBetweenLaserTwoAndThreeMatters() async throws {
        monitor.laser2PhaseOffset = .pi / 2.0
        monitor.laser3PhaseOffset = -.pi / 2.0
        let opposing = monitor.phaseCoherence
        monitor.laser3PhaseOffset = .pi / 2.0
        let matched = monitor.phaseCoherence
        #expect(matched > opposing)
    }

    // MARK: Cavity Resonance
    @Test("On resonance produces maximum resonance factor")
    func testOnResonanceProducesMaximumResonanceFactor() async throws {
        monitor.detuning = 0.0
        #expect(abs(monitor.resonanceFactor - 1.0) < 0.000_001)
    }

    @Test("Detuning reduces resonance factor")
    func testDetuningReducesResonanceFactor() async throws {
        monitor.detuning = 0.0
        let onReson = monitor.resonanceFactor
        monitor.detuning = 0.10
        let detuned = monitor.resonanceFactor
        #expect(detuned < onReson)
    }

    @Test("On resonance produces higher circulating power")
    func testOnResonanceProducesHigherCirculatingPower() async throws {
        monitor.detuning = 0.0
        let resonantP = monitor.circulatingPowerW
        monitor.detuning = 0.10
        let detunedP = monitor.circulatingPowerW
        #expect(resonantP > detunedP)
    }

    @Test("Laser off sets cavity outputs to zero")
    func testLaserOffSetsCavityOutputsToZero() async throws {
        monitor.laserOn = false
        #expect(abs(monitor.buildupFactor - 0.0) < 0.000_001)
        #expect(abs(monitor.circulatingPowerW - 0.0) < 0.000_001)
        #expect(abs(monitor.standingWaveStrength - 0.0) < 0.000_001)
    }

    // MARK: QRTL Shell Model
    @Test("Shell starts at zero after reset")
    func testShellStartsAtZeroAfterReset() async throws {
        monitor.resetRun()
        #expect(abs(monitor.shellResonantAmplitude - 0.0) < 0.000_001)
        #expect(abs(monitor.shellThresholdFraction - 0.0) < 0.000_001)
        #expect(abs(monitor.resonantShellTransitionRateGPerHr - 0.0) < 0.000_001)
    }

    @Test("Shell does not produce nonlinear output at startup")
    func testShellDoesNotProduceNonlinearOutputAtStartup() async throws {
        #expect(!monitor.isNonlinearRegime)
        #expect(abs(monitor.resonantShellTransitionRateGPerHr - 0.0) < 0.000_001)
    }

    @Test("QRTL disabled cannot enter nonlinear regime")
    func testQRTLDisabledCannotEnterNonlinearRegime() async throws {
        monitor.qrtlEnabled = false
        monitor.shellInstabilityThreshold = 0.01
        advanceShell(by: 30.0, step: 0.1)
        #expect(!monitor.isNonlinearRegime)
        #expect(abs(monitor.resonantShellTransitionRateGPerHr - 0.0) < 0.000_001)
    }

    @Test("No Ca40 cannot enter nonlinear regime")
    func testNoCa40CannotEnterNonlinearRegime() async throws {
        monitor.ca40Present = false
        monitor.shellInstabilityThreshold = 0.01
        advanceShell(by: 30.0, step: 0.1)
        #expect(!monitor.isNonlinearRegime)
        #expect(abs(monitor.resonantShellTransitionRateGPerHr - 0.0) < 0.000_001)
    }

    @Test("Shell can reach threshold under ideal resonance")
    func testShellCanReachThresholdUnderIdealResonance() async throws {
        monitor.shellInstabilityThreshold = 0.10
        monitor.shellCouplingEfficiency = 1.0
        monitor.shellCoherenceLifetimeS = 20.0
        advanceShell(by: 10.0, step: 0.1)
        #expect(monitor.shellResonantAmplitude >= monitor.shellInstabilityThreshold)
        #expect(monitor.isNonlinearRegime)
        #expect(monitor.resonantShellTransitionRateGPerHr > 0.0)
    }

    @Test("Detuning prevents shell transition")
    func testDetuningPreventsShellTransition() async throws {
        monitor.shellInstabilityThreshold = 0.10
        monitor.shellCouplingEfficiency = 1.0
        monitor.shellCoherenceLifetimeS = 20.0
        monitor.detuning = 1.0
        advanceShell(by: 10.0, step: 0.1)
        #expect(monitor.resonanceFactor < 0.90)
        #expect(!monitor.isNonlinearRegime)
        #expect(abs(monitor.resonantShellTransitionRateGPerHr - 0.0) < 0.000_001)
    }

    @Test("Phase decoherence prevents shell transition")
    func testPhaseDecoherencePreventsShellTransition() async throws {
        monitor.shellInstabilityThreshold = 0.10
        monitor.shellCouplingEfficiency = 1.0
        monitor.shellCoherenceLifetimeS = 20.0
        monitor.laser2PhaseOffset = .pi / 2.0
        monitor.laser3PhaseOffset = -.pi / 2.0
        advanceShell(by: 10.0, step: 0.1)
        #expect(monitor.phaseCoherence < 0.90)
        #expect(!monitor.isNonlinearRegime)
        #expect(abs(monitor.resonantShellTransitionRateGPerHr - 0.0) < 0.000_001)
    }

    @Test("Shell amplitude falls when laser turns off")
    func testShellAmplitudeFallsWhenLaserTurnsOff() async throws {
        monitor.shellInstabilityThreshold = 10.0
        monitor.shellCouplingEfficiency = 1.0
        monitor.shellCoherenceLifetimeS = 2.0
        advanceShell(by: 2.0, step: 0.1)
        let charged = monitor.shellResonantAmplitude
        #expect(charged > 0.0)
        monitor.laserOn = false
        advanceShell(by: 2.0, step: 0.1)
        #expect(monitor.shellResonantAmplitude < charged)
    }

    @Test("Shell threshold fraction tracks amplitude")
    func testShellThresholdFractionTracksAmplitude() async throws {
        monitor.shellInstabilityThreshold = 2.0
        monitor.shellCouplingEfficiency = 1.0
        monitor.shellCoherenceLifetimeS = 20.0
        advanceShell(by: 1.0, step: 0.1)
        let expected = min(monitor.shellResonantAmplitude / monitor.shellInstabilityThreshold, 2.0)
        #expect(abs(monitor.shellThresholdFraction - expected) < 0.000_001)
    }

    // MARK: Hydrogen / Oxygen Model
    @Test("Oxygen rate uses water mass stoichiometry")
    func testOxygenRateUsesWaterMassStoichiometry() async throws {
        #expect(abs(monitor.oxygenRateGPerHr - monitor.hydrogenRateGPerHr * 8.0) < 0.000_001)
    }

    @Test("Hydrogen rate includes QRTL transition rate")
    func testHydrogenRateIncludesQRTLTransitionRate() async throws {
        monitor.shellInstabilityThreshold = 0.10
        monitor.shellCouplingEfficiency = 1.0
        monitor.shellCoherenceLifetimeS = 20.0
        advanceShell(by: 10.0, step: 0.1)
        #expect(monitor.isNonlinearRegime)
        #expect(monitor.hydrogenRateGPerHr > monitor.resonantShellTransitionRateGPerHr)
    }

    // MARK: Economics
    @Test("Reset clears accumulated production and cost")
    func testResetClearsAccumulatedProductionAndCost() async throws {
        advanceShell(by: 5.0, step: 0.1)
        monitor.resetRun()
        #expect(abs(monitor.hydrogenProducedKg - 0.0) < 0.000_001)
        #expect(abs(monitor.oxygenProducedKg - 0.0) < 0.000_001)
        #expect(abs(monitor.electricityConsumedKWh - 0.0) < 0.000_001)
        #expect(abs(monitor.electricityCost - 0.0) < 0.000_001)
    }

    @Test("Profit matches revenue minus operating cost")
    func testProfitMatchesRevenueMinusOperatingCost() async throws {
        advanceShell(by: 5.0, step: 0.1)
        #expect(abs(monitor.profit - (monitor.revenue - monitor.totalOperatingCost)) < 0.000_001)
    }

    
    // MARK: Test Helpers
    private func advanceShell(by durationS: Double, step: Double) {
        let steps = Int((durationS / step).rounded(.down))
        for _ in 0..<steps {
            monitor.advanceSimulationForTesting(deltaTimeS: step)
        }
    }
}
