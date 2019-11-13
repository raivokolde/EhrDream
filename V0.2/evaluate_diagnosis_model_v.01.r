library(parsnip)
library(recipes)
library(tidyverse)
library(ranger)

# INFER = "Data/2019-10-07/OMOPchallenge/evaluation/"
# SCRATCH = "Data/2019-10-17/SCRATCH/"
# MODEL = "Data/2019-10-22/scratch/"
# OUTPUT = "Data/2019-10-17/SCRATCH/"

INFER = "/infer/"
SCRATCH = "/scratch/"
MODEL = "/model/"
OUTPUT = "/output/"

print(Cstack_info())

# Read model ------------------------------------------------------------------
cat("-------------Load model \n")
load(str_glue("{MODEL}/model.RData"), verbose = TRUE)

# Read evaluation data --------------------------------------------------------
cat("-------------Load dataset \n")
training = list(
  condition_occurrence = read_csv(str_glue("{INFER}/condition_occurrence.csv"), col_types = cols_only(person_id = col_double(), condition_concept_id = col_double())),
  person = read_csv(str_glue("{INFER}/person.csv"), col_types = cols_only(person_id = col_double()))
)

# Create features ------------------------------------------------------------
# Create dummy 
cat("-------------Create features \n")
diagnosis = training$condition_occurrence %>% 
  mutate(condition_concept_id = coalesce(condition_concept_id, 99999999)) %>% 
  mutate(condition_concept_id = str_c("X", condition_concept_id)) %>% 
  mutate(value = 1) %>% 
  pivot_wider(id_cols = person_id, names_from = condition_concept_id, values_from = value, values_fn = list(value = max), values_fill = list(value = 0))

# Harmonize with training data features
cat("-------------Harmonize features \n")
features_not_present = setdiff(features, colnames(diagnosis))
if(length(features_not_present) > 0){
  supplement = matrix(0, nrow = nrow(diagnosis), ncol = length(features_not_present), dimnames = list(NULL, features_not_present)) %>% 
    as_tibble()
  
  diagnosis = diagnosis %>% 
    bind_cols(supplement)
}

diagnosis$Other = diagnosis %>% 
  magrittr::extract(setdiff(colnames(diagnosis), features)) %>% 
  reduce(`+`)

diagnosis = training$person %>% 
  left_join(diagnosis, by = "person_id") %>%
  mutate_at(.vars = vars(starts_with("X")), .funs = ~ coalesce(., 0)) %>% 
  mutate_at(.vars = vars(starts_with("Other")), .funs = ~ coalesce(., 0)) %>% 
  arrange(person_id)
  
data = diagnosis %>% 
  magrittr::extract(features)

# Predict ---------------------------------------------------------------------
cat("-------------Predict \n")
res = tibble(
  person_id = diagnosis$person_id,
  score = model %>%
    predict(data, type = "prob") %>% 
    pull(.pred_Yes)
)

cat("-------------Write results \n")
write_csv(res, path = str_glue("{OUTPUT}/predictions.csv"))








