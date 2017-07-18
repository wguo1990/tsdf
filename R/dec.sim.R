#' Dose-finding simulations
#' @description Run dose-finding simulations based on a customized decision table.
#' @param truep A vector of length k (the number of doses being considered in the trial), with values equal to the true probabilities of toxicity at the dose levels.
#' @param decTable A customized decision table. (same format as output of \code{\link{dec.table}})
#' @param start.level Starting dose level. Defaults to 1, i.e. the lowest dose level.
#' @param nsim The number of simulation trials. Defaults to 1000.
#' @return The functions \code{\link{summary.dec.sim}} is used to obtain and print a summary table of the results (recommended). An object of class \code{"dec.sim"} is a list containing:
#'  \item{mtd}{a vector of dose levels giving the recommended maximum tolerated dose (MTD) at the end of the trial.}
#'  \item{mtd.prob}{a vector of length \code{k} giving the average proportions of selected as MTD at each dose level}
#'  \item{n.patients}{the average number of patients dosed at each level.}
#'  \item{dlt}{the average number of DLTs experienced at each dose level}
#'  \item{truep}{input; true probabilities of toxicity.}
#'  \item{start.level}{input; starting dose level.}
#'  \item{nsim}{input; number of simulated trails.}
#' @author Wenchuan Guo <wguo007@ucr.edu>
#' @import stats
#' @export
#' @examples
#' truep <- c(0.3, 0.45, 0.5, 0.6)
#' res <- dec.table(0.6,0.4,0.2,0.3,0.3,c(3,3,3))
#' out <- dec.sim(truep, res$table, start.level=2, nsim=1000)
#' summary(out, pt=0.3)

dec.sim  <- function(truep, decTable, start.level = 1, nsim = 1000) {
  # initialization
  n_dose <- length(truep)
  maxn <- 9
  mtd <- rep(0, nsim)
  np <- matrix(0, nrow=nsim, ncol=n_dose)
  dlt <- matrix(0, nsim, n_dose)
  for(i in 1:nsim){
    # dose need to be removed
    rm.dose <- NULL
    # current dose level
    dose <- start.level
    while(mtd[i] == 0){
      np[i, dose] <- np[i, dose] + 3
      dlt[i, dose] <- dlt[i, dose] + sum(rbinom(3, 1, truep[dose]))
      des <- decTable[dlt[i, dose]+1, np[i, dose]/3]
      # case: stay (S)
      if(des == "S"){
        if(np[i, dose]!=maxn) {
          dose <- dose
        }
        else {
          mtd[i] <- dose
        }
      }
      # case : escalate (E)
      if(des == "E") {
        # check if next dose level is available
        if((dose+1)%in%rm.dose){
          mtd[i] <- dose
        } else {
          # check if can escalate
          if(dose!=n_dose){
            if(np[i, dose+1] != maxn) {
              dose <- dose + 1
            } else {
              next_des <- decTable[dlt[i, dose + 1] + 1, np[i, dose + 1]/3]
              if(next_des == "D" | next_des == "DU"){
                mtd[i] <- dose
              } else {
                mtd[i] <- dose + 1
              }
            }
          } else {
            mtd[i] <- dose
          }
        }
      }
      # case : de-escalate (D)
      if(des == "D") {
        if(dose!=1) {
          if(np[i, dose-1] != maxn) {
            dose <- dose - 1
          } else {
            mtd[i] <- dose -1
          }
        } else {
          mtd[i] <- dose
        }
      }
      # case : de-escalate U
      if(des == "DU") {
        if(dose != 1) {
          # can not go back to this dose again
          rm.dose <- c(rm.dose, dose)
          if(np[i, dose-1] != maxn) {
            dose <- dose - 1
          } else {
            mtd[i] <- dose -1
          }
        } else {
          mtd[i] <- dose
        }
      }
    }
  }
  mtd.prob <- sapply(1:n_dose, function(ii) mean(mtd==ii))

  out <- list(mtd = mtd, mtd.prob = mtd.prob, dlt = colMeans(dlt), n.patients = colMeans(np), truep = truep, start.level = start.level, nsim = nsim)
  class(out) <- "dec.sim"
  return(out)
}