#
#' Length of a Vector or Column Lengths of a Matrix
#'
#' \code{len} calculates the Euclidean length (also called Euclidean norm) of a vector or the
#' length of each column of a numeric matrix.
#'
#' @param X a numeric vector or matrix
#'
#' @return a scalar or vector containing the length(s)
#' @seealso \code{\link[base]{norm}} for more general matrix norms
#' @export
#' @examples
#' len(1:3)
#' len(matrix(1:9, 3, 3))
#' 
#' # distance between two vectors
#' len(1:3 - c(1,1,1))

len <- function(X) {
  if (!is.numeric(X)) stop("X must be numeric")
  if (is.vector(X)) X <- matrix(X, ncol=1)
  sqrt(colSums(X^2))
}
