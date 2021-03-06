#' generate three-stage dose-finding decision table
#' @description Generate three stage dose finding decision table
#' @details  Alpha-spending method is added to two-/three-stage designs. \code{dec.table} supports Hwang-Shih-DeCani spending function. 
#' @param alpha.l left-side overall type 1 error. Control the upper bound of dose escalation.
#' @param alpha.r right-side overall type 1 error. Control the lower bound of dose de-escalatition.
#' @param alpha.u right-side overall type 1 error. This also controls the lower bound of dose de-escalatition, but it is used to find lower bound for "DU".
#' @param pt a numeric vector of target toxicity. Should be a vector with 1 or 2(when the target is an interval).
#' @param n a vector of sample size at each stage. \code{sum(n)} is the total sample size. For A+B designs, \code{n} is a vector with length 2; for A+B+C designs, \code{n} has length 3.
#' @param sf.param  a single real value specifying the gamma parameter for which Hwang-Shih-DeCani spending is to be computed; allowable range is [-40, 40]. Increasing this parameter implies that more error is spent early stage and less is available in late stage. Default to 4.
#' @param pe.par alternative hypothesis that used to calculate power/type 2 error. The alternative is set to be \code{pe = pt + pe.par}. Default to 0.25.
#' @param ... not used argument.
#' @return An object of class "dec.table" is a list containing:
#'  \item{table}{the generated decision table.}
#'  \item{alpha.two}{a vector of true type 1 error for two-tailed test.}
#'  \item{alpha.one}{a vector of true type 1 error for right-tailed test.}
#'  \item{beta}{a single value of true type 2 error(depends on alternative).}
#'  \item{E}{a vector of "E" bound.}
#'  \item{D}{a vector of "D" bound.}
#'  \item{DU}{a vector of "DU" bound.}
#'  \item{pt}{input; a vector of target toxicity}
#'  \item{n}{input; a vector with sample size at each stage.}
#'  \item{sf.param}{input; the alpha-spending function parameter used.}
#' @author Wenchuan Guo <wguo007@ucr.edu>
#' @import stats
#' @export
#' @examples
#' alpha.l <- 0.6
#' alpha.r <- 0.4
#' alpha.u <- 0.1
#' pt <- 0.3
#' # print out decision table for a 3+3+3 design 
#' n <- rep(3, 3)
#' dec.table(alpha.l, alpha.r, alpha.u, pt, n)$table
#' # 3+3 design
#' n <- rep(3, 2)
#' dec.table(alpha.l, alpha.r, alpha.u, pt, n)$table

dec.table <- function(alpha.l, alpha.r, alpha.u, pt, n, sf.param  = 4, pe.par = 0.25, ...) {
  # check
  err <- c(alpha.l, alpha.r, alpha.u)
  k <- length(n)
  if(sum(err < 0 | err > 1) != 0) {
    stop("'alpha' should between 0 and 1.")
  }
  if(length(pt) > 2) {
    stop("'pt''s length should less than 2 (two-tailed test).")
  }
  if(length(pt) == 1) {
    pt <- rep(pt, 2)
  }
  if(k != 3 & k != 2) {
    stop("This function only find two-stage/three-stage optimal design")
  }
  if(k == 3) {
    out.two <- three.opt(alpha.l, alpha.r, pt, n, sf.param, pe.par)
    out.one <- right.three.opt(alpha.u, pt[2], n, sf.param)
  } else {
    out.two <- two.opt(alpha.l, alpha.r, pt, n, sf.param, pe.par)
    out.one <- right.two.opt(alpha.u, pt[2], n, sf.param)
  }
  des <- list(E = out.two$bdry[1:k], D = out.two$bdry[(k+1):(2*k)], DU = out.one$bdry,  n = n, pt = pt, sf.param = sf.param, alpha.two = out.two$error, alpha.one = out.one$error, beta = out.two$beta)
  r <- des$E
  s <- des$D
  su <- des$DU
  ns <- length(n)
  nt <- sum(n)
  nc <- cumsum(n)
  ans <- matrix(0, nt+1, ns)
  rownames(ans) <- 0:nt
  colnames(ans) <- nc
  for(j in 1:length(r)){
    ans[ ,j][1:(r[j]+1)] <- "E"
    ans[ ,j][(s[j]+2):(nc[j]+1)] <- "D"
    ans[ ,j][(su[j]+2):(nc[j]+1)] <- "DU"
    ans[ ,j][which(ans[, j] ==0)] <- "S"
    ind.s <- (1:(nc[k]+1)) > nc[j]+1
    ans[ , ][ind.s] <- rep("0", sum(ind.s))
  }
  out <- c(des, list(table=as.table(ans)))
  class(out) <- "dec.table"
  return(out)
}