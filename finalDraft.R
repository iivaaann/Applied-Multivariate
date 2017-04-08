library(doParallel)
library(itertools)
library(missForest)
library(foreach)
library(qgraph)
library(mlr)
library(psych)
library(GPArotation)
library(HapEstXXR)

# This is a test to see how to edit a file

####################### DATA CLEANING #############################

ddata <- read.csv("road.csv")
#change "number NAs" to NA
ddata[ddata== 99] <- NA
ddata[ddata ==98] <- NA
sum(is.na(ddata))

# removing the rows with more than 18 observations
d <- ddata[-which(rowSums(is.na(ddata)) > 18), ]
which(colSums(is.na(ddata)) == 0)
sum(is.na(d))

#remove ID and group number columns
data <- d[, -c(1,2)]
#get rid of unused levels in factors
data$BL_YADB5 <- droplevels(data$BL_YADB5)



#turn BL_YAD85 into a factor
as.numeric.factor <- function(x) {as.numeric(levels(x))[x]}
data2 <- data
data2$BL_YADB5 <- as.numeric(levels(data2$BL_YADB5))[data2$BL_YADB5]
data2$BL_YADB5 == data$BL_YADB5
str(data2)

# create a complete dataset to compare imputed dataset to 
comp <- data2[-which(rowSums(is.na(data2)) > 0),]
#imput missing values
cl <- makeCluster(2)
registerDoParallel(cl)
im.out.2 <- missForest(xmis = data2, maxiter = 10, ntree = 500,
                       variablewise = FALSE,
                       decreasing = FALSE, verbose = FALSE,
                       replace = TRUE,
                       classwt = NULL, cutoff = NULL, strata = NULL,
                       sampsize = NULL, nodesize = NULL, maxnodes = NULL,
                       parallelize = "variables")
im.out.2$OOBerror
cdata <- cbind(im.out.2$ximp)
stopCluster(cl)
sum(is.na(cdata))

write.csv(cdata, "imputed_dat") 




########################### ANALYSIS ################################################



#1. Chose number of factors
fa.parallel(cdata[,4:31], fa = "fa", n.iter = 100, show.legend = FALSE) # shows number of factors to use


#2. choose rotation and extraction method 
# 
# chose method = "pa". Most common. According to help file, "true" minimal resid is probably found using
efa_var <- fa(cdata[,4:31], nfactors = 3, rotate = "varimax", scores = T, fm = "pa")# factor analysis with n selected factors
efa_pro <- fa(cdata[,4:31], nfactors = 3, rotate = "promax", scores = T, fm = "pa")


#3. decide how to deal with complex items

# all possible subsets
subs <- powerset(colnum)

for (i in 1:length(subs)) {
  delcol <- subs[[i]]
  splits <- fa(sdata[,-delcol], nfactors = 3, rotate = "varimax", scores = T, fm = "pa")# factor analysis with n selected factors
  rmse[i] <- splits$RMSEA[1] 
  print(i)
}

which.min(rmse)
our_sub <- as.vector(subs[1272])
our_sub

#FA without complex items 
efa_splits <- fa(sdata[, -c(11,9,25,13,23,7)], nfactors = 3, rotate = "varimax", scores = T, fm = "pa")
efa_splits

loadings(efa_splits)
factor.plot(efa, labels = rownames(efa_splits$loadings)) #??
fa.diagram(efa_splits) # shows contents of each factor

# Defining factors as indices or scales using coef. alpha