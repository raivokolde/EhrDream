FROM rocker/tidyverse:3.6.1

RUN install2.r --error \
    --deps TRUE \
    parsnip \
    recipes \
    ranger \
    lubridate

# Move to the app folder
RUN mkdir /app
WORKDIR /app

# Copy our python program for training and inference
COPY train_diagnosis_model_v.01.r .
COPY evaluate_diagnosis_model_v.01.r .

# Copy Bash scripts expected by the IT infrastructure of the EHR DREAM Challenge
COPY train.sh .
COPY infer.sh .

# Add executable permission to Bash scripts
RUN chmod +x train.sh infer.sh


