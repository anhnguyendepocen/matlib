#' Eigen Decomposition of a Square Symmetric Matrix
#'
#' \code{Eigen} calculates the eigenvalues and eigenvectors of a square, symmetric matrix using the iterated QR decomposition
#'
#' @param X a square symmetric matrix
#' @param tol tolerance passed to \code{\link{QR}}
#' @param max.iter maximum number of QR iterations
#' @param retain.zeroes logical; retain 0 eigenvalues?
#' @return a list of two elements: \code{values}-- eigenvalues, \code{vectors}-- eigenvectors
#' @author John Fox and Georges Monette
#' @seealso \code{\link[base]{eigen}}
#' @seealso \code{\link{SVD}}
#' @export
#' @examples
#' C <- matrix(c(1,2,3,2,5,6,3,6,10), 3, 3) # nonsingular, symmetric
#' C
#' EC <- Eigen(C) # eigenanalysis of C
#' EC$vectors %*% diag(EC$values) %*% t(EC$vectors) # check

Eigen <- function(X, tol=sqrt(.Machine$double.eps), max.iter=100, retain.zeroes=TRUE){
  # returns the eigenvalues and eigenvectors of a square, symmetric matrix using the iterated QR decomposition
  # X: a square, symmetric matrix
  # tol: 0 tolerance
  # max.iter: iteration limit
  # retain.zeroes: retain 0 eigenvalues?
  if (!is.numeric(X) || !is.matrix(X) || nrow(X) != ncol(X) || any(abs(X - t(X)) > tol))
    stop("X must be a numeric, square, symmetric matrix")
  i <- 1
  Q <- diag(nrow(X))
  while (i <= max.iter){
    qr <- QR(X, tol=tol)
    Q <- Q %*% qr$Q
    X <- qr$R %*% qr$Q
    if (max(abs(X[lower.tri(X)])) <= tol) break
    i <- i + 1
  }
  if (i > max.iter) warning("eigenvalues did not converge")
  values <- diag(X)
  if (!retain.zeroes){
    nonzero <- values != 0
    values <- values[nonzero]
    Q <- Q[, nonzero, drop=FALSE]
  }
  list(values=values, vectors=Q)
}

#' Singular Value Decomposition of a Matrix
#'
#' Compute the singular-value decomposition of a matrix \eqn{X} either by Jacobi
#' rotations (the default) or from the eigenstructure of \eqn{X'X} using
#' \code{\link{Eigen}}. Both methods are iterative.
#' The result consists of two orthonormal matrices, \eqn{U}, and \eqn{V} and the vector \eqn{d}
#' of singular values, such that \eqn{X = U diag(d) V'}.
#' 
#' The default method is more numerically stable, but the eigenstructure method
#' is much simpler.

#' Singular values of zero are not retained in the solution.
#'
#' @param X a square symmetric matrix
#' @param tol zero and convergence tolerance
#' @param max.iter maximum number of iterations
#' @param method either \code{"Jacobi"} (the default) or \code{"eigen"}
#' @return a list of three elements: \code{d}-- singular values, \code{U}-- left singular vectors, \code{V}-- right singular vectors
#' @author John Fox and Georges Monette
#' @seealso \code{\link[base]{svd}}, the standard svd function
#' @seealso \code{\link{Eigen}}
#' @export
#' @examples
#' C <- matrix(c(1,2,3,2,5,6,3,6,10), 3, 3) # nonsingular, symmetric
#' C
#' SVD(C)
#'
#' # least squares by the SVD
#' data("workers")
#' X <- cbind(1, as.matrix(workers[, c("Experience", "Skill")]))
#' head(X)
#' y <- workers$Income
#' head(y)
#' (svd <- SVD(X))
#' VdU <- svd$V %*% diag(1/svd$d) %*%t(svd$U)
#' (b <- VdU %*% y)
#' coef(lm(Income ~ Experience + Skill, data=workers))

SVD <- function(X, method=c("Jacobi", "eigen"), 
                tol=sqrt(.Machine$double.eps), max.iter=100){
  # compute the singular-value decomposition of a matrix X
  # X: a matrix
  # method: "Jacobi" (by Jacobi rotations) 
  #         or "eigen" (by eigenstructure of X'X)
  # tol: 0 (and convergence) tolerance
  # max.iter: iteration limit for Jacobi method
  
  SVDJ <- function(X){
    # SVD by Jacobi rotations
    #   implementation of Algorithm 4.1 from Demmel & Veselic,
    #   "Jacobi's method is more accurate than QR"
    #   <http://www.netlib.org/lapack/lawnspdf/lawn15.pdf>
    n <- ncol(X)
    U <- X
    V <- diag(n)
    for (iter in 1:max.iter){
      converged <- 0
      for (i in 1:(n - 1)){
        for (j in (i + 1):n){
          a <- sum(U[ , i]^2)
          b <- sum(U[ , j]^2)
          g <- sum(U[ , i]*U[ , j])
          converged <- max(converged, abs(g)/sqrt(a*b))
          if (abs(g) > tol){
            z <- (b - a)/(2*g)
            t <- sign(z)/(abs(z) + sqrt(1 + z^2))
          }
          else {
            t <- 0
          }
          c <- 1/(sqrt(1 + t^2))
          s <- c*t
          T <- U[ , i]
          U[ , i] <- c*T - s*U[ , j]
          U[ , j] <- s*T + c*U[ , j]
          T <- V[ , i]
          V[ , i] <- c*T - s*V[ , j]
          V[ , j] <- s*T + c*V[ , j]
        }
      }
      if (converged < tol) break
    }
    if (iter > max.iter) stop("singular values did not converge")
    d <- rep(0, n)
    for (j in 1:n){
      d[j]=len(U[ , j])
      U[ , j] <- U[ , j]/d[j]
    }
    ord <- order(d, decreasing=TRUE)
    d <- d[ord]
    U <- U[, ord]
    V <- V[, ord]
    zeroes <- abs(d) < tol
    if (any(zeroes)){
      d <- d[!zeroes]
      U <- U[, !zeroes]
      V <- V[, !zeroes]
    }
    list(d=d, U=U, V=V)
  }
  
  SVDE <- function(X){
    # compute the singular-value decomposition of a matrix X from the eigenstructure of X'X
    VV <- Eigen(t(X) %*% X, tol=tol, max.iter=max.iter, retain.zeroes=FALSE)
    V <- VV$vectors
    d <- sqrt(VV$values)
    U <- X %*% V %*% diag(1/d,nrow=length(d)) # magically orthogonal
    list(d=d, U=U, V=V)
  }
  
  method <- match.arg(method)
  if (method == "Jacobi") SVDJ(X) else SVDE(X)
}

# SVD <- function(X, tol=sqrt(.Machine$double.eps)){
#   # compute the singular-value decomposition of a matrix X from the eigenstructure of X'X
#   # X: a matrix
#   # tol: 0 tolerance
#   VV <- Eigen(t(X) %*% X, tol=tol, retain.zeroes=FALSE)
#   V <- VV$vectors
#   d <- sqrt(VV$values)
#   U <- X %*% V %*% diag(1/d,nrow=length(d)) # magically orthogonal
#   list(d=d, U=U, V=V)
# }
