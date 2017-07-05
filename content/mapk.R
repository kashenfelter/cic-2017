##' ---
##' output: 
##'   md_document:
##'     variant: markdown_github
##' ---

#+ echo=FALSE, message=FALSE
knitr::opts_chunk$set(message=FALSE,fig.path="img/mapk-R-",comment=".",fig.align="center")

#+ echo=TRUE

##' # Reference
##' 
##' - Title 
##'     - *Clinical responses to ERK inhibition
##' in BRAF{V600E}-mutant colorectal cancer predicted
##' using a computational model*
##' - Authors
##'     - Daniel C. Kirouac
##'     - Gabriele Schaefer
##'     - Jocelyn Chan
##'     - Mark Merchant
##'     - Christine Orr
##'     - Shih-Min A. Huang
##'     - John Moffat
##'     - Lichuan Liu
##'     - Kapil Gadkar
##'     - Saroja Ramanujan
##' - Citation
##'     - npj Systems Biology and Applications, 3
##'     - Article number: 14 (2017)
##'     - doi: 10.1038/s41540-017-0016-1
##' 
##' 


##' # Setup

##' ### Required packages
library(mrgsolve)
library(readr)
library(magrittr)
library(mrgsolvetk)
library(dplyr)
library(ggplot2)
source("src/functions.R")

##' ### Load the model
mod <- mread("mapk", "model")

##' ### Load in vpop dataset
##' 
##' - This was provided in the supplementary material
##' 
vp <- read_csv("data/s10vpop.csv") %>% slice(1)


##' ### Update parameters and initial conditions
mod %<>% param(vp) %>% init(vp) %>% update(end=56,delta=0.1)

##' ## Simple simulation scenario
##' 
##' - `GDC` is the `TUMOR` `GDC-0994` concentration (partition coefficient=1; `ERKi`)
##' - `TUMOR` is the `CELLS` compartment (renamed for clarity here)`
##' 
dataG <- datag(400)

out <- mrgsim(mod,data=dataG,obsonly=TRUE,Req="GDC,TUMOR")
out

plot(out)


##' ## Dose/response
dataG2 <- datag(amt=c(150,200,300,400))
out <- mrgsim(mod,data=dataG2,obsonly=TRUE,Req="GDC,TUMOR")
out

plot(out)



##' ## Sensitivity analysis - `wOR`
.mod <- update(mod,events=as.ev(dataG,keep_id=FALSE),delta=0.25)

set.seed(2223)
out <- sens_unif(.mod, n=200, lower = 0.9, upper=1, 
                 pars="wOR",Req="GDC,TUMOR")

out %<>% mutate(wORq = cutq(wOR))

ggplot(out, aes(time,TUMOR,col=wORq,group=ID)) + 
  geom_line() + geom_hline(yintercept=1, lty=2) +
  .colSet1() 


##' ## Sensitivity analysis - `taui4`
##' 
##' - Adding 30% variability to IC50
##' 

set.seed(3332)
out <- sens_norm(.mod, n=200, cv=30, pars="taui4",Req="GDC,TUMOR")

out %<>% mutate(taui4q = cutq(taui4))

ggplot(out, aes(time,TUMOR,col=taui4q,group=ID)) + 
  geom_line() + geom_hline(yintercept=1, lty=2) +
  .colSet1() 


##' ## Explore doses in the `vpop`
set.seed(111)
vp <- read_csv("data/s10vpop.csv") %>% sample_n(250,replace=TRUE,weight=PW)
vp %<>% mutate(ID = 1:n())
data <- datag(1)

sim <- function(dose) {
  data %<>% mutate(amt=dose)
  mrgsim(mod,idata=vp,events=as.ev(data,keep_id=FALSE),
         end=-1,add=56,obsonly=TRUE,Req="TUMOR") %>% mutate(dose=dose)
}

library(parallel)
doses <- c(seq(0,400,100),800)
out <- mclapply(doses,sim)

sims <- bind_rows(out) %>% mutate(dosef = nfact(dose))

ggplot(data=sims, aes(x=dosef,y=TUMOR)) + 
  geom_point(position=position_jitter(width=0.1),col="darkgrey") +
  geom_hline(yintercept=0.7,col="darkslateblue",lty=2) + 
  geom_boxplot(aes(fill=dosef),alpha=0.4) + ylim(0,2.25) +
  .fillSet1(name="")

##' ### Summary
sims %>% 
  group_by(dosef) %>%
  summarise(med=median(TUMOR), R30 = mean(TUMOR < 0.7))
























