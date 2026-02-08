using MacroModelling
using DataFrames
using CSV
using Plots 

# 1. DEFINICIÓ DEL MODEL
# ---------------------------------------------------------


@model RBC begin
    # Paràmetres
    beta = 0.99      # Paciència (aprox 4% interès anual)
    alpha = 0.33     # Pes del capital
    delta = 0.025    # Depreciació (2.5% trimestral)
    gamma = 2.0      # Pes de l'oci
    rho = 0.95       # Persistència del xoc
    sigma_z = 0.01   # Volatilitat del xoc (1%)

    
    # 1. Euler Equation (1/c_t = beta * E_t [...])
    1 / c[0] = beta * (1 / c[1]) * (r[1] + 1 - delta)

    # 2. Oferta de Treball (gamma * c / (1-n) = w)
    (gamma * c[0]) / (1 - n[0]) = w[0]

    # 3. Funció de Producció (Cobb-Douglas)
    y[0] = exp(z[0]) * k[-1]^alpha * n[0]^(1 - alpha)

    # 4. Preus dels Factors (Marginals)
    w[0] = (1 - alpha) * y[0] / n[0]
    r[0] = alpha * y[0] / k[-1]

    # 5. Restricció de Recursos
    y[0] = c[0] + i[0]

    # 6. Llei de Moviment del Capital
    k[0] = (1 - delta) * k[-1] + i[0]

    # 7. Procés del Xoc Tecnològic (AR1 en logs)
    # z[0] és log(A_t).
    z[0] = rho * z[-1] + sigma_z * eps_z[x]
end

# 2. CALIBRATGE I SOLUCIÓ
# ---------------------------------------------------------
# Obtenim l'estat estacionari (SS) automàticament
ss = get_steady_state(RBC)

println("--- Estat Estacionari ---")
println(ss)

# 3. SIMULACIÓ DE DADES
# ---------------------------------------------------------
# Simulem 200 trimestres (50 anys)
# El paquet genera els xocs aleatoris automàticament basant-se en 'eps_z'

simulated_data = simulate(RBC, periods = 200)

# El resultat és un DataFrame amb molta info (nivells, desviacions, xocs...)
# Seleccionem només les variables en nivells per al CSV
df_clean = simulated_data[:, [:period, :c, :n, :y, :i, :w, :r, :k, :z]]


# 4. GUARDAR A CSV
# ---------------------------------------------------------
csv_filename = "../../data/rbc_simulated_data.csv"
CSV.write(csv_filename, df_clean)

println("\nSimulació completada! Dades guardades a: $csv_filename")

# 5. VISUALITZACIÓ RÀPIDA (OPCIONAL)
# ---------------------------------------------------------
plot(
    simulated_data.period, 
    [simulated_data.y, simulated_data.c, simulated_data.i],
    label = ["Output (y)" "Consumption (c)" "Investment (i)"],
    title = "Simulació RBC (MacroModelling.jl)",
    lw = 2
)