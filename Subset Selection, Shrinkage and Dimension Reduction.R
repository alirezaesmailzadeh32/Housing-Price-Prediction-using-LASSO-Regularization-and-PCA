rm(list=ls())
# Load Libraries, o.S.
library(tidyverse)
library(tidymodels)
library(GGally)
library(here)
library(caret)
library(knitr)
library(modelsummary)
library(dplyr)

# Load data, o.S.
housing_data <- read.csv(here("data", "housing_data.csv")) %>%  
  drop_na()
  
glimpse(housing_data)
# Remove id variable
housing_data <- housing_data %>% select(-id)

# Train-test split
set.seed(123)
housing_split <- initial_split(housing_data, prop = 0.7)

housing_train <- training(housing_split)
housing_test <- testing(housing_split)

######################## Regularization #######################################

## Lasso, 
lasso_spec <- linear_reg(mixture=1, penalty=0) %>%
  set_mode("regression") %>%
  set_engine("glmnet")

## Extend the Use of Recipes
# Recipe (preprocessing)
lasso_recipe <- 
  recipe( formula = price_doc ~ ., data = housing_train ) %>% 
  # assigns a previously unseen factor level to a new value
  step_novel( all_nominal_predictors() ) %>%     
  step_dummy( all_nominal_predictors() ) %>% 
  # removes variables that contain only a single value
  step_zv( all_predictors() ) %>%                
  step_normalize( all_numeric_predictors() )

## Create the Workflow and Fit the Model

lasso_wf <- workflow() %>%
  add_recipe(lasso_recipe) %>%
  add_model(lasso_spec)
lasso_fit <- lasso_wf %>%
  fit(housing_train)

## Check the Results
tidy( lasso_fit )

## Check the Results
tidy( lasso_fit, penalty = 50 )
tidy( lasso_fit, penalty = 500000 )

## How Do Predictions Look Like with Large Lambda Values
predict(lasso_fit, new_data = housing_train, penalty = 10000000)

## Visualize Regularization Path
lasso_fit %>%
  extract_fit_engine() %>%
  plot( xvar = "lambda" )

# Dimension Reduction

## Conducting a PCA Regression Just Needs a Small Adjustment in the Recipe of a Linear Model
# Recipe (preprocessing)
pca_recipe <- 
  recipe( formula = price_doc ~ ., data = housing_train ) %>% 
  # assigns a previously unseen factor level to a new value
  step_novel( all_nominal_predictors() ) %>%     
  step_dummy( all_nominal_predictors() ) %>% 
  # removes variables that contain only a single value
  step_zv( all_predictors() ) %>%                
  step_normalize( all_numeric_predictors()) %>%
  # create three principal components
  step_pca(all_predictors(), num_comp = 3)

## The Rest of the Workflow Stays Unchanged
lmod_spec <- linear_reg() %>%
  set_engine("lm") %>%
  set_mode("regression")

wf <- workflow() %>%
  add_recipe(pca_recipe) %>%
  add_model(lmod_spec)

pca_fit <- wf %>%
  fit(housing_train)

## Confirm that it Worked by Inspecting the Model Fit
tidy(pca_fit)

## We can Check How Much of the Variance is Explained by each PC
pca_cols <- pca_recipe %>%
  prep()

tidied_pca <- tidy(pca_cols, 5)
pca_sum <- summary(pca_cols$steps[[5]]$res)
pca_sum$importance[,1:3]

## We Can also Inspect the PCA Loadings
tidied_pca %>%
  filter(component %in% paste0("PC", 1:3)) %>%
  mutate(component = fct_inorder(component)) %>%
  ggplot(aes(value, terms, fill = terms)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~component, nrow = 1)

## 1. Workflow Object
lasso_tune_spec <- linear_reg(penalty= tune(), mixture = 1) %>%
  set_mode("regression") %>%
  set_engine("glmnet")

lasso_tuned_wf <- workflow() %>%
  add_recipe(lasso_recipe) %>%
  add_model(lasso_tune_spec)

## 2. Object of the Cross-Validation Resamples
housing_folds <- vfold_cv(housing_train, v = 10)
housing_folds

## 3. Grid: Values of Hyperparameter Values to be Explored
lambda_grid <- grid_regular( penalty( range = c(-10, 6)), levels = 20) # *
lambda_grid

## Tuning: Combine the 3 Steps
tune_res <- tune_grid(
  object = lasso_tuned_wf,
  resamples = housing_folds,
  grid = lambda_grid
)

## Plot the Validation Curve
tune_res %>%
  collect_metrics() %>%
  ggplot(aes(penalty, mean, color = .metric)) +
  geom_errorbar(aes(
    ymin= mean - std_err,
    ymax = mean + std_err),
    alpha = 0.5) +
  geom_line(size=1.5) +
  facet_wrap(~.metric, scales = "free", nrow=2) + 
  scale_x_log10() + 
  theme(legend.position = "none")

## Show Best Performing Models
show_best(tune_res, metric="rmse")

## Finalize the Model
best_lambda <- select_best(tune_res, metric="rmse")
final_wf <- lasso_tuned_wf %>%
  finalize_workflow(best_lambda)
lasso_final <- final_wf %>%
  fit(housing_train)

## Let's Check the Out-of-sample Accuracy
# RMSE out of sample (testing)
RMSE_test <- augment(lasso_final, new_data = housing_test ) %>%
  yardstick::rmse( truth = price_doc, estimate = .pred ) 

# Print RMSE testing
RMSE_test$.estimate



