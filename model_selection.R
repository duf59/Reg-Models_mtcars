# model_selection.R
# Author : R. Dufour
# February 2015
#
# This script is part of the course project of "Regression models" on Coursera
# See the readme file for the project intsructions
#
# The aim of the following code is to select a model, i.e. a set of predictor related with the response (mpg)
# To this purpose we best subset selection and 10-fold cross-validation to estimate test MSE.

# The mtcars contains the following variables :
#
#   - AM (transmission type)
#   - VS (Engine Shape : 1 = Straight, 0 = V)
#   - DISP (Engine size, in cubic inches)
#   - DRAT (Final drive ratio == Rear axle ratio)
#   - CYL (number of cylinders)
#   - GEAR (number of transmission speed == number of forward gears)
#   - CARB (number of carburetors)
#   - WT (weight)
#   - HP (Gross horsepower)
#   - QSEC (1/4 mile time in seconds)
#   - MPG (Gasoline mileage in Miles per gallon)
#
# Here we consider mpg as the outcome, and all the other variables as potential predictors.

# Load the data ####
  data(mtcars)
  str(mtcars)  
  sum(!complete.cases(mtcars))  # check all observations are complete
  
# BEST SUBSET SELECTION ####
# Perform best subset selection and look at the adjusted R² as indicator of model performance
  library(leaps)
  regfit.full <- regsubsets(mpg  ~ ., data = mtcars, nvmax = 10)
  reg.summary <- summary(regfit.full)

  
  # Find optimal model based on adjusted R square (Cp and BIC give the same result)
  opt <- which.max(reg.summary$adjr2)

  plot(1:10,reg.summary$adjr2, type = "b", xlab = "Number of predictors", ylab = "Adjusted RSq")
  points(opt,reg.summary$adjr2[opt], col = "red", cex = 2, pch = 20)
  
  # get the coefficient estimates for the optimal model
  coef(regfit.full,opt)
  
# BEST SUBSET SELECTION INC. "AM" WITH CROSS-VALIDATION ####
# Use cross validation to find the best model
  
  k <- 10       # number of folds
  set.seed(1)  # for reproducibility
  
  folds     <- sample(1:k, nrow(mtcars), replace = TRUE)
  cv.errors <- matrix(NA, k, 9, dimnames = list(NULL, paste(2:10)))
  
  predict.regsubsets <- function(object, newdata, id, ...){
    formula <- as.formula(object$call[[2]])
    mat     <- model.matrix(formula, newdata)
    coefi   <- coef(object, id=id)
    xvars   <- names(coefi)
    mat[,xvars]%*%coefi
  } 
  
  for (j in 1:k){
    best.fit <- regsubsets(mpg ~ ., data = mtcars[folds!=j,], force.in = 8, nvmax = 10)
    for (i in 1:9){
      pred <- predict.regsubsets(best.fit, newdata = mtcars[folds==j,], id=i)
      cv.errors[j,i] <- mean((mtcars$mpg[folds==j]-pred)^2)
    }
  }
  
  # average accross folds and plot
  mean.cv.errors <- apply(cv.errors,2,mean, na.rm=TRUE)
  opt.cv <- which.min(mean.cv.errors)

  plot(2:10,mean.cv.errors, type = "b", xlab = "Number of predictors (including am)", ylab = "test MSE")
  points(opt.cv+1, mean.cv.errors[opt.cv], col = "red", cex = 2, pch = 20)

  
  # The above result suggests that a model containing 3 variables,
  # including am,  should be enough to describe the outcome.

  # REMARK : USING LOOCV WE CLEARLY SEE A MINIMAL TEST MSE FOR 3 PREDICTORS
  
  # Finally perform best subset on the full dataset and get the coefficient for the 3-variables model
  # (this is just for completeness since we did it previously)
  
  regfit.final <- regsubsets(mpg ~ ., data = mtcars, force.in = 8)
  coef(regfit.final,3)
  coef(regfit.final,1)

  
  # Conclusion : best predictors are : 
  #   - AM : the transmission type (0 for automatic, 1 for manual)
  #   - QSEC (1/4 mile time in seconds)
  #   - WT : the weight (in lb/1000)
  
  
# BEST SUBSET SELECTION INC. ALL VARIABLES  ####
# Same as above but we consider all variables in the dataset, and do not force "am" in.
  
  data(mtcars)
  library(leaps)
  
  k <- 10       # number of folds
  set.seed(1)  # for reproducibility
  
  folds     <- sample(1:k, nrow(mtcars), replace = TRUE)
  cv.errors <- matrix(NA, k, 10, dimnames = list(NULL, paste(1:10)))
  
  
  predict.regsubsets <- function(object, newdata, id, ...){
    formula <- as.formula(object$call[[2]])
    mat     <- model.matrix(formula, newdata)
    coefi   <- coef(object, id=id)
    xvars   <- names(coefi)
    mat[,xvars]%*%coefi
  } 
  
  for (j in 1:k){
      
    # fit 2 to 8 variables models
    best.fit <- regsubsets(mpg ~ ., data = mtcars[folds!=j,], nvmax = 10)
    for (i in 1:10){
      pred <- predict.regsubsets(best.fit, newdata = mtcars[folds==j,], id=i)
      cv.errors[j,i] <- mean((mtcars$mpg[folds==j]-pred)^2)
    }
  }
  
  # average accross folds and plot
  mean.cv.errors <- apply(cv.errors,2,mean)
  opt.cv <- which.min(mean.cv.errors)

  plot(1:10,mean.cv.errors, type = "b", xlab = "Number of predictors", ylab = "CV test MSE")

  points(opt.cv, mean.cv.errors[opt.cv], col = "red", cex = 2, pch = 20)

  regfit.final <- regsubsets(mpg ~ ., data = mtcars, nvmax = 10)
  coef(regfit.final,3)
  
  # Not forcing am variable in the model, best result is obtain with 2 predictors : cyl and wt.
  # However the 3-predictor model, which presents the second lower test MSE, is the same as
  # obtained previously (i.e. predictors wt, qsec and am)

regfit.all <- regsubsets(mpg ~ ., data = mtcars)
summary(regfit.all)
  