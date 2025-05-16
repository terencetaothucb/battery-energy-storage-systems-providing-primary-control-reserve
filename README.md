# BESS PCR Simulation Framework

This repository contains a MATLAB-based simulation framework for reproducing the results of the paper:

**"Impact analysis of different operation strategies for battery energy storage systems providing primary control reserve"**  
*Johannes Fleer, Peter Stenzel, Journal of Energy Storage, 2016.*

## 📌 Overview

The code simulates the operation of a Battery Energy Storage System (BESS) providing **Primary Control Reserve (PCR)** in accordance with the German regulatory framework. It evaluates how different operational strategies—**overfulfillment**, **deadband utilization**, and **scheduled energy transactions**—affect BESS performance in terms of:

- Energy throughput
- State of Charge (SOC) distribution
- Full Cycle Equivalents (FCE)
- Schedule energy exchange

---

## 🗂 Repository Structure

| File / Folder           | Description |
|------------------------|-------------|
| `runBESS_PCR_Model.m`  | Main script to configure and run simulations. |
| `BESS_Parameters.m`    | Defines simulation parameters and scenario configurations. |
| `BESS_Simulator.m`     | Core function simulating BESS operation under frequency data. |
| `BESS_Utilities.m`     | Helper functions for SOC calculation, energy balance, and cycle counting. |
| `BESS_Visualization.m` | Tools for visualizing SOC distributions, energy exchanges, etc. |
| `FreqData.mat`         | High-resolution frequency data for several real-world days. |
| `FreqDataRep.mat`      | Synthetic full-year frequency profile built from sampled days. |

---

## ⚙️ How to Use

### 1. **Environment Requirements**
- MATLAB R2018b or newer (earlier versions may work)
- Statistics and Signal Processing Toolboxes (optional, for plotting)

### 2. **Running a Simulation**

Open `runBESS_PCR_Model.m` in MATLAB and execute:

```matlab
runBESS_PCR_Model
```

This will:
- Load frequency data from `FreqDataRep.mat`
- Load parameters via `BESS_Parameters.m`
- Simulate BESS behavior with selected operational strategies
- Output key metrics such as total energy throughput, FCE, and SOC distributions
- Optionally visualize results (see next section)

---

## 🧪 Reproduced Functions from the Paper

| Paper Section | Functionality in Code | Related Files |
|---------------|-----------------------|---------------|
| §3 Methodology | Simulation of frequency-driven PCR and battery response | `BESS_Simulator.m` |
| §4 Model calculations | Parameter studies on SOC bands, overfulfillment, transaction energy | `BESS_Parameters.m`, `runBESS_PCR_Model.m` |
| Fig. 9–18 | Energy exchange, SOC histogram, FCE analysis | `BESS_Visualization.m` |
| Eq. (1)–(9) | Implemented directly in power control logic | `BESS_Simulator.m`, `BESS_Utilities.m` |

---

## 🧩 Simulation Parameters

You can modify the following options inside `BESS_Parameters.m`:

- **Battery Size & Power**: `C`, `PPQ`
- **Charge/Discharge Efficiencies**: `eta_ch`, `eta_dis`
- **SOC Ranges** for:
  - Overfulfillment (`SOC1_low`, `SOC1_high`)
  - Deadband utilization (`SOC2_low`, `SOC2_high`)
  - Scheduled transactions (`SOC3_low`, `SOC3_high`)
- **Schedule Parameters**: power `P_ST`, duration `dt_contract`
- **Simulation Duration**: full year vs. limited test period

---

## 📈 Output & Visualization

Simulation results include:

- `FCE`: Full Cycle Equivalents per year
- `DEST`, `DEOF`, `DEDU`: Energy exchanged via transaction, overfulfillment, or deadband
- `SOC_hist`: SOC histogram over time
- `E_rate_dist`: Distribution of E-rates (C-rate proxy)

Use `BESS_Visualization.m` to plot:

```matlab
plotSOCDistribution(SOC_vector);
plotEnergyFlows(DEST, DEOF, DEDU);
```

---

## 🧠 Extensions

- Couple with detailed **battery degradation models** using DoD-sensitive metrics
- Extend to multi-BESS aggregation or hybrid systems (e.g., wind + BESS)
- Port to Python or Simulink for real-time or embedded simulation

---

## 📄 Reference

Fleer, J., & Stenzel, P. (2016). *Impact analysis of different operation strategies for battery energy storage systems providing primary control reserve*. Journal of Energy Storage, 8, 320–338. https://doi.org/10.1016/j.est.2016.02.003

---

## 📬 Contact

For questions or collaboration, please contact [Your Name] or open an issue in this repository.
