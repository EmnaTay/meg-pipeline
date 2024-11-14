import plotly.graph_objs as go
import plotly.io as pio
import os
import pandas as pd

# List of CSV file paths, one for each system
csv_files = [
    os.path.abspath(os.path.join("9-dashboard", "data", "system-status-dashboards", "vpixx-system-status.csv")),
    os.path.abspath(os.path.join( "9-dashboard",  "data", "system-status-dashboards", "qd-helium-system-status.csv")),
    os.path.abspath(os.path.join("9-dashboard",  "data", "system-status-dashboards", "opm-system-status.csv")),
    os.path.abspath(os.path.join("9-dashboard", "data","system-status-dashboards", "kit-system-status.csv")),
]
current_directory = os.getcwd()
print('Current directory:', current_directory)
# Ensure the output directory exists
output_dir = os.path.abspath(os.path.join("_static", "1-systems-dashboard"))
os.makedirs(output_dir, exist_ok=True)

# Function to create dashboard for each system
for csv_file in csv_files:
    # Read the CSV file into a pandas DataFrame
    df = pd.read_csv(csv_file)

    # Extract the system name from the CSV file name
    system_name = os.path.splitext(os.path.basename(csv_file))[0].replace("-", " ").title()

    # Get unique timestamps (weeks) for the dropdown
    timestamps = df["Timestamp"].unique()

    # Create a figure
    fig = go.Figure()

    # Add a trace for each timestamp (week)
    for timestamp in timestamps:
        filtered_df = df[df["Timestamp"] == timestamp]
        status = filtered_df["Status"].tolist()
        system_names = filtered_df["System Name"].tolist()

        fig.add_trace(
            go.Table(
                visible=(timestamp == max(timestamps)),  # Make the most recent week visible by default
                header=dict(values=["Status", "System Name"], fill_color="paleturquoise", align="left"),
                cells=dict(values=[status, system_names], fill_color="lavender", align="left"),
            )
        )

    # Add dropdown menu for selecting the week
    dropdown_buttons = [
        dict(
            args=[{"visible": [timestamp == t for t in timestamps]}],  # Show table for selected week
            label=f"Week {timestamp}",
            method="update",
        )
        for timestamp in timestamps
    ]

    # Update layout with dropdown and title
    fig.update_layout(
        title=f"{system_name} Status Dashboard",
        width=600,
        height=400,
        updatemenus=[
            dict(
                active=0,
                buttons=dropdown_buttons,
                x=1.15,
                xanchor="left",
                y=1.15,
                yanchor="top"
            )
        ]
    )

    # Define the output file path for each system
    output_file = os.path.join(output_dir, f"plotly_dashboard_{system_name.lower().replace(' ', '_')}.html")

    # Save the figure as an HTML file
    pio.write_html(fig, output_file)

    print(f"Dashboard for {system_name} generated and saved to {output_file}")
