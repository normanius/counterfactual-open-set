# OSRCI: Open Set Recognition with Counterfactual Images

This is a fork of a project by Lawrence Neal et al., with some adaptations made for an exploratory project in the context of hematology. (OSR4H)

**Original work:**

- *Publication*: Open Set Learning with Counterfactual Images, Lawrence Neal et al., 2018   
- *Repository*: https://github.com/lwneal/counterfactual-open-set



## Instructions

```bash
###############################################################################
# REPO
###############################################################################

# Clone the repository and checkout the develop branch.
git clone "https://github.com/normanius/osrci4h.git"
cd "osrci4h"

###############################################################################
# PYTHON ENVIRONMENT
###############################################################################

# Set up the virtual environment (optional). The code below was tested
# with a miniforge env (miniforge3-4.10.1-5) running Python 3.9.5.
pyenv virtualenv "miniforge3-4.10.1-5" "env-3.9.5-miniforge-osr4h"
# Install the environment
python -m pip install -r "requirements.txt"

# Alternatively, install via conda (don't remember what exactly worked for us)
conda install --file "requirements-conda.txt"

###############################################################################
# DATASET
###############################################################################
# Set an environment variable OSR4H_DATA pointing to the location
# where the BOSTON dataset resides.
export OSR4H_DATA="path/to/data"

# The folder "BOSTON" should contain subfolders "baso", "blast", "eo", etc.
ls "$OSR4H_DATA/BOSTON"

# OSRCI uses *.dataset files, which are JSON formatted "inventories" of the
# datasets used for training and testing.
cd "datasets"
# Read and adjust the file get_boston_datasets.py.
vim "get_boston_datasets.py"
# Create the datasets.
python "get_boston_datasets.py"
# Return to project root.
cd ".."

###############################################################################
# SETTINGS
###############################################################################
# Adjust the parameters.

# Settings with cropping, not scaling
vim "params_boston_32.json"
# Settings with cropping, and scaling
vim "params_boston_32_5s.json"

###############################################################################
# RUN
###############################################################################
# The main script is start_boston.sh
# It takes the following parameters:
#     ./start_boston.sh <PARAMS_FILE> <HOLD_OUT_CLASS> <OUTPUT_DIR>

# Check settings inside the start_boston.sh
# (Note: Some arguments override the settings in the params file)
vim "start_boston.sh"

# Output directory.
RESULTS_DIR="out_all"

# Options are: baso blast eo ig lymph mono neut nrbc
HOLD_OUT="baso"

# Run the script!
./start_boston.sh "params_boston_32.json" "${HOLD_OUT}" "${RESULTS_DIR}/${HOLD_OUT}"

# The results presented in the report were created with with
# ./start_boston_all.sh

```



