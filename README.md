# 🔥 SMR Reaction Optimisation via Neural Networks

> **Maximising methane conversion in Steam Methane Reforming (SMR) using deep neural networks and grid search — without running expensive experiments.**

[![Python](https://img.shields.io/badge/Python-3.8%2B-3776AB?style=flat-square&logo=python&logoColor=white)](https://www.python.org/)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.0%2B-EE4C2C?style=flat-square&logo=pytorch&logoColor=white)](https://pytorch.org/)
[![MATLAB](https://img.shields.io/badge/MATLAB-R2023+-0076A8?style=flat-square&logo=mathworks&logoColor=white)](https://www.mathworks.com/)
[![Streamlit](https://img.shields.io/badge/Streamlit-1.32%2B-FF4B4B?style=flat-square&logo=streamlit&logoColor=white)](https://streamlit.io/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

## 📌 Overview

Steam Methane Reforming (SMR) is responsible for ~50% of the world's hydrogen production. Finding the optimal operating conditions (temperature, pressure, steam-to-carbon ratio, catalyst mass, and inlet velocity) to **maximise methane conversion** traditionally requires running thousands of expensive experiments.

This project replaces that with a **neural network surrogate model** trained on ODE-simulated data. A **grid search** over 100,000 combinations then identifies the optimal operating point — at a fraction of the cost and time.

**Key result:** Neural network prediction of **71.34%** conversion vs. numerical solver value of **71.03%** — a relative error of just **0.43%**.

---

## ✨ Features

- 🧪 **Physics-based data generation** via MATLAB ODE solver (`ode23s`) using Xu & Froment (1989) kinetics
- 🧠 **Deep neural network** (PyTorch) with ReLU activation, trained on 7,776 ODE-simulated data points
- 🔍 **Grid search** over 100,000 operating condition combinations for global optimum identification
- 📊 **Interactive Streamlit dashboard** for exploring predictions and optimal conditions
- 📉 **Architecture ablation study** — from 8 hidden layers (17,800 weights) down to 1 layer with 500 neurons (3,000 weights) with comparable accuracy
- ⚡ Validated against independent numerical solutions

---

## 🏗️ Project Structure

```
smr-nn-optimisation/
│
├── notebook/OptimisationSMR_NN_8HiddenLayers.ipynb        # Main Jupyter notebook (training + grid search)
├── matlab/OptimisationSMRDataGeneratorU_Included.m       # MATLAB data generator (ODE solver)
├── data/OptimiserDataU_Included_NewRangeWithoutTin.xlsx # Generated training dataset
├── requirements.txt                               # Python dependencies
└── README.md
```

---

## ⚙️ Methodology

### 1. Data Generation (MATLAB)

The MATLAB script solves a zero-dimensional coupled ODE system (species balances for CH₄, H₂O, CO, H₂, CO₂) using `ode23s` for different combinations of operating parameters:

| Parameter | Range |
|-----------|-------|
| Reaction Temperature (T_rxn) | 600 – 800 °C |
| Inlet Velocity (U) | 0.5 – 5 m/s |
| Total Pressure (Pₜ) | 7 – 20 bar |
| Steam-to-Carbon Ratio (S/C) | 1 – 3 |
| Catalyst Mass (W_cat) | 500 – 1000 kg |

With `npts = 6`, this yields **7,776 training combinations**. The target variable is methane conversion (Wisman method).

Kinetic parameters follow **Xu & Froment (1989)** for the three reactions:
- **SMR**: CH₄ + H₂O ⇌ CO + 3H₂
- **WGS**: CO + H₂O ⇌ CO₂ + H₂
- **GRR**: CH₄ + 2H₂O ⇌ CO₂ + 4H₂

### 2. Neural Network (PyTorch)

- **Input layer**: 5 features (T_rxn, S/C, Pₜ, W_cat, U)
- **Hidden layers**: 8 layers × 50 neurons (ReLU activation)
- **Output layer**: 1 neuron (predicted conversion)
- **Scaling**: StandardScaler
- **Loss**: MSE | **Learning rate**: 1e-5 | **Train/Test split**: 80/20

### 3. Grid Search

The trained network predicts conversions for **100,000 new combinations** (npts = 10). Grid search identifies the optimal point, which is then validated against the numerical solver.

---

## 📊 Results

### Optimal Operating Conditions (Grid Search)

| T_rxn (°C) | S/C | Pressure (bar) | Catalyst Mass (kg) | Inlet Velocity (m/s) |
|------------|-----|---------------|-------------------|----------------------|
| 800 | 2 | 7 | 667.67 | 2 |

| | Conversion (%) |
|--|--|
| Neural Network Prediction | **71.34%** |
| Numerical Solver (validation) | **71.03%** |
| Relative Error | **0.43%** |

### Architecture Ablation

| Hidden Layers | Neurons/Layer | Total Weights | Predicted Conv. | Relative Error |
|:---:|:---:|:---:|:---:|:---:|
| 8 | 50 | 17,800 | 71.34% | 0.43% |
| 4 | 50 | 7,800 | 71.18% | 0.21% |
| 2 | 50 | 2,800 | 69.68% | 1.90% |
| 1 | 50 | 300 | 68.01% | 4.25% |
| **1** | **500** | **3,000** | **71.16%** | **0.18%** |

> ✅ **Best trade-off**: 1 hidden layer × 500 neurons — only 3,000 weights with just 0.18% error.

### Activation Function Comparison (1 layer, 500 neurons)

| Activation | Predicted Conv. | Relative Error |
|---|---|---|
| **ReLU** | **71.16%** | **0.18%** |
| Tanh | 67.80% | 4.54% |
| SoftPlus | 67.27% | 5.29% |

---

## 🔬 References

1. Jianguo Xu, Gilbert F. Froment — *Methane Steam Reforming, Methanation and Water-Gas Shift: 1, Intrinsic Kinetics*, AIChE Journal, 1989
2. Sebastian T. Wismann et al. — *Electrified Methane Reforming: Understanding the Dynamic Interplay*, Ind. Eng. Chem. Res., 2019
3. Giovanni Franchi et al. — *Hydrogen Production via Steam Reforming: A Critical Analysis of MR and RMM Technologies*, 2019

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
