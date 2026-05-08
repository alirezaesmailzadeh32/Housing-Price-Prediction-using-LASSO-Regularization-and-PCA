# Housing Price Prediction using LASSO Regularization and PCA

## Project Overview
This project applies machine learning techniques to predict housing prices using regularization and dimensionality reduction methods in R.

The analysis focuses on:
- LASSO Regression
- Principal Component Analysis (PCA)
- Hyperparameter tuning
- Cross-validation
- Model evaluation using RMSE

## Technologies
- R
- tidymodels
- glmnet
- tidyverse
- ggplot2

## Machine Learning Methods
### LASSO Regression
LASSO regression was used for:
- Feature selection
- Shrinkage regularization
- Reducing overfitting

### Principal Component Analysis (PCA)
PCA was used for:
- Dimensionality reduction
- Variance explanation
- Feature transformation

## Workflow
1. Data preprocessing
2. Dummy encoding
3. Feature normalization
4. Train-test split
5. Cross-validation
6. Hyperparameter tuning
7. Final model evaluation

## Results
- Final RMSE: 3,420,783
- 10-fold cross-validation
- Optimal lambda selected through grid search

## Key Insights
- Larger lambda values shrink coefficients toward zero
- LASSO successfully performed feature selection
- PCA reduced dimensionality while preserving variance structure

## Repository Structure
Housing-Price-Prediction-LASSO-PCA/
│
├── data/
│   └── housing_data.csv
│
├── scripts/
│   └── housing_analysis.R
│
├── outputs/
│   ├── regularization_path.png
│   ├── pca_loadings.png
│   └── validation_curve.png
│
├── README.md
├── .gitignore
└── Housing_Price_Analysis.Rproj
