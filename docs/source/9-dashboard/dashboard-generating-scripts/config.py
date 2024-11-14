
BASE_FOLDER = r"data"

EMPTY_ROOM_DATA_PATH = "Data/empty-room/sub-emptyroom"

KIT_EMPTY_ROOM_DATA_PATH = EMPTY_ROOM_DATA_PATH+"/meg-kit"
OPM_EMPTY_ROOM_DATA_PATH = EMPTY_ROOM_DATA_PATH+"/meg-opm"

KIT_LOCAL_DATA_PATH = r"data/meg-kit"
OPM_LOCAL_DATA_PATH = r"data/meg-opm"

KIT_CSV_PATH = "Data/empty-room/sub-emptyroom"
OPM_CSV_PATH = "Data/empty-room/sub-emptyroom"

KIT_CSV_FILE_NAME = 'kit-con-files-statistics.csv'
OPM_CSV_FILE_NAME = 'opm-fif-files-statistics.csv'

KIT_CSV_LOCAL_SAVE_PATH = 'data/kit-con-files-statistics.csv'
OPM_CSV_LOCAL_SAVE_PATH = 'data/opm-fif-files-statistics.csv'


KIT_CON_FILE_DOWNLOAD_LIMIT = 5
OPM_FIF_FILE_DOWNLOAD_LIMIT = 10000

# Metrics

METRICS_CSV_PATH = '9-dashboard/data/data-quality-dashboard/noise_metrics.csv'


#Processing vars

BASE_PATH_DATA = r"data"

PROCESSKIT = True
PROCESSOPM = True

KIT_FILE_LIMIT = None
OPM_FILE_LIMIT = None

TMIN = 10.0  # Length of empty room data segment to compute the metrics for
TMAX = 60.0
