import sys
import os
import logging
import traceback

from config import *

from dotenv import load_dotenv
from boxsdk import JWTAuth, Client
from boxsdk.exception import BoxAPIException
import pandas as pd
from datetime import datetime
import numpy as np
import mne

import plotly.graph_objects as go





def get_folder_id_by_path(path, client):
    folder_id = "0"  # Start with the root folder
    for folder_name in path.split("/"):
        items = client.folder(folder_id).get_items()
        folder_id = None
        for item in items:
            if item.type == "folder" and item.name == folder_name:
                folder_id = item.id
                break
        if folder_id is None:
            raise ValueError(f'Folder "{folder_name}" not found in path.')
    return folder_id

def compute_fft(data, sfreq):
    fft_data = np.fft.rfft(data, axis=-1)
    freqs = np.fft.rfftfreq(data.shape[-1], d=1 / sfreq)
    return freqs, np.abs(fft_data)
def remove_zero_channels(raw):
    data = raw.get_data()
    non_zero_indices = np.any(data != 0, axis=1)
    # print(non_zero_indices)
    raw.pick(
        [raw.ch_names[i] for i in range(len(non_zero_indices)) if non_zero_indices[i]]
    )
    return raw
def process_con_file(file_path):
    try:
        # 3 set to be the Threshold
        s_avg = 3
        # add other matrices here
        s_fft = 10


        #metrics = pd.read_csv(file_path)

        logging.info(f"Processing file: {file_path}")
        # Load the .con file using MNE
        raw = mne.io.read_raw_kit(file_path, preload=False, verbose=False)
        raw.pick(picks="meg")

        data_duration = raw.times[-1]

        if TMAX <= data_duration and TMIN <= data_duration:
            # Crop data:
            raw = raw.crop(TMIN, TMAX)
            logging.info(f"Cropped data for: {file_path}")

        raw = remove_zero_channels(raw)

        # Get data for all channels
        data = raw.get_data()

        #logging.info(f"Processing file: {file_path}, Data shape: {data.shape}")
        sfreq = raw.info["sfreq"]
        freqs, fft_data = compute_fft(data, sfreq)

        # Calculate average, variance and find the maximum across all channels
        avg = (np.mean(data)) * 1e15
        var = np.var(data)
        max_val = np.max(data) * 1e15
        # Status for avg
        status_avg = [
            (f"🟢 In the threshold" if avg < s_avg else f"🔴 Above the threshold")
        ]
        # Status for fft
        status_fft = [
            (f"🟢 In the threshold" if var < s_avg else f"🔴 Above the threshold")
        ]
        # status for max
        status_max = [
            (f"🟢 In the threshold" if max_val < s_avg else f"🔴 Above the threshold")
        ]

        return avg, var, max_val, status_avg, freqs, fft_data, status_fft, status_max
    except Exception as e:
        tb = traceback.format_exc()
        failed_function_name = traceback.extract_tb(sys.exc_info()[2])[-1].name
        logging.info(f"Error in function '{failed_function_name}': {e}")
        logging.info(f"Traceback: {tb}")
        return None

def process_all_con_files(base_folder, file_limit=None):
    """ """
    results = []
    file_count = 0  # Initialize a counter

    try:

        kit_csv = pd.read_csv(KIT_CSV_LOCAL_SAVE_PATH)

        kit_csv = kit_csv.dropna(how='all')

        for root, _, files in os.walk(base_folder):
            for file in files:
                if file.endswith(".con"):

                    if file in kit_csv['File Name'].values:
                        logging.info(f"File {file} found in KIT CSV")

                        if kit_csv.loc[kit_csv['File Name'] == file, 'Processing State'].values[0] == 'TO BE PROCESSED':

                            processing_state = "UNPROCESSED"
                            file_path = os.path.join(root, file)

                            result = process_con_file(file_path)

                            if result is None:
                                logging.info(f"Processing failed for {file_path}")
                            else:
                                # Process the file
                                (
                                    avg,
                                    var,
                                    max_val,
                                    status,
                                    freqs,
                                    fft_data,
                                    status_fft,
                                    status_max,
                                ) = result

                                # Extract date
                                #date = extract_date(file)
                                details = "Nothing added yet"
                                # date_str = (
                                #     date.strftime("%d-%m-%y %H:%M:%S")
                                #     if date
                                #     else "Unknown Date"
                                # )
                                processing_state = "PROCESSED"

                                # Append the result
                                new_values_dic = {
                                        "Processing State": processing_state,
                                        "Status for average values": status,
                                        "Average": avg,
                                        "Variance": var,
                                        "Status for max values": status_max,
                                        "Maximum": max_val,
                                        "Details": details,
                                    }

                                for key in new_values_dic.keys():
                                    # Cast each column to 'object' dtype
                                    kit_csv[key] = kit_csv[key].astype('object')

                                kit_csv.loc[kit_csv['File Name'] == file, new_values_dic.keys()] = (
                                    new_values_dic.values())


                                os.makedirs(os.path.dirname(KIT_CSV_LOCAL_SAVE_PATH), exist_ok=True)

                                kit_csv.to_csv(KIT_CSV_LOCAL_SAVE_PATH, index=False)


                            file_count += 1  # Increment the counter
                            if file_limit != None:
                                if file_count >= file_limit:
                                    break  # Stop processing after reaching the limit
                        else:
                            logging.info(f"File {file} already processed")

                    else:
                        logging.info(f"File {file} downloaded but not found in KIT CSV")


            if file_limit != None:
                if file_count >= file_limit:
                    break  # Stop outer loop if limit is reached


    except Exception as e:
        tb = traceback.format_exc()
        failed_function_name = traceback.extract_tb(sys.exc_info()[2])[-1].name
        logging.info(f"Error in function '{failed_function_name}': {e}")
        logging.info(f"Traceback: {tb}")


def plot_data_var(csv_file, output_html):
    # Load data from CSV
    df = pd.read_csv(csv_file)

    # Ensure 'Date' column is in datetime format

    df = df.sort_values(by="Date")

    # Create figure
    fig = go.Figure()

    # Add line plot for Variance
    fig.add_trace(
        go.Scatter(
            x=df["Date"],
            y=df["Variance"],
            mode="markers",
            line=dict(color="grey"),
            marker=dict(color="grey", size=8),
            name="Variance",
        )
    )

    # Update layout
    fig.update_layout(
        title="Variance Over Time",
        xaxis_title="Date",
        yaxis_title="Value",
        legend_title="Metrics",
    )

    # Save plot as HTML
    fig.write_html(output_html)
    logging.info(f"Plot saved to {output_html}")


def plot_data_max(csv_file, output_html):
    # Load data from CSV
    df = pd.read_csv(csv_file)

    # Ensure 'Date' column is in datetime format

    df = df.sort_values(by="Date")

    # Create figure
    fig = go.Figure()

    # Add line plot for Average
    fig.add_trace(
        go.Scatter(
            x=df["Date"],
            y=df["Maximum"],
            mode="markers",
            line=dict(color="blue"),
            marker=dict(color="blue", size=8),
            name="Maximum",
        )
    )

    # Update layout
    fig.update_layout(
        title="Maximum Over Time",
        xaxis_title="Date",
        yaxis_title="Maximum Value(fT)",
        legend_title="Metrics",
    )

    # Save plot as HTML
    fig.write_html(output_html)
    logging.info(f"Plot saved to {output_html}")
def plot_data_avg(csv_file, output_html):
    try:
        # Load data from CSV
        df = pd.read_csv(csv_file)

        df = df.sort_values(by="Date")

        # Create figure
        fig = go.Figure()

        # Add line plot for Average
        fig.add_trace(
            go.Scatter(
                x=df["Date"],
                y=df["Average"],
                mode="markers",
                line=dict(color="blue"),
                marker=dict(color="blue", size=8),
                name="Average",
            )
        )

        # Update layout
        fig.update_layout(
            title="Average Over Time",
            xaxis_title="Date",
            yaxis_title="Average Value(fT)",
            legend_title="Metrics",
        )

        # Save plot as HTML
        fig.write_html(output_html)
        logging.info(f"Plot saved to {output_html}")
    except Exception as e:
        logging.info(f"Error processing: {e}")
def process_kit_empty_room_files(client):

    # KIT .con metric computation
    if PROCESSKIT:

        # Set the output CSV file path

        # Process all .con files and save the results
        process_all_con_files(BASE_FOLDER, file_limit=KIT_FILE_LIMIT)

        #save_results_to_csv(results, output_file)

        logging.info(f"Results saved to {KIT_CSV_LOCAL_SAVE_PATH}")
        # print(results)

        output_avg_html = "_static/2-data-quality-dashboards/kit_average_plot.html"  # Path to save the HTML file

        # Ensure output directory exists
        os.makedirs(os.path.dirname(output_avg_html), exist_ok=True)

        # Create and save the plot
        plot_data_avg(KIT_CSV_LOCAL_SAVE_PATH, output_avg_html)

        output_variance_html = "_static/2-data-quality-dashboards/kit_variance_plot.html"  # Path to save the HTML file

        # Ensure output directory exists
        os.makedirs(os.path.dirname(output_variance_html), exist_ok=True)

        # Create and save the plot
        plot_data_var(KIT_CSV_LOCAL_SAVE_PATH, output_variance_html)
        output_variance_html = "_static/2-data-quality-dashboards/kit_max_plot.html"
        plot_data_max(KIT_CSV_LOCAL_SAVE_PATH, output_variance_html)

def process_opm_empty_room_files(client):

    if PROCESSOPM:
        # OPM .fif metric computation

        # Process all .fif files and save the results
        process_all_fif_files(BASE_FOLDER, file_limit=OPM_FILE_LIMIT)

        #save_results_to_csv(results, output_file)

        logging.info(f"Results saved to {OPM_CSV_LOCAL_SAVE_PATH}")
        # print(results)

        output_avg_html = (
            "_static/2-data-quality-dashboards/opm_average_plot.html"  # Path to save the HTML file
        )

        # Ensure output directory exists
        os.makedirs(os.path.dirname(output_avg_html), exist_ok=True)

        # Create and save the plot
        plot_data_avg(OPM_CSV_LOCAL_SAVE_PATH, output_avg_html)

        output_variance_html = (
            "_static/2-data-quality-dashboards/opm_variance_plot.html"  # Path to save the HTML file
        )

        # Ensure output directory exists
        os.makedirs(os.path.dirname(output_variance_html), exist_ok=True)

        # Create and save the plot
        plot_data_var(OPM_CSV_LOCAL_SAVE_PATH, output_variance_html)
        output_variance_html = "_static/2-data-quality-dashboards/opm_max_plot.html"
        plot_data_max(OPM_CSV_LOCAL_SAVE_PATH, output_variance_html)


def process_fif_file(file_path):
    s_avg = 3
    s_max = 10
    s_fft = 10

    # Load raw MEG/EEG data from a .fif file
    raw = mne.io.read_raw_fif(file_path, preload=False)

    data_duration = raw.times[-1]

    if TMAX <= data_duration and TMIN <= data_duration:
        # Crop data:
        raw = raw.crop(TMIN, TMAX)
        logging.info(f"Cropped data for: {file_path}")

    # Select channels that start with 'L' or 'R'
    selected_channels = [
        ch_name for ch_name in raw.ch_names if ch_name.startswith(("L", "R"))
    ]

    # Pick only those channels
    raw.pick(selected_channels)

    # Optional: Remove zero channels (if needed)
    raw = remove_zero_channels(raw)

    # Get data and calculate statistics
    data = raw.get_data()  # Get data from the selected channels
    avg = np.mean(data)  # Average over time (axis=1)
    var = np.var(data)  # Variance over time (axis=1)
    max_val = np.max(data)  # Maximum value over time (axis=1)

    # FFT calculation
    sfreq = raw.info["sfreq"]
    freqs, fft_data = compute_fft(data, sfreq)

    # Status for avg
    status_avg = [
        ("🟢 In the threshold" if np.all(avg < s_avg) else "🔴 Above the threshold")
    ]

    # Status for fft
    status_fft = [
        (
            "🟢 In the threshold"
            if np.all(fft_data < s_fft)
            else "🔴 Above the threshold"
        )
    ]

    # Status for max
    status_max = [
        ("🟢 In the threshold" if np.all(max_val < s_max) else "🔴 Above the threshold")
    ]

    # Return the processed values
    return avg, var, max_val, status_avg, freqs, fft_data, status_fft, status_max


def process_all_fif_files(base_folder, file_limit=None):
    """ """
    results = []
    file_count = 0  # Initialize a counter

    try:

        opm_csv = pd.read_csv(OPM_CSV_LOCAL_SAVE_PATH)
        for root, _, files in os.walk(base_folder):
            for file in files:
                if file.endswith(".fif"):

                    if file in opm_csv['File Name'].values:
                        logging.info(f"File {file} found in OPM CSV")

                        if opm_csv.loc[opm_csv['File Name'] == file, 'Processing State'].values[0] == 'TO BE PROCESSED':

                            processing_state = "UNPROCESSED"
                            file_path = os.path.join(root, file)

                            result = process_fif_file(file_path)

                            if result is None:
                                logging.info(f"Processing failed for {file_path}")
                            else:
                                # Process the file
                                (
                                    avg,
                                    var,
                                    max_val,
                                    status,
                                    freqs,
                                    fft_data,
                                    status_fft,
                                    status_max,
                                ) = result

                                # Extract date
                                #date = extract_date(file)
                                details = "Nothing added yet"
                                # date_str = (
                                #     date.strftime("%d-%m-%y %H:%M:%S")
                                #     if date
                                #     else "Unknown Date"
                                # )
                                processing_state = "PROCESSED"

                                # Append the result
                                new_values_dic = {
                                        "Processing State": processing_state,
                                        "Status for average values": status,
                                        "Average": avg,
                                        "Variance": var,
                                        "Status for max values": status_max,
                                        "Maximum": max_val,
                                        "Details": details,
                                    }

                                for key in new_values_dic.keys():
                                    # Cast each column to 'object' dtype
                                    opm_csv[key] = opm_csv[key].astype('object')

                                opm_csv.loc[opm_csv['File Name'] == file, new_values_dic.keys()] = (
                                    new_values_dic.values())


                                os.makedirs(os.path.dirname(OPM_CSV_LOCAL_SAVE_PATH), exist_ok=True)

                                opm_csv.to_csv(OPM_CSV_LOCAL_SAVE_PATH, index=False)


                            file_count += 1  # Increment the counter
                            if file_limit != None:
                                if file_count >= file_limit:
                                    break  # Stop processing after reaching the limit
                        else:
                            logging.info(f"File {file} already processed")

                    else:
                        logging.info(f"File {file} downloaded but not found in OPM CSV")


            if file_limit != None:
                if file_count >= file_limit:
                    break  # Stop outer loop if limit is reached


    except Exception as e:
        tb = traceback.format_exc()
        failed_function_name = traceback.extract_tb(sys.exc_info()[2])[-1].name
        logging.info(f"Error in function '{failed_function_name}': {e}")
        logging.info(f"Traceback: {tb}")

def download_kit_empty_room_data_from_folder(folder_id, path, client):
    try:
        folder = client.folder(folder_id).get()
        items = folder.get_items(limit=10000, offset=0)

        kit_df = pd.read_csv(KIT_CSV_LOCAL_SAVE_PATH)

        kit_con_files_download_counter = 0

        for item in items:
            try:

                if item.type == "file" and item.name.endswith((".con")):

                    if kit_con_files_download_counter >= KIT_CON_FILE_DOWNLOAD_LIMIT:
                        logging.info("Download Limit for KIT reached")
                        break

                    else:

                        file_id = item.id
                        file = client.file(file_id).get()

                        # Get the content creation date
                        # modified_at = datetime.strptime(
                        #     file.content_modified_at, "%Y-%m-%dT%H:%M:%S%z"
                        # )

                        modified_at = pd.to_datetime(file.content_modified_at, errors="coerce")

                        #formatted_date = created_at.strftime("%d-%m-%y-%H-%M-%S")
                        #filename = f"{formatted_date}_{file.name}"

                        filename = file.name
                        file_path = os.path.join(path, filename)

                        if (filename not in kit_df['File Name'].values):

                            new_row = pd.DataFrame({'File Name': filename,
                                                    'Date': modified_at,
                                                    'Processing State': ['TO BE PROCESSED']})

                            kit_df = pd.concat([kit_df, new_row], ignore_index=True)

                            # Open the .csv files

                            # Download the file
                            with open(file_path, "wb") as open_file:
                                file.download_to(open_file)

                            kit_df.to_csv(KIT_CSV_LOCAL_SAVE_PATH, index=False)

                            kit_con_files_download_counter +=1

                            logging.info(f"Downloaded KIT File {filename} to {file_path}")

                        else:
                            logging.info(f"File {filename} already processed")

            except Exception as e:
                logging.error(
                    f"Failed to download file or process folder '{item.name}': {str(e)}"
                )
                logging.info(f"Error processing item '{item.name}': {str(e)}")
                traceback.print_exc()

        logging.info(f"Downloaded {kit_con_files_download_counter} KIT files")

    except Exception as e:
        logging.error(f"Failed to access folder with ID {folder_id}: {str(e)}")
        print(f"Error accessing folder with ID {folder_id}: {str(e)}")
        traceback.print_exc()


def download_opm_empty_room_data_from_folder(folder_id, path, client):
    try:
        folder = client.folder(folder_id).get()
        items = folder.get_items(limit=10000, offset=0)

        opm_df = pd.read_csv(OPM_CSV_LOCAL_SAVE_PATH)

        opm_fif_files_download_counter = 0

        for item in items:
            try:

                if item.type == "file" and item.name.endswith((".fif")):

                    if opm_fif_files_download_counter >= OPM_FIF_FILE_DOWNLOAD_LIMIT:
                        logging.info("Download Limit for OPM reached")
                        break

                    else:

                        file_id = item.id
                        file = client.file(file_id).get()

                        # Get the content creation date
                        # created_at = datetime.strptime(
                        #     file.content_created_at, "%Y-%m-%dT%H:%M:%S%z"
                        # )

                        #formatted_date = created_at.strftime("%d-%m-%y-%H-%M-%S")
                        #filename = f"{formatted_date}_{file.name}"

                        filename = file.name
                        file_path = os.path.join(path, filename)
                        modified_at = pd.to_datetime(file.content_modified_at, errors="coerce")


                        if (filename not in opm_df['File Name'].values):

                            new_row = pd.DataFrame({'File Name': filename,
                                                    'Date': modified_at,
                                                    'Processing State': ['TO BE PROCESSED']})

                            opm_df = pd.concat([opm_df, new_row], ignore_index=True)

                            # Open the .csv files

                            # Download the file
                            with open(file_path, "wb") as open_file:
                                file.download_to(open_file)

                            opm_df.to_csv(OPM_CSV_LOCAL_SAVE_PATH, index=False)

                            opm_fif_files_download_counter +=1

                            logging.info(f"Downloaded OPM File {filename} to {file_path}")

                        else:
                            logging.info(f"File {filename} already processed")

            except Exception as e:
                logging.error(
                    f"Failed to download file or process folder '{item.name}': {str(e)}"
                )
                logging.info(f"Error processing item '{item.name}': {str(e)}")
                traceback.print_exc()

        logging.info(f"Downloaded {opm_fif_files_download_counter} OPM files")

    except Exception as e:
        logging.error(f"Failed to access folder with ID {folder_id}: {str(e)}")
        print(f"Error accessing folder with ID {folder_id}: {str(e)}")
        traceback.print_exc()


def get_file_id_by_name(client, folder_id, file_name):
    """
    Retrieves the file ID by searching for the file in a given folder.

    Parameters:
        client (boxsdk.Client): The authenticated Box client.
        folder_id (str): The ID of the folder to search in (0 for root folder).
        file_name (str): The name of the file to search for.

    Returns:
        str: The file ID if found, otherwise None.
    """
    folder = client.folder(folder_id).get_items(limit=1000)

    for item in folder:
        if item.name == file_name:
            return item.id

    return None

def setup_logging():
    # Set the logging level for the boxsdk to WARNING or ERROR
    logging.getLogger("boxsdk").setLevel(logging.WARNING)

    logging.basicConfig(level=logging.INFO)

    # Check if the file exists
    if os.path.exists("box_secrets.env"):
        load_dotenv("box_secrets.env")
    else:
        logging.info("box_secrets.env file not found. Skipping load.")


def authenticate_box():
    # Load the configuration from environment variables
    client_id = os.getenv("BOX_CLIENT_ID")
    # logging.info(f"Client ID {client_id}")
    client_secret = os.getenv("BOX_CLIENT_SECRET")
    # print(client_secret)
    enterprise_id = os.getenv("BOX_ENTERPRISE_ID")

    public_key_id = os.getenv("BOX_PUBLIC_KEY_ID")

    private_key = os.getenv("BOX_PRIVATE_KEY")

    # Ensure it's correctly formatted (remove extra quotes if they exist) This caused an issue on the RTD scripts
    if private_key.startswith("'") and private_key.endswith("'"):
        private_key = private_key[1:-1]

    # Replace escaped newlines with actual newlines
    private_key = private_key.replace("\\n", "\n").encode()

    passphrase = os.getenv("BOX_PASSPHRASE").encode()

    if all(
        [
            client_id,
            client_secret,
            enterprise_id,
            public_key_id,
            private_key,
            passphrase,
        ]
    ):
        logging.info("Secrets retrieved successfully.")
    else:
        logging.error("Secrets not retrieved.")

    # Set up JWT authentication
    auth = JWTAuth(
        client_id=client_id,
        client_secret=client_secret,
        enterprise_id=enterprise_id,
        jwt_key_id=public_key_id,
        rsa_private_key_data=private_key,
        rsa_private_key_passphrase=passphrase,
    )

    # Authenticate and create a client
    auth.authenticate_instance()
    client = Client(auth)

    # Example: Get the details of the current user
    try:
        user = client.user().get()
        logging.info(f"User ID: {user.id}")
        logging.info(f"User Login: {user.login}")
    except BoxAPIException as e:
        logging.info(f"Error getting user details: {e}")

    if client is not None:
        return client

    else:
        return None