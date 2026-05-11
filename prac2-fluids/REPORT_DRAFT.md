# ENGR30002 Fluid Mechanics
## Practical 2: Elements & Evaluation of a Centrifugal Pump

**Student Name:** [Your official name]
**Student ID:** [Your ID]
**Date:** 2026-05-11

---

## Abstract

This practical investigated the operation and performance of a 100 W centrifugal pump. The pump was first dismantled to identify its principal components (impeller, volute, motor, seals). Performance was then characterised across three speed settings by measuring the pump head h_P as a function of volumetric flow rate Q. Experimental data were fitted to the form h_P = a + b·Q^c (R² > 0.996 for all settings), giving shutoff heads of 3.31 m, 4.79 m and 5.61 m for the Slow, Mid and High settings respectively. A theoretical system head curve was constructed for the valve-fully-open configuration using the Fanning friction factor (Haaland equation) and tabulated minor-loss coefficients. The theoretical system head underpredicted the measured head loss by a factor of approximately 3 at all three operating points, with the orifice flow meter contributing the largest single source of theoretical loss (~50% of h_sys). The discrepancy is attributed primarily to an underestimated flow-meter resistance coefficient and unaccounted-for losses in pipe fittings and unions.

---

## Aim

1. To dismantle a centrifugal pump and identify its constituent components.
2. To determine the performance curve of a 100 W centrifugal pump at three speed settings.
3. To construct a theoretical system head curve and determine operating conditions for the pump.

---

## Questions

### (a) System sketch

**See Figure A1.** The piping system consists of (from inlet to outlet):

| Element | Length / size | Location |
|---|---|---|
| Reservoir entrance (sharp-edged) | DN25, ID 25 mm | Pipe inlet |
| DN25 PVC pipe (section 1) | L = 108 cm, D = 25 mm | Reservoir → contraction |
| Centrifugal pump | — | Within DN25 section |
| Gate valve (fully open during this test) | — | Within DN25 section |
| 2 × 90° elbows | — | Within DN25 section |
| Contraction DN25 → DN20 | sudden | Before flow meter |
| DN20 PVC pipe | L = 39 cm, D = 20 mm | Contraction → expansion |
| Orifice flow meter (DN20 → DN14 → DN20) | ID 14 mm | Mid of DN20 section, K = 2.7 |
| Expansion DN20 → DN25 | sudden | After flow meter |
| DN25 PVC pipe (section 2) | L = 22 cm, D = 25 mm | Expansion → tank |
| Reservoir exit (pipe → tank) | — | Pipe exit |

Minor losses occur at: pipe entrance, gate valve, 2 elbows, sudden contraction (25→20), flow meter, sudden expansion (20→25), pipe exit. Major losses (pipe friction) occur in the three pipe sections (1.30 m total of DN25 and 0.39 m of DN20).

---

### (b) Priming a pump

**Priming** is the process of filling the pump casing and suction line with the working liquid prior to startup, displacing any trapped air. It is essential for centrifugal pumps because they are not self-priming: the impeller develops head by transferring kinetic energy to the liquid via centrifugal action, and air is too low in density for the impeller to generate sufficient suction pressure to draw water up from the reservoir. Consequences of running an unprimed pump include:

- **No flow develops** — the pump cannot lift water against the suction-side static head.
- **Mechanical seal damage** — many pump seals are cooled and lubricated by the working fluid; dry running rapidly destroys them.
- **Cavitation-like vibration** as air pockets collapse, accelerating bearing wear.

In this practical the water-sealing bolt is loosened to vent trapped air while the system fills, and re-tightened once a continuous stream of water flows through.

---

### (c) Experimental pump curves (h_P vs Q)

The pump head was computed from the gauge readings using

$$h_P = \frac{P_4 - P_3}{\rho g}$$

with ρ = 1000 kg/m³ and g = 9.81 m/s². Since P_4 is the only gauge reading (P_3 ≈ atmospheric on the suction side at the tank free surface), h_P (m) = P_gauge (kPa) / 9.81.

**See Figure 1** for h_P vs Q data for all three settings.

| Setting | P (kPa) range | Q (L/min) range | Shutoff head (m) |
|---|---|---|---|
| Slow (I) | 32.5 → 10 | 0 → 20.65 | 3.31 |
| Mid (II) | 47 → 20 | 0 → 28.40 | 4.79 |
| High (III) | 55 → 30 | 0 → 36.36 | 5.61 |

---

### (d) Pump curve fits: h_P = a + b·Q^c

Nonlinear least-squares fitting (MATLAB `lsqcurvefit`) gives:

| Setting | a (m) | b | c | R² |
|---|---|---|---|---|
| **Slow** | 3.3395 | −0.16888 | 0.8747 | 0.9967 |
| **Mid** | 4.7939 | −0.06548 | 1.1210 | 0.9986 |
| **High** | 5.5369 | −0.02546 | 1.2733 | 0.9966 |

**See Figure 2** for fits overlaid on data. All three fits achieve R² > 0.996 and the parameter a closely matches the experimentally-measured shutoff head, confirming the fit is consistent with the Q = 0 boundary.

**Physical interpretation:** the parameter a equals the shutoff head (maximum pressure rise the pump can develop at zero flow), b·Q^c is the head-degradation term as flow increases, and c reflects the curvature of the pump characteristic (closer to 1 = closer to linear, > 1 = increasingly steep at high Q).

---

### (e) Throttling valve and NPSH

**Purpose of a throttling valve:** to control the volumetric flow rate Q through a piping system. The valve introduces a variable resistance coefficient K, increasing the friction head of the system. The system head curve h_sys(Q) is therefore shifted upward, and its intersection with the pump curve (which is fixed for a given speed setting) moves to a lower Q. This allows the operator to set Q to any desired value below the wide-open value.

**Implications of placing a throttling valve before (upstream of) the pump inlet — NPSH analysis:**

The Net Positive Suction Head available is

$$NPSH_A = \frac{P_1 - P_{vap}}{\rho g} + z_1 - h_{fs}$$

where h_fs is the friction head loss on the suction side of the pump. Placing the throttling valve upstream of the pump inlet adds a substantial K-value to the suction-side losses, directly increasing h_fs and therefore decreasing NPSH_A. If NPSH_A falls below NPSH_R (the pump's required NPSH), the liquid pressure on the suction side falls below its vapour pressure, vapour bubbles form, and **cavitation** occurs. Consequences of cavitation include:

- Sudden noise and vibration as bubbles collapse on the impeller.
- Pitting damage to the impeller blades and pump casing.
- Loss of pump head and efficiency.

For these reasons, throttling valves are always placed on the **discharge** (high-pressure) side of the pump, where the additional pressure drop does not impact NPSH_A. The suction side is kept as low-resistance as practicable.

---

### (f) Theoretical system head curve

The mechanical energy balance between the reservoir surface (point 1) and the discharge into the tank (point 2) reduces to:

$$h_P = h_L = \sum_i 2 f_F \left(\frac{L}{D}\right)_i \frac{V_i^2}{g} + \sum_j K_j \frac{V_j^2}{2g}$$

since both surfaces are at atmospheric pressure, both have negligible surface velocity, and there is no elevation change. The pump head therefore equals the total system head loss.

**Assumptions:**
- Water at 20 °C: ρ = 1000 kg/m³, μ = 1.0 × 10⁻³ Pa·s
- PVC pipe taken as hydraulically smooth (ε ≈ 1.5 × 10⁻⁶ m = drawn-tubing value)
- Turbulent flow (verified — see below), so α = 1
- Sharp-edged pipe entrance/exit

**Friction factor** (Fanning) calculated from the Haaland correlation, then converted:

$$\frac{1}{\sqrt{f_D}} = -1.8 \log_{10}\!\left[ \frac{6.9}{Re} + \left(\frac{\varepsilon/D}{3.7}\right)^{1.11}\right], \quad f_F = f_D/4$$

**Resistance coefficients used:**

| Element | K value | Velocity used |
|---|---|---|
| Pipe entrance (sharp-edged) | 0.5 | V_25 |
| Gate valve (fully open) | 0.2 | V_25 |
| 90° threaded elbow (×2) | 0.9 each | V_25 |
| Sudden contraction (25→20, d²/D² = 0.64) | 0.20 | V_20 |
| Orifice flow meter (given) | 2.7 | V_20 |
| Sudden expansion (20→25), K = (1 − A_20/A_25)² | 0.130 | V_20 |
| Pipe exit (pipe → tank) | 1.0 | V_25 |

(values from Cengel & Cimbala Table 8-4 and Topic 4 lecture notes)

**Flow regime check** (at maximum flow, Q = 36.36 L/min):

| Section | V (m/s) | Re | Regime |
|---|---|---|---|
| DN25 | 1.235 | 30,863 | turbulent |
| DN20 | 1.929 | 38,579 | turbulent |

Both Re ≫ 4000 so the turbulent assumption is valid.

**The system head curve is shown in Figure 3.** It is approximately quadratic in Q (since all loss terms are ∝ V²) and rises from 0 m at Q = 0 to approximately 2.7 m at Q = 60 L/min.

---

### (g) Comparison of experimental and theoretical system head losses

At the valve-fully-open condition, the pump head equals the total system head loss (since Δz = 0, ΔP = 0, ΔV² = 0 at the tank surfaces). The experimental operating points are:

| Setting | Q_exp (L/min) | h_P,exp = h_sys,exp (m) | h_sys,theory (m) | Ratio exp/theory |
|---|---|---|---|---|
| Slow | 20.65 | 1.019 | 0.338 | 3.02 × |
| Mid  | 28.40 | 2.039 | 0.630 | 3.24 × |
| High | 36.36 | 3.058 | 1.022 | 2.99 × |

**Theoretical operating points** (intersection of pump curve and theoretical system curve, Figure 4):

| Setting | Q_theory (L/min) | h_theory (m) | Q_exp (L/min) | Q error |
|---|---|---|---|---|
| Slow | 25.14 | 0.505 | 20.65 | +21.7% |
| Mid  | 36.85 | 1.060 | 28.40 | +29.8% |
| High | 49.47 | 1.879 | 36.36 | +36.0% |

**Head-loss breakdown at each experimental operating point** (theoretical, m):

| Loss term | Slow (20.65 L/min) | Mid (28.40 L/min) | High (36.36 L/min) |
|---|---|---|---|
| Friction DN25 (1.30 m) | 0.0348 | 0.0608 | 0.0940 |
| Friction DN20 (0.39 m) | 0.0302 | 0.0529 | 0.0819 |
| Entrance (K=0.5) | 0.0125 | 0.0237 | 0.0388 |
| Gate valve (K=0.2) | 0.0050 | 0.0095 | 0.0155 |
| 2 × 90° elbow | 0.0451 | 0.0853 | 0.1398 |
| Contraction (K=0.20) | 0.0122 | 0.0231 | 0.0379 |
| **Flow meter (K=2.7)** | **0.1652** | **0.3124** | **0.5120** |
| Expansion (K=0.130) | 0.0079 | 0.0150 | 0.0246 |
| Exit (K=1.0) | 0.0251 | 0.0474 | 0.0777 |
| **Total h_sys (m)** | **0.338** | **0.630** | **1.022** |

**Discussion of discrepancies:**

The experimental system head loss is approximately **3.0–3.2× larger** than the theoretical prediction across all three settings. Importantly, this ratio is essentially constant, suggesting a **systematic underestimation** rather than random error. Several factors likely contribute:

1. **Orifice flow meter K-value underestimated.** The given K = 2.7 already represents 49–50% of the theoretical h_sys. Real orifice meters with β = d/D = 14/20 = 0.7 typically have full-loss coefficients in the range K = 5–15 (depending on Re and edge geometry). If the actual K_flowmeter ≈ 10, the theoretical h_sys would roughly double, closing about half the gap.

2. **Gate valve not perfectly open.** A gate valve at 75% open has K ≈ 0.3 (vs 0.2 fully open); even slightly partial closure significantly raises losses.

3. **Additional minor losses not accounted for.** The system contains barrel unions, threaded couplings and pipe-end fittings, each contributing K ≈ 0.05–0.1. Summed, these could add 0.3–0.5 to the total ΣK.

4. **Pipe roughness.** PVC was assumed smooth (ε = 1.5 µm), but assembly joints, glue residue and connector edges raise the effective roughness. The friction factor would be modestly higher (~15–20%) on a Moody chart with realistic ε ≈ 0.05 mm.

5. **Pump head includes pump-internal losses.** Strictly, h_P is the head delivered by the pump impeller to the fluid; some of the measured (P_4 − P_3) might include losses across the gauge tappings themselves.

6. **Measurement uncertainty** in pressure gauges (±0.5 kPa typical) and flow meter (±5% typical) compounds toward the experimental side.

**Conclusion of comparison:** While the *shape* of the theoretical system curve correctly captures the quadratic Q² dependence, the *magnitude* is significantly underestimated, primarily because the standard K = 2.7 for the orifice flow meter is conservative for this specific geometry. A more accurate prediction would require either direct measurement of the flow meter pressure drop or a calibrated orifice-meter discharge coefficient.

---

## Conclusion

The three primary aims of the practical were achieved:

1. **Pump dismantling** revealed the standard centrifugal pump architecture: motor → drive shaft → impeller in volute casing with seals at the shaft penetration. The volute's expanding cross-section converts the impeller's kinetic energy gain into a pressure rise.

2. **Performance characterisation** yielded three smooth, monotonically-decreasing pump curves well fitted by h_P = a + bQ^c with R² > 0.996 for all settings. The shutoff heads (3.31, 4.79, 5.61 m) and maximum flows (20.65, 28.40, 36.36 L/min) scale approximately linearly with the dial setting, consistent with proportional speed control of the impeller.

3. **System curve** construction using standard friction-factor and minor-loss correlations correctly predicts the quadratic h_sys ∝ Q² form but underestimates the magnitude by a factor of approximately 3. The dominant contributor to losses is the orifice flow meter (~50% of theoretical h_sys), and its given K = 2.7 is the most likely source of error. The pump's operating point would shift to lower Q than predicted, with all theoretical predictions of Q being 22–36% higher than measured.

For improved theoretical accuracy, the flow meter K-value should be calibrated experimentally, and additional fitting losses (unions, couplings) should be included.

---

## Appendix

### A1. Pump curve fit calculations
Pump head computed as h_P = P_kPa / 9.81 (with ρ = 1000 kg/m³, g = 9.81 m/s²).
Nonlinear regression performed in MATLAB `lsqcurvefit` minimising the sum of squared residuals between data and h_P = a + b·Q^c.

### A2. Sample system head calculation at Q = 36.36 L/min

```
Q = 36.36 L/min = 6.06 × 10⁻⁴ m³/s
V_25 = Q / (π × 0.025² / 4) = 1.235 m/s
V_20 = Q / (π × 0.020² / 4) = 1.929 m/s
Re_25 = 1000 × 1.235 × 0.025 / 1e-3 = 30,863  (turbulent)
Re_20 = 1000 × 1.929 × 0.020 / 1e-3 = 38,579  (turbulent)

Haaland (smooth pipe, ε/D ≈ 0):
f_D,25 = 0.0233 → f_F,25 = 0.00582
f_D,20 = 0.0221 → f_F,20 = 0.00554

Major losses:
  h_f,25 = 2 × 0.00582 × (1.30 / 0.025) × 1.235² / 9.81 = 0.094 m
  h_f,20 = 2 × 0.00554 × (0.39 / 0.020) × 1.929² / 9.81 = 0.082 m

Minor losses (V²/2g terms):
  V_25²/2g = 0.0777 m;  V_20²/2g = 0.1896 m
  Entry      = 0.5 × 0.0777 = 0.0388 m
  Valve      = 0.2 × 0.0777 = 0.0155 m
  2 elbows   = 1.8 × 0.0777 = 0.140 m
  Contract   = 0.20 × 0.1896 = 0.0379 m
  Flow meter = 2.7  × 0.1896 = 0.512 m
  Expand     = 0.130 × 0.1896 = 0.0246 m
  Exit       = 1.0 × 0.0777 = 0.0777 m

Total h_sys = 1.022 m
Experimental h_sys at Q = 36.36 = 30/9.81 = 3.058 m
```

### A3. Raw data tables (transcribed from lab notes)

**Slow (Setting I)** — same format for Mid and High in main report Tables.

| P (kPa) | Q (L/min) | h_P (m) |
|---|---|---|
| 32.5 | 0.00 | 3.313 |
| 30.0 | 2.17 | 3.058 |
| 27.5 | 3.75 | 2.803 |
| 26.0 | 4.85 | 2.650 |
| 25.0 | 6.06 | 2.548 |
| 22.5 | 7.75 | 2.293 |
| 20.0 | 10.60 | 2.039 |
| 17.5 | 12.71 | 1.784 |
| 15.0 | 14.90 | 1.529 |
| 12.5 | 16.67 | 1.274 |
| 10.0 | 20.65 | 1.019 |

(Mid and High tables identical structure — see Section 4(c) summary, full data in MATLAB script `prac2_full_analysis.m`)

### A4. MATLAB script
Full analysis script is at `/Users/jincinga24/Documents/Playground/prac2-fluids/prac2_full_analysis.m`.
