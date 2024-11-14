from utilities import *

from config import *

# Setup logging

setup_logging()

# Authenticate with BOX and download files

client = authenticate_box()

if client is None:
    logging.info('Authentication failed')


# Update KIT Dashboard

    # Get the current KIT csv folder then file ID's

kit_csv_folder_id = get_folder_id_by_path(KIT_CSV_PATH, client)
kit_csv_file_id = get_file_id_by_name(client, kit_csv_folder_id, KIT_CSV_FILE_NAME)

    # Download the KIT csv file

box_kit_file = client.file(kit_csv_file_id).get()

# Ensure the directory exists
os.makedirs(os.path.dirname(KIT_CSV_LOCAL_SAVE_PATH), exist_ok=True)

with open(KIT_CSV_LOCAL_SAVE_PATH, 'wb') as open_file:
    box_kit_file.download_to(open_file)


    # Update dashboards and update the KIT csv
        # Download the .con files that must be processed

os.makedirs(KIT_LOCAL_DATA_PATH, exist_ok=True)
logging.info(f"Downloading empty room files for KIT with limit {KIT_CON_FILE_DOWNLOAD_LIMIT} for .con files")
kit_start_folder_id = get_folder_id_by_path(KIT_EMPTY_ROOM_DATA_PATH, client)

download_kit_empty_room_data_from_folder(kit_start_folder_id, KIT_LOCAL_DATA_PATH, client)

        # Process the downloaded .con files

process_kit_empty_room_files(client)

        # Update the KIT csv file on NYU BOX

kit_updated_file = client.file(kit_csv_file_id).update_contents(KIT_CSV_LOCAL_SAVE_PATH)

logging.info(f'KIT dashboard tracking file "{kit_updated_file.name}" has been updated on Box.')



# Update OPM Dashboard

    # Get the current OPM csv folder then file ID's

opm_csv_folder_id = get_folder_id_by_path(OPM_CSV_PATH, client)
opm_csv_file_id = get_file_id_by_name(client,opm_csv_folder_id, OPM_CSV_FILE_NAME)

    # Download the OPM csv file

box_opm_file = client.file(opm_csv_file_id).get()

# Ensure the directory exists
os.makedirs(os.path.dirname(OPM_LOCAL_DATA_PATH), exist_ok=True)

with open(OPM_CSV_LOCAL_SAVE_PATH, 'wb') as open_file:
    box_opm_file.download_to(open_file)


    # Update dashboards and update the KIT csv
        # Download the .con files that must be processed


os.makedirs(OPM_LOCAL_DATA_PATH, exist_ok=True)

logging.info(f"Downloading empty room files for OPM with limit {OPM_FIF_FILE_DOWNLOAD_LIMIT} for .fif files")

opm_start_folder_id = get_folder_id_by_path(OPM_EMPTY_ROOM_DATA_PATH, client)

download_opm_empty_room_data_from_folder(opm_start_folder_id, OPM_LOCAL_DATA_PATH, client)

        # Process the downloaded .con files

process_opm_empty_room_files(client)

        # Update the KIT csv file on NYU BOX

opm_updated_file = client.file(opm_csv_file_id).update_contents(OPM_CSV_LOCAL_SAVE_PATH)

logging.info(f'OPM dashboard tracking file "{opm_updated_file.name}" has been updated on Box.')



# Update OPM Dashboard
#
# opm_start_folder_id = get_folder_id_by_path(OPM_EMPTY_ROOM_DATA_PATH, client)
# opm_download_directory = r"data/meg-opm"
# os.makedirs(opm_download_directory, exist_ok=True)
#
#
# download_opm_empty_room_data_from_folder(opm_start_folder_id, opm_download_directory, client)
