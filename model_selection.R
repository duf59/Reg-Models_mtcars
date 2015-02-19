# model_selection.R
# Author : R. Dufour
# February 2015
#
# This script is part of the course project of "Regression models" on Coursera
# See the readme file for the project intsructions
#
# The aim of the following code is to select a model, i.e. a set of predictor related with the response (mpg)
# To this purpose we best subset selection and 10-fold cross-validation to estimate test MSE.

# Note that the mtcars contains two types of variables :
#
# * design variables :  
#   - AM (transmission type)
#   - VS (Engine Shape : 1 = Straight, 0 = V)
#   - DISP (Engine size, in cubic inches)
#   - DRAT (Final drive ratio == Rear axle ratio)
#   - CYL (number of cylinders)
#   - GEAR (number of transmission speed == number of forward gears)
#   - CARB (number of carburetors)
#   - WT (weight)
#
# * performance variables : 
#   - HP (Gross horsepower)
#   - QSEC (1/4 mile time in seconds)
#   - MPG (Gasoline mileage in Miles per gallon)
#
# Here we consider mpg as the outcome, and the design variables as the potential predictors.
# Thereby hp and qsec have been removed.

# Load the data
  data(mtcars)
  str(mtcars)
  mtcars <- mtcars[,-c(4,7)]
  sum(!complete.cases(mtcars))  # check all observations are complete
  
# BEST SUBSET SELECTION ####
# Perform best subset selection and look at the adjusted R² as indicator of model performance
  library(leaps)
  regfit.full <- regsubsets(mpg  ~ ., data = mtcars, force.in = 6)
  reg.summary <- summary(regfit.full)
  
  # least square fit with am variable only
  am.fit <- lm(mpg ~ am, data = mtcars)
  am.summary <- summary(am.fit)
  
  # Find optimal model based on adjusted R square (Cp and BIC give the same result)
  opt <- which.max(c(am.summary$adj.r.squared, reg.summary$adjr2))
  
  par(mfrow = c(1,1))
  plot(1:8,c(am.summary$adj.r.squared, reg.summary$adjr2), type = "b", xlab = "Number of predictors",
       ylab = "Adjusted RSq")
  points(opt,reg.summary$adjr2[opt-1], col = "red", cex = 2, pch = 20)
  
  # get the coefficient estimates for the optimal model
  coef(regfit.full,opt-1)
  
# BEST SUBSET SELECTION INC. "AM" WITH CROSS-VALIDATION ####
# Use cross validation to find the best model
  
  k <- 5       # number of folds
  set.seed(1)  # for reproducibility
  
  folds     <- sample(1:k, nrow(mtcars), replace = TRUE)
  cv.errors <- matrix(NA, k, 8, dimnames = list(NULL, paste(1:8)))
  
  
  predict.regsubsets <- function(object, newdata, id, ...){
    formula <- as.formula(object$call[[2]])
    mat     <- model.matrix(formula, newdata)
    coefi   <- coef(object, id=id)
    xvars   <- names(coefi)
    mat[,xvars]%*%coefi
  } 
  
  
  for (j in 1:k){
    # fit the 1 variable model
    am.fit <- lm(mpg ~ am, data = mtcars[folds!=j,])
    am.pred <- predict(am.fit, newdata = mtcars[folds==j,])
    cv.errors[j,1] <- mean((mtcars$mpg[folds==j]-am.pred)^2)
    
    # fit 2 to 8 variables models
    best.fit <- regsubsets(mpg ~ ., data = mtcars[folds!=j,], force.in = 6)
    for (i in 2:8){
      pred <- predict.regsubsets(best.fit, newdata = mtcars[folds==j,], id=i-1)
      cv.errors[j,i] <- mean((mtcars$mpg[folds==j]-pred)^2)
    }
  }
  
  # average accross folds and plot
  mean.cv.errors <- apply(cv.errors,2,mean)
  mean.cv.sd <- apply(cv.errors,2,sd)
  par(mfrow = c(1,1))
  plot(1:8,mean.cv.errors, type = "b", xlab = "Number of predictors",
       ylab = "CV test MSE")
  opt.cv <- which.min(mean.cv.errors)
  points(opt.cv, mean.cv.errors[opt.cv], col = "red", cex = 2, pch = 20)
  mean.cv.sd[opt.cv]
  mean.cv.errors[opt.cv] + mean.cv.sd[opt.cv]
  
  # The above result also suggests than a model containing 4 variables,
  # including am, is enough to describe the outcome.
  
  # Note : the above code should be improved to see if the 4 optimal variables
  # remain the same or if they change accross the different folds.
  
  # Finally perform best subset on the full dataset and get the coefficient for the 4-variable model
  # (this is just for completeness since we did it previously)
  
  regfit.final <- regsubsets(mpg ~ ., data = mtcars, force.in = 6)
  summary(regfit.final)
  coef(regfit.final,3)
  
  # Conclusion : best predictors are : 
  #   - AM : the transmission type (0 for automatic, 1 for manual)
  #   - CYL : the number of cylinders
  #   - CARB : the number of carburetors
  #   - WT : the weight (in lb/1000)
  
  
  # BEST SUBSET SELECTION INC. ALL VARIABLES WITH CROSS-VALIDATION ####
  # Same as above but we consider all variables in the dataset, and do not force "am" in.
  
  data(mtcars)
  library(leaps)
  
  k <- 5       # number of folds
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
  mean.cv.sd <- apply(cv.errors,2,sd)
  par(mfrow = c(1,1))
  plot(1:10,mean.cv.errors, type = "b", xlab = "Number of predictors",
       ylab = "CV test MSE")
  opt.cv <- which.min(mean.cv.errors)
  points(opt.cv, mean.cv.errors[opt.cv], col = "red", cex = 2, pch = 20)
  mean.cv.sd[opt.cv]
  mean.cv.errors[opt.cv] + mean.cv.sd[opt.cv]
  
  # The above result also suggests than a model containing 4 variables,
  # including am, is enough to describe the outcome.
  
  # Note : the above code should be improved to see if the 4 optimal variables
  # remain the same or if they change accross the different folds.
  
  # Finally perform best subset on the full dataset and get the coefficient for the 4-variable model
  # (this is just for completeness since we did it previously)
  
  regfit.final <- regsubsets(mpg ~ ., data = mtcars, nvmax = 10)
  summary(regfit.final)
  coef(regfit.final,2)
  
  # Conclusion : best predictors are : 
  #   - AM : the transmission type (0 for automatic, 1 for manual)
  #   - CYL : the number of cylinders
  #   - CARB : the number of carburetors
  #   - WT : the weight (in lb/1000)
  