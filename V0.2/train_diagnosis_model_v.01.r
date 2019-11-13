library(parsnip)
library(recipes)
library(tidyverse)
library(lubridate)

# TRAIN = "CodeData/training_fastlane/"
# SCRATCH = "Data/2019-10-17/SCRATCH/"
# MODEL = "Data/2019-10-17/SCRATCH/"

TRAIN = "/train/"
SCRATCH = "/scratch/"
MODEL = "/model/"

print(Cstack_info())

# Util functions --------------------------------------------------------------
add_response = function(tables){
  dates = tables$observation_period %>% 
    select(person_id, date = observation_period_end_date)

  dates = dates %>% 
    arrange(person_id, desc(date)) %>% 
    distinct(person_id, .keep_all = TRUE)
  
  tables$response = dates %>% 
    left_join(tables$death %>% select(person_id, death_date), by = "person_id") %>% 
    mutate(death_date = coalesce(death_date, as_date("2030-01-01"))) %>% 
    mutate(response = factor(death_date - date < 183, labels = c("No", "Yes")) %>% as.character()) %>% 
    select(person_id, response)
  
  return(tables)
}

# Read data -------------------------------------------------------------------
training = list(
  condition_occurrence = read_csv(str_glue("{TRAIN}/condition_occurrence.csv"), col_types = cols_only(person_id = col_double(), condition_concept_id = col_double())), 
  death = read_csv(str_glue("{TRAIN}/death.csv"), col_types = cols_only(person_id = col_double(), death_date = col_date())), 
  observation_period = read_csv(str_glue("{TRAIN}/observation_period.csv"), col_types = cols_only(person_id = col_double(), observation_period_end_date = col_date())),
  person = read_csv(str_glue("{TRAIN}/person.csv"), col_types = cols_only(person_id = col_double()))
)

# Create response variable ----------------------------------------------------
training = add_response(training)

# Create features -------------------------------------------------------------
diagnosis = training$condition_occurrence %>% 
  mutate(condition_concept_id = coalesce(condition_concept_id, 99999999)) %>% 
  mutate(condition_concept_id = str_c("X", condition_concept_id)) %>% 
  mutate(value = 1) %>% 
  pivot_wider(id_cols = person_id, names_from = condition_concept_id, values_from = value, values_fn = list(value = max), values_fill = list(value = 0))

diagnosis$Other = diagnosis %>% keep(~ mean(.x) < 0.05) %>% reduce(`+`)

diagnosis = diagnosis %>% 
  keep(~ mean(.x) > 0.05)

data = training$response %>% 
  left_join(diagnosis, by = "person_id") %>% 
  right_join(training$person, by = "person_id") %>% 
  mutate_at(.vars = vars(starts_with("X")), .funs = ~ coalesce(., 0)) %>% 
  mutate_at(.vars = vars(starts_with("Other")), .funs = ~ coalesce(., 0)) %>% 
  mutate_at(.vars = vars(starts_with("response")), .funs = ~ coalesce(., "No")) %>% 
  select(-person_id)

# Train model -----------------------------------------------------------------
data = data %>% 
  recipe(response ~ .) %>% 
  step_upsample(response, over_ratio = 0.3) %>% 
  prep() %>% 
  juice() 

model = rand_forest(trees = 50, mode = "classification") %>%
  set_engine("ranger") %>%
  fit(response ~ ., data = data)

# Save model ------------------------------------------------------------------
features = setdiff(colnames(data), "response")
save(model, features, file = str_glue("{MODEL}/model.RData"))














