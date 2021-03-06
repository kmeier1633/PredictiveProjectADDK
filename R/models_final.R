
#####################################################
#####################################################
######################################################
# LOGISTIC REGRESSION MODELS
# MULTIPLE LINEAR REGRESSION MODELS
# EXPECTED DONATION CALCULATION
######################################################
#####################################################
#####################################################

#install.packages('ROCR')
library(ROCR)
library(pROC)

who = "dustin"

# Set appropriate file address
if(who=="kristin"){
  address <- '/Users/kmeier92/Documents/Northwestern/fall2016/Predictive_Analytics/PredictiveProjectADDK/'
}
if(who=="adit"){
  address <- ''
}
if(who=="dylan"){
  address <- 'C:/Users/Dylan/Documents/Northwestern/Predictive Analytics I/PROJECT/'
}
if(who=="dustin"){
  address <- 'C:/Users/Dustin/Documents/Northwestern/Predictive Analytics 1/PredictiveProjectADDK/'
}

# source R code that cleans the data as needed
setwd(address)
source(paste(address,'R/cleandata.R',sep=""))
# functions auc & ccr
source(paste(address,'R/helper.R',sep=""))

# call function to create the 2 datasets 
thedata <- cleandata(dropNA=T)

donTRAINING_orig <- thedata$train
donTEST_orig <- thedata$test

#add quadratic and interaction terms to data
donTRAINING_orig <- addSecondDegree(donTRAINING_orig)
donTEST_orig <- addSecondDegree(donTEST_orig)

#####################################################
#####################################################
######################################################
# LOGISTIC REGRESSION MODEL
######################################################
#####################################################
#####################################################

# fit basic logistic regression model
# https://www.r-bloggers.com/evaluating-logistic-regression-models/

######################################################
# 1 BASIC LOGISTIC MODEL 
######################################################

# what to do regression on
keepcols <- c("donated", "CNDOL1", "CNTRLIF", "CONLARG", "CONTRFST",
              "CNDOL2", "CNDOL3", "CNTMLIF", "SEX", "CNMON1", 
              "CNMONF", "CNMONL", "ContType1", "SolType1",
              "avg", "avgTime", "don2", "don3","incr_don", "Region")

#filter data sets to appropriate columns
donTRAINING <- donTRAINING_orig[,(names(donTRAINING_orig) %in% keepcols)]
donTEST <- donTEST_orig[,(names(donTEST_orig) %in% keepcols)]

logModel <- glm(donated ~ . , data = donTRAINING, family=binomial)
sum.mod <- summary(logModel)

num.pred <- nrow(sum.mod$coefficients)

auc(model=logModel) # 0.716036
ccr(model=logModel) # 0.7530394

##########################
# 2. BACKWARDS STEPWISE
##########################

logModel <- glm(donated ~ . , data = donTRAINING, family=binomial)

backwards = step(logModel)
summary(backwards)

auc(model=backwards) # 0.716004
ccr(model=backwards) # 0.7531906

# final with NA
'donated ~ CNDOL1 + CNTRLIF + CONLARG + CONTRFST + CNDOL2 + CNTMLIF + 
CNMON1 + CNMONF + CNMONL + avgTime + don2 + don3 + incr_don + 
SEX + ContType1 + SolType1 + Region'

##########################
# 3. FORWARD STEPWISE
##########################

nothing <- glm(donated ~ 1, data = donTRAINING, family=binomial)
forwards = step(nothing,
                scope=list(lower=formula(nothing),upper=formula(logModel)),
                direction="forward")

summary(forwards)

# final w/ NA
'
donated ~ CNMON1 + CNMONL + CNTMLIF + CNMONF + ContType1 + CONTRFST + 
SolType1 + incr_don + SEX + don2 + avgTime + CNTRLIF + CNDOL2 + 
CNDOL1 + CONLARG + don3 + Region
'

auc(model=forwards) # 0.716004
ccr(model=forwards) # 0.7531906


######################################################
# 4. QUADRATIC TERMS ADDED
# http://stats.stackexchange.com/questions/28730/does-it-make-sense-to-add-a-quadratic-term-but-not-the-linear-term-to-a-model
######################################################

keepcols.quad <- c("donated", "CNDOL1", "CNTRLIF", "CONLARG", "CONTRFST",  "CNDOL2", "CNDOL3",
                   "CNTMLIF", "SEX", "CNMON1","CNMONF", "CNMONL", "ContType1", 
                   "SolType1",  "avg", "avgTime", "don2", "don3", "incr_don", "Region", "sq_CNDOL1", 
                   "sq_CNTRLIF", "sq_CONLARG", "sq_CONTRFST",
                   "sq_CNDOL2", "sq_CNDOL3", "sq_CNTMLIF", "sq_CNMON1", 
                   "sq_CNMONF", "sq_CNMONL", "sq_avg", "sq_avgTime")

donTRAINING.quad <- donTRAINING_orig[,(names(donTRAINING_orig) %in% keepcols.quad)]
donTEST.quad <- donTEST_orig[,(names(donTEST_orig) %in% keepcols.quad)]

logModel.quad <- glm(donated ~ . , data = donTRAINING.quad, family=binomial)
sum.mod.quad <- summary(logModel.quad)

num.pred.quad <- nrow(sum.mod.quad$coefficients)

auc(model=logModel.quad, testdata = donTEST.quad) # 0.7194766
ccr(model=logModel.quad, testdata = donTEST.quad) # 0.7550656

###################################
# 5. BACKWARDS STEPWISE - W/ QUADRATIC
###################################

logModel.quad <- glm(donated ~ . , data = donTRAINING.quad, family=binomial)

backwards.quad = backwards

backwards.quad = step(logModel.quad)
summary(backwards.quad)

'final w/ NA
donated ~ sq_CNDOL1 + sq_CONLARG + sq_CNDOL2 + sq_CNTMLIF + sq_CNMON1 + 
sq_CNMONL + sq_avg + sq_avgTime + CNDOL1 + CNTRLIF + CONLARG + 
CONTRFST + CNDOL2 + CNTMLIF + CNMON1 + CNMONF + CNMONL + 
avg + avgTime + don2 + don3 + incr_don + SEX + ContType1 + 
SolType1 + Region
'

auc(model=backwards.quad, testdata = donTEST.quad) # 0.7194993
ccr(model=backwards.quad, testdata = donTEST.quad) # 0.7550051

###################################
# 6. ALL SECOND DEGREE TERMS ADDED (interaction and quadratic)
###################################

donTRAINING2 <- donTRAINING_orig
donTEST2 <- donTEST_orig

logModelInter <- glm(donated ~ . -targdol, data = donTRAINING2, family=binomial)
sum.mod2 <- summary(logModelInter)

num.pred2 <- nrow(sum.mod2$coefficients)

auc(model=logModelInter, testdata=donTEST2, testresponse = donTEST2$donated) # 0.7939676
ccr(model=logModelInter, testdata=donTEST2, testresponse = donTEST2$donated) # 0.7392989

########################################
# 7. log model with quadratic and log terms
########################################

logModel.quad.log <- glm(donated ~ log(CNDOL1)+CNTRLIF+log(CONLARG)+log(CONTRFST+1)+log(CNDOL2+1)+CNDOL3+CNTMLIF+SEX+CNMON1+
                           CNMONF+CNMONL+ContType1+SolType1+avg+avgTime+don2+don3+incr_don+Region+log(sq_CNDOL1)+sq_CNTRLIF+
                           log(sq_CONLARG)+log(sq_CONTRFST+1)+log(sq_CNDOL2+1)+sq_CNDOL3+sq_CNTMLIF+sq_CNMON1+sq_CNMONF+sq_CNMONL+
                           log(sq_avg)+sq_avgTime, data = donTRAINING.quad, family=binomial)

auc(model=logModel.quad.log, testdata = donTEST.quad, testresponse = donTEST.quad$donated)
ccr(model=logModel.quad.log, testdata = donTEST.quad, testresponse = donTEST.quad$donated) 

# classification table
model = logModel.quad.log 
testdata = donTEST.quad
testresponse = donTEST.quad$donated
pstar=.5
# confusion matrix
p <- predict(model, newdata=testdata, type="response")
tab = table(testresponse, p > pstar)
tab

#####################################################
#####################################################
######################################################
# MULTIPLE LINEAR REGRESSION W/ DONATION > 0
# http://stats.stackexchange.com/questions/28730/does-it-make-sense-to-add-a-quadratic-term-but-not-the-linear-term-to-a-model
######################################################
#####################################################
#####################################################

########################################
# 1. Basic multiple linear regression
########################################

# now only want where TARGDOL > 0

# what to do regression on
keepcols.lm <- c("targdol", "CNDOL1", "CNTRLIF", "CONLARG", "CONTRFST",  "CNDOL2", "
                 CNDOL3", "CNTMLIF", "SEX", "CNMON1", "CNMONF", "CNMONL", "ContType1",
                 "SolType1", "avg", "avgTime", "don2", "don3","incr_don","Region")

donTRAINING.lm <- donTRAINING_orig[,(names(donTRAINING_orig) %in% keepcols.lm)]
donTEST.lm <- donTEST_orig[,(names(donTEST_orig) %in% keepcols.lm)]
donTRAINING.lm <- donTRAINING.lm[donTRAINING.lm$targdol > 0,]
donTEST.lm <- donTEST.lm[donTEST.lm$targdol > 0,]

lmModel <- lm(targdol ~ . , data = donTRAINING.lm)
sum.mod.lm <- summary(lmModel)

num.pred.lm <- nrow(sum.mod.lm$coefficients)

r2.lm <- sum.mod.lm$r.squared # 0.8389792

##########################
# 2. BACKWARDS STEPWISE - LM
##########################

backwards.lm = step(lmModel)
sum.back.lm = summary(backwards.lm)

r2.lm.back <- sum.back.lm$r.squared # 0.838841
sum.back.lm
' final w/ NA
targdol ~ CNDOL1 + CNTRLIF + CONLARG + CONTRFST + 
CNDOL2 + CNTMLIF + CNMONF + CNMONL + avg + don2 + don3 + 
incr_don + ContType1 + SolType1'

##########################
# 3. ADD QUADRATIC - LM W/ QUADRATIC
##########################

keepcols.quad <- c("targdol", "CNDOL1", "CNTRLIF", "CONLARG", "CONTRFST", "CNDOL2","CNDOL3", 
                   "CNTMLIF",  "SEX", "CNMON1", "CNMONF", "CNMONL", "ContType1", 
                   "SolType1", "avg", "avgTime", "don2", "don3", "incr_don", "Region", "sq_CNDOL1", 
                   "sq_CNTRLIF", "sq_CONLARG", "sq_CONTRFST", 
                   "sq_CNDOL2", "sq_CNDOL3", "sq_CNTMLIF",  
                   "sq_CNMON1",  
                   "sq_CNMONF", "sq_CNMONL", "sq_avg", "sq_avgTime")


donTRAINING.lm.quad <- donTRAINING_orig[,(names(donTRAINING_orig) %in% keepcols.quad)]
donTEST.lm.quad <- donTEST_orig[,(names(donTEST_orig) %in% keepcols.quad)]
donTRAINING.lm.quad <- donTRAINING.lm.quad[donTRAINING.lm.quad$targdol > 0,]
donTEST.lm.quad <- donTEST.lm.quad[donTEST.lm.quad$targdol > 0,]

lmModel.quad <- lm(targdol ~ . , data = donTRAINING.lm.quad)
sum.mod.lm.quad <- summary(lmModel.quad)

num.pred.lm.quad <- nrow(sum.mod.lm.quad$coefficients)

r2.lm.quad <- sum.mod.lm.quad$r.squared # 0.8804493

##########################
# 4. BACKWARDS STEPWISE LM W/ QUADRATIC
##########################

backwards.lm.quad = step(lmModel.quad)
sum.back.lm.quad = summary(backwards.lm.quad)

r2.lm.back.quad <- sum.back.lm.quad$r.squared # 0.8803298

'final w/ NA
targdol ~ sq_CNDOL1 + sq_CNTRLIF + sq_CONLARG + 
sq_CONTRFST + sq_CNDOL2 + sq_CNDOL3 + sq_CNTMLIF + sq_CNMON1 + 
sq_CNMONL + sq_avg + sq_avgTime + CNDOL1 + CNTRLIF + CONLARG + 
CONTRFST + CNDOL2 + CNDOL3 + CNTMLIF + CNMONF + CNMONL + 
avg + avgTime + don2 + don3 + incr_don + SEX + ContType1 + 
SolType1
'
###################################
# 5. ALL SECOND DEGREE TERMS ADDED
###################################

donTRAINING.lm.inter <- donTRAINING_orig
donTEST.lm.inter <- donTEST_orig
donTRAINING.lm.inter <- donTRAINING.lm.inter[donTRAINING.lm.inter$targdol > 0,]
donTEST.lm.inter <- donTEST.lm.inter[donTEST.lm.inter$targdol > 0,]

lmModel.inter <- lm(targdol ~ . , data = donTRAINING.lm.inter)
sum.mod.lm.inter <- summary(lmModel.inter)

num.pred.lm.inter <- nrow(sum.mod.lm.inter$coefficients)

r2.lm.inter <- sum.mod.lm.inter$r.squared # 0.9517647

#####################################################
# 6. lm with removed influential obs
#####################################################
#find and remove influential observations
zz <- influence.measures(lmModel)
inf <- which(apply(zz$is.inf,1,any))
donTRAINING.lm2 <- donTRAINING.lm[-(inf),]
?influence.measures()
lmModel.rminf <- lm(targdol ~ ., data = donTRAINING.lm2)

#fix missing levels
lmModel.rminf$xlevels[["SEX"]] <- union(lmModel.rminf$xlevels[["SEX"]], levels(donTEST_orig$SEX))
lmModel.rminf$xlevels[["ContType1"]] <- union(lmModel.rminf$xlevels[["ContType1"]], levels(donTEST_orig$ContType1))
lmModel.rminf$xlevels[["SolType1"]] <- union(lmModel.rminf$xlevels[["SolType1"]], levels(donTEST_orig$SolType1))
lmModel.rminf$xlevels[["Region"]] <- union(lmModel.rminf$xlevels[["Region"]], levels(donTEST_orig$Region))

sum.mod.lm2 <- summary(lmModel.rminf)
num.pred.lm2 <- nrow(sum.mod.lm2$coefficients)
r2.lm2 <- sum.mod.lm2$r.squared # 0.6744903

#####################################################
# 7. lm with quadratic terms added and removed influential obs
#####################################################
#find and remove influential observations
yy <- influence.measures(lmModel.quad)
infl <- which(apply(yy$is.inf,1,any))
donTRAINING.lm.quad.rminf <- donTRAINING.lm.quad[-(infl),]

lmModel.quad.rminf <- lm(targdol ~ . , data = donTRAINING.lm.quad.rminf)

#fix missing levels
lmModel.quad.rminf$xlevels[["SEX"]] <- union(lmModel.quad.rminf$xlevels[["SEX"]], levels(donTEST_orig$SEX))
lmModel.quad.rminf$xlevels[["ContType1"]] <- union(lmModel.quad.rminf$xlevels[["ContType1"]], levels(donTEST_orig$ContType1))
lmModel.quad.rminf$xlevels[["SolType1"]] <- union(lmModel.quad.rminf$xlevels[["SolType1"]], levels(donTEST_orig$SolType1))
lmModel.quad.rminf$xlevels[["Region"]] <- union(lmModel.quad.rminf$xlevels[["Region"]], levels(donTEST_orig$Region))


sum.mod.lm.quad.rminf <- summary(lmModel.quad.rminf)
num.pred.lm.quad.rminf <- nrow(sum.mod.lm.quad.rminf$coefficients)
r2.lm2 <- sum.mod.lm.quad.rminf$r.squared # 0.6852158

###########################################
# 8. LM QUAD. TERMS AND TAKE LOG OF SOME COLUMNS
###########################################

lmModel.quad.log <- lm(targdol ~ log(sq_CNDOL1)+sq_CNTRLIF+log(sq_CONLARG)+log(sq_CONTRFST+1)+log(sq_CNDOL2+1)+
                         sq_CNDOL3+sq_CNTMLIF+sq_CNMON1+sq_CNMONF+sq_CNMONL+I(log(sq_avg))+sq_avgTime+log(CNDOL1)+
                         CNTRLIF+log(CONLARG)+log(CONTRFST+1)+log(CNDOL2+1)+CNDOL3+CNTMLIF+CNMON1+CNMONF+CNMONL+avg+
                         avgTime+don2+don3+incr_don+SEX+ContType1+SolType1+Region, data = donTRAINING.lm.quad)
summary(lmModel.quad.log)

expected.don(logModel.quad,lmModel.quad.log)

#####################################################
#####################################################
######################################################
# EXPECTED DONATIONS
######################################################
#####################################################
#####################################################

logmodelnames = c("logModel", "logModel.quad","backwards","backwards.quad", "logModelInter", "logModel.quad.log")
logmodels = list(logModel, logModel.quad, backwards, backwards.quad, logModelInter, logModel.quad.log)
lmmodelnames = c("lmModel", "lmModel.quad", "backwards.lm.quad", "backwards.lm", "lmModel.inter", "lmModel.rminf", "lmModel.quad.rminf", "lmModel.quad.log")
lmmodels = list(lmModel, lmModel.quad, backwards.lm.quad, backwards.lm, lmModel.inter, lmModel.rminf, lmModel.quad.rminf, lmModel.quad.log)

don.output <- data.frame("","",0,stringsAsFactors=FALSE)
colnames(don.output) <- c("logmodel","lmmodel","exp.don")
for(i in 1:length(logmodelnames)){
  for(j in 1:length(lmmodelnames)){
    newcol <- c(logmodelnames[i],
                lmmodelnames[j],
                expected.don(final.log.model = logmodels[[i]],
                             final.lm.model = lmmodels[[j]]))
    don.output <- rbind(don.output,newcol)
  }
}
don.output <- don.output[2:nrow(don.output),]
don.output$exp.don <- as.numeric(don.output$exp.don)
# ORDER GREATEST TO LEAST
don.output[order(-don.output$exp.don),]

'
NEW
           logmodel            lmmodel  exp.don
49 logModel.quad.log   lmModel.quad.log 10428.23
17     logModel.quad   lmModel.quad.log 10340.73
44 logModel.quad.log  backwards.lm.quad 10334.23
43 logModel.quad.log       lmModel.quad 10295.23
48 logModel.quad.log lmModel.quad.rminf 10280.73
33    backwards.quad   lmModel.quad.log 10275.73
41     logModelInter   lmModel.quad.log 10210.73
47 logModel.quad.log      lmModel.rminf 10190.73
46 logModel.quad.log      lmModel.inter 10182.73
11     logModel.quad       lmModel.quad 10123.23
12     logModel.quad  backwards.lm.quad 10102.23
38     logModelInter      lmModel.inter 10070.73
28    backwards.quad  backwards.lm.quad 10047.23
27    backwards.quad       lmModel.quad 10032.23
35     logModelInter       lmModel.quad 10028.73
36     logModelInter  backwards.lm.quad 10018.73
42 logModel.quad.log            lmModel  9999.73
32    backwards.quad lmModel.quad.rminf  9977.23
40     logModelInter lmModel.quad.rminf  9976.34
30    backwards.quad      lmModel.inter  9975.23
20         backwards  backwards.lm.quad  9957.23
16     logModel.quad lmModel.quad.rminf  9945.66
45 logModel.quad.log       backwards.lm  9939.73
14     logModel.quad      lmModel.inter  9938.23
4           logModel  backwards.lm.quad  9917.23
19         backwards       lmModel.quad  9912.23
3           logModel       lmModel.quad  9892.23
39     logModelInter      lmModel.rminf  9891.34
15     logModel.quad      lmModel.rminf  9872.23
31    backwards.quad      lmModel.rminf  9857.23
9           logModel   lmModel.quad.log  9845.23
25         backwards   lmModel.quad.log  9815.23
6           logModel      lmModel.inter  9777.23
22         backwards      lmModel.inter  9760.23
23         backwards      lmModel.rminf  9673.23
24         backwards lmModel.quad.rminf  9663.23
34     logModelInter            lmModel  9624.34
37     logModelInter       backwards.lm  9624.34
7           logModel      lmModel.rminf  9623.23
8           logModel lmModel.quad.rminf  9603.23
26    backwards.quad            lmModel  9602.23
10     logModel.quad            lmModel  9589.23
13     logModel.quad       backwards.lm  9546.23
29    backwards.quad       backwards.lm  9534.23
5           logModel       backwards.lm  9435.23
21         backwards       backwards.lm  9410.23
2           logModel            lmModel  9400.23
18         backwards            lmModel  9380.23
'
