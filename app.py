import streamlit as st
import torch
import torch.nn as nn
import numpy as np
import joblib

# Must match your notebook exactly
class SMRNet(nn.Module):
    def __init__(self, input_size, hidden_size, output_size):
        super(SMRNet, self).__init__()
        self.fc1  = nn.Linear(input_size, hidden_size)
        self.relu = nn.ReLU()
        self.fc2  = nn.Linear(hidden_size, hidden_size)
        self.fc3  = nn.Linear(hidden_size, hidden_size)
        self.fc4  = nn.Linear(hidden_size, hidden_size)
        self.fc5  = nn.Linear(hidden_size, hidden_size)
        self.fc6  = nn.Linear(hidden_size, hidden_size)
        self.fc7  = nn.Linear(hidden_size, hidden_size)
        self.fc8  = nn.Linear(hidden_size, hidden_size)
        self.fc9  = nn.Linear(hidden_size, hidden_size)
        self.fc10 = nn.Linear(hidden_size, output_size)

    def forward(self, x):
        x = self.relu(self.fc1(x))
        x = self.relu(self.fc2(x))
        x = self.relu(self.fc3(x))
        x = self.relu(self.fc4(x))
        x = self.relu(self.fc5(x))
        x = self.relu(self.fc6(x))
        x = self.relu(self.fc7(x))
        x = self.relu(self.fc8(x))
        x = self.relu(self.fc9(x))
        x = self.fc10(x)
        return x

@st.cache_resource          # loads once, not on every slider move
def load_all():
    model = SMRNet(5, 50, 1)
    model.load_state_dict(torch.load("smr_model.pt", map_location="cpu"))
    model.eval()
    x_scaler = joblib.load("x_scaler.pkl")
    y_scaler = joblib.load("y_scaler.pkl")
    return model, x_scaler, y_scaler

model, x_scaler, y_scaler = load_all()


st.title("SMR Neural Network Optimizer")

st.sidebar.header("Process Parameters")

T    = st.sidebar.slider("Temperature (K)",     873.15, 1073.15, 973.15, step=10.0)
SC   = st.sidebar.slider("Steam/Carbon ratio",  1.0,    3.0,     2.0,    step=0.1)
Pt   = st.sidebar.slider("Pressure (bar)",      7.0,    20.0,    13.5,   step=0.5)
Cat  = st.sidebar.slider("Catalyst amount (g)", 500.0,  1000.0,  750.0,  step=50.0)
U    = st.sidebar.slider("Velocity (m/s)",      1.0,    10.0,    5.5,    step=0.1)



# Scale → predict → inverse scale
inputs  = np.array([[T, SC, Pt, Cat, U]])
scaled  = x_scaler.transform(inputs)
tensor  = torch.tensor(scaled, dtype=torch.float32)

with torch.no_grad():
    pred_scaled = model(tensor).item()

conversion = y_scaler.inverse_transform([[pred_scaled]])[0][0] * 100

st.subheader("Predicted CH₄ Conversion")
st.metric(label="Conversion", value=f"{conversion:.2f}%")
st.progress(min(conversion / 75, 1.0))   # bar scaled to max ~75%



st.markdown("---")
st.subheader("Grid Search — Find Optimal Conditions")

if st.button("Run Optimizer (100K combinations)"):
    with st.spinner("Searching..."):

        T_r   = np.linspace(873.15, 1073.15, 10)
        SC_r  = np.linspace(1.0,    3.0,     10)
        Pt_r  = np.linspace(7.0,    20.0,    10)
        Cat_r = np.linspace(500.0,  1000.0,  10)
        U_r   = np.linspace(1.0,    10.0,    10)

        T_g, SC_g, Pt_g, Cat_g, U_g = np.meshgrid(T_r, SC_r, Pt_r, Cat_r, U_r)
        X_grid = np.vstack([T_g.ravel(), SC_g.ravel(),
                            Pt_g.ravel(), Cat_g.ravel(), U_g.ravel()]).T

        # Batch predict — much faster than a loop
        X_sc  = x_scaler.transform(X_grid)
        X_ten = torch.tensor(X_sc, dtype=torch.float32)
        with torch.no_grad():
            preds = model(X_ten).numpy().ravel()
        preds = y_scaler.inverse_transform(preds.reshape(-1, 1)).ravel()

        best_i    = np.argmax(preds)
        best_p    = X_grid[best_i]
        best_conv = preds[best_i] * 100

    st.success(f"Best conversion: {best_conv:.3f}%")
    st.table({
        "Parameter": ["Temperature (K)", "S/C ratio", "Pressure (bar)", "Catalyst (g)", "Velocity (m/s)"],
        "Optimal":   [f"{best_p[0]:.2f}", f"{best_p[1]:.2f}", f"{best_p[2]:.2f}",
                      f"{best_p[3]:.1f}", f"{best_p[4]:.2f}"]
    })