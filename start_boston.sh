#!/bin/bash
# Break on any error
set -e

# Hyperparameters
GAN_EPOCHS=30
#GAN_EPOCHS=15
CLASSIFIER_EPOCHS=3
CF_COUNT=100
GENERATOR_MODE=open_set

# Utility to create the params file with some default values.
# Note: The Boston dataset is not supported by this!
# python "generativeopenset/create_experiment.py" \
#         --result_dir "${RESULTS_DIR}" \
#         --dataset "/mnt/data/boston.dataset" \
#         --hypothesis "boston simple" \
#         --image_size 200
PARAMS_TEMPLATE="${1:-./params_boston_32.json}"

# Argument 1: Leave out class
# Options are: baso blast eo ig lymph mono neut nrbc
LEAVE_ONE_OUT_CLASS="${2:-mono}"

# Argument 2: Output directory
RESULTS_DIR="${3:-./out_new}"

print_title () {
    _bar=$(printf '=%.0s' {1..60})
    printf "\n${_bar}\n${1}\n${_bar}\n\n"
}

mkdir -p "$RESULTS_DIR"
mkdir -p "$RESULTS_DIR/console"

# Copy params template to RESULTS_DIR/params.json
# Then replace the parameter ${CLASS_LABEL}
cp "${PARAMS_TEMPLATE}" "${RESULTS_DIR}/params.json"
sed -e "s/\${CLASS_LABEL}/${LEAVE_ONE_OUT_CLASS}/" \
    "${PARAMS_TEMPLATE}" > "${RESULTS_DIR}/params.json"

###############################################################################
# Train the initial generative model (E+G+D) and the initial classifier (C_K)
print_title "TRAIN GAN" \
    2>&1 | tee "$RESULTS_DIR/console/01-train-gan.txt"
python src/train_gan.py --epochs $GAN_EPOCHS --result_dir "$RESULTS_DIR"  \
    2>&1 | tee -a "$RESULTS_DIR/console/01-train-gan.txt"

###############################################################################
# Baseline: Evaluate the standard classifier (C_k+1)
print_title "EVALUATE CLASSIFIER C_k+1" \
    2>&1 | tee "$RESULTS_DIR/console/02-evaluate-kplusone-baseline.txt"
python src/evaluate_classifier.py --result_dir "$RESULTS_DIR" --mode baseline \
    2>&1 | tee -a "$RESULTS_DIR/console/02-evaluate-kplusone-baseline.txt"

###############################################################################
print_title "EVALUATE CLASSIFIER C_k+1" \
    2>&1 | tee "$RESULTS_DIR/console/02-evaluate-kplusone-weibull.txt"
python src/evaluate_classifier.py --result_dir "$RESULTS_DIR" --mode weibull \
    2>&1 | tee -a "$RESULTS_DIR/console/02-evaluate-kplusone-weibull.txt"

cp $RESULTS_DIR/checkpoints/classifier_k_epoch_00${GAN_EPOCHS}.pth \
   $RESULTS_DIR/checkpoints/classifier_kplusone_epoch_00${GAN_EPOCHS}.pth

###############################################################################
# Generate a number of counterfactual images (in the K+2 by K+2 square grid format)
print_title "GENERATE COUNTERFACTUAL IMAGES" \
    2>&1 | tee "$RESULTS_DIR/console/03-generate-counterfactuals.txt"
python src/generate_${GENERATOR_MODE}.py \
    --result_dir $RESULTS_DIR \
    --count $CF_COUNT \
    2>&1 | tee -a "$RESULTS_DIR/console/03-generate-counterfactuals.txt"

###############################################################################
# Automatically label the rightmost column in each grid (ignore the others)
print_title "CREATE LABELS" \
    2>&1 | tee "$RESULTS_DIR/console/04-create-labels.txt"
python src/auto_label.py \
    --output_filename "$RESULTS_DIR/generated_images_${GENERATOR_MODE}.dataset" \
    --result_dir $RESULTS_DIR \
    2>&1 | tee -a "$RESULTS_DIR/console/04-create-labels.txt"

###############################################################################
# Train a new classifier, now using the aux_dataset containing the counterfactuals
print_title "TRAIN C_k+1 CLASSIFIER" \
    2>&1 | tee "$RESULTS_DIR/console/05-train-kplusone.txt"
python src/train_classifier.py \
    --epochs $CLASSIFIER_EPOCHS \
    --result_dir "$RESULTS_DIR" \
    --aux_dataset "$RESULTS_DIR/generated_images_${GENERATOR_MODE}.dataset" \
    2>&1 | tee -a "$RESULTS_DIR/console/05-train-kplusone.txt"

###############################################################################
# Evaluate the C_K+1 classifier, trained with the augmented data
print_title "EVALUATE C_k+1 CLASSIFIER" \
    2>&1 | tee "$RESULTS_DIR/console/06-evaluate-kplusone-fuxin.txt"
python src/evaluate_classifier.py \
    --result_dir "$RESULTS_DIR" \
    --mode fuxin \
    2>&1 | tee -a "$RESULTS_DIR/console/06-evaluate-kplusone-fuxin.txt"

#print_title "EVALUATE C_k+1 CLASSIFIER" \
#    2>&1 | tee "$RESULTS_DIR/console/06-evaluate-kplusone-baseline.txt"
#python src/evaluate_classifier.py \
#    --result_dir "$RESULTS_DIR" \
#    --mode baseline \
#    2>&1 | tee -a "$RESULTS_DIR/console/06-evaluate-kplusone-baseline.txt"

###############################################################################
print_title "RESULTS" 2>&1 | tee "$RESULTS_DIR/console/07-results.txt"
./print_results.sh "$RESULTS_DIR" 2>&1 | tee -a "$RESULTS_DIR/console/07-results.txt"
